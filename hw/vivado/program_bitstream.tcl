set script_dir [file dirname [file normalize [info script]]]
set bitstream_file [file normalize [file join $script_dir sixteen_camera.runs impl_1 top_wrapper.bit]]
if {[info exists ::env(BITSTREAM_FILE)] && $::env(BITSTREAM_FILE) ne ""} {
    set bitstream_file [file normalize $::env(BITSTREAM_FILE)]
}
if {![file exists $bitstream_file]} {
    error "Bitstream not found: $bitstream_file"
}

open_hw_manager
connect_hw_server
if {[llength [get_hw_targets * -quiet]] == 0} {
    error "No Vivado hardware target found"
}
open_hw_target [lindex [get_hw_targets *] 0]
set devices [get_hw_devices]
if {[llength $devices] == 0} {
    error "No FPGA device found on hardware target"
}
set device [lindex $devices 0]
set_property PROGRAM.FILE $bitstream_file $device
program_hw_devices $device
puts "BITSTREAM_PROGRAM=PASS"
# Some board MIG builds expose empty version registers after programming.
# Refresh is useful for Hardware Manager diagnostics but is not required to
# keep the configured FPGA running, so do not turn that known condition into a
# failed bitstream download.
if {[catch {refresh_hw_device $device} refresh_error]} {
    puts "BITSTREAM_REFRESH_WARNING=$refresh_error"
} else {
    puts "BITSTREAM_REFRESH=PASS"
}
close_hw_target
disconnect_hw_server
close_hw_manager
