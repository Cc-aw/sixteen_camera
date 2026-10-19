set v3 [file dirname [file dirname [file normalize [info script]]]]
set root [file dirname [file dirname $v3]]
set kind [lindex $argv 0]
set out [file normalize [lindex $argv 1]]
file mkdir $out
# Separate scratch paths even when isolated tool processes reuse a PID.
cd $out
set_param general.maxThreads 8
if {$kind eq "head"} {
    read_verilog -sv [file join $v3 overlay rtl interfaces axi4_if.sv]
    read_verilog -sv [file join $root rtl ai postprocess head_uram_store.sv]
    read_verilog -sv [file join $v3 overlay rtl ai postprocess axi4_head_uram_router.sv]
    read_verilog -sv [file join $v3 tests memory_v3_head_ooc.sv]
    synth_design -top memory_v3_head_ooc -part xcvu13p-fhga2104-2-i -mode out_of_context -flatten_hierarchy rebuilt
    create_clock -name soc_clock -period 10 [get_ports clk]
    set urams [llength [get_cells -hier -filter {REF_NAME =~ URAM288*}]]
    if {$urams != 192} {error "Head URAM inference failed: $urams, expected 192"}
} elseif {$kind eq "counters"} {
    read_verilog -sv [file join $v3 overlay rtl memory memory_perf_counters.sv]
    synth_design -top memory_perf_async_group -part xcvu13p-fhga2104-2-i -mode out_of_context -flatten_hierarchy rebuilt
    create_clock -name source_clock -period 3.333 [get_ports src_clk]
    create_clock -name destination_clock -period 10 [get_ports dst_clk]
    # Only first-stage synchronizer D pins are false paths. Bundled payload
    # has a finite settling budget; do not false-path all inter-domain data.
    set memory_perf_ooc 1
    source [file join $v3 overlay xdc memory_parallel_v3_cdc.tcl]
    report_cdc -file [file join $out cdc.rpt]
} elseif {$kind eq "l2"} {
    set rtl [file normalize [lindex $argv 2]]
    read_verilog -sv [glob -directory $rtl *.sv *.v]
    synth_design -top InclusiveCache -part xcvu13p-fhga2104-2-i -mode out_of_context -flatten_hierarchy rebuilt
    create_clock -name soc_clock -period 10 [get_ports clock]
} elseif {$kind eq "sbus" || $kind eq "mbus"} {
    set rtl [file normalize [lindex $argv 2]]
    read_verilog -sv [glob -directory $rtl *.sv *.v]
    set top [expr {$kind eq "sbus" ? "SystemBus" : "MemoryBus"}]
    synth_design -top $top -part xcvu13p-fhga2104-2-i -mode out_of_context -flatten_hierarchy rebuilt
    set clocks [get_ports -filter {DIRECTION == IN && NAME =~ *_clock}]
    create_clock -name soc_clock -period 10 $clocks
    set_input_delay -clock soc_clock 2 [get_ports -filter {DIRECTION == IN && NAME !~ *_clock}]
    set_output_delay -clock soc_clock 2 [get_ports -filter {DIRECTION == OUT && NAME !~ *_clock}]
} else {error "Unknown OOC target"}
report_utilization -file [file join $out utilization.rpt]
report_timing_summary -delay_type min_max -max_paths 10 -file [file join $out timing.rpt]
check_timing -verbose -file [file join $out check_timing.rpt]
write_checkpoint [file join $out synthesized.dcp]
set worst [lindex [get_timing_paths -delay_type max -max_paths 1] 0]
if {$worst eq ""} {error "No setup paths"}
set slack [get_property SLACK $worst]
set fd [open [file join $out result.txt] w]
puts $fd "target=$kind WNS=$slack"
close $fd
if {$slack < 0} {error "V3 $kind OOC timing failed: $slack"}
puts "MEMORY_V3_OOC_PASS target=$kind WNS=$slack"
