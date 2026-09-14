# YOLOv5nu Stage 8 All Shared-Scale Adds

This cumulative candidate keeps the validated Stage 8C model.2 split-K
Concat-Conv and maps all seven feature residual Adds to Gemmini.

## Scope

- seven feature-map Adds use shared input scales and Gemmini resadd;
- `/model.2/Concat -> /model.2/cv3/conv/Conv` remains fused split-K;
- split-K keeps the validated fence between partial K loops;
- other Concat-Conv edges remain materialized for isolation;
- no RTL, Scala, or bitstream change is required.

The model.4 and model.6 residual chains are processed topologically. An
earlier Add output scale is aligned with the next Add's second input scale,
then every affected Conv bias, bias scale, output requant and dynamic SiLU LUT
is regenerated.

## Reproduce

```bash
python3 scripts/yolov5nu_stage8_all_shared_adds.py all
```

Individual steps are `model`, `validate`, `aot`, and `elf`.

The independent model directory is:

```text
generators/gemmini/software/gemmini-ort/models/detection/stage8_all_shared_adds/
```

The board ELF is:

```text
generators/gemmini/software/gemmini-rocc-tests/build/imagenet/
yolov5nu-stage8c-model2-alladds-image025-profile-baremetal-uart
```

## Validation

- all seven Add input scale pairs are equal;
- `7 * 65536 = 458752` host shared-resadd input pairs pass;
- 76/76 Conv QDQ checks pass;
- all 69 dynamic SiLU LUTs pass 17,664 exhaustive mappings;
- five ORT image references are stored in `ort_reference.json`;
- generated AOT has seven shared Gemmini resadd calls and one model.2 split-K call;
- memory plan: `arena=846400`, `direct_concat=9`.

Image025 expected board signature:

```text
class logits checksum=-6457179
class sigmoid checksum=884
DFL sparse_positions=10 elems=40 checksum=845 min=5 max=43
Top #0 giraffe score_milli=696 bbox_cxcywh=(245,159,109,145) index=2037
```

These values belong to the cumulative shared-scale model and are expected to
differ from the single-Add Stage 8A/8C reference.
