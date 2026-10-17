Memory Parallel V3 — independent hardware overlay
=================================================

Baseline: first timing-passing memory32 build, 100 MHz Rocket/Gemmini,
512 KiB total L2, Gemmini DMA experiments OFF (0, false, 2, 0).
The production tree, old generated SoC, build/soc_manifest.tcl and bitstreams
are not modified. Everything here is selected explicitly for V3.

Hardware
--------
* Two L2 banks: 256 KiB/bank, 8 ways, 512 sets, 64-byte lines,
  32 ordinary + 2 coherence MSHRs PER BANK. Total cache capacity unchanged.
* Bank = physical address bit 12; 4 KiB interleave. A physical address does
  not change. Set bits are [15:13] concatenated with [11:6]. Cache-Cork,
  probe, flush and writeback retain the original physical address.
* Inner bus/DMA = 256 bits. L2 outer bus/MBUS/SoC memory AXI/Head/DDR S00
  = 512 bits at 100 MHz. MIG remains 512 bits at 300 MHz. FBus stays 256.
* ExtMem idBits=2; AXI4IdIndexer + AXI4UserYanker preserve original IDs.
  Four physical IDs do not mean four outstanding requests. S00 accepts
  32 read + 32 write requests. Crossbar global IDs use 4 bits including
  master selection: S00 local ID bits 1:0, S01 base ID 4, S02 base ID 8.
  Width-extension/truncation warnings at the crossbar coupler are expected:
  only the already-defined S00 local two bits return to that master.
* Head URAM stores 512-bit words; PPU still reads 256-bit words at the same
  local addresses. The half selector is retained with each accepted read.
  All six slots, byte masks and DDR/Head ordering fences are retained.
* CPU counter MMIO is at 0x02020000 (64 KiB), connected to CBUS.
  See REGISTERS.txt and registers.json. No software driver is included.
* MIG observation uses an AXI MONITOR interface in the block design.
  Never replace it with connect_bd_net calls on individual AXI pins:
  Vivado overrides interface-pin connectivity in that case.
* video_memory_ports.sv only relaxes the modport annotation at its split
  read/write interface boundary. Assignments and traffic are unchanged;
  the module also drives the unused return channels, which a conventional
  AXI master modport incorrectly marks input-only.

Source ownership
----------------
scala/ contains the independently named configuration and IO/harness binder.
chipyard/ contains complete modified/new dependency files; the source hashes
in chipyard_baseline.json prevent silently patching a different revision.
overlay/ contains board RTL, the DDR block-design Tcl and mailbox constraints.
baseline.json hashes board inputs that must be reviewed on a future rebase.
No functional changes are hand-patched into generated SoC Verilog.

Reproduction (from the project root)
-----------------------------------
1. Create a NEW private Chipyard snapshot with the existing
   soc_shell/npu100_video/prepare_workspace.py --destination <private-path>.
2. Run the existing sync_npu_sys_to_chipyard.sh with CHIPYARD_ROOT set to it.
3. Run scripts/prepare.py --chipyard <private-path> --output <NEW-source-dir>.
   Do NOT run the production sync script again after applying V3 overrides.
4. CHIPYARD_ROOT=<private-path> bash scripts/elaborate.sh
   (script paths here are relative to soc_shell/memory_parallel_v3/).
5. Run scripts/check_structure.py <private-path> <DDR-IP-dir> <report.json>.
   DDR IP is created using Vivado -mode batch -source scripts/check_ddr_ip.tcl
   -tclargs <NEW-DDR-IP-dir>. This validates/generates IP only; no synth run.
6. Run scripts/test_cache.sh <NEW-test-dir> [MemoryV3Test|MemoryV3IdTest|
   MemoryV3MmioTest] with CHIPYARD_ROOT set. Run scripts/test_sv.py for board
   RTL tests and scripts/test_crossbar.py <NEW-test-dir> for vendor AXI RTL.
7. Vivado -mode batch -source scripts/ooc.tcl -tclargs
   <head|counters|l2|sbus|mbus> <NEW-report-dir> [generated-gen-collateral-dir].
8. scripts/lint_wrappers.py <source-snapshot> <generated-gen-collateral-dir>
   <DDR-IP-dir> <NEW-lint-dir> checks actual generated module port declarations.
   Generated internals are stubbed only for this wiring check; use the separate
   functional tests and generated DDR IP connectivity audit above.

The chosen configuration is
  tsmcchip.fpga.taihangsoc.TaihangSoC1Rocket1RVV3Gemmini32x32MemoryParallelV3Config
and the top module remains TaihangSoCFPGATestHarness with an added
memory_perf_* sideband. The SoC and board overlay must be selected together.

Full project build (subsequently authorized by the user):
* Export the postprocessed V3 SoC with the existing
  soc_shell/npu100_video/export_video_soc.py into a NEW destination.
* python3 scripts/build.py --soc-export <frozen-export-config-directory>
  prepares a new build/bitstream_memory_parallel_v3/<timestamp>/workspace.
* python3 scripts/build.py --launch-results <that-new-build-directory>
  runs synthesis, implementation and bitstream generation. Launch detached
  when monitoring only through synthesis. Do not interrupt it at that point.
* SYNTHESIS_DONE marks completed synthesis AND the mailbox constraint check.
  console.log, build.log and workspace/prj/sixteen_camera.runs/synth_1/runme.log
  are the logs. Full implementation continues in the same independent build.
* The builder regenerates DDR BD/IP from V3 Tcl, registers the three new RTL
  files, and applies the CDC Tcl after link through a pre-opt hook. It retains
  the passing V1 placement/optimization strategy and real timing constraints.
* Following the user's prior instruction, a legal routed design may generate
  a bitstream with negative timing; final_status.txt then says TARGET_MET=0
  and BUILD=BITSTREAM_TIMING_UNMET. No DRC severity is downgraded.
* Old projects, exports and bitstreams are untouched. The build records SHA256
  inputs and checks preservation of the original project/output directories.
Do not use an old design_1_wrapper or production SoC with the V3 board RTL.

Limits
------
Local synthesis is not a routed timing signoff. Full build status belongs to
its independent results directory; no board performance claim is made here.
The two-bank distribution proof concerns equal offsets in the current
worker input/activation arenas; actual bank balance must be measured.
DDR has a shared physical channel. Two banks and wider AXI increase available
concurrency, not physical DRAM bandwidth. S02 is currently tied idle.

L2 directory hit/miss events include all directory lookups (also coherence
and replay), not just primary Gemmini load misses. Per-client counters are
at the two L2 entrances after the system-bus arbitration. They do not measure
requests blocked before reaching those entrances. Bank/client stall counts
can overlap and must not be added as disjoint execution time.
