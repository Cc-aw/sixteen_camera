# YOLOv5nu Stage 8B Shared-Scale Gemmini ResAdd

Stage 8B is the first Gemmini mapping for the Stage 8A shared-scale model.
It changes only `/model.2/m/m.0/Add`. The other six feature-map Adds remain on
the Stage 7E RVV fixed-point path.

## Reproduce

Stage 8A must exist first:

```bash
python3 scripts/yolov5nu_stage8a_shared_scale.py
python3 scripts/yolov5nu_stage8b_shared_resadd.py
```

The output is written to:

`generators/gemmini/software/gemmini-ort/models/detection/stage8b_shared_resadd/`

The main files are:

- `yolov5nu-stage8b-shared-resadd-image025-profile.c`;
- `yolov5nu-stage8b-shared-resadd-image025-profile_params.h`;
- `yolov5nu-stage8b-shared-resadd-image025-profile_memory.json`;
- `build_manifest.json`.

## Arithmetic contract

The Stage 8A Add inputs both use:

```text
shared_scale = 0.15322692692279816
```

The Add output scale is:

```text
add_output_scale = 0.1639299839735031
```

The generated Gemmini call uses identity mvin scaling for both inputs and
sets the store scale to:

```text
shared_scale / add_output_scale = 0.9347095828
```

Therefore the intended operation is:

```text
Q((A + B) * shared_scale / add_output_scale)
```

The selected Add is materialized at its own Add output scale. Its following
Concat still performs the original Add-output-to-Concat-output requant. This
is important for preserving the Stage 8A QDQ graph semantics; directly writing
the Concat scale would remove one quantization boundary.

## Current validation boundary

The generator confirms one shared Gemmini resadd call, no direct-Concat
lowering for the selected Add, and `direct_concat=13` in the memory plan.
The Stage 8A 76-Conv QDQ validation and 69-LUT exhaustive validation also pass
for the generated parameter set.

Actual Gemmini hardware bit-exactness is not established by source generation
alone. The next validation must compare the selected Add output and all
downstream tensors against the Stage 8A ORT reference, first in simulator and
then on FPGA when a board test is requested. No RTL or Scala changes are part
of Stage 8B.
