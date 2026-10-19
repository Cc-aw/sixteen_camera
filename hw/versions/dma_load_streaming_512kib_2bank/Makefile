SHELL := /bin/bash
.DEFAULT_GOAL := help
FEATURE := $(abspath $(dir $(lastword $(MAKEFILE_LIST))))
REPO := $(abspath $(FEATURE)/../../..)
PYTHON ?= python3
WORKSPACE ?= $(REPO)/build/soc_workspaces/dma_load_streaming_512kib_2bank
SOC_REFERENCE ?=
RUN_DIR ?= $(REPO)/build/experiments/dma_load/streaming_current
DMA_CONTEXT ?= $(RUN_DIR)/candidate/GENERATION_CONTEXT.json
DMA_UNITS ?= $(RUN_DIR)/units
DMA_SPAD ?= $(RUN_DIR)/acceptance/spad
DMA_FAULT ?= $(RUN_DIR)/acceptance/fault
TRACE_DIR ?= $(RUN_DIR)/trace_layers
BITSTREAM_DIR ?= $(RUN_DIR)/bitstream
SOC_BUFFERED ?= 0
DMA_OUTPUT ?= $(RUN_DIR)/validation
OUTPUT_ARG = $(if $(CANDIDATE_OUTPUT),--output "$(CANDIDATE_OUTPUT)") $(if $(filter 1,$(SOC_BUFFERED)),--buffered)

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

.PHONY: firmware verify-functional bitstream analyze-combining
firmware:
	$(MAKE) -C "$(FEATURE)/software" all host-check check DMA_CONTEXT="$(DMA_CONTEXT)" OUT="$(RUN_DIR)/firmware"

analyze-combining:
	$(PYTHON) -B "$(FEATURE)/scripts/analyze_combining.py" "$(TRACE_DIR)/spad_events_lane0.csv" --output "$(RUN_DIR)/combining_report.json"

verify-functional:
	$(PYTHON) -B "$(FEATURE)/scripts/verify_functional.py" --context "$(DMA_CONTEXT)" --units "$(DMA_UNITS)" --integration "$(RUN_DIR)/acceptance" --spad "$(DMA_SPAD)" --fault "$(DMA_FAULT)" --firmware "$(RUN_DIR)/firmware/dma_load_manifest.json" --trace-manifest "$(TRACE_DIR)/trace_manifest.json" --combining "$(RUN_DIR)/combining_report.json" --micro "$(RUN_DIR)/micro_comparison.json" --output "$(RUN_DIR)/verification.json"

bitstream: verify-functional
	$(PYTHON) -B "$(REPO)/tools/build/launch_dma_load_bitstream.py" --context "$(DMA_CONTEXT)" --verification "$(RUN_DIR)/verification.json" --report-dir "$(BITSTREAM_DIR)"
