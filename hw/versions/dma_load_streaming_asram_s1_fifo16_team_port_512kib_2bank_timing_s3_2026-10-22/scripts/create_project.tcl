# Reconstruct this version's private project; no synthesis or implementation is launched.
set root [file normalize [file join [file dirname [info script]] ..]]
if {[llength $argv] != 2} {error "Pass a new project directory and selected generated output"}
set out [file normalize [lindex $argv 0]]
set generated [file normalize [lindex $argv 1]]
if {[string first "${root}/build/" "${out}/"] != 0 || [file exists $out]} {
    error "Use a new private directory below $root/build"
}
if {[string first 2023.2 [version -short]] < 0} {error "Vivado 2023.2 required"}
create_project s3 $out -part xcvu13p-fhga2104-2-i
set_property target_language Verilog [current_project]
set_property simulator_language Mixed [current_project]
set_property XPM_LIBRARIES {XPM_CDC XPM_FIFO XPM_MEMORY} [current_project]
set_property verilog_define {SOC_MEMORY_PARALLEL_V3 SOC_TENSOR_INGRESS} [get_filesets sources_1]
set_property include_dirs [list [file join $generated gen-collateral include]] [get_filesets sources_1]
exec env -u PYTHONHOME -u PYTHONPATH python3 -B [file join $root scripts project_inputs.py] --output $out --generated $generated
source [file join $out version_inputs.tcl]
generate_target all [get_ips -all]
source [file join $root board ip create_design_1.tcl]
set bd [get_files -quiet */design_1.bd]
if {[llength $bd] != 1} {error "Expected one DDR block design"}
validate_bd_design
save_bd_design
generate_target all $bd
add_files -norecurse [make_wrapper -files $bd -top]
set_property top top_wrapper [get_filesets sources_1]
update_compile_order -fileset sources_1
set synth_run [get_runs synth_1]
set impl_run [get_runs impl_1]
set_property STRATEGY Flow_PerfOptimized_high $synth_run
set_property STEPS.SYNTH_DESIGN.ARGS.DIRECTIVE PerformanceOptimized $synth_run
set_property STEPS.SYNTH_DESIGN.ARGS.SHREG_MIN_SIZE 5 $synth_run
set_property STEPS.SYNTH_DESIGN.ARGS.RESOURCE_SHARING off $synth_run
set_property STEPS.SYNTH_DESIGN.ARGS.GLOBAL_RETIMING on $synth_run
set_property STRATEGY Performance_SpreadSLLs $impl_run
set_property STEPS.OPT_DESIGN.ARGS.DIRECTIVE ExploreWithRemap $impl_run
set_property STEPS.PLACE_DESIGN.ARGS.DIRECTIVE SSI_SpreadSLLs $impl_run
set_property STEPS.PHYS_OPT_DESIGN.IS_ENABLED 1 $impl_run
set_property STEPS.PHYS_OPT_DESIGN.ARGS.DIRECTIVE AggressiveExplore $impl_run
set_property STEPS.ROUTE_DESIGN.ARGS.DIRECTIVE AlternateCLBRouting $impl_run
set_property -dict [list {STEPS.ROUTE_DESIGN.ARGS.MORE OPTIONS} {-tns_cleanup}] $impl_run
set_property STEPS.POST_ROUTE_PHYS_OPT_DESIGN.IS_ENABLED 1 $impl_run
set_property STEPS.POST_ROUTE_PHYS_OPT_DESIGN.ARGS.DIRECTIVE AggressiveExplore $impl_run
set hooks [file join $root board scripts npu3x32_100mhz]
foreach {run property name} {
    synth_1 STEPS.SYNTH_DESIGN.TCL.PRE init_s5.tcl
    impl_1 STEPS.INIT_DESIGN.TCL.PRE init_s5.tcl
    impl_1 STEPS.OPT_DESIGN.TCL.PRE memory_timing_s2_pre_opt.tcl
    impl_1 STEPS.PLACE_DESIGN.TCL.PRE placement_timing_s3.tcl
    impl_1 STEPS.POST_ROUTE_PHYS_OPT_DESIGN.TCL.POST postroute_timing_s3.tcl
} {
    set file [file join $hooks $name]
    if {![file isfile $file]} {error "Missing local hook $file"}
    add_files -fileset utils_1 -norecurse $file
    set_property $property $file [get_runs $run]
}
puts "S3_PROJECT_RECONSTRUCTED=PASS NO_RUNS_LAUNCHED=1"
close_project
