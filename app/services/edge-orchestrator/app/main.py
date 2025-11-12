from fastapi import FastAPI
from pydantic import BaseModel
import os, requests, json

app = FastAPI(title=os.getenv("SERVICE_NAME","service"))

@app.get("/health")
def health():
    return {"ok": True, "service": os.getenv("SERVICE_NAME","service")}

class RunRequest(BaseModel):
    payload: dict = {}

@app.post("/run")
def run(req: RunRequest):
    # Emit lightweight event to ClickHouse HTTP if configured
    ch_url = os.getenv("CH_HTTP_URL", "").rstrip('/')
    if ch_url:
        try:
            # Simple ingestion via JSONEachRow
            data = {"ts": os.getenv("RUN_TS",""), "service": os.getenv("SERVICE_NAME","service"), "keys": list(req.payload.keys())}
            sql = "INSERT INTO events_raw FORMAT JSONEachRow\n" + json.dumps(data)
            requests.post(f"{ch_url}/?query=" + sql, timeout=1.5)
        except Exception as e:
            pass
    return {"status": "accepted", "payload_keys": list(req.payload.keys())}
