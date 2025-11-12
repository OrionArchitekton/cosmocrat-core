from fastapi import FastAPI
import os

app = FastAPI(title="MCP Server")

@app.get("/healthz")
def healthz():
    return {"ok": True, "service": "mcp"}

@app.get("/health")
def health():
    return {"ok": True, "service": "mcp"}

@app.post("/tools/{tool_name}")
def run_tool(tool_name: str, payload: dict = {}):
    # Placeholder - MCP tools will be loaded from YAML files
    # This endpoint structure matches what n8n flows expect
    return {"status": "accepted", "tool": tool_name, "payload_keys": list(payload.keys())}

@app.get("/tools")
def list_tools():
    # Placeholder - will load from tools/*.yaml files
    return {"tools": []}

