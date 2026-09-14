# YOLOv5nu Stage 8C Backbone Split-K Expansion

This candidate keeps all seven shared-scale Gemmini Adds and expands the
validated model.2 split-K Concat-Conv path to four backbone blocks:

```text
/model.2/Concat -> /model.2/cv3/conv/Conv
/model.4/Concat -> /model.4/cv3/conv/Conv
/model.6/Concat -> /model.6/cv3/conv/Conv
/model.8/Concat -> /model.8/cv3/conv/Conv
```

## Implementation

The generalized helper supports these matrix geometries:

```text
model2: 6400x32  = 2 * (6400x16),  output 32
model4: 1600x64  = 2 * (1600x32),  output 64
model6:  400x128 = 2 * (400x64),   output 128
model8:  100x256 = 2 * (100x128),  output 256
```

For every output tile:

1. partial 0 loads bias, computes the first K slice, and does not mvout;
2. a fence completes partial 0 before changing the global mvin scale;
3. partial 1 accumulates into the same accumulator address;
4. final mvout applies Conv requant and the dynamic SiLU LUT;
5. a fence completes the final output before the next tile.

The partial-K fence policy is unchanged from the board-validated model2 v1.
All four materialized Concat tensors are inactive and unallocated.

## Reproduce

```bash
python3 scripts/yolov5nu_stage8c_backbone_splitk.py all
```

Individual commands are `build`, `validate`, and `elf`.

The generated ELF is:

```text
generators/gemmini/software/gemmini-rocc-tests/build/imagenet/
yolov5nu-stage8c-backbone-splitk-image025-profile-baremetal-uart
```

## Validation

- AOT contract: seven Gemmini resadds, four split-K calls;
- all four fused Concat tensors are inactive;
- memory plan: `arena=846400`, `direct_concat=7`;
- 76/76 Conv QDQ checks pass;
- 69 dynamic SiLU LUTs pass 17,664 exhaustive mappings;
- five images pass element-wise materialized-Concat, Conv, and SiLU checks for
  all four fusions;
- model2-only and all-Add/model2-only candidates pass regeneration regression.

The expected image025 output is unchanged from the board-validated all-Add
candidate:

```text
class logits checksum=-6457179 min=-73 max=2
class sigmoid checksum=884 min=0 max=93
DFL sparse_positions=10 elems=40 checksum=845 min=5 max=43
#0 giraffe score_milli=696 bbox_cxcywh=(245,159,109,145) index=2037
```

This expansion remains a candidate until FPGA output and cycles are checked.
The all-Add/model2-only version remains the current board-validated baseline.
