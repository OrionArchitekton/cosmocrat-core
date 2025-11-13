#!/usr/bin/env bash
set -euo pipefail

# Find project root
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
cd "$PROJECT_ROOT"

echo "🔧 Langfuse Quick Fix"
echo "===================="
echo ""

# Check Doppler
if ! command -v doppler &> /dev/null; then
    echo "❌ Doppler not found"
    exit 1
fi

echo "1️⃣ Stopping Langfuse..."
doppler run -- docker compose stop langfuse 2>/dev/null || true

echo ""
echo "2️⃣ Checking required secrets..."

# Check DATABASE_URL (try --plain first, fallback to regular get)
DB_URL=$(doppler secrets get DATABASE_URL --plain 2>/dev/null || doppler secrets get DATABASE_URL 2>/dev/null | grep -v "^┌" | grep -v "^│" | grep -v "^└" | grep -v "^├" | tail -1 | awk '{print $2}' || echo "")

if [ -z "$DB_URL" ]; then
    # Try checking for individual DB components
    if doppler secrets get DB_POSTGRESDB_USER --plain &>/dev/null || doppler secrets get DB_POSTGRESDB_USER &>/dev/null; then
        echo "✅ Database credentials found (using DB_POSTGRESDB_USER)"
    else
        echo "⚠️  DATABASE_URL not found, but docker-compose.yml has fallback"
    fi
else
    echo "✅ DATABASE_URL found"
fi

# Check NEXTAUTH_SECRET
AUTH_SECRET=$(doppler secrets get NEXTAUTH_SECRET --plain 2>/dev/null || doppler secrets get NEXTAUTH_SECRET 2>/dev/null | grep -v "^┌" | grep -v "^│" | grep -v "^└" | grep -v "^├" | tail -1 | awk '{print $2}' || echo "")

if [ -z "$AUTH_SECRET" ]; then
    echo "⚠️  NEXTAUTH_SECRET not found - generating one..."
    SECRET=$(openssl rand -base64 32 2>/dev/null || head -c 32 /dev/urandom | base64)
    echo "   Setting in Doppler..."
    doppler secrets set NEXTAUTH_SECRET="$SECRET" 2>/dev/null || echo "   Run manually: doppler secrets set NEXTAUTH_SECRET='$SECRET'"
else
    echo "✅ NEXTAUTH_SECRET found"  
fi

echo "✅ Secrets check complete"

echo ""
echo "3️⃣ Starting dependencies..."
# Start all Langfuse dependencies
doppler run -- docker compose up -d postgres redis minio clickhouse 2>/dev/null || \
doppler run -- docker compose up -d postgres redis
sleep 5

echo ""
echo "4️⃣ Checking postgres..."
for i in {1..30}; do
    if doppler run -- docker compose exec -T postgres pg_isready &>/dev/null; then
        echo "✅ Postgres ready"
        break
    fi
    [ $i -eq 30 ] && echo "❌ Postgres not ready" && exit 1
    sleep 1
done

echo ""
echo "5️⃣ Checking redis..."
for i in {1..30}; do
    if doppler run -- docker compose exec -T redis redis-cli ping &>/dev/null; then
        echo "✅ Redis ready"
        break
    fi
    [ $i -eq 30 ] && echo "❌ Redis not ready" && exit 1
    sleep 1
done

echo ""
echo "6️⃣ Starting Langfuse services..."
# Start langfuse-worker first, then langfuse
doppler run -- docker compose up -d langfuse-worker langfuse 2>/dev/null || \
doppler run -- docker compose up -d langfuse

echo ""
echo "7️⃣ Waiting for Langfuse (this may take 2-3 minutes for DB migrations)..."
for i in {1..120}; do
    if curl -fsS http://localhost:3000/health &>/dev/null 2>&1; then
        echo ""
        echo "✅ Langfuse is UP!"
        echo ""
        echo "Access at:"
        echo "  - http://localhost:3000"
        echo "  - http://ops.localhost:8888/langfuse"
        exit 0
    fi
    if [ $((i % 10)) -eq 0 ]; then
        echo "   Still waiting... ($i/120 seconds)"
        echo "   Checking logs..."
        doppler run -- docker compose logs --tail=5 langfuse 2>/dev/null | tail -3
    fi
    sleep 2
done

echo "" 
echo "❌ Langfuse didn't start after 2 minutes"
echo ""
echo "Checking logs..."
doppler run -- docker compose logs --tail=50 langfuse

echo ""
echo "Common issues:"
echo "  - Database connection failed (check DATABASE_URL)"
echo "  - Database migrations failed (check postgres logs)"
echo "  - Port 3000 in use (check: sudo lsof -i :3000)"
echo ""
echo "Try: doppler run -- docker compose logs -f langfuse"

