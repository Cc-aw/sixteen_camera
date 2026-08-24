`timescale 1ns/1ps

// Keeps the verified full-screen reader intact and selects it or the mosaic
// reader for one complete output frame. Both engines share one read-only AXI
// port and one AXI4-Stream output.
module display_reader_subsystem #(
    parameter integer CHANNELS = 16,
    parameter integer SOURCE_WIDTH = 640,
    parameter integer SOURCE_HEIGHT = 480,
    parameter integer SOURCE_STRIDE_BYTES = SOURCE_WIDTH * 4,
    parameter integer BURST_MAX_BEATS = 64,
    parameter integer READ_OUTSTANDING = 8,
    parameter integer READ_DESCRIPTOR_DEPTH = 8
) (
    input  wire                     clk,
    input  wire                     resetn,
    output wire                     buffer_acquire,
    input  wire                     buffer_grant,
    input  wire [31:0]              buffer_base,
    input  wire [CHANNELS*32-1:0]   buffer_bases,
    input  wire [CHANNELS-1:0]      buffer_valid_mask,
    input  wire                     buffer_mode,
    output wire                     buffer_done,
    input  wire [31:0]              frame_width,
    input  wire [31:0]              frame_height,
    input  wire [31:0]              frame_stride_bytes,
    axi4_if.master                  m_axi,
    axis_video_if.source            m_axis,
    output wire                     axi_error,
    output wire                     fifo_underflow,
    output wire [31:0]              debug_active_base,
    output wire [31:0]              debug_status
);
    axi4_if #(.ADDR_WIDTH(32), .DATA_WIDTH(256), .ID_WIDTH(3)) full_axi();
    axi4_if #(.ADDR_WIDTH(32), .DATA_WIDTH(256), .ID_WIDTH(3)) mosaic_axi();
    axis_video_if #(.DATA_WIDTH(48)) full_axis();
    axis_video_if #(.DATA_WIDTH(48)) mosaic_axis();

    reg active;
    reg active_mosaic;
    reg full_grant;
    reg mosaic_grant;
    wire full_acquire;
    wire mosaic_acquire;
    wire full_done;
    wire mosaic_done;
    wire full_error;
    wire mosaic_error;
    wire full_underflow;
    wire mosaic_underflow;
    wire [31:0] full_debug_base;
    wire [31:0] full_debug_status;
    wire [31:0] mosaic_debug_status;

    assign buffer_acquire = !active && full_acquire && mosaic_acquire;
    assign buffer_done = active && (active_mosaic ? mosaic_done : full_done);
    assign axi_error = active_mosaic ? mosaic_error : full_error;
    assign fifo_underflow = active_mosaic ? mosaic_underflow : full_underflow;
    assign debug_active_base = active_mosaic ? 32'd0 : full_debug_base;
    assign debug_status = active_mosaic ?
                          {1'b0, mosaic_debug_status[30:0]} :
                          full_debug_status;

    always @(posedge clk) begin
        if (!resetn) begin
            active <= 1'b0;
            active_mosaic <= 1'b1;
            full_grant <= 1'b0;
            mosaic_grant <= 1'b0;
        end else begin
            full_grant <= 1'b0;
            mosaic_grant <= 1'b0;
            if (!active && buffer_grant) begin
                active <= 1'b1;
                active_mosaic <= !buffer_mode;
                if (buffer_mode)
                    full_grant <= 1'b1;
                else
                    mosaic_grant <= 1'b1;
            end
            if (buffer_done)
                active <= 1'b0;
        end
    end

    ddr_frame_reader #(
        .BURST_MAX_BEATS(BURST_MAX_BEATS),
        .READ_OUTSTANDING(READ_OUTSTANDING),
        .DESCRIPTOR_DEPTH(READ_DESCRIPTOR_DEPTH)
    ) u_full_reader (
        .clk(clk), .resetn(resetn),
        .buffer_acquire(full_acquire), .buffer_grant(full_grant),
        .buffer_base(buffer_base), .buffer_done(full_done),
        .frame_width(frame_width), .frame_height(frame_height),
        .frame_stride_bytes(frame_stride_bytes), .m_axi(full_axi),
        .m_axis(full_axis), .axi_error(full_error),
        .fifo_underflow(full_underflow),
        .debug_active_base(full_debug_base),
        .debug_status(full_debug_status)
    );

    mosaic_frame_reader #(
        .CHANNELS(CHANNELS),
        .SOURCE_WIDTH(SOURCE_WIDTH),
        .SOURCE_HEIGHT(SOURCE_HEIGHT),
        .SOURCE_STRIDE_BYTES(SOURCE_STRIDE_BYTES),
        .BURST_MAX_BEATS(BURST_MAX_BEATS),
        .READ_OUTSTANDING(READ_OUTSTANDING),
        .DESCRIPTOR_DEPTH(READ_DESCRIPTOR_DEPTH)
    ) u_mosaic_reader (
        .clk(clk), .resetn(resetn),
        .buffer_acquire(mosaic_acquire), .buffer_grant(mosaic_grant),
        .buffer_bases(buffer_bases),
        .buffer_valid_mask(buffer_valid_mask), .buffer_done(mosaic_done),
        .m_axi(mosaic_axi), .m_axis(mosaic_axis),
        .axi_error(mosaic_error), .fifo_underflow(mosaic_underflow),
        .debug_status(mosaic_debug_status)
    );

    assign m_axis.aclk = clk;
    assign m_axis.aresetn = resetn;
    assign m_axis.tdata = active_mosaic ? mosaic_axis.tdata : full_axis.tdata;
    assign m_axis.tvalid = active_mosaic ? mosaic_axis.tvalid : full_axis.tvalid;
    assign m_axis.tuser = active_mosaic ? mosaic_axis.tuser : full_axis.tuser;
    assign m_axis.tlast = active_mosaic ? mosaic_axis.tlast : full_axis.tlast;
    assign mosaic_axis.tready = active_mosaic ? m_axis.tready : 1'b0;
    assign full_axis.tready = active_mosaic ? 1'b0 : m_axis.tready;

    assign m_axi.aclk = clk;
    assign m_axi.aresetn = resetn;
    assign m_axi.awid = active_mosaic ? mosaic_axi.awid : full_axi.awid;
    assign m_axi.awaddr = active_mosaic ? mosaic_axi.awaddr : full_axi.awaddr;
    assign m_axi.awlen = active_mosaic ? mosaic_axi.awlen : full_axi.awlen;
    assign m_axi.awsize = active_mosaic ? mosaic_axi.awsize : full_axi.awsize;
    assign m_axi.awburst = active_mosaic ? mosaic_axi.awburst : full_axi.awburst;
    assign m_axi.awlock = active_mosaic ? mosaic_axi.awlock : full_axi.awlock;
    assign m_axi.awcache = active_mosaic ? mosaic_axi.awcache : full_axi.awcache;
    assign m_axi.awprot = active_mosaic ? mosaic_axi.awprot : full_axi.awprot;
    assign m_axi.awqos = active_mosaic ? mosaic_axi.awqos : full_axi.awqos;
    assign m_axi.awvalid = active_mosaic ? mosaic_axi.awvalid : full_axi.awvalid;
    assign m_axi.wdata = active_mosaic ? mosaic_axi.wdata : full_axi.wdata;
    assign m_axi.wstrb = active_mosaic ? mosaic_axi.wstrb : full_axi.wstrb;
    assign m_axi.wlast = active_mosaic ? mosaic_axi.wlast : full_axi.wlast;
    assign m_axi.wvalid = active_mosaic ? mosaic_axi.wvalid : full_axi.wvalid;
    assign m_axi.bready = active_mosaic ? mosaic_axi.bready : full_axi.bready;
    assign m_axi.arid = active_mosaic ? mosaic_axi.arid : full_axi.arid;
    assign m_axi.araddr = active_mosaic ? mosaic_axi.araddr : full_axi.araddr;
    assign m_axi.arlen = active_mosaic ? mosaic_axi.arlen : full_axi.arlen;
    assign m_axi.arsize = active_mosaic ? mosaic_axi.arsize : full_axi.arsize;
    assign m_axi.arburst = active_mosaic ? mosaic_axi.arburst : full_axi.arburst;
    assign m_axi.arlock = active_mosaic ? mosaic_axi.arlock : full_axi.arlock;
    assign m_axi.arcache = active_mosaic ? mosaic_axi.arcache : full_axi.arcache;
    assign m_axi.arprot = active_mosaic ? mosaic_axi.arprot : full_axi.arprot;
    assign m_axi.arqos = active_mosaic ? mosaic_axi.arqos : full_axi.arqos;
    assign m_axi.arvalid = active_mosaic ? mosaic_axi.arvalid : full_axi.arvalid;
    assign m_axi.rready = active_mosaic ? mosaic_axi.rready : full_axi.rready;

    assign mosaic_axi.awready = active_mosaic ? m_axi.awready : 1'b0;
    assign full_axi.awready = active_mosaic ? 1'b0 : m_axi.awready;
    assign mosaic_axi.wready = active_mosaic ? m_axi.wready : 1'b0;
    assign full_axi.wready = active_mosaic ? 1'b0 : m_axi.wready;
    assign mosaic_axi.bid = m_axi.bid;
    assign full_axi.bid = m_axi.bid;
    assign mosaic_axi.bresp = m_axi.bresp;
    assign full_axi.bresp = m_axi.bresp;
    assign mosaic_axi.bvalid = active_mosaic ? m_axi.bvalid : 1'b0;
    assign full_axi.bvalid = active_mosaic ? 1'b0 : m_axi.bvalid;
    assign mosaic_axi.arready = active_mosaic ? m_axi.arready : 1'b0;
    assign full_axi.arready = active_mosaic ? 1'b0 : m_axi.arready;
    assign mosaic_axi.rid = m_axi.rid;
    assign full_axi.rid = m_axi.rid;
    assign mosaic_axi.rdata = m_axi.rdata;
    assign full_axi.rdata = m_axi.rdata;
    assign mosaic_axi.rresp = m_axi.rresp;
    assign full_axi.rresp = m_axi.rresp;
    assign mosaic_axi.rlast = m_axi.rlast;
    assign full_axi.rlast = m_axi.rlast;
    assign mosaic_axi.rvalid = active_mosaic ? m_axi.rvalid : 1'b0;
    assign full_axi.rvalid = active_mosaic ? 1'b0 : m_axi.rvalid;
endmodule
