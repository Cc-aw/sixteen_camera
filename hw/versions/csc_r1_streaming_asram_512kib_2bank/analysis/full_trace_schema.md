# Full native G0 capture

The command capture executes the frozen C packet submitters and specialized WS
functions, including three pool5 and two resize stages. It checks the source
lock and records all 166 nonterminal graph stages, 462 ordinary packets, 224 WS
packets, 1,944 memory-kernel Mvin and 624 memory-kernel Mvout per lane/frame.
Six native pool padding services execute their frozen padding semantics in the
functional memory model. Six Head services are explicit output-only boundaries;
PPU execution is outside this load-residency measurement.

Weights/bias come from the frozen parameter arrays. DDR symbols are relocated to
distinct 64-byte aligned ranges; native activation-arena aliases and each lane's
ASRAM physical base are preserved. Input is a deterministic full 480x640x3
fixture. This is not a recorded board image or a full-network numerical oracle.

## Two distinct RTL experiments

`full_command_rtl.py` runs real LoopConv, LoopMatmul and LoadController with a
synthetic completion backend. Its source-identity model ignores EX writes,
source updates and real retirement timing. Its estimated Get bytes and tick
counts cannot pass G0 or serve as performance results. Three-lane request
multisets were calibrated against the complete Gemmini compact XSim traces.

`full_gemmini_rtl.py` runs the unmodified C0 Gemmini closure, including RS, EX,
FP16 conversion, load/store controllers, Reader, A1 and physical SPAD memories.
Its external physical memory is a deterministic functional service. ASRAM and
DDR share this service in the harness, so there is no faithful shared-system
timing model. Existing parent regressions separately exercise actual ASRAM TL
and vendor URAM. No full-system FPS or speedup follows from this harness.

The SiLU RAM uses the Xilinx 2023.2 functional primitive. An experiment-local
copy omits its unsupported `specify` timing annotation and simplifies Z tests
on explicitly driven two-state inputs. Functional logic and scheduled delays
remain. Both original and adapted SHA256 are recorded. All eight compact
stages' physical write bank/row/mask/processed bytes/writer types are compared
against archived unmodified-vendor XSim results before accepting full results.

## Full trace CSV

Every row starts `event,cycle,lane,frame,stage,event_seq`. Build id, source hashes,
runtime mode (`read_assembled`) and simulator identity belong to the run's
manifests. SRAM power-up in the two-state Verilator model is zero; a reusable
descriptor always requires a prior real completed Load and never matches
unknown initial contents.

| Event | Fields after the common prefix |
|---|---|
| B | marker (253 stage / 254 HOST / 255 native fence), source, destination |
| C | accepted native funct, rs1, rs2 |
| R | first, last, row_index, cmd_rows, physical_cmd_id, paddr, physical_local_row, is_acc, cols, repeats, scale, wide, zero, block_stride, pixel_repeats, source_stride, load_rob_id |
| G | actual Reader transaction reservation source, original Load cmd_id (group ownership resolved from the real descriptor) |
| T | actual external TL A opcode, source, size, physical address, byte mask, data |
| D | actual external TL D source, size, opcode, beat, data |
| A / W | bank, row, byte mask, writer type, physical cmd_id, data |
| I | real EX read intent bank, row (one record each asserted cycle) |
| Q / V | accepted SRAM read bank, row / returned bank, data |
| Y / X | returned DMA cmd_id, byte credit / actual retired Load ROB id |
| S | stage functional cycles, EX active, SPAD A/B/D wait, Load busy, row backpressure, union of A/B/D wait |

The native C stream supplies ordered packet launches/configurations. A raw
packet launch number is not assumed to equal a physical Load tag or loop slot.
The physical proof uses the actual accepted Load descriptor and bank/byte
coordinates. The current trace does not assign guessed loop-slot identities.

## Qualification and failure checks

`full_lifecycle.py` compares complete descriptors, source physical-byte versions,
and actual committed byte ownership. It requires the previous whole Load's
credit, ROB retirement and physical write coverage to finish. Any intervening
overlapping EX/DMA/zero writer invalidates residency even if values agree.
Pending writes reject reuse. Every write of a candidate must be individually
idempotent and no other writer may overlap before its last commit. Actual
Reader reservations attribute measured TL Get bytes to Load owners.

DMA tags can recycle after credit/ROB completion while the old last physical
write is still queued. This is legal C0 behavior. Queue entries retain the old
logical owner; tag recycling never establishes residency or transfers ownership.

Source generations change on actual masked TL Put bytes and HOST pad writes. Tracking
uses physical bytes, so a neighboring-byte mutation does not reject an unchanged source. Frame
switches invalidate all descriptors. A completed DRAIN does not mutate memory;
retention across it requires the same generation and writer proof. No CPU
modification outside the recorded native HOST schedule is assumed.

The auditor checks contiguous events, all DMA rows, credit/ROB closure, actual
SRAM acceptance/commit queues, reconstructed masks, every SRAM read response,
Reader reservation/TL A/D ledgers, full stage/frame coverage and independent
simulator totals. Missing completion markers, truncated files or omitted lanes
fail. Single-stage and compact analyses are explicitly partial scope.

Qualified baseline opportunities are not an implemented or validated skip
controller. G1 must still prove replacement completion tokens, descriptor size,
reset/fault behavior and hypothetical timing changes. The analyzer uses an
unbounded descriptor catalogue; a small hardware implementation can realize less.

`validate_elision.py` performs a separate deletion replay after qualification.
It removes every physical SPAD write of each final qualified whole Load and
accounts for all its original Get bytes. It retains the recorded credit/ROB
tokens and consumer times, representing local replacement completions. Every
real SRAM read response must remain byte-identical. This is a fixed-timeline
data-equivalence model; it proves neither an implemented skip controller nor
an earlier completion or throughput gain.

Zero writes use the actual selected producer: `zeroWriteBuffer` for the legacy
zero writer and `mvinWriteBuffer` for grouped zero rows. They are not assigned
the unrelated current ordinary DMA tag. Whole zero-load matches are reported
separately; they never add eliminated Get bytes.

The original native `gemmini_timeout=10000` simulation watchdog rejects the
long pool5 store operation. An isolated, unchanged stage-75 replay completes
with `+gemmini_timeout=60000` in 90,657 functional cycles. The selected-lane
runner records this explicit existing plusarg; all RTL assertions remain
enabled. Failed default-watchdog runs are retained and excluded from accepted
evidence. No source assertion or hardware configuration is removed.

Independent functional lanes may run in separate host processes. Their
physical lane addresses and per-lane stall seed remain intact. Assembling
those files preserves every event timestamp; it does not create shared DDR
timing or a three-lane throughput result. Lane 0 can serve as the single-lane
functional control, explicitly identified as reused evidence.
