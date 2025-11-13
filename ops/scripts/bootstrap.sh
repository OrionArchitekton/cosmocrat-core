#!/usr/bin/env bash
set -euo pipefail

echo "🚀 Starting Cosmocrat Core Bootstrap..."
echo ""

# Check if Doppler is configured
if ! command -v doppler &> /dev/null; then
    echo "❌ Error: Doppler CLI not found. Please install Doppler CLI first."
    echo "   Visit: https://docs.doppler.com/docs/install-cli"
    exit 1
fi

echo "✓ Doppler CLI found"
echo ""

# Verify Doppler is authenticated and configured
if ! doppler secrets get DOPPLER_PROJECT &> /dev/null; then
    echo "❌ Error: Doppler not configured. Please run 'doppler setup' first."
    exit 1
fi

echo "✓ Doppler configured"
echo ""

# Clean up old images to avoid conflicts
echo "🧹 Cleaning up old images..."
doppler run -- docker compose down --rmi local --remove-orphans 2>/dev/null || true
docker image prune -f >/dev/null 2>&1 || true
echo "✓ Cleanup complete"
echo ""

# Build all services
echo "📦 Building Docker images..."
doppler run -- docker compose build --no-cache
echo "✓ Build complete"
echo ""

# Start core services
echo "🔧 Starting core services..."
doppler run -- docker compose up -d traefik postgres redis langfuse ollama edge-orchestrator confirm-engine deploy-memory mcp memory-consolidator
echo "✓ Services started"
echo ""

# Wait for services to be healthy
echo "⏳ Waiting for services to become healthy..."
echo ""

# Wait for postgres
echo -n "Waiting for postgres..."
for i in {1..60}; do
    if docker compose exec -T postgres pg_isready &> /dev/null; then
        echo " ✓"
        break
    fi
    if [ $i -eq 60 ]; then
        echo " ❌ Timeout"
        exit 1
    fi
    sleep 1
    echo -n "."
done

# Wait for redis
echo -n "Waiting for redis..."
for i in {1..30}; do
    if docker compose exec -T redis redis-cli ping &> /dev/null; then
        echo " ✓"
        break
    fi
    if [ $i -eq 30 ]; then
        echo " ❌ Timeout"
        exit 1
    fi
    sleep 1
    echo -n "."
done

# Wait for langfuse
echo -n "Waiting for langfuse..."
for i in {1..60}; do
    if curl -fsS http://localhost:3000/health &> /dev/null; then
        echo " ✓"
        break
    fi
    if [ $i -eq 60 ]; then
        echo " ❌ Timeout"
        exit 1
    fi
    sleep 2
    echo -n "."
done

# Wait for ollama
echo -n "Waiting for ollama..."
for i in {1..30}; do
    if curl -fsS http://localhost:11434/api/tags &> /dev/null; then
        echo " ✓"
        break
    fi
    if [ $i -eq 30 ]; then
        echo " ❌ Timeout"
        exit 1
    fi
    sleep 1
    echo -n "."
done

# Wait for edge-orchestrator
echo -n "Waiting for edge-orchestrator..."
for i in {1..60}; do
    if curl -fsS http://localhost:8000/health &> /dev/null; then
        echo " ✓"
        break
    fi
    if [ $i -eq 60 ]; then
        echo " ❌ Timeout"
        exit 1
    fi
    sleep 2
    echo -n "."
done

# Wait for confirm-engine
echo -n "Waiting for confirm-engine..."
for i in {1..60}; do
    if curl -fsS http://localhost:8010/health &> /dev/null; then
        echo " ✓"
        break
    fi
    if [ $i -eq 60 ]; then
        echo " ❌ Timeout"
        exit 1
    fi
    sleep 2
    echo -n "."
done

# Wait for deploy-memory
echo -n "Waiting for deploy-memory..."
for i in {1..60}; do
    if curl -fsS http://localhost:8020/health &> /dev/null; then
        echo " ✓"
        break
    fi
    if [ $i -eq 60 ]; then
        echo " ❌ Timeout"
        exit 1
    fi
    sleep 2
    echo -n "."
done

# Wait for mcp
echo -n "Waiting for mcp..."
for i in {1..60}; do
    if curl -fsS http://localhost:8080/healthz &> /dev/null; then
        echo " ✓"
        break
    fi
    if [ $i -eq 60 ]; then
        echo " ❌ Timeout"
        exit 1
    fi
    sleep 2
    echo -n "."
done

echo ""
echo "✅ All core services are healthy!"
echo ""
echo "📊 Service Status:"
echo "  - Traefik:      http://ops.localhost:8888/traefik"
echo "  - Langfuse:     http://ops.localhost/langfuse"
echo "  - Ollama:       http://ops.localhost/llm"
echo "  - Edge-Orch:    http://localhost:8000"
echo "  - Confirm-Eng:  http://localhost:8010"
echo "  - Deploy-Mem:   http://localhost:8020"
echo "  - MCP:          http://mcp.localhost"
echo ""
echo "🎉 Bootstrap complete! Run './ops/scripts/healthcheck.sh' to verify all services."
echo ""
echo "💡 To deploy LLM models (Codex, Claude, Gemini), run:"
echo "   ./ops/scripts/deploy-models.sh"
echo ""
echo "   Or set DEPLOY_MODELS=true to auto-deploy after bootstrap:"
if [ "${DEPLOY_MODELS:-false}" = "true" ]; then
    echo "   Auto-deploying models..."
    ./ops/scripts/deploy-models.sh || echo "⚠ Model deployment had issues, but core services are running"
fi
