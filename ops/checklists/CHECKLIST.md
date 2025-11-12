# Deployment Checklist

Follow this checklist step-by-step to ensure everything works.

## Pre-Deployment

- [ ] Headless Ubuntu server is set up
- [ ] You have SSH access to the server
- [ ] Tailscale is installed (optional but recommended)
- [ ] Doppler account is set up
- [ ] Doppler project has all required secrets

## Step-by-Step Deployment

### Step 1: Clone Repository
```bash
git clone <your-repo-url>
cd cosmocrat-core
```
- [ ] Repository cloned successfully
- [ ] You're in the `cosmocrat-core` directory

### Step 2: Install Doppler CLI
```bash
curl -sLf --retry 3 --tlsv1.2 --proto "=https" 'https://packages.doppler.com/public/cli/gpg.DE2A7741A397C129.key' | sudo apt-key add -
echo "deb https://packages.doppler.com/public/cli/deb/debian any-version main" | sudo tee /etc/apt/sources.list.d/doppler-cli.list
sudo apt-get update && sudo apt-get install doppler
```
- [ ] Doppler CLI installed
- [ ] Verify: `doppler --version` works

### Step 3: Install Docker
```bash
sudo apt-get install -y docker.io docker-compose-plugin
sudo usermod -aG docker $USER
# Log out and back in, then verify:
docker --version
docker compose version
```
- [ ] Docker installed
- [ ] Docker Compose installed
- [ ] User added to docker group
- [ ] Logged out and back in
- [ ] Can run `docker ps` without sudo

### Step 4: Configure Doppler
```bash
doppler login
doppler setup
```
- [ ] Logged into Doppler
- [ ] Project selected with `doppler setup`
- [ ] Can see secrets: `doppler secrets`

### Step 5: Verify Required Secrets
```bash
doppler secrets get DB_POSTGRESDB_USER --plain
doppler secrets get DB_POSTGRESDB_PASSWORD --plain
doppler secrets get NEXTAUTH_SECRET --plain
```
- [ ] `DB_POSTGRESDB_USER` is set
- [ ] `DB_POSTGRESDB_PASSWORD` is set
- [ ] `NEXTAUTH_SECRET` is set (generate with: `openssl rand -hex 32`)

### Step 6: Make Scripts Executable
```bash
chmod +x ops/scripts/*.sh
```
- [ ] All scripts are executable
- [ ] Verify: `ls -la ops/scripts/*.sh` shows executable permissions

### Step 7: Run Bootstrap
```bash
./ops/scripts/bootstrap.sh
```
- [ ] Bootstrap script runs without errors
- [ ] All services build successfully
- [ ] All services start successfully
- [ ] Healthchecks pass
- [ ] You see "✅ All core services are healthy!"

### Step 8: Run Healthcheck
```bash
./ops/scripts/healthcheck.sh
```
- [ ] All services show "✓ OK"
- [ ] No services show "✗ FAILED"
- [ ] You see "✅ All services are healthy!"

### Step 9: Test Services
```bash
# Test from server
curl http://localhost:8000/health
curl http://localhost:8010/health
curl http://localhost:8020/health
curl http://localhost:8080/healthz
```
- [ ] Edge-Orchestrator responds: `{"ok":true,"service":"edge-orchestrator"}`
- [ ] Confirm-Engine responds: `{"ok":true,"service":"confirm-engine"}`
- [ ] Deploy-Memory responds: `{"ok":true,"service":"deploy-memory"}`
- [ ] MCP responds: `{"ok":true,"service":"mcp"}`

### Step 10: Access Remotely (Choose One)

**Option A: Via Tailscale**
- [ ] Tailscale is running on server
- [ ] Tailscale IP: `tailscale ip -4`
- [ ] Can access: `http://<tailscale-ip>:8000/health`

**Option B: Via SSH Port Forwarding**
```bash
# On your local machine
./ops/scripts/ssh-forward.sh user@server-ip
```
- [ ] SSH port forwarding works
- [ ] Can access: `http://localhost:8000/health`

## Post-Deployment (Optional)

- [ ] Deploy LLM models: `./ops/scripts/deploy-models.sh`
- [ ] Load packs via subgits
- [ ] Configure Terraform

## If Something Fails

1. **Check logs:**
   ```bash
   doppler run -- docker compose logs <service-name>
   ```

2. **Check service status:**
   ```bash
   doppler run -- docker compose ps
   ```

3. **Restart a service:**
   ```bash
   doppler run -- docker compose restart <service-name>
   ```

4. **Full restart:**
   ```bash
   doppler run -- docker compose down
   doppler run -- docker compose up -d
   ```

## Success Criteria

✅ All 9 core services running  
✅ All healthchecks passing  
✅ Can access services remotely  
✅ Ready to load packs  

**You're done!** 🎉

