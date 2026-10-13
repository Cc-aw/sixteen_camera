# Unified entry points. Run `make help`; no build starts by default.
.DEFAULT_GOAL := help
PROJECT_ROOT := $(abspath $(dir $(lastword $(MAKEFILE_LIST))))
-include $(PROJECT_ROOT)/tools/config/tools.local.mk
ifneq ($(strip $(VIVADO_PROJECT)),)
override VIVADO_PROJECT := $(abspath $(VIVADO_PROJECT))
endif

SOC_VARIANT ?= dual16
VIVADO_BIN ?= vivado
export SOC_VARIANT VIVADO_BIN
export VIVADO_PROJECT
export SOC_CONFIG TOOLCHAIN OPENOCD_BIN OPENOCD_CFG GDB_BIN GDB_PYTHONHOME BOARD_JTAG_SERIAL BITSTREAM_FILE

.PHONY: runtime-baseline test-runtime-abi test-runtime-baseline
.PHONY: test-tensor-device test-runtime-tensor-hal
.PHONY: test-ppu-device test-runtime-ppu-hal
.PHONY: test-overlay-device test-runtime-overlay-hal test-cache-ops
.PHONY: test-runtime-resources test-runtime-faults test-runtime-scheduler test-runtime-r3
.PHONY: help check firmware firmware-benchmark test-v17a check-v17a-firmware bitstream elaborate test-tensor test-tensor-ingress test-cache test-ppu test-video test-runtime test-software
help:
	@printf '%s\n' \
	  'SoC variants: dual16 (default), single4, triple32_v3_tensor' \
	  'make check                          Validate selected source manifests' \
	  'make project                        Create/open local Vivado project from Tcl' \
	  'make firmware SOC_VARIANT=triple32_v3_tensor  Build V17 A video firmware' \
	  'make firmware-benchmark            Build V17 A three-image benchmark' \
	  'make test-v17a                     Native packet, scheduler and PPU regressions' \
	  'make firmware SOC_VARIANT=single4    Build matching YOLOv5nu firmware' \
	  'make bitstream SOC_VARIANT=single4   Build matching video bitstream' \
	  'make bitstream SOC_CONFIG=<name>    Build any hw/soc/<name>/gen-collateral' \
	  'make elaborate SOC_VARIANT=single4   Run Vivado RTL elaboration' \
	  'make test-tensor                    Tensor DMA and recovery tests' \
	  'make test-tensor-ingress            New SoC ingress protocol and real L2 tests' \
	  'make test-cache SOC_VARIANT=single4  Selected generated L2 control test' \
	  'make project SOC_VARIANT=triple32_v3_tensor  Rebuild V3 + Tensor hardware project' \
	  'make soc-triple32-v3-tensor SOC_WORKSPACE=/tmp/new-chipyard  Generate from the imported shell' \
	  'make test-memory-v3                 V3 Head, outstanding and counter CDC tests' \
	  'make test-ppu                       PPU publication tests' \
	  'make test-video                     Video refactor tests' \
	  'make test-runtime                   Host stream runtime tests (2/3 workers)' \
	  'make runtime-baseline               Capture R0 software baseline under build/' \
	  'make test-runtime-baseline          ABI, identity trace and known-gap characterization' \
	  'make test-tensor-device             Tensor HAL protocol and timeout traces against R0' \
	  'make test-runtime-tensor-hal        Runtime MMIO, event and UART arguments against R0' \
	  'make test-ppu-device                PPU protocol and barriers against frozen R1a' \
	  'make test-runtime-ppu-hal           PPU backend ownership and MMIO traces against R1a' \
	  'make test-overlay-device           Overlay MMIO, labels and timeouts against R1b' \
	  'make test-runtime-overlay-hal      Real overlay with Runtime busy retry and TTL' \
	  'make test-cache-ops                Host/RV64 Flush64 traces and capability checks' \
	  'make test-runtime-resources        Tensor, activation, Head and job ownership checks' \
	  'make test-runtime-faults           Runtime/backend abort, timeout and drain checks' \
	  'make test-runtime-scheduler        Pure EDF selection and Runtime control states' \
	  'make test-runtime-r3               Full split Runtime event traces against R2' \
	  'make test-software                  All software host tests' \
	  'make program                        Download selected firmware (existing bitstream)' \
	  'make check-deps                     Check source closure and installed tools' \
	  'make outputs                        Inventory outputs and retention policy' \
	  'Local tool overrides: tools/config/tools.local.mk (see tools.example.mk)'

