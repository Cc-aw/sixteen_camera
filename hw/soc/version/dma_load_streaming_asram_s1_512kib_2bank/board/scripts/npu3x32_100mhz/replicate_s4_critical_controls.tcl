# Run on the placed fresh S4 netlist, immediately before normal physical
# optimization. Duplicate only actual failing, high-fanout FF output nets.
# This preserves latency, protocol and all functional timing checks.
set s4_seen [dict create]
set s4_nets {}
foreach {s4_group s4_quota s4_sample_limit} {
    clk_100m_p 40 12000
    mmcm_clkout0 16 6000
    camera_video_clk 4 3000
    **async_default** 4 2000
} {
  set s4_group_count 0
  set s4_bad [get_timing_paths -delay_type max -group $s4_group \
      -slack_lesser_than 0 -max_paths $s4_sample_limit -nworst 1]
  foreach path $s4_bad {
    set start_name [get_property STARTPOINT_PIN $path]
    if {[dict exists $s4_seen "start:$start_name"]} {continue}
    dict set s4_seen "start:$start_name" 1
    set start_pin [get_pins -quiet $start_name]
    set driver [get_cells -quiet -of_objects $start_pin]
    if {[llength $driver] != 1} {continue}
    set name [get_property NAME $driver]
    if {![regexp {(/coh_wrapper/l2/|/vector_unit/|/applyOrElse[^/]*/|/u_memory_perf/|/u_ddr_platform/|/u_hdmi_rx/)} $name]} {continue}
    # Keep the DDR PHY/calibration implementation intact. Its ordinary AXI
    # interconnect/register-slice logic can still use physical replication.
    if {[string match */u_ddr_platform/u_ddr_bd/* $name] &&
        ![regexp {/(axi_interconnect_0|m00_full_regslice)/} $name]} {continue}
    if {![string match FD* [get_property REF_NAME $driver]]} {continue}
    if {[get_property IS_LOC_FIXED $driver] in {1 true TRUE} ||
        [get_property IS_BEL_FIXED $driver] in {1 true TRUE}} {continue}
    if {[get_property ASYNC_REG $driver] in {1 true TRUE} ||
        [get_property DONT_TOUCH $driver] in {1 true TRUE}} {continue}
    set q [get_pins -quiet -of_objects $driver -filter {DIRECTION == OUT}]
    set net [get_nets -quiet -of_objects $q]
    if {[llength $net] != 1 || [dict exists $s4_seen $net]} {continue}
    dict set s4_seen $net 1
    set loads [get_pins -quiet -leaf -of_objects $net -filter {DIRECTION == IN}]
    if {[llength $loads] < 64} {continue}
    lappend s4_nets $net
    puts "TIMING_S4_REPLICATION_CANDIDATE group=$s4_group slack=[get_property SLACK $path] loads=[llength $loads] net=$net"
    incr s4_group_count
    if {$s4_group_count == $s4_quota} {break}
  }
}
if {[llength $s4_nets] && ![info exists timing_s4_replication_query_only]} {
    phys_opt_design -force_replication_on_nets [get_nets -quiet $s4_nets]
}
puts "TIMING_S4_TARGETED_REPLICATION=PASS candidate_nets=[llength $s4_nets]"
unset s4_bad s4_seen s4_nets

