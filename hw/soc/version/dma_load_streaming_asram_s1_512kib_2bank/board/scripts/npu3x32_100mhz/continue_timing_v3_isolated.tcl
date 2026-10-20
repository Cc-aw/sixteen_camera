# Continue from completed synthesis in the isolated project; do not rebuild RTL.
set repo [file normalize [file join [file dirname [info script]] ../..]]
set results [file normalize $::env(ISOLATED_RESULTS_DIR)]
set original [file normalize $::env(ORIGINAL_REPO_DIR)]
if {![string match "${results}/*" $repo] || $repo eq $original} {
    error "An isolated workspace beneath the results directory is required"
}
if {![string match "2023.2*" [version -short]]} { error "Vivado 2023.2 required" }
set_param general.maxThreads 8
if {[current_project -quiet] eq ""} {
    open_project [file join $repo prj sixteen_camera.xpr]
}
set synth [get_runs synth_1]
set impl [get_runs impl_1]
puts "RESUME_SYNTH_STATUS=[get_property STATUS $synth]"
if {[get_property STATUS $synth] ne "synth_design Complete!" ||
    [get_property NEEDS_REFRESH $synth]} {
    error "A completed, current synthesis run is required"
}
# Restore implementation parameters without touching completed synthesis.
set_property STRATEGY Performance_SpreadSLLs $impl
set_property STEPS.OPT_DESIGN.ARGS.DIRECTIVE ExploreWithRemap $impl
set_property STEPS.PLACE_DESIGN.ARGS.DIRECTIVE SSI_SpreadLogic_high $impl
set_property STEPS.PLACE_DESIGN.TCL.PRE [file join $repo scripts npu3x32_100mhz placement_3x32.tcl] $impl
set_property STEPS.PHYS_OPT_DESIGN.IS_ENABLED 1 $impl
set_property STEPS.PHYS_OPT_DESIGN.ARGS.DIRECTIVE AggressiveExplore $impl
set_property STEPS.ROUTE_DESIGN.ARGS.DIRECTIVE AlternateCLBRouting $impl
set_property -dict [list {STEPS.ROUTE_DESIGN.ARGS.MORE OPTIONS} {-tns_cleanup}] $impl
set_property STEPS.POST_ROUTE_PHYS_OPT_DESIGN.IS_ENABLED 1 $impl
set_property STEPS.POST_ROUTE_PHYS_OPT_DESIGN.ARGS.DIRECTIVE AggressiveExplore $impl
set_property STEPS.POST_ROUTE_PHYS_OPT_DESIGN.TCL.POST [file join $repo scripts npu3x32_100mhz postroute_timing_close.tcl] $impl
foreach run [get_runs] {
    if {![string match "${repo}/*" [file normalize [get_property DIRECTORY $run]]]} {
        error "Run directory is outside isolated workspace: $run"
    }
}
foreach f [get_files -all -quiet] {
    set path [file normalize [get_property NAME $f]]
    if {[string match "${original}/*" $path] && ![string match "${repo}/*" $path]} {
        error "Original file remains registered: $path"
    }
}
# Validate the accepted API step and generated flow before starting implementation.
launch_runs $impl -to_step {phys_opt_design (Post-Route)} -jobs 8 -scripts_only
set generated_script [file join [get_property DIRECTORY $impl] top_wrapper.tcl]
set fd [open $generated_script r]
set run_text [read $fd]
close $fd
foreach expected {
    {opt_design -directive ExploreWithRemap}
    {place_design -directive SSI_SpreadLogic_high}
    {route_design -directive AlternateCLBRouting -tns_cleanup}
    {phys_opt_design -directive AggressiveExplore}
    placement_3x32.tcl
    postroute_timing_close.tcl
} {
    if {[string first $expected $run_text] < 0} {
        error "Expected successful-run command missing from generated flow: $expected"
    }
}
puts "TIMING_V3_IMPLEMENTATION_SCRIPT_VALIDATION=PASS"
puts "ISOLATED_TIMING_V3_STAGE=IMPLEMENTATION"
launch_runs $impl -to_step {phys_opt_design (Post-Route)} -jobs 8
wait_on_run $impl
if {[regexp -nocase {error|fail|cancel} [get_property STATUS $impl]] ||
    ![file isfile [file join [get_property DIRECTORY $impl] top_wrapper_postroute_physopt.dcp]]} {
    error "Implementation failed: [get_property STATUS $impl]"
}
open_run $impl
report_timing_summary -delay_type min_max -report_unconstrained \
    -file [file join $results final_timing_summary.rpt]
report_timing -delay_type max -max_paths 20 -file [file join $results final_setup.rpt]
report_timing -delay_type min -max_paths 20 -file [file join $results final_hold.rpt]
report_utilization -file [file join $results final_utilization.rpt]
report_drc -file [file join $results final_drc.rpt]
check_timing -verbose -file [file join $results final_check_timing.rpt]
set route_report [report_route_status -return_string]
set fd [open [file join $results final_route_status.rpt] w]
puts $fd $route_report
close $fd
set setup [get_timing_paths -delay_type max -max_paths 1 -nworst 1]
set hold [get_timing_paths -delay_type min -max_paths 1 -nworst 1]
if {[llength $setup] != 1 || [llength $hold] != 1} {
    error "Setup/hold timing paths are unavailable"
}
set wns [get_property SLACK [lindex $setup 0]]
set whs [get_property SLACK [lindex $hold 0]]
set route_clean [regexp {# of nets with routing errors[^:]*:\s*0\s*:} $route_report]
set fd [open [file join $results final_status.txt] w]
puts $fd "WNS_NS=$wns"
puts $fd "WHS_NS=$whs"
puts $fd "LEGAL_ROUTE=$route_clean"
puts $fd "TARGET_MET=[expr {$route_clean && $wns > 0 && $whs >= 0}]"
close $fd
if {!$route_clean} {
    error "Timing/route did not pass: WNS=$wns WHS=$whs route_clean=$route_clean"
}
close_design
puts "ISOLATED_TIMING_V3_STAGE=WRITE_BITSTREAM"
launch_runs $impl -to_step write_bitstream -jobs 8
wait_on_run $impl
if {[get_property STATUS $impl] ne "write_bitstream Complete!"} {
    error "Bitstream generation failed: [get_property STATUS $impl]"
}
set bit [file join [get_property DIRECTORY $impl] top_wrapper.bit]
if {![file isfile $bit] || [file size $bit] == 0} { error "Bitstream is missing" }
set final_bit [file join $results top_wrapper_memory_parallel_v3.bit]
file copy $bit $final_bit
set fd [open [file join $results final_status.txt] a]
puts $fd "BITSTREAM=$final_bit"
if {$wns >= 0 && $whs >= 0} {puts $fd "BUILD=PASS"} else {puts $fd "BUILD=BITSTREAM_TIMING_UNMET"}
close $fd
puts "MEMORY_PARALLEL_V3_BITSTREAM_WRITTEN=$final_bit TARGET_MET=[expr {$wns >= 0 && $whs >= 0}]"
close_project
exit
