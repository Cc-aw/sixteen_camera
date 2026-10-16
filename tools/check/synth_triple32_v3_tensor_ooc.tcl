# Local synthesis only; this entry never launches an entire SoC or implementation.
set repo [file dirname [file dirname [file dirname [file normalize [info script]]]]]
set kind [lindex $argv 0]
set out [file normalize [lindex $argv 1]]
set filelist [file normalize [lindex $argv 2]]
file mkdir $out
cd $out
if {![string match "2023.2*" [version -short]]} {error "Vivado 2023.2 required"}
set_param general.maxThreads 4
set fd [open $filelist r]
foreach path [split [string trim [read $fd]] "\n"] {
    read_verilog -sv $path
}
close $fd
set tops [dict create tensor TaihangTensorIngress l2 InclusiveCache sbus SystemBus mbus MemoryBus coherence CoherenceManagerWrapper head memory_v3_head_ooc counters memory_perf_async_group pool-store StoreController pool-dma StreamWriter]
if {![dict exists $tops $kind]} {error "Unknown local synthesis target $kind"}
synth_design -top [dict get $tops $kind] -part xcvu13p-fhga2104-2-i -mode out_of_context \
    -flatten_hierarchy rebuilt -directive PerformanceOptimized -retiming -resource_sharing off -shreg_min_size 5
set blackboxes [get_cells -hier -quiet -filter {IS_BLACKBOX == 1}]
if {[llength $blackboxes]} {error "Unresolved cells in local synthesis: $blackboxes"}
if {$kind eq "counters"} {
    create_clock -name source_clock -period 3.333 [get_ports src_clk]
    create_clock -name destination_clock -period 10 [get_ports dst_clk]
    set memory_perf_ooc 1
    source [file join $repo hw constraints memory_parallel_v3_cdc.tcl]
    report_cdc -file [file join $out cdc.rpt]
} else {
    if {$kind eq "head"} {
        set clock_ports [get_ports clk]
        set urams [llength [get_cells -hier -filter {REF_NAME =~ URAM288*}]]
        if {$urams != 192} {error "Expected 192 Head URAM primitives, found $urams"}
    } elseif {$kind in {sbus mbus coherence}} {
        set clock_ports [get_ports -filter {DIRECTION == IN && NAME =~ *_clock}]
    } else {
        set clock_ports [get_ports clock]
    }
    if {[llength $clock_ports] == 0} {error "No local 100MHz clock found"}
    # SBUS exposes several synchronous domain aliases of the same SoC clock.
    create_clock -name soc_clock -period 10 $clock_ports
}
report_utilization -file [file join $out utilization.rpt]
report_timing_summary -delay_type min_max -max_paths 10 -file [file join $out timing.rpt]
report_drc -file [file join $out drc.rpt]
check_timing -verbose -file [file join $out check_timing.rpt]
write_checkpoint -force [file join $out synthesized.dcp]
set paths [get_timing_paths -delay_type max -max_paths 1]
if {[llength $paths] != 1} {error "No internal setup path available"}
set wns [get_property SLACK $paths]
set fd [open [file join $out result.txt] w]
puts $fd "SYNTHESIS=PASS"
puts $fd "TARGET=$kind"
puts $fd "WNS_NS=$wns"
puts $fd "TIMING_MET=[expr {$wns >= 0}]"
puts $fd "SCOPE=out_of_context_synthesis_only"
close $fd
puts "V3_TENSOR_OOC_SYNTHESIS=PASS target=$kind WNS_NS=$wns"
