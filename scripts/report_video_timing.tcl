# Export a reproducible timing/CDC/methodology snapshot from a routed DCP.
#
# Usage:
#   vivado -mode batch -source scripts/report_video_timing.tcl -tclargs \
#     -dcp path/to/top_wrapper_routed.dcp \
#     -out_dir reports/video_timing_refactor/P0/baseline_reported

proc usage {} {
    puts "Usage: report_video_timing.tcl -dcp <routed.dcp> -out_dir <directory>"
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

# One worst setup path per endpoint.  A generous max_paths is intentional: the
# exporter checks its count against the timing summary instead of silently
# treating a truncated list as complete.
set failing_paths [get_timing_paths -delay_type max -slack_lesser_than 0 \
    -max_paths 1000000 -unique_pins]
set table_path [file join $out_dir negative_endpoints.tsv]
set table [open $table_path w]
puts $table "slack\trequirement\tdatapath_delay\tlogic_levels\tstartpoint\tendpoint\tendpoint_pin_type\tstart_clock\tend_clock\tstart_slr\tend_slr"
foreach path $failing_paths {
    set start_pin [get_property STARTPOINT_PIN $path]
    set end_pin [get_property ENDPOINT_PIN $path]
    set start_clock [get_property STARTPOINT_CLOCK $path]
    set end_clock [get_property ENDPOINT_CLOCK $path]
    set endpoint_pin_type [get_property -quiet REF_PIN_NAME $end_pin]
    set start_cell [get_cells -quiet -of_objects $start_pin]
    set end_cell [get_cells -quiet -of_objects $end_pin]
    set start_slr [get_property -quiet NAME [get_slrs -quiet -of_objects $start_cell]]
    set end_slr [get_property -quiet NAME [get_slrs -quiet -of_objects $end_cell]]
    puts $table [join [list \
        [get_property SLACK $path] \
        [get_property REQUIREMENT $path] \
        [get_property DATAPATH_DELAY $path] \
        [get_property LOGIC_LEVELS $path] \
        [get_property NAME $start_pin] \
        [get_property NAME $end_pin] \
        $endpoint_pin_type \
        [get_property NAME $start_clock] \
        [get_property NAME $end_clock] \
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
