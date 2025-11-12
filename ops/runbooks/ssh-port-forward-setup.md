# SSH Port Forwarding Setup for Headless Ubuntu

## Common Issues & Solutions

### Issue 1: SSH Server Not Allowing Port Forwarding

**Check SSH server config:**
```bash
# On headless Ubuntu server
sudo nano /etc/ssh/sshd_config

# Ensure these are set:
AllowTcpForwarding yes
GatewayPorts yes  # Optional: allows binding to 0.0.0.0
PermitTunnel yes   # Optional: for advanced forwarding

# Restart SSH
sudo systemctl restart sshd
```

### Issue 2: Services Bound to localhost Only

**Check if services are accessible:**
```bash
# On headless server, check what's listening
sudo netstat -tlnp | grep -E '8000|8010|8020|8080|8888'

# If services show 127.0.0.1:PORT, they're localhost-only
# If they show 0.0.0.0:PORT, they're accessible remotely
```

**Our docker-compose.yml binds to 0.0.0.0, so this should be fine.**

### Issue 3: Firewall Blocking Ports

**On Ubuntu (UFW):**
```bash
# Check firewall status
sudo ufw status

# Allow SSH
sudo ufw allow 22/tcp

# Allow Docker ports (if needed for direct access)
sudo ufw allow 8000/tcp
sudo ufw allow 8010/tcp
sudo ufw allow 8020/tcp
sudo ufw allow 8080/tcp
sudo ufw allow 8888/tcp

# Or allow Docker subnet
sudo ufw allow from 172.17.0.0/16
```

### Issue 4: SSH Port Forwarding Command Syntax

**Correct syntax:**
```bash
# Forward single port
ssh -L 8000:localhost:8000 user@headless-server

# Forward multiple ports
ssh -L 8000:localhost:8000 \
    -L 8010:localhost:8010 \
    -L 8020:localhost:8020 \
    -L 8080:localhost:8080 \
    -L 8888:localhost:8888 \
    user@headless-server

# Keep connection alive
ssh -L 8000:localhost:8000 -o ServerAliveInterval=60 user@headless-server

# Background with nohup
nohup ssh -L 8000:localhost:8000 -N user@headless-server &
```

### Issue 5: Docker Services Not Accessible from Host

**Check Docker network:**
```bash
# On headless server
docker compose ps
docker compose logs <service-name>

# Test from server itself
curl http://localhost:8000/health
curl http://localhost:8010/health
```

### Issue 6: SSH Client Configuration

**Create SSH config (~/.ssh/config):**
```
Host headless-cosmocrat
    HostName <your-server-ip>
    User <your-username>
    LocalForward 8000 localhost:8000
    LocalForward 8010 localhost:8010
    LocalForward 8020 localhost:8020
    LocalForward 8080 localhost:8080
    LocalForward 8888 localhost:8888
    ServerAliveInterval 60
    ServerAliveCountMax 3
```

Then connect:
```bash
ssh headless-cosmocrat
```

## Quick Test

**On your local machine:**
```bash
# Test SSH connection first
ssh user@headless-server "echo 'SSH works'"

# Test port forwarding
ssh -L 8000:localhost:8000 -N user@headless-server &
curl http://localhost:8000/health

# Should return: {"ok":true,"service":"edge-orchestrator"}
```

## Troubleshooting Steps

1. **Verify SSH works:**
   ```bash
   ssh user@headless-server
   ```

2. **Check if services are running:**
   ```bash
   ssh user@headless-server "docker compose ps"
   ```

3. **Test services from server:**
   ```bash
   ssh user@headless-server "curl http://localhost:8000/health"
   ```

4. **Try port forwarding:**
   ```bash
   ssh -L 8000:localhost:8000 user@headless-server
   # In another terminal:
   curl http://localhost:8000/health
   ```

5. **Check for errors:**
   ```bash
   # Look for "bind: address already in use" - port already forwarded
   # Look for "Permission denied" - SSH config issue
   # Look for "Connection refused" - service not running or firewall
   ```

## Recommended Setup for Headless Deployment

Since you're deploying to headless Ubuntu, consider:

1. **Use SSH port forwarding for development/testing**
2. **Use Tailscale/VPN for production** (you mentioned Tailscale)
3. **Or expose ports directly** (with proper firewall rules)

For production, Tailscale is probably better than SSH port forwarding.

