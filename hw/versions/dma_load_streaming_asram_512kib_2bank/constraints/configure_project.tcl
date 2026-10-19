# Configure source membership and run hooks only. Never launch synthesis/implementation.
if {$argc != 3} {error "Usage: configure_project.tcl <context> <new.xpr> <report-dir>"}
set context [file normalize [lindex $argv 0]]
set project [file normalize [lindex $argv 1]]
set out [file normalize [lindex $argv 2]]
if {[file exists $project]} {error "Use a new private ASRAM project"}
set ::env(ASRAM_FEATURE_VARIANT) dma_load_streaming_asram_512kib_2bank
set ::env(ASRAM_CANDIDATE_CONTEXT) $context
set ::env(VIVADO_PROJECT) $project
set ::env(SOC_VARIANT) dma_load_streaming_asram_512kib_2bank
unset -nocomplain ::env(DMA_LOAD_CANDIDATE_CONTEXT) ::env(SOC_CONFIG)
set repo [file normalize [file join [file dirname [info script]] ../../../..]]
source [file join $repo hw vivado create_project.tcl]
set impl [get_runs impl_1]
set flow [file dirname [file normalize [info script]]]
foreach {property relative} {
    STEPS.OPT_DESIGN.TCL.PRE pre_opt.tcl
    STEPS.PLACE_DESIGN.TCL.PRE placement.tcl
    STEPS.POST_ROUTE_PHYS_OPT_DESIGN.TCL.POST base/postroute_timing_close.tcl
} {
    if {[file normalize [get_property $property $impl]] ne [file join $flow $relative]} {
        error "Private ASRAM run hook was not retained: $property"
    }
}
if {[get_property STEPS.WRITE_BITSTREAM.TCL.PRE $impl] ne ""} {
    error "Unexpected write_bitstream hook; this flow reports timing without a timing gate"
}
file mkdir $out
report_property -all [get_runs synth_1] -file [file join $out synth_properties.rpt]
report_property -all $impl -file [file join $out impl_properties.rpt]
set f [open [file join $out project_files.txt] w]
foreach name [lsort [get_property NAME [get_files -all]]] {puts $f $name}
close $f
set f [open [file join $out configured.txt] w]
puts $f "ASRAM_PROJECT_CONFIGURED=PASS"
puts $f "project=$project"
puts $f "context=$context"
puts $f "synthesis_started=0"
puts $f "implementation_started=0"
puts $f "timing_gate=none"
close $f
puts "ASRAM_PROJECT_CONFIGURED=PASS synthesis_started=0 implementation_started=0 timing_gate=none"
close_project
