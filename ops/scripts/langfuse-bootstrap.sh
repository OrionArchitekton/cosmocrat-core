#!/usr/bin/env bash
set -e
# Prereq: Langfuse is up; get an admin session cookie or API token first if needed.
BASE="${LANGFUSE_BASE_URL:-http://ops.localhost/langfuse}"
NAME="${1:-orion-biz}"
echo "NOTE: This is a placeholder. Use Langfuse UI to create the project and API key, or adapt this script to your auth model."
echo "Target project name: ${NAME} at ${BASE}"
