# Elaborate and generate the DDR block design only. Never launch synthesis.
set v3 [file dirname [file dirname [file normalize [info script]]]]
set out [file normalize [lindex $argv 0]]
if {[file exists $out]} {error "Use a new output directory"}
file mkdir $out
create_project memory_parallel_v3 $out -part xcvu13p-fhga2104-2-i
source [file join $v3 overlay prj create_design_1.tcl]
validate_bd_design
generate_target all [get_files */design_1.bd]
make_wrapper -files [get_files */design_1.bd] -top
set ipfiles [get_files -all *.xci]
set fd [open [file join $out ip_parameters.txt] w]
foreach ip $ipfiles {
    puts $fd "$ip"
    set obj [get_ips -quiet [file rootname [file tail $ip]]]
    if {[llength $obj]} {
        foreach prop [list_property $obj] {
            if {[regexp {CONFIG\..*(DATA_WIDTH|ID_WIDTH|THREAD|ACCEPTANCE|ISSUING|AxiIDWidth)} $prop]} {
                puts $fd "  $prop=[get_property $prop $obj]"
            }
        }
    }
}
close $fd
puts "DDR_V3_IP_GENERATION_PASS"
close_project
