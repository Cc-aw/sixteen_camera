# Unified entry points. Run `make help`; no build starts by default.
.DEFAULT_GOAL := help
PROJECT_ROOT := $(abspath $(dir $(lastword $(MAKEFILE_LIST))))
-include $(PROJECT_ROOT)/tools/config/tools.local.mk
ifneq ($(strip $(VIVADO_PROJECT)),)
override VIVADO_PROJECT := $(abspath $(VIVADO_PROJECT))
endif

SOC_VARIANT ?= triple32_v3_tensor
VIVADO_BIN ?= vivado
ifneq ($(SOC_VARIANT),triple32_v3_tensor)
$(error Only the current triple32_v3_tensor configuration is supported)
endif
SW_P3_MODE ?= reference
export SW_P3_MODE
export SOC_VARIANT VIVADO_BIN HEAD_VERILATOR
export VIVADO_PROJECT
export SOC_REFERENCE SOC_WORKSPACE RISCV_LINUX_CC RISCV_TOOLCHAIN_DIR
export SOC_CONFIG TOOLCHAIN OPENOCD_BIN OPENOCD_CFG GDB_BIN GDB_PYTHONHOME BOARD_JTAG_SERIAL BITSTREAM_FILE

.PHONY: runtime-baseline test-runtime-abi test-runtime-baseline
.PHONY: test-tensor-device test-runtime-tensor-hal
.PHONY: test-ppu-device test-runtime-ppu-hal
.PHONY: test-overlay-device test-runtime-overlay-hal test-cache-ops
.PHONY: test-runtime-resources test-runtime-faults test-runtime-scheduler test-runtime-r3 test-runtime-backend test-runtime-r4a test-runtime-r4b test-runtime-r5
.PHONY: help check firmware firmware-benchmark bitstream elaborate test-tensor test-tensor-ingress test-cache test-ppu test-video test-runtime test-software
help:
	@printf '%s\n' \
	  'Current hardware: triple32_v3_tensor + autonomous command frontend (3x32)' \
	  'Standalone benchmark: V33 frontend; realtime v26 Runtime adaptation pending' \
	  'make check / check-deps    Validate production identity, sources and tools' \
	  'make soc SOC_REFERENCE=<ref> SOC_WORKSPACE=<new>  Generate the current SoC' \
	  'make project / elaborate / bitstream  Reconstruct and build hardware' \
	  'make benchmark            Build V33 formal and diagnostic frontend ELFs' \
	  'make benchmark-sw-p3 / test-sw-p3 / audit-sw-p3  Build, test and audit reference (SW_P3_MODE=compare for candidates)' \
	  'make benchmark-v34 / test-v34 / program-v34  V34 HOST/Gemmini/MPV3 diagnostics' \
	  'make benchmark-first-layer-s2d / test-first-layer-s2d / program-first-layer-s2d  RVV first-layer serial/parallel A/B' \
	  'make test-v33 / check-v33-firmware  Check V33 plans, scheduler, PPU, logs and ELFs' \
	  'make firmware             Realtime Runtime adaptation required' \
	  'make test-software         Run host and model regressions' \
	  'make test-rtl              Run RTL regressions (SoC workspace required)' \
	  'make program-bitstream / program  Load matching hardware / ELF' \
	  'make help-tests           List directed regression and diagnostic commands' \
	  'Local tool overrides: tools/config/tools.local.mk'

.PHONY: help-tests soc benchmark test-model test-rtl
soc: soc-triple32-v3-tensor
benchmark: firmware-benchmark
test-rtl: test-video test-video-pipeline test-tensor test-tensor-ingress test-memory-v3 test-ppu test-cache test-frontend

.PHONY: test-frontend test-frontend-equivalence test-frontend-memory test-frontend-compute
test-frontend: test-frontend-equivalence test-frontend-memory test-frontend-compute
test-frontend-equivalence:
	SOC_WORKSPACE="$(SOC_WORKSPACE)" python3 tests/rtl/command_frontend/test_equivalence.py
test-frontend-memory:
	python3 tests/rtl/command_frontend/test_memory_widths.py
test-frontend-compute:
	VIVADO_BIN="$(VIVADO_BIN)" python3 tests/rtl/command_frontend/test_real_gemmini.py
help-tests:
	@printf '%s\n' \
	  'Software: test-software test-host test-model test-v26 check-v26-firmware' \
	  'HAL: test-tensor-device test-ppu-device test-overlay-device test-cache-ops' \
	  'Runtime: test-runtime-resources test-runtime-faults test-runtime-scheduler test-runtime-backend' \
	  'Frozen traces: test-runtime-baseline test-runtime-tensor-hal test-runtime-ppu-hal test-runtime-overlay-hal' \
	  'Layer traces: test-runtime-r3 test-runtime-r4a test-runtime-r4b test-runtime-r5' \
	  'RTL: test-rtl test-video test-video-pipeline test-tensor test-tensor-ingress test-memory-v3 test-ppu test-cache' \
	  'Timing repair: test-v3-timing-repair SOC_WORKSPACE=<rebuilt-workspace>' \
	  'Memory performance: test-head-performance / test-l2-performance [PERF_RTL=<reference>] [PERF_COUNT=4096]' \
	  'Frontend: test-frontend SOC_WORKSPACE=<rebuilt-workspace> (equivalence, memory widths, real DIM32 compute)' \
	  'Details and prerequisites: tests/README.md'

