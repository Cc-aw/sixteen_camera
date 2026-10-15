# Actual V3 settings, shared by GUI setup and batch builds.
set ::triple32_v3_flow_dir [file dirname [file normalize [info script]]]
proc apply_triple32_v3_run_settings {} {
    set flow $::triple32_v3_flow_dir
    foreach name {pre_opt.tcl placement_3x32.tcl placement_timing_repair.tcl postroute_timing_close.tcl} {
        set path [file join $flow $name]
        if {![llength [get_files -all -quiet $path]]} {
            add_files -fileset utils_1 -norecurse $path
        }
    }
    set repo [file normalize [file join $flow ../../..]]
    foreach name {memory_parallel_v3_cdc.tcl timing_sync_constraints.tcl} {
        set path [file join $repo hw constraints $name]
        if {![llength [get_files -all -quiet $path]]} {
            add_files -fileset utils_1 -norecurse $path
        }
    }
    set synth [get_runs synth_1]
    set impl [get_runs impl_1]
    set_property strategy Flow_PerfOptimized_high $synth
    set_property STEPS.SYNTH_DESIGN.ARGS.DIRECTIVE PerformanceOptimized $synth
    set_property STEPS.SYNTH_DESIGN.ARGS.RESOURCE_SHARING off $synth
    set_property STEPS.SYNTH_DESIGN.ARGS.GLOBAL_RETIMING on $synth
    set_property STEPS.SYNTH_DESIGN.ARGS.FSM_EXTRACTION auto $synth
    set_property STEPS.SYNTH_DESIGN.ARGS.NO_LC false $synth
    set_property STEPS.SYNTH_DESIGN.ARGS.KEEP_EQUIVALENT_REGISTERS false $synth
    set_property STEPS.SYNTH_DESIGN.ARGS.SHREG_MIN_SIZE 5 $synth
    set_property strategy Performance_SpreadSLLs $impl
    set_property STEPS.OPT_DESIGN.ARGS.DIRECTIVE ExploreWithRemap $impl
    set_property STEPS.OPT_DESIGN.TCL.PRE [file join $flow pre_opt.tcl] $impl
    set_property STEPS.PLACE_DESIGN.ARGS.DIRECTIVE SSI_SpreadLogic_high $impl
    set_property STEPS.PLACE_DESIGN.TCL.PRE [file join $flow placement_timing_repair.tcl] $impl
    set_property STEPS.PHYS_OPT_DESIGN.IS_ENABLED 1 $impl
    set_property STEPS.PHYS_OPT_DESIGN.ARGS.DIRECTIVE AggressiveExplore $impl
    set_property STEPS.ROUTE_DESIGN.ARGS.DIRECTIVE AlternateCLBRouting $impl
    set_property -dict [list {STEPS.ROUTE_DESIGN.ARGS.MORE OPTIONS} {-tns_cleanup}] $impl
    set_property STEPS.POST_ROUTE_PHYS_OPT_DESIGN.IS_ENABLED 1 $impl
    set_property STEPS.POST_ROUTE_PHYS_OPT_DESIGN.ARGS.DIRECTIVE AggressiveExplore $impl
    set_property STEPS.POST_ROUTE_PHYS_OPT_DESIGN.TCL.POST [file join $flow postroute_timing_close.tcl] $impl
}
