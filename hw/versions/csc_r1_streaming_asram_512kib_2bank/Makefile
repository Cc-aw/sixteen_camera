SHELL := /bin/bash
.DEFAULT_GOAL := help
FEATURE := $(abspath $(dir $(lastword $(MAKEFILE_LIST))))
REPO := $(abspath $(FEATURE)/../../..)
-include $(REPO)/tools/config/tools.local.mk
VIVADO_BIN ?= vivado
export VIVADO_BIN
PYTHON ?= python3
CSC_OUT ?=
DMA_CONTEXT ?=
MEMORY_LATENCY ?= 7
LAYERS_RUN ?= baseline_layers
WORKLOAD_RUN ?= whole_workload
FULL_RTL_RUN ?= full_rtl
COMPACT_TRACE ?=
FULL_SINGLE_RUN ?= full_network_single
FULL_PARALLEL_RUN ?= full_network_parallel
FULL_RTL_THREADS ?= 1
PIPELINE_WATCHDOG ?= 60000
CALIBRATION_RUN ?= calibration_full
CANDIDATE_CONTEXT ?=
REFERENCE_BUILD ?=
CANDIDATE_RUN ?= candidate
CANDIDATE_BUILD ?= candidate_rtl

.PHONY: help init require-out require-context trace inventory analyze test-unit baseline-asram baseline-fault decide whole-capture command-rtl-build command-enumerate full-rtl-build calibrate-full full-single full-parallel analyze-full decide-full finalize-g0
help:
	@printf '%s\n' 'CSC-R1 G0 evidence and experimental G1 C1a; simulation only.' \
	 'Set CSC_OUT=<new run root> and DMA_CONTEXT=<verified C0 context>.' \
	 'init: freeze HEAD, initial dirty files/patch and decision policy in a new root' \
	 'trace: eight compact stages, four modes, three lanes; mode-2 lifecycle capture' \
	 'baseline-asram / baseline-fault: real generated RTL and vendor primitives' \
	 'inventory: roundtrip all frozen ordinary packets through native C helpers' \
	 'analyze: check SPAD/read/completion and physical TL trace ledgers' \
	 'test-unit: positive and negative reconstruction tests' \
	 'decide: write compact checkpoint decision/evidence; exit 2 for insufficient evidence' \
	 'whole-capture: all 166 native stages, 3 lanes, 2 frames, including WS and memory kernels' \
	 'command-rtl-build / command-enumerate: actual unrollers, synthetic backend; diagnostics only' \
	 'full-rtl-build: actual complete C0 Gemmini closure and physical lifecycle probes' \
	 'calibrate-full: compare all compact physical writes against COMPACT_TRACE=<archived XSim>' \
	 'full-single / full-parallel: complete native workload, real EX/SRAM/DMA; functional memory service' \
	 'analyze-full: physical bytes, source epochs, pending writers, credit/read/retirement ledgers' \
	 'decide-full: aggregate full evidence; G0 never implies physical-prototype GO' \
	 'finalize-g0: wait for full-parallel, audit full lanes + lane-0 control, independently check deletion, decide' \
	 'candidate-prepare: hash-guarded independent C1a overlay of DMA_CONTEXT' \
	 'candidate-build: full Gemmini C1a OFF/ON binary, set CANDIDATE_CONTEXT and REFERENCE_BUILD' \
	 'test-csc-unit: bounded RTL lifecycle and independent numerical comparator negative controls'
require-out:
	@test -n "$(CSC_OUT)" || { echo 'Set CSC_OUT'; exit 2; }
require-context:
	@test -n "$(DMA_CONTEXT)" || { echo 'Set DMA_CONTEXT'; exit 2; }
init: require-out
	$(PYTHON) -B "$(FEATURE)/scripts/freeze.py" --output "$(CSC_OUT)"
trace: require-out require-context
	$(PYTHON) -B "$(FEATURE)/scripts/run_baseline.py" --suite layers --context "$(DMA_CONTEXT)" --output "$(CSC_OUT)/$(LAYERS_RUN)" --memory-latency "$(MEMORY_LATENCY)"
