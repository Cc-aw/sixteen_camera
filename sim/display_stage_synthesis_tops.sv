`timescale 1ns/1ps

// Explicit 256-bit AXI and 32-bit RGB565 stream widths are essential here.
// Synthesizing an interface-bearing module as the top would use axi4_if's
// 64-bit default, which incorrectly prunes three quarters of the data path.
module display_scaler_synth_top (
    input  wire clk, resetn,
    input  wire [47:0] input_data,
    input  wire input_valid, input_sof, input_eol, input_eof,
    input  wire input_error,
    input  wire [3:0] stream_id,
    input  wire [31:0] frame_id,
    output wire input_ready,
    input  wire output_ready,
    output wire [31:0] output_data,
    output wire output_valid, output_sof, output_eol, output_eof,
    output wire output_error,
    output wire [3:0] output_stream_id,
    output wire [31:0] output_frame_id
);
    video_stream_if #(.DATA_WIDTH(48), .STREAM_ID_WIDTH(4)) source();
    video_stream_if #(.DATA_WIDTH(32), .STREAM_ID_WIDTH(4)) scaled();
    assign source.aclk = clk;
    assign source.aresetn = resetn;
    assign source.data = input_data;
    assign source.valid = input_valid;
    assign source.sof = input_sof;
    assign source.eol = input_eol;
    assign source.eof = input_eof;
    assign source.error = input_error;
    assign source.stream_id = stream_id;
    assign source.frame_id = frame_id;
    assign input_ready = source.ready;
    assign scaled.ready = output_ready;
    assign output_data = scaled.data;
    assign output_valid = scaled.valid;
    assign output_sof = scaled.sof;
    assign output_eol = scaled.eol;
    assign output_eof = scaled.eof;
    assign output_error = scaled.error;
    assign output_stream_id = scaled.stream_id;
    assign output_frame_id = scaled.frame_id;
    display_scaler dut(.s_video(source), .m_video(scaled));
endmodule

module display_frame_dma_synth_top (
    input  wire clk, resetn,
    input  wire [31:0] video_data, frame_id,
    input  wire video_valid, video_sof, video_eol, video_eof, video_error,
    output wire video_ready,
    input  wire [31:0] buffer_base,
    input  wire buffer_grant, buffer_drop,
    output wire buffer_acquire, frame_done, frame_error,
    input  wire awready, wready, bvalid,
    input  wire [1:0] bresp,
    output wire awvalid, wvalid, wlast, bready,
    output wire [31:0] awaddr, wstrb,
    output wire [7:0] awlen,
    output wire [255:0] wdata
);
    video_stream_if #(.DATA_WIDTH(32)) video [1]();
    axi4_if #(.DATA_WIDTH(256), .ID_WIDTH(3)) axi();
    assign video[0].aclk = clk;
    assign video[0].aresetn = resetn;
    assign video[0].data = video_data;
    assign video[0].valid = video_valid;
    assign video[0].sof = video_sof;
    assign video[0].eol = video_eol;
    assign video[0].eof = video_eof;
    assign video[0].error = video_error;
    assign video[0].frame_id = frame_id;
    assign video[0].stream_id = 0;
    assign video_ready = video[0].ready;
    assign axi.awready = awready;
    assign axi.wready = wready;
    assign axi.bid = 0;
    assign axi.bresp = bresp;
    assign axi.bvalid = bvalid;
    assign axi.arready = 0;
    assign axi.rid = 0;
    assign axi.rdata = 0;
    assign axi.rresp = 0;
    assign axi.rlast = 0;
    assign axi.rvalid = 0;
    assign awvalid = axi.awvalid;
    assign awaddr = axi.awaddr;
    assign awlen = axi.awlen;
    assign wvalid = axi.wvalid;
    assign wdata = axi.wdata;
    assign wstrb = axi.wstrb;
    assign wlast = axi.wlast;
    assign bready = axi.bready;
    multi_channel_video_dma #(
        .CHANNELS(1), .FRAME_WIDTH(368), .FRAME_HEIGHT(270),
        .FRAME_STRIDE_BYTES(736), .PIXEL_BYTES(2), .FIFO_DEPTH(64)
    ) dut (
        .channels(video), .m_axi(axi),
        .buffer_acquire(buffer_acquire), .buffer_grant(buffer_grant),
        .buffer_drop(buffer_drop), .buffer_base(buffer_base),
        .frame_done(frame_done), .frame_error(frame_error),
        .channel_active(), .fifo_levels(), .active_frame_ids(),
        .perf_outstanding_current(), .perf_outstanding_max(),
        .perf_aw_stall_cycles(), .perf_w_stall_cycles(),
        .perf_b_stall_cycles(), .perf_bursts_issued(),
        .perf_bursts_completed(), .perf_response_errors()
    );
endmodule

module full_rgb565_synth_top (
    input  wire clk, resetn, buffer_grant,
    input  wire [31:0] buffer_base,
    output wire buffer_acquire, buffer_done,
    input  wire arready,
    output wire arvalid,
    output wire [31:0] araddr,
    output wire [7:0] arlen,
    input  wire [255:0] rdata,
    input  wire [1:0] rresp,
    input  wire rvalid, rlast,
    output wire rready,
    input  wire axis_ready,
    output wire [47:0] axis_data,
    output wire axis_valid, axis_user, axis_last,
    output wire axi_error, fifo_underflow
);
    axi4_if #(.DATA_WIDTH(256), .ID_WIDTH(3)) axi();
    axis_video_if #(.DATA_WIDTH(48)) axis();
    assign axi.awready = 0;
    assign axi.wready = 0;
    assign axi.bid = 0;
    assign axi.bresp = 0;
    assign axi.bvalid = 0;
    assign axi.arready = arready;
    assign axi.rid = 0;
    assign axi.rdata = rdata;
    assign axi.rresp = rresp;
    assign axi.rlast = rlast;
    assign axi.rvalid = rvalid;
    assign arvalid = axi.arvalid;
    assign araddr = axi.araddr;
    assign arlen = axi.arlen;
    assign rready = axi.rready;
    assign axis.tready = axis_ready;
    assign axis_data = axis.tdata;
    assign axis_valid = axis.tvalid;
    assign axis_user = axis.tuser;
    assign axis_last = axis.tlast;
    full_rgb565_reader dut (
        .clk(clk), .resetn(resetn),
        .buffer_acquire(buffer_acquire), .buffer_grant(buffer_grant),
        .buffer_base(buffer_base), .buffer_done(buffer_done),
        .m_axi(axi), .m_axis(axis), .axi_error(axi_error),
        .fifo_underflow(fifo_underflow), .debug_active_base(),
        .debug_status()
    );
endmodule

module mosaic_rgb565_synth_top (
    input  wire clk, resetn,
    input  wire buffer_grant,
    input  wire [511:0] buffer_bases,
    input  wire [15:0] buffer_valid_mask,
    output wire buffer_acquire, buffer_done,
    input  wire arready,
    output wire arvalid,
    output wire [31:0] araddr,
    output wire [7:0] arlen,
    input  wire [255:0] rdata,
    input  wire [1:0] rresp,
    input  wire rvalid, rlast,
    output wire rready,
    input  wire axis_ready,
    output wire [47:0] axis_data,
    output wire axis_valid, axis_user, axis_last,
    output wire axi_error, fifo_underflow
);
    axi4_if #(.DATA_WIDTH(256), .ID_WIDTH(3)) axi();
    axis_video_if #(.DATA_WIDTH(48)) axis();
    assign axi.awready = 0;
    assign axi.wready = 0;
    assign axi.bid = 0;
    assign axi.bresp = 0;
    assign axi.bvalid = 0;
    assign axi.arready = arready;
    assign axi.rid = 0;
    assign axi.rdata = rdata;
    assign axi.rresp = rresp;
    assign axi.rlast = rlast;
    assign axi.rvalid = rvalid;
    assign arvalid = axi.arvalid;
    assign araddr = axi.araddr;
    assign arlen = axi.arlen;
    assign rready = axi.rready;
    assign axis.tready = axis_ready;
    assign axis_data = axis.tdata;
    assign axis_valid = axis.tvalid;
    assign axis_user = axis.tuser;
    assign axis_last = axis.tlast;
    mosaic_rgb565_reader dut (
        .clk(clk), .resetn(resetn),
        .buffer_acquire(buffer_acquire), .buffer_grant(buffer_grant),
        .buffer_bases(buffer_bases), .buffer_valid_mask(buffer_valid_mask),
        .buffer_done(buffer_done), .m_axi(axi), .m_axis(axis),
        .axi_error(axi_error), .fifo_underflow(fifo_underflow),
        .debug_status()
    );
endmodule

module display_reader_compact_synth_top (
    input  wire clk, resetn,
    input  wire buffer_grant, buffer_mode,
    input  wire [31:0] buffer_base,
    input  wire [511:0] buffer_bases,
    input  wire [15:0] buffer_valid_mask,
    output wire buffer_acquire, buffer_done,
    input  wire arready,
    output wire arvalid,
    output wire [31:0] araddr,
    output wire [7:0] arlen,
    input  wire [255:0] rdata,
    input  wire [1:0] rresp,
    input  wire rvalid, rlast,
    output wire rready,
    input  wire axis_ready,
    output wire [47:0] axis_data,
    output wire axis_valid, axis_user, axis_last,
    output wire axi_error, fifo_underflow
);
    axi4_if #(.DATA_WIDTH(256), .ID_WIDTH(3)) axi();
    axis_video_if #(.DATA_WIDTH(48)) axis();
    assign axi.awready = 0;
    assign axi.wready = 0;
    assign axi.bid = 0;
    assign axi.bresp = 0;
    assign axi.bvalid = 0;
    assign axi.arready = arready;
    assign axi.rid = 0;
    assign axi.rdata = rdata;
    assign axi.rresp = rresp;
    assign axi.rlast = rlast;
    assign axi.rvalid = rvalid;
    assign arvalid = axi.arvalid;
    assign araddr = axi.araddr;
    assign arlen = axi.arlen;
    assign rready = axi.rready;
    assign axis.tready = axis_ready;
    assign axis_data = axis.tdata;
    assign axis_valid = axis.tvalid;
    assign axis_user = axis.tuser;
    assign axis_last = axis.tlast;
    display_reader_subsystem dut (
        .clk(clk), .resetn(resetn),
        .buffer_acquire(buffer_acquire), .buffer_grant(buffer_grant),
        .buffer_base(buffer_base), .buffer_bases(buffer_bases),
        .buffer_valid_mask(buffer_valid_mask),
        .buffer_mode(buffer_mode), .buffer_done(buffer_done),
        .frame_width(32'd368), .frame_height(32'd270),
        .frame_stride_bytes(32'd736), .overlay_commit(1'b0),
        .overlay_stream(4'd0), .overlay_count(4'd0),
        .overlay_boxes(512'd0), .overlay_labels(1024'd0),
        .m_axi(axi), .m_axis(axis),
        .axi_error(axi_error), .fifo_underflow(fifo_underflow),
        .debug_active_base(), .debug_status()
    );
endmodule
