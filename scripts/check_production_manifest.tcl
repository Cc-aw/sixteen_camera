set repo_root [file dirname [file dirname [file normalize [info script]]]]
source [file join $repo_root build rtl_manifest.tcl]
source [file join $repo_root build ip_manifest.tcl]
source [file join $repo_root build soc_manifest.tcl]
source [file join $repo_root build xdc_manifest.tcl]

set seen [dict create]
foreach {category sources} [list RTL $RTL_SOURCES IP $IP_SOURCES \
                                 XDC $XDC_SOURCES] {
    if {[llength $sources] == 0} {
        error "$category manifest is empty"
    }
    foreach relative_path $sources {
        if {[file pathtype $relative_path] ne "relative" ||
            [string match "../*" $relative_path]} {
            error "non-repository-relative $category path: $relative_path"
        }
        if {[dict exists $seen $relative_path]} {
            error "duplicate manifest path: $relative_path"
        }
        dict set seen $relative_path 1
        if {![file isfile [file join $repo_root $relative_path]]} {
            error "missing $category source: $relative_path"
        }
    }
}

# Every hand-written HDL file below rtl/ must be explicitly selected.  This
# catches an accidental new module that simulates locally but never enters the
# production Vivado project.
proc collect_hdl {directory} {
    set result {}
    foreach path [glob -nocomplain -directory $directory *] {
        if {[file isdirectory $path]} {
            set result [concat $result [collect_hdl $path]]
        } elseif {[file extension $path] in {.sv .v .vhd .vhdl}} {
            lappend result [file normalize $path]
        }
    }
    return $result
}
foreach path [collect_hdl [file join $repo_root rtl]] {
    set relative_path [string range $path [expr {[string length $repo_root] + 1}] end]
    if {![dict exists $seen $relative_path]} {
        error "unlisted production RTL source: $relative_path"
    }
}

set soc_dir [file join $repo_root $SOC_COLLATERAL_DIR]
if {![file isdirectory $soc_dir] ||
    ![file isfile [file join $soc_dir TaihangSoCFPGATestHarness.sv]]} {
    error "missing frozen production SoC: $SOC_COLLATERAL_DIR"
}
foreach forbidden {rtl/ip rtl/soc rtl/rtl_old} {
    if {[file exists [file join $repo_root $forbidden]]} {
        error "legacy/generated tree remains under production RTL: $forbidden"
    }
}
foreach retired {batch_preprocess_engine.sv frame_preprocess_accel.sv} {
    if {![file isfile [file join $repo_root legacy preprocess $retired]]} {
        error "missing retired preprocess module: $retired"
    }
}
puts "PRODUCTION_MANIFEST=PASS rtl=[llength $RTL_SOURCES] ip=[llength $IP_SOURCES] xdc=[llength $XDC_SOURCES] soc=$SOC_CONFIG"
