set repo_root [file dirname [file dirname [file dirname [file normalize [info script]]]]]
source [file join $repo_root hw manifests rtl_manifest.tcl]
source [file join $repo_root hw manifests ip_manifest.tcl]
source [file join $repo_root hw manifests soc_manifest.tcl]
source [file join $repo_root hw manifests xdc_manifest.tcl]

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

set soc_dir [file join $repo_root $SOC_COLLATERAL_DIR]
if {![file isdirectory $soc_dir] ||
    ![file isfile [file join $soc_dir TaihangSoCFPGATestHarness.sv]]} {
    error "missing frozen production SoC: $SOC_COLLATERAL_DIR"
}
foreach forbidden {hw/rtl/ip hw/rtl/soc hw/rtl/rtl_old} {
    if {[file exists [file join $repo_root $forbidden]]} {
        error "legacy/generated tree remains under production RTL: $forbidden"
    }
}
puts "PRODUCTION_MANIFEST=PASS rtl=[llength $RTL_SOURCES] ip=[llength $IP_SOURCES] xdc=[llength $XDC_SOURCES] soc=$SOC_CONFIG"
