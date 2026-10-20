# MyBoard DDR Debug Handoff

Last updated: 2026-07-07.

This note records the current DDR/JTAG bring-up state for the VU13P/MyBoard flow. It is intended as the first file to read before continuing the debug.

## Current Symptom

JTAG/BSCAN debug is working. OpenOCD can halt the core and read BootROM:

```text
halt
riscv.cpu.0 halted due to debug-request.

reg pc
pc (/64): 0x0000000000010038

mdw 0x10000 1
0x00010000: 00000517
```

DDR access through OpenOCD fails on the tested bitstream:

```text
mww 0x80000000 0x12345678
[riscv.cpu.0] Timed out after 5s waiting for busy to go low
[riscv.cpu.0] Unexpected error during fence execution
[riscv.cpu.0] Failed to write memory (addr=0x80000000)
progbuf=failed (fence execution failed), sysbus=disabled, abstract=disabled
```

Interpretation: the debug path and core are alive, but a hart-driven load/store or fence involving DDR does not complete. This points at the DDR/AXI/memory-system path, not at JTAG itself.

## Repositories Compared

Known-good older tree:

```text
/home/wzr/chipyard-1.11.0
```

Current tree:

```text
/home/wzr/chipyard
```

Current Vivado project:

```text
/home/wzr/chipyard_vivado/testTiny
```

## Important Findings

The older successful design used:

```text
CONFIG=RocketMyBoardConfig
```

from `chipyard-1.11.0`, not Tiny and not SmallRocket.

The currently tested failing design was:

```text
CONFIG=SmallRocketDDRMyBoardConfig
```

That means the failure does not yet prove the current MyBoard harness is broken. SmallRocket has a materially different SoC/cache structure.

## Generated Configs Now Available

Current tree has generated:

```text
fpga/generated-src/chipyard.fpga.myboard.MyBoardFPGATestHarness.SmallRocketDDRMyBoardConfig/
fpga/generated-src/chipyard.fpga.myboard.MyBoardFPGATestHarness.RocketMyBoardConfig/
```

`RocketMyBoardConfig` was generated after the DDR failure to separate "SmallRocket config problem" from "current MyBoard harness problem".

Generation command used:

```bash
cd /home/wzr/chipyard/fpga
source ../env.sh
env -u JAVA_OPTS -u SBT_OPTS make SUB_PROJECT=myboard CONFIG=RocketMyBoardConfig verilog
```

The command completed and produced Verilog collateral.

## Static Comparison Summary

### Old known-good RocketMyBoardConfig

Path:

```text
/home/wzr/chipyard-1.11.0/fpga/generated-src/chipyard.fpga.myboard.MyBoardFPGATestHarness.RocketMyBoardConfig/
```

Key properties:

```text
CPU: RV64 Rocket
ISA: rv64imafdczicsr_zifencei_zihpm_xrocket
I-cache: 16 KiB
D-cache: 16 KiB
L2/cache-controller: present at 0x2010000
DDR window: 0x80000000 size 0x10000000  // 256 MiB
Harness top ports: clk, reset, axi4_mem_*
AXI: 4-bit SoC ID, 32-bit SoC addr, 64-bit data
```

### Current SmallRocketDDRMyBoardConfig

Path:

```text
/home/wzr/chipyard/fpga/generated-src/chipyard.fpga.myboard.MyBoardFPGATestHarness.SmallRocketDDRMyBoardConfig/
```

Key properties:

```text
CPU: RV64 Small Rocket
ISA: rv64imaczicsr_zifencei_zihpm_xrocket
I-cache: 4 KiB
D-cache: 4 KiB
L2/cache-controller: absent
DDR window: 0x80000000 size 0x80000000  // 2 GiB
Harness top ports: clock, reset, axi4_mem_*
AXI: 4-bit SoC ID, 32-bit SoC addr, 64-bit data
```

### Current RocketMyBoardConfig

Path:

```text
/home/wzr/chipyard/fpga/generated-src/chipyard.fpga.myboard.MyBoardFPGATestHarness.RocketMyBoardConfig/
```

Key properties:

