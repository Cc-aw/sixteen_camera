#!/usr/bin/env bash
set -euo pipefail

# Keep the accepted 64x64 packed-inference memory policy, but replace only the
# accumulator wrapper with the shared-clock wide implementation. The
# scratchpad remains in BRAM; no architectural Gemmini parameter is changed.
repo_root=$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)
generated_dir=${1:-"$repo_root/fpga/generated-src/xcvu13p_gemmini_64x64_packed_inference_wide_uram/gen-collateral"}

if [[ ! -d "$generated_dir" ]]; then
  echo "Error: generated RTL directory does not exist: $generated_dir" >&2
  exit 1
fi

# Apply the block-RAM hint to the scratchpad only. The wide accumulator rewrite
# below replaces mem_0_ext (which otherwise instantiates 256 byte lanes).
ram_style_file=$(find "$generated_dir" -maxdepth 1 -type f -name '*.top.mems.v' -print -quit)
if [[ -z "$ram_style_file" ]]; then
  echo "Error: no top-level memory file in $generated_dir" >&2
  exit 1
fi
scratchpad_text=$(sed -n '/^module split_mem_ext(/,/^endmodule/p' "$ram_style_file")
if [[ -z "$scratchpad_text" ]]; then
  echo "Error: scratchpad split_mem_ext module not found in $ram_style_file" >&2
  exit 1
fi
if ! grep -q 'reg \[7:0\] ram \[0:1023\];' <<<"$scratchpad_text"; then
  echo "Error: unexpected scratchpad geometry in $ram_style_file" >&2
  exit 1
fi
if ! grep -q 'ram_style = "block"' <<<"$scratchpad_text"; then
  sed -i '/^module split_mem_ext(/,/^endmodule/ s/^  reg \[7:0\] ram /  (* ram_style = "block" *) reg [7:0] ram /' "$ram_style_file"
fi

"$repo_root/fpga/scripts/apply_xcvu13p_gemmini_64x64_wide_acc_uram.sh" "$generated_dir"

if ! sed -n '/^module split_mem_ext(/,/^endmodule/p' "$ram_style_file" | grep -q 'ram_style = "block"'; then
  echo "Error: scratchpad BRAM mapping was not applied" >&2
  exit 1
fi
if ! sed -n '/^module mem_0_ext(/,/^endmodule/p' "$ram_style_file" | grep -q 'reg \[2047:0\] ram \[0:127\]'; then
  echo "Error: wide accumulator mapping was not applied" >&2
  exit 1
fi

echo "MEMORY_STYLE_FILE=$ram_style_file"
echo "SCRATCHPAD_GEOMETRY=1024x8"
echo "SCRATCHPAD_RAM_STYLE=block"
echo "ACCUMULATOR_ORGANIZATION=128x2048"
echo "ACCUMULATOR_RAM_STYLE=ultra"
echo "ACCUMULATOR_CLOCKING=shared_R0_clk"
echo "STATUS=PASS"
