# P5 routed capture baseline (2026-09-23)

Source: `prj/sixteen_camera.runs/impl_1/top_wrapper_routed.dcp`,
SHA-256 `2aa698a571b6d077bee3b90cfd7c3d8b5d3c80c4af125e5a15d4432d7588fdbc`.
The route completed at 12:49 local time. The routed timing summary was
generated at 12:47. This checkpoint predates the PCLK RTL changes described
below.

The full design reports WNS -8.066 ns, TNS -245784.766 ns, and 155186
failing setup endpoints; most of these are in the `clk_100m_p` SoC domain.
The 300 MHz `mmcm_clkout0` group reports WNS -0.218 ns, TNS -38.411 ns,
and 460 failing endpoints. These clock-group figures include other 300 MHz
logic and are not a PCLK-only signoff.

Targeted reports were generated from the checkpoint with
`scripts/report_pclk_capture_timing.tcl`:

| Path set | Result |
| --- | --- |
| DVP IOB→sync, 1.500 ns datapath-only | 88 paths; 4 violations; worst slack -0.163 ns |
| CH0 HREF / PCLK | -0.163 / -0.125 ns |
| CH1 HREF / PCLK | -0.012 / -0.005 ns |
| Capture endpoints, worst sampled path | -0.218 ns, reset release to event bridge overflow counter CE |
| Recovery endpoints, worst sampled path | -0.217 ns, edge interval to expected-phase CE |

The targeted capture/recovery reports request 200/100 worst paths, so their
sampled violation counts are not totals. The 88 IOB→sync paths are complete.

The first RTL step registers the overflow diagnostic event, registers the
final recovered sample tap, extends production history to eight samples,
removes history-payload reset, registers SEARCH interval classifications, and
snapshots the measured edge phase with its existing FSM latency accounted for.
No threshold, recovery policy, or 1.500 ns physical budget changes were made.
These changes require a new routed checkpoint before timing improvement can
be claimed. In particular, the four IOB→sync violations need a placement
check after routing; RTL pipeline changes do not prove their removal.
