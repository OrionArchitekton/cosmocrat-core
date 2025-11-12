# Codex CLI Headless Authentication Workaround

## Problem
Codex CLI requires browser-based OAuth authentication ("Sign in with ChatGPT"), which doesn't work on headless systems. See [GitHub Issue #3820](https://github.com/openai/codex/issues/3820).

## Solutions

### Option 1: Use OpenAI API Directly (Recommended)
Instead of using Codex CLI, use the OpenAI API directly with API keys:

```bash
# Set API key from Doppler
export OPENAI_API_KEY=$(doppler secrets get OPENAI_API_KEY --plain)

# Use OpenAI Python SDK
pip install openai
python -c "from openai import OpenAI; client = OpenAI(); print(client.models.list())"
```

**Benefits:**
- ✅ Works perfectly on headless systems
- ✅ No browser required
- ✅ Full API access with your subscription
- ✅ Better for automation/CI/CD

### Option 2: Authenticate Once, Copy Session Token
If you must use Codex CLI:

1. **On a machine with a browser:**
   ```bash
   codex auth login
   # Complete OAuth flow in browser
   ```

2. **Extract the session token:**
   ```bash
   # Find where Codex stores credentials (usually ~/.config/codex/)
   cat ~/.config/codex/credentials.json
   # or
   cat ~/.codex/auth.json
   ```

3. **Copy the token to your headless system:**
   ```bash
   # Set as environment variable
   export CODEX_SESSION_TOKEN="<copied-token>"
   
   # Or add to Doppler
   doppler secrets set CODEX_SESSION_TOKEN="<copied-token>"
   ```

**Limitations:**
- ⚠️ Token may expire
- ⚠️ Requires manual setup
- ⚠️ Not ideal for automation

### Option 3: Use API Keys with Subscription
If your Ultra/Pro subscription includes API access:

```bash
# Get API key from OpenAI dashboard
# https://platform.openai.com/api-keys

# Add to Doppler
doppler secrets set OPENAI_API_KEY="sk-..."

# Use in your services
export OPENAI_API_KEY=$(doppler secrets get OPENAI_API_KEY --plain)
```

## Recommendation
**For headless Ubuntu deployment, use Option 1 (OpenAI API with API keys).**

This is the most reliable approach for:
- Headless servers
- CI/CD pipelines
- Docker containers
- Automation scripts

Your Ultra/Pro subscription should include API access - check your OpenAI dashboard for API keys.

