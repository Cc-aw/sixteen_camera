# The production tree has one identity. The JSON manifest owns its path mapping.
set sc_product_repo [file dirname [file dirname [file dirname [file normalize [info script]]]]]
array set sc_product [exec python3 [file join $sc_product_repo tools check check_current_product.py] --tcl]
set SOC_VARIANT $sc_product(hardware_alias)
set SOC_CONFIG $sc_product(soc_config)
foreach selector {SOC_VARIANT SOC_CONFIG} {
    if {[info exists ::env($selector)] && $::env($selector) ne "" && $::env($selector) ne [set $selector]} {
        error "Unsupported $selector '$::env($selector)'; production uses [set $selector]"
    }
}
set SOC_ALIASES [dict create $SOC_VARIANT $SOC_CONFIG]
set SOC_BITSTREAM_FLOW default
set SOC_COLLATERAL_DIR $sc_product(collateral_directory)
# Detect the actual port contract rather than relying on the configuration name.
# setup_vivado removes this define when switching back to an older SoC.
set SOC_TENSOR_INGRESS 0
set SOC_MEMORY_PARALLEL_V3 0
set sc_tensor_repo [file dirname [file dirname [file dirname [file normalize [info script]]]]]
set sc_tensor_harness [file join $sc_tensor_repo $SOC_COLLATERAL_DIR TaihangSoCFPGATestHarness.sv]
if {[file isfile $sc_tensor_harness]} {
    set sc_tensor_file [open $sc_tensor_harness r]
    set sc_tensor_text [read $sc_tensor_file]
    close $sc_tensor_file
    set SOC_TENSOR_INGRESS [regexp {axi4_tensor_aw_ready} $sc_tensor_text]
    set SOC_MEMORY_PARALLEL_V3 [regexp {memory_perf_command} $sc_tensor_text]
}
set SOC_HDL_EXTENSIONS {.v .sv .vh .svh .vhd .vhdl .mif .mem}

if {$SOC_MEMORY_PARALLEL_V3} {set SOC_BITSTREAM_FLOW triple32_v3}
