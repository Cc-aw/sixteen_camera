# Select one collateral tree. RTL updates in the same directory need no edits.
# The current three-worker configuration is the only production alias.
set SOC_VARIANT triple32_v3_tensor
if {[info exists ::env(SOC_VARIANT)]} {
    set SOC_VARIANT $::env(SOC_VARIANT)
}
set SOC_ALIASES [dict create \
    triple32_v3_tensor tsmcchip.fpga.taihangsoc.TaihangSoCFPGATestHarness.TaihangSoC1Rocket1RVV3Gemmini32x32MemoryParallelV3TensorIngressConfig]
if {[info exists ::env(SOC_CONFIG)] && $::env(SOC_CONFIG) ne ""} {
    set SOC_CONFIG $::env(SOC_CONFIG)
} elseif {[dict exists $SOC_ALIASES $SOC_VARIANT]} {
    set SOC_CONFIG [dict get $SOC_ALIASES $SOC_VARIANT]
} else {
    error "Unknown SOC_VARIANT '$SOC_VARIANT'; use an existing alias or set SOC_CONFIG to a hw/soc directory name"
}
# SOC_CONFIG names a direct child of hw/soc, never an arbitrary path.
if {![regexp {^[A-Za-z0-9_][A-Za-z0-9_.-]*$} $SOC_CONFIG]} {
    error "SOC_CONFIG must be a hw/soc directory name"
}
set SOC_BITSTREAM_FLOW default
set SOC_COLLATERAL_DIR "hw/soc/${SOC_CONFIG}/gen-collateral"
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
