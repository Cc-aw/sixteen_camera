# Export a reproducible timing/CDC/methodology snapshot from a routed DCP.
#
# Usage:
#   vivado -mode batch -source scripts/report_video_timing.tcl -tclargs \
#     -dcp path/to/top_wrapper_routed.dcp \
#     -out_dir reports/video_timing_refactor/P0/baseline_reported

proc usage {} {
    puts "Usage: report_video_timing.tcl -dcp <routed.dcp> -out_dir <directory>"
}

# Timing paths can start or end at a design port as well as a cell pin.  Keep
# the exporter total over both cases so newly constrained I/O paths cannot
# terminate an otherwise complete stage report.
proc path_endpoint_object {path pin_property port_property} {
    set object [get_property -quiet $pin_property $path]
    if {[llength $object] == 0} {
        set object [get_property -quiet $port_property $path]
    }
    return $object
}

proc object_name_or_empty {object} {
    if {[llength $object] == 0} {
        return ""
    }
    return [get_property -quiet NAME $object]
}

proc slr_name_or_empty {object} {
    if {[llength $object] == 0} {
        return ""
    }
    set cells [get_cells -quiet -of_objects $object]
    if {[llength $cells] == 0} {
        return ""
    }
    return [get_property -quiet NAME [get_slrs -quiet -of_objects $cells]]
}

set dcp_path ""
set out_dir ""
for {set i 0} {$i < [llength $argv]} {incr i} {
    set arg [lindex $argv $i]
    switch -- $arg {
        -dcp {
            incr i
            set dcp_path [lindex $argv $i]
        }
        -out_dir {
            incr i
            set out_dir [lindex $argv $i]
        }
        default {
            usage
            error "Unknown argument: $arg"
        }
    }
}

if {$dcp_path eq "" || $out_dir eq ""} {
    usage
    error "Both -dcp and -out_dir are required"
}

set dcp_path [file normalize $dcp_path]
set out_dir [file normalize $out_dir]
if {![file exists $dcp_path]} {
    error "DCP does not exist: $dcp_path"
}
file mkdir $out_dir

open_checkpoint $dcp_path

report_timing_summary -delay_type min_max -check_timing_verbose \
    -report_unconstrained -max_paths 100 -file \
    [file join $out_dir timing_summary.rpt]
report_clocks -file [file join $out_dir clocks.rpt]
report_clock_interaction -delay_type min_max -file \
    [file join $out_dir clock_interaction.rpt]
report_cdc -details -file [file join $out_dir cdc.rpt]
report_methodology -file [file join $out_dir methodology.rpt]
check_timing -verbose -file [file join $out_dir check_timing.rpt]
report_exceptions -coverage -file \
    [file join $out_dir exceptions_coverage.rpt]
report_exceptions -ignored -file \
    [file join $out_dir exceptions_ignored.rpt]
report_control_sets -verbose -file [file join $out_dir control_sets.rpt]
report_utilization -hierarchical -hierarchical_depth 5 -file \
    [file join $out_dir utilization_hierarchical.rpt]
report_design_analysis -congestion -file \
    [file join $out_dir congestion.rpt]

# Keep a named audit artifact for the DVP IOB sampling aperture.  The global
# exception coverage report identifies this as the 88-cell 1.5 ns rule, while
# these reports retain the concrete endpoints and both max/min path delays.
set dvp_iob_cells [get_cells -hierarchical -filter \
    {NAME =~ *dvp_data_iob_reg* || \
     NAME =~ *dvp_href_iob_reg || \
     NAME =~ *dvp_vsync_iob_reg || \
     NAME =~ *dvp_pclk_iob_reg}]
set dvp_sync_cells [get_cells -hierarchical -filter \
    {NAME =~ *dvp_data_sync_reg* || \
     NAME =~ *dvp_href_sync_reg || \
     NAME =~ *dvp_vsync_sync_reg || \
     NAME =~ *dvp_pclk_sync_reg}]
set dvp_iob_q_pins [get_pins -of_objects $dvp_iob_cells -filter \
    {REF_PIN_NAME == Q}]
