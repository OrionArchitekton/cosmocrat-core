import os

def get_env(key: str, default: str = "") -> str:
    val = os.getenv(key, default)
    if not val and default == "":
        raise RuntimeError(f"Missing required env var: {key}")
    return val
