# Simple Deployment Guide - Headless Ubuntu

Follow these steps exactly to get everything running green.

## Step 1: Clone the Repository

```bash
git clone <your-repo-url>
cd cosmocrat-core
```

## Step 2: Install Prerequisites

```bash
# Install Doppler CLI
curl -sLf --retry 3 --tlsv1.2 --proto "=https" 'https://packages.doppler.com/public/cli/gpg.DE2A7741A397C129.key' | sudo apt-key add -
echo "deb https://packages.doppler.com/public/cli/deb/debian any-version main" | sudo tee /etc/apt/sources.list.d/doppler-cli.list
sudo apt-get update && sudo apt-get install doppler

# Install Docker & Docker Compose (if not already installed)
sudo apt-get update
sudo apt-get install -y docker.io docker-compose-plugin
sudo usermod -aG docker $USER
# Log out and back in for group changes to take effect
```

## Step 3: Configure Doppler

```bash
# Login to Doppler
doppler login

# Setup your project (use your Doppler project name)
doppler setup

# Verify it works
doppler secrets
```

## Step 4: Add Required Secrets to Doppler

Make sure these are set in your Doppler project:

**Required:**
- `DB_POSTGRESDB_USER` - PostgreSQL username
- `DB_POSTGRESDB_PASSWORD` - PostgreSQL password
- `PG_DB` - Database name (or defaults to "cosmocrat")
- `NEXTAUTH_SECRET` - Langfuse secret (generate with: `openssl rand -hex 32`)

**Optional but recommended:**
- `SB_URL` - Supabase URL
- `SB_ANON_KEY` - Supabase anonymous key
- `OPENAI_API_KEY` - OpenAI API key (for headless access)
- `ANTHROPIC_USER` + `ANTHROPIC_PASSWORD` - Claude subscription
- `GEMINI_USER` + `GEMINI_PASSWORD` - Gemini subscription

## Step 5: Deploy Everything

```bash
# Make scripts executable
chmod +x ops/scripts/*.sh

# Run bootstrap (builds and starts everything)
./ops/scripts/bootstrap.sh
```

This will:
- ✅ Check Doppler is configured
- ✅ Build all Docker images
- ✅ Start all services
- ✅ Wait for healthchecks
- ✅ Show you status

## Step 6: Verify Everything is Green

```bash
# Run healthcheck
./ops/scripts/healthcheck.sh
```

You should see:
```
✓ PostgreSQL: OK
✓ Redis: OK
✓ Langfuse: OK
✓ Ollama: OK
✓ Edge-Orchestrator: OK
✓ Confirm-Engine: OK
✓ Deploy-Memory: OK
✓ MCP: OK
✓ Memory-Consolidator: OK
✅ All services are healthy!
```

## Step 7: Access Services

**Via Tailscale (recommended):**
- Traefik: `http://<tailscale-ip>:8888/traefik`
- Langfuse: `http://<tailscale-ip>:3000`
- Edge-Orchestrator: `http://<tailscale-ip>:8000`
- Confirm-Engine: `http://<tailscale-ip>:8010`
- Deploy-Memory: `http://<tailscale-ip>:8020`
- MCP: `http://<tailscale-ip>:8080`

**Via SSH Port Forwarding (alternative):**
```bash
# On your local machine
./ops/scripts/ssh-forward.sh user@your-server-ip

# Then access via localhost:
# http://localhost:8000/health
# http://localhost:8010/health
# etc.
```

## Troubleshooting

**Services not starting?**
```bash
# Check logs
docker compose logs <service-name>

# Restart a service
doppler run -- docker compose restart <service-name>
```

**Healthcheck failing?**
```bash
# Check individual service
curl http://localhost:8000/health

# Check Docker status
doppler run -- docker compose ps
```

**Port conflicts?**
- Traefik uses port 8888 (changed from 80 due to Tailscale)
- If you need different ports, edit `docker-compose.yml`

## Next Steps

After everything is green:
1. Deploy LLM models (optional): `./ops/scripts/deploy-models.sh`
2. Load packs via subgits (as planned)
3. Configure Terraform (as planned)

## Quick Reference

```bash
# Start services
doppler run -- docker compose up -d

# Stop services
doppler run -- docker compose down

# View logs
doppler run -- docker compose logs -f

# Restart everything
doppler run -- docker compose restart

# Full rebuild
doppler run -- docker compose build --no-cache
doppler run -- docker compose up -d
```