baseline-asram: require-out require-context
	$(PYTHON) -B "$(FEATURE)/scripts/run_baseline.py" --suite asram --context "$(DMA_CONTEXT)" --output "$(CSC_OUT)/baseline_asram_retry"
baseline-fault: require-out require-context
	$(PYTHON) -B "$(FEATURE)/scripts/run_baseline.py" --suite fault --context "$(DMA_CONTEXT)" --output "$(CSC_OUT)/baseline_fault"
inventory: require-out
	$(PYTHON) -B "$(FEATURE)/analysis/workload_inventory.py" --output "$(CSC_OUT)/g0/inventory"
analyze: require-out
	$(PYTHON) -B "$(FEATURE)/analysis/analyze_residency.py" --trace "$(CSC_OUT)/$(LAYERS_RUN)/simulation" --output "$(CSC_OUT)/g0/residency"
test-unit:
	$(PYTHON) -B "$(FEATURE)/tests/test_residency_reference.py"
	$(PYTHON) -B "$(FEATURE)/tests/test_full_lifecycle.py"
	$(PYTHON) -B "$(FEATURE)/tests/test_elision.py"
decide: require-out require-context
	$(PYTHON) -B "$(FEATURE)/scripts/decide.py" --output "$(CSC_OUT)" --context "$(DMA_CONTEXT)" --layers-directory "$(LAYERS_RUN)"
whole-capture: require-out
	$(PYTHON) -B "$(FEATURE)/analysis/whole_workload.py" --output "$(CSC_OUT)/$(WORKLOAD_RUN)"
	$(PYTHON) -B "$(FEATURE)/analysis/validate_workload.py" --workload "$(CSC_OUT)/$(WORKLOAD_RUN)" --output "$(CSC_OUT)/workload_coverage.json"
	$(PYTHON) -B "$(FEATURE)/analysis/whole_memory.py" --workload "$(CSC_OUT)/$(WORKLOAD_RUN)/workload.json" --output "$(CSC_OUT)/functional_memory.bin"
command-rtl-build: require-out require-context
	$(PYTHON) -B "$(FEATURE)/scripts/full_command_rtl.py" --context "$(DMA_CONTEXT)" --output "$(CSC_OUT)/command_rtl"
command-enumerate: require-out
	"$(CSC_OUT)/command_rtl/obj/VCscCommandTrace" "$(CSC_OUT)/$(WORKLOAD_RUN)/native_commands.txt" "$(CSC_OUT)/enumerated_single" 1
	"$(CSC_OUT)/command_rtl/obj/VCscCommandTrace" "$(CSC_OUT)/$(WORKLOAD_RUN)/native_commands.txt" "$(CSC_OUT)/enumerated_parallel" 3
full-rtl-build: require-out require-context
	$(PYTHON) -B "$(FEATURE)/scripts/full_gemmini_rtl.py" --context "$(DMA_CONTEXT)" --output "$(CSC_OUT)/$(FULL_RTL_RUN)" --threads "$(FULL_RTL_THREADS)"
calibrate-full: require-out
	@test -n "$(COMPACT_TRACE)" || { echo 'Set COMPACT_TRACE to verified real XSim compact output'; exit 2; }
	$(PYTHON) -B "$(FEATURE)/analysis/calibrate_full.py" --compact "$(COMPACT_TRACE)" --executable "$(CSC_OUT)/$(FULL_RTL_RUN)/obj/VFullGemmini" --output "$(CSC_OUT)/$(CALIBRATION_RUN)"
full-single: require-out
	$(PYTHON) -B "$(FEATURE)/scripts/parallel_functional.py" --build "$(CSC_OUT)/$(FULL_RTL_RUN)" --commands "$(CSC_OUT)/$(WORKLOAD_RUN)/native_commands.txt" --memory "$(CSC_OUT)/functional_memory.bin" --output "$(CSC_OUT)/$(FULL_SINGLE_RUN)" --lanes 0 --timeout "$(PIPELINE_WATCHDOG)"
