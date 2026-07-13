# G-AI Tool Description Review

Purpose: The text an AI client sees for each MCP tool comes 1:1 from that VI's own **VI Description** (Documentation tab). This file reviews the current descriptions of every VI in [`src/tools`](src/tools) plus the new [`set invoke node.vi`](src/tools/set%20invoke%20node.vi), flags the ones that are unclear, inaccurate, or missing information an AI agent would need, and proposes replacement text.

Editing a VI's description currently requires opening it for editing in LabVIEW and pasting the text into **File → VI Properties → Documentation → VI Description**, then saving — this is not yet something the G-AI tools themselves can do (there is no `set_description`/load-and-edit-existing-VI tool). So this file is meant as a checklist to apply by hand.

Legend: 🔴 needs a fix (wrong/misleading/incomplete) · 🟡 minor polish (works, could be clearer) · 🟢 fine as-is (not listed below).

---

## ✅ `set invoke node.vi` — description and connector pane are correct; the MCP server just needs a restart to see them

**Resolved.** Confirmed directly via `get_vi_details` (block diagram + description) that the VI itself has always been fine:
- Connector pane / front panel: `object_id`, `method_name`, `allow_alternate_names`, `error in`, `error out` — sensible names, not copy-pasted from `set_property`.
- VI description: already updated to the improved text (the one proposed in an earlier draft of this file).

**The actual bug:** a live `ToolSearch` lookup of `mcp__G-MCP__set_invoke_node` *still* returns the stale schema (`propertynode_id`/`method_id`) and the old placeholder description ("Sets the properties of a property-node...") — even after the VI was saved with the corrected connector pane and description. This means the G-MCP server's tool registry (built by `Init MCP.vi` scanning `src/tools` once at startup) does **not** auto-refresh when a tool VI is edited and saved afterward. It's serving whatever it read at the last server start.

**Fix:** restart the G-MCP server (re-run/reload `Init MCP.vi`, or whatever bootstraps it) so it rescans `src/tools` and picks up the current connector pane and description. This isn't specific to this VI — **any** edit to a tool VI's description or connector pane will look correct in LabVIEW but stay invisible to AI clients until the server restarts. Worth remembering as a general workflow step whenever applying the fixes in this document: edit → save → **restart the G-MCP server** → re-verify via `ToolSearch`.

---

## 🔴 `add subvi to vi.vi` — description is a copy-paste of `add object to vi.vi` and is factually wrong for this VI

**Current** (identical to `add object to vi.vi`):
> Adds an object to the block diagram, structure sub-diagram or frontpanel of the referenced vi. Get a VI reference from new_vi or get a structure sub-diagram by get_stucture_diagram to add to this. If adding a control, consider the create_control tool and think about adding objects first and then creating structures around them using the enclose with selection.
> Add a subVI or typedef by using the subvi_path, object name will be ignored. Leave subvi_path empty for all other objects.

**Problem:** Talks about an `object_name` parameter and "leave subvi_path empty for all other objects" — but `add_subvi_to_vi`'s connector pane has no `object_name` input at all (only `vi_id`, `subvi_path`, `position_x`, `position_y`). An AI reading this will look for a parameter that doesn't exist.

**Proposed:**
> Adds a subVI call (or a type-defined control/.ctl) to the block diagram, a structure's sub-diagram, or the front panel of the referenced VI, given the file path of the .vi/.ctl in `subvi_path`. This is the subVI-only equivalent of `add_object_to_vi` with `subvi_path` set — use it instead when you already know you're placing a subVI/typedef, since this tool has no unused `object_name` parameter. Get `vi_id` from `create_new_vi`, or a sub-diagram id from `get_structure_diagram`.

---

## 🟡 `add object to vi.vi` — typo and vague reference

**Current:**
> Adds an object to the block diagram, structure sub-diagram or frontpanel of the referenced vi. Get a VI reference from new_vi or get a structure sub-diagram by get_stucture_diagram to add to this. If adding a control, consider the create_control tool and think about adding objects first and then creating structures around them using the enclose with selection.
> Add a subVI or typedef by using the subvi_path, object name will be ignored. Leave subvi_path empty for all other objects.

