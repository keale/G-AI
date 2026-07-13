# G-AI – Project Overview

> This analysis was produced using G-AI's own MCP tools (`get_project`, `get_vi_details`) directly against the LabVIEW project [`src/G-AI.lvproj`](src/G-AI.lvproj) and the block diagrams of the VIs in [`src/tools`](src/tools) and [`src/G-AI Core`](src/G-AI%20Core).

## 1. Overview

G-AI is a **LabVIEW MCP server**: it starts a local HTTP server and registers itself with an MCP client (e.g. Claude Desktop) as a set of tools. Through these tools an LLM can

- **read and analyze** LabVIEW projects, libraries, classes, VIs and controls (including block-diagram screenshots), and
- **create and edit new VIs via VI Scripting** (place objects, wire them, set properties, rename, …).

The generic MCP infrastructure (HTTP server, JSON-RPC 2.0, tool registration, schema generation from connector panes) comes from the submodule [`Submodules/LabVIEW-MCP-Server-Toolkit`](Submodules/LabVIEW-MCP-Server-Toolkit) — a standalone, reusable toolkit by the same author. G-AI is the domain application built on top of it: the concrete VI-scripting tools plus the DQMH module that ties them together.

## 2. Project Structure (derived from `src/G-AI.lvproj`)

```
G-AI.lvproj
├── Modules
│   └── G-AI Core.lvlib          DQMH main module (event/message loop, MCP init, reference cache)
├── tests
│   ├── G-AI tests.lvlib         Caraya unit tests
│   └── Run_G-AI_Tests_CLI.vi    CLI test runner
├── Tools                        15 VIs – each is 1:1 an MCP tool (see section 5)
│   ├── get project.vi / get vi details.vi / get control.vi / get enum.vi
│   ├── get available objects.vi / get available properties.vi / get object terminals.vi
│   ├── get structure diagram.vi
│   ├── create new vi.vi / add object to vi.vi / add subvi to vi.vi
│   ├── create control.vi / connect objects.vi / rename object.vi / set property.vi
│   ├── cleanup vi.vi / close vi.vi / get broken vi list.vi
└── Dependencies (vi.lib)
    ├── Delacor QMH classes       DQMH framework (Message Queue, Module Admin)
    ├── jg_mcp MCP Server.lvlib   generic MCP/JSON-RPC server (from the submodule)
    ├── JDP Science JSONtext      JSON (de)serialization
    └── IlluminatedG HTTP/Stream  HTTP server & transport layer
```

The "G-AI Source Distribution" build spec packages the `Tools` folder and `G-AI Core.lvlib` as a VI package (VIPM), including a `launcher.vi` that appears in the LabVIEW Tools menu.

## 3. DQMH – How It Works and Its Structure

**DQMH (Delacor Queued Message Handler)** is the widely used LabVIEW architecture pattern for asynchronous, event-driven modules. `G-AI Core.lvlib` is built as a DQMH **singleton** module; `Main.vi` is its top-level VI with two parallel loops:

- **Event Handling Loop (EHL):** registers user events and, among others, waits on `MCP Events.onRpc` — this event is fired by the MCP Server Toolkit whenever the AI client calls a tool (a request with tool name/arguments, expecting a response). The EHL translates incoming requests into messages for the MHL.
- **Message Handling Loop (MHL):** processes messages (a string type plus an optional variant payload) through a case structure, e.g. the internal message case `"Get Reference"`, which returns a previously stored reference by its ID.

Other DQMH building blocks in the project:
- **Public DQMH API** (`Requests`/`Broadcasts`): standard requests such as `Show Panel`, `Hide Panel`, `Stop Module`, `Get Module Execution Status`; standard broadcasts such as `Module Did Init`, `Module Did Stop`, `Status Updated`, `Error Reported` — these let other modules observe G-AI Core's state.
- **Module Sync:** semaphore-based synchronization so the module can run both standalone (Tools-menu launcher) and when started by calling code.
- **Private:** init/error VIs, typedefs, and the two VIs central to the MCP connection: `Init MCP.vi`, `Do Get Reference.vi`, `Do Store Reference.vi` (see sections 4 and 6).

In short: DQMH provides the robust scaffolding (start/stop, error handling/logging, concurrency), while the actual MCP domain logic lives in the VIs inside the `Tools` folder.

## 4. How Tools Get Registered – `Init MCP.vi`

On startup, `Init MCP.vi` iterates over every `*.vi` file in the project's `Tools` folder and calls `MCP ADD TOOL` (a function from the `jg_mcp` SDK) for each one. The SDK automatically derives:

- the **tool name** from the VI name,
- the **tool description** from the VI's description (the exact text that `get_vi_details` also returns to the LLM),
- the **parameter JSON schema** from the connector pane (terminal names and types).

This means adding a new tool is as simple as dropping a new VI with a clear description and typed terminals into `src/tools` — no separate registration step required.

## 5. Reference Mechanism: Store/Get Reference

LabVIEW references (VI refnums, object/terminal refs, property-node refs) cannot be returned to the AI client as JSON, and without an active holder the memory manager would garbage-collect them. G-AI solves this with an internal ID cache:

