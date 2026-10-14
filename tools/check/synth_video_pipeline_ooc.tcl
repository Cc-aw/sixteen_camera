# Local synthesis only: no launch_runs, placement, routing or programming.
set kind [lindex $argv 0]
set out [file normalize [lindex $argv 1]]
set fd [open [lindex $argv 2] r]
foreach path [split [string trim [read $fd]] "\n"] {read_verilog -sv $path}
close $fd
if {![string match "2023.2*" [version -short]]} {error "Vivado 2023.2 required"}
set_param general.maxThreads 4
set tops [dict create ui-return ui_return_synthesis_top mosaic mosaic_rgb565_reader dvp dvp_event_bridge tensor-dma yolov5nu_multi_channel_tensor_dma perf-reset memory_perf_external camera camera_frontend_synthesis_top]
synth_design -top [dict get $tops $kind] -part xcvu13p-fhga2104-2-i -mode out_of_context \
    -flatten_hierarchy rebuilt -directive PerformanceOptimized -retiming -resource_sharing off -shreg_min_size 5
if {[llength [get_cells -hier -quiet -filter {IS_BLACKBOX == 1}]]} {error "Unresolved cells in $kind"}
switch -- $kind {
    ui-return {
        create_clock -name ui_clock -period 3.333 [get_ports ui_clk]
        create_clock -name video_clock -period 6.666 [get_ports video_clk]
        set reset_first [get_cells -hier -quiet -regexp {^dut/video_resetn_ui_sync_reg\[0\]$}]
        if {[llength $reset_first] != 1 || ![get_property ASYNC_REG $reset_first]} {
            error "UI return reset first synchronizer did not survive synthesis"
        }
        set first_d [get_pins -of_objects $reset_first -filter {REF_PIN_NAME == D}]
        if {[llength $first_d] != 1} {error "Missing UI return first-stage D"}
        set_false_path -to $first_d
        set counts [get_cells -hier -quiet -regexp {^dut/return_count_reg\[[01]\]$}]
        if {[llength $counts] != 2} {error "Return occupancy boundary was removed"}
        set fanin [all_fanin -flat -startpoints_only -to [get_ports m_rready]]
        foreach pin $fanin {
            set name [get_property NAME $pin]
            if {[string match *u_r/u_fifo* $name] || [string match *fifo_reset_pipe* $name]} {
                error "CDC FIFO combinational cone still drives MIG RREADY: $name"
            }
        }
        set fp [open [file join $out ready_startpoints.txt] w]
        puts $fp $fanin
        close $fp
    }
    dvp {
        create_clock -name capture_clock -period 3.333 [get_ports capture_clk]
        create_clock -name video_clock -period 6.666 [get_ports video_clk]
        if {![llength [get_cells -hier -quiet -filter {NAME =~ fifo_write_q_reg*}]]} {
            error "DVP FIFO write register boundary was removed"
        }
    }
    camera {
        create_clock -name capture_clock -period 3.333 [get_ports video_clk]
        create_clock -name control_clock -period 41.667 [get_ports ov7670_ctrl_clk]
        set local_regs [get_cells -hier -quiet -regexp {^dut/capture_active_local_reg\[[0-4]\]$}]
        if {[llength $local_regs] != 5} {error "Camera local capture/reset register bank was removed"}
    }
    perf-reset {
        create_clock -name soc_clock -period 10 [get_ports soc_clk]
        create_clock -name ddr_clock -period 3.333 [get_ports ddr_clk]
        if {[llength [get_cells -hier -quiet -filter {NAME =~ local_reset_sync_reg*}]] != 3} {
            error "Local memory statistics reset synchronizer was removed"
        }
    }
    default {create_clock -name video_clock -period 6.666 [get_ports clk]}
}
source [file join [file dirname [info script]] video_pipeline_ooc_constraints.tcl]
report_utilization -file [file join $out utilization.rpt]
report_timing_summary -delay_type min_max -file [file join $out timing.rpt]
report_drc -file [file join $out drc.rpt]
write_checkpoint -force [file join $out synthesized.dcp]
set fp [open [file join $out result.txt] w]
puts $fp "SYNTHESIS=PASS"
puts $fp "TARGET=$kind"
set setup [get_timing_paths -delay_type max -max_paths 1]
if {[llength $setup] != 1} {error "No internal setup path in $kind"}
set wns [get_property SLACK $setup]
puts $fp "WNS_NS=$wns"
puts $fp "TIMING_MET=[expr {$wns >= 0}]"
puts $fp "SCOPE=out_of_context_synthesis_only"
puts $fp "FULL_SYSTEM_ROUTED_TIMING=NOT_MEASURED"
close $fp
puts "VIDEO_PIPELINE_OOC=PASS target=$kind"
exit
