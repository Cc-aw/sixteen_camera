#!/usr/bin/env bash
set -euo pipefail

repo_root=$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)
generated_dir=${1:-"$repo_root/fpga/generated-src/xcvu13p_gemmini_64x64_packed_inference_ram/gen-collateral"}

mem_file=$(find "$generated_dir" -maxdepth 1 -type f -name '*.top.mems.v' -print -quit)
if [[ -z "$mem_file" ]]; then
  echo "Error: no generated top-level memory file in $generated_dir" >&2
  exit 1
fi

# Firtool emits the Gemmini scratchpad and accumulator as byte-write lanes.
# Force both lane memories into block RAM instead of LUTRAM/register storage.
# The accepted 64x64 capacities produce 1024x8 scratchpad lanes and 128x8
# accumulator lanes.
declare -A expected_depths=(
  [split_mem_ext]='\[0:1023\]'
  [split_mem_0_ext]='\[0:127\]'
)

for module_name in split_mem_ext split_mem_0_ext; do
  module_text=$(sed -n "/^module ${module_name}(/,/^endmodule/p" "$mem_file")
  if [[ -z "$module_text" ]]; then
    echo "Error: module ${module_name} not found in $mem_file" >&2
    exit 1
  fi
  if ! grep -q "reg \[7:0\] ram ${expected_depths[$module_name]};" <<<"$module_text"; then
    echo "Error: unexpected ${module_name} geometry in $mem_file" >&2
    exit 1
  fi
  if ! grep -q 'ram_style = "block"' <<<"$module_text"; then
    sed -i "/^module ${module_name}(/,/^endmodule/ s/^  reg \[7:0\] ram /  (* ram_style = \"block\" *) reg [7:0] ram /" "$mem_file"
  fi
done

scratchpad_count=$(sed -n '/^module split_mem_ext(/,/^endmodule/p' "$mem_file" | grep -c 'ram_style = "block"' || true)
accumulator_count=$(sed -n '/^module split_mem_0_ext(/,/^endmodule/p' "$mem_file" | grep -c 'ram_style = "block"' || true)
if [[ "$scratchpad_count" -ne 1 || "$accumulator_count" -ne 1 ]]; then
  echo "Error: expected one BRAM attribute on each Gemmini memory" >&2
  exit 1
fi

echo "MEMORY_STYLE_FILE=$mem_file"
echo "SCRATCHPAD_GEOMETRY=1024x8"
echo "ACCUMULATOR_GEOMETRY=128x8"
echo "SCRATCHPAD_RAM_STYLE=block"
echo "ACCUMULATOR_RAM_STYLE=block"
echo "STATUS=PASS"