1. **`Store Reference.vi`** stores a reference in a lookup table and returns a unique string ID (e.g. `vi_id`, `ctl_id`, `new_id`, `diagram_id`).
2. **`Get Reference.vi` / `Do Get Reference.vi`** later resolve that ID back to the actual reference — also reachable as its own DQMH message case `"Get Reference"` in `Main.vi`.

In practice this means: when the AI client calls, say, `create_new_vi`, it only gets a `vi_id` (string) back. That ID is then passed as a parameter to all subsequent tool calls (`add_object_to_vi`, `connect_objects`, `cleanup_vi`, …); the module resolves it internally back into the real VI reference. This keeps tool calls stateless from the client's perspective, while LabVIEW-side referential integrity and object lifetime are preserved.

## 6. The MCP Tools in Detail

All tools follow the standard LabVIEW error pattern (`error in` → `error out`) and are either purely read-only (analyze existing code, change nothing) or write tools (edit an in-memory VI that must then be explicitly saved).

### Read / Analysis (read-only)

| Tool | Purpose | Key inputs/outputs |
|---|---|---|
| `get_project` | Reads the XML content of a `.lvproj`/`.lvlib`/`.lvclass` file | `path` → `text` (XML) |
| `get_vi_details` | Description + block-diagram screenshot of a VI | `path` → `vi_description`, `vi_blockdiagram` |
| `get_control` | Front-panel screenshot of a `.ctl` (typedef/custom control) | `path` → `control_frontpanel_image` |
| `get_enum` | Elements of a typedef'd enum inside a `.ctl` file | `path` → `Enum Elements` |
| `get_available_objects` | List of all object names that can be placed on FP/BD | – → `available_objects` |
| `get_available_properties` | Available property IDs of a property node | `propertynode_id` → `All Supported Properties` |
| `get_object_terminals` | Terminal names, indices, types of a node/subVI | `object_id` → terminal list |
| `get_structure_diagram` | Reference to a sub-diagram of a structure (loop/case) | `structure_id`, `index` → `diagram_id` |
| `get_broken_vi_list` | Lists VIs currently broken in the LabVIEW environment, via the Application class's Get Broken VI List method | – → `Broken VI List` |

### Write / Code Generation

| Tool | Purpose | Key inputs/outputs |
|---|---|---|
| `create_new_vi` | Creates a new VI, optionally opens the block-diagram window | `show_vi` → `vi_id` |
| `add_object_to_vi` | Places an element (or, via `subvi_path`, a subVI/typedef) on FP/BD/structure | `vi_id`, `object_name`/`subvi_path`, `position_x/y` → `ctl id` |
| `add_subvi_to_vi` | Special case of `add_object_to_vi` for subVI calls | analogous, via `subvi_path` |
| `create_control` | Creates a control/indicator/constant on a terminal | `object_id`, `terminal_index`, `Create Constant` → `new_id` |
| `connect_objects` | Wires two terminals on the block diagram | `from_object_id`+index, `to_object_id`+index |
| `rename_object` | Changes an object's label text/visibility | `id`, `new_label_name`, `label_visible` |
| `set_property` | Sets/reads properties of a property node | `propertynode_id`, `property_ids[]`, `properties_iswrite[]` |
| `cleanup_vi` | Cleans up the block diagram (`BD.CleanUp`) | `vi_id` |
| `close_vi` | Closes the front-panel window (deletes unsaved VIs!) | `vi_id` |

## 7. Typical Interaction Flow

**Analysis request** ("Analyze this project and suggest optimizations: `C:\...\test.lvproj`"):
1. The AI calls `get_project` (repeatedly, for the project and any contained libraries).
2. The AI calls `get_vi_details` for the most relevant VIs (text description + block-diagram image).
3. The AI formulates its analysis purely from the text/images received — no files are modified.

**Code-generation request** ("Create a VI that generates a random number between min and max"):
1. `create_new_vi` → `vi_id`
2. Repeated `add_object_to_vi` calls (placing functions/controls) → new object IDs each time
3. `get_object_terminals` to determine wiring points
4. `connect_objects` to wire them together
5. `create_control` / `rename_object` for front-panel labeling
6. `cleanup_vi` to finish

## 8. Dependencies (excerpt)

- **Delacor QMH** (`Delacor_lib_QMH_*`) – DQMH framework
- **jg_mcp MCP Server SDK** (`jgoebel`) – generic MCP/JSON-RPC server, developed in the `LabVIEW-MCP-Server-Toolkit` submodule
- **JDP Science JSONtext / Common Utilities** – JSON serialization, Base64, timestamps
- **IlluminatedG HTTP Server / HTTP Utils / Stream(-TCP/-Websocket)** – transport layer of the HTTP server
- **JKI Caraya** – unit test framework (`tests/`)

## 9. Submodule `LabVIEW-MCP-Server-Toolkit`

A standalone, reusable project by the same author that provides the generic MCP infrastructure: HTTP server, JSON-RPC 2.0 handling, registration of tools/prompts/resources, and automatic JSON schema generation from VI connector panes. G-AI is the first concrete application of this toolkit — specialized for VI-scripting tools used in LabVIEW code analysis and generation.

## 10. Security Notice

Because the tools transmit project contents (code, block diagrams as screenshots) to the AI client, the server should only be run against code you own or are permitted to share (see also [README.md](README.md), "Security Warning" section).
