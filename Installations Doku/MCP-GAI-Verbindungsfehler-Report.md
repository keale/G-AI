# Report: MCP-Server "G-AI" – Verbindungsfehler und Behebung

**Datum:** 2026-07-06
**Betroffenes System:** lokaler PC (Konto `alexk`, Domäne `p4keal`)
**Betroffene Komponente:** MCP-Server `G-AI` (stdio, `npx mcp-remote http://127.0.0.1:36987/mcp/server`)

## Symptom

`claude mcp get G-AI` zeigte:

```
Status: ✘ Failed to connect
```

## Diagnose

1. **Backend war nicht das Problem.** Ein direkter HTTP-Test gegen `http://127.0.0.1:36987/mcp/server` lieferte `200 OK` mit einer erwarteten JSON-RPC-Parse-Fehlermeldung (weil ein einfacher GET ohne Body gesendet wurde). Der lokale Server, den `mcp-remote` ansprechen soll, lief also einwandfrei.

2. **`npx` selbst crashte beim Start.** Jeder Aufruf von `npx`/`npm` (nicht aber `node --version`) endete mit:
   ```
   Error: EPERM: operation not permitted, lstat 'C:\Users\AdminHIJ'
       at Object.realpathSync (node:fs:2552:7)
       ...
   Node.js v18.13.0
   ```

3. **Ursache gefunden:**
   - `C:\Program Files\nodejs` ist ein **Symlink** (angelegt von nvm-windows) auf `C:\Users\AdminHIJ\AppData\Roaming\nvm\v18.13.0`.
   - Die einzige systemweite Node.js-Installation lag also physisch im Profilordner des Admin-Kontos `AdminHIJ`.
   - Das Konto `alexk` hat **keine Zugriffsrechte** auf `C:\Users\AdminHIJ` (`Get-Acl` → *"Attempted to perform an unauthorized operation"*).
   - Sobald Node beim Ausführen eines Skripts (wie `npm-cli.js`/`npx-cli.js`) den realen Pfad durch den Symlink auflösen muss (`realpathSync`), scheitert das `lstat` auf `C:\Users\AdminHIJ` mit `EPERM` — der Prozess stürzt sofort ab.
   - Da Claude Code den MCP-Server per `npx mcp-remote ...` startet, starb dieser Kindprozess vor jedem Handshake → *"Failed to connect"*.
   - Zusätzlich verwiesen sowohl die **System**- als auch die **Benutzer**-`PATH`-Variable sowie `NVM_HOME` auf den `AdminHIJ`-Pfad (Altlast aus einer früheren nvm-windows-Installation).

## Lösung

### 1. Node.js separat für das eigene Konto installieren
```powershell
winget install --id OpenJS.NodeJS.LTS --scope user
```
- Installiert Node.js 24 LTS **nutzerspezifisch** unter:
  `C:\Users\AlexK\AppData\Local\Microsoft\WinGet\Packages\OpenJS.NodeJS.LTS_Microsoft.Winget.Source_8wekyb3d8bbwe\node-v24.18.0-win-x64`
- Kein Admin nötig, rührt `C:\Program Files\nodejs` und das Konto `AdminHIJ` nicht an.

### 2. Problem: System-PATH gewinnt immer
Windows setzt bei jedem neuen Prozess die **System-PATH** (Machine-Scope) vor die **Benutzer-PATH**. Da `C:\Program Files\nodejs` (der kaputte Symlink) in der System-PATH steht, hätte ein einfaches `npx` im Terminal weiterhin den alten, defekten Pfad zuerst gefunden — unabhängig davon, wie die Benutzer-PATH sortiert ist.

### 3. Gezielter Fix für den MCP-Server G-AI
Statt die globale PATH-Variable zu verändern (würde Adminrechte erfordern und potenziell `AdminHIJ` beeinflussen), wurde dem Server-Eintrag eine **eigene `PATH`-Umgebungsvariable** mitgegeben, die nur für diesen einen Prozess gilt:

```bash
claude mcp remove G-AI
claude mcp add G-AI -e "PATH=<neues-Node-Verzeichnis>;<restliche System- und Benutzer-PATH>" -- npx mcp-remote http://127.0.0.1:36987/mcp/server
```

Damit findet `npx` beim Start des G-AI-Servers zuerst das neue, funktionierende Node 24 statt des defekten Node 18 unter `AdminHIJ`.

