# YOLOv5nu Stage 8H: Split-K Config/Fence Merge

Stage 8H is a software-only candidate built on Stage 8F. It does not modify
RTL, Scala, the Vivado project, or the bitstream.

## Change

The four-slice `/model.9/Concat` consumer has four consecutive partial-K
operations with the same input scale and stride. Stage 8H keeps the first
`config_ld`, reuses that global mvin configuration for the following partials,
and removes only the intermediate fences while the scale is unchanged. The
final fence of each spatial tile remains mandatory.

For any scale or stride transition, the helper fences before changing the
configuration. Two-slice and dual-consumer paths remain conservative and keep
their existing fences.

## Validation requirements

The candidate must pass:

1. source contract: seven shared Add calls, seventeen split-K edge markers,
   four dual-consumer reuse calls, zero direct Concat calls;
2. Spike five-image output comparison against the Stage 8F baseline;
3. FPGA five-image double-run comparison before any baseline promotion.

The first implementation is not declared bit-exact from source inspection
alone, because removing an intermediate fence changes the ordering contract
between successive accumulator partials. If FPGA or RTL simulation shows an
accumulator hazard, retain the config merge but restore that fence.

## FPGA result

All five images passed the hardware-aware bit-exact comparison. The H8 average
over ten runs was `5,988,950 cycles` (`8.349 FPS`). The Stage 8F comparison
average was `5,987,670 cycles` (`8.350 FPS`), so H8 was `1,281 cycles` or
`0.02%` slower overall, within normal board-run variation. H8 is not promoted
to the baseline.

The targeted `/model.9/cv2/conv/Conv` Gemmini profile did improve from about
`47,079` cycles in Stage 8F to `43,681` cycles in H8, a reduction of about
`3,397 cycles` (`7.2%`). Other graph phases absorbed this local improvement.
The measured conclusion is therefore: the merge is functionally safe and
locally effective, but not an end-to-end speedup on this board.

## Reproduction

```bash
python3 scripts/yolov5nu_stage8h_splitk_config_fence.py
```

The UART ELFs are generated under:

```text
generators/gemmini/software/gemmini-rocc-tests/build/imagenet/
```
