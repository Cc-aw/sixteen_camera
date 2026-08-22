# Refresh the clean phase-one project integration.
# design_1.bd is the only BD source; Vivado owns all generated BD HDL.
set script_dir [file dirname [file normalize [info script]]]
set project_file [file join $script_dir sixteen_camera.xpr]

open_project $project_file

# Keep hand-written RTL sources that are easy to remove accidentally anchored
# in sources_1 whenever the project integration is refreshed.
set required_rtl [list \
    [file normalize [file join $script_dir .. rtl video framebuffer \
        ddr_frame_reader.sv]]]
foreach rtl_file $required_rtl {
    if {![file exists $rtl_file]} {
        error "Required RTL source does not exist: $rtl_file"
    }
    if {[llength [get_files -quiet $rtl_file]] == 0} {
        add_files -fileset sources_1 -norecurse $rtl_file
        puts "RESTORED_REQUIRED_RTL=$rtl_file"
    }
}

set bd_file [get_files -quiet */design_1.bd]
if {[llength $bd_file] != 1} {
    error "Expected exactly one design_1.bd, found [llength $bd_file]"
}

generate_target all $bd_file
set wrapper_files [make_wrapper -files $bd_file -top -force]
foreach wrapper $wrapper_files {
    if {[llength [get_files -quiet $wrapper]] == 0} {
        add_files -fileset sources_1 -norecurse $wrapper
    }
}

set_property top top_wrapper [get_filesets sources_1]
set_property top top_wrapper [get_filesets sim_1]
update_compile_order -fileset sources_1
update_compile_order -fileset sim_1

set non_generated_design {}
foreach generated_file [get_files -quiet */design_1.v] {
    if {[get_property IS_GENERATED $generated_file] ne "1"} {
        lappend non_generated_design $generated_file
    }
}
if {[llength $non_generated_design] != 0} {
    error "Non-generated design_1.v source is registered: $non_generated_design"
}

puts "PHASE1_INTEGRATION=PASS"
puts "BD_FILE=$bd_file"
puts "WRAPPER_FILES=$wrapper_files"
puts "SOURCE_COUNT=[llength [get_files -of_objects [get_filesets sources_1]]]"
close_project
