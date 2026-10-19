# The production tree has one identity. The JSON manifest owns its path mapping.
set sc_product_repo [file dirname [file dirname [file dirname [file normalize [info script]]]]]
set SOC_ASRAM_PRIVATE 0
if {[info exists ::env(ASRAM_CANDIDATE_CONTEXT)] && $::env(ASRAM_CANDIDATE_CONTEXT) ne ""} {
    if {[info exists ::env(DMA_LOAD_CANDIDATE_CONTEXT)] && $::env(DMA_LOAD_CANDIDATE_CONTEXT) ne ""} {
        error "Select exactly one private candidate context"
    }
    set sc_candidate_root [file normalize [file join $sc_product_repo build experiments activation_sram]]
    if {![info exists ::env(VIVADO_PROJECT)] || \
        [string first "${sc_candidate_root}/" [file normalize $::env(VIVADO_PROJECT)]] != 0} {
        error "ASRAM candidate requires a private project below $sc_candidate_root"
    }
    set sc_asram_python python3
    if {[info exists ::env(ASRAM_PYTHON)] && $::env(ASRAM_PYTHON) ne ""} {
        set sc_asram_python $::env(ASRAM_PYTHON)
    }
    # Vivado exports PYTHONHOME/PYTHONPATH for its bundled interpreter. Do not
    # let those redirect the explicitly selected source-audit Python runtime.
    array set sc_product [exec env -u PYTHONHOME -u PYTHONPATH $sc_asram_python -B [file join $sc_product_repo hw versions \
        activation_sram_512kib_2bank scripts physical_candidate.py] \
        --context $::env(ASRAM_CANDIDATE_CONTEXT) --tcl]
    set SOC_ASRAM_PRIVATE 1
} elseif {[info exists ::env(DMA_LOAD_CANDIDATE_CONTEXT)] && $::env(DMA_LOAD_CANDIDATE_CONTEXT) ne ""} {
    # An experiment must own its project and must never select the production
    # XPR while substituting private collateral.
    set sc_candidate_root [file normalize [file join $sc_product_repo build experiments dma_load]]
    if {![info exists ::env(VIVADO_PROJECT)] || \
        [string first "${sc_candidate_root}/" [file normalize $::env(VIVADO_PROJECT)]] != 0} {
        error "DMA load candidate requires a private project below $sc_candidate_root"
    }
    array set sc_product [exec python3 [file join $sc_product_repo tools soc dma_load_candidate.py] \
        --context $::env(DMA_LOAD_CANDIDATE_CONTEXT) --tcl]
} else {
    array set sc_product [exec python3 [file join $sc_product_repo tools check check_current_product.py] --tcl]
}
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
