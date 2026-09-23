# Retired RTL

This directory contains RTL retained for historical reference and standalone
regression tests. These modules are not instantiated by the current production
top-level design.

The retired tensor-ingest chain consists of:

- `yolov5nu_tensor_slot_ingest.sv`
- `yolov5nu_tensor_capture_sidecar.sv`
- `yolov5nu_tensor_frame_writer.sv`
- `axi4_write_arbiter2.sv`

The production tensor path uses `yolov5nu_multi_channel_tensor_dma` and its
shared `yolov5nu_tensor_stream_packer` instances instead.

`async_fifo.sv` is the retired combinational-read CDC FIFO. Current AXI CDC
bridges use `cdc_payload_fifo`.
