# Build only the selected S1 project. The imported board-validated bit stays frozen.
open_project $::env(S1_BUILD_PROJECT)
set hw [file normalize $::env(S1_HARDWARE_DIRECTORY)]
set stage $::env(S1_BUILD_STAGE)
set jobs $::env(S1_BUILD_JOBS)
set expected [file normalize [file join $hw board rtl top_wrapper.sv]]
set top_files [get_files -quiet */top_wrapper.sv]
if {[llength $top_files] != 1 || [file normalize [lindex $top_files 0]] ne $expected} {
    error "Project is not the selected S1 board source"
}
set expected_harness [file normalize [file join $hw generated gen-collateral TaihangSoCFPGATestHarness.sv]]
set harness [get_files -quiet */TaihangSoCFPGATestHarness.sv]
if {[llength $harness] != 1 || [file normalize [lindex $harness 0]] ne $expected_harness} {
    error "Project is not the selected S1 generated SoC"
}
if {$stage eq "elaborate"} {
    synth_design -rtl -name s1_elaborated -top top_wrapper -part xcvu13p-fhga2104-2-i
} else {
    set synth [get_runs synth_1]
    if {![string match "*Complete*" [get_property STATUS $synth]]} {
        launch_runs synth_1 -jobs $jobs
        wait_on_run synth_1
    }
    if {![string match "*Complete*" [get_property STATUS $synth]]} {error "S1 synthesis failed"}
    if {$stage eq "bitstream"} {
        set impl [get_runs impl_1]
        if {![string match "write_bitstream Complete*" [get_property STATUS $impl]]} {
            launch_runs impl_1 -to_step write_bitstream -jobs $jobs
            wait_on_run impl_1
        }
        if {![string match "write_bitstream Complete*" [get_property STATUS $impl]]} {error "S1 bitstream build failed"}
        puts "S1_REBUILT_BITSTREAM=[file join [get_property DIRECTORY $impl] top_wrapper.bit]"
    }
}
puts "S1_BUILD_STAGE=$stage COMPLETE"
close_project
