#!/usr/bin/env bash
set -euo pipefail

# Check if user wants to remove volumes too
REMOVE_VOLUMES=false
if [ "${1:-}" = "--volumes" ] || [ "${1:-}" = "-v" ]; then
    REMOVE_VOLUMES=true
    echo "⚠️  WARNING: This will remove all data volumes (databases, redis, etc.)"
    read -p "Continue? (y/N): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        echo "Cancelled."
        exit 0
    fi
fi

echo "🧹 Cleaning up Docker images and containers..."
echo ""

# Stop and remove containers
echo "Stopping containers..."
doppler run -- docker compose down --remove-orphans 2>/dev/null || true

# Remove images built by this project
echo "Removing project images..."
if [ "$REMOVE_VOLUMES" = true ]; then
    doppler run -- docker compose down --rmi local --volumes --remove-orphans 2>/dev/null || true
else
    doppler run -- docker compose down --rmi local --remove-orphans 2>/dev/null || true
fi

# Remove specific images if they exist
IMAGES=(
    "cosmocrat-core-edge-orchestrator"
    "cosmocrat-core-confirm-engine"
    "cosmocrat-core-deploy-memory"
    "cosmocrat-core-mcp"
)

for image in "${IMAGES[@]}"; do
    if docker images --format "{{.Repository}}" | grep -q "^${image}$"; then
        echo "Removing ${image}..."
        docker rmi "${image}" 2>/dev/null || true
    fi
done

# Clean up dangling images
echo "Cleaning up dangling images..."
docker image prune -f

if [ "$REMOVE_VOLUMES" = true ]; then
    echo "Removing volumes..."
    docker volume prune -f
fi

echo ""
echo "✅ Cleanup complete!"
echo ""
if [ "$REMOVE_VOLUMES" = true ]; then
    echo "⚠️  All data volumes have been removed. Databases will be recreated fresh."
fi
echo "💡 Run './ops/scripts/bootstrap.sh' to rebuild and deploy fresh."

