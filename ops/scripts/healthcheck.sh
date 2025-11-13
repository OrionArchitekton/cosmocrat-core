#!/usr/bin/env bash
set -euo pipefail

echo "🏥 Cosmocrat Core Health Check"
echo "================================"
echo ""

# Check postgres
echo -n "PostgreSQL: "
if docker compose exec -T postgres pg_isready &> /dev/null; then
    echo "✓ OK"
else
    echo "✗ FAILED"
    exit 1
fi

# Check redis
echo -n "Redis: "
if docker compose exec -T redis redis-cli ping &> /dev/null; then
    echo "✓ OK"
else
    echo "✗ FAILED"
    exit 1
fi

# Check langfuse
echo -n "Langfuse: "
if curl -fsS http://localhost:3000/health &> /dev/null; then
    echo "✓ OK"
else
    echo "✗ FAILED"
    exit 1
fi

# Check ollama
echo -n "Ollama: "
if curl -fsS http://localhost:11434/api/tags &> /dev/null; then
    echo "✓ OK"
else
    echo "✗ FAILED"
    exit 1
fi

# Check edge-orchestrator
echo -n "Edge-Orchestrator: "
if curl -fsS http://localhost:8000/health &> /dev/null; then
    echo "✓ OK"
else
    echo "✗ FAILED"
    exit 1
fi

# Check confirm-engine
echo -n "Confirm-Engine: "
if curl -fsS http://localhost:8010/health &> /dev/null; then
    echo "✓ OK"
else
    echo "✗ FAILED"
    exit 1
fi

# Check deploy-memory
echo -n "Deploy-Memory: "
if curl -fsS http://localhost:8020/health &> /dev/null; then
    echo "✓ OK"
else
    echo "✗ FAILED"
    exit 1
fi

# Check mcp
echo -n "MCP: "
if curl -fsS http://localhost:8080/healthz &> /dev/null; then
    echo "✓ OK"
else
    echo "✗ FAILED"
    exit 1
fi

# Check memory-consolidator (check if container is running)
echo -n "Memory-Consolidator: "
if docker compose ps memory-consolidator | grep -q "Up"; then
    echo "✓ OK (running)"
else
    echo "✗ FAILED (not running)"
    exit 1
fi

echo ""
echo "✅ All services are healthy!"
