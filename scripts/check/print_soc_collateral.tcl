# Machine-readable path resolved through the same manifest as Vivado.
set repo_root [file dirname [file dirname [file dirname [file normalize [info script]]]]]
source [file join $repo_root config manifests soc_manifest.tcl]
switch -- $argv {
    {} { puts [file join $repo_root $SOC_COLLATERAL_DIR] }
    --flow { puts $SOC_BITSTREAM_FLOW }
    --config { puts $SOC_CONFIG }
    default { error "Usage: print_soc_collateral.tcl \[--flow|--config\]" }
}
