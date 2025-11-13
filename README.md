# Cosmocrat Core (Lean Build)

Core runtime for headless MCP mini PC deployment. Includes PostgreSQL (pgvector), Redis, Langfuse, Ollama, and core services.

## Quick Start

### Option A: USB Stick Cloud-Init (Headless Ubuntu)

1. **Get Tailscale auth key:**
   - Go to [Tailscale Admin Console](https://login.tailscale.com/admin/settings/keys)
   - Generate auth key (reusable or one-time)

2. **Prepare USB stick:**
   - Format as FAT32
   - Copy `user-data` file to USB root
   - Update: Tailscale auth key, repo URL, password hash
   - Boot mini PC from USB

3. **After first boot:**
   ```bash
   # Find hostname/IP in Tailscale admin console or:
   tailscale status  # on another device
   
   # SSH via Tailscale:
   ssh cosmocrat@edge-01
   
   # Configure & deploy:
   doppler login && doppler setup
   cd cosmocrat-core && ./ops/scripts/bootstrap.sh
   ```

📖 **See [USB-SETUP.md](USB-SETUP.md) for detailed cloud-init setup**

### Editing Files on edge-01

📝 **See [REMOTE-EDITING.md](REMOTE-EDITING.md) for how to edit files via SSH**

### Option B: Manual Setup (5 Steps)

#### 1. Clone & Enter Directory
```bash
git clone <your-repo-url>
cd cosmocrat-core
```

### 2. Install Prerequisites
```bash
# Install Doppler CLI
curl -sLf --retry 3 --tlsv1.2 --proto "=https" 'https://packages.doppler.com/public/cli/gpg.DE2A7741A397C129.key' | sudo apt-key add -
echo "deb https://packages.doppler.com/public/cli/deb/debian any-version main" | sudo tee /etc/apt/sources.list.d/doppler-cli.list
sudo apt-get update && sudo apt-get install doppler

# Install Docker (if needed)
sudo apt-get install -y docker.io docker-compose-plugin
sudo usermod -aG docker $USER
# Log out and back in
```

### 3. Configure Doppler
```bash
doppler login
doppler setup  # Select your project
```

### 4. Deploy Everything
```bash
chmod +x ops/scripts/*.sh

# Optional: Clean up old images first (prevents conflicts)
./ops/scripts/cleanup.sh

# Deploy everything (automatically cleans up old images)
./ops/scripts/bootstrap.sh
```

**Note:** 
- Bootstrap automatically cleans up old images before building
- Run `./ops/scripts/cleanup.sh --volumes` to also remove data volumes (fresh start, but loses all data)

### 5. Verify It's Green
```bash
./ops/scripts/healthcheck.sh
```

**That's it!** All services should be running green.

📖 **For detailed steps, see [DEPLOY.md](DEPLOY.md)**

### Deploy LLM Models (Optional)
After core services are healthy, deploy Codex, Claude, and Gemini models:

```bash
./ops/scripts/deploy-models.sh
```

Or auto-deploy after bootstrap:
```bash
DEPLOY_MODELS=true ./ops/scripts/bootstrap.sh
```

### CLI Access to LLM Services
To use CLI tools for Codex, Claude, or Gemini, set up authentication:

```bash
# Export credentials from Doppler to your shell
source ./ops/scripts/setup-cli-auth.sh

# Or use doppler run for one-time commands
doppler run -- python your_script.py
```

**⚠️ Important for Headless Systems:**
- **Codex CLI** requires browser OAuth (not headless-friendly)
- **Workaround:** Use OpenAI API with `OPENAI_API_KEY` instead
- See `ops/scripts/codex-headless-workaround.md` for details

**Note:** Codex, Claude, and Gemini use subscription-based authentication (Ultra/Pro subscriptions). Configure user credentials in Doppler:

**Subscription Access (Ultra/Pro subscriptions):**

**For OpenAI/Codex (headless systems):**
- `OPENAI_API_KEY` - **Recommended for headless** - Use API key directly
  - Note: Codex CLI requires browser OAuth (see [issue #3820](https://github.com/openai/codex/issues/3820))
  - Workaround: Use OpenAI API with API keys instead of Codex CLI
- `OPENAI_USER` + `OPENAI_PASSWORD` - For GUI-based authentication
- `CODEX_USER` + `CODEX_PASSWORD` - Alternative naming

**For Claude (Anthropic):**
- `ANTHROPIC_USER` + `ANTHROPIC_PASSWORD` - Subscription login
- `CLAUDE_USER` + `CLAUDE_PASSWORD` - Alternative naming
- `ANTHROPIC_API_KEY` or `ANTHROPIC_TOKEN` - API key fallback

**For Gemini (Google):**
- `GEMINI_USER` + `GEMINI_PASSWORD` - Subscription login
- `GOOGLE_USER` + `GOOGLE_PASSWORD` - Alternative naming
- `GEMINI_API_KEY` or `GEMINI_TOKEN` - API key fallback

Once configured in Doppler, these credentials are:
- ✅ Available to all Docker services via environment variables
- ✅ Accessible via CLI using `setup-cli-auth.sh` script
- ✅ Usable with `doppler run --` prefix for any command

## Core Services

All services start automatically with bootstrap:

- **Traefik** - Reverse proxy (http://ops.localhost:8888/traefik)
- **PostgreSQL** - Local pgvector database (port 5432)
- **Redis** - Cache and queue (port 6379)
- **Langfuse** - LLM observability (http://ops.localhost/langfuse)
- **Ollama** - Local LLM inference (http://ops.localhost/llm)
- **Edge-Orchestrator** - Main orchestration service (port 8000)
- **Confirm-Engine** - Confirmation service (port 8010)
- **Deploy-Memory** - Memory deployment service (port 8020)
- **MCP** - Model Context Protocol server (http://mcp.localhost)
- **Memory-Consolidator** - Daily memory consolidation job

## Optional Services (Profiles)

Enable additional services as needed:

### ClickHouse (Analytics)
```bash
doppler run -- docker compose --profile analytics up -d clickhouse
```

### n8n (Automation)
```bash
doppler run -- docker compose --profile automation up -d n8n
```

### Appsmith (Cockpit)
```bash
doppler run -- docker compose --profile cockpit up -d appsmith
```

## Required Doppler Secrets

Ensure these are set in your Doppler project:

### Database
- `DB_POSTGRESDB_USER` - PostgreSQL username (or `PG_USER`)
- `DB_POSTGRESDB_PASSWORD` - PostgreSQL password (or `PG_PASSWORD`)
- `PG_DB` - Database name (defaults to `cosmocrat`)

### Supabase (Remote)
- `SB_URL` - Supabase project URL
- `SB_ANON_KEY` - Supabase anonymous key
- `SB_POSTGRES_URL` - Direct Supabase Postgres connection (optional)

### Langfuse
- `NEXTAUTH_SECRET` - Langfuse authentication secret
- `LANGFUSE_BASE_URL` - Langfuse base URL (defaults to http://langfuse:3000)
- `LANGFUSE_PUBLIC_KEY` - Langfuse public API key (optional)
- `LANGFUSE_SECRET_KEY` - Langfuse secret API key (optional)
- `LANGFUSE_CACHE_BACKEND` - Cache backend (defaults to redis)
- `LANGFUSE_REDIS_URL` - Langfuse Redis URL (defaults to redis://redis:6379/3)

### Redis
- `REDIS_URL` - Override default Redis URL if needed (defaults to redis://redis:6379/0)

### ClickHouse (Optional)
- `CH_URL_PRIMARY` - Primary ClickHouse URL
- `CH_URL_FALLBACK` - Fallback ClickHouse URL

### LLM Authentication (Subscription-based - Ultra/Pro)
**Subscription Access (recommended):**
- `OPENAI_USER` + `OPENAI_PASSWORD` - OpenAI/Codex subscription credentials
- `ANTHROPIC_USER` + `ANTHROPIC_PASSWORD` - Anthropic/Claude subscription credentials
- `GEMINI_USER` + `GEMINI_PASSWORD` - Google/Gemini subscription credentials

**Alternative variable names:**
- `CODEX_USER` + `CODEX_PASSWORD` - Alternative for Codex/OpenAI
- `CLAUDE_USER` + `CLAUDE_PASSWORD` - Alternative for Claude
- `GOOGLE_USER` + `GOOGLE_PASSWORD` - Alternative for Gemini

**Token-based (fallback only):**
- `OPENAI_TOKEN` or `CODEX_TOKEN` - Token-based fallback
- `ANTHROPIC_TOKEN` or `CLAUDE_TOKEN` - Token-based fallback
- `GEMINI_TOKEN` or `GOOGLE_TOKEN` - Token-based fallback

### Other
- `SLACK_WEBHOOK_URL` - Slack webhook for notifications (optional)
- `MCP_TOKEN` - MCP service authentication token (optional)

## Redis Database Indices

Services use different Redis DB indices for isolation:

- **DB 0**: edge-orchestrator, mcp (default)
- **DB 1**: confirm-engine
- **DB 2**: deploy-memory
- **DB 3**: langfuse LangCache

## Notes

- Services use **local PostgreSQL (pgvector)** for vector operations
- Services can use **Supabase REST API** via `app/tools/supabase_client.py` for remote operations
- Supabase environment variables (`SB_URL`, `SB_ANON_KEY`) are available to all services
- Packs will be loaded post-deployment via subgits
- vLLM is disabled (commented out) - using Ollama for CPU inference instead

## Troubleshooting

### Services not starting
1. Check Doppler configuration: `doppler secrets`
2. Verify Docker is running: `docker ps`
3. Check service logs: `docker compose logs <service-name>`

### Healthcheck failures
Run individual healthchecks:
```bash
curl http://localhost:8000/health  # edge-orchestrator
curl http://localhost:8010/health  # confirm-engine
curl http://localhost:8020/health  # deploy-memory
curl http://localhost:8080/healthz # mcp
```

### Database connection issues
- Verify `DB_POSTGRESDB_USER` and `DB_POSTGRESDB_PASSWORD` are set in Doppler
- Check postgres container: `docker compose logs postgres`
- Test connection: `docker compose exec postgres psql -U $DB_POSTGRESDB_USER -d $PG_DB`
