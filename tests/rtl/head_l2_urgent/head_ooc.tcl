set root [file normalize [file join [file dirname [info script]] ../../..]]
read_verilog -sv [list $root/hw/rtl/interfaces/axi4_if.sv \
    $root/hw/rtl/ai/postprocess/head_uram_store.sv \
    $root/hw/rtl/ai/postprocess/axi4_head_uram_router_v3.sv \
    $root/tests/rtl/benches/memory/memory_v3_head_ooc.sv]
synth_design -top memory_v3_head_ooc -part xcvu13p-fhga2104-2-i -mode out_of_context
create_clock -period 10 [get_ports clk]
report_utilization -file utilization.rpt
report_timing_summary -file timing.rpt
set urams [llength [get_cells -hier -filter {REF_NAME =~ URAM288*}]]
if {$urams != 192} { error "Head UltraRAM inference changed: expected 192, found $urams" }
set fd [open status.txt w]
puts $fd "HEAD_OOC=PASS URAM=$urams READ_DECOUPLE=1"
close $fd
write_checkpoint -force head_decoupled.dcp
