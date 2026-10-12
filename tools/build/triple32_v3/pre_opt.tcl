set v3_repo [file dirname [file dirname [file dirname [file dirname [file normalize [info script]]]]]]
source [file join $v3_repo hw constraints memory_parallel_v3_cdc.tcl]
