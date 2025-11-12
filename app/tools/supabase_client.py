from typing import Any, Dict, List, Optional
import os
import json
import urllib.request

SB_URL = os.getenv("SB_URL","")
SB_ANON_KEY = os.getenv("SB_ANON_KEY","")

def insert(table: str, rows: List[Dict[str, Any]]) -> Dict[str, Any]:
    assert SB_URL and SB_ANON_KEY, "Supabase env missing"
    req = urllib.request.Request(
        f"{SB_URL}/rest/v1/{table}",
        data=json.dumps(rows).encode("utf-8"),
        headers={
            "apikey": SB_ANON_KEY,
            "Authorization": f"Bearer {SB_ANON_KEY}",
            "Content-Type": "application/json",
            "Prefer": "return=representation"
        },
        method="POST"
    )
    with urllib.request.urlopen(req, timeout=5) as r:
        return json.loads(r.read().decode("utf-8"))
