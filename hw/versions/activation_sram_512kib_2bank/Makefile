SHELL := /bin/bash
.DEFAULT_GOAL := help
FEATURE := $(abspath $(dir $(lastword $(MAKEFILE_LIST))))
REPO := $(abspath $(FEATURE)/../../..)
PYTHON ?= python3
WORKSPACE ?= $(REPO)/build/soc_workspaces/activation_sram_512kib_2bank
SOC_REFERENCE ?=
DMA_CONTEXT ?=
DMA_OUTPUT ?= $(REPO)/build/experiments/activation_sram/512kib_2bank/dma_regression
ASRAM_OUTPUT ?= $(REPO)/build/experiments/activation_sram/512kib_2bank
VIVADO_BIN ?= /mnt/data/Vivado/Vivado/2023.2/bin/vivado
OUTPUT_ARG = $(if $(CANDIDATE_OUTPUT),--output "$(CANDIDATE_OUTPUT)")

.PHONY: help check test check-bitstream check-workspace check-rtl prepare soc resume test-unit test-rtl
help:
	@printf '%s\n' \
	  'check             Audit ASRAM-local source hashes and generated address constants' \
	  'test-store        Full-size byte-mask tests with behavioral and Vivado URAM models' \
	  'test-tl           Real TL control, backpressure, collisions and error tests' \
	  'test-software     Host arena view, full-range/guard and capability checks' \
	  'ooc               Route the 72-URAM storage wrapper; set OOC_OUTPUT' \
	  'test              Exercise prepare/overlays and rejection paths with a minimal reference' \
	  'check-bitstream   Hash the historical THREE-mode bitstream; read only' \
	  'check-workspace   Compare WORKSPACE against feature-local effective sources' \
	  'check-rtl         Audit an explicit new FOUR-mode DMA_CONTEXT and its RTL' \
	  'prepare           Copy SOC_REFERENCE to a new WORKSPACE and apply local sources' \
	  'soc               Prepare and generate private 512 KiB/two-bank/four-mode RTL' \
	  'resume            Generate RTL in an already prepared WORKSPACE' \
	  'test-unit         Source unit tests using dependencies in WORKSPACE' \
	  'test-rtl          Full all-mode acceptance of explicit DMA_CONTEXT' \
	  'Variables: SOC_REFERENCE=<Chipyard> WORKSPACE=<new-directory>' \
	  '           CANDIDATE_OUTPUT=<new-directory> DMA_CONTEXT=<context.json> DMA_OUTPUT=<new-directory>'

check:
	$(PYTHON) -B "$(FEATURE)/scripts/audit.py"

test: check
	$(PYTHON) -B "$(FEATURE)/tests/test_prepare.py"

check-bitstream:
	$(PYTHON) -B "$(FEATURE)/scripts/audit.py" --historical-bitstream

check-workspace:
	$(PYTHON) -B "$(FEATURE)/scripts/build_soc.py" --workspace "$(WORKSPACE)" --validate-workspace-only

check-rtl:
	@test -n "$(DMA_CONTEXT)" || { echo 'Set DMA_CONTEXT to the new four-mode candidate'; exit 2; }
	$(PYTHON) -B "$(FEATURE)/scripts/audit.py" --context "$(DMA_CONTEXT)"

prepare:
	$(PYTHON) -B "$(FEATURE)/scripts/build_soc.py" --reference "$(SOC_REFERENCE)" --workspace "$(WORKSPACE)" --prepare-only

soc:
	$(PYTHON) -B "$(FEATURE)/scripts/build_soc.py" --reference "$(SOC_REFERENCE)" --workspace "$(WORKSPACE)" $(OUTPUT_ARG)

resume:
	$(PYTHON) -B "$(FEATURE)/scripts/build_soc.py" --workspace "$(WORKSPACE)" --resume $(OUTPUT_ARG)

test-unit: check
	$(PYTHON) -B "$(FEATURE)/scripts/run_dma_load_tests.py" --workspace "$(WORKSPACE)" --unit-only --output "$(DMA_OUTPUT)"

test-rtl: check-rtl
	$(PYTHON) -B "$(FEATURE)/scripts/run_dma_load_tests.py" --workspace "$(WORKSPACE)" --rtl "$(dir $(DMA_CONTEXT))gen-collateral" --mode all --output "$(DMA_OUTPUT)"

.PHONY: test-prepare test-store test-tl ooc

test-prepare: test

test-store:
	$(PYTHON) -B "$(FEATURE)/scripts/test_store.py" --output "$(ASRAM_OUTPUT)/store"

test-tl:
	$(PYTHON) -B "$(FEATURE)/scripts/test_tl.py" --workspace "$(WORKSPACE)" --output "$(ASRAM_OUTPUT)/tl"

ooc:
	@test -n "$(OOC_OUTPUT)" || { echo 'Set OOC_OUTPUT to a new report directory'; exit 2; }
	"$(VIVADO_BIN)" -mode batch -source "$(FEATURE)/scripts/ooc_store.tcl" -tclargs "$(OOC_OUTPUT)"

.PHONY: test-software

test-software:
	@mkdir -p "$(ASRAM_OUTPUT)/software"
	$(CC) -std=c11 -Wall -Wextra -Werror -DACTIVATION_MEMORY_HOST_TEST -I "$(FEATURE)/software/include" "$(FEATURE)/software/src/activation_memory.c" "$(FEATURE)/tests/test_activation_memory.c" -o "$(ASRAM_OUTPUT)/software/test_activation_memory"
	"$(ASRAM_OUTPUT)/software/test_activation_memory"

.PHONY: test-physical bitstream
test-physical:
	$(PYTHON) -B "$(FEATURE)/tests/test_physical_provenance.py"

# Negative routed timing is reported without blocking write_bitstream.
bitstream:
	@test -n "$(DMA_CONTEXT)" -a -n "$(ASRAM_BUILD_OUTPUT)" || { echo 'Set DMA_CONTEXT and a new ASRAM_BUILD_OUTPUT'; exit 2; }
	$(PYTHON) -B "$(FEATURE)/scripts/launch_bitstream.py" --context "$(DMA_CONTEXT)" --report-dir "$(ASRAM_BUILD_OUTPUT)" --vivado "$(VIVADO_BIN)"
