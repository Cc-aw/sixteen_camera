set script_dir [file dirname [file normalize [info script]]]
open_project [file join $script_dir sixteen_camera.xpr]
update_ip_catalog

foreach core [get_ips -quiet] {
    puts "GENERATE_IP=[get_property NAME $core]"
    generate_target all $core
}
foreach bd [get_files -quiet *.bd] {
    puts "GENERATE_BD=[get_property NAME $bd]"
    generate_target all $bd
}
update_compile_order -fileset sources_1
puts "IP_OUTPUT_PREPARE=PASS"
close_project