set dvp_sync_d_pins [get_pins -of_objects $dvp_sync_cells -filter \
    {REF_PIN_NAME == D}]
report_timing -delay_type max -max_paths 200 -unique_pins \
    -from $dvp_iob_q_pins -to $dvp_sync_d_pins -file \
    [file join $out_dir dvp_iob_to_sync_max.rpt]
report_timing -delay_type min -max_paths 200 -unique_pins \
    -from $dvp_iob_q_pins -to $dvp_sync_d_pins -file \
    [file join $out_dir dvp_iob_to_sync_min.rpt]
unset dvp_iob_q_pins
unset dvp_sync_d_pins
unset dvp_iob_cells
unset dvp_sync_cells

# One worst setup path per endpoint.  A generous max_paths is intentional: the
# exporter checks its count against the timing summary instead of silently
# treating a truncated list as complete.
set failing_paths [get_timing_paths -delay_type max -slack_lesser_than 0 \
    -max_paths 1000000 -unique_pins]
set table_path [file join $out_dir negative_endpoints.tsv]
set table [open $table_path w]
puts $table "slack\trequirement\tdatapath_delay\tlogic_levels\tstartpoint\tendpoint\tendpoint_pin_type\tstart_clock\tend_clock\tstart_slr\tend_slr"
foreach path $failing_paths {
    set start_pin [path_endpoint_object $path STARTPOINT_PIN STARTPOINT_PORT]
    set end_pin [path_endpoint_object $path ENDPOINT_PIN ENDPOINT_PORT]
    set start_clock [get_property STARTPOINT_CLOCK $path]
    set end_clock [get_property ENDPOINT_CLOCK $path]
    if {[get_property -quiet CLASS $end_pin] eq "port"} {
        set endpoint_pin_type "PORT"
    } else {
        set endpoint_pin_type [get_property -quiet REF_PIN_NAME $end_pin]
    }
    set start_slr [slr_name_or_empty $start_pin]
    set end_slr [slr_name_or_empty $end_pin]
    puts $table [join [list \
        [get_property SLACK $path] \
        [get_property REQUIREMENT $path] \
        [get_property DATAPATH_DELAY $path] \
        [get_property LOGIC_LEVELS $path] \
        [object_name_or_empty $start_pin] \
        [object_name_or_empty $end_pin] \
        $endpoint_pin_type \
        [object_name_or_empty $start_clock] \
        [object_name_or_empty $end_clock] \
        $start_slr \
        $end_slr] "\t"]
}
close $table

set manifest [open [file join $out_dir manifest.txt] w]
puts $manifest "generated_at=[clock format [clock seconds] -format {%Y-%m-%dT%H:%M:%S%z}]"
puts $manifest "vivado=[version -short]"
puts $manifest "part=[get_property PART [current_design]]"
puts $manifest "design=[current_design]"
puts $manifest "dcp=$dcp_path"
puts $manifest "dcp_mtime=[clock format [file mtime $dcp_path] -format {%Y-%m-%dT%H:%M:%S%z}]"
puts $manifest "negative_endpoint_rows=[llength $failing_paths]"
if {![catch {exec git -C [file dirname [file dirname [info script]]] rev-parse HEAD} git_head]} {
    puts $manifest "git_head=$git_head"
}
if {![catch {exec git -C [file dirname [file dirname [info script]]] status --porcelain} git_status]} {
    if {$git_status eq ""} {
        puts $manifest "git_dirty=false"
    } else {
        puts $manifest "git_dirty=true"
        puts $manifest "git_status_begin"
        puts $manifest $git_status
        puts $manifest "git_status_end"
    }
}
if {![catch {exec sha256sum $dcp_path} dcp_sha]} {
    puts $manifest "dcp_sha256=[lindex $dcp_sha 0]"
}
close $manifest

puts "VIDEO_TIMING_REPORT_DIR=$out_dir"
puts "NEGATIVE_ENDPOINT_ROWS=[llength $failing_paths]"
close_design
exit
