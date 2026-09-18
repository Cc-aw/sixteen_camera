set repo_dir [file dirname [file dirname [file normalize [info script]]]]
read_verilog -sv [file join $repo_dir rtl interfaces axi4_if.sv]
read_verilog -sv [file join $repo_dir rtl ai preprocess yolov5nu_tensor_stream_packer.sv]
read_verilog -sv [file join $repo_dir rtl ai preprocess yolov5nu_multi_channel_tensor_dma.sv]
synth_design -top yolov5nu_multi_channel_tensor_dma \
    -part xcvu13p-fhga2104-2-i -flatten_hierarchy rebuilt
create_clock -name tensor_dma_clk -period 6.667 [get_ports clk]
set timing_path [get_timing_paths -delay_type max -max_paths 1]
set tensor_dma_wns [get_property SLACK $timing_path]
report_timing_summary -file /tmp/yolov5nu_multi_channel_tensor_dma_timing.rpt
report_utilization -file /tmp/yolov5nu_multi_channel_tensor_dma_utilization.rpt
puts "TENSOR_DMA_SYNTH_WNS=$tensor_dma_wns"
puts "TENSOR_DMA_SYNTHESIS=PASS"
