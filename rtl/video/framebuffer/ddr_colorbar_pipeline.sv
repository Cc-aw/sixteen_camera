`timescale 1ns/1ps

module ddr_colorbar_pipeline #(
    parameter [31:0] FRAME_BASE_ADDR = 32'h0800_0000,
    parameter integer FRAME_WIDTH = 1920,
    parameter integer FRAME_HEIGHT = 1080,
    parameter integer FRAME_STRIDE_BYTES = FRAME_WIDTH * 4,
    parameter integer BURST_MAX_BEATS = 64,
    parameter integer READER_FIFO_DEPTH = 1024
) (
    input  wire init_done,
    input  wire ddr_ui_clk,
    input  wire ddr_resetn,
    axi4_if.master writer_axi,
    axi4_if.master reader_axi,
    axis_video_if.source video_axis,
    output wire frame_ready,
    output wire writer_busy,
    output wire writer_error,
    output wire reader_error,
    output wire reader_underflow
);
    wire [15:0] writer_line;
    wire [15:0] writer_beat;
    wire [15:0] reader_fifo_count;

    assign writer_axi.aclk = ddr_ui_clk;
    assign writer_axi.aresetn = ddr_resetn;
    assign reader_axi.aclk = ddr_ui_clk;
    assign reader_axi.aresetn = ddr_resetn;
    assign video_axis.aclk = ddr_ui_clk;
    assign video_axis.aresetn = ddr_resetn;

    ddr_colorbar_writer #(
        .FRAME_BASE_ADDR(FRAME_BASE_ADDR),
        .FRAME_WIDTH(FRAME_WIDTH),
        .FRAME_HEIGHT(FRAME_HEIGHT),
        .FRAME_STRIDE_BYTES(FRAME_STRIDE_BYTES),
        .BURST_MAX_BEATS(BURST_MAX_BEATS)
    ) u_writer (
        .clk(ddr_ui_clk),
        .resetn(ddr_resetn),
        .init_done(init_done),
        .m_axi_awid(writer_axi.awid),
        .m_axi_awaddr(writer_axi.awaddr),
        .m_axi_awlen(writer_axi.awlen),
        .m_axi_awsize(writer_axi.awsize),
        .m_axi_awburst(writer_axi.awburst),
        .m_axi_awlock(writer_axi.awlock),
        .m_axi_awcache(writer_axi.awcache),
        .m_axi_awprot(writer_axi.awprot),
        .m_axi_awqos(writer_axi.awqos),
        .m_axi_awvalid(writer_axi.awvalid),
        .m_axi_awready(writer_axi.awready),
        .m_axi_wdata(writer_axi.wdata),
        .m_axi_wstrb(writer_axi.wstrb),
        .m_axi_wlast(writer_axi.wlast),
        .m_axi_wvalid(writer_axi.wvalid),
        .m_axi_wready(writer_axi.wready),
        .m_axi_bid(writer_axi.bid),
        .m_axi_bresp(writer_axi.bresp),
        .m_axi_bvalid(writer_axi.bvalid),
        .m_axi_bready(writer_axi.bready),
        .frame_ready(frame_ready),
        .busy(writer_busy),
        .axi_error(writer_error),
        .debug_line(writer_line),
        .debug_beat(writer_beat)
    );

    // S01 is write-only in this stage.
    assign writer_axi.arid = 3'd0;
    assign writer_axi.araddr = 32'd0;
    assign writer_axi.arlen = 8'd0;
    assign writer_axi.arsize = 3'b101;
    assign writer_axi.arburst = 2'b01;
    assign writer_axi.arlock = 1'b0;
    assign writer_axi.arcache = 4'd0;
    assign writer_axi.arprot = 3'd0;
    assign writer_axi.arqos = 4'd0;
    assign writer_axi.arvalid = 1'b0;
    assign writer_axi.rready = 1'b0;

    ddr_axis_frame_reader #(
        .FRAME_BASE_ADDR(FRAME_BASE_ADDR),
        .FRAME_WIDTH(FRAME_WIDTH),
        .FRAME_HEIGHT(FRAME_HEIGHT),
        .FRAME_STRIDE_BYTES(FRAME_STRIDE_BYTES),
        .BURST_MAX_BEATS(BURST_MAX_BEATS),
        .FIFO_DEPTH(READER_FIFO_DEPTH)
    ) u_reader (
        .clk(ddr_ui_clk),
        .resetn(ddr_resetn),
        .enable(frame_ready),
        .m_axi_arid(reader_axi.arid),
        .m_axi_araddr(reader_axi.araddr),
        .m_axi_arlen(reader_axi.arlen),
        .m_axi_arsize(reader_axi.arsize),
        .m_axi_arburst(reader_axi.arburst),
        .m_axi_arlock(reader_axi.arlock),
        .m_axi_arcache(reader_axi.arcache),
        .m_axi_arprot(reader_axi.arprot),
        .m_axi_arqos(reader_axi.arqos),
        .m_axi_arvalid(reader_axi.arvalid),
        .m_axi_arready(reader_axi.arready),
        .m_axi_rid(reader_axi.rid),
        .m_axi_rdata(reader_axi.rdata),
        .m_axi_rresp(reader_axi.rresp),
        .m_axi_rlast(reader_axi.rlast),
        .m_axi_rvalid(reader_axi.rvalid),
        .m_axi_rready(reader_axi.rready),
        .m_axis_tdata(video_axis.tdata),
        .m_axis_tvalid(video_axis.tvalid),
        .m_axis_tready(video_axis.tready),
        .m_axis_tuser(video_axis.tuser),
        .m_axis_tlast(video_axis.tlast),
        .axi_error(reader_error),
        .fifo_underflow(reader_underflow),
        .debug_fifo_count(reader_fifo_count)
    );

    // S02 is read-only in this stage.
    assign reader_axi.awid = 3'd0;
    assign reader_axi.awaddr = 32'd0;
    assign reader_axi.awlen = 8'd0;
    assign reader_axi.awsize = 3'b101;
    assign reader_axi.awburst = 2'b01;
    assign reader_axi.awlock = 1'b0;
    assign reader_axi.awcache = 4'd0;
    assign reader_axi.awprot = 3'd0;
    assign reader_axi.awqos = 4'd0;
    assign reader_axi.awvalid = 1'b0;
    assign reader_axi.wdata = 256'd0;
    assign reader_axi.wstrb = 32'd0;
    assign reader_axi.wlast = 1'b0;
    assign reader_axi.wvalid = 1'b0;
    assign reader_axi.bready = 1'b0;

    wire unused = &{1'b0, writer_axi.rid, writer_axi.rdata,
                    writer_axi.rresp, writer_axi.rlast, writer_axi.rvalid,
                    reader_axi.bid, reader_axi.bresp, reader_axi.bvalid,
                    writer_line, writer_beat, reader_fifo_count};
endmodule
