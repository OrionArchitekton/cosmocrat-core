# Langfuse Debugging - Step by Step

## Run These Commands on edge-01

### Step 1: Check Current Status

```bash
cd ~/cosmocrat-core
doppler run -- docker compose ps langfuse
doppler run -- docker compose ps postgres redis
```

### Step 2: Check Logs

```bash
# Langfuse logs
doppler run -- docker compose logs --tail=100 langfuse

# Postgres logs
doppler run -- docker compose logs --tail=50 postgres

# Redis logs  
doppler run -- docker compose logs --tail=50 redis
```

### Step 3: Check Environment Variables

```bash
# Check what Langfuse sees
doppler run -- docker compose exec langfuse env | grep -E "(DATABASE|NEXTAUTH|LANGFUSE)"
```

### Step 4: Test Database Connection

```bash
# Test postgres connection
doppler run -- docker compose exec postgres psql -U $(doppler secrets get DB_POSTGRESDB_USER --plain) -d $(doppler secrets get PG_DB --plain) -c "SELECT 1;"
```

### Step 5: Check Port Availability

```bash
# Check if port 3000 is in use
sudo lsof -i :3000
# or
sudo netstat -tlnp | grep 3000
```

### Step 6: Try Quick Fix Script

```bash
cd ~/cosmocrat-core
chmod +x ops/scripts/langfuse-quick-fix.sh
./ops/scripts/langfuse-quick-fix.sh
```

## Common Errors & Fixes

### Error: "Cannot connect to database"

**Check:**
```bash
doppler secrets get DATABASE_URL --plain
doppler secrets get DB_POSTGRESDB_USER --plain
doppler secrets get DB_POSTGRESDB_PASSWORD --plain
doppler secrets get PG_DB --plain
```

**Fix:** Make sure all database variables are set in Doppler

### Error: "NEXTAUTH_SECRET is required"

**Fix:**
```bash
# Generate secret
SECRET=$(openssl rand -base64 32)
doppler secrets set NEXTAUTH_SECRET="$SECRET"
```

### Error: "Port 3000 already in use"

**Fix:**
```bash
# Find what's using port 3000
sudo lsof -i :3000
# Kill it or change Langfuse port in docker-compose.yml
```

### Error: "Database migrations failed"

**Fix:**
```bash
# Check postgres is healthy
doppler run -- docker compose exec postgres pg_isready

# Check database exists
doppler run -- docker compose exec postgres psql -U $(doppler secrets get DB_POSTGRESDB_USER --plain) -l

# Restart Langfuse (migrations run on startup)
doppler run -- docker compose restart langfuse
```

### Error: "Connection refused" on health check

**Check:**
```bash
# Is Langfuse container running?
doppler run -- docker compose ps langfuse

# Check logs for startup errors
doppler run -- docker compose logs langfuse | grep -i error
```

## Manual Restart Process

```bash
cd ~/cosmocrat-core

# Stop everything
doppler run -- docker compose stop langfuse

# Start dependencies
doppler run -- docker compose up -d postgres redis
sleep 5

# Start Langfuse
doppler run -- docker compose up -d langfuse

# Watch logs
doppler run -- docker compose logs -f langfuse
```

## Test Access

```bash
# Direct port
curl -v http://localhost:3000/health

# Via Traefik
curl -v http://ops.localhost:8888/langfuse/health

# Check container health
doppler run -- docker compose exec langfuse curl http://localhost:3000/health
```

## Still Not Working?

**Share these outputs:**

```bash
# 1. Container status
doppler run -- docker compose ps

# 2. Langfuse logs (last 50 lines)
doppler run -- docker compose logs --tail=50 langfuse

# 3. Environment check
doppler run -- docker compose exec langfuse env | grep -E "(DATABASE|NEXTAUTH)" | head -5

# 4. Port check
curl -v http://localhost:3000/health 2>&1 | head -20
```

