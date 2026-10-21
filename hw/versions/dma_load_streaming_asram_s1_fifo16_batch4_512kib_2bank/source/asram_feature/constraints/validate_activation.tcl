# Small OOC netlist selection test; never place/route or build a bitstream.
if {$argc != 1} {error "Usage: validate_activation.tcl <new-report-dir>"}
set out [file normalize [lindex $argv 0]]
if {[file exists $out]} {error "Use a new fixture report directory"}
file mkdir $out
set flow [file dirname [file normalize [info script]]]
set feature [file dirname $flow]
create_project -in_memory -part xcvu13p-fhga2104-2-i
read_verilog -sv [file join $feature activation_sram resources activation_sram_store.sv]
read_verilog -sv [file join $feature tests asram_placement_fixture.sv]
synth_design -top asram_placement_fixture -mode out_of_context -flatten_hierarchy none
create_clock -period 10.000 [get_ports clock]
source [file join $flow physical_groups.tcl]
::asram_physical::activation_banks
foreach {lane slr} {0 SLR0 1 SLR1 2 SLR3} {
    set pb [get_pblocks asram_lane${lane}_uram]
    set cells [get_cells -of_objects $pb -filter {REF_NAME =~ URAM288*}]
    puts "ASRAM_FIXTURE_BLOCK lane=$lane cells=[llength $cells] soft=[get_property IS_SOFT $pb] ranges=[get_property GRID_RANGES $pb]"
    if {[llength $cells] != 72 || [get_property IS_SOFT $pb]} {error "Invalid lane $lane primitive block count=[llength $cells] soft=[get_property IS_SOFT $pb]"}
    if {[get_property GRID_RANGES $pb] ne $slr} {error "Unexpected lane $lane target region"}
    if {![get_property IS_SOFT [get_pblocks asram_lane${lane}_controller]]} {error "Controller must remain a soft guide"}
}
# Fail closed if a generated bank disappears or loses one primitive.
rename get_cells asram_real_get_cells
proc get_cells {args} {
    set result [uplevel 1 [list asram_real_get_cells {*}$args]]
    if {[lsearch -exact $args {REF_NAME =~ activation_sram_store*}] >= 0} {return [lrange $result 0 1]}
    return $result
}
if {![catch {::asram_physical::activation_banks} message] || ![string match {*three real*} $message]} {
    error "Missing-bank rejection failed: $message"
}
rename get_cells {}
proc get_cells {args} {
    set result [uplevel 1 [list asram_real_get_cells {*}$args]]
    if {[string match {*REF_NAME =~ URAM288*} $args]} {return [lrange $result 0 70]}
    return $result
}
if {![catch {::asram_physical::activation_banks} message] || ![string match {*72 URAM*} $message]} {
    error "Missing-primitive rejection failed: $message"
}
rename get_cells {}
rename asram_real_get_cells get_cells
set f [open [file join $out activation_replay.txt] w]
puts $f "ASRAM_ACTIVATION_PLACEMENT_REPLAY=PASS"
puts $f "physical_uram=216 lane_uram=72 targets=SLR0,SLR1,SLR3"
puts $f "missing_bank_rejected=1 missing_primitive_rejected=1"
puts $f "scope=storage_fixture_selection_only; full_SoC_place_route_NOT_RUN"
close $f
puts "ASRAM_ACTIVATION_PLACEMENT_REPLAY=PASS uram=216 negative_cases=2"
close_design
