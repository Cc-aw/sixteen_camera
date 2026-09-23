# PCLK capture optimization bundle (pre-route)

This bundle follows the P5 routed baseline in
`pclk_p5_routed_baseline_20260923.md`. No new full-system placement or route
has been run for these changes.

## RTL changes

- Registered the event-bridge overflow diagnostic pulse before the wide
  saturating counter. Fault/drop control still reacts in the original cycle.
- Registered the final recovered sample tap, increased production DATA history
  from six to eight entries, and removed reset from history payload registers.
  The default tap=2 sampling position is preserved.
- Registered SEARCH interval flags and a latency-compensated edge phase anchor
  before the recovery FSM. Recovery thresholds and policies are unchanged.
- Moved loss snapshots, min/max, short-pulse, and wide counters into
  `dvp_pclk_telemetry`. The recovery core emits registered diagnostic events;
  telemetry does not backpressure functional recovery. The existing recovery
  module name and ports remain compatible with callers.
- Narrowed accepted/raw elapsed counters and their edge snapshots to seven
  bits with saturation at 127. All configured valid intervals and the 2T
  harmonic window fit below this limit. The `last_interval` and
  `raw_candidate_interval` debug outputs now saturate at 127 after a longer
  gap; these outputs are unconnected in the production frontend.
- In a separate follow-up change, narrowed core phase/period arithmetic from
  fixed 24 bits to `PERIOD_FRAC_BITS + 8` bits (16 bits for the board's Q8
  configuration). The phase accumulator wraps at 256 capture clocks, and lock
  decisions use the signed modular difference around the predicted edge.
  External estimator and diagnostic ports retain their 24-bit widths.
- Added a real classification stage between the edge snapshot and recovery
  FSM. It registers phase and raw-period decisions from the captured edge
  state. The missing-edge deadline is predicted into a register one clock
  ahead. Pending edges are resolved before declaring a miss, and synthetic
  holdover CE receives its own alignment delay so the final sampled byte
  remains on the previous board phase.
- The capture soft SLR pblocks now select recovery leaf logic without pulling
  the telemetry child into the same region.

## Verification before layout

- Before this new PCLK RTL was built, the user ran the single-4x4 Gemmini
  bitstream with live video and YOLOv5nu inference: the UART status reported
  `jobs/done/post/pub=3/2/2/2`, `fault=0`, `err=0`, and a published CH4
  detection. This validates that board/firmware baseline, not the new PCLK RTL.
- `scripts/run_video_refactor_tests.sh`: pass, including PCLK recovery,
  event bridge overflow/resync, CDC, DMA, frame manager, and mosaic tests.
- PCLK recovery test includes a 200-cycle HREF-gated PCLK gap, beyond the
  new seven-bit saturation point, and checks reacquisition.
- A side-by-side simulation of the prior recovery RTL and this bundle matched
  all 300 emitted `{HREF, VSYNC, DATA}` events, including a 200-cycle gap.
- Standalone Vivado 2023.2 synthesis of the recovery and telemetry modules:
  0 RTL errors. Under identical settings, the 24-bit reference used 861 LUT /
  1287 FF; the narrowed version uses 694 LUT / 1151 FF. The recovery core
  changed from 679 LUT / 437 FF to 516 LUT / 341 FF. Production pruning
  differs because most diagnostic ports are unconnected there.
- The full `scripts/run_video_refactor_tests.sh` regression passed after the
  phase-width change. A side-by-side simulation using the same recovery test
  stimulus and a 24-bit reference matched `pixel_ce`, emitted pixel data,
  HREF/VSYNC, lock state, recovery state, and period estimate cycle by cycle.
  This includes the 200-cycle HREF-gated gap and repeated phase wrap.
- After the classification/deadline change, the full video regression passed
  again. A cycle-by-cycle comparison against the pre-change recovery RTL
  matched `pixel_ce`, emitted DATA/HREF/VSYNC on every test cycle, including
  the single missing edge, short and wide glitches, harmonic rejection, and
  the long blanking gap. Standalone Vivado synthesis completed with no RTL
  errors at 740 LUT / 1187 FF total (562 LUT / 377 FF in the core). The
  pipeline adds 46 LUT / 36 FF versus the narrowed pre-classification core;
  it remains 121 LUT / 100 FF below the 24-bit reference standalone result.
- The next fast-core follow-up moved the independent raw-period IIR calculation
  from the edge-snapshot stage into the registered classification stage.
  SEARCH and ACQUIRE counters now have widths derived from their configured
  thresholds; ACQUIRE saturates once its edge threshold is reached. The
  one-missing-edge state uses one bit, and the period-stability counter
  saturates at eight. The PCLK recovery test and cycle-by-cycle pixel/CE
  comparison with the pre-classification RTL passed. Standalone synthesis
  completed without RTL errors at 721 LUT / 1181 FF total, 19 LUT / 6 FF
  below the previous classification version. No full-system synthesis,
  placement, route, or bitstream was run for this follow-up.

## Route acceptance still required

The next routed build must recheck the 1.500 ns IOB→sync budget, capture
WNS/TNS and failing endpoints, recovery/telemetry placement, cross-SLR paths,
and CDC/methodology reports. The old routed DCP cannot prove timing for this
bundle. The phase-width change has passed simulation and standalone synthesis,
but its physical timing effect and camera behavior still require a new routed
build and board check.
