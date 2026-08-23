set script_dir [file dirname [file normalize [info script]]]
open_project [file join $script_dir sixteen_camera.xpr]

set project_ip_dir [file normalize [file join $script_dir .. rtl ip]]
foreach xci_file [list \
    [file join $project_ip_dir clk_wiz_ov7670 clk_wiz_ov7670.xci]] {
    if {![file exists $xci_file]} { error "Missing project IP source: $xci_file" }
    if {[llength [get_files -quiet [file normalize $xci_file]]] == 0} {
        add_files -norecurse $xci_file
    }
}

update_compile_order -fileset sources_1
set_property top top_wrapper [get_filesets sources_1]
puts "PROJECT_IP_REGISTERED=PASS"
close_project
