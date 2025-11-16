#!/usr/bin/env bash
set -euo pipefail

# Find project root
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
cd "$PROJECT_ROOT"

echo "🔧 Langfuse Simple Fix"
echo "====================="
echo ""

# Check Doppler
if ! command -v doppler &> /dev/null; then
    echo "❌ Doppler not found"
    exit 1
fi

echo "1️⃣ Stopping Langfuse..."
doppler run -- docker compose stop langfuse langfuse-worker 2>/dev/null || true

echo ""
echo "2️⃣ Starting all dependencies..."
# Start everything Langfuse needs
doppler run -- docker compose up -d postgres redis minio clickhouse 2>/dev/null || \
doppler run -- docker compose up -d postgres redis

echo ""
echo "3️⃣ Waiting for dependencies (30 seconds)..."
sleep 30

echo ""
echo "4️⃣ Starting Langfuse..."
doppler run -- docker compose up -d langfuse-worker langfuse 2>/dev/null || \
doppler run -- docker compose up -d langfuse

echo ""
echo "5️⃣ Waiting for Langfuse to start..."
echo "   (This can take 2-3 minutes for database migrations)"
echo ""

for i in {1..180}; do
    if curl -fsS http://localhost:3000/health &>/dev/null 2>&1; then
        echo ""
        echo "✅ Langfuse is UP!"
        echo ""
        echo "Access at:"
        echo "  - http://localhost:3000"
        echo "  - http://ops.localhost:8888/langfuse"
        exit 0
    fi
    
    if [ $((i % 15)) -eq 0 ]; then
        echo "   Still waiting... ($i/180 seconds)"
        echo "   Recent logs:"
        doppler run -- docker compose logs --tail=3 langfuse 2>/dev/null | tail -2 || echo "   (checking...)"
    fi
    sleep 2
done

echo ""
echo "❌ Langfuse didn't start after 3 minutes"
echo ""
echo "Checking status..."
doppler run -- docker compose ps langfuse langfuse-worker

echo ""
echo "Recent logs:"
doppler run -- docker compose logs --tail=30 langfuse

echo ""
echo "💡 Try checking logs manually:"
echo "   doppler run -- docker compose logs -f langfuse"

