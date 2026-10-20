SHELL := /bin/bash
.DEFAULT_GOAL := help
FEATURE := $(abspath $(dir $(lastword $(MAKEFILE_LIST))))
include $(FEATURE)/config.example.mk
-include $(FEATURE)/config.local.mk
export VIVADO_BIN JAVA_HOME SBT_LAUNCH RISCV
RTL_RUN ?= rtl_acceptance
.PHONY: help check lock test-rtl prepare-workspace soc project
help:
	@echo 'check: audit frozen source, generated RTL, ABI and local bitstream'
	@echo 'test-rtl: 72 numerical cases on imported three-Gemmini/ASRAM RTL'
	@echo 'prepare-workspace / soc: private Scala workspace / fresh generation (set WORKSPACE and OUTPUT)'
	@echo 'project: reconstruct a private Vivado project; does not launch synthesis or bitstream'
check:
	python3 -B $(FEATURE)/scripts/audit.py
lock:
	python3 -B $(FEATURE)/scripts/lock.py

test-rtl: check
	python3 -B $(FEATURE)/scripts/test_rtl.py --output "$(FEATURE)/build/$(RTL_RUN)"
prepare-workspace: check
	python3 -B $(FEATURE)/scripts/generate.py --workspace "$(WORKSPACE)" --prepare-only
soc: check
	python3 -B $(FEATURE)/scripts/generate.py --workspace "$(WORKSPACE)" --output "$(OUTPUT)"
project: check
	@test -n "$(PROJECT_OUTPUT)" || { echo 'Set a new PROJECT_OUTPUT below this version build/'; exit 2; }
	@mkdir -p $(FEATURE)/build
	cd $(FEATURE)/build && $(VIVADO_BIN) -mode batch -nojournal -log "$(PROJECT_OUTPUT).vivado.log" -source $(FEATURE)/scripts/create_project.tcl -tclargs "$(PROJECT_OUTPUT)"
