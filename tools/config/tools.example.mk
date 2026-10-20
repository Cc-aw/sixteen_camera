# Copy to tools/config/tools.local.mk; local machine settings are ignored.
# Tools default to PATH. Compiler prefix may also be an absolute path.
# TOOLCHAIN := /path/to/bin/riscv64-unknown-elf-
# VIVADO_BIN := /path/to/Vivado/2023.2/bin/vivado
# PROJECT_OUTPUT := /repo/hw/soc/version/dma_load_streaming_asram_s1_512kib_2bank/build/project_02
# OPENOCD_BIN := /path/to/riscv-openocd/bin/openocd
# GDB_BIN := /path/to/bin/riscv64-unknown-elf-gdb
# GDB_PYTHONHOME := /path/to/conda-env  # only if this GDB needs it
# BOARD_JTAG_SERIAL := your-adapter-serial
# SOC_VARIANT := dma_load_streaming_asram_s1_512kib_2bank
# The default bitstream is SHA-locked by hw/manifests/current.json.
# SOC_VARIANT and SOC_CONFIG accept only the current production identity.
# See hw/manifests/current.json for the sole hardware mapping.
# SOC_WORKSPACE := /repo/hw/soc/version/dma_load_streaming_asram_s1_512kib_2bank/build/workspace_02
# RISCV_LINUX_CC := /path/to/bin/riscv64-unknown-linux-gnu-gcc
