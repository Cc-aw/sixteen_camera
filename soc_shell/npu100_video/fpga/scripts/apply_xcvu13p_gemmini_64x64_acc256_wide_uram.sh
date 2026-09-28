#!/usr/bin/env bash
set -euo pipefail

# Replace FIRRTL's byte-lane accumulator RAM with one 256-deep, 2048-bit
# memory.  The generated 256 KiB/4-bank configuration has this interface:
# 8-bit row addresses, 256 byte write enables, and one 2048-bit row per bank.
# The scratchpad is left as a block RAM and no Gemmini protocol is changed.
repo_root=$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)
generated_dir=${1:-"$repo_root/fpga/generated-src/xcvu13p_gemmini_64x64_acc256_single/gen-collateral"}

if [[ ! -d "$generated_dir" ]]; then
  echo "Error: generated RTL directory does not exist: $generated_dir" >&2
  exit 1
fi

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
  input  [7:0]    R0_addr,
  input           R0_clk,
  output [2047:0] R0_data,
  input           R0_en,
  input  [7:0]    W0_addr,
  input           W0_clk,
  input  [2047:0] W0_data,
  input           W0_en,
  input  [255:0]  W0_mask
);
  // 256 x 2048-bit organization: 64 KiB per accumulator bank.
  // R0_clk and W0_clk are the same design clock in AccumulatorMem.  A single
  // clocked process lets Vivado infer a true wide URAM while retaining the
  // generated module's one-cycle read-address behavior and byte write mask.
  (* ram_style = "ultra", rw_addr_collision = "yes" *) reg [2047:0] ram [0:255];
  reg [7:0] r_addr_pipe;
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

# Replace only mem_0_ext; all other generated memories remain untouched.
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

# Apply a block-RAM hint to the 512 KiB scratchpad only.
scratchpad_text=$(sed -n '/^module split_mem_ext(/,/^endmodule/p' "$mem_file")
if [[ -z "$scratchpad_text" ]]; then
  echo "Error: scratchpad split_mem_ext module not found in $mem_file" >&2
  exit 1
fi
if ! grep -q 'reg \[7:0\] ram \[0:1023\];' <<<"$scratchpad_text"; then
  echo "Error: unexpected scratchpad geometry in $mem_file" >&2
  exit 1
fi
if ! grep -q 'ram_style = "block"' <<<"$scratchpad_text"; then
  sed -i '/^module split_mem_ext(/,/^endmodule/ s/^  reg \[7:0\] ram /  (* ram_style = "block" *) reg [7:0] ram /' "$mem_file"
fi

if ! sed -n '/^module mem_0_ext(/,/^endmodule/p' "$mem_file" | grep -q 'reg \[2047:0\] ram \[0:255\]'; then
  echo "Error: 256-deep wide accumulator replacement was not applied" >&2
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
echo "SCRATCHPAD_GEOMETRY=1024x8"
echo "SCRATCHPAD_RAM_STYLE=block"
echo "ACCUMULATOR_ORGANIZATION=256x2048"
echo "ACCUMULATOR_RAM_STYLE=ultra"
echo "ACCUMULATOR_CLOCKING=shared_R0_clk"
echo "BYTE_WRITE_ENABLES=256"
echo "STATUS=PASS"
