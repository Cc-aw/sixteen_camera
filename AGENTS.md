# Repository Guidelines

## Project Structure & Module Organization

This repository provides a sixteen-channel video and AI platform for the Xilinx VU13P, integrating OV7670/HDMI capture, DDR, tensor production, Gemmini, and display overlays.

- `hw/rtl/`: handwritten RTL; `hw/soc/`: generated SoC integration examples.
- `hw/constraints/`, `hw/ip/`, `hw/vivado/`, `hw/manifests/`: board constraints, IP reconstruction Tcl, project scripts, and production source lists.
- `sw/src/`: bare-metal firmware; `sw/models/yolov5nu/`: model runtime and parameters; `sw/third_party/`: validated dependency snapshots.
- `tests/host/`: C tests; `tests/rtl/benches/`: subsystem testbenches; `tests/data/`: reference vectors.
- `tools/`: build, programming, generation, and validation scripts; `docs/`: architecture, integration, and validation records.
- `build/`: ignored build and simulation outputs.

## Build, Test, and Development Commands

Run commands from the repository root:

- `make help`: list supported workflows.
- `make check`: validate production manifests; `make check-deps`: also check tools and source dependencies.
- `make project`: reconstruct the Vivado project from Tcl.
- `make firmware`: build v26 firmware for the current `triple32_v3_tensor` hardware (three DIM32 MaxPool workers plus TensorIngress).
- `make elaborate`: check RTL elaboration; `make bitstream`: synthesize and implement hardware.
- `make test-software`: run all host software tests.
- `make test-video test-tensor test-ppu`: run subsystem RTL regressions.
- `make test-cache`: test the current generated L2 controller; `make test-video-pipeline` checks the registered video timing boundaries.

Use Vivado 2023.2, an RV64GCV/LP64D toolchain, Icarus Verilog, Verilator, and Python 3.10+. Install regression dependencies with `python3 -m pip install -r tests/requirements.txt`.

## Coding Style & Naming Conventions

Match neighboring files: generally four-space indentation in C, SystemVerilog, and Python; tabs for Make recipes. Use `snake_case` functions, signals, and filenames, uppercase constants, and existing `Ai...` C type names. Match RTL filenames to module names. No centralized formatter configuration is present; host tests enforce compiler warnings with `-Wall -Wextra -Werror`.

## Testing Guidelines

Use C assertion tests and directed Icarus/Verilator simulations. Name host tests `test_*.c`, RTL benches `tb_*.sv`, and runners `run_*`. Run affected suites and add regression cases for changed behavior. No numeric coverage threshold is documented. Report board validation separately from offline simulation.

## Commit & Pull Request Guidelines

Follow history with concise `feat:`, `build:`, or `refactor:` subjects. PRs should explain behavior changes, affected SoC variants, relevant issues, and validation commands/results. Include timing or board evidence for hardware changes.

## Configuration & Generated Files

Keep local tool paths in ignored `tools/config/tools.local.mk`. Commit reconstruction Tcl rather than Vivado-generated projects or caches. Keep hardware and firmware ABIs aligned: `SOC_CONFIG` selects hardware only and does not select firmware.
