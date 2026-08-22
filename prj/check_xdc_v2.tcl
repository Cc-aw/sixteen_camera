set script_dir [file dirname [file normalize [info script]]]
set project [file join $script_dir sixteen_camera.xpr]
open_project $project
set cs [get_files -of_objects [get_filesets constrs_1] *anti_interference_v2.xdc]
puts "V2_CONSTRAINT_FILES=$cs"
if {[llength $cs] != 1} { error "v2 constraint is not the sole active camera constraint" }
open_run synth_1
set ports [get_ports -quiet {cam_data[*] cam_pclk[*] cam_vsync[*] cam_href[*] cam_xclk[*] cam_scl[*] cam_sda[*] cam_rst_n[*] cam_pwdn[*]}]
puts "CAMERA_PORT_COUNT=[llength $ports]"
if {[llength $ports] != 128} { error "unexpected camera port count" }
read_xdc [file normalize [file join $script_dir .. xdc vu13p_ov7670_8ch_fmc1_fmc2_anti_interference_v2.xdc]] -ref top_wrapper
set unconstrained [get_ports -quiet {cam_data[*] cam_pclk[*] cam_vsync[*] cam_href[*] cam_xclk[*] cam_scl[*] cam_sda[*] cam_rst_n[*] cam_pwdn[*]}]
set missing {}
foreach p $unconstrained {
    if {[string equal [get_property PACKAGE_PIN $p] ""]} { lappend missing $p }
}
puts "CAMERA_UNPINNED=$missing"
if {[llength $missing] != 0} { error "camera ports without package pin" }
close_project
puts "XDC_V2_CHECK=PASS"
