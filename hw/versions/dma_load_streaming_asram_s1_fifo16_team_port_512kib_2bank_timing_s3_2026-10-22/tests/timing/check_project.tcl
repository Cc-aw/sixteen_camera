# Read-only project strategy/locality audit; never launch any run.
set root [file normalize [file join [file dirname [info script]] .. ..]]
set project [file join $root build timing_project_01 s3.xpr]
if {[llength $argv] == 1} {set project [file normalize [lindex $argv 0]]}
open_project $project
set vendor [file normalize $::env(XILINX_VIVADO)]
set count 0
foreach file [get_files -all] {
    set path [file normalize [get_property NAME $file]]
    if {[string first "${root}/" $path] != 0 && [string first "${vendor}/" $path] != 0} {
        error "External project source: $path"
    }
    incr count
}
foreach run [get_runs] {
    set path [file normalize [get_property DIRECTORY $run]]
    if {[string first "[file dirname $project]/" "${path}/"] != 0} {
        error "External run directory: $path"
    }
}
foreach {run property expected} {
    synth_1 STRATEGY Flow_PerfOptimized_high
    synth_1 STEPS.SYNTH_DESIGN.ARGS.GLOBAL_RETIMING 1
    impl_1 STEPS.OPT_DESIGN.ARGS.DIRECTIVE ExploreWithRemap
    impl_1 STEPS.PLACE_DESIGN.ARGS.DIRECTIVE SSI_SpreadSLLs
    impl_1 STEPS.PHYS_OPT_DESIGN.IS_ENABLED 1
    impl_1 STEPS.PHYS_OPT_DESIGN.ARGS.DIRECTIVE AggressiveExplore
    impl_1 STEPS.ROUTE_DESIGN.ARGS.DIRECTIVE AlternateCLBRouting
    impl_1 {STEPS.ROUTE_DESIGN.ARGS.MORE OPTIONS} -tns_cleanup
    impl_1 STEPS.POST_ROUTE_PHYS_OPT_DESIGN.IS_ENABLED 1
    impl_1 STEPS.POST_ROUTE_PHYS_OPT_DESIGN.ARGS.DIRECTIVE AggressiveExplore
} {
    set actual [get_property $property [get_runs $run]]
    if {$expected eq "1"} {
        if {![string is boolean -strict $actual] || ![expr {$actual ? 1 : 0}]} {
            error "Disabled strategy setting $run $property: $actual"
        }
    } elseif {$actual ne $expected} {
        error "Strategy mismatch $run $property: $actual"
    }
}
foreach {run property name} {
    synth_1 STEPS.SYNTH_DESIGN.TCL.PRE init_s5.tcl
    impl_1 STEPS.INIT_DESIGN.TCL.PRE init_s5.tcl
    impl_1 STEPS.OPT_DESIGN.TCL.PRE memory_timing_s2_pre_opt.tcl
    impl_1 STEPS.PLACE_DESIGN.TCL.PRE placement_timing_s3.tcl
    impl_1 STEPS.POST_ROUTE_PHYS_OPT_DESIGN.TCL.POST postroute_timing_s3.tcl
} {
    set expected [file join $root board scripts npu3x32_100mhz $name]
    if {[file normalize [get_property $property [get_runs $run]]] ne $expected} {
        error "Incorrect implementation hook: $property"
    }
}
if {[get_property STEPS.PHYS_OPT_DESIGN.TCL.PRE [get_runs impl_1]] ne ""} {
    error "Unexpected forced control replication hook"
}
foreach ip [get_ips -all] {
    if {[get_property IS_LOCKED $ip]} {error "Locked IP: $ip"}
}
set file [open [file join $root validation project_strategy.txt] w]
puts $file "STATUS=S3_PROJECT_STRATEGY_PASS"
puts $file "PROJECT=$project"
puts $file "FILES=$count"
puts $file "SYNTH_STATUS=[get_property STATUS [get_runs synth_1]]"
puts $file "IMPL_STATUS=[get_property STATUS [get_runs impl_1]]"
puts $file "RUNS_LAUNCHED_BY_AUDIT=0"
close $file
puts "S3_PROJECT_STRATEGY_PASS FILES=$count RUNS_LAUNCHED=0"
close_project
