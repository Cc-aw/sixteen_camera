#!/usr/bin/env bash
set -euo pipefail

# Apply the same wide accumulator URAM implementation used by the accepted
# 64x64 project to the YOLOv5-trimmed generated RTL.
repo_root=$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)
generated_dir=${1:-"$repo_root/fpga/generated-src/xcvu13p_gemmini_64x64_yolov5/gen-collateral"}

"$repo_root/fpga/scripts/apply_xcvu13p_gemmini_64x64_wide_acc_uram.sh" "$generated_dir"
