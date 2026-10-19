# Compatibility entry point for primitive/controller locality only.
# Real whole-chip builds use constraints/placement.tcl, including Head/L2/DDR.
source [file normalize [file join [file dirname [info script]] .. constraints physical_groups.tcl]]
::asram_physical::activation_banks
