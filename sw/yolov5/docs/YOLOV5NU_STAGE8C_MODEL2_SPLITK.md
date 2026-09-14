# YOLOv5nu Stage 8C `/model.2` Split-K Concat-Conv

This candidate combines the validated Stage 8B shared-scale ResAdd with the
first Concat-to-Conv fusion:

```text
/model.2/Concat -> /model.2/cv3/conv/Conv
```

The original 1x1 Conv has matrix geometry `6400x32 * 32x32`. Stage 8C splits
the K dimension into two slices:

```text
slice 0: 6400x16 * 16x32, with bias, no mvout
slice 1: 6400x16 * 16x32, accumulate, final mvout + SiLU
```

Each input slice uses its own Gemmini mvin scale relative to the original
Concat scale. Bias is loaded once. Conv requant and the dynamic SiLU LUT are
applied only on the final mvout. The `/model.2/Concat` int8 tensor is inactive
and is not allocated in the arena.

## Build and validate

```bash
python3 scripts/yolov5nu_stage8c_model2_splitk.py all
```

Individual steps are `build`, `validate`, and `elf`.

Generated ELF:

```text
generators/gemmini/software/gemmini-rocc-tests/build/imagenet/
yolov5nu-stage8c-model2-splitk-image025-profile-baremetal-uart
```

## Host validation

For images `025`, `036`, `142`, `404`, and `650`, the validator checks:

1. independent slice requantization equals the materialized QDQ Concat;
2. split-K int32 accumulation plus bias equals the QDQ Conv output;
3. final dynamic SiLU LUT output equals the QDQ SiLU output.

All three checks are element-wise bit-exact for all five images. The memory
plan reports `direct_concat=12`, `arena=846400`, and marks the model.2 Concat
tensor inactive.

## V1 scheduling boundary

The first hardware version uses a fence after each partial K loop. This makes
the global mvin-scale change unambiguous while preserving accumulator state,
but adds command/fence overhead. Once FPGA output is bit-exact, a later
candidate may overlap the two partial loops or use explicit scratchpad loads.

No RTL, Scala, or bitstream change is required.
