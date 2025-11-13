#!/usr/bin/env bash
set -euo pipefail

echo "🔍 Langfuse Diagnostic Tool"
echo "=========================="
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
    echo "❌ Doppler CLI not found"
    exit 1
fi

echo "1️⃣ Checking Langfuse container status..."
doppler run -- docker compose ps langfuse || echo "⚠️  Langfuse container not found"

echo ""
echo "2️⃣ Checking Langfuse logs (last 50 lines)..."
doppler run -- docker compose logs --tail=50 langfuse || echo "⚠️  Could not fetch logs"

echo ""
echo "3️⃣ Checking Langfuse health endpoint..."
if doppler run -- docker compose exec -T langfuse curl -fsS http://localhost:3000/health 2>/dev/null; then
    echo "✅ Langfuse health check passed"
else
    echo "❌ Health check failed - Langfuse may not be ready or database not initialized"
fi

echo ""
echo "4️⃣ Checking database connection..."
doppler run -- docker compose exec -T langfuse env | grep DATABASE_URL || echo "⚠️  DATABASE_URL not set"

echo ""
echo "5️⃣ Checking postgres health..."
doppler run -- docker compose ps postgres | grep -q "Up" && echo "✅ Postgres is running" || echo "❌ Postgres is not running"

echo ""
echo "6️⃣ Checking redis health..."
doppler run -- docker compose ps redis | grep -q "Up" && echo "✅ Redis is running" || echo "❌ Redis is not running"

echo ""
echo "7️⃣ Checking Traefik routing..."
doppler run -- docker compose ps traefik | grep -q "Up" && echo "✅ Traefik is running" || echo "❌ Traefik is not running"

echo ""
echo "8️⃣ Testing direct port access..."
curl -fsS http://localhost:3000/health 2>/dev/null && echo "✅ Langfuse accessible on port 3000" || echo "❌ Cannot access Langfuse on port 3000"

echo ""
echo "9️⃣ Testing Traefik route..."
curl -fsS http://ops.localhost:8888/langfuse/health 2>/dev/null && echo "✅ Langfuse accessible via Traefik" || echo "❌ Cannot access Langfuse via Traefik"

echo ""
echo "🔟 Checking environment variables..."
doppler run -- docker compose exec -T langfuse env | grep -E "(DATABASE_URL|NEXTAUTH_SECRET|LANGFUSE)" | head -10

echo ""
echo "=========================="
echo "Diagnostic complete!"

