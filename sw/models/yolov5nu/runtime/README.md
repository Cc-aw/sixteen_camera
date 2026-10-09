# YOLOv5nu cooperative runtime

The validated 640×480 Stage8F AOT graph is shared by dual16 (two DIM16 workers) and single4 (one DIM4 worker), with matching Gemmini parameters. Worker 0 uses custom3; worker 1 uses custom2. Activation and convolution scratch memory are independent per worker.

`generate_runtime.py` transforms `../aot/` into 167 cooperative stages, including Head publication and the worker profile template. Run `make -C sw yolov5nu-regenerate` from the repository root. The generated C file is checked in; normal firmware builds do not regenerate it.

With continuous inference disabled, UART `t` runs embedded image025 and checks checksums, sparse DFL candidates, NMS output and worker equality. Build/download with `tests/rtl/run_yolov5nu_dual_correctness.sh`; it leaves UART operation to the user. Parse a saved log with:

```bash
python3 tests/rtl/test_yolov5nu_dual_correctness.py --log uart.log --workers 2
```

Use `--workers 1` for single4. Generic queues are tested separately at three workers; the model itself supports one or two workers.
