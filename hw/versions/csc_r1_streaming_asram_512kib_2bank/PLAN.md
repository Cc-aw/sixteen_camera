# CSC-R1 simulation implementation

The controlling plan is [CSC-R1](../../../docs/architecture/CSC-R1.md).
This directory implements G0 capture, replay and qualification, followed by an
experimental switchable C1a generated-RTL overlay. G0 archives are immutable;
new G1 evidence and source identities belong to a separate run/archive.

1. Freeze HEAD, dirty patch, untracked/modified file copies and hashes in a new
   ignored experiment directory. Pre-register decision thresholds before results.
2. Audit the streaming + ASRAM parent sources and generated candidate identity.
3. Replay compact native layers on three real generated DIM32 Gemminis in all
   four DMA modes, comparing complete outputs against legacy. Capture three-lane
   SPAD/EX, command, credit/completion and physical TL events in mode 2.
4. Independently rerun real ASRAM/vendor-URAM routing and late-error/reset tests.
5. Roundtrip all 58 ordinary full-size native plans. Inventory prepared WS stages
   and existing operand retention; do not interpret logical payload as TL bytes.
6. Capture every native stage on three lanes for two frames, including all
   ordinary Conv, prepared WS and memory-kernel commands. Preserve native arena
   aliases, execute recorded CPU padding and initialize frozen parameters.
7. Calibrate real C0 unroller requests and full physical writes against the
   compact XSim trace. Synthetic completion enumeration is a diagnostic only.
8. Replay the whole native workload on actual C0 RS/EX/DMA/FP16/SPAD logic with
   deterministic private physical-memory services. Record real byte commits,
   source generations, all reads, native boundaries and completion ledgers.
9. Qualify complete matching Load descriptors after full physical commit, not
   just credit/ROB completion. Reject source mutations, pending writers, every
   overlapping overwrite, partial-region matches and destination remapping.
10. Publish full per-stage traffic/opportunities, zero-load and R2 diagnostics,
    hashes and a fail-closed G0 decision. Actual shared-system time weighting is
    still required for the alternative hotspot gate; functional stage cycles do
    not establish CPU/PPU cost or system FPS.

The native 10,000-cycle simulation watchdog rejects a legal pool5 store. An
isolated native replay completes with the existing `gemmini_timeout=60000`
plusarg; retain all assertions and the failed default-timeout evidence.
Full functional lane aggregation preserves timestamps and physical lane
identity. It does not model shared DDR/ASRAM arbitration or a complete CPU/PPU.
Only G0 PASS authorizes implementation of the smallest switchable candidate;
only G1 correctness PASS authorizes candidate cycle A/B performance evaluation.
No physical implementation or board access is part of this work.

The C1a prototype and supported geometry are documented in
[analysis/c1a_design.md](analysis/c1a_design.md). Validate bounded descriptor
coverage, disabled cycle identity, complete numerical results, actual completion
and fault/reset behavior before allowing G2 timing conclusions.

The Store-wait optimization proves unissued output ranges disjoint for both
Loop slots and the active Store generator. Derive-pending slots use their
configured outer channel bound. Unsafe/unknown cases reload immediately;
issued Store, Load/Weight/Bias and physical commit drains remain in force.
Archive its full regression separately under `validation/g1_store_wait`,
including source-writer fallback, all four modes, fault/reset, complete native
network comparisons and diagnostic functional cycles. These cycles alone
cannot satisfy G2 or authorize a bitstream.
