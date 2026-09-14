# YOLOv5nu Stage 8F A-Slice Scratchpad Reuse

Stage 8F is the frozen final bit-exact software/AOT baseline on top of the frozen hardware-aware
Stage 8 baseline. It targets the four dual-consumer Concat nodes:

```text
/model.12/Concat -> /model.13/cv1 and cv2
/model.16/Concat -> /model.17/cv1 and cv2
/model.19/Concat -> /model.20/cv1 and cv2
/model.22/Concat -> /model.23/cv1 and cv2
```

## Idea

The two consumers need the same two input slices but different weights,
biases and accumulator results. Stage 8F keeps the two A slices resident in
separate Scratchpad partitions:

```text
slice 0 -> A-side Scratchpad partition 1
slice 1 -> A-side Scratchpad partition 2
```

The first consumer loads both slices from DDR and computes its two split-K
partials. The second consumer passes `NULL` for both A DRAM pointers and uses
the same Scratchpad partition IDs. Its B-side weights are still loaded and
its accumulator is independent, so this candidate does not share
accumulator state.

The partial-K fences and final output fences are unchanged. Quantization,
bias, requantization, SiLU LUT and output layout are unchanged.

## Implementation

The generated helper is emitted by:

`generators/gemmini/software/gemmini-rocc-tests/imagenet/generate_yolov5nu_baremetal.py`

The build driver is:

`scripts/yolov5nu_stage8f_spad_reuse.py`

Five image-specific ELFs are generated for `025/036/142/404/650`.

## Build checks

```text
shared Gemmini ResAdd calls: 7
split-K consumer edges:      17
Scratchpad-reuse calls:      8
reuse=false calls:            4
reuse=true calls:             4
inactive Concat tensors:      13
direct Concat:                0
arena:                        739200 bytes
```

All five ELFs compile as ELF64 RISC-V with entry address `0x80000000`.

## Validation status

Host generation, compilation and five-image Spike simulation passed. The
five-image FPGA double-run also passed. Class logits, sigmoid, sparse DFL,
Top-10 and NMS match the frozen hardware-aware reference for all images:

```text
image025: class=-6457179 sigmoid=884  dfl=845  top=giraffe
image036: class=-6349811 sigmoid=2202 dfl=2090 top=umbrella
image142: class=-6121235 sigmoid=2339 dfl=2128 top=cup
image404: class=-6505866 sigmoid=905  dfl=801  top=boat
image650: class=-6358397 sigmoid=1110 dfl=809  top=cat
```

All ten FPGA runs exited with zero. The 8F average end-to-end result is
`6123155 cycles` at 50 MHz, compared with `6150829 cycles` for the frozen 8C
all-consumer baseline: `27674 cycles` or about `0.45%` lower, approximately
`8.166 FPS` versus `8.129 FPS`.

The 8F profile has 382 records instead of the baseline's 398 because each
dual-consumer pair is emitted through one combined helper. The pair helper
does not remove computation; it only combines profiling boundaries. The
graph-level cycle counter remains the valid performance comparison.

This baseline does not modify RTL, Scala, Chisel, the Vivado project or the
bitstream. Stage 8H was tested afterward but was not promoted because its
local fence/config gain did not improve end-to-end cycles.