### Zwischenfehler unterwegs
Ein erster Versuch, direkt den absoluten Pfad zum neuen `npx.cmd` einzutragen, reichte **nicht** aus: `npx` selbst startete zwar korrekt, spawnte aber beim Ausführen des heruntergeladenen `mcp-remote`-Pakets intern wieder `node` über die (kaputte) System-PATH. Ergebnis war ein neuer Fehler:
```
ReferenceError: File is not defined
    at .../undici/lib/web/webidl/index.js:537
Node.js v18.13.0
```
(`undici`, eine Abhängigkeit von `mcp-remote`, benötigt Node ≥ 20; lief aber auf dem alten Node 18). Das bestätigte, dass nicht nur der Aufruf von `npx` selbst, sondern auch alle intern gespawnten `node`-Prozesse auf das neue Node-Verzeichnis umgelenkt werden mussten — daher die Lösung über eine explizite `PATH`-Umgebungsvariable für den gesamten Prozessbaum.

## Ergebnis

```
G-AI:
  Status: ✔ Connected
```

## Offene Punkte / Empfehlungen

- **Nur der G-AI-MCP-Server ist gefixt.** Ein normales Terminal (PowerShell/CMD) unter `alexk` nutzt weiterhin standardmäßig das kaputte `C:\Program Files\nodejs`, solange die **System-PATH** nicht bereinigt wird (das erfordert Adminrechte, z. B. über das Konto `AdminHIJ`).
- Mögliche Optionen für eine dauerhafte, allgemeine Lösung:
  1. Admin (`AdminHIJ`) bereinigt die System-PATH/`NVM_HOME`-Altlasten oder installiert Node.js neu ohne nvm-windows-Symlink.
  2. Eine PowerShell-Profil-Funktion für `alexk` anlegen, die `node`/`npm`/`npx` auf das neue, nutzerspezifische Node umleitet (wirkt nur in interaktiven PowerShell-Sitzungen, nicht für andere Programme, die `npx` direkt aufrufen).


  nvm-windows wurde deinstalliert, Pfade bereinigt.


## Probleme
ein Schema-Fehler im G-AI-Server. Ich habe den MCP-Server direkt per JSON-RPC (tools/list) angesprochen und die Tool-Schemas ausgelesen.

Ursache: Mehrere Tools (add_object_to_vi, get_control, get_enum, get_project, get_vi_details) haben eine Input-Property namens:

"error_in_(no_error)"

Das kommt vom LabVIEW-Standardcluster "error in (no error)", dessen Label 1:1 als JSON-Property-Key übernommen wurde. Klammern ( ) sind aber im Anthropic-API-Schema für Tool-Properties nicht erlaubt — Keys müssen ^[a-zA-Z0-9_.-]{1,64}$ entsprechen. tools.14 in der Fehlermeldung ist get_vi_details (0-indiziert), das erste Tool mit diesem verbotenen Key.

Das ist ein Bug im G-AI-Server (LabVIEW-seitig, läuft auf 127.0.0.1:36987), nicht in eurem Projekt-Repo. Lässt sich von hier aus nicht patchen, weil der Server-Prozess nicht Teil dieses Repos ist.

Mögliche Wege das zu umgehen:

● User declined to answer questions
· Wie soll ich weiter vorgehen, um den G-AI Verbindungsfehler zu umgehen? (G-AI Quellcode suchen und Property-Key fixen / Nur Workaround via Proxy / Nichts automatisiert – nur Diagnose melden)

✻ Churned for 3m 58s · 1 shell still running

❯ würde dieser Fehler auch in Claude Desktop auftreten?

● Skill(claude-api)
Successfully loaded skill · 4 tools allowed
Skills restored (claude-api)

Yes — on both counts.

The validation is server-side, in the Messages API itself. The error path tools.14.custom.input_schema.properties is the API's own request validation on the tools array — it happens when any client sends a tools: [{type: "custom", ...}] definition whose input_schema.properties contains a key that doesn't match ^[a-zA-Z0-9_.-]{1,64}$. This isn't a Claude Code-specific check; it's enforced wherever a request hits POST /v1/messages with that tool schema attached, regardless of which client assembled the req

Claude Desktop would hit the identical error. Claude Desktop's MCP integration works the same way Claude Code's does: it connects to the MCP server, calls tools/lch tool declares, and forwards it into thetools array of the Messages API request as a custom tool. Since the malformed key error_in_(no_error) lives in the G-AI server's own tools/list response — not in anything Claude Code adds — any MCP client that passes that schema through untouched (Desktop included) would produce the same invalid tools payload and get the same 400.

So this is fully a G-AI-server-side bug: it will reproduce in Claude Desktop, in the raw API, in mcp-remote, in any
MCP client — anywhere that server's schema fer affected tools) gets forwarded as-is tothe Anthropic API.

✻ Sautéed for 1m 43s · 1 shell still running
