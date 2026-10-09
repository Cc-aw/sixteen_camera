# Open or recreate the local project from source Tcl.
set repo_dir [file dirname [file dirname [file dirname [file normalize [info script]]]]]
source [file join $repo_dir hw vivado create_project.tcl]
