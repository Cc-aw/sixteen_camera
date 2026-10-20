set s4_hook_dir [file dirname [info script]]
source [file join $s4_hook_dir memory_v3_pre_opt.tcl]
source [file join $s4_hook_dir .. .. xdc timing_s4_sync_constraints.tcl]
unset s4_hook_dir

