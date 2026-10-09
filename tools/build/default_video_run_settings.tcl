# Clear overrides left by a previous special flow in the shared XPR.
# Defaults apply to synthesis and implementation, including Tcl hooks.
proc apply_default_video_run_settings {} {
    foreach {name strategy} {
        synth_1 {Vivado Synthesis Defaults}
        impl_1 {Vivado Implementation Defaults}
    } {
        set run [get_runs $name]
        set_property strategy $strategy $run
        foreach property [list_property $run] {
            if {[string match STEPS.*.ARGS.* $property] ||
                [string match STEPS.*.TCL.* $property] ||
                [string match STEPS.*.IS_ENABLED $property]} {
                reset_property $property $run
            }
        }
        set_property AUTO_INCREMENTAL_CHECKPOINT 0 $run
        set_property INCREMENTAL_CHECKPOINT {} $run
    }
}
