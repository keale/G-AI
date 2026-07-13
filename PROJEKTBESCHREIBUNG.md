# G-AI – Projektbeschreibung

> Diese Analyse wurde mit den G-AI-eigenen MCP-Tools (`get_project`, `get_vi_details`) direkt aus dem LabVIEW-Projekt [`src/G-AI.lvproj`](src/G-AI.lvproj) sowie den Block-Diagrammen der VIs in [`src/tools`](src/tools) und [`src/G-AI Core`](src/G-AI%20Core) erstellt.

## 1. Überblick

G-AI ist ein **LabVIEW MCP-Server**: Er startet einen lokalen HTTP-Server und meldet sich bei einem MCP-Client (z. B. Claude Desktop) als Werkzeugsammlung an. Über diese Werkzeuge ("Tools") kann ein LLM

- LabVIEW-Projekte, -Bibliotheken, -Klassen, -VIs und -Controls **lesen und analysieren** (inkl. Blockdiagramm-Screenshots), und
- neue VIs **erzeugen und per VI-Scripting bearbeiten** (Objekte platzieren, verdrahten, Properties setzen, umbenennen …).

Die generische MCP-Infrastruktur (HTTP-Server, JSON-RPC 2.0, Tool-Registrierung, Schema-Generierung aus Connector Panes) stammt aus dem Submodul [`Submodules/LabVIEW-MCP-Server-Toolkit`](Submodules/LabVIEW-MCP-Server-Toolkit) – einem eigenständigen, wiederverwendbaren Toolkit desselben Autors. G-AI ist die fachliche Anwendung darauf: die konkreten VI-Scripting-Tools plus das DQMH-Modul, das sie zusammenhält.

## 2. Projektstruktur (aus `src/G-AI.lvproj`)

```
G-AI.lvproj
├── Modules
│   └── G-AI Core.lvlib          DQMH-Hauptmodul (Event-/Message-Loop, MCP-Init, Referenz-Cache)
├── tests
│   ├── G-AI tests.lvlib         Caraya-Unit-Tests
│   └── Run_G-AI_Tests_CLI.vi    CLI-Test-Runner
├── Tools                        15 VIs – je 1:1 ein MCP-Tool (siehe Abschnitt 5)
│   ├── get project.vi / get vi details.vi / get control.vi / get enum.vi
│   ├── get available objects.vi / get available properties.vi / get object terminals.vi
│   ├── get structure diagram.vi
│   ├── create new vi.vi / add object to vi.vi / add subvi to vi.vi
│   ├── create control.vi / connect objects.vi / rename object.vi / set property.vi
│   ├── cleanup vi.vi / close vi.vi
└── Dependencies (vi.lib)
    ├── Delacor QMH Klassen       DQMH-Framework (Message Queue, Module Admin)
    ├── jg_mcp MCP Server.lvlib   generischer MCP/JSON-RPC-Server (aus dem Submodul)
    ├── JDP Science JSONtext      JSON-(De-)Serialisierung
    └── IlluminatedG HTTP/Stream  HTTP-Server & Transport-Layer
```

Das Build-Spec "G-AI Source Distribution" packt den `Tools`-Ordner und `G-AI Core.lvlib` als VI-Package (VIPM), inkl. eines `launcher.vi`, der im LabVIEW-Tools-Menü erscheint.

## 3. DQMH – Arbeitsweise und Struktur

**DQMH (Delacor Queued Message Handler)** ist das in LabVIEW verbreitete Architekturmuster für asynchrone, ereignisgesteuerte Module. `G-AI Core.lvlib` ist als DQMH-**Singleton**-Modul aufgebaut, `Main.vi` ist dessen Top-Level-VI mit zwei parallelen Schleifen:

- **Event Handling Loop (EHL):** registriert User Events und wartet u. a. auf `MCP Events.onRpc` – dieses Event feuert das MCP-Server-Toolkit, sobald der AI-Client ein Tool aufruft (Request mit Tool-Name/Argumenten, erwartet eine Response). Die EHL übersetzt eingehende Requests in Nachrichten für die MHL.
- **Message Handling Loop (MHL):** verarbeitet Nachrichten (String-Typ + optionale Variant-Payload) über eine Case-Struktur, z. B. den internen Message-Case `"Get Reference"`, der eine zuvor gespeicherte Referenz per ID zurückgibt.

