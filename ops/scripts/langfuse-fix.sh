#!/usr/bin/env bash
set -euo pipefail

echo "🔧 Langfuse Fix Script"
echo "====================="
echo ""

# Find project root (where docker-compose.yml is)
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"

# Change to project root
cd "$PROJECT_ROOT"

if [ ! -f "docker-compose.yml" ]; then
    echo "❌ docker-compose.yml not found in $PROJECT_ROOT"
    echo "   Please run this script from the cosmocrat-core directory"
    exit 1
fi

echo "📁 Working directory: $PROJECT_ROOT"
echo ""

# Check if Doppler is configured
if ! command -v doppler &> /dev/null; then
    echo "❌ Doppler CLI not found. Please run: doppler login && doppler setup"
    exit 1
fi

echo "1️⃣ Stopping Langfuse..."
doppler run -- docker compose stop langfuse || true

echo ""
echo "2️⃣ Checking database connection..."
DB_URL=$(doppler secrets get DATABASE_URL --plain 2>/dev/null || echo "")
if [ -z "$DB_URL" ]; then
    echo "⚠️  DATABASE_URL not in Doppler, using fallback from docker-compose.yml"
    echo "   Make sure DB_POSTGRESDB_USER, DB_POSTGRESDB_PASSWORD, PG_DB are set in Doppler"
else
    echo "✅ DATABASE_URL found in Doppler"
fi

echo ""
echo "3️⃣ Checking NEXTAUTH_SECRET..."
if doppler secrets get NEXTAUTH_SECRET --plain &>/dev/null; then
    echo "✅ NEXTAUTH_SECRET found"
else
    echo "⚠️  NEXTAUTH_SECRET not set in Doppler"
    echo "   Generating one now..."
    NEXTAUTH_SECRET=$(openssl rand -base64 32)
    echo "   Add this to Doppler: NEXTAUTH_SECRET=$NEXTAUTH_SECRET"
    echo "   Or run: doppler secrets set NEXTAUTH_SECRET='$NEXTAUTH_SECRET'"
fi

echo ""
echo "4️⃣ Waiting for postgres to be ready..."
doppler run -- docker compose up -d postgres
sleep 5
until doppler run -- docker compose exec -T postgres pg_isready &>/dev/null; do
    echo "   Waiting for postgres..."
    sleep 2
done
echo "✅ Postgres is ready"

echo ""
echo "5️⃣ Waiting for redis to be ready..."
doppler run -- docker compose up -d redis
sleep 3
until doppler run -- docker compose exec -T redis redis-cli ping &>/dev/null; do
    echo "   Waiting for redis..."
    sleep 2
done
echo "✅ Redis is ready"

echo ""
echo "6️⃣ Starting Langfuse (this may take a few minutes for first-time DB migration)..."
doppler run -- docker compose up -d langfuse

echo ""
echo "7️⃣ Waiting for Langfuse to initialize (checking logs)..."
echo "   This can take 1-2 minutes on first run for database migrations"
for i in {1..60}; do
    if curl -fsS http://localhost:3000/health &>/dev/null; then
        echo "✅ Langfuse is healthy!"
        break
    fi
    if [ $i -eq 60 ]; then
        echo "⚠️  Langfuse health check timed out after 60 seconds"
        echo "   Checking logs..."
        doppler run -- docker compose logs --tail=50 langfuse
        exit 1
    fi
    echo -n "."
    sleep 2
done

echo ""
echo "8️⃣ Testing access..."
if curl -fsS http://localhost:3000/health &>/dev/null; then
    echo "✅ Langfuse accessible on http://localhost:3000"
else
    echo "❌ Cannot access Langfuse on port 3000"
fi

if curl -fsS http://ops.localhost:8888/langfuse/health &>/dev/null; then
    echo "✅ Langfuse accessible via Traefik: http://ops.localhost:8888/langfuse"
else
    echo "⚠️  Cannot access Langfuse via Traefik (check Traefik is running)"
fi

echo ""
echo "=========================="
echo "✅ Langfuse fix complete!"
echo ""
echo "Access Langfuse at:"
echo "  - Direct: http://localhost:3000"
echo "  - Via Traefik: http://ops.localhost:8888/langfuse"
echo ""
echo "If still having issues, check logs:"
echo "  doppler run -- docker compose logs -f langfuse"

