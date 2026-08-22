set script_dir [file dirname [file normalize [info script]]]
open_project [file join $script_dir sixteen_camera.xpr]

set camera_xdc [get_files -quiet *vu13p_ov7670_8ch_fmc1_fmc2_j2_cam3_legacy_v3.xdc]
if {[llength $camera_xdc] != 1} {
    error "expected exactly one active v3 camera XDC, got: $camera_xdc"
}

reset_run synth_1
launch_runs synth_1 -jobs 4
wait_on_run synth_1
if {![string equal [get_property STATUS [get_runs synth_1]] "synth_design Complete!"]} {
    error "synth_1 did not complete successfully"
}
open_run synth_1

set camera_clocks [get_clocks -quiet {cam_pclk_1 cam_pclk_2 cam_pclk_3 cam_pclk_4 cam_pclk_5 cam_pclk_6 cam_pclk_7 cam_pclk_8}]
puts "CAMERA_PCLK_CLOCKS=[llength $camera_clocks]"
if {[llength $camera_clocks] != 8} {
    error "not all camera PCLK constraints are active"
}

set constrained_inputs [get_ports -quiet \
    {cam_data[*] cam_href[*] cam_vsync[*] cam_pclk[*]}]
puts "CAMERA_DVP_INPUTS=[llength $constrained_inputs]"
if {[llength $constrained_inputs] != 88} {
    error "camera DVP input port coverage is incomplete"
}

set iob_cells [get_cells -hier -quiet -filter {
    NAME =~ *dvp_data_iob_reg* ||
    NAME =~ *dvp_href_iob_reg* ||
    NAME =~ *dvp_vsync_iob_reg* ||
    NAME =~ *dvp_pclk_iob_reg*
}]
puts "CAMERA_IOB_SAMPLE_CELLS=[llength $iob_cells]"
foreach cell $iob_cells {
    puts "CAMERA_IOB_CELL=$cell IOB=[get_property -quiet IOB $cell]"
    if {![string equal -nocase [get_property -quiet IOB $cell] "true"]} {
        error "camera input sample register lost its IOB property: $cell"
    }
}
if {[llength $iob_cells] != 88} {
    error "expected 88 DVP IOB sample registers"
}

puts "CAMERA_IOB_TIMING_CHECK=PASS"
close_design
close_project
