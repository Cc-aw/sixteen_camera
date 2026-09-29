# Copy to config/tools.local.mk for machine-specific paths. Do not commit it.
# These are consumed by the root Makefile and inherited by child tools.
VIVADO_BIN ?= /mnt/data/Vivado/Vivado/2023.2/bin/vivado
# export CHIPYARD := /home/wzr/chipyard
# export TOOLCHAIN := /path/to/bin/riscv64-unknown-elf-
# export REFERENCE_ROOT := /absolute/path/to/4k60to1k60
# export REFERENCE_SW := /absolute/path/to/4k60to1k60/sw
# export DEMO_BSP := /absolute/path/to/bsp/libsrc
# Use `make ... SOC_VARIANT=single4` to select the fast test configuration.
# Or remember the local default for subsequent make invocations:
# SOC_VARIANT := single4
# For new hardware, `make bitstream SOC_CONFIG=<generated/soc directory name>`
# uses the default Vivado flow without adding an alias or a new build script.
