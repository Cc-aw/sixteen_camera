# Run only in the copied workspace created by build_triple32_timing_v3_isolated.py.
set repo [file normalize [file join [file dirname [info script]] ../..]]
set results [file normalize $::env(ISOLATED_RESULTS_DIR)]
set original [file normalize $::env(ORIGINAL_REPO_DIR)]
if {![string match "${results}/*" $repo] || $repo eq $original} {
    error "An isolated workspace beneath the new results directory is required"
}
if {![string match "2023.2*" [version -short]]} { error "Vivado 2023.2 required" }
set_param general.maxThreads 8
open_project [file join $repo prj sixteen_camera.xpr]
# Module references require automatic compile order.
set_property SOURCE_MGMT_MODE All [current_project]
# Delete only the copied baseline BD and generated wrapper, then rebuild
# from V3 Tcl. Reusing a 256-bit BD with the new SoC is forbidden.
set stale_bd [get_files -all -quiet */design_1.bd]
set stale_wrappers [get_files -all -quiet */design_1_wrapper.v]
if {[llength $stale_wrappers]} {remove_files $stale_wrappers}
if {[llength $stale_bd]} {remove_files $stale_bd}
foreach relative {prj/sixteen_camera.srcs/sources_1/bd/design_1 prj/sixteen_camera.gen/sources_1/bd/design_1} {
    set stale [file normalize [file join $repo $relative]]
    if {![string match "${repo}/*" $stale]} {error "Unsafe copied BD path"}
    file delete -force $stale
}
source [file join $repo setup_vivado.tcl]
open_bd_design [get_files */design_1.bd]
foreach {key expected} {DATA_WIDTH 512 ID_WIDTH 2 NUM_READ_OUTSTANDING 32 NUM_WRITE_OUTSTANDING 32} {
    if {[get_property CONFIG.$key [get_bd_intf_ports S00_AXI]] != $expected} {error "Wrong V3 DDR S00 $key"}
}
if {[get_property MODE [get_bd_intf_pins u_mig_perf/S_AXI]] ne "Monitor"} {error "MIG tap is not passive"}

if {$sc_total_failed != 0 || $sc_top_status ne "OK" ||
    $::sixteen_camera_setup::bd_status ne "OK" ||
    $::sixteen_camera_setup::wrapper_status ne "OK"} {
    error "Project source synchronization failed"
}

# setup_vivado registers sources but also changes strategies. Restore the
# settings evidenced by the successful October 7 project run afterwards.
source [file join $repo scripts apply_timing_v3_run_properties.tcl]
set synth [get_runs synth_1]
set impl [get_runs impl_1]
set_property STEPS.SYNTH_DESIGN.ARGS.SHREG_MIN_SIZE 5 $synth
set_property STEPS.SYNTH_DESIGN.ARGS.DIRECTIVE PerformanceOptimized $synth
set_property AUTO_INCREMENTAL_CHECKPOINT 0 $synth
set_property INCREMENTAL_CHECKPOINT {} $synth
set_property AUTO_INCREMENTAL_CHECKPOINT 0 $impl
set_property INCREMENTAL_CHECKPOINT {} $impl
set_property STEPS.OPT_DESIGN.TCL.PRE [file join $repo scripts npu3x32_100mhz memory_v3_pre_opt.tcl] $impl
update_compile_order -fileset sources_1

set fd [open [file join $results effective_run_settings.txt] w]
foreach run [list $synth $impl] {
    puts $fd "RUN=$run"
    report_property $run -file [file join $results ${run}_properties.rpt]
    foreach property {STRATEGY DIRECTORY AUTO_INCREMENTAL_CHECKPOINT INCREMENTAL_CHECKPOINT} {
        puts $fd "$property=[get_property $property $run]"
    }
}
puts $fd "SHREG_MIN_SIZE=[get_property STEPS.SYNTH_DESIGN.ARGS.SHREG_MIN_SIZE $synth]"
puts $fd "PLACE_PRE=[get_property STEPS.PLACE_DESIGN.TCL.PRE $impl]"
puts $fd "POSTROUTE_POST=[get_property STEPS.POST_ROUTE_PHYS_OPT_DESIGN.TCL.POST $impl]"
close $fd

# No file, output directory, or hook may point into the original workspace.
set fd [open [file join $results registered_files.txt] w]
foreach f [get_files -all -quiet] {
    set path [file normalize [get_property NAME $f]]
    puts $fd $path
    if {[string match "${original}/*" $path] && ![string match "${repo}/*" $path]} {
        error "Original project file remains registered: $path"
    }
}
close $fd
foreach run [get_runs] {
    set directory [file normalize [get_property DIRECTORY $run]]
    if {![string match "${repo}/*" $directory]} {
        error "Run output is outside isolated workspace: $run $directory"
    }
}
foreach property {STEPS.PLACE_DESIGN.TCL.PRE STEPS.POST_ROUTE_PHYS_OPT_DESIGN.TCL.POST} {
    if {![string match "${repo}/*" [get_property $property $impl]]} {
        error "Implementation hook is outside isolated workspace: $property"
    }
}

# Rebuild the BD IP synthesis products as well: the copied crossbar DCP may
# still correspond to eight credits despite the updated 32-credit XCI.
set bd [get_files -all -quiet */design_1.bd]
reset_target synthesis $bd
generate_target all $bd
create_ip_run $bd
reset_run $impl
foreach run [get_runs -filter {IS_SYNTHESIS == 1}] { reset_run $run }
puts "ISOLATED_TIMING_V3_STAGE=SYNTHESIS"
launch_runs $synth -jobs 8
wait_on_run $synth
if {[get_property PROGRESS $synth] ne "100%" ||
    [get_property STATUS $synth] ne "synth_design Complete!"} {
    error "Synthesis failed: [get_property STATUS $synth]"
}
open_run $synth
source [file join $repo xdc memory_parallel_v3_cdc.tcl]
report_utilization -file [file join $results synthesis_utilization.rpt]
report_timing_summary -file [file join $results synthesis_timing.rpt]
close_design
set fd [open [file join $results SYNTHESIS_DONE] w]
puts $fd "synth_design Complete!; V3 CDC constraints checked"
close $fd
puts "MEMORY_PARALLEL_V3_SYNTHESIS_COMPLETE"
source [file join $repo scripts npu3x32_100mhz continue_timing_v3_isolated.tcl]
