# G-AI

> **This is a fork.** Local changes here diverge from the upstream VIPM `.vip` package, so this fork is meant to be run from source in LabVIEW rather than installed as a package — see [Install Server](#install-server-this-fork) below.

## Overview
A LabVIEW MCP Server allowing you to control LabVIEW with an AI-Chatbot. It can read Project-, Library- and Class-Files and also creates a **full JSON graph representation** of a VI blockdiagrams. This way you can use a Large Language Model to read, document and port LabVIEW code and give advise on full projects. 

**The MCP can also create new VIs and add code to them, but this feature is really limited for now. Please feal free to ask for missing features!** 

![G-AI Banner Image](pictures/code_generation.png)

## MCP Overview
[MCP](https://modelcontextprotocol.io/docs/getting-started/intro) is a plugin-interface for Large Language Model Chatbots. An MCP Client is a Chat Application (e.g. Claude Desktop). An MCP Server is the Plugin itself providing the chatbot with functions (tools) that it can call during a conversation.

## MCP Example
If I have the MCP Server registered in Claude Desktop I can ask "Analyze this Project and tell me how to optimize it. C:/../test.lvproj". The Model will then propably call "get_project" multiple times to read the project file first and potentially all contained libraries. It will then call "get_vi_details" multiple times to get the description and block diagram screenshot of the most important VIs in the project. With all that information it can then provide guidance on the code.

## Installation
### Install Server (this fork)
This fork carries local changes that collide with the upstream repo's VIPM `.vip` package, so instead of installing a built package, run G-AI directly from source in LabVIEW:

1. Clone this repo.
2. Install dependencies with **NI-VIPM**. For my setup some dependencies aren't resolved automatically by VIPM from the `.vipc` — if that fails, install the `.vip` files under `Dependencies not resolved auto by vipm/` manually first, then retry.
3. Open `src/G-AI.lvproj` in LabVIEW 2020.
4. Run `G-AI Core.lvlib:main.vi` from the project to start the G-AI server, and leave it running in the LabVIEW dev environment while you use it. 

### Install Client
To use this tool you need to install an MCP client. [Claude Desktop](https://claude.com/de-de/download) is the one this project was tested on. It has a free trial, but for extensive projects a paid subscription will be required, since this process will use many tokens.

Different MCP Clients have different ways of installing the servers. But mostly it's a json config file that looks similar to this:

<pre>
  "mcpServers": {
    "G-AI": {
      "command": "npx",
      "args": [
        "mcp-remote",
        "http://127.0.0.1:36987/mcp/server"
      ]
    }
  }
</pre>

In Claude Desktop you can find this file through File -> Settings -> Developer -> Edit Config. See this [article from claude](https://support.claude.com/de/articles/10949351-erste-schritte-mit-lokalen-mcp-servern-auf-claude-desktop) for more details.
There might be multiple servers separated with comma in the "mcpServers" json element.
If you have issues modifying the file correctly, ask a chatbot of your choice for help, they'll know what to do.

Once the file is correctly formatted, you should see the Server in the Claude Desktop Settings -> Developer menu. If the server is running it should show as "running" in that menu.

![claude desktop mcp menu](pictures/mcpmenu.png)

Done, you should be able to ask Claude Desktop to analyze LabVIEW code now.

## Prompts
MCP features template-prompts. I'm planning on creating some that will automatically insert the current projects URL in your chat message field in claude code but it's not in place yet. Currently prompts like this will work:

<pre>
C:\Temp\src\My Project.lvproj
Analyze this LabVIEW project and tell me how to implement XYZ.
</pre>

<pre>
In LabVIEW, create a VI that generates a random number between a min and a max value.
</pre>

## Troubleshooting
### Claude Desktop Connectors
In Claude Desktop in a new chat window hit the "+" icon -> Connectors to see available connectors. G-AI should show up here and be activated.

![connectors menu in claude desktop](pictures/newchat.png)

When clicking "Manage Connectors" you can enable all tools to not require confirmation. This can also be done on the first time they're being used:

![manage connectors menu in claude desktop](pictures/manageconnectors.png)

### Logs
To troubleshoot issues related to MCP servers in claude desktop (and other clients) there's usually a log-file tracking all mcp interactions for a specific server.

More infos on MCP debugging [here](https://modelcontextprotocol.io/legacy/tools/debugging).

### MCP Inspector
To debug the server directly, without going through a chat client, use the official [MCP Inspector](https://modelcontextprotocol.io/legacy/tools/debugging):

```
npx @modelcontextprotocol/inspector
```

This opens a local web UI. Connect it to G-AI with:
- **Transport Type:** `Streamable HTTP` (or `SSE`, depending on inspector version)
- **URL:** `http://127.0.0.1:36987/mcp/server`

Make sure the G-AI server is already running in LabVIEW before connecting. From there you can list all registered tools with their live schemas/descriptions and call them individually with custom arguments — useful for checking whether a tool change (description, connector pane) actually took effect after restarting the server, without needing a full chat client session.

### Tool changes not showing up in the chat client
G-AI only scans `src/tools` once, at server startup (see `Init MCP.vi`) — editing a tool VI's description or connector pane and restarting just the G-AI server is not enough for a client to see the change, because most MCP clients also cache the `tools/list` result for the lifetime of their connection/session. In Claude Desktop specifically, a simple disconnect/reconnect of the MCP connector does **not** refresh this cache — you need to fully quit and restart the Claude Desktop app (not just close the window) to force a fresh `tools/list` handshake. After restarting both the G-AI server and the client, verify the change actually took effect (e.g. via the MCP Inspector above) rather than assuming it did.

## Security Warning
This toolkit may share any details of your LabVIEW Project with Claude Desktop, so make sure to only run this on code you own or have permission to share.