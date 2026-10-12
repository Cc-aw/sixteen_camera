# Source after link/synthesis and clock definition, before implementation.
# Restrict exceptions to this mailbox. Do not cut whole clock domains.
set perf_prefix "u_ddr_memory/u_memory_perf/u_async/"
if {[info exists memory_perf_ooc] && $memory_perf_ooc} {set perf_prefix ""}
set perf_cells [get_cells -hier -quiet -filter "NAME =~ ${perf_prefix}*"]
set perf_sync {}; set perf_resets {}; set perf_src {}; set perf_dst {}; set perf_cmd {}
foreach cell $perf_cells {
    set relative [string range [get_property NAME $cell] [string length $perf_prefix] end]
    if {[regexp {^(req_sync|ack_sync|up_sync)_reg\[0\]$} $relative]} {lappend perf_sync $cell}
    if {[regexp {^(src_reset|dst_reset)_reg\[.*\]$} $relative]} {lappend perf_resets $cell}
    if {[regexp {^g_bank.*u_counter/.*frozen_reg.*} $relative]} {lappend perf_src $cell}
    if {[regexp {^snapshots_reg.*} $relative]} {lappend perf_dst $cell}
    if {[regexp {^g_bank.*u_counter/command_q_reg.*} $relative]} {lappend perf_cmd $cell}
}
foreach group {perf_sync perf_resets perf_src perf_dst perf_cmd} {
    if {![llength [set $group]]} {error "Memory V3 CDC: no cells for $group in $perf_prefix"}
}
set_false_path -to [get_pins -of_objects $perf_sync -filter {REF_PIN_NAME == D}]
set_false_path -to [get_pins -of_objects $perf_resets -filter {REF_PIN_NAME == CLR || REF_PIN_NAME == PRE}]
# The command is launched with the request, held through the returned ack,
# and consumed only after two request synchronizers plus a staging cycle.
set perf_cmd_from [all_fanin -flat -startpoints_only -to [get_pins -of_objects $perf_cmd -filter {REF_PIN_NAME == D}]]
set_max_delay -datapath_only 3 -from $perf_cmd_from -to $perf_cmd
# Source snapshots settle before the delayed source ack and its destination
# synchronizers. Keep a finite payload budget, including physical bus skew.
set_max_delay -datapath_only 10 -from $perf_src -to $perf_dst
set_bus_skew 10 -from $perf_src -to $perf_dst
puts "MEMORY_V3_CDC_CONSTRAINTS=PASS prefix=$perf_prefix sync=[llength $perf_sync] frozen=[llength $perf_src] destination=[llength $perf_dst] command=[llength $perf_cmd]"
