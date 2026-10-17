SHELL := /bin/bash
.DEFAULT_GOAL := help
FEATURE := $(abspath $(dir $(lastword $(MAKEFILE_LIST))))
REPO := $(abspath $(FEATURE)/../../..)
PYTHON ?= python3
WORKSPACE ?= $(REPO)/build/soc_workspaces/l2_1m_4bank
FALLBACK_WORKSPACE ?= $(REPO)/build/soc_workspaces/l2_1m_4bank_fallback
SOC_REFERENCE ?=

.PHONY: help check check-rtl check-bitstream check-workspace prepare soc resume soc-fallback
help:
	@printf '%s\n' \
	  'check             Audit frozen source hashes and the recorded generated RTL' \
	  'check-rtl         Same source and RTL checks as check' \
	  'check-bitstream   Also verify the local candidate bitstream hash (read only)' \
	  'check-workspace   Check effective overlays in WORKSPACE without compilation' \
	  'prepare           Copy SOC_REFERENCE to WORKSPACE and apply this variant' \
	  'soc               Prepare, compile and generate private 1 MiB / four-bank RTL' \
	  'resume            Regenerate RTL in an already prepared WORKSPACE' \
	  'soc-fallback      Generate private 512 KiB / two-bank RTL in FALLBACK_WORKSPACE' \
	  'Variables: SOC_REFERENCE=<Chipyard> WORKSPACE=<new-directory>'

check check-rtl:
	$(PYTHON) -B "$(FEATURE)/scripts/audit.py" --rtl

check-bitstream:
	$(PYTHON) -B "$(FEATURE)/scripts/audit.py" --rtl --bitstream

check-workspace:
	$(PYTHON) -B "$(FEATURE)/scripts/build_soc.py" --workspace "$(WORKSPACE)" --validate-workspace-only

prepare:
	$(PYTHON) -B "$(FEATURE)/scripts/build_soc.py" --reference "$(SOC_REFERENCE)" --workspace "$(WORKSPACE)" --prepare-only

soc:
	$(PYTHON) -B "$(FEATURE)/scripts/build_soc.py" --reference "$(SOC_REFERENCE)" --workspace "$(WORKSPACE)"

resume:
	$(PYTHON) -B "$(FEATURE)/scripts/build_soc.py" --workspace "$(WORKSPACE)" --resume

soc-fallback:
	$(PYTHON) -B "$(FEATURE)/scripts/build_soc.py" --reference "$(SOC_REFERENCE)" --workspace "$(FALLBACK_WORKSPACE)" --l2-banks 2
