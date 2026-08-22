# Configure and verify the DDR AXI acceptance used by the phase-one project.
# The writer and reader both use a fixed AXI ID and rely on the interconnect
# retaining eight transactions, so keep the interface and Xbar limits equal.
set script_dir [file dirname [file normalize [info script]]]
set project_path [file join $script_dir sixteen_camera.xpr]
open_project $project_path

set bd_files [get_files -quiet */design_1.bd]
if {[llength $bd_files] != 1} {
    error "Expected one design_1.bd, found [llength $bd_files]"
}
set bd_file [lindex $bd_files 0]
open_bd_design $bd_file

set writer_port [get_bd_intf_ports -quiet S01_AXI]
set reader_port [get_bd_intf_ports -quiet S02_AXI]
set interconnect [get_bd_cells -quiet axi_interconnect_0]
if {[llength $writer_port] != 1 || [llength $reader_port] != 1 ||
    [llength $interconnect] != 1} {
    error "Missing S01_AXI, S02_AXI, or axi_interconnect_0"
}

set_property CONFIG.NUM_WRITE_OUTSTANDING 8 $writer_port
set_property CONFIG.NUM_READ_OUTSTANDING 8 $reader_port
# Acceptance is automatically propagated by the AXI interconnect from these
# external interface settings.  Its internal xbar is an appcore and read-only.

validate_bd_design
save_bd_design

foreach check {
    {writer_port CONFIG.NUM_WRITE_OUTSTANDING 8}
    {reader_port CONFIG.NUM_READ_OUTSTANDING 8}
} {
    lassign $check object_name property expected
    set object [set $object_name]
    set actual [get_property $property $object]
    if {$actual ne $expected} {
        error "$property expected $expected, got $actual"
    }
    puts "AXI_ACCEPTANCE $property=$actual"
}

generate_target all $bd_file
update_compile_order -fileset sources_1
update_compile_order -fileset sim_1
puts "AXI_OUTSTANDING_CONFIG=PASS"
close_project
