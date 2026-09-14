# YOLOv5nu Stage 8C Single-Consumer Split-K

This candidate keeps all seven shared-scale Gemmini Adds and fuses all nine
single-consumer feature Concat nodes into their following 1x1 Conv:

```text
/model.2/4/6/8/Concat -> cv3/conv/Conv
/model.9/Concat       -> cv2/conv/Conv
/model.13/17/20/23/Concat -> cv3/conv/Conv
```

Eight nodes use the board-validated two-slice helper. `/model.9/Concat` is an
SPPF four-slice input and uses a separate multi-slice helper. Both helpers:

1. load bias only for the first slice;
2. retain int32 accumulator values between slices;
3. keep a fence after every partial K loop;
4. apply Conv requant and the dynamic SiLU LUT only on final mvout.

## Reproduce

```bash
python3 scripts/yolov5nu_stage8c_single_consumer_splitk.py all
```

Generated ELF:

```text
generators/gemmini/software/gemmini-rocc-tests/build/imagenet/
yolov5nu-stage8c-single-consumer-splitk-image025-profile-baremetal-uart
```

## AOT contract

```text
Gemmini shared resadd calls: 7
two-slice split-K calls:     8
four-slice split-K calls:    1
inactive fused Concats:      9
direct Concat producers:     2
arena:                       784000 bytes
```

Only four dual-consumer feature Concats remain materialized:

```text
/model.12/Concat
/model.16/Concat
/model.19/Concat
/model.22/Concat
```

## Validation

For five images and all nine fusions, the following hardware-path comparisons
are element-wise exact:

- slice requantization versus materialized int8 Concat;
- partial-K int32 sums plus bias versus the full materialized-Concat Conv
  accumulator;
- materialized hardware Conv versus split-K hardware Conv;
- materialized hardware SiLU LUT versus split-K hardware SiLU LUT.

The 76-Conv QDQ and 69 dynamic SiLU LUT checks also pass. The previously
board-validated four-fusion backbone mode passes regeneration regression.

ORT debug graphs can change float Conv accumulation when many intermediate
outputs are exposed. For `/model.17/cv3`, this produces a reference-only tie:
image142 has one Conv value differing by 1 LSB and its SiLU value by 2 LSB;
image650 has three Conv values differing by 1 LSB and equal SiLU output. The
old materialized Gemmini path and new split-K path remain exactly equal. Final
FPGA output must still match the normal, non-debug ORT model reference.

Expected image025 signature remains:

```text
class logits checksum=-6457179 min=-73 max=2
class sigmoid checksum=884 min=0 max=93
DFL sparse_positions=10 elems=40 checksum=845 min=5 max=43
#0 giraffe score_milli=696 bbox_cxcywh=(245,159,109,145) index=2037
```
