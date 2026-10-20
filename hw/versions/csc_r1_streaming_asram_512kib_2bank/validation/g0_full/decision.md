# CSC-R1 full G0 feasibility evaluation

G0: **PASS**. Final physical-prototype decision: **INSUFFICIENT_EVIDENCE**.

Reason: `G0_PASS_CANDIDATE_G1_G2_NOT_RUN`.

The baseline is frozen streaming + ASRAM C0. Existing LoopConv input reuse, native null-operand retention, WS/B reuse and A1 request grouping are already included. No candidate skip controller is enabled.

Full trace: 421,746 Mvin, 177,340,416 actual TL Get bytes; 19,608 qualified whole-Load opportunities and 13,390,080 attributed Get bytes.

Eligible read fraction: 7.550495% (preregistered byte gate: 5%).

These are baseline residency opportunities, not measured candidate savings or a throughput improvement. An unbounded descriptor catalogue is used; a small hardware implementation may realize less.

The functional harness executes actual C0 RS/EX/DMA/FP16/SPAD logic with private physical-memory services. All three lane identities and native activation aliases are retained. It does not model shared DDR/ASRAM timing, CPU instruction cost or PPU completion. Stage cycle and operand-wait counters are accelerator-only diagnostics and cannot establish full-system FPS.

The default native 10,000-cycle pipeline watchdog rejected a legal SPPF pool5 operation. An isolated native replay completed with `+gemmini_timeout=60000`; all RTL assertions remain enabled. Failed default-timeout and interrupted diagnostic runs are excluded from accepted comparisons.

Whole descriptors require matching source bytes/generations, shape/layout/scale and physical target bytes, full prior SRAM commit/credit/ROB completion, no pending or intervening overlapping writer, and individually idempotent candidate commits. Frames invalidate descriptors. HOST pad and actual masked Put writes update physical-byte generations. Same-source/different-destination remains an R2 diagnostic.

G1 replacement completion semantics, whole-network numerical oracle, fault/reset behavior, descriptor hardware cost and G2 matched A/B cycles remain untested. G0 PASS would authorize further simulation implementation only; it never authorizes a physical build.

Remaining evidence:

- G1: implemented candidate, numerical outputs and completion/fault/reset proof
- G2: matched candidate cycle A/B, shared-system timing and throughput evidence

No synthesis, implementation, bitstream generation or FPGA access was performed.
