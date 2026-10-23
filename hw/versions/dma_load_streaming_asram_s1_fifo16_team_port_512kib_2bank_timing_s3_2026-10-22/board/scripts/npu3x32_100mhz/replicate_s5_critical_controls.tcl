# Physical duplication only: no pipeline, clock-period or timing exceptions.
# The remaining SoC paths need a 16-load rule: the final FMA stage has a
# 24-load FF; L2, Gemmini and FBus queue controls also remain slightly late.
# Use 32 loads on the 300 MHz UI, 64 elsewhere, and cap replication counts.
set s5_rep_seen [dict create]
set s5_rep_nets {}
proc s5_add_replication_net {pin threshold context} {
    global s5_rep_seen s5_rep_nets
    set driver [get_cells -quiet -of_objects $pin]
    if {[llength $driver] != 1} {return 0}
    set ref [get_property REF_NAME $driver]
    if {![string match FD* $ref] && ![string match LUT* $ref]} {return 0}
    foreach prop {IS_LOC_FIXED IS_BEL_FIXED ASYNC_REG DONT_TOUCH} {
        if {[get_property $prop $driver] in {1 true TRUE}} {return 0}
    }
    set net [get_nets -quiet -of_objects $pin]
    if {[llength $net] != 1 || [dict exists $s5_rep_seen $net]} {return 0}
    set loads [get_pins -quiet -leaf -of_objects $net -filter {DIRECTION == IN}]
    if {[llength $loads] < $threshold} {return 0}
    dict set s5_rep_seen $net 1
    lappend s5_rep_nets $net
    puts "TIMING_S5_REPLICATION_CANDIDATE $context ref=$ref loads=[llength $loads] net=$net"
    return 1
}
foreach {group quota limit} {
    clk_100m_p 40 12000
    mmcm_clkout0 16 6000
    camera_video_clk 4 3000
    **async_default** 4 2000
} {
    set count 0
    set bad [get_timing_paths -delay_type max -group $group -slack_lesser_than 0 -max_paths $limit -nworst 1]
    foreach path $bad {
        set start [get_pins -quiet [get_property STARTPOINT_PIN $path]]
        set driver [get_cells -quiet -of_objects $start]
        if {[llength $driver] != 1} {continue}
        set name [get_property NAME $driver]
        if {![regexp {(/coh_wrapper/l2/|/vector_unit/|/applyOrElse[^/]*/|/system/(fbus|sbus)/|/tile_prci_domain/buffer/|/u_memory_perf/|/u_ddr_platform/|/u_hdmi_rx/)} $name]} {continue}
        if {[string match */u_ddr_platform/u_ddr_bd/* $name] &&
            ![regexp {/(axi_interconnect_0|m00_full_regslice)/|/ddr4_0/inst/u_ddr_axi/|/ddr4_0/inst/u_ddr4_mem_intfc/u_ddr_ui/} $name]} {continue}
        if {![string match FD* [get_property REF_NAME $driver]]} {continue}
        set threshold [expr {$group eq "clk_100m_p" ? 16 : ($group eq "mmcm_clkout0" ? 32 : 64)}]
        set q [get_pins -quiet -of_objects $driver -filter {DIRECTION == OUT}]
        incr count [s5_add_replication_net $q $threshold "group=$group slack=[get_property SLACK $path]"]
        if {$count >= $quota} {break}
    }
}
# Inspect the FMA combinational cone of actual late endpoints, rather than
# selecting only the launching FF. The public all_fanin API works on 2023.2;
# timing_path objects in that release do not expose a TIMING_POINTS property.
# Restrict this extra pass to FMA LUTs and cap their duplication.
set fma_regs [get_cells -hier -quiet -filter {NAME =~ */vector_unit/vu/vxufp/* && REF_NAME =~ FD*}]
set s5_lut_count 0
if {[llength $fma_regs]} {
    if {[info exists timing_s5_replication_probe]} {
        set fma_paths [get_timing_paths -delay_type max -from $fma_regs -max_paths 20 -nworst 1]
    } else {
        set fma_paths [get_timing_paths -delay_type max -from $fma_regs -slack_lesser_than 0 -max_paths 2000 -nworst 1]
    }
    foreach path $fma_paths {
        set endpoint [get_pins -quiet [get_property ENDPOINT_PIN $path]]
        set cone [all_fanin -flat -only_cells -to $endpoint]
        set cone [filter $cone {REF_NAME =~ LUT* && NAME =~ */vector_unit/vu/vxufp/*/fma/*}]
        foreach cell $cone {
            set pin [get_pins -quiet -of_objects $cell -filter {DIRECTION == OUT}]
            incr s5_lut_count [s5_add_replication_net $pin 32 "group=RVV_internal slack=[get_property SLACK $path]"]
            if {$s5_lut_count >= 12} {break}
        }
        if {$s5_lut_count >= 12} {break}
    }
}
if {[llength $s5_rep_nets] && ![info exists timing_s5_replication_query_only]} {
    phys_opt_design -force_replication_on_nets [get_nets -quiet $s5_rep_nets]
}
puts "TIMING_S5_TARGETED_REPLICATION=PASS candidate_nets=[llength $s5_rep_nets] internal_RVV_LUT_nets=$s5_lut_count"
rename s5_add_replication_net {}
unset s5_rep_seen s5_rep_nets