```text
CPU: RV64 Rocket
ISA: rv64imafdcbzicsr_zifencei_zihpm_zfh_zba_zbb_zbs_xrocket
I-cache: 32 KiB
D-cache: 32 KiB
L2/cache-controller: present at 0x2010000
DDR window: 0x80000000 size 0x80000000  // 2 GiB
Harness top ports: clock, reset, axi4_mem_*
AXI: 4-bit SoC ID, 32-bit SoC addr, 64-bit data
```

This current `RocketMyBoardConfig` is the closest next test to the old known-good design.

## Vivado Wrapper / BD Status

Current top wrapper:

```text
/home/wzr/chipyard_vivado/testTiny/rtl/top_wrapper.sv
```

It instantiates:

```verilog
MyBoardFPGATestHarness soc (
  .clock (soc_clk),
  .reset (~soc_resetn),
  ...
);
```

So it matches current generated collateral, whose harness ports are `clock/reset`.

The wrapper maps AXI IDs and addresses as:

```verilog
assign bd_awid   = axi4_mem_aw_id[2:0];
assign bd_awaddr = axi4_mem_aw_addr[30:0];
assign bd_arid   = axi4_mem_ar_id[2:0];
assign bd_araddr = axi4_mem_ar_addr[30:0];

assign axi4_mem_b_id = {1'b0, bd_bid};
assign axi4_mem_r_id = {1'b0, bd_rid};
```

Vivado BD generated wrapper reports:

```text
S00_AXI ADDR_WIDTH = 31
S00_AXI DATA_WIDTH = 64
S00_AXI ID_WIDTH   = 3
```

This matches the intended 2 GiB mapping:

```text
CPU 0x80000000 -> BD/MIG 0x00000000
CPU 0xffffffff -> BD/MIG 0x7fffffff
```

No static mismatch was found in AXI width/address mapping.

## OpenOCD Note

Current OpenOCD cfg still has:

```tcl
$_TARGETNAME.0 configure -work-area-phys 0x80000000 -work-area-size 0x10000 -work-area-backup 1
```

For DDR bring-up, this should be temporarily removed or disabled so OpenOCD does not depend on DDR before DDR has been proven.

## Recommended Next Step

Do not change MyBoard code yet.

First import and test current-tree `RocketMyBoardConfig` in Vivado:

```text
/home/wzr/chipyard/fpga/generated-src/chipyard.fpga.myboard.MyBoardFPGATestHarness.RocketMyBoardConfig/gen-collateral/
```

Keep the current `top_wrapper.sv`.

Then test with OpenOCD:

```tcl
halt
mdw 0x10000 1
mww 0x80000000 0x12345678
mdw 0x80000000 1
```

Expected OpenOCD XLEN:

```text
XLEN=64
```

Decision point:

```text
If current RocketMyBoardConfig passes DDR:
  The issue is likely SmallRocketDDRMyBoardConfig's SoC/cache/memory-system composition.

If current RocketMyBoardConfig also fails DDR:
  The issue is likely the current MyBoard harness/AXI export structure, or a Vivado integration mismatch.
  Then port the old chipyard-1.11.0 MyBoard harness style forward and keep DDR size at 2 GiB.
```

## If Reverting Toward Old MyBoard Structure

Only do this after testing current `RocketMyBoardConfig`.

Old successful MyBoard structure used:

```text
fpga/src/main/scala/myboard/TestHarness.scala
fpga/src/main/scala/myboard/HarnessBinders.scala
fpga/src/main/scala/myboard/IOBinders.scala
```

from:

```text
/home/wzr/chipyard-1.11.0/fpga/src/main/scala/myboard/
```

The old harness directly constructed the top-level AXI IO in `TestHarness.scala`:

```scala
val memAXI4 = IO(new AXI4Bundle(...)).suggestName("axi4_mem")
```

and used `WithMyBoardAXI4Mem` to connect the harness AXI to the Chipyard memory port.

If this route is used, preserve the current 2 GiB intent:

```scala
new freechips.rocketchip.subsystem.WithExtMemSize(BigInt(2) << 30)
```

## Gemmini Implication

Gemmini should not be added until the non-Gemmini `RocketMyBoardConfig` DDR path is proven.

After DDR works, Gemmini can be added only in the Chipyard config layer, while reusing the same MyBoard harness/DDR/JTAG structure. After generation, recheck the generated `MyBoardFPGATestHarness.sv` AXI port widths before importing into Vivado.
