# Export the active Vivado project source/IP/XDC/run inventory without saving
# project changes.
#
# Usage:
#   vivado -mode batch -source scripts/inventory_vivado.tcl -tclargs \
#     -project prj/sixteen_camera.xpr -out_dir reports/.../project_inventory

proc usage {} {
    puts "Usage: inventory_vivado.tcl -project <project.xpr> -out_dir <directory>"
}

set project_path ""
set out_dir ""
for {set i 0} {$i < [llength $argv]} {incr i} {
    set arg [lindex $argv $i]
    switch -- $arg {
        -project {
            incr i
            set project_path [lindex $argv $i]
        }
        -out_dir {
            incr i
            set out_dir [lindex $argv $i]
        }
        default {
            usage
            error "Unknown argument: $arg"
        }
    }
}
if {$project_path eq "" || $out_dir eq ""} {
    usage
    error "Both -project and -out_dir are required"
}

set project_path [file normalize $project_path]
set out_dir [file normalize $out_dir]
file mkdir $out_dir
open_project $project_path

set summary [open [file join $out_dir project.txt] w]
puts $summary "generated_at=[clock format [clock seconds] -format {%Y-%m-%dT%H:%M:%S%z}]"
puts $summary "vivado=[version -short]"
puts $summary "project=[get_property NAME [current_project]]"
puts $summary "part=[get_property PART [current_project]]"
puts $summary "source_top=[get_property TOP [get_filesets sources_1]]"
puts $summary "simulation_top=[get_property TOP [get_filesets sim_1]]"
foreach run_name {synth_1 impl_1} {
    set run [get_runs -quiet $run_name]
    if {[llength $run] != 0} {
        puts $summary "${run_name}.status=[get_property STATUS $run]"
        puts $summary "${run_name}.strategy=[get_property STRATEGY $run]"
        puts $summary "${run_name}.part=[get_property PART $run]"
    }
}
close $summary

set sources [open [file join $out_dir sources_compile_order.txt] w]
foreach file_obj [get_files -compile_order sources -used_in synthesis] {
    puts $sources [get_property NAME $file_obj]
}
close $sources

set constraints [open [file join $out_dir constraints_order.txt] w]
foreach file_obj [get_files -of_objects [get_filesets constrs_1]] {
    puts $constraints [join [list \
        [get_property PROCESSING_ORDER $file_obj] \
        [get_property USED_IN_SYNTHESIS $file_obj] \
        [get_property USED_IN_IMPLEMENTATION $file_obj] \
        [get_property NAME $file_obj]] "\t"]
}
close $constraints

set ips [open [file join $out_dir ips.txt] w]
foreach ip [lsort [get_ips -quiet]] {
    puts $ips [join [list \
        [get_property NAME $ip] \
        [get_property IPDEF $ip] \
        [get_property IS_LOCKED $ip] \
        [get_property IP_FILE $ip]] "\t"]
}
close $ips

puts "PROJECT_INVENTORY_DIR=$out_dir"
close_project
exit
