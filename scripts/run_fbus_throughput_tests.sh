#!/usr/bin/env bash
set -euo pipefail
repo_dir=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
cd "$repo_dir"
python3 scripts/run_fbus_generated_path_test.py \
  --bytes 2116800 --short-only --consumer-period 4 --latency 48 \
  --min-mbps 600 --require-eight
# The fair shared responder serves both the production 18/14 ID partitions.
# With a six-cycle memory gap and concurrent tensor writes, the bounded read
# model measures about 421 MB/s; require 400 MB/s and full ID concurrency.
python3 scripts/run_fbus_generated_path_test.py \
  --bytes 2116800 --short-only --consumer-period 4 --latency 160 \
  --memory-gap 6 --fair-memory --write-traffic --min-mbps 400 \
  --require-eight
# Adversarial fixed-priority service is a correctness stress, not a bounded
# latency performance model. Report its bandwidth without hiding gate misses.
python3 scripts/run_fbus_generated_path_test.py \
  --bytes 2116800 --short-only --consumer-period 4 --latency 160 \
  --memory-gap 6 --write-traffic
echo "FBUS_THROUGHPUT_MODELS=PASS (board gate still requires measurement)"
