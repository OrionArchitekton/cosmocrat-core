#!/usr/bin/env bash
set -e
MODEL="${MODEL:-mistralai/Mistral-7B-Instruct-v0.3}"
PORT="${PORT:-8000}"
docker run --rm -d --name vllm   -p ${PORT}:8000   --shm-size 4g   vllm/vllm-openai:latest   --model "${MODEL}" --port 8000
echo "vLLM serving ${MODEL} at http://localhost:${PORT}/v1"
