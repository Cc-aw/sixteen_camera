# Source after link/synthesis and clock definition, before implementation.
# Restrict exceptions to this mailbox. Do not cut whole clock domains.
set perf_prefix "u_ddr_memory/u_memory_perf/u_async/"
if {[info exists memory_perf_ooc] && $memory_perf_ooc} {set perf_prefix ""}
if {[info exists memory_perf_hierarchy]} {set perf_prefix $memory_perf_hierarchy}
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
    # lappend produces strings. Re-resolve them to typed design objects before
    # using -of_objects; otherwise Vivado silently fails to find the pins.
    set $group [get_cells -quiet [set $group]]
}
set perf_sync_pins [get_pins -of_objects $perf_sync -filter {REF_PIN_NAME == D}]
set perf_reset_pins [get_pins -of_objects $perf_resets -filter {REF_PIN_NAME == CLR || REF_PIN_NAME == PRE}]
if {![llength $perf_sync_pins] || ![llength $perf_reset_pins]} {
    error "Memory V3 CDC: empty synchronizer/reset pin collection"
}
set_false_path -to $perf_sync_pins
set_false_path -to $perf_reset_pins
if {![info exists memory_perf_ooc] || !$memory_perf_ooc} {
    set local_reset_pattern u_ddr_memory/u_memory_perf/local_reset_sync_reg*
    if {[info exists memory_perf_local_reset_pattern]} {set local_reset_pattern $memory_perf_local_reset_pattern}
    set local_reset_cells [get_cells -hier -quiet -filter "NAME =~ $local_reset_pattern"]
    # The baseline checkpoint has no local synchronizer. Newly synthesized
    # projects must have it; baseline diagnosis may explicitly allow absence.
    if {![llength $local_reset_cells] && ![info exists memory_perf_baseline]} {
        error "Memory V3 CDC: local SoC reset synchronizer is missing"
    }
    if {[llength $local_reset_cells]} {
        set local_reset_pins [get_pins -of_objects $local_reset_cells -filter {REF_PIN_NAME == CLR || REF_PIN_NAME == PRE}]
        if {![llength $local_reset_pins]} {error "Memory V3 CDC: local reset has no asynchronous assertion pins"}
        set_false_path -to $local_reset_pins
    }
}
# The command is launched with the request, held through the returned ack,
# and consumed only after two request synchronizers plus a staging cycle.
set perf_cmd_from [all_fanin -flat -startpoints_only -to [get_pins -of_objects $perf_cmd -filter {REF_PIN_NAME == D}]]
set_max_delay -datapath_only 3 -from $perf_cmd_from -to $perf_cmd
# Source snapshots settle before the delayed source ack and its destination
# synchronizers. Keep a finite payload budget, including physical bus skew.
set_max_delay -datapath_only 10 -from $perf_src -to $perf_dst
# Each bank is an independent, stable 2048-bit mailbox payload. Split the skew
# checks by bank to stay below the router's 5120-element implementation limit.
set perf_source_banks [dict create]
set perf_destination_banks [dict create]
foreach cell $perf_src {
    set relative [string range [get_property NAME $cell] [string length $perf_prefix] end]
    if {![regexp {^g_bank\[([0-9]+)\]\.u_counter/} $relative -> bank]} {
        error "Memory V3 CDC: unrecognized snapshot source $relative"
    }
    dict lappend perf_source_banks $bank $cell
}
foreach cell $perf_dst {
    set relative [string range [get_property NAME $cell] [string length $perf_prefix] end]
    if {![regexp {^snapshots_reg\[([0-9]+)\]} $relative -> bit]} {
        error "Memory V3 CDC: unrecognized snapshot destination $relative"
    }
    dict lappend perf_destination_banks [expr {$bit / 2048}] $cell
}
foreach bank [dict keys $perf_source_banks] {
    if {![dict exists $perf_destination_banks $bank]} {error "Memory V3 CDC: missing destination bank $bank"}
    set bank_src [get_cells -quiet [dict get $perf_source_banks $bank]]
    set bank_dst [get_cells -quiet [dict get $perf_destination_banks $bank]]
    set_bus_skew 10 -from $bank_src -to $bank_dst
    puts "MEMORY_V3_CDC_BANK=$bank source=[llength $bank_src] destination=[llength $bank_dst]"
}
puts "MEMORY_V3_CDC_CONSTRAINTS=PASS prefix=$perf_prefix sync=[llength $perf_sync] frozen=[llength $perf_src] destination=[llength $perf_dst] command=[llength $perf_cmd]"
