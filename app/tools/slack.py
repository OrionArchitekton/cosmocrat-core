import os, json, urllib.request

def post(text: str, channel_hint: str = None):
    hook = os.getenv("SLACK_WEBHOOK_URL")
    if not hook:
        return False
    payload = {"text": text}
    data = json.dumps(payload).encode("utf-8")
    req = urllib.request.Request(hook, data=data, headers={"Content-Type":"application/json"})
    try:
        with urllib.request.urlopen(req, timeout=3) as r:
            return r.status == 200
    except Exception:
        return False
