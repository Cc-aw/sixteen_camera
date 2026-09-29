# YOLOv5nu dual Gemmini16 runtime

This directory adapts the imported 640x480 Stage8F YOLOv5nu AOT graph to the
two Gemmini16 accelerators in this project. Worker 0 dispatches RoCC commands
to custom3 and worker 1 dispatches to custom2. Each worker owns independent
activation and convolution scratch memory.

`generate_runtime.py` mechanically splits the validated AOT `main()` into 167
cooperative graph stages. The 78 Gemmini stages return to the batch scheduler
after command submission; polling waits on busy CSR 0x7c2 or 0x7c3 before CPU
post-processing and submission of the next stage. This permits batch=2 layer
overlap without changing the model parameters.

Run `make yolov5nu-regenerate` from `sw/` after replacing the imported Stage8F
source. The normal `make` target builds YOLOv5nu by default; use
`make AI_MODEL=yolov2` for the previous TinyYOLOv2 image.

For the board correctness test, press `t` while the continuous AI runtime is
disabled. It runs embedded image025 on both accelerators and checks bit-exact
FNV/checksum signatures, sparse DFL candidates, NMS output, and cross-worker
equality. From the repository root, build and download with:

```sh
scripts/run_yolov5nu_dual_correctness.sh
```

The script deliberately does not open, read, or write the UART. Keep using
your own serial terminal and manually press `t` after download.

An existing UART log can be checked without board access using:

```sh
python3 scripts/test_yolov5nu_dual_correctness.py --log uart.log
```
