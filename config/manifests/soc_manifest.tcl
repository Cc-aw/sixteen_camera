# Select one collateral tree. RTL updates in the same directory need no edits.
# Known aliases are conveniences; SOC_CONFIG can name any generated SoC tree.
set SOC_VARIANT triple64
if {[info exists ::env(SOC_VARIANT)]} {
    set SOC_VARIANT $::env(SOC_VARIANT)
}
set SOC_ALIASES [dict create \
    triple64 tsmcchip.fpga.taihangsoc.TaihangSoCFPGATestHarness.TaihangSoC1Rocket1RVV3Gemmini64x64PackedInference100MHzConfig \
    single4 tsmcchip.fpga.taihangsoc.TaihangSoCFPGATestHarness.TaihangSoC1Rocket1RVV1Gemmini4x4PackedFullOps256BitConfig \
    dual16 tsmcchip.fpga.taihangsoc.TaihangSoCFPGATestHarness.TaihangSoC1Rocket1RVV2Gemmini16x16PackedFullOps256BitConfig]
if {[info exists ::env(SOC_CONFIG)] && $::env(SOC_CONFIG) ne ""} {
    set SOC_CONFIG $::env(SOC_CONFIG)
} elseif {[dict exists $SOC_ALIASES $SOC_VARIANT]} {
    set SOC_CONFIG [dict get $SOC_ALIASES $SOC_VARIANT]
} else {
    error "Unknown SOC_VARIANT '$SOC_VARIANT'; use an existing alias or set SOC_CONFIG to a generated/soc directory name"
}
# SOC_CONFIG names a direct child of generated/soc, never an arbitrary path.
if {![regexp {^[A-Za-z0-9_][A-Za-z0-9_.-]*$} $SOC_CONFIG]} {
    error "SOC_CONFIG must be a generated/soc directory name"
}
set SOC_BITSTREAM_FLOW default
if {$SOC_CONFIG eq [dict get $SOC_ALIASES triple64]} {
    set SOC_BITSTREAM_FLOW triple64
}
set SOC_COLLATERAL_DIR "generated/soc/${SOC_CONFIG}/gen-collateral"
set SOC_HDL_EXTENSIONS {.v .sv .vh .svh .vhd .vhdl .mif .mem}
