SHELL := /bin/bash
.DEFAULT_GOAL := help
FEATURE := $(abspath $(dir $(lastword $(MAKEFILE_LIST))))
REPO := $(abspath $(FEATURE)/../../..)
include $(FEATURE)/config.example.mk
-include $(REPO)/tools/config/tools.local.mk
export VIVADO_BIN VERILATOR JAVA_HOME SBT_LAUNCH RISCV
export COURSIER_CACHE_SEED SBT_BOOT_SEED IVY_CACHE_SEED
S1_MVIN_SKIP ?= 1
S1_DIRECT_A ?= 1
export S1_MVIN_SKIP S1_DIRECT_A
WORKSPACE ?= $(FEATURE)/build/timing_workspace
OUTPUT ?= $(FEATURE)/build/timing_generated_final
RTL_RUN ?= rtl_acceptance
PROJECT_OUTPUT ?= $(FEATURE)/build/timing_project_01
override WORKSPACE := $(abspath $(WORKSPACE))
override OUTPUT := $(abspath $(OUTPUT))
override PROJECT_OUTPUT := $(abspath $(PROJECT_OUTPUT))
export S3_GENERATED_OUTPUT := $(OUTPUT)
export S3_WORKSPACE := $(WORKSPACE)
.PHONY: help check prepare-workspace soc test-frontend test-rtl test-scaler project elaborate synth bitstream
help:
	@printf '%s\n' 'Independent S1 FIFO16 Team timing S3 patch version; all outputs stay in build/.' \
	  'make prepare-sources: reconstruct the pinned baseline and this version patches in build/' \
	  'make soc: full-source SBT/Chisel generation into a NEW OUTPUT' \
	  'make check: check generated FIFO16/fetch4 configuration and S1 ABI headers' \
	  'make test-frontend: generated batch4 protocol regression' \
	  'make test-rtl: three real Gemminis + ASRAM numerical tests' \
	  'make project: reconstruct a NEW private Vivado project; no runs launched' \
	  'make elaborate / synth / bitstream: build this version in its private project'
check:
	python3 -B $(FEATURE)/scripts/audit.py --generated "$(OUTPUT)"
prepare-workspace:
	python3 -B $(FEATURE)/scripts/generate.py --workspace "$(WORKSPACE)" --prepare-only
soc:
	python3 -B $(FEATURE)/scripts/generate.py --workspace "$(WORKSPACE)" --output "$(OUTPUT)" $(SOC_FLAGS)
test-frontend:
	python3 -B $(FEATURE)/scripts/test_frontend.py --generated "$(OUTPUT)" --output "$(FEATURE)/build/$(RTL_RUN)_frontend" --jobs $(JOBS)
test-rtl:
	python3 -B $(FEATURE)/scripts/test_rtl.py --generated "$(OUTPUT)" --output "$(FEATURE)/build/$(RTL_RUN)"
test-scaler:
	python3 -B $(FEATURE)/tests/scaler/run_scaler.py --generated "$(OUTPUT)" --output "$(FEATURE)/build/$(RTL_RUN)_scaler" --jobs $(JOBS)
project:
	@mkdir -p $(FEATURE)/build
	cd $(FEATURE)/build && $(VIVADO_BIN) -mode batch -nojournal -log "$(PROJECT_OUTPUT).vivado.log" -source $(FEATURE)/scripts/create_project.tcl -tclargs "$(PROJECT_OUTPUT)" "$(OUTPUT)"
elaborate synth bitstream:
	@test -f "$(PROJECT_OUTPUT)/s3.xpr" || $(MAKE) -C $(FEATURE) project PROJECT_OUTPUT="$(PROJECT_OUTPUT)" OUTPUT="$(OUTPUT)"
	cd "$(PROJECT_OUTPUT)" && S1_BUILD_PROJECT="$(PROJECT_OUTPUT)/s3.xpr" S1_HARDWARE_DIRECTORY="$(FEATURE)" S1_GENERATED_OUTPUT="$(OUTPUT)" S1_BUILD_STAGE="$@" S1_BUILD_JOBS="$(JOBS)" $(VIVADO_BIN) -mode batch -nojournal -log "$@.vivado.log" -source $(FEATURE)/scripts/build.tcl

.PHONY: prepare-sources test-source-overlay
prepare-sources:
	python3 -B $(REPO)/tools/build/source_overlay.py --version "$(FEATURE)"
test-source-overlay:
	python3 -B -m unittest discover -s $(REPO)/tests/host -p test_source_overlay.py -v

.PHONY: audit-source test-timing test-ingress test-fault
audit-source:
	python3 -B $(FEATURE)/scripts/audit_timing.py
test-timing:
	python3 -B $(FEATURE)/tests/timing/run_sourcec.py
	python3 -B $(FEATURE)/tests/timing/run_sourced.py
	python3 -B $(FEATURE)/tests/timing/run_hdmi.py
test-ingress:
	python3 -B $(FEATURE)/tests/timing/run_group.py
test-fault:
	python3 -B $(FEATURE)/tests/timing/run_fault.py
