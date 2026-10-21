# Read-only inspection: never place/route/write a checkpoint or bitstream.
if {$argc != 2} {error "Usage: inspect_routed.tcl <routed.dcp> <new-report-directory>"}
set checkpoint [file normalize [lindex $argv 0]]
set out [file normalize [lindex $argv 1]]
if {[file exists $out]} {error "Use a new inspection report directory"}
file mkdir $out
open_checkpoint $checkpoint
report_utilization -file [file join $out utilization.rpt]
report_route_status -file [file join $out route.rpt]
report_timing_summary -delay_type min_max -report_unconstrained -file [file join $out timing.rpt]

# Build placement lookup tables in bulk, rather than invoking get_slrs once
# for every cell in this million-cell design.
set site_slr [dict create]
set site_region [dict create]
foreach cr [get_clock_regions] {
    set slr [get_slrs -of_objects $cr]
    foreach site [get_sites -of_objects $cr -filter {SITE_TYPE =~ SLIC* || SITE_TYPE =~ RAMB* || SITE_TYPE =~ URAM* || SITE_TYPE =~ DSP*}] {
        dict set site_slr $site $slr
        dict set site_region $site $cr
    }
}
set groups [dict create]
set anchors [dict create]
foreach {group pattern} {
    l2_bank0 */coh_wrapper/l2/inclusive_cache_bank_sched/*
    l2_bank1 */coh_wrapper/l2/inclusive_cache_bank_sched_1/*
    head */u_head_uram_router/*
    ddr_upsizer */ddr4_0/inst/u_ddr_axi/*
    ddr_m00 */design_1_i/m00_full_regslice/*
    ddr_xbar */axi_interconnect_0/xbar/*
    gemmini0 */applyOrElse/*
    gemmini1 */applyOrElse_1/*
    gemmini2 */applyOrElse_2/*
} {
    set cells [get_cells -hier -quiet -filter "IS_PRIMITIVE && NAME =~ $pattern"]
    set locations [get_property LOC $cells]
    set refs [get_property REF_NAME $cells]
    foreach cell $cells loc $locations ref $refs {
        if {![dict exists $site_slr $loc]} {continue}
        set slr [dict get $site_slr $loc]
        set region [dict get $site_region $loc]
        dict incr groups $group,$slr,$ref
        if {$group in {ddr_upsizer ddr_m00 ddr_xbar head l2_bank0 l2_bank1}} {
            dict incr anchors $group,$region
        }
    }
}
set f [open [file join $out placement_counts.tsv] w]
puts $f "group\tslr\tprimitive\tcount"
foreach key [lsort [dict keys $groups]] {puts $f "[join [split $key ,] \t]\t[dict get $groups $key]"}
close $f
set f [open [file join $out region_counts.tsv] w]
puts $f "group\tclock_region\tcount"
foreach key [lsort [dict keys $anchors]] {puts $f "[join [split $key ,] \t]\t[dict get $anchors $key]"}
close $f

set f [open [file join $out critical_paths.tsv] w]
puts $f "clock\tslack_ns\tstart\tstart_loc\tstart_region\tend\tend_loc\tend_region\tlogic_levels\tdatapath_delay_ns"
foreach name {clk_100m_p mmcm_clkout0 camera_video_clk} {
    set clk [get_clocks -quiet $name]
    if {[llength $clk] != 1} {error "Missing baseline clock $name"}
    set paths [get_timing_paths -from $clk -to $clk -delay_type max -max_paths 100 -nworst 1]
    report_timing -of_objects $paths -file [file join $out ${name}_worst100.rpt]
    foreach path $paths {
        set start [get_property STARTPOINT_PIN $path]
        set end [get_property ENDPOINT_PIN $path]
        set sc [get_cells -of_objects [get_pins $start]]
        set ec [get_cells -of_objects [get_pins $end]]
        set sloc [get_property LOC $sc]; set eloc [get_property LOC $ec]
        set sr {}; set er {}
        if {[dict exists $site_region $sloc]} {set sr [dict get $site_region $sloc]}
        if {[dict exists $site_region $eloc]} {set er [dict get $site_region $eloc]}
        puts $f [join [list $name [get_property SLACK $path] $start $sloc $sr $end $eloc $er \
            [get_property LOGIC_LEVELS $path] [get_property DATAPATH_DELAY $path]] \t]
    }
}
close $f
set f [open [file join $out pblocks.tsv] w]
puts $f "name\tsoft\tcontain_routing\tgrid_ranges"
foreach pb [get_pblocks] {
    puts $f [join [list $pb [get_property IS_SOFT $pb] [get_property CONTAIN_ROUTING $pb] [get_property GRID_RANGES $pb]] \t]
}
close $f
puts "ASRAM_BASELINE_ROUTED_INSPECTION=PASS checkpoint=$checkpoint mutation=none"
close_design
