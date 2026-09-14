# TinyYOLOv2 Fixed-Point Reference Contract v0

This directory contains the bit-exact software specification for the first
TinyYOLOv2 hardware postprocessor frontend. The RTL must match this reference;
the older floating-point decoder remains a semantic comparison only.

## Tensor contract

- Shape: `13 x 13 x 5 x 25`, exactly 21,125 bytes.
- Type: signed INT8 with zero point 0.
- Physical order: `[row][column][anchor][attribute]`.
- Attributes: `tx, ty, tw, th, objectness, class0..class19`.
- Original index: `((row * 13) + column) * 5 + anchor`.
- Real scale source: `0.2735902981`; its frozen Q8.24 representation is
  `4,590,084`.
- Class ties select the lowest class ID.

## Fixed-point math

Probabilities use unsigned Q0.15. Calculations use 32,768 as unity and values
written to the candidate ABI saturate at 32,767. Every positive integer divide
and right shift rounds by adding half the denominator or half an LSB before
truncation. This is round-half-up, not round-to-even.

The exponential tables are defined by these recurrences, which are also the
normative way to generate RTL ROM contents:

```text
softmax_exp_neg_q24[0] = 16,777,216
softmax_exp_neg_q24[d] =
    (softmax_exp_neg_q24[d-1] * 12,761,483 + 2^23) >> 24

bbox_exp_q16[0] = 65,536
bbox_exp_q16[q > 0] = repeat q times:
    min(UINT32_MAX, (previous * 86,159 + 2^15) >> 16)
bbox_exp_q16[q < 0] = repeat abs(q) times:
    (previous * 49,850 + 2^15) >> 16
```

A decreasing recurrence that can no longer decrease after rounding underflows
to zero. An increasing bbox recurrence that exceeds 32 bits saturates to
`UINT32_MAX`.

The raw INT8 subtraction used for softmax is widened before subtraction, so
`best - class` covers the complete range 0 through 255. Softmax sums 20 Q8.24
terms in an unsigned 64-bit accumulator. Sigmoid is derived from the same
negative exponential recurrence. Objectness and best-class probability are
multiplied with round-half-up to produce `score_q15`.

The committed LUT fingerprints are 32-bit FNV-1a over little-endian words:

| LUT input sequence | Fingerprint |
|---|---:|
| softmax exp, differences `0..255` | `0x61bc241e` |
| bbox exp, raw bit patterns `0..255` | `0x6f6f9df0` |
| sigmoid, raw bit patterns `0..255` | `0x391d778f` |

## Bounding boxes

Anchor dimensions are Q16.16 values rounded from the existing model anchors:

| Anchor | Width | Height |
|---:|---:|---:|
| 0 | 70,779 | 77,988 |
| 1 | 224,133 | 289,014 |
| 2 | 434,504 | 745,800 |
| 3 | 617,349 | 334,889 |
| 4 | 1,089,208 | 689,439 |

The frontend calculates `cx/cy/width/height` in Q16.16 network-input pixels,
forms `xyxy`, clips it to `[0,416]`, floors minimum coordinates, and ceils
maximum coordinates. A box with `x_min >= x_max` or `y_min >= y_max` is
invalid and is discarded.

## Filtering, ordering, and NMS

- Score threshold: Q15 9,830; equality is retained.
- Default Top-K: 256.
- Sort key: score descending, class ID ascending, original index ascending.
- NMS threshold: Q15 14,746; equality suppresses.
- NMS is class-aware. Different classes never suppress one another.
- IoU comparison uses `intersection * 32768 >= union * threshold_q15`; no
  division is performed.
- Default result limit: 32.

Candidates and Result RAM entries use four little-endian 32-bit words:

```text
word0[15:0]  = x_min       word0[31:16] = y_min
word1[15:0]  = x_max       word1[31:16] = y_max
word2[15:0]  = score_q15   word2[23:16] = class_id
word2[31:24] = flags
word3[15:0]  = original_index; word3[31:16] = 0
```

Run the host regression with:

```bash
./sw/test/run_yolov2_fixed_ref_test.sh
```

The test covers all LUT inputs, INT8 extrema, class ties, threshold equality,
Top-256 cutoff, deterministic sorting, class-aware NMS, and NMS threshold
equality. A validated 21,125-byte raw dog output tensor will be added as a
corpus vector after the known Gemmini output corruption is repaired.
