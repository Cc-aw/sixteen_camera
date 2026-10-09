# Unified entry points. Run `make help`; no build starts by default.
.DEFAULT_GOAL := help
PROJECT_ROOT := $(abspath $(dir $(lastword $(MAKEFILE_LIST))))
-include $(PROJECT_ROOT)/tools/config/tools.local.mk

SOC_VARIANT ?= dual16
VIVADO_BIN ?= vivado
export SOC_VARIANT VIVADO_BIN
export SOC_CONFIG TOOLCHAIN OPENOCD_BIN OPENOCD_CFG GDB_BIN GDB_PYTHONHOME BOARD_JTAG_SERIAL BITSTREAM_FILE

.PHONY: help check firmware bitstream elaborate test-tensor test-cache test-ppu test-video test-runtime test-software
help:
	@printf '%s\n' \
	  'SoC integration examples: SOC_VARIANT=dual16 (default) or single4' \
	  'make check                          Validate selected source manifests' \
	  'make firmware SOC_VARIANT=single4    Build matching YOLOv5nu firmware' \
	  'make bitstream SOC_VARIANT=single4   Build matching video bitstream' \
	  'make bitstream SOC_CONFIG=<name>    Build any hw/soc/<name>/gen-collateral' \
	  'make elaborate SOC_VARIANT=single4   Run Vivado RTL elaboration' \
	  'make test-tensor                    Tensor DMA and recovery tests' \
	  'make test-cache SOC_VARIANT=single4  Selected generated L2 control test' \
	  'make test-ppu                       PPU publication tests' \
	  'make test-video                     Video refactor tests' \
	  'make test-runtime                   Host stream runtime tests (2/3 workers)' \
	  'make test-software                  All software host tests' \
	  'make program                        Download selected firmware (existing bitstream)' \
	  'make check-deps                     Check source closure and installed tools' \
	  'make outputs                        Inventory outputs and retention policy' \
	  'Local tool overrides: tools/config/tools.local.mk (see tools.example.mk)'

check:
	@cd "$(PROJECT_ROOT)" && tclsh tools/check/check_production_manifest.tcl

firmware:
	@test -z "$(SOC_CONFIG)" || { echo 'SOC_CONFIG selects hardware only; use SOC_VARIANT with a matching firmware ABI'; exit 2; }
	@case "$(SOC_VARIANT)" in single4|dual16) ;; *) echo 'Firmware needs a supported SOC_VARIANT'; exit 2 ;; esac
	cd "$(PROJECT_ROOT)" && python3 tools/build/build_$(SOC_VARIANT)_video_yolov5nu.py

bitstream:
	cd "$(PROJECT_ROOT)" && bash tools/build/build_video_bitstream.sh

elaborate: check
	@mkdir -p "$(PROJECT_ROOT)/build/reports/elaborate/$(SOC_VARIANT)"
	cd "$(PROJECT_ROOT)/build/reports/elaborate/$(SOC_VARIANT)" && \
	  flock "$(PROJECT_ROOT)/build/video_project.lock" \
	  "$(VIVADO_BIN)" -mode batch -source "$(PROJECT_ROOT)/tools/check/check_tensor_production_elaboration.tcl"

test-tensor:
	cd "$(PROJECT_ROOT)" && bash tests/rtl/run_yolov5nu_multi_channel_tensor_dma_tests.sh

test-cache: check
	cd "$(PROJECT_ROOT)" && python3 tests/rtl/run_ppu_cache_control_test.py

test-ppu: check
	cd "$(PROJECT_ROOT)" && bash tests/rtl/run_ppu_publication_tests.sh

test-video:
	cd "$(PROJECT_ROOT)" && bash tests/rtl/run_video_refactor_tests.sh

test-runtime:
	cd "$(PROJECT_ROOT)" && bash tests/host/run_ai_batch_runtime_stream_test.sh

test-software:
	@cd "$(PROJECT_ROOT)" && for test_script in tests/host/run_*_test.sh; do \
	  bash "$$test_script" || exit; \
	done

.PHONY: outputs
outputs:
	@python3 "$(PROJECT_ROOT)/tools/check/inventory_outputs.py"

.PHONY: program check-deps
program:
	cd "$(PROJECT_ROOT)" && VIDEO_VARIANT="$(SOC_VARIANT)" bash tools/program/run_firmware.sh $(PROGRAM_ARGS)

check-deps: check
	@python3 "$(PROJECT_ROOT)/tools/check/check_dependencies.py"
