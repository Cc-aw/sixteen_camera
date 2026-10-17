SHELL := /bin/bash
.DEFAULT_GOAL := help
FEATURE := $(abspath $(dir $(lastword $(MAKEFILE_LIST))))
REPO := $(abspath $(FEATURE)/../../..)
PYTHON ?= python3
WORKSPACE ?= $(REPO)/build/soc_workspaces/dma_load_512kib_2bank
SOC_REFERENCE ?=
DMA_CONTEXT ?=
DMA_OUTPUT ?= $(REPO)/build/experiments/dma_load/version_validation
OUTPUT_ARG = $(if $(CANDIDATE_OUTPUT),--output "$(CANDIDATE_OUTPUT)")

.PHONY: help check test check-bitstream check-workspace check-rtl prepare soc resume test-unit test-rtl
help:
	@printf '%s\n' \
	  'check             Audit feature-local source hashes (no generated RTL implied)' \
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
