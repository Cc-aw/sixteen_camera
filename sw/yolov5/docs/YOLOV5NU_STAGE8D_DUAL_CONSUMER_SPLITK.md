# YOLOv5nu Stage 8D Dual-Consumer Split-K

This candidate handles the four remaining feature-map Concat nodes with two
downstream Conv consumers each:

```text
/model.12/Concat -> /model.13/cv1/conv/Conv and cv2/conv/Conv
/model.16/Concat -> /model.17/cv1/conv/Conv and cv2/conv/Conv
/model.19/Concat -> /model.20/cv1/conv/Conv and cv2/conv/Conv
/model.22/Concat -> /model.23/cv1/conv/Conv and cv2/conv/Conv
```

The candidate preserves the seven shared-scale Gemmini Adds and the nine
single-consumer split-K fusions. A dual-consumer Concat is not materialized;
each downstream Conv independently reads the two source slices.

## Scheduling

For every consumer and spatial tile:

1. partial K slice 0 loads bias and computes without mvout;
2. a fence completes the partial before the mvin scale changes;
3. partial K slice 1 accumulates into the same accumulator;
4. final mvout applies that Conv's requant and SiLU LUT;
5. a fence completes the consumer output.

The source slices remain in their producer tensors because one producer-direct
write cannot serve two consumers. This duplicates mvin work for the two
consumers, but removes the shared Concat copy/requant.

## Reproduce

```bash
python3 scripts/yolov5nu_stage8c_single_consumer_splitk.py dual
```

Outputs are in:

```text
generators/gemmini/software/gemmini-ort/models/detection/stage8c_all_consumer_splitk/
```

ELF:

```text
generators/gemmini/software/gemmini-rocc-tests/build/imagenet/
yolov5nu-stage8c-all-consumer-splitk-image025-profile-baremetal-uart
```

## Contract and validation

```text
shared Gemmini Add calls: 7
two-slice split-K calls:  16
four-slice calls:         1 (model.9 SPPF)
split-K consumer edges:   17
inactive Concat tensors:  13
direct Concat:            0
arena:                    739200 bytes
```

Five-image host validation covers all 17 consumer edges. Slice requant,
int32 accumulator, materialized-vs-split Conv, and materialized-vs-split SiLU
are exact for every edge. The 76 Conv QDQ and 69 dynamic SiLU LUT checks also
pass. The known ORT debug observation at `/model.17/cv3` is limited to a few
floating reference ties; it does not occur between the two hardware paths.

No RTL, Scala, or bitstream changes are included.
