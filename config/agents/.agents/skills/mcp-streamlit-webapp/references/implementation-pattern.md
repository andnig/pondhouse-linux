# Standalone Streamlit MCP Web App Pattern

Use this reference when implementing the web app. The MCP server already exists; do not create or modify server tools unless the user explicitly asks.

## Dependencies

Add these to the project dependency file (`pyproject.toml`, `requirements.txt`, etc.) if missing:

```toml
"streamlit>=1.30.0"
"streamlit-shadcn-ui>=0.1.19"
"pandas>=2.0.0"
```

The MCP client usually comes from the project MCP package, for FastMCP:

```python
from fastmcp.client import Client, StreamableHttpTransport
```

## Minimal client wrapper

```python
import asyncio
import json
import os
import sys

from fastmcp.client import Client, StreamableHttpTransport

DEFAULT_MCP_URL = os.environ.get("MCP_URL", "http://127.0.0.1:8000/mcp/")


def extract_tool_result(result) -> object:
    if hasattr(result, "data") and result.data is not None:
        return result.data
    if hasattr(result, "content") and result.content:
        text = getattr(result.content[0], "text", None)
        if text and text != "[Rendered Prefab UI]":
            try:
                return json.loads(text)
            except (json.JSONDecodeError, TypeError):
                return text
        return text
    return None


async def call_tool(url: str, tool_name: str, args: dict) -> object:
    async with Client(StreamableHttpTransport(url.strip() or DEFAULT_MCP_URL)) as client:
        result = await client.call_tool(tool_name, args)
        return extract_tool_result(result)


def call_tool_sync(url: str, tool_name: str, args: dict) -> object:
    return asyncio.run(call_tool(url, tool_name, args))
```

## Browserless smoke mode

Add a CLI flag so agents can verify MCP connectivity without launching a browser:

```python
def run_smoke(mcp_url: str, machine_id: str = "1") -> None:
    try:
        data = call_tool_sync(mcp_url, "get_dashboard_data", {"machine_id": machine_id})
        if not isinstance(data, dict) or "machines" not in data:
            raise RuntimeError("Invalid dashboard data returned")
        print(f"Smoke test passed: {len(data.get('machines', []))} machines")
        sys.exit(0)
    except Exception as exc:
        print(f"Smoke test failed: {exc}")
        sys.exit(1)
```

## Streamlit app structure

```python
def main() -> None:
    import pandas as pd
    import streamlit as st
    import streamlit_shadcn_ui as ui

    st.set_page_config(page_title="MCP Dashboard", layout="wide")
    st.title("MCP Dashboard")

    with st.sidebar:
        mcp_url = st.text_input("MCP Server URL", value=DEFAULT_MCP_URL).strip()
        initial_data = call_tool_sync(mcp_url, "get_dashboard_data", {"machine_id": "1"})
        machines = initial_data["machines"]
        labels = {f"Machine {m['id']} - {m['name']}": str(m["id"]) for m in machines}
        label = ui.select(options=list(labels.keys()), key="selected_machine")
        machine_id = labels.get(label, "1")

    data = initial_data if machine_id == "1" else call_tool_sync(
        mcp_url, "get_dashboard_data", {"machine_id": machine_id}
    )
```

## Dark metric cards

`streamlit_shadcn_ui.metric_card` may render in a white iframe even in dark Streamlit themes. Use native Streamlit HTML for top metric cards if the surrounding shell is dark:

```python
import html

def dark_metric_card(title: str, value: object, description: str, accent: str) -> str:
    return f"""
    <div style="background:#111827;border:1px solid rgba(148,163,184,.22);border-radius:14px;padding:24px 28px;min-height:102px;box-shadow:0 18px 45px rgba(0,0,0,.28);position:relative;overflow:hidden">
      <div style="position:absolute;inset:0 auto 0 0;width:4px;background:{html.escape(accent)}"></div>
      <div style="color:#cbd5e1;font-size:.76rem;font-weight:700;text-transform:uppercase;letter-spacing:.04em;margin-bottom:10px">{html.escape(title)}</div>
      <div style="color:#f8fafc;font-size:1.85rem;font-weight:800;line-height:1;margin-bottom:8px">{html.escape(str(value))}</div>
      <div style="color:#94a3b8;font-size:.78rem">{html.escape(description)}</div>
    </div>
    """
```

Render with `st.markdown(card_html, unsafe_allow_html=True)`. Escape all dynamic values.

## Pie chart without extra dependencies

Use Streamlit Vega-Lite for severity summaries:

```python
df_pie = pd.DataFrame(data["aggregates"]["pie_data"])
st.vega_lite_chart(
    df_pie,
    {
        "mark": {"type": "arc", "outerRadius": 118},
        "encoding": {
            "theta": {"field": "count", "type": "quantitative"},
            "color": {"field": "severity", "type": "nominal"},
            "tooltip": [
                {"field": "severity", "type": "nominal", "title": "Severity"},
                {"field": "count", "type": "quantitative", "title": "Events"},
            ],
        },
        "view": {"stroke": None},
    },
    use_container_width=True,
)
```

## Verification commands

Run from repo root, adapting the module path as needed:

```bash
uv sync
uv run python -m compileall <package_or_app_dir>

# terminal 1 / background
uv run fastmcp run path/to/server.py --transport http --port 8765 --path /mcp/

# terminal 2
uv run python path/to/web_app.py --smoke --mcp-url http://127.0.0.1:8765/mcp/
```
