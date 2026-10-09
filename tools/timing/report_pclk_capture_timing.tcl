# Inspect the routed capture paths without collecting the SoC's unrelated paths.
set dcp [lindex $argv 0]
set out_dir [lindex $argv 1]
if {$dcp eq "" || $out_dir eq ""} {
    error "usage: report_pclk_capture_timing.tcl <routed.dcp> <out_dir>"
}
file mkdir $out_dir
open_checkpoint $dcp
set iob_cells [get_cells -hier -filter {NAME =~ *dvp_data_iob_reg* || NAME =~ *dvp_href_iob_reg || NAME =~ *dvp_vsync_iob_reg || NAME =~ *dvp_pclk_iob_reg}]
set sync_cells [get_cells -hier -filter {NAME =~ *dvp_data_sync_reg* || NAME =~ *dvp_href_sync_reg || NAME =~ *dvp_vsync_sync_reg || NAME =~ *dvp_pclk_sync_reg}]
report_timing -delay_type max -max_paths 100 -unique_pins -from [get_pins -of_objects $iob_cells -filter {REF_PIN_NAME == Q}] -to [get_pins -of_objects $sync_cells -filter {REF_PIN_NAME == D}] -file [file join $out_dir iob_to_sync.rpt]
set capture_cells [get_cells -hier -filter {NAME =~ *g_camera_frontend*}]
report_timing -delay_type max -max_paths 200 -unique_pins -to [get_pins -of_objects $capture_cells -filter {REF_PIN_NAME == D || REF_PIN_NAME == CE}] -file [file join $out_dir capture_endpoints.rpt]
report_timing -delay_type max -max_paths 100 -unique_pins -to [get_pins -hier -filter {NAME =~ *u_pclk_recovery*/D || NAME =~ *u_pclk_recovery*/CE}] -file [file join $out_dir recovery_endpoints.rpt]
close_design