.PHONY: project
project: check
	@mkdir -p "$(PROJECT_ROOT)/build/reports/project"
	cd "$(PROJECT_ROOT)/build/reports/project" && \
	  flock "$(PROJECT_ROOT)/build/video_project.lock" \
	  "$(VIVADO_BIN)" -mode batch -source "$(PROJECT_ROOT)/hw/vivado/create_project.tcl"

check:
	@cd "$(PROJECT_ROOT)" && tclsh tools/check/check_production_manifest.tcl
	@python3 tools/check/check_current_product.py

firmware: check
	@python3 tools/check/check_current_product.py --firmware
	@test -z "$(SOC_CONFIG)" || { echo 'SOC_CONFIG selects hardware only; use SOC_VARIANT with a matching firmware ABI'; exit 2; }
	@case "$(SOC_VARIANT)" in triple32_v3_tensor) ;; *) echo 'Firmware needs a supported SOC_VARIANT'; exit 2 ;; esac
	cd "$(PROJECT_ROOT)" && python3 tools/build/build_$(SOC_VARIANT)_video_yolov5nu.py

.PHONY: check-v26-firmware test-v26
check-v26-firmware:
	@python3 tools/check/check_current_product.py --firmware
	python3 tools/check/check_firmware.py

firmware-benchmark: check
	@python3 tools/check/check_current_product.py --benchmark
	$(MAKE) -C sw/benchmarks/frontend all

.PHONY: test-v33 check-v33-firmware program-benchmark
test-v33: check
	$(MAKE) -C sw/benchmarks/frontend check
check-v33-firmware: check
	$(MAKE) -C sw/benchmarks/frontend audit
	python3 -B sw/benchmarks/frontend/scripts/manifest.py --check
program-benchmark:
	bash sw/benchmarks/frontend/download.sh $(PROGRAM_ARGS)

test-model:
	$(MAKE) -C sw/benchmarks/triple_infer check

test-v26: test-model
	bash tests/host/run_v17a_live_scheduler_test.sh
	bash tests/host/run_v26_live_scheduler_test.sh
	bash tests/host/run_v17a_backend_test.sh

bitstream: check
	cd "$(PROJECT_ROOT)" && bash tools/build/build_video_bitstream.sh

elaborate: check
	@mkdir -p "$(PROJECT_ROOT)/build/reports/elaborate/$(SOC_VARIANT)"
	cd "$(PROJECT_ROOT)/build/reports/elaborate/$(SOC_VARIANT)" && \
	  flock "$(PROJECT_ROOT)/build/video_project.lock" \
	  "$(VIVADO_BIN)" -mode batch -source "$(PROJECT_ROOT)/tools/check/check_tensor_production_elaboration.tcl"

test-tensor:
	cd "$(PROJECT_ROOT)" && bash tests/rtl/run_yolov5nu_multi_channel_tensor_dma_tests.sh

test-tensor-ingress:
	@if test -n "$(SOC_WORKSPACE)"; then \
	  python3 tools/soc/build_triple32_v3_tensor.py --workspace "$(SOC_WORKSPACE)" --emit-core-only; \
	fi
	cd "$(PROJECT_ROOT)" && python3 tests/rtl/run_tensor_ingress_tests.py
	cd "$(PROJECT_ROOT)" && python3 tests/rtl/run_tensor_ingress_l2_test.py $(if $(SOC_WORKSPACE),--workspace "$(SOC_WORKSPACE)")

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

test-runtime-backend:
	bash tests/host/run_runtime_backend_ops_test.sh

test-runtime-r5:
	bash tests/host/run_application_trace_test.sh
	bash tests/host/run_runtime_facade_trace_test.sh
	bash tests/host/run_runtime_facade_metrics_test.sh

test-runtime-r4b:
	bash tests/host/run_runtime_postprocess_proof_test.sh
	bash tests/host/run_runtime_postprocess_trace_test.sh

test-runtime-r4a:
	bash tests/host/run_runtime_backend_adapter_trace_test.sh

.PHONY: test-host
test-software: test-model test-host

test-host:
	@cd "$(PROJECT_ROOT)" && for test_script in tests/host/run_*_test.sh; do \
	  bash "$$test_script" || exit; \
	done

.PHONY: outputs
outputs:
	@python3 "$(PROJECT_ROOT)/tools/check/inventory_outputs.py"

