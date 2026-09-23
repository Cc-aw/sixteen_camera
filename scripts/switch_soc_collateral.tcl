# Register only the SoC selected by build/soc_manifest.tcl in an existing XPR.
set repo_root [file dirname [file dirname [file normalize [info script]]]]
source [file join $repo_root build soc_manifest.tcl]
open_project [file join $repo_root prj sixteen_camera.xpr]

set selected_dir [file normalize [file join $repo_root $SOC_COLLATERAL_DIR]]
if {![file isfile [file join $selected_dir TaihangSoCFPGATestHarness.sv]]} {
    error "selected SoC harness is missing: $selected_dir"
}

set stale {}
foreach source [get_files -quiet -of_objects [get_filesets sources_1]] {
    set path [file normalize [get_property NAME $source]]
    if {[string first "/generated/soc/" $path] >= 0 &&
        [string first "${selected_dir}/" $path] != 0} {
        lappend stale $source
    }
}
if {[llength $stale] > 0} {
    remove_files -fileset sources_1 $stale
}

set selected {}
foreach extension {.sv .v .vh .svh .vhd .vhdl .mif .mem} {
    foreach path [glob -nocomplain -directory $selected_dir *$extension] {
        set normalized [file normalize $path]
        lappend selected $normalized
        if {[llength [get_files -quiet $normalized]] == 0} {
            lappend missing $normalized
        }
    }
}
if {[info exists missing]} {
    add_files -fileset sources_1 -norecurse $missing
}
set_property top top_wrapper [get_filesets sources_1]
update_compile_order -fileset sources_1
puts "SOC_SWITCH=PASS removed=[llength $stale] selected=[llength $selected] config=$SOC_CONFIG"
close_project
