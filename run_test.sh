#!/bin/bash
set -euo pipefail

cd /root/ai-scientist-v3-new

# Source .env with export
set -a
source .env
set +a

# Activate venv
source .venv/bin/activate

# Verify env vars
echo "=== Env check ==="
echo "ANTHROPIC_API_KEY=${ANTHROPIC_API_KEY:0:20}..."
echo "ANTHROPIC_BASE_URL=$ANTHROPIC_BASE_URL"
echo "E2B_API_KEY=${E2B_API_KEY:0:20}..."
echo "REVIEW_API_URL=$REVIEW_API_URL"
echo "SEARCH_PUBLIC_URL=$SEARCH_PUBLIC_URL"
echo "==================" 

# Clean any previous stale jobs
rm -rf jobs/tabulartransformer__*

# Run
./run.sh ideas/idea_tabulartransformer.json     --model deepseek-v4-pro     --timeout 3600     --use-upstream-agent     --env docker --gpus 1
