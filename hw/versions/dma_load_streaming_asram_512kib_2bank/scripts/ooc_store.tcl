# One full-size physical bank, using the actual production primitive wrapper.
set feature [file normalize [file join [file dirname [info script]] ..]]
if {$argc != 1} { error "Usage: ooc_store.tcl <new-report-directory>" }
set out [file normalize [lindex $argv 0]]
if {[file exists $out]} { error "Refusing to replace existing OOC output: $out" }
file mkdir $out
create_project -in_memory -part xcvu13p-fhga2104-2-i
read_verilog -sv [file join $feature activation_sram resources activation_sram_store.sv]
synth_design -top activation_sram_store -mode out_of_context -part xcvu13p-fhga2104-2-i
create_clock -name asram_clock -period 10.000 [get_ports clock]
set inputs [get_ports -filter {DIRECTION == IN && NAME != clock}]
set_input_delay -clock asram_clock 1.000 $inputs
set_output_delay -clock asram_clock 1.000 [get_ports -filter {DIRECTION == OUT}]
set urams [get_cells -hier -filter {REF_NAME =~ URAM288*}]
if {[llength $urams] != 72} { error "Expected 72 physical URAM, found [llength $urams]" }
report_utilization -file [file join $out utilization_synth.rpt]
opt_design
place_design
phys_opt_design
route_design
report_utilization -file [file join $out utilization.rpt]
report_timing_summary -file [file join $out timing.rpt]
report_route_status -file [file join $out route.rpt]
report_drc -file [file join $out drc.rpt]
write_checkpoint [file join $out routed.dcp]
set f [open [file join $out result.txt] w]
puts $f "ASRAM_STORE_OOC_COMPLETE URAM=72 CAPACITY_BYTES=2359296 PORTS=2 PIPELINE_CYCLES=2"
close $f
