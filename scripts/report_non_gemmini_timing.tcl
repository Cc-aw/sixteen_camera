set repo_dir [file dirname [file dirname [file normalize [info script]]]]
set checkpoint [file join $repo_dir prj sixteen_camera.runs impl_1 \
    top_wrapper_routed.dcp]
open_checkpoint $checkpoint

set output_path /tmp/non_gemmini_timing_paths.tsv
set output [open $output_path w]
puts $output "clock\tslack\tlogic_levels\tstartpoint\tendpoint"
foreach clock_name {camera_video_clk mmcm_clkout0} {
    set clock [get_clocks -quiet $clock_name]
    if {[llength $clock] == 0} {
        puts "MISSING_CLOCK=$clock_name"
        continue
    }
    set paths [get_timing_paths -from $clock -to $clock \
        -slack_lesser_than 0 -max_paths 200 -nworst 1]
    puts "TIMING_PATH_COUNT_${clock_name}=[llength $paths]"
    foreach path $paths {
        puts $output [join [list $clock_name \
            [get_property SLACK $path] \
            [get_property LOGIC_LEVELS $path] \
            [get_property STARTPOINT_PIN $path] \
            [get_property ENDPOINT_PIN $path]] "\t"]
    }
}
close $output
puts "NON_GEMMINI_TIMING_PATHS=$output_path"
close_design
