#!/usr/bin/env bash
set -euo pipefail

# Find project root
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
cd "$PROJECT_ROOT"

echo "🔍 Langfuse Status Check"
echo "======================="
echo ""

# Check Doppler
if ! command -v doppler &> /dev/null; then
    echo "❌ Doppler not found"
    exit 1
fi

echo "📦 Container Status:"
doppler run -- docker compose ps | grep -E "(langfuse|postgres|redis|minio|clickhouse)" || echo "No containers found"

echo ""
echo "🔐 Required Secrets Check:"
echo ""

# Check DATABASE_URL
if doppler secrets get DATABASE_URL --plain &>/dev/null; then
    echo "✅ DATABASE_URL: Set"
else
    echo "❌ DATABASE_URL: Missing"
    echo "   Need: DB_POSTGRESDB_USER, DB_POSTGRESDB_PASSWORD, PG_DB"
fi

# Check NEXTAUTH_SECRET
if doppler secrets get NEXTAUTH_SECRET --plain &>/dev/null; then
    echo "✅ NEXTAUTH_SECRET: Set"
else
    echo "❌ NEXTAUTH_SECRET: Missing"
fi

# Check SALT
if doppler secrets get SALT --plain &>/dev/null; then
    echo "✅ SALT: Set"
else
    echo "⚠️  SALT: Not set (using default)"
fi

# Check ENCRYPTION_KEY
if doppler secrets get ENCRYPTION_KEY --plain &>/dev/null; then
    echo "✅ ENCRYPTION_KEY: Set"
else
    echo "❌ ENCRYPTION_KEY: Missing (CRITICAL - generate one!)"
fi

# Check ClickHouse (if needed)
if doppler secrets get CLICKHOUSE_PASSWORD --plain &>/dev/null; then
    echo "✅ CLICKHOUSE_PASSWORD: Set"
else
    echo "⚠️  CLICKHOUSE_PASSWORD: Not set (using default)"
fi

# Check Redis Auth
if doppler secrets get REDIS_AUTH --plain &>/dev/null; then
    echo "✅ REDIS_AUTH: Set"
else
    echo "⚠️  REDIS_AUTH: Not set (using default)"
fi

echo ""
echo "📋 Recent Logs (last 20 lines):"
echo "--- Langfuse ---"
doppler run -- docker compose logs --tail=20 langfuse 2>/dev/null || echo "No logs"

echo ""
echo "🌐 Health Check:"
if curl -fsS http://localhost:3000/health &>/dev/null 2>&1; then
    echo "✅ Langfuse responding on port 3000"
else
    echo "❌ Langfuse NOT responding on port 3000"
fi

echo ""
echo "💡 Next Steps:"
echo "  1. Check logs: doppler run -- docker compose logs -f langfuse"
echo "  2. Check all services: doppler run -- docker compose ps"
echo "  3. Restart: doppler run -- docker compose restart langfuse"

