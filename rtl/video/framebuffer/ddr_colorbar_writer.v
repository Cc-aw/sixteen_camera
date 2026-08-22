`timescale 1ns/1ps

module ddr_colorbar_writer #(
    parameter [31:0] FRAME_BASE_ADDR = 32'h0800_0000,
    parameter integer FRAME_WIDTH = 1920,
    parameter integer FRAME_HEIGHT = 1080,
    parameter integer FRAME_STRIDE_BYTES = FRAME_WIDTH * 4,
    parameter integer BURST_MAX_BEATS = 64
) (
    input  wire         clk,
    input  wire         resetn,
    input  wire         init_done,

    output wire [2:0]   m_axi_awid,
    output wire [31:0]  m_axi_awaddr,
    output wire [7:0]   m_axi_awlen,
    output wire [2:0]   m_axi_awsize,
    output wire [1:0]   m_axi_awburst,
    output wire         m_axi_awlock,
    output wire [3:0]   m_axi_awcache,
    output wire [2:0]   m_axi_awprot,
    output wire [3:0]   m_axi_awqos,
    output wire         m_axi_awvalid,
    input  wire         m_axi_awready,
    output wire [255:0] m_axi_wdata,
    output wire [31:0]  m_axi_wstrb,
    output wire         m_axi_wlast,
    output wire         m_axi_wvalid,
    input  wire         m_axi_wready,
    input  wire [2:0]   m_axi_bid,
    input  wire [1:0]   m_axi_bresp,
    input  wire         m_axi_bvalid,
    output wire         m_axi_bready,

    output reg          frame_ready,
    output reg          busy,
    output reg          axi_error,
    output reg  [15:0]  debug_line,
    output reg  [15:0]  debug_beat
);
    localparam integer PIXELS_PER_BEAT = 8;
    localparam integer BYTES_PER_BEAT = 32;
    localparam integer LINE_BEATS = FRAME_WIDTH / PIXELS_PER_BEAT;

    localparam [2:0] ST_WAIT  = 3'd0;
    localparam [2:0] ST_PREP  = 3'd1;
    localparam [2:0] ST_START = 3'd2;
    localparam [2:0] ST_WRITE = 3'd3;
    localparam [2:0] ST_NEXT  = 3'd4;
    localparam [2:0] ST_DONE  = 3'd5;

    reg [2:0] state;
    reg [15:0] line_index;
    reg [15:0] line_beat_index;
    reg [15:0] burst_beats;
    reg [15:0] feed_beat_index;
    reg [15:0] feed_beats_left;
    reg [255:0] fifo_data;
    reg fifo_valid;
    reg wr_start;

    wire [31:0] next_addr = FRAME_BASE_ADDR +
                            line_index * FRAME_STRIDE_BYTES +
                            line_beat_index * BYTES_PER_BEAT;
    wire [15:0] line_beats_left = LINE_BEATS - line_beat_index;
    wire [15:0] beats_to_4k = (16'h1000 - {4'd0, next_addr[11:0]}) /
                               BYTES_PER_BEAT;
    wire [15:0] line_limited = (line_beats_left > BURST_MAX_BEATS) ?
                               BURST_MAX_BEATS : line_beats_left;
    wire [15:0] planned_beats = (line_limited > beats_to_4k) ?
                                beats_to_4k : line_limited;

    wire wr_ready;
    wire wr_fifo_re;
    wire wr_done;
    wire wr_error;
    wire [5:0] awid_full;
    wire [5:0] bid_full = {3'd0, m_axi_bid};

    function [23:0] color_for_x;
        input [15:0] x;
        begin
            if      (x < FRAME_WIDTH/8)   color_for_x = 24'hffffff;
            else if (x < FRAME_WIDTH*2/8) color_for_x = 24'hffff00;
            else if (x < FRAME_WIDTH*3/8) color_for_x = 24'h00ffff;
            else if (x < FRAME_WIDTH*4/8) color_for_x = 24'h00ff00;
            else if (x < FRAME_WIDTH*5/8) color_for_x = 24'hff00ff;
            else if (x < FRAME_WIDTH*6/8) color_for_x = 24'hff0000;
            else if (x < FRAME_WIDTH*7/8) color_for_x = 24'h0000ff;
            else                          color_for_x = 24'h000000;
        end
    endfunction

    function [255:0] make_colorbar_beat;
        input [15:0] beat_x;
        integer lane;
        reg [15:0] pixel_x;
        begin
            make_colorbar_beat = 256'd0;
            for (lane = 0; lane < PIXELS_PER_BEAT; lane = lane + 1) begin
                pixel_x = beat_x * PIXELS_PER_BEAT + lane;
                make_colorbar_beat[lane*32 +: 32] =
                    {8'h00, color_for_x(pixel_x)};
            end
        end
    endfunction

    axi_master_write #(.AXI_QOS(4'h8)) u_axi_master_write (
        .ARESETN(resetn), .ACLK(clk),
        .M_AXI_AWID(awid_full), .M_AXI_AWADDR(m_axi_awaddr),
        .M_AXI_AWLEN(m_axi_awlen), .M_AXI_AWSIZE(m_axi_awsize),
        .M_AXI_AWBURST(m_axi_awburst), .M_AXI_AWLOCK(m_axi_awlock),
        .M_AXI_AWCACHE(m_axi_awcache), .M_AXI_AWPROT(m_axi_awprot),
        .M_AXI_AWQOS(m_axi_awqos), .M_AXI_AWUSER(),
        .M_AXI_AWVALID(m_axi_awvalid), .M_AXI_AWREADY(m_axi_awready),
        .M_AXI_WDATA(m_axi_wdata), .M_AXI_WSTRB(m_axi_wstrb),
        .M_AXI_WLAST(m_axi_wlast), .M_AXI_WUSER(),
        .M_AXI_WVALID(m_axi_wvalid), .M_AXI_WREADY(m_axi_wready),
        .M_AXI_BID(bid_full), .M_AXI_BRESP(m_axi_bresp),
        .M_AXI_BUSER(1'b0), .M_AXI_BVALID(m_axi_bvalid),
        .M_AXI_BREADY(m_axi_bready),
        .WR_START(wr_start), .WR_ADRS(next_addr),
        .WR_LEN({16'd0, burst_beats}), .WR_READY(wr_ready),
        .WR_FIFO_RE(wr_fifo_re), .WR_FIFO_EMPTY(feed_beats_left == 0),
        .WR_FIFO_VALID(fifo_valid), .WR_FIFO_AEMPTY(1'b0),
        .WR_FIFO_DATA(fifo_data), .WR_DONE(wr_done), .WR_ERROR(wr_error)
    );

    assign m_axi_awid = awid_full[2:0];

    always @(posedge clk) begin
        if (!resetn) begin
            state <= ST_WAIT;
            line_index <= 0;
            line_beat_index <= 0;
            burst_beats <= 0;
            feed_beat_index <= 0;
            feed_beats_left <= 0;
            fifo_data <= 0;
            fifo_valid <= 1'b0;
            wr_start <= 1'b0;
            frame_ready <= 1'b0;
            busy <= 1'b0;
            axi_error <= 1'b0;
            debug_line <= 0;
            debug_beat <= 0;
        end else begin
            wr_start <= 1'b0;
            fifo_valid <= 1'b0;
            debug_line <= line_index;
            debug_beat <= line_beat_index;

            if (wr_fifo_re) begin
                fifo_data <= make_colorbar_beat(feed_beat_index);
                fifo_valid <= 1'b1;
                feed_beat_index <= feed_beat_index + 1'b1;
                feed_beats_left <= feed_beats_left - 1'b1;
            end
            if (wr_error)
                axi_error <= 1'b1;

            case (state)
                ST_WAIT: begin
                    busy <= 1'b0;
                    if (init_done) begin
                        busy <= 1'b1;
                        state <= ST_PREP;
                    end
                end
                ST_PREP: begin
                    burst_beats <= planned_beats;
                    feed_beat_index <= line_beat_index;
                    feed_beats_left <= planned_beats;
                    state <= ST_START;
                end
                ST_START: begin
                    if (wr_ready) begin
                        wr_start <= 1'b1;
                        state <= ST_WRITE;
                    end
                end
                ST_WRITE: begin
                    if (wr_done)
                        state <= ST_NEXT;
                end
                ST_NEXT: begin
                    if (line_beat_index + burst_beats >= LINE_BEATS) begin
                        line_beat_index <= 0;
                        if (line_index == FRAME_HEIGHT-1)
                            state <= ST_DONE;
                        else begin
                            line_index <= line_index + 1'b1;
                            state <= ST_PREP;
                        end
                    end else begin
                        line_beat_index <= line_beat_index + burst_beats;
                        state <= ST_PREP;
                    end
                end
                ST_DONE: begin
                    busy <= 1'b0;
                    frame_ready <= !axi_error;
                end
                default: state <= ST_WAIT;
            endcase
        end
    end
endmodule