full-parallel: require-out
	$(PYTHON) -B "$(FEATURE)/scripts/parallel_functional.py" --build "$(CSC_OUT)/$(FULL_RTL_RUN)" --commands "$(CSC_OUT)/$(WORKLOAD_RUN)/native_commands.txt" --memory "$(CSC_OUT)/functional_memory.bin" --output "$(CSC_OUT)/$(FULL_PARALLEL_RUN)" --lanes 0,1,2 --timeout "$(PIPELINE_WATCHDOG)"
analyze-full: require-out
	$(PYTHON) -B "$(FEATURE)/scripts/assemble_functional.py" --source "$(CSC_OUT)/$(FULL_PARALLEL_RUN)" --output "$(CSC_OUT)/parallel_traces"
	$(PYTHON) -B "$(FEATURE)/analysis/analyze_full.py" --trace "$(CSC_OUT)/$(FULL_SINGLE_RUN)/lane0" --log "$(CSC_OUT)/$(FULL_SINGLE_RUN)/lane0.log" --workload "$(CSC_OUT)/$(WORKLOAD_RUN)/workload.json" --output "$(CSC_OUT)/single_residency" --lanes 1 --zero-owners
	$(PYTHON) -B "$(FEATURE)/analysis/analyze_full.py" --trace "$(CSC_OUT)/parallel_traces" --log "$(CSC_OUT)/parallel_traces/simulation.log" --workload "$(CSC_OUT)/$(WORKLOAD_RUN)/workload.json" --output "$(CSC_OUT)/parallel_residency" --zero-owners
	$(PYTHON) -B "$(FEATURE)/analysis/validate_elision.py" --summary "$(CSC_OUT)/parallel_residency/opportunity_summary.json" --qualified "$(CSC_OUT)/parallel_residency/qualified_loads.csv" --output "$(CSC_OUT)/parallel_residency/elision_model.json"
decide-full: require-out
	$(PYTHON) -B "$(FEATURE)/scripts/decide_full.py" --run "$(CSC_OUT)" --workload "$(WORKLOAD_RUN)" --rtl-build "$(FULL_RTL_RUN)" --calibration "$(CALIBRATION_RUN)"
finalize-g0: require-out
	$(PYTHON) -B "$(FEATURE)/scripts/finalize_g0.py" --run "$(CSC_OUT)" --execution "$(FULL_PARALLEL_RUN)" --workload "$(WORKLOAD_RUN)" --rtl-build "$(FULL_RTL_RUN)" --calibration "$(CALIBRATION_RUN)"

.PHONY: candidate-prepare candidate-build test-csc-unit
candidate-prepare: require-out require-context
	$(PYTHON) -B "$(FEATURE)/scripts/candidate_rtl.py" --context "$(DMA_CONTEXT)" --output "$(CSC_OUT)/$(CANDIDATE_RUN)"
candidate-build: require-out
	@test -n "$(CANDIDATE_CONTEXT)" -a -n "$(REFERENCE_BUILD)" || { echo 'Set CANDIDATE_CONTEXT and REFERENCE_BUILD'; exit 2; }
	$(PYTHON) -B "$(FEATURE)/scripts/build_candidate.py" --context "$(CANDIDATE_CONTEXT)" --reference-build "$(REFERENCE_BUILD)" --output "$(CSC_OUT)/$(CANDIDATE_BUILD)"
test-csc-unit: require-out
	mkdir -p "$(CSC_OUT)/unit"
	iverilog -g2012 -s tb_csc_r1_input_residency -o "$(CSC_OUT)/unit/residency.vvp" "$(FEATURE)/rtl/CscR1InputResidency.sv" "$(FEATURE)/tests/tb_csc_r1_input_residency.sv"
	vvp "$(CSC_OUT)/unit/residency.vvp"
	iverilog -g2012 -s tb_csc_r1_store_disjoint -o "$(CSC_OUT)/unit/store_disjoint.vvp" "$(FEATURE)/rtl/CscR1StoreDisjoint.sv" "$(FEATURE)/tests/tb_csc_r1_store_disjoint.sv"
	vvp "$(CSC_OUT)/unit/store_disjoint.vvp"
	$(PYTHON) -B -Werror::ResourceWarning "$(FEATURE)/tests/test_candidate_comparison.py"
	$(PYTHON) -B "$(FEATURE)/tests/test_g1_transactions.py"
