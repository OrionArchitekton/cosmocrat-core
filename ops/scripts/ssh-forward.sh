#!/usr/bin/env bash
set -euo pipefail

# SSH Port Forwarding Helper Script
# Usage: ./ops/scripts/ssh-forward.sh [user@]hostname

if [ $# -eq 0 ]; then
    echo "Usage: $0 [user@]hostname"
    echo ""
    echo "Example:"
    echo "  $0 user@192.168.1.100"
    echo "  $0 ubuntu@my-server.com"
    exit 1
fi

REMOTE_HOST="$1"

echo "🔌 Setting up SSH port forwarding to $REMOTE_HOST"
echo "================================================"
echo ""

# Check if ports are already in use locally
check_port() {
    local port=$1
    if lsof -Pi :$port -sTCP:LISTEN -t >/dev/null 2>&1; then
        echo "⚠️  Port $port is already in use locally"
        return 1
    fi
    return 0
}

echo "📋 Checking local ports..."
PORTS_OK=true
for port in 8000 8010 8020 8080 8888 3000 11434; do
    if ! check_port $port; then
        PORTS_OK=false
    fi
done

if [ "$PORTS_OK" = false ]; then
    echo ""
    echo "❌ Some ports are already in use. Kill existing processes or use different ports."
    exit 1
fi

echo "✓ All ports available"
echo ""

# Test SSH connection first
echo "🔍 Testing SSH connection..."
if ! ssh -o ConnectTimeout=5 -o BatchMode=yes "$REMOTE_HOST" "echo 'SSH connection OK'" 2>/dev/null; then
    echo "❌ Cannot connect to $REMOTE_HOST"
    echo "   Make sure:"
    echo "   1. SSH key is set up (ssh-copy-id $REMOTE_HOST)"
    echo "   2. Server is reachable"
    echo "   3. SSH service is running on server"
    exit 1
fi

echo "✓ SSH connection works"
echo ""

# Check if services are running on remote
echo "🔍 Checking services on remote server..."
if ! ssh "$REMOTE_HOST" "docker compose ps 2>/dev/null | grep -q Up" 2>/dev/null; then
    echo "⚠️  Warning: Docker services may not be running on remote"
    echo "   Run on server: doppler run -- docker compose up -d"
fi

echo ""
echo "🚀 Starting SSH port forwarding..."
echo ""
echo "Forwarding ports:"
echo "  - 8000  → edge-orchestrator"
echo "  - 8010  → confirm-engine"
echo "  - 8020  → deploy-memory"
echo "  - 8080  → mcp"
echo "  - 8888  → traefik"
echo "  - 3000  → langfuse"
echo "  - 11434 → ollama"
echo ""
echo "Access services at:"
echo "  - http://localhost:8000/health"
echo "  - http://localhost:8010/health"
echo "  - http://localhost:8020/health"
echo "  - http://localhost:8080/healthz"
echo "  - http://localhost:8888/traefik"
echo "  - http://localhost:3000/health"
echo ""
echo "Press Ctrl+C to stop forwarding"
echo ""

# Start port forwarding
ssh -L 8000:localhost:8000 \
    -L 8010:localhost:8010 \
    -L 8020:localhost:8020 \
    -L 8080:localhost:8080 \
    -L 8888:localhost:8888 \
    -L 3000:localhost:3000 \
    -L 11434:localhost:11434 \
    -o ServerAliveInterval=60 \
    -o ServerAliveCountMax=3 \
    -N "$REMOTE_HOST"

