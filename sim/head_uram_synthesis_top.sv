`timescale 1ns/1ps

// Production-parameter synthesis harness used to verify UltraRAM inference.
module head_uram_synthesis_top (
    input  wire          clk,
    input  wire          resetn,
    input  wire          write_valid,
    output wire          write_ready,
    input  wire [19:0]   write_addr,
    input  wire [255:0]  write_data,
    input  wire [31:0]   write_strb,
    input  wire          start,
    input  wire [32:0]   base_addr,
    input  wire [31:0]   byte_count,
    output wire          busy,
    output wire          done,
    output wire          error,
    output wire [255:0]  stream_data,
    output wire [31:0]   stream_keep,
    output wire          stream_valid,
    input  wire          stream_ready,
    output wire          stream_last
);
    wire memory_req_valid, memory_req_ready;
    wire [14:0] memory_req_word_addr;
    wire [255:0] memory_rsp_data;
    wire memory_rsp_valid, memory_rsp_ready;

    head_uram_store store (
        .clk(clk), .resetn(resetn), .write_valid(write_valid),
        .write_ready(write_ready), .write_addr(write_addr),
        .write_data(write_data), .write_strb(write_strb),
        .read_req_valid(memory_req_valid),
        .read_req_ready(memory_req_ready),
        .read_req_word_addr(memory_req_word_addr),
        .read_rsp_data(memory_rsp_data), .read_rsp_valid(memory_rsp_valid),
        .read_rsp_ready(memory_rsp_ready)
    );

    head_local_reader reader (
        .clk(clk), .resetn(resetn), .start(start), .base_addr(base_addr),
        .byte_count(byte_count), .busy(busy), .done(done), .error(error),
        .error_flags(), .bytes_read(),
        .memory_req_valid(memory_req_valid),
        .memory_req_ready(memory_req_ready),
        .memory_req_word_addr(memory_req_word_addr),
        .memory_rsp_data(memory_rsp_data),
        .memory_rsp_valid(memory_rsp_valid),
        .memory_rsp_ready(memory_rsp_ready), .stream_data(stream_data),
        .stream_keep(stream_keep), .stream_valid(stream_valid),
        .stream_ready(stream_ready), .stream_last(stream_last)
    );
endmodule
