SHELL := /bin/bash
.DEFAULT_GOAL := help
FEATURE := $(abspath $(dir $(lastword $(MAKEFILE_LIST))))
REPO := $(abspath $(FEATURE)/../../../..)
include $(FEATURE)/config.example.mk
-include $(REPO)/tools/config/tools.local.mk
export VIVADO_BIN VERILATOR JAVA_HOME SBT_LAUNCH RISCV
export COURSIER_CACHE_SEED SBT_BOOT_SEED IVY_CACHE_SEED
WORKSPACE ?= $(FEATURE)/build/workspace
OUTPUT ?= $(FEATURE)/generated
RTL_RUN ?= rtl_acceptance
PROJECT_OUTPUT ?= $(FEATURE)/build/project
.PHONY: help check prepare-workspace soc test-frontend test-rtl project elaborate synth bitstream
help:
	@printf '%s\n' 'Independent S1 FIFO16 / fetch4 hardware; production default is unchanged.' \
	  'make soc: full-source SBT/Chisel generation into a NEW OUTPUT' \
	  'make check: check generated FIFO16/fetch4 configuration and S1 ABI headers' \
	  'make test-frontend: generated batch4 protocol regression' \
	  'make test-rtl: three real Gemminis + ASRAM numerical tests' \
	  'make project: reconstruct a NEW private Vivado project; no runs launched' \
	  'make elaborate / synth / bitstream: build this version in its private project'
check:
	python3 -B $(FEATURE)/scripts/audit.py
prepare-workspace:
	python3 -B $(FEATURE)/scripts/generate.py --workspace "$(WORKSPACE)" --prepare-only
soc:
	python3 -B $(FEATURE)/scripts/generate.py --workspace "$(WORKSPACE)" --output "$(OUTPUT)" $(SOC_FLAGS)
test-frontend:
	python3 -B $(FEATURE)/scripts/test_frontend.py --output "$(FEATURE)/build/$(RTL_RUN)_frontend" --jobs $(JOBS)
test-rtl:
	python3 -B $(FEATURE)/scripts/test_rtl.py --output "$(FEATURE)/build/$(RTL_RUN)"
project:
	@mkdir -p $(FEATURE)/build
	cd $(FEATURE)/build && $(VIVADO_BIN) -mode batch -nojournal -log "$(PROJECT_OUTPUT).vivado.log" -source $(FEATURE)/scripts/create_project.tcl -tclargs "$(PROJECT_OUTPUT)"
elaborate synth bitstream:
	@test -f "$(PROJECT_OUTPUT)/s1.xpr" || $(MAKE) -C $(FEATURE) project PROJECT_OUTPUT="$(PROJECT_OUTPUT)"
	cd "$(PROJECT_OUTPUT)" && S1_BUILD_PROJECT="$(PROJECT_OUTPUT)/s1.xpr" S1_HARDWARE_DIRECTORY="$(FEATURE)" S1_BUILD_STAGE="$@" S1_BUILD_JOBS="$(JOBS)" $(VIVADO_BIN) -mode batch -nojournal -log "$@.vivado.log" -source $(FEATURE)/scripts/build.tcl
