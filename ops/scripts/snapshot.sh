#!/usr/bin/env bash
set -euo pipefail
TS=$(date +%Y%m%d-%H%M%S)
docker image ls | grep -E 'cosmocrat|edge|confirm|deploy|n8n|clickhouse|appsmith' || true
docker save $(docker images --format '{{.Repository}}:{{.Tag}}' | grep -E 'cosmocrat|edge|confirm|deploy|n8n|clickhouse|appsmith' || true) -o /mnt/data/cosmocrat_images_$TS.tar || true
echo "Snapshot (if any) saved to /mnt/data/cosmocrat_images_$TS.tar"
