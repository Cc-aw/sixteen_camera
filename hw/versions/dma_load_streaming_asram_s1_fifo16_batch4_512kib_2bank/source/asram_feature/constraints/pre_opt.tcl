# Keep the baseline CDC constraints and clock definitions unchanged.
set asram_repo [file normalize [file join [file dirname [info script]] ../../../..]]
source [file join $asram_repo hw constraints memory_parallel_v3_cdc.tcl]
source [file join $asram_repo hw constraints timing_sync_constraints.tcl]
