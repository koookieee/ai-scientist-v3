#!/bin/bash
set -euo pipefail
cd /root/ai-scientist-v3-new
set -a; source .env; set +a
source .venv/bin/activate
./run.sh ideas/idea_ibcl_with_reviews.json \
    --model deepseek-v4-pro \
    --timeout 21600 \
    --use-upstream-agent \
    --env docker --gpus 1
