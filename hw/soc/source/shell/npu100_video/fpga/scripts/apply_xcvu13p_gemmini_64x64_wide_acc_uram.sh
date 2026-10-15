#!/usr/bin/env bash
set -euo pipefail

# Replace FIRRTL's byte-lane accumulator RAM with one genuinely wide RAM.
# The generated mem_0_ext interface is 128 deep, 2048 bits wide, with one
# write-enable bit per byte. Keeping that interface avoids changing the
# AccumulatorMem timing or its read/write protocol.
repo_root=$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)
generated_dir=${1:-"$repo_root/fpga/vivado/xcvu13p-gemmini-64x64-wide-uram-demo/xcvu13p_gemmini_64x64_wide_uram.srcs/sources_1/imports/rtl/xcvu13p_gemmini_64x64_wide_uram/gen-collateral"}

mem_file=$(find "$generated_dir" -maxdepth 1 -type f -name '*.top.mems.v' -print -quit)
if [[ -z "$mem_file" ]]; then
  echo "Error: no top-level memory implementation found in $generated_dir" >&2
  exit 1
fi

if ! grep -q '^module mem_0_ext(' "$mem_file"; then
  echo "Error: accumulator mem_0_ext module not found in $mem_file" >&2
  exit 1
fi

body_file=$(mktemp)
tmp_file=$(mktemp)
trap 'rm -f "$body_file" "$tmp_file"' EXIT
cat > "$body_file" <<'VERILOG'
module mem_0_ext(
  input  [6:0]    R0_addr,
  input           R0_clk,
  output [2047:0] R0_data,
  input           R0_en,
  input  [6:0]    W0_addr,
  input           W0_clk,
  input  [2047:0] W0_data,
  input           W0_en,
  input  [255:0]  W0_mask
);
  // 128 x 2048-bit organization. The actual design connects R0_clk and
  // W0_clk to the same clock, so use one clocked process here. Keeping the
  // ports separate preserves the generated interface while allowing Vivado
  // to infer a true wide URAM instead of treating the clocks as unrelated.
  (* ram_style = "ultra", rw_addr_collision = "yes" *) reg [2047:0] ram [0:127];
  reg [6:0]  r_addr_pipe;
  integer i;

  assign R0_data = ram[r_addr_pipe];

  always @(posedge R0_clk) begin
    if (R0_en)
      r_addr_pipe <= R0_addr;
    if (W0_en) begin
      for (i = 0; i < 256; i = i + 1) begin
        if (W0_mask[i])
          ram[W0_addr][i*8 +: 8] <= W0_data[i*8 +: 8];
      end
    end
  end
endmodule
VERILOG

# Replace only the implementation block; all other generated memories remain
# untouched (the scratchpad continues to use its existing block-RAM mapping).
awk -v body_file="$body_file" '
  BEGIN { replacing = 0 }
  /^module mem_0_ext\(/ {
    while ((getline line < body_file) > 0) print line
    close(body_file)
    replacing = 1
    next
  }
  replacing && /^endmodule/ {
    replacing = 0
    next
  }
  !replacing { print }
' "$mem_file" > "$tmp_file"
mv "$tmp_file" "$mem_file"

if ! sed -n '/^module mem_0_ext(/,/^endmodule/p' "$mem_file" | grep -q 'reg \[2047:0\] ram \[0:127\]'; then
  echo "Error: wide accumulator RAM replacement was not applied" >&2
  exit 1
fi
if ! sed -n '/^module mem_0_ext(/,/^endmodule/p' "$mem_file" | grep -q 'ram_style = "ultra"'; then
  echo "Error: wide accumulator RAM is missing ram_style=ultra" >&2
  exit 1
fi
if ! sed -n '/^module mem_0_ext(/,/^endmodule/p' "$mem_file" | grep -q 'always @(posedge R0_clk)'; then
  echo "Error: wide accumulator RAM is not using the shared read clock" >&2
  exit 1
fi

echo "MEMORY_STYLE_FILE=$mem_file"
echo "ACCUMULATOR_ORGANIZATION=128x2048"
echo "ACCUMULATOR_RAM_STYLE=ultra"
echo "ACCUMULATOR_CLOCKING=shared_R0_clk"
echo "BYTE_WRITE_ENABLES=256"
echo "STATUS=PASS"
