# Rebuild the phase-one project with a clean Vivado project database.
# The DDR block design is reconstructed from create_design_1.tcl; generated
# wrappers and output products are created by Vivado and are never source
# inputs to this project.
set script_dir [file dirname [file normalize [info script]]]
set root_dir   [file normalize [file join $script_dir ..]]
set project_name sixteen_camera
set project_dir $script_dir
set part_name xcvu13p-fhga2104-2-i

create_project -force $project_name $project_dir -part $part_name
set_property target_language Verilog [current_project]
set_property simulator_language Mixed [current_project]
set_property ip_repo_paths [file join $root_dir ip_repo] [current_project]
update_ip_catalog

proc collect_files {root} {
    set result {}
    foreach entry [glob -nocomplain -directory $root *] {
        if {[file isdirectory $entry]} {
            set result [concat $result [collect_files $entry]]
        } elseif {[string tolower [file extension $entry]] in {.v .sv .vhd .vhdl .mif}} {
            lappend result [file normalize $entry]
        }
    }
    return $result
}

set sources {}
foreach subdir {interfaces bus control memory si5338 video} {
    set sources [concat $sources [collect_files [file join $root_dir rtl $subdir]]]
}
lappend sources [file join $root_dir rtl axi4_mmio_error_slave.sv]
lappend sources [file join $root_dir rtl top_wrapper.sv]

set soc_dir [file join $root_dir rtl soc \
    chipyard.fpga.myboard.MyBoardFPGATestHarness.SmallRocketVideoDDR256MyBoardConfig \
    gen-collateral]
set sources [concat $sources [collect_files $soc_dir]]

# Only top-level IP explicitly used by the RTL is added.  Old OV5645/MIPI XCI
# files are intentionally absent from this clean project.
foreach ip_xci [glob -nocomplain -directory [file join $root_dir rtl ip] */*.xci] {
    lappend sources [file normalize $ip_xci]
}

foreach source [lsort -unique $sources] {
    add_files -fileset sources_1 -norecurse $source
}

foreach constraint {clk.xdc ddr.xdc hdmi_tx.xdc mipi.xdc camera_sccb.xdc vu13p_ov7670_8ch_fmc1_fmc2_j2_cam3_legacy_v3.xdc} {
    set path [file join $root_dir xdc $constraint]
    if {[file exists $path]} {
        add_files -fileset constrs_1 -norecurse $path
    }
}

# Create the DDR BD in this project.  This is the only BD source operation.
source [file join $script_dir create_design_1.tcl]
set bd_file [get_files -quiet */design_1.bd]
if {[llength $bd_file] != 1} {
    error "Expected one generated design_1.bd, found [llength $bd_file]"
}
generate_target all $bd_file
set wrapper_files [make_wrapper -files $bd_file -top]
foreach wrapper $wrapper_files {
    if {[llength [get_files -quiet $wrapper]] == 0} {
        add_files -fileset sources_1 -norecurse $wrapper
    }
}

set_property top top_wrapper [get_filesets sources_1]
set_property top top_wrapper [get_filesets sim_1]
update_compile_order -fileset sources_1
update_compile_order -fileset sim_1
puts "CLEAN_BD_PROJECT=PASS"
puts "BD_FILE=$bd_file"
puts "WRAPPER_FILES=$wrapper_files"
puts "SOURCE_COUNT=[llength [get_files -of_objects [get_filesets sources_1]]]"
close_project
