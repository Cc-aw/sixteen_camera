# Audit saved GUI/run properties and generated scripts; never run synthesis.
set repo [file dirname [file dirname [file dirname [file normalize [info script]]]]]
set project [file join $repo build projects triple32_v3_tensor sixteen_camera.xpr]
set out [file join $repo build reports hardware_project_audit]
if {[info exists ::env(VIVADO_PROJECT)] && $::env(VIVADO_PROJECT) ne ""} {
    set project [file normalize $::env(VIVADO_PROJECT)]
}
if {[info exists ::env(HARDWARE_PROJECT_AUDIT_DIR)] && $::env(HARDWARE_PROJECT_AUDIT_DIR) ne ""} {
    set out [file normalize $::env(HARDWARE_PROJECT_AUDIT_DIR)]
}
file mkdir $out
open_project $project
set expected [dict create \
    synth_1 [dict create STRATEGY Flow_PerfOptimized_high \
        STEPS.SYNTH_DESIGN.ARGS.DIRECTIVE PerformanceOptimized \
        STEPS.SYNTH_DESIGN.ARGS.RESOURCE_SHARING off \
        STEPS.SYNTH_DESIGN.ARGS.GLOBAL_RETIMING on \
        STEPS.SYNTH_DESIGN.ARGS.SHREG_MIN_SIZE 5] \
    impl_1 [dict create STRATEGY Performance_SpreadSLLs \
        STEPS.PLACE_DESIGN.ARGS.DIRECTIVE SSI_SpreadLogic_high \
        STEPS.ROUTE_DESIGN.ARGS.DIRECTIVE AlternateCLBRouting \
        STEPS.PHYS_OPT_DESIGN.ARGS.DIRECTIVE AggressiveExplore \
        STEPS.POST_ROUTE_PHYS_OPT_DESIGN.ARGS.DIRECTIVE AggressiveExplore]]
set fd [open [file join $out properties.txt] w]
foreach run [dict keys $expected] {
    foreach property [dict keys [dict get $expected $run]] {
        set actual [get_property $property [get_runs $run]]
        set wanted [dict get $expected $run $property]
        if {![string equal -nocase $actual $wanted]} {error "$run $property=$actual expected=$wanted"}
        puts $fd "$run $property=$actual"
    }
}
set definitions [get_property VERILOG_DEFINE [get_filesets sources_1]]
foreach define {SOC_MEMORY_PARALLEL_V3 SOC_TENSOR_INGRESS} {
    if {$define ni $definitions} {error "Missing design definition $define"}
}
puts $fd "DEFINES=$definitions"
puts $fd "SYNTH_STATUS=[get_property STATUS [get_runs synth_1]]"
puts $fd "IMPL_STATUS=[get_property STATUS [get_runs impl_1]]"
close $fd
set bd [get_files -all -quiet */design_1.bd]
if {[llength $bd] != 1} {error "Expected one DDR block design"}
open_bd_design $bd
foreach channel {AW W B AR R} {
    if {[get_property CONFIG.REG_$channel [get_bd_cells m00_full_regslice]] != 1} {
        error "DDR slice $channel must use full-throughput mode 1"
    }
}
foreach {property expected} {DATA_WIDTH 512 ID_WIDTH 2 NUM_READ_OUTSTANDING 32 NUM_WRITE_OUTSTANDING 32} {
    if {[get_property CONFIG.$property [get_bd_intf_ports S00_AXI]] != $expected} {
        error "Wrong DDR S00 $property"
    }
}
set fd [open [file join $out ddr_parameters.txt] w]
foreach ip [get_ips -all -quiet] {
    foreach property [list_property $ip] {
        if {[regexp {CONFIG\..*(DATA_WIDTH|ID_WIDTH|ACCEPTANCE|ISSUING|REG_AW|REG_W|REG_B|REG_AR|REG_R)} $property]} {
            puts $fd "$ip $property=[get_property $property $ip]"
        }
    }
}
close $fd
close_bd_design [get_bd_designs design_1]
# Repeated script generation leaves runs in "Scripts Generated". Reset only
# unstarted runs; refuse to discard any real synthesis/implementation results.
foreach run {synth_1 impl_1} {
    set status [get_property STATUS [get_runs $run]]
    if {[get_property PROGRESS [get_runs $run]] ne "0%" ||
        ![regexp -nocase {^(Not started|Scripts Generated)$} $status]} {
        error "Audit requires an unstarted project; preserving $run ($status)"
    }
}
reset_run synth_1
reset_run impl_1
launch_runs synth_1 -scripts_only
launch_runs impl_1 -scripts_only
foreach run {synth_1 impl_1} {
    set directory [get_property DIRECTORY [get_runs $run]]
    if {![file isfile [file join $directory top_wrapper.tcl]]} {error "$run script was not generated"}
    set fd [open [file join $directory top_wrapper.tcl] r]
    set text [read $fd]
    close $fd
    if {$run eq "impl_1"} {
        foreach token {SSI_SpreadLogic_high AlternateCLBRouting -tns_cleanup AggressiveExplore placement_timing_repair.tcl postroute_timing_close.tcl pre_opt.tcl} {
            if {[string first $token $text] < 0} {error "Implementation script is missing $token"}
        }
    }
    if {[get_property PROGRESS [get_runs $run]] ne "0%"} {error "$run unexpectedly ran"}
}
puts "HARDWARE_PROJECT_AUDIT=PASS latest_sources MaxPool_TensorIngress DDR_slice_mode1 GUI_batch_strategy scripts_only_no_runs"
close_project
exit
