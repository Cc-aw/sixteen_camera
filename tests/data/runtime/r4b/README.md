# R4b frozen Application and Runtime oracles

These files are exact copies from commit `4c704f5`. They remain independent
of current facade/application edits; the removed bridge header is supplied
only to the frozen main fixture.

- `main-reference.c.inc`: `sw/src/main.c`
  SHA-256: `71dae1004c7a0bee2953dc0c061ae02ae2a2829997edd8ad02757205acfc6534`.
- `stream-runtime-reference.c.inc`: `sw/src/ai/runtime/ai_batch_runtime_stream.c`
  SHA-256: `88e9eb5f7b75b437e97a9a5b055b8a81de7e6c7884364780db9c4d95615f2b02`.
- `bridge-reference.h.inc`: `sw/src/ai/runtime/ai_runtime_bridge.h`
  SHA-256: `f543a5d26082b9c3dc7a0eb8e97ab98490be4ce99bb5bb65df67e853ccedbf78`.

Application comparison runs the actual old/new main loops with the same
video/Runtime/reader/CSR doubles and records all diagnostic MMIO, fences,
logical cycles, UART arguments and service calls. The Tensor ingress snapshot
API is a double; its production HAL is unchanged and checked separately.

Runtime comparison invokes the current canonical facade and diagnostics directly
against the frozen old facade, using the same production core/services/Ops
and original scheduler/fault workloads. No traces are filtered.
