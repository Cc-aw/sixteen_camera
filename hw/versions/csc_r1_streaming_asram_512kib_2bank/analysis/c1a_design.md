# Experimental C1a implementation

The G0 full-network byte gate authorizes this prototype. It does not establish
that two bounded descriptors capture the unbounded G0 catalogue, or that saved
traffic produces throughput. G1 and G2 remain separate acceptance gates.

## Representation

`rtl/CscR1InputResidency.sv` holds two descriptors, selected by the **effective
physical SPAD half**, after both loop-slot selection and `a_ex_spad_id` overrides.
Each descriptor describes the complete Input generator request, including all
its real Mvin and zero-padding commands. There is no partial Load omission.

The 232-bit unhashed key includes the actual source address, source strides,
padding, padded/unpadded geometry, channels, and bank stride. It intentionally
excludes output-channel and Weight geometry, which do not affect Input bytes.
The generator fixes identity FP16 scaling and the normal int8 format. Hits
preserve its original configuration command, including after raw configuration.

The first prototype supports batch 1, normal layout, no downsampling or input
dilation, and one pixel repeat. It checks that the complete destination fits
one 8,192-row half, that the bank stride equals the untruncated spatial area,
that padding extents agree, and that source arithmetic neither wraps the
generator's 32-bit offset ring nor exceeds the 33-bit physical memory service.
Other cases execute C0. This experiment uses the verified bare-metal identity
address mapping; translated aliases are outside its supported integration.

The source interval conservatively includes gaps between rows/channels. Every
overlapping real TL Put invalidates the descriptor; disjoint output stores do
not. Candidate acceptance/promotion also waits for issued stores to drain, so
an earlier pending source writer cannot be hidden by an early completion.

## Commit and writer ownership

An accepted miss starts a building descriptor. The Input generator must finish
emitting **all** commands, the real LoadController, RS load/store utilization,
Scratchpad DMA engines, future Weight/Bias generators and every physical
bank write queue must drain before promotion. New Weight/Bias requests also
block a hit in their acceptance cycle. Credit/ROB retirement alone cannot
promote a descriptor.

The Store-wait optimization removes the requirement to finish generating
unissued Stores before reuse. `CscR1StoreDisjoint.sv` proves their entire
output envelope disjoint from the requested Input source, including aligned
64-byte TL beats and gaps between rows. It checks both Loop slots, including
pending derivation, and the independently latched active Store generator;
a slot can be recycled while the latter still drains. Derive-pending slots
already hold their complete native configuration, so their full outer output
channel count supplies a conservative bound without reading stale derived
parameters or discarding a pending Input match. The proof supports
normal, unpooled, batch-1 output with checked stride and nonwrapping offsets.
The prototype's frozen legal native tiling contract requires tile output
channels not to exceed the configured outer channels. The independent
`store_bound_contract.py` audit pins the actual configuration packing and
derived-ochs pipeline and checks all 2,938 workload/fixture Conv packets.
Arbitrary malformed native packets are outside this prototype's contract.
Unknown geometry or any overlap disables admission and executes the original
Input load immediately. It does not wait for a potentially dependent Store.
Null output pointers emit no Stores and are safe. This is an admission check,
not a new completion or DMA credit. Already issued Stores, Load traffic,
physical bank queues, and same-cycle invalidation retain their original
drain checks. The earlier global-drain prototype and its measurements remain
immutable in `validation/g1`; new measurements require a separate archive.

Every tile request receives a monotonically increasing 32-bit writer sequence.
Two bounded metadata FIFOs carry the sequence from the Input command generator
through in-order RS load issue and the LoadController's first-row acceptance.
The actual two DMA tags retain that owner until physical bank acceptance.
These FIFOs hold ownership only; commands, data, ROB entries and credits follow
their unchanged C0 paths. Their bounds/underflow and the two-tag assumption are
asserted. Exhausting the writer sequence disables reuse until reset.

While a descriptor is building, only writes carrying its exact sequence may
contribute. A previous Input tile, ordinary DMA, zero command from another
owner, or EX writer invalidates it on any overlapping physical row. Once
resident, **every** overlapping writer invalidates it, including identical
data. A pending bank commit blocks a hit. Invalidation wins same-cycle races
with promotion or lookup. This avoids re-reading a recycled DMA tag at commit.

## Replacement completion

The hit preserves the Input generator's original configuration command and
cuts its complete Mvin sequence. The generator then follows its normal
pipeline-empty/idle/loop-completion path. The configuration still enters the
real RS and retires normally; no Mvin RS entry or DMA tag is created, and no DMA
credit or ROB retirement is fabricated. Preserving this configuration prevents
subsequent raw Mvin commands observing stale scale/stride/pixel state. An
independent one-per-hit completion observation token checks the lifecycle.
Compute, Weight/Bias generation, Store, and output addressing remain unchanged.

A matching descriptor, including one still being filled, waits for physical
quiescence and promotion. Native null Input operands preserve residency and
retain their original no-command behavior. A miss uses the original ready/valid
path. With `csc_enabled=0`,
both lookup and waiting are disabled; cycle/event identity is checked against
the unmodified C0 simulation, in addition to numerical comparison.

## Boundaries and integration limits

The experiment's explicit `csc_clear` input is driven by native HOST/DRAIN and
frame boundaries. A mode change or disabling CSC clears descriptors. Raw
Load/Compute/Store or Matmul commands quarantine admission until the whole
Gemmini drains. Configuration/LUT commands do not write SPAD and do not by
themselves quarantine admission; the preserved Input config maintains their
correct state ordering. Real
late denied/corrupt responses or an interrupt disable reuse until actual reset.

`scripts/candidate_rtl.py` applies a SHA-guarded, experiment-local overlay to
the complete frozen generated RTL closure. `CANDIDATE_CONTEXT.json` records
both original and modified files. The parent context and production SoC are
never edited. This is a generated-RTL prototype, not a regenerated production
Scala export. A future production integration must wire the real frontend
boundaries and establish the physical address-mapping contract explicitly.

`build_candidate.py` builds OFF/ON into the same complete Gemmini binary with
all RTL assertions enabled. `run_candidate.py` preserves each physical lane's
addresses and backpressure schedule. Its private functional memory services
do not include shared DDR/ASRAM arbitration or CPU/RVV/PPU timing. Their cycle
counts cannot satisfy G2 or establish full-system FPS.

`compare_candidate.py` checks each actual SRAM response against independently
reconstructed committed memory, then compares all C0/C1a consumer bytes,
final SPAD bytes and every masked TL output-store byte. It fails closed on an
incomplete read, Put, or replacement-completion ledger. `run_accumulator.py`
reads all four actual 512-row, 1024-bit Accumulator RAMs at native completed
fences; `compare_accumulator.py` compares every captured byte. This is a
separate check from output-store comparison, and does not change the RTL or
simulation cycle schedule.

`g1_transactions.py` independently closes native-command, Mvin row/credit/ROB,
Reader reservation, Get/Put response and physical bank acceptance/commit
ledgers. It retains the accepted logical owner across legal tag reuse before
the last bank commit. Its negative controls reject oversized credit, early
retirement, unfinished transfers and fake replacement completions.

The current overlay binds generated hierarchy probes. A production export
still needs explicit frontend boundary wiring and a review of synthesis-portable
interfaces, geometry arithmetic and ready-path timing; no such physical
validation is claimed by these functional tests.