Weitere DQMH-Bausteine im Projekt:
- **Public DQMH API** (`Requests`/`Broadcasts`): Standard-Requests wie `Show Panel`, `Hide Panel`, `Stop Module`, `Get Module Execution Status`; Standard-Broadcasts wie `Module Did Init`, `Module Did Stop`, `Status Updated`, `Error Reported` – darüber können andere Module den Zustand von G-AI Core beobachten.
- **Module Sync:** Semaphore-basierte Synchronisierung, damit das Modul sowohl eigenständig (Tools-Menü-Launcher) als auch von aufrufendem Code gestartet werden kann.
- **Private:** Init-/Fehler-VIs, Typdefs, sowie die beiden für die MCP-Anbindung zentralen VIs `Init MCP.vi`, `Do Get Reference.vi`, `Do Store Reference.vi` (siehe Abschnitt 4 und 6).

Kurz: DQMH liefert hier den robusten Rahmen (Start/Stop, Fehlerbehandlung/Logging, Nebenläufigkeit), während die eigentliche MCP-Fachlogik in der `Tools`-Ordner-VIs steckt.

## 4. Wie Tools registriert werden – `Init MCP.vi`

Beim Start iteriert `Init MCP.vi` über alle `*.vi`-Dateien im Projektordner `Tools` und ruft für jede davon `MCP ADD TOOL` auf (Funktion aus dem `jg_mcp` SDK). Dabei generiert das SDK automatisch:

- den **Tool-Namen** aus dem VI-Namen,
- die **Tool-Beschreibung** aus der VI-Description (genau der Text, den `get_vi_details` auch dem LLM zurückgibt),
- das **JSON-Schema der Parameter** aus dem Connector Pane (Terminal-Namen und -Typen).

Damit ist ein neues Tool hinzuzufügen so einfach wie: eine neue VI mit klarer Description und typisierten Terminals in `src/tools` ablegen – keine separate Registrierung nötig.

## 5. Referenz-Mechanismus: Store/Get Reference

LabVIEW-Referenzen (VI-Refnums, Objekt-/Terminal-Refs, Property-Node-Refs) lassen sich nicht als JSON an den AI-Client zurückgeben, und ohne aktiven Halter würde der Memory-Manager sie aufräumen. G-AI löst das über einen internen ID-Cache:

1. **`Store Reference.vi`** legt eine Referenz in einer Lookup-Tabelle ab und liefert eine eindeutige String-ID zurück (z. B. `vi_id`, `ctl_id`, `new_id`, `diagram_id`).
2. **`Get Reference.vi` / `Do Get Reference.vi`** lösen diese ID später wieder in die reale Referenz auf – auch als eigener DQMH-Message-Case `"Get Reference"` in `Main.vi` erreichbar.

Praktisch bedeutet das: Ruft der AI-Client z. B. `create_new_vi` auf, bekommt er nur eine `vi_id` (String) zurück. Diese ID wird bei allen folgenden Tool-Aufrufen (`add_object_to_vi`, `connect_objects`, `cleanup_vi` …) als Parameter mitgegeben; das Modul löst sie intern wieder in die tatsächliche VI-Referenz auf. So bleiben Tool-Aufrufe zustandslos für den Client, während LabVIEW-seitig referenzielle Integrität und Lebensdauer der Objekte gewahrt bleiben.

## 6. Die MCP-Tools im Detail

Alle Tools folgen dem Standard-LabVIEW-Fehlermuster (`error in` → `error out`) und sind entweder rein lesend (analysieren bestehenden Code, ändern nichts) oder schreibend (bearbeiten eine im Speicher offene VI, die anschließend explizit gespeichert werden muss).

### Lesen / Analyse (read-only)

| Tool | Zweck | Wichtige Ein-/Ausgaben |
|---|---|---|
| `get_project` | Liest den XML-Inhalt einer `.lvproj`/`.lvlib`/`.lvclass`-Datei | `path` → `text` (XML) |
| `get_vi_details` | Beschreibung + Blockdiagramm-Screenshot einer VI | `path` → `vi_description`, `vi_blockdiagram` |
| `get_control` | Screenshot des Frontpanels eines `.ctl` (Typdef/Custom Control) | `path` → `control_frontpanel_image` |
| `get_enum` | Elemente eines typdefinierten Enums aus einer `.ctl`-Datei | `path` → `Enum Elements` |
| `get_available_objects` | Liste aller Objektnamen, die auf FP/BD platzierbar sind | – → `available_objects` |
| `get_available_properties` | Verfügbare Property-IDs eines Property Node | `propertynode_id` → `All Supported Properties` |
| `get_object_terminals` | Terminal-Namen, -Indizes, -Typen eines Node/SubVI | `object_id` → Terminal-Liste |
| `get_structure_diagram` | Referenz auf ein Sub-Diagramm einer Struktur (Loop/Case) | `structure_id`, `index` → `diagram_id` |

