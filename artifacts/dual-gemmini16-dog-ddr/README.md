# Dual-Gemmini16 single-dog DDR baseline

`gemmini16_tinyyolov2_dog_only_board.riscv` is the frozen bare-metal test
image for the current
`TaihangSoC1Rocket1RVV2Gemmini16x16PackedFullOps256BitConfig` bitstream.

The image has one built-in 416x416 dog input and runs the validated
TinyYOLOv2 serial path on worker0 (`custom3`, busy CSR `0x7c2`). It provides a
repeatable CPU/Gemmini0 DDR traffic baseline for board tests. It is compatible
with the dual-Gemmini SoC but does not submit concurrent work to worker1.

Frozen identity:

- ELF entry: `0x80000000`
- SHA-256: `f52d0eab0750a9bfe0c71a721061ccd874e8385cd5cef2f37d1a35da8c07a914`
- UART: 115200 baud, 8N1
- Expected final line:
  `RESULT: PASS - validated twoGemmini serial path detected dog on worker0`

Validate the artifact without accessing the board:

```bash
./scripts/download_standalone_dog.sh --check
```

With the matching bitstream already programmed, download and start it with:

```bash
./scripts/download_standalone_dog.sh
```

The script verifies the architecture, entry point and SHA-256 before every
download. The frozen image must not be rebuilt in place; a changed test image
should be added as a new versioned artifact with its own recorded hash.
