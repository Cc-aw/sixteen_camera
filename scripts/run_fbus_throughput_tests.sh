#!/usr/bin/env bash
set -euo pipefail
repo_dir=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
cd "$repo_dir"
python3 scripts/run_fbus_generated_path_test.py \
  --bytes 2116800 --short-only --consumer-period 4 --latency 48 --min-mbps 600
python3 scripts/run_fbus_generated_path_test.py \
  --bytes 2116800 --short-only --consumer-period 4 --latency 160 \
  --memory-gap 6 --fair-memory --write-traffic --min-mbps 600
# Adversarial fixed-priority service is a correctness stress, not a bounded
# latency performance model. Report its bandwidth without hiding gate misses.
python3 scripts/run_fbus_generated_path_test.py \
  --bytes 2116800 --short-only --consumer-period 4 --latency 160 \
  --memory-gap 6 --write-traffic
echo "FBUS_THROUGHPUT_MODELS=PASS (board gate still requires measurement)"
