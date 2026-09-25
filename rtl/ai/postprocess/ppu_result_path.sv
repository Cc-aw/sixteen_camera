`timescale 1ns/1ps
module ppu_result_path(
 input wire clk,resetn,completion_valid,output wire completion_ready,
 input wire [363:0] descriptor,input wire [5:0] result_count,input wire [31:0] cycles,input wire error,
 output wire [4:0] result_index,input wire [127:0] result_word,
 input wire write_valid,input wire [9:0] write_addr,read_addr,input wire [31:0] write_data,input wire [3:0] write_strb,
 output wire read_hit,output wire [31:0] read_data,
 input wire admission_valid,input wire [3:0] configured_stream,input wire [63:0] configured_frame,input wire [31:0] configured_version,
 output wire overlay_valid,input wire overlay_ready,output wire [3:0] overlay_stream,overlay_count,
 output wire [511:0] overlay_boxes,output wire [1023:0] overlay_labels
);
 wire capture_valid,capture_ready,fifo_valid,fifo_ready,observe_valid,observe_ready;
 wire [1567:0] capture_record,fifo_record,observe_record,cpu_record;
 wire [2:0] fifo_count,cpu_count;wire cpu_valid,cpu_pop,observe_enable,expect_valid;
 wire [31:0] published,stale;
 ppu_result_capture capture(.clk(clk),.resetn(resetn),.completion_valid(completion_valid),.completion_ready(completion_ready),
 .descriptor(descriptor),.result_count(result_count),.cycles(cycles),.error(error),.result_index(result_index),.result_word(result_word),
 .valid(capture_valid),.ready(capture_ready),.record(capture_record));
 ppu_result_fifo results(.clk(clk),.resetn(resetn),.in_valid(capture_valid),.in_ready(capture_ready),.in_data(capture_record),
 .out_valid(fifo_valid),.out_ready(fifo_ready),.out_data(fifo_record),.count(fifo_count));
 ppu_result_manager manager(.clk(clk),.resetn(resetn),.expect_valid(expect_valid||admission_valid),
 .expect_stream(configured_stream),.expect_frame(configured_frame),.expect_version(configured_version),
 .in_valid(fifo_valid),.in_ready(fifo_ready),.in_record(fifo_record),
 .observation_valid(observe_valid),.observation_ready(observe_ready),.observation_record(observe_record),
 .overlay_valid(overlay_valid),.overlay_ready(overlay_ready),.overlay_stream(overlay_stream),.overlay_count(overlay_count),
 .overlay_boxes(overlay_boxes),.overlay_labels(overlay_labels),.published(published),.stale(stale));
 wire cpu_in_ready;
 assign observe_ready=!observe_enable||cpu_in_ready;
 ppu_result_fifo observations(.clk(clk),.resetn(resetn),.in_valid(observe_valid&&observe_enable),.in_ready(cpu_in_ready),.in_data(observe_record),
 .out_valid(cpu_valid),.out_ready(cpu_pop),.out_data(cpu_record),.count(cpu_count));
 ppu_result_csr csr(.clk(clk),.resetn(resetn),.write_valid(write_valid),.write_addr(write_addr),.read_addr(read_addr),
 .write_data(write_data),.write_strb(write_strb),.observation_valid(cpu_valid),.observation_record(cpu_record),.observation_pop(cpu_pop),
 .result_count(fifo_count),.observation_count(cpu_count),.published(published),.stale(stale),
 .expect_valid(expect_valid),.observation_enable(observe_enable),.read_hit(read_hit),.read_data(read_data));
endmodule
