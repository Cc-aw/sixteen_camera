# YOLOv5nu Migration Changeset

This document records the files added or changed after
`docs/TINYYOLOV2_TO_YOLOV5N_MIGRATION_GUIDE.md` was written on 2026-08-19.
It is intended to define the review and Gitee submission boundary.

## Scope

The completed path is:

```text
yolov5nu.pt
  -> fixed 320x320 FP32 ONNX
  -> symmetric QDQ INT8 ONNX
  -> graph manifest
  -> generated Gemmini C/params.h
  -> RV64GCV baremetal ELF
  -> XCVU13P JTAG/UART execution
```

The current validated model is `yolov5nu`, not the older anchor-based
`yolov5n` model. The implementation uses per-tensor signed INT8 activations
and weights, `zero_point=0`, CPU/RVV non-Conv operators, and Gemmini Conv.

## Files To Submit

### Chipyard top-level repository

These files are in the top-level Chipyard repository:

```text
scripts/yolov5nu_graph_parser.py
scripts/yolov5nu_validate_baremetal_reference.py
scripts/xcvu13p_build_yolov5nu_uart_baremetal.sh
docs/YOLOV5NU_GEMMINI_BAREMETAL_FLOW.md
docs/YOLOV5NU_CHANGESET_FROM_MIGRATION.md
```

Responsibilities:

| File | Responsibility |
| --- | --- |
| `scripts/yolov5nu_graph_parser.py` | Audits QDQ constraints and emits the graph manifest. |
| `scripts/yolov5nu_validate_baremetal_reference.py` | Compares integer Conv/requant results against ONNX Runtime. |
| `scripts/xcvu13p_build_yolov5nu_uart_baremetal.sh` | Runs parser, generator and RV64GCV baremetal build. |
| `docs/YOLOV5NU_GEMMINI_BAREMETAL_FLOW.md` | Reproduction and architecture flow. |
| `docs/YOLOV5NU_CHANGESET_FROM_MIGRATION.md` | This submission boundary. |

### `generators/gemmini` subrepository

`generators/gemmini` is a separate Git repository/submodule. These files must
be committed in that repository, or copied into the destination Gitee project
if the submodule is being flattened:

```text
software/gemmini-ort/models/detection/export_yolov5nu_int8.py
software/gemmini-ort/models/detection/export_yolov5nu_gemmini_int8.py
software/gemmini-rocc-tests/imagenet/Makefile
software/gemmini-rocc-tests/imagenet/generate_yolov5nu_baremetal.py
```

The Gemmini RTL and software changes already described by the migration guide
are separate historical dependencies. They must also exist in the Gemmini
commit selected by the top-level submodule pointer; do not silently point the
top-level repository back to upstream Gemmini.

## Reproducibility Artifacts

These generated files are useful for a release or an experiment archive:

```text
software/gemmini-ort/models/detection/yolov5nu-gemmini-fp32-img320.onnx
software/gemmini-ort/models/detection/yolov5nu-gemmini-int8-img320.onnx
software/gemmini-ort/models/detection/yolov5nu-gemmini-int8-img320.graph.json
software/gemmini-ort/models/detection/yolov5nu-gemmini-int8-img320.quant.json
software/gemmini-rocc-tests/imagenet/yolov5nu-gemmini-img320.c
software/gemmini-rocc-tests/imagenet/yolov5nu-gemmini-img320_params.h
```

The ONNX and parameter header files are large binary/text artifacts. Prefer
Git LFS or an artifact store for them. The source generator and the manifest
are the authoritative reproducible inputs; a generated artifact should not
replace them.

## Test-Image Artifacts

These were generated for board validation and should not be part of the
generic compiler change:

```text
software/gemmini-rocc-tests/imagenet/yolov5nu-image25.c
software/gemmini-rocc-tests/imagenet/yolov5nu-image25_params.h
software/gemmini-rocc-tests/imagenet/yolov5nu-image142.c
software/gemmini-rocc-tests/imagenet/yolov5nu-image142_params.h
software/gemmini-rocc-tests/imagenet/yolov5nu-imag36.c
software/gemmini-rocc-tests/imagenet/yolov5nu-imag36_params.h
software/gemmini-rocc-tests/imagenet/yolov5nu-imag142.c
software/gemmini-rocc-tests/imagenet/yolov5nu-imag142_params.h
```

`imag36` and `imag142` are naming-error duplicates/experiments. Keep them
locally only if their UART logs are needed.

## Experimental Artifacts

These files document earlier export/quantization experiments, but are not
needed by the current 320x320 Gemmini baremetal path:

```text
software/gemmini-ort/models/detection/yolov5nu-int8-img640x480.onnx
software/gemmini-ort/models/detection/yolov5nu-int8-symmetric-img640x480.onnx
software/gemmini-ort/models/detection/export_yolov5nu_int8.py
```

Keep the exporter only if the comparison with the non-Gemmini export is part
of the submission. Otherwise the Gemmini-specific exporter is sufficient.

## Do Not Submit

Do not add these generated or machine-local files:

```text
generators/gemmini/software/gemmini-rocc-tests/build/imagenet/*yolov5*
**/__pycache__/
*.elf
*.dump
*.map
*.readelf
*.sha256
Vivado journals and project output directories
```

The current board ELFs are reproducible build outputs, not source changes.

## Commit Order

1. In the Gemmini repository, commit the Gemmini RTL/software dependency and
   the four YOLOv5nu source/build files. Record that commit SHA.
2. In the top-level Chipyard repository, update the `generators/gemmini`
   submodule pointer and commit the three scripts plus the two YOLOv5nu docs.
3. Add model/manifest/generated artifacts only if the project policy requires
   checked-in artifacts. Use Git LFS for ONNX and very large parameter files.
4. Re-run the build from a clean checkout:

```bash
PYTHON=./.conda-env/bin/python \
./scripts/xcvu13p_build_yolov5nu_uart_baremetal.sh
```

5. Run the reference check before uploading the ELF:

```bash
./.conda-env/bin/python scripts/yolov5nu_validate_baremetal_reference.py
```

## Current Validation

- Model input: `1x3x320x320`
- Detection output: `1x84x2100`
- Conv count: `76`
- QDQ contract: signed INT8, symmetric, `zero_point=0`
- Reference Conv checks: `76/76` passed
- Gemmini/CPU synchronization: `gemmini_fence()` after each Conv
- NMS: CPU class-aware greedy NMS, default score `0.25`, IoU `0.45`
- Board validation: `000000000025.jpg` and `000000000142.jpg`

The board result for both images matched the corresponding quantized ONNX
Runtime result after the Conv fences were added. This establishes functional
correctness of the current bring-up path; it is not a full COCO mAP result.
