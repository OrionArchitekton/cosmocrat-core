# Langfuse Connection Fix Guide

## Quick Fix

Run this from **anywhere** (the script will find the project):

```bash
cd ~/cosmocrat-core
./ops/scripts/langfuse-fix.sh
```

Or if you're already in the project:

```bash
./ops/scripts/langfuse-fix.sh
```

## Manual Steps (if script doesn't work)

### 1. Make sure you're in the right directory

```bash
cd ~/cosmocrat-core
# or wherever you cloned the repo
ls docker-compose.yml  # Should show the file
```

### 2. Check Doppler is configured

```bash
doppler secrets get DATABASE_URL --plain
doppler secrets get NEXTAUTH_SECRET --plain
```

### 3. Check postgres and redis are running

```bash
doppler run -- docker compose ps postgres redis
```

### 4. Restart Langfuse

```bash
doppler run -- docker compose restart langfuse
```

### 5. Check logs

```bash
doppler run -- docker compose logs -f langfuse
```

Look for:
- Database connection errors
- Migration errors
- Port binding issues

### 6. Test health endpoint

```bash
curl http://localhost:3000/health
```

## Common Issues

### "no configuration file provided"
- **Fix:** Make sure you're in the directory with `docker-compose.yml`
- **Fix:** Run: `cd ~/cosmocrat-core` first

### Database connection errors
- **Check:** `doppler secrets get DATABASE_URL --plain`
- **Check:** Postgres is running: `doppler run -- docker compose ps postgres`
- **Fix:** Ensure `DB_POSTGRESDB_USER`, `DB_POSTGRESDB_PASSWORD`, `PG_DB` are set in Doppler

### NEXTAUTH_SECRET missing
- **Fix:** Generate one: `openssl rand -base64 32`
- **Fix:** Add to Doppler: `doppler secrets set NEXTAUTH_SECRET='your-secret-here'`

### Port 3000 already in use
- **Check:** `sudo lsof -i :3000`
- **Fix:** Stop whatever is using port 3000, or change Langfuse port in docker-compose.yml

### Langfuse won't start
- **Check logs:** `doppler run -- docker compose logs langfuse`
- **Check:** Database migrations may be running (first startup takes 1-2 minutes)
- **Wait:** Give it 2-3 minutes on first run

## Access Langfuse

Once fixed, access at:
- **Direct:** http://localhost:3000
- **Via Traefik:** http://ops.localhost:8888/langfuse

## Still Having Issues?

Run the diagnostic script:

```bash
./ops/scripts/langfuse-diagnose.sh
```

This will show you exactly what's wrong.

