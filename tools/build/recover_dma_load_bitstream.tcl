# Generate a validation bitstream from the complete route, before post-route
# phys_opt. Keep the original checkpoint and failed implementation untouched.
set out [file normalize [lindex $argv 1]]
proc phase {value} {
    global out
    set fd [open [file join $out phase.txt] w]
    puts $fd $value
    close $fd
    puts "DMA_LOAD_RECOVERY_PHASE=$value"
}
proc recover {} {
    global argv out
    set_param general.maxThreads 8
    phase OPEN_ROUTED_CHECKPOINT
    open_checkpoint [file normalize [lindex $argv 0]]
    phase CHECK_ROUTE
    set report [file join $out route.rpt]
    report_route_status -file $report
    set fd [open $report r]
    set body [read $fd]
    close $fd
    foreach {key label} {routable {routable nets} routed {fully routed nets} errors {nets with routing errors}} {
        set pattern [format {# of %s[. ]* :[ ]*([0-9]+) :} $label]
        if {![regexp $pattern $body unused count($key)]} {
            error "Missing route status field: $label"
        }
    }
    if {$count(routable) == 0 || $count(routable) != $count(routed) || $count(errors) != 0} {
        error "Checkpoint is not completely routed"
    }
    phase CHECK_DRC_AND_TIMING
    report_drc -file [file join $out drc.rpt]
    report_timing_summary -delay_type min_max -report_unconstrained -file [file join $out routed_timing.rpt]
    check_timing -verbose -file [file join $out check_timing.rpt]
    phase WRITE_BITSTREAM
    set_property XPM_LIBRARIES {XPM_CDC XPM_FIFO XPM_MEMORY} [current_project]
    set bit [file join $out dma_load_streaming.bit]
    # Native write_bitstream DRC remains enabled, with original severities.
    write_bitstream $bit
    if {![file isfile $bit] || [file size $bit] == 0} {
        error "Missing or empty bitstream"
    }
    set fd [open [file join $out result.txt] w]
    puts $fd "BITSTREAM=$bit"
    puts $fd "ROUTABLE_NETS=$count(routable)"
    puts $fd "FULLY_ROUTED_NETS=$count(routed)"
    puts $fd "ROUTING_ERRORS=$count(errors)"
    close $fd
    close_design
    phase COMPLETE
}
if {[catch {recover} message options]} {
    puts stderr $message
    puts stderr [dict get $options -errorinfo]
    exit 1
}
exit 0
