foreach var {FINAL_RESULTS_DIR SYNTH_DCP FINAL_THREADS} {
  if {![info exists ::env($var)] || $::env($var) eq ""} { error "Missing $var" }
}
if {![string match "2023.2*" [version -short]]} { error "Use Vivado 2023.2" }
set results [file normalize $::env(FINAL_RESULTS_DIR)]
file mkdir $results
set here [file dirname [file normalize [info script]]]
source [file join $here impl_reports_0918.tcl]
set_param general.maxThreads $::env(FINAL_THREADS)

open_checkpoint $::env(SYNTH_DCP)
# Board clocks, pins and CDC constraints are already in synth_opt.dcp.
# Standalone DDR/reset exceptions do not describe this video wrapper.
source [file join $here placement_0918_video.tcl]
check_source_slr_hints_0918

place_design -directive SSI_SpreadLogic_high
write_checkpoint -force [file join $results placed.dcp]
report_stage_0918 $results placed
placed_resource_gate $results placed

# Break up high-fanout control and allow sequential movement across the long
# Saturn datapaths before the broad physical optimization pass.
phys_opt_design -directive AggressiveFanoutOpt
report_stage_0918 $results physopt_fanout
phys_opt_design -directive AlternateFlowWithRetiming
report_stage_0918 $results physopt_retime
phys_opt_design -directive AggressiveExplore
write_checkpoint -force [file join $results physopt.dcp]
report_stage_0918 $results physopt

set route_threads 4
if {[info exists ::env(ROUTE_THREADS)]} { set route_threads $::env(ROUTE_THREADS) }
set_param general.maxThreads $route_threads
set failed [catch {route_design -directive Default -tns_cleanup} message]
puts "NPU0918_ROUTE directive=Default failed=$failed message=$message"
set route_metrics [report_stage_0918 $results route]
write_checkpoint -force [file join $results route.dcp]
if {$failed || ![legal_route]} {
  catch {report_design_analysis -congestion -file [file join $results route_failed_congestion.rpt]}
  error "0918 Default route is not legal"
}

set best_metrics $route_metrics
set best_checkpoint [file join $results route.dcp]

# Post-route passes are evaluated independently. A worse result is discarded by
# reopening the best checkpoint before the next attempt.
foreach {tag command} {
  postroute_explore {phys_opt_design -directive AggressiveExplore}
  postroute_critical {phys_opt_design -routing_opt -critical_pin_opt -critical_cell_opt}
} {
  if {[target_met_0918 $best_metrics]} { break }
  close_design
  open_checkpoint $best_checkpoint
  set opt_failed [catch {uplevel #0 $command} opt_message]
  puts "NPU0918_POSTROUTE tag=$tag failed=$opt_failed message=$opt_message"
  if {$opt_failed} { continue }
  if {![legal_route]} {
    set reroute_failed [catch {route_design -directive Default -tns_cleanup} reroute_message]
    puts "NPU0918_POSTROUTE_REROUTE tag=$tag directive=Default failed=$reroute_failed message=$reroute_message"
    if {$reroute_failed} { continue }
  }
  set candidate_metrics [report_stage_0918 $results $tag]
  set candidate_checkpoint [file join $results ${tag}.dcp]
  write_checkpoint -force $candidate_checkpoint
  if {[legal_route] && [better_0918 $candidate_metrics $best_metrics]} {
    set best_metrics $candidate_metrics
    set best_checkpoint $candidate_checkpoint
    puts "NPU0918_BEST tag=$tag checkpoint=$best_checkpoint"
  }
}

close_design
open_checkpoint $best_checkpoint
set hold_metrics [repair_hold_0918 $results hold]
if {[legal_route] && [better_0918 $hold_metrics $best_metrics]} {
  set best_metrics $hold_metrics
  set best_checkpoint [file join $results hold_best.dcp]
  write_checkpoint -force $best_checkpoint
}

close_design
open_checkpoint $best_checkpoint
set m [report_stage_0918 $results final]
set legal [legal_route]
set hold_clean [hold_clean_0918 $m]
set target [target_met_0918 $m]
write_checkpoint -force [file join $results final.dcp]
report_timing -delay_type min -slack_lesser_than 0 -max_paths 500 -nworst 1 \
  -file [file join $results final_hold.rpt]
report_timing -delay_type max -max_paths 500 -nworst 1 \
  -file [file join $results final_setup.rpt]
report_drc -file [file join $results final_drc.rpt]
report_bus_skew -file [file join $results final_bus_skew.rpt]
report_clock_interaction -file [file join $results final_clock_interaction.rpt]
check_timing -verbose -file [file join $results final_check_timing.rpt]
report_utilization -file [file join $results final_utilization.rpt]
report_utilization -hierarchical -hierarchical_depth 8 \
  -file [file join $results final_hierarchy.rpt]
catch {report_design_analysis -congestion -file [file join $results final_congestion.rpt]}

set bit ""
if {$legal && $hold_clean} {
  set suffix _setup_violated
  if {[dict get $m SETUP_FAIL] == 0} { set suffix "" }
  set bit [file join $results video_100m_3x64_0918${suffix}.bit]
  if {[catch {write_bitstream -force $bit} bit_error]} {
    puts "NPU0918_BIT_ERROR=$bit_error"
    set bit ""
  }
}
set fd [open [file join $results final_status.txt] w]
puts $fd "VIVADO_VERSION=[version -short]"
puts $fd "ROUTE_DIRECTIVE=Default"
puts $fd "LEGAL_ROUTE=$legal"
puts $fd "HOLD_CLEAN=$hold_clean"
puts $fd "TARGET_MET=$target"
puts $fd "TARGET_WNS=>0.000"
puts $fd "TARGET_TNS=0.000"
puts $fd "WNS_TNS_WHS_THS=[dict get $m WNS] [dict get $m TNS] [dict get $m WHS] [dict get $m THS]"
puts $fd "SETUP_FAILING_ENDPOINTS=[dict get $m SETUP_FAIL]"
puts $fd "HOLD_FAILING_ENDPOINTS=[dict get $m HOLD_FAIL]"
puts $fd "BEST_CHECKPOINT=[file join $results final.dcp]"
puts $fd "BITSTREAM=$bit"
close $fd
close_design
if {$bit eq ""} { error "Default implementation is not safe for bitstream generation" }
puts "NPU0918_IMPLEMENTATION_COMPLETE route=Default target=$target bitstream=$bit"
