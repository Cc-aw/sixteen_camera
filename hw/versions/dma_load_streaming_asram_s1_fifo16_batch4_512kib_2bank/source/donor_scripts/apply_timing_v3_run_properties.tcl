# Apply the timing-v3 run strategy to the currently open project. Keep this in
# one file so GUI builds and all batch entry points use identical properties.
set timing_v3_repo [file normalize [file join [file dirname [info script]] ..]]
set synth_run [get_runs synth_1]
set impl_run [get_runs impl_1]
foreach timing_v3_relative {
    scripts/npu3x32_100mhz/memory_v3_pre_opt.tcl
    scripts/npu3x32_100mhz/postroute_timing_close.tcl
    xdc/memory_parallel_v3_cdc.tcl
    xdc/timing_v3_sync_constraints.tcl
} {
    set timing_v3_hook [file join $timing_v3_repo $timing_v3_relative]
    if {[llength [get_files -all -quiet $timing_v3_hook]] == 0} {
        add_files -fileset utils_1 -norecurse $timing_v3_hook
    }
}

# The 3x32 design uses about 41% of the device LUTs, so timing optimization can
# spend more logic than the area-first strategy inherited from the 3x64 build.
set_property STRATEGY Flow_PerfOptimized_high $synth_run
set_property STEPS.SYNTH_DESIGN.ARGS.DIRECTIVE PerformanceOptimized $synth_run
set_property STEPS.SYNTH_DESIGN.ARGS.SHREG_MIN_SIZE 5 $synth_run
set_property STEPS.SYNTH_DESIGN.ARGS.FSM_EXTRACTION auto $synth_run
set_property STEPS.SYNTH_DESIGN.ARGS.RESOURCE_SHARING off $synth_run
set_property STEPS.SYNTH_DESIGN.ARGS.GLOBAL_RETIMING on $synth_run
set_property STEPS.SYNTH_DESIGN.ARGS.NO_LC 0 $synth_run
set_property STEPS.SYNTH_DESIGN.ARGS.KEEP_EQUIVALENT_REGISTERS 0 $synth_run

set_property STRATEGY Performance_SpreadSLLs $impl_run
set_property STEPS.OPT_DESIGN.ARGS.DIRECTIVE ExploreWithRemap $impl_run
set_property STEPS.OPT_DESIGN.TCL.PRE \
    [file join $timing_v3_repo scripts npu3x32_100mhz memory_v3_pre_opt.tcl] $impl_run
set_property STEPS.PLACE_DESIGN.ARGS.DIRECTIVE SSI_SpreadLogic_high $impl_run
set_property STEPS.PLACE_DESIGN.TCL.PRE \
    [file join $timing_v3_repo scripts npu3x32_100mhz placement_3x32.tcl] $impl_run
set_property STEPS.PHYS_OPT_DESIGN.IS_ENABLED 1 $impl_run
set_property STEPS.PHYS_OPT_DESIGN.ARGS.DIRECTIVE AggressiveExplore $impl_run
set_property STEPS.ROUTE_DESIGN.ARGS.DIRECTIVE AlternateCLBRouting $impl_run
set_property -dict [list \
    {STEPS.ROUTE_DESIGN.ARGS.MORE OPTIONS} {-tns_cleanup}] $impl_run
set_property STEPS.POST_ROUTE_PHYS_OPT_DESIGN.IS_ENABLED 1 $impl_run
set_property STEPS.POST_ROUTE_PHYS_OPT_DESIGN.ARGS.DIRECTIVE AggressiveExplore $impl_run
set_property STEPS.POST_ROUTE_PHYS_OPT_DESIGN.TCL.POST \
    [file join $timing_v3_repo scripts npu3x32_100mhz postroute_timing_close.tcl] $impl_run

unset timing_v3_repo
