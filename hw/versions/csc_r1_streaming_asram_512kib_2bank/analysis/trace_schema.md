# G0 baseline diagnostic trace schema (version 1)

These probes observe the generated C0 RTL. They do not change the command,
memory delay, arithmetic, SRAM arbitration or completion path. All three lanes
run concurrently. The workload covers stages 0/2/4/5/8/10/59/132 with compact
spatial shapes and frozen native channels, parameters, LUTs and packing.
All four runtime modes run; lifecycle collection is restricted to mode 2.
Each stage initializes deterministic synthetic input bytes independently; these
are not the activations produced by the preceding full-network stage. Cross-stage
value coincidences in this fixture cannot establish native source identity.

This is a **partial G0 diagnostic schema**, not the complete network evidence
required by CSC-R1 §3.2. Missing lifecycle/epoch evidence must remain unknown.

## Identity and scope

`adapter_manifest.json` identifies the C0 generation context, parent driver,
adapter and probe sources. `trace_manifest.json` binds the generated workload,
all six lane trace files and probe text with SHA256. The parent runner verifies
every generated RTL file against `final_rtl_sha256` before compilation.
`source_rtl_sha256.json` records the actual compiled source closure and wrappers.

The lane is encoded in the filename. `cases.json` maps `layer_case` to the
original stage and records the exact compact shape. `trace_epoch=layer_case`
is only a fixture boundary label. It is **not** a proven native producer epoch.
No full-model frame, HOST ownership or source generation is inferred from it.

## `spad_events_lane{0,1,2}.csv`

Headerless columns, inherited from the baseline simulation probe:

```text
event_seq,cycle,event,trace_epoch,runtime_mode,layer_case,bank,row,mask_hex,data_hex,owner,aux
```

- `BEGIN`, followed by 8 × 2048 `SNAPSHOT` rows, gives complete initial SRAM
  contents at the start of mode 2. The test SRAM was initialized at reset;
  snapshots reflect the earlier runtime-mode workloads too.
- `LOAD_ACCEPT` is a first-row ready/valid handshake at LoadController's DMA
  interface. `owner` is a monotonically increasing logical load sequence;
  `aux` is expected completion credit in bytes. The legacy packed `data` word
  is retained verbatim and is not independently decoded here. `rows_laneN.csv`
  preserves the accepted source address, stride, columns, row count and zero flag.
- `LOAD_CREDIT` and `CMD_COMPLETE` carry actual returned byte credit and ROB
  completion. They are checked independently of physical SRAM writes.
- `BANK_ACCEPT` and `BANK_COMMIT` identify actual pending-bank queue admission
  and dequeue. Bank write ready is constant true in this audited generation.
  `mask` selects bytes, least-significant byte first. `aux=0/1/2` distinguishes
  DMA/EX/zero. Queue ownership must match exactly from admission to commit.
- `DMA_CANDIDATE` observes a pending DMA write offer; `aux` is ready. An offer
  alone never changes reconstructed SRAM or counts as a committed write.
- `READ_INTENT`, `READ_ACCEPT` and `READ_DATA` carry a separate monotonic
  request ID in `owner`. The consumer-visible returned 32 bytes must match the
  reconstructed SRAM at the physical read handshake. Intent presence is checked;
  producer-dependent early-read equivalence is not established by this check.
- `BOUNDARY` compares observed commits with the generated SPAD write counter
  delta. `END`, complete snapshots, contiguous sequences, empty physical queues
  and closed logical load credits are required for a successful reconstruction.

Events from each bank preserve its procedural ordering. Cross-bank events on
one clock edge are serialized by the simulator; this order does not establish
cross-bank dependency precedence. No skip decision is made from that order.

## `lifecycle_lane{0,1,2}.csv`

Common columns:

```text
event_seq,cycle,layer_case,runtime_mode,latest_accepted_packet_seq,event,...
```

Payloads:

```text
CMD: funct_decimal,rs1_hex,rs2_hex
TL_A: opcode_decimal,source_decimal,size_decimal,address_hex,mask_hex,data_hex
TL_D: opcode_decimal,source_decimal,size_decimal,denied_decimal,corrupt_decimal,data_hex
```

All CMD and TL observations use `ready && valid`. `CMD funct=15` increments
the packet sequence; funct 16–21 preserves raw configuration operands.
`latest_accepted_packet_seq` is a time correlation label, **not** a DMA owner
tag: overlapping Loop slots can have older requests in flight. TL A comes from
the real Gemmini physical port before the fixture's frontend mux; command-table
fetches are excluded. The current fixture routes this workload to DDR. ASRAM
and mixed-route regression evidence is recorded separately.

Get bytes are measured as `1 << size` per physical A handshake. D beat counts
are checked against source, opcode and size. A single response beat carries
32 bytes or a smaller transfer. Late errors are tested by the separate fault
suite; the normal trace must have no denied/corrupt responses.

## Interpretation limits

`same_value_bytes_at_commit` counts value equality immediately before actual
DMA writes. It includes coincidences and partial-row equality. It does not
prove equality at Load issue, source identity/version, scale equivalence,
stable ownership, complete-Load residency or legal consumer dependencies.
`eligible_exact_*`, `exact_resident`, relocation and sliding-window opportunity
counts remain null until those proofs and complete network coverage exist.

The analyzer also reconstructs every command's eventual written byte footprint
against SRAM history at that command's first accepted row. It rejects overlapping
intervening writers for `loads_value_resident_at_issue_without_intervening_writer`.
This is a stronger value diagnostic, but still does not prove source epochs,
conversion/layout identity, a complete native Load footprint or legal skip-token
completion. It must not be promoted to `eligible_exact_mvin_commands`.
