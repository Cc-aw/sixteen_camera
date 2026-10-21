set s3_hook_dir [file dirname [info script]]
source [file join $s3_hook_dir memory_v3_pre_opt.tcl]
source [file join $s3_hook_dir .. .. xdc timing_s3_sync_constraints.tcl]
unset s3_hook_dir
