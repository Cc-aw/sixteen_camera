# Repository Guidelines

## Project Structure & Module Organization

This repository provides a sixteen-channel video and AI platform for the Xilinx VU13P, integrating OV7670/HDMI capture, DDR, tensor production, Gemmini, and display overlays.

- `hw/soc/version/dma_load_streaming_asram_s1_512kib_2bank/`: default S1 source, generated SoC, board RTL/IP/constraints and provenance; selected by `hw/manifests/current.json`.
- `hw/constraints/`, `hw/ip/`, `hw/vivado/`, `hw/manifests/`: board constraints, IP reconstruction Tcl, project scripts, and production source lists.
- `sw/video_runtime/dma_load_streaming_asram_s1_512kib_2bank/`: default independent bare-metal video runtime, model and BSP. `sw/models/` and `sw/third_party/` remain historical benchmark inputs.
- `tests/host/`: C tests; `tests/rtl/benches/`: subsystem testbenches; `tests/data/`: reference vectors.
- `tools/`: build, programming, generation, and validation scripts; `docs/`: architecture, integration, and validation records.
- `build/`: ignored build and simulation outputs.

## Build, Test, and Development Commands

Run commands from the repository root:

- `make help`: list supported workflows.
- `make check`: validate production manifests; `make check-deps`: also check tools and source dependencies.
- `make project`: reconstruct the Vivado project from Tcl.
- `make firmware`: build the default S1 live-video ELF; `make -C sw` selects the same package.
- `make program-bitstream`: program its SHA-locked bitstream; `make board-live` loads firmware and captures continuous inference. Board actions require the user's instruction.
- `make board-run`: about 100 total inferences; use a new `RUN` and `PORT=/dev/ttyACM0`.
- `make preflight`: check ELF, tools and bitstream offline.
- `make benchmark`: build the independent S1 fixed-image benchmark.
- `make elaborate`, `make synth`, `make bitstream`: build S1 hardware in its private build directory; never overwrite the imported bitstream or gate bitgen on negative timing.
- `make test`: run current software/HAL/tool tests and native S1 capture RTL. `make test-rtl RTL_RUN=<new>` runs native three-Gemmini/ASRAM numerical cases.
- `make test-software`: run current software tests; older directed test scripts and documents are historical references.

Use Vivado 2023.2, an RV64GCV/LP64D toolchain, Icarus Verilog, Verilator, and Python 3.10+. Install regression dependencies with `python3 -m pip install -r tests/requirements.txt`.

## Coding Style & Naming Conventions

Match neighboring files: generally four-space indentation in C, SystemVerilog, and Python; tabs for Make recipes. Use `snake_case` functions, signals, and filenames, uppercase constants, and existing `Ai...` C type names. Match RTL filenames to module names. No centralized formatter configuration is present; host tests enforce compiler warnings with `-Wall -Wextra -Werror`.

## Testing Guidelines

Use C assertion tests and directed Icarus/Verilator simulations. Name host tests `test_*.c`, RTL benches `tb_*.sv`, and runners `run_*`. Run affected suites and add regression cases for changed behavior. No numeric coverage threshold is documented. Report board validation separately from offline simulation.

## Commit & Pull Request Guidelines

Follow history with concise `feat:`, `build:`, or `refactor:` subjects. PRs should explain behavior changes, affected SoC variants, relevant issues, and validation commands/results. Include timing or board evidence for hardware changes.

## Configuration & Generated Files

Keep local tool paths in ignored `tools/config/tools.local.mk`. Commit reconstruction Tcl rather than Vivado-generated projects or caches. Keep hardware and firmware ABIs aligned: `SOC_CONFIG` selects hardware only and does not select firmware.
