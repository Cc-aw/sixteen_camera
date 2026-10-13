# R4a frozen model backend oracle

`model-backend-reference.c.inc` is an exact copy of
`sw/src/ai/backend/ai_model_backend_yolov5nu.c` at `b1de2e3`.
SHA-256: `6f2a3d3639135658299897f84663f46c58415f973df9e7cd200f1d5c1bb1842e`.

The R4b runner compiles it as a separate reference executable with the same
production Ops adapter, PPU drivers, resource managers and model/CSR doubles.
It compares the complete trace against the extracted service, without filtering
MMIO, fences, logical cycles, result identity, resource ownership or UART arguments.
It must stay independent of future edits to the production backend/service.