### Schreiben / Code-Generierung

| Tool | Zweck | Wichtige Ein-/Ausgaben |
|---|---|---|
| `create_new_vi` | Erzeugt eine neue VI, öffnet optional das Blockdiagramm-Fenster | `show_vi` → `vi_id` |
| `add_object_to_vi` | Platziert ein Element (oder per `subvi_path` ein SubVI/Typedef) auf FP/BD/Struktur | `vi_id`, `object_name`/`subvi_path`, `position_x/y` → `ctl id` |
| `add_subvi_to_vi` | Spezialfall von `add_object_to_vi` für SubVI-Aufrufe | analog, über `subvi_path` |
| `create_control` | Erzeugt Control/Indicator/Konstante an einem Terminal | `object_id`, `terminal_index`, `Create Constant` → `new_id` |
| `connect_objects` | Verdrahtet zwei Terminals auf dem Blockdiagramm | `from_object_id`+Index, `to_object_id`+Index |
| `rename_object` | Ändert Label-Text/-Sichtbarkeit eines Objekts | `id`, `new_label_name`, `label_visible` |
| `set_property` | Setzt/liest Properties eines Property Node | `propertynode_id`, `property_ids[]`, `properties_iswrite[]` |
| `cleanup_vi` | Räumt das Blockdiagramm auf (`BD.CleanUp`) | `vi_id` |
| `close_vi` | Schließt das Frontpanel-Fenster (löscht ungespeicherte VIs!) | `vi_id` |

## 7. Typischer Interaktionsablauf

**Analyse-Anfrage** ("Analysiere dieses Projekt und schlage Optimierungen vor: `C:\...\test.lvproj`"):
1. AI ruft `get_project` (mehrfach, für Projekt + enthaltene Libraries) auf.
2. AI ruft `get_vi_details` für die relevantesten VIs auf (Text-Beschreibung + Blockdiagramm-Bild).
3. AI formuliert die Analyse rein aus den erhaltenen Texten/Bildern – es werden keine Dateien verändert.

**Code-Generierungs-Anfrage** ("Erstelle eine VI, die eine Zufallszahl zwischen Min und Max erzeugt"):
1. `create_new_vi` → `vi_id`
2. mehrfach `add_object_to_vi` (Funktionen/Controls platzieren) → jeweils neue Objekt-IDs
3. `get_object_terminals` zur Ermittlung der Wiring-Punkte
4. `connect_objects` zum Verdrahten
5. `create_control` / `rename_object` für Frontpanel-Beschriftung
6. `cleanup_vi` zum Abschluss

## 8. Abhängigkeiten (Auszug)

- **Delacor QMH** (`Delacor_lib_QMH_*`) – DQMH-Framework
- **jg_mcp MCP Server SDK** (`jgoebel`) – generischer MCP/JSON-RPC-Server, entwickelt im Submodul `LabVIEW-MCP-Server-Toolkit`
- **JDP Science JSONtext / Common Utilities** – JSON-Serialisierung, Base64, Timestamps
- **IlluminatedG HTTP Server / HTTP Utils / Stream(-TCP/-Websocket)** – Transport-Layer des HTTP-Servers
- **JKI Caraya** – Unit-Test-Framework (`tests/`)

## 9. Submodul `LabVIEW-MCP-Server-Toolkit`

Eigenständiges, wiederverwendbares Projekt desselben Autors, das die generische MCP-Infrastruktur bereitstellt: HTTP-Server, JSON-RPC-2.0-Handling, Registrierung von Tools/Prompts/Resources sowie automatische JSON-Schema-Generierung aus VI-Connector-Panes. G-AI ist die erste konkrete Anwendung dieses Toolkits – spezialisiert auf VI-Scripting-Tools für LabVIEW-Codeanalyse und -generierung.

## 10. Sicherheitshinweis

Da die Tools Projektinhalte (Code, Blockdiagramme als Screenshots) an den AI-Client übertragen, sollte der Server nur mit Code betrieben werden, den man selbst besitzt oder weitergeben darf (siehe auch [README.md](README.md), Abschnitt "Security Warning").