**Problems:** `get_stucture_diagram` is missing an "r" (should be `get_structure_diagram`); "the enclose with selection" is a vague reference to a specific placeable object name a reader can't act on without more context; refers informally to "new_vi" instead of the actual tool name `create_new_vi`.

**Proposed:**
> Adds an object (function, structure, constant, or a typedef/subVI via `subvi_path`) to the block diagram, a structure's sub-diagram, or the front panel of the referenced VI. Get `vi_id` from `create_new_vi`, or a sub-diagram id from `get_structure_diagram`. To wrap existing objects in a new loop/case structure, place the objects first, then add one of the "Enclose Selection in..." structure objects around them. For a control/indicator on a terminal, prefer `create_control` instead — it creates and wires the right type automatically. To add a subVI or type-defined control (.ctl), set `subvi_path` to its file path (`object_name` is then ignored); leave `subvi_path` empty for every other object (see `get_available_objects` for valid `object_name` values).

---

## 🟡 `get available properties.vi` — missing an important limitation

**Current:**
> returns available properties for a propertynode. Use this before using set property to make sure to use the right property ID. Make sure to set the class of the propertynode first by connecting a reference wire to it.

**Problem:** Doesn't warn that this only works for **Property Nodes** — calling it on an Invoke Node reference fails (error 1057, "To More Specific Class"). This cost real trial-and-error to discover; worth saving the next AI agent the same detour. Also starts with a lowercase letter, inconsistent with the other tools.

**Proposed:**
> Returns the available property IDs for a Property Node — this does **not** work on Invoke Nodes (use `set_invoke_node` for those instead). Use this before `set_property` to find the correct property ID. Make sure a concrete-class reference (VI, Control, Application, etc.) is already wired into the property node's input, since the available properties depend on that class.

---

## 🟡 `connect objects.vi` — informal tool references

**Current:**
> Connects two terminals of two objects with a wire on the block diagram of a labview vi. To get a new VI use "new vi" to add objects to a vi use "add object". If a frontpanel control/indicator reference is passed to this function, it will automatically use the corresponding terminal on the block diagram for wiring. Use get_object_terminals before wiring to find out which terminals to wire.

**Problem:** References tools by informal names ("new vi", "add object") rather than their actual callable names (`create_new_vi`, `add_object_to_vi`), which is a minor mismatch for an AI client matching tool names literally.

**Proposed:**
> Connects two terminals of two objects with a wire on the block diagram. Get object ids from `create_new_vi`, `add_object_to_vi`/`add_subvi_to_vi`, or `create_control`. If a front-panel control/indicator's id is passed, the corresponding block-diagram terminal is used automatically. Call `get_object_terminals` first on each object to find the correct terminal indices.

---

## 🟡 `rename object.vi` — minor grammar/clarity

**Current:**
> Renames an objects label.text property, can be a control/indicator or a block diagram element like a constant.

**Problem:** "an objects label.text" → missing apostrophe; doesn't explain what `label_visible` does.

**Proposed:**
> Renames an object's label (its `Label.Text` property) — works on front-panel controls/indicators as well as block-diagram elements such as constants. Set `new_label_name` to the new text, and `label_visible` to show or hide the label.

---

## Not changed (already clear enough)

`get_project`, `get_vi_details`, `get_available_objects`, `get_object_terminals`, `get_structure_diagram`, `create_new_vi`, `create_control`, `set_property`, `cleanup_vi`, `close_vi`, `get_control`, `get_enum` — read fine for an AI client as-is; only cosmetic nitpicks (e.g. a double space in `cleanup_vi.vi`'s description) that aren't worth a separate edit pass.

## Next steps

1. Open each 🔴/🟡 VI listed above in LabVIEW, paste the proposed text into VI Properties → Documentation → VI Description, save.
2. **Restart the G-MCP server** (reload `Init MCP.vi`) afterward — it only reads each tool VI's connector pane and description once at startup, so edits stay invisible to AI clients until it rescans (see the `set_invoke_node` case above).
3. Re-check via `ToolSearch` that the live schema/description now match what's in the VI.
4. Once description-editing is scriptable (a future `set_description`-style tool, analogous to how `set_invoke_node` closed the Invoke Node gap), these edits could be applied programmatically instead of by hand.
