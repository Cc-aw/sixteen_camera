foreach var {PROJECT_XPR FINAL_RESULTS_DIR FINAL_JOBS FINAL_THREADS} {
  if {![info exists ::env($var)] || $::env($var) eq ""} { error "Missing $var" }
}
if {![string match "2023.2*" [version -short]]} { error "Use Vivado 2023.2" }
set_param general.maxThreads $::env(FINAL_THREADS)
file mkdir $::env(FINAL_RESULTS_DIR)
open_project $::env(PROJECT_XPR)
set repo [file normalize [file join [file dirname [info script]] ../../..]]
source [file join $repo setup_vivado.tcl]
source [file join $repo config/manifests/soc_manifest.tcl]
if {![string match *TaihangSoC1Rocket1RVV3Gemmini64x64PackedInference100MHzConfig $SOC_CONFIG]} {
  error "Expected triple64 100 MHz video SoC in production manifest"
}
update_compile_order -fileset sources_1
set run [get_runs synth_1]
set_property AUTO_INCREMENTAL_CHECKPOINT 0 $run
set_property INCREMENTAL_CHECKPOINT {} $run
set_property strategy Flow_PerfOptimized_high $run
set_property -dict [list \
  STEPS.SYNTH_DESIGN.ARGS.FLATTEN_HIERARCHY rebuilt \
  STEPS.SYNTH_DESIGN.ARGS.GLOBAL_RETIMING on \
  {STEPS.SYNTH_DESIGN.ARGS.MORE OPTIONS} {-fanout_limit 64} \
  STEPS.SYNTH_DESIGN.ARGS.RESOURCE_SHARING auto \
  STEPS.SYNTH_DESIGN.ARGS.NO_LC false \
  STEPS.SYNTH_DESIGN.ARGS.KEEP_EQUIVALENT_REGISTERS false \
  STEPS.SYNTH_DESIGN.ARGS.SHREG_MIN_SIZE 3] $run
if {[info exists ::env(NPU_FLOW_CONFIG_ONLY)] && $::env(NPU_FLOW_CONFIG_ONLY) eq "1"} {
  puts "NPU0918_VIDEO_SYNTH_CONFIG=PASS strategy=[get_property strategy $run]"
  close_project
  return
}
reset_run $run
launch_runs $run -jobs $::env(FINAL_JOBS)
wait_on_run $run
if {[get_property PROGRESS $run] ne "100%" || [regexp -nocase {error|fail|cancel} [get_property STATUS $run]]} {
  error "synth_1 failed: [get_property STATUS $run]"
}
open_run $run
opt_design -directive ExploreWithRemap
report_timing_summary -delay_type min_max -max_paths 10 \
  -file [file join $::env(FINAL_RESULTS_DIR) synth_timing.rpt]
report_utilization -file [file join $::env(FINAL_RESULTS_DIR) synth_utilization.rpt]
write_checkpoint -force [file join $::env(FINAL_RESULTS_DIR) synth_opt.dcp]
close_project
