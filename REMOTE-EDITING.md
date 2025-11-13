# Editing Files on edge-01 via SSH

## Option 1: VS Code Remote SSH (Recommended)

### Setup (One-time)

1. **Install VS Code Remote SSH extension:**
   - Open VS Code
   - Extensions → Search "Remote - SSH"
   - Install

2. **Connect to edge-01:**
   - Press `F1` or `Ctrl+Shift+P`
   - Type: `Remote-SSH: Connect to Host`
   - Enter: `orion@edge-01` (or `cosmocrat@edge-01`)
   - VS Code will open a new window connected to the server

3. **Open folder:**
   - File → Open Folder
   - Navigate to: `/home/cosmocrat/cosmocrat-core`
   - Or: `/home/orion/cosmocrat-core` (depending on your user)

**Now you can edit files directly in VS Code!**

## Option 2: Command Line Editors (Quick Edits)

### Using nano (easiest)

```bash
ssh orion@edge-01
cd cosmocrat-core
nano docker-compose.yml
# Edit, then Ctrl+X to save, Y to confirm
```

### Using vim

```bash
ssh orion@edge-01
cd cosmocrat-core
vim docker-compose.yml
# Press 'i' to insert, edit, then Esc, type ':wq' to save and quit
```

## Option 3: Copy Files from Local (Windows) to Remote

### Using scp (single file)

```powershell
# From Windows PowerShell in your local repo
scp docker-compose.yml orion@edge-01:~/cosmocrat-core/
```

### Using rsync (entire directory - better for multiple files)

```powershell
# Install rsync for Windows or use WSL
# From WSL or Git Bash:
rsync -avz --exclude '.git' ./ orion@edge-01:~/cosmocrat-core/
```

## Option 4: Git Workflow (Best for Code Changes)

### Push from local, pull on remote

```bash
# On your local Windows machine:
git add .
git commit -m "Update docker-compose.yml"
git push

# Then SSH to edge-01:
ssh orion@edge-01
cd cosmocrat-core
git pull
```

### Or: Edit on remote, commit and push

```bash
ssh orion@edge-01
cd cosmocrat-core
nano docker-compose.yml  # Make changes
git add docker-compose.yml
git commit -m "Fix Langfuse config"
git push
```

## Option 5: VS Code Remote Tunnels (No SSH Config Needed)

1. **On edge-01:**
   ```bash
   # Install VS Code Server
   curl -Lk 'https://code.visualstudio.com/sha/download?build=stable&os=cli-alpine-x64' --output vscode_cli.tar.gz
   tar -xf vscode_cli.tar.gz
   
   # Start tunnel
   ./code tunnel --name edge-01
   ```

2. **In VS Code on Windows:**
   - Remote Explorer → Tunnels
   - Connect to edge-01

## Quick Reference: Common Edits

### Edit docker-compose.yml

```bash
ssh orion@edge-01
cd cosmocrat-core
nano docker-compose.yml
# Make changes, Ctrl+X, Y, Enter
doppler run -- docker compose up -d  # Restart services
```

### Edit a script

```bash
ssh orion@edge-01
cd cosmocrat-core/ops/scripts
nano langfuse-fix.sh
chmod +x langfuse-fix.sh  # Make executable if needed
```

### Edit user-data (cloud-init)

```bash
ssh orion@edge-01
sudo nano /var/lib/cloud/seed/nocloud/user-data
# Or if editing for next deployment:
nano ~/user-data
```

## Recommended Workflow

**For development:**
1. Use VS Code Remote SSH (Option 1) - best experience
2. Edit files directly in VS Code
3. Commit changes via VS Code terminal
4. Push to git

**For quick fixes:**
1. SSH and use nano
2. Make quick edit
3. Restart services

**For bulk updates:**
1. Edit locally on Windows
2. Push to git
3. Pull on edge-01

## VS Code Remote SSH Setup (Detailed)

### Step 1: Configure SSH Config

On Windows, edit `C:\Users\YourName\.ssh\config`:

```
Host edge-01
    HostName edge-01.tail7db2d7.ts.net
    User orion
    IdentityFile ~/.ssh/id_rsa
```

Or if using Tailscale hostname:
```
Host edge-01
    HostName edge-01
    User orion
```

### Step 2: Connect

1. VS Code → `F1` → `Remote-SSH: Connect to Host`
2. Select `edge-01`
3. Enter password (or use SSH keys)
4. Open folder: `/home/orion/cosmocrat-core`

### Step 3: Install Extensions on Remote

VS Code will prompt to install extensions on the remote server. Install:
- Docker
- YAML
- Bash IDE
- GitLens

## Troubleshooting

**Can't connect via VS Code Remote SSH?**
- Check SSH works: `ssh orion@edge-01`
- Check Tailscale: `tailscale status` on your Windows machine
- Try IP instead of hostname

**Files not syncing?**
- Use git push/pull workflow
- Or use scp/rsync for manual sync

**Permission denied?**
- Check file ownership: `ls -la`
- May need sudo for some files
- Check user: `whoami`