.PHONY: project
project: check
	@mkdir -p "$(PROJECT_ROOT)/build/reports/project"
	cd "$(PROJECT_ROOT)/build/reports/project" && \
	  flock "$(PROJECT_ROOT)/build/video_project.lock" \
	  "$(VIVADO_BIN)" -mode batch -source "$(PROJECT_ROOT)/hw/vivado/create_project.tcl"

check:
	@cd "$(PROJECT_ROOT)" && tclsh tools/check/check_production_manifest.tcl

firmware:
	@test -z "$(SOC_CONFIG)" || { echo 'SOC_CONFIG selects hardware only; use SOC_VARIANT with a matching firmware ABI'; exit 2; }
	@case "$(SOC_VARIANT)" in single4|dual16|triple32_v3_tensor) ;; *) echo 'Firmware needs a supported SOC_VARIANT'; exit 2 ;; esac
	cd "$(PROJECT_ROOT)" && python3 tools/build/build_$(SOC_VARIANT)_video_yolov5nu.py

check-v17a-firmware:
	python3 tools/check/check_v17a_firmware.py

firmware-benchmark:
	$(MAKE) -C sw/models/yolov5nu/triple32 all

test-v17a:
	$(MAKE) -C sw/models/yolov5nu/triple32 check
	bash tests/host/run_v17a_live_scheduler_test.sh
	bash tests/host/run_v17a_backend_test.sh

bitstream:
	cd "$(PROJECT_ROOT)" && bash tools/build/build_video_bitstream.sh

elaborate: check
	@mkdir -p "$(PROJECT_ROOT)/build/reports/elaborate/$(SOC_VARIANT)"
	cd "$(PROJECT_ROOT)/build/reports/elaborate/$(SOC_VARIANT)" && \
	  flock "$(PROJECT_ROOT)/build/video_project.lock" \
	  "$(VIVADO_BIN)" -mode batch -source "$(PROJECT_ROOT)/tools/check/check_tensor_production_elaboration.tcl"

test-tensor:
	cd "$(PROJECT_ROOT)" && bash tests/rtl/run_yolov5nu_multi_channel_tensor_dma_tests.sh

test-tensor-ingress:
	cd "$(PROJECT_ROOT)" && python3 tests/rtl/run_tensor_ingress_tests.py
	cd "$(PROJECT_ROOT)" && python3 tests/rtl/run_tensor_ingress_l2_test.py

test-cache: check
	cd "$(PROJECT_ROOT)" && python3 tests/rtl/run_ppu_cache_control_test.py

test-ppu: check
	cd "$(PROJECT_ROOT)" && bash tests/rtl/run_ppu_publication_tests.sh

test-video:
	cd "$(PROJECT_ROOT)" && bash tests/rtl/run_video_refactor_tests.sh

test-runtime:
	cd "$(PROJECT_ROOT)" && bash tests/host/run_ai_batch_runtime_stream_test.sh

runtime-baseline:
	python3 tools/check/capture_sw_runtime_baseline.py

test-runtime-abi:
	bash tests/host/run_runtime_abi_baseline_test.sh

test-runtime-baseline: test-runtime-abi
	bash tests/host/run_runtime_baseline_trace_test.sh
	bash tests/host/run_runtime_version_baseline_test.sh

test-tensor-device:
	bash tests/host/run_ai_tensor_device_test.sh

test-runtime-tensor-hal:
	bash tests/host/run_runtime_tensor_hal_trace_test.sh

test-ppu-device:
	bash tests/host/run_ai_ppu_device_test.sh

test-runtime-ppu-hal:
	bash tests/host/run_runtime_ppu_hal_trace_test.sh

test-overlay-device:
	bash tests/host/run_ai_overlay_device_test.sh

test-runtime-overlay-hal:
	bash tests/host/run_runtime_overlay_hal_trace_test.sh

test-cache-ops:
	bash tests/host/run_cache_ops_test.sh

test-runtime-resources:
	bash tests/host/run_runtime_resources_test.sh

test-runtime-faults:
	bash tests/host/run_runtime_fault_ownership_test.sh
	bash tests/host/run_backend_fault_ownership_test.sh

test-runtime-scheduler:
	bash tests/host/run_runtime_scheduler_test.sh

test-runtime-r3:
	bash tests/host/run_runtime_r3_trace_test.sh

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

.PHONY: soc-triple32-v3-tensor test-memory-v3
soc-triple32-v3-tensor:
	@test -n "$(SOC_WORKSPACE)" || { echo 'Set SOC_WORKSPACE to a new private Chipyard path'; exit 2; }
	python3 tools/soc/build_triple32_v3_tensor.py --workspace "$(SOC_WORKSPACE)" $(SOC_GENERATE_ARGS)

test-memory-v3:
	python3 tests/rtl/run_memory_parallel_v3_tests.py
