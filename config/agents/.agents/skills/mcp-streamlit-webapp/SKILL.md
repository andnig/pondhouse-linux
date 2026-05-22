---
name: mcp-streamlit-webapp
description: Build standalone Streamlit web app clients for existing MCP/FastMCP servers. Use when asked to create a web dashboard or browser UI that consumes MCP tools over HTTP, especially with `streamlit_shadcn_ui`, FastMCP `Client`/`StreamableHttpTransport`, browserless smoke tests, run-command documentation, dark Streamlit dashboards, KPI cards, tables, and charts. Do not use for creating the MCP server itself.
---

# MCP Streamlit Web App

Create a standalone Streamlit client for an already-existing MCP server. The app must call MCP tools over the server's HTTP transport; it must not import database helpers or server internals to fetch data directly.

For concrete FastMCP/Streamlit snippets, read [references/implementation-pattern.md](references/implementation-pattern.md) when implementing.

## Workflow

1. **Inspect the existing MCP API**
   - Find the MCP server run command, HTTP path, and port convention.
   - Identify the tool(s) the web app should call and the returned data shape.
   - Prefer one combined dashboard tool when it exists, e.g. `get_dashboard_data(machine_id)`.

2. **Add only web-client dependencies**
   - Add Streamlit and UI/data dependencies (`streamlit`, `streamlit-shadcn-ui`, `pandas`) to the project's dependency file.
   - Reuse the existing MCP client package already in the project, such as FastMCP.
   - Do not add server/database dependencies unless already required by the project.

3. **Create a separate web app file**
   - Put the app near the existing package code, e.g. `factory_demo/web_app.py` or `<package>/web_app.py`.
   - Keep it independent from server internals: no `from package.db import ...`, no private `_load_dashboard_data`, no direct SQL.
   - Use an endpoint default like `MCP_URL=http://127.0.0.1:8000/mcp/`, overridable via environment variable and sidebar text input.

4. **Use a real MCP HTTP client**
   - For FastMCP, use `Client(StreamableHttpTransport(url))` and `client.call_tool(...)`.
   - Normalize `CallToolResult`: prefer `result.data`, then parse JSON text from `result.content[0].text`.
   - Wrap async calls for Streamlit with a synchronous helper using `asyncio.run(...)`.

5. **Build the dashboard UI**
   - Use `streamlit_shadcn_ui` where it works well: machine selector, metric cards when theme-compatible, read-only tables.
   - Use standard Streamlit charts or Vega-Lite for reliable plotting.
   - For dark dashboards, avoid white `metric_card` iframes by using escaped HTML metric cards with `st.markdown(..., unsafe_allow_html=True)`.
   - Show a helpful error with the exact MCP server command when the app cannot connect.

6. **Add browserless smoke mode**
   - Add `--smoke`, `--mcp-url`, and any key selector args such as `--machine-id`.
   - The smoke path must call the same MCP client function as the UI.
   - Exit `0` on valid MCP data and nonzero on connection/schema failure.

7. **Document the two-process run flow**
   - Document server process: `fastmcp run ... --transport http --port 8000 --path /mcp/`.
   - Document web process: `streamlit run path/to/web_app.py`.
   - Document smoke verification and alternate ports/`MCP_URL` override.

8. **Verify**
   - Run dependency sync.
   - Compile the package/app.
   - Run existing MCP/server smoke tests so the web work did not break the server.
   - Start the MCP HTTP server on a non-default port and run the web app smoke against it.

## Required guardrails

- Do not create the MCP server unless explicitly asked.
- Do not bypass MCP with direct DB calls or server private function imports.
- Do not suppress type/import errors with ignore comments.
- Do not remove existing MCP app behavior or tests.
- Do not commit changes unless the user explicitly requests it.
