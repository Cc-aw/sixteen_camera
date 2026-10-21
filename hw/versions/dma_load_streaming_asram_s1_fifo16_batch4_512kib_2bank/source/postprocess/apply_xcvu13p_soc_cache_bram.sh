#!/usr/bin/env bash
set -euo pipefail

# Reassemble Rocket's lane-split cache data arrays as wide inferred BRAMs.
# The generated split memories are synchronous-read SRAMs; this replacement
# preserves their capacity, write masks, and one-cycle read-address behavior.
repo_root=$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)
generated_dir=${1:-"$repo_root/fpga/generated-src/xcvu13p_gemmini_64x64_packed_inference_ram_multi_silu_only_acc256_silu_bram_no_dwconv_soc_bram"}

if [[ ! -d "$generated_dir" ]]; then
  echo "Error: generated RTL directory does not exist: $generated_dir" >&2
  exit 1
fi

mem_file=$(find "$generated_dir" -maxdepth 1 -type f -name '*.top.mems.v' -print -quit)
if [[ -z "$mem_file" ]]; then
  echo "Error: no top-level memory implementation found in $generated_dir" >&2
  exit 1
fi

dcache_module=rockettile_dcache_data_arrays_0_ext
icache_module=rockettile_icache_data_arrays_0_ext

for module_name in "$dcache_module" "$icache_module"; do
  if ! grep -q "^module ${module_name}(" "$mem_file"; then
    echo "Error: expected module $module_name was not found in $mem_file" >&2
    exit 1
  fi
done

dcache_body=$(mktemp)
icache_body=$(mktemp)
tmp_file=$(mktemp)
trap 'rm -f "$dcache_body" "$icache_body" "$tmp_file"' EXIT

cat > "$dcache_body" <<'VERILOG'
module rockettile_dcache_data_arrays_0_ext(
  input  [7:0]    RW0_addr,
  input           RW0_clk,
  input  [1023:0] RW0_wdata,
  output [1023:0] RW0_rdata,
  input           RW0_en,
  input           RW0_wmode,
  input  [127:0]  RW0_wmask
);
  // Rocket DCache data: 256 rows x 128 bytes = 32 KiB.
  (* ram_style = "block", rw_addr_collision = "yes" *) reg [1023:0] ram [0:255];
  reg [7:0] r_addr_pipe;
  integer byte_lane;

  assign RW0_rdata = ram[r_addr_pipe];

  always @(posedge RW0_clk) begin
    if (RW0_en && !RW0_wmode)
      r_addr_pipe <= RW0_addr;
    if (RW0_en && RW0_wmode) begin
      for (byte_lane = 0; byte_lane < 128; byte_lane = byte_lane + 1) begin
        if (RW0_wmask[byte_lane])
          ram[RW0_addr][byte_lane*8 +: 8] <= RW0_wdata[byte_lane*8 +: 8];
      end
    end
  end
endmodule
VERILOG

cat > "$icache_body" <<'VERILOG'
module rockettile_icache_data_arrays_0_ext(
  input  [6:0]   RW0_addr,
  input          RW0_clk,
  input  [255:0] RW0_wdata,
  output [255:0] RW0_rdata,
  input          RW0_en,
  input          RW0_wmode,
  input  [7:0]   RW0_wmask
);
  // Rocket ICache data: 128 rows x 32 bytes = 4 KiB.
  (* ram_style = "block", rw_addr_collision = "yes" *) reg [255:0] ram [0:127];
  reg [6:0] r_addr_pipe;
  integer word_lane;

  assign RW0_rdata = ram[r_addr_pipe];

  always @(posedge RW0_clk) begin
    if (RW0_en && !RW0_wmode)
      r_addr_pipe <= RW0_addr;
    if (RW0_en && RW0_wmode) begin
      for (word_lane = 0; word_lane < 8; word_lane = word_lane + 1) begin
        if (RW0_wmask[word_lane])
          ram[RW0_addr][word_lane*32 +: 32] <= RW0_wdata[word_lane*32 +: 32];
      end
    end
  end
endmodule
VERILOG

replace_module() {
  local module_name=$1
  local body_file=$2
  awk -v module_name="$module_name" -v body_file="$body_file" '
    BEGIN { replacing = 0 }
    $0 == "module " module_name "(" {
      while ((getline line < body_file) > 0) print line
      close(body_file)
      replacing = 1
      next
    }
    replacing && /^endmodule[[:space:]]*$/ {
      replacing = 0
      next
    }
    !replacing { print }
    END {
      if (replacing) {
        print "Error: unterminated module " module_name > "/dev/stderr"
        exit 2
      }
    }
  ' "$mem_file" > "$tmp_file"
  mv "$tmp_file" "$mem_file"
}

replace_module "$dcache_module" "$dcache_body"
replace_module "$icache_module" "$icache_body"

dcache_text=$(sed -n "/^module ${dcache_module}(/,/^endmodule/p" "$mem_file")
icache_text=$(sed -n "/^module ${icache_module}(/,/^endmodule/p" "$mem_file")

if ! grep -q 'ram_style = "block"' <<<"$dcache_text" ||
   ! grep -q 'reg \[1023:0\] ram \[0:255\]' <<<"$dcache_text" ||
   ! grep -q 'byte_lane < 128' <<<"$dcache_text"; then
  echo "Error: DCache wide-BRAM replacement verification failed" >&2
  exit 1
fi
if ! grep -q 'ram_style = "block"' <<<"$icache_text" ||
   ! grep -q 'reg \[255:0\] ram \[0:127\]' <<<"$icache_text" ||
   ! grep -q 'word_lane < 8' <<<"$icache_text"; then
  echo "Error: ICache wide-BRAM replacement verification failed" >&2
  exit 1
fi

echo "SOC_MEMORY_STYLE_FILE=$mem_file"
echo "ROCKET_DCACHE_DATA_GEOMETRY=256x1024"
echo "ROCKET_DCACHE_DATA_CAPACITY_KIB=32"
echo "ROCKET_DCACHE_DATA_RAM_STYLE=block"
echo "ROCKET_ICACHE_DATA_GEOMETRY=128x256"
echo "ROCKET_ICACHE_DATA_CAPACITY_KIB=4"
echo "ROCKET_ICACHE_DATA_RAM_STYLE=block"
echo "ROCKET_CACHE_TAG_RAM_STYLE=unchanged"
echo "SATURN_MEMORY_STYLE=unchanged"
echo "STATUS=PASS"
