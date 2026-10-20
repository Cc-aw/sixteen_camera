# Taihang SoC: 2 Rocket + 2 Saturn RVV + 3 packed 64x64 Gemmini

This configuration is defined in `fpga/src/main/scala/taihang_soc/Configs.scala`:

```text
TaihangSoC2Rocket2RVV3Gemmini64x64PackedConfig
```

The existing `TaihangSoC2Rocket2RVV3Gemmini4x4Config` is unchanged and remains
the bring-up rollback baseline.

## Gemmini policy

All three accelerators use the colleague's logical DIM64 WS packed array:

```text
tileRows=1, tileColumns=2
meshRows=64, meshColumns=32
dataflow=WS
use_dsp_mac_blackbox=false
use_dsp_mac_packing=true
has_max_pool=false
has_nonlinear_activations=false
```

Storage and memory policy is copied from the colleague's 64x64 packed config:

```text
scratchpad=512 KiB, 8 banks
accumulator=128 KiB, 4 banks
reservation station=16/8/32 (ld/st/ex)
queues=16/8/16 (ld/st/ex)
max in-flight memory requests=32
dma_buswidth=256, dma_maxbytes=64, tlb_size=8
```

The instances are tile-local and mapped as follows:

| Hart | Instance | Opcode | Busy CSR | Header |
| --- | --- | --- | --- | --- |
| 0 | gemmini0 | `custom3` | `0x7c2` | `gemmini_params_taihang_64x64_packed_gemmini0.h` |
| 0 | gemmini1 | `custom2` | `0x7c3` | `gemmini_params_taihang_64x64_packed_gemmini1.h` |
| 1 | gemmini2 | `custom1` | `0x7c4` | `gemmini_params_taihang_64x64_packed_gemmini2.h` |

The two Saturn units retain the current MyBoard settings (`vLen=128`,
`dLen=64`, `VectorParams()`, attached to cores 0 and 1). Board interfaces,
UART, MMIO, JTAG, DMA, and system bus remain 256-bit as in the 4x4 baseline.

## RTL generation

Run from `fpga/`:

```bash
source ../env.sh
env -u JAVA_OPTS -u SBT_OPTS XDG_RUNTIME_DIR=/tmp \
  make SUB_PROJECT=taihang_soc \
  CONFIG=TaihangSoC2Rocket2RVV3Gemmini64x64PackedConfig verilog
```

Verified output directory:

```text
fpga/generated-src/chipyard.fpga.myboard.MyBoardFPGATestHarness.TaihangSoC2Rocket2RVV3Gemmini64x64PackedConfig/
```

The generated hierarchy contains two `RocketTile`, two `SaturnRocketUnit`,
three Gemmini instances, and 6144 `WSDualPackedPE` instances (2048 per
logical 64x64 Gemmini).

The generated software headers are under
`generators/gemmini/software/gemmini-rocc-tests/include/` and each reports
`DIM=64`, `BANK_NUM=8`, `ACC_ROWS=512`, and `MAX_BYTES=64`.

## Synthesis prerequisite

The RTL generation command succeeds. Vivado synthesis/implementation requires
the board shell and constraints at:

```text
fpga/fpga-shells/xilinx/myboard/
```

That board-shell directory is not present in this repository, so synthesis
must wait until the MyBoard Xilinx shell/constraints are supplied. Do not use a
different board shell: the generated harness uses the MyBoard interfaces.

The existing synthesis reports from the colleague's single-SoC designs are
useful estimates only. The ordinary 64x64 version used 4551 DSPs; the packed
version used 2503 DSPs on `xcvu13p-fhga2104-2-i`.