.PHONY: program check-deps
program:
	@python3 tools/check/check_current_product.py --firmware
	cd "$(PROJECT_ROOT)" && VIDEO_VARIANT="$(SOC_VARIANT)" bash tools/program/run_firmware.sh $(PROGRAM_ARGS)

check-deps: check
	@python3 "$(PROJECT_ROOT)/tools/check/check_dependencies.py"

.PHONY: soc-triple32-v3-tensor test-memory-v3
soc-triple32-v3-tensor:
	@test -n "$(SOC_WORKSPACE)" || { echo 'Set SOC_WORKSPACE to a new private Chipyard path'; exit 2; }
	python3 tools/soc/build_triple32_v3_tensor.py --workspace "$(SOC_WORKSPACE)" $(SOC_GENERATE_ARGS)

test-memory-v3:
	python3 tests/rtl/run_memory_parallel_v3_tests.py

.PHONY: test-video-pipeline
test-video-pipeline:
	python3 tests/rtl/run_video_timing_pipeline_tests.py

.PHONY: test-v3-timing-repair
test-v3-timing-repair:
	@test -n "$(SOC_WORKSPACE)" || { echo 'Set SOC_WORKSPACE to the rebuilt private Chipyard path'; exit 2; }
	python3 tests/rtl/run_v3_timing_repair_tests.py --workspace "$(SOC_WORKSPACE)" --output "$(PROJECT_ROOT)/build/sim/v3_timing_repair_$$(date +%Y%m%d_%H%M%S)_$$$$"

.PHONY: program-bitstream
program-bitstream:
	cd "$(PROJECT_ROOT)" && bash tools/program/download_bitstream.sh $(PROGRAM_ARGS)

.PHONY: test-head-read-decouple test-head-s1 test-l2-secondary-capacity test-head-l2-urgent
test-head-s1: test-head-read-decouple
test-head-read-decouple:
	python3 tests/rtl/head_l2_urgent/run_tests.py --suite head
test-l2-secondary-capacity:
	python3 tests/rtl/head_l2_urgent/run_tests.py --suite l2 $(if $(SOC_WORKSPACE),--workspace "$(SOC_WORKSPACE)")
test-head-l2-urgent:
	python3 tests/rtl/head_l2_urgent/run_tests.py --suite all $(if $(SOC_WORKSPACE),--workspace "$(SOC_WORKSPACE)")

.PHONY: test-head-performance test-l2-performance
test-head-performance:
	python3 tests/rtl/performance/run_head_compare.py --output "$(PROJECT_ROOT)/build/reports/hardware_performance/head_$$(date +%Y%m%d_%H%M%S)_$$$$"
test-l2-performance:
	python3 tests/rtl/performance/run_l2_compare.py $(if $(PERF_RTL),--rtl "$(PERF_RTL)") --count "$(or $(PERF_COUNT),512)" --output "$(PROJECT_ROOT)/build/reports/hardware_performance/l2_$$(date +%Y%m%d_%H%M%S)_$$$$"

# SW-P3 is an isolated derived frontend; the frozen V33 targets stay strict.
.PHONY: benchmark-sw-p3 test-sw-p3 audit-sw-p3 program-sw-p3
benchmark-sw-p3: test-v33
	$(MAKE) -f sw/benchmarks/frontend/sw-p3.mk all
test-sw-p3: test-v33
	$(MAKE) -f sw/benchmarks/frontend/sw-p3.mk test
audit-sw-p3:
	$(MAKE) -f sw/benchmarks/frontend/sw-p3.mk audit
program-sw-p3:
	bash sw/benchmarks/frontend/download-sw-p3.sh $(PROGRAM_ARGS)

# Imported V34 diagnostics preserve the frozen V33 formal entry.
.PHONY: benchmark-v34 test-v34 audit-v34 program-v34
benchmark-v34: test-v33
	$(MAKE) -f sw/benchmarks/frontend/v34.mk all
test-v34: test-v33
	$(MAKE) -f sw/benchmarks/frontend/v34.mk test
audit-v34:
	$(MAKE) -f sw/benchmarks/frontend/v34.mk audit
program-v34:
	bash sw/benchmarks/frontend/download-v34.sh $(PROGRAM_ARGS)

.PHONY: benchmark-first-layer-s2d test-first-layer-s2d test-first-layer-s2d-rtl audit-first-layer-s2d program-first-layer-s2d
benchmark-first-layer-s2d:
	$(MAKE) -f sw/benchmarks/frontend/first-layer-s2d.mk all
test-first-layer-s2d:
	$(MAKE) -f sw/benchmarks/frontend/first-layer-s2d.mk test
test-first-layer-s2d-rtl:
	$(MAKE) -f sw/benchmarks/frontend/first-layer-s2d.mk test-rtl
audit-first-layer-s2d:
	$(MAKE) -f sw/benchmarks/frontend/first-layer-s2d.mk audit
program-first-layer-s2d:
	bash sw/benchmarks/frontend/download-first-layer-s2d.sh $(PROGRAM_ARGS)
