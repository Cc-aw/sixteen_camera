`timescale 1ns/1ps

// Writes one complete NHWC RGB INT8 frame into a 32-byte-aligned tensor slot.
// Completion is reported only after the final AXI B response.  The caller
// must keep the slot owned until done, including on an error response.
module yolov5nu_tensor_frame_writer #(
    parameter integer FRAME_WIDTH = 640,
    parameter integer FRAME_HEIGHT = 480,
    parameter integer MAX_BURST_BEATS = 64,
    parameter integer FRAME_ID_WIDTH = 32
) (
    input  wire                      clk,
    input  wire                      resetn,
    input  wire                      start,
    input  wire                      abort,
    input  wire [31:0]               tensor_addr,
    input  wire [FRAME_ID_WIDTH-1:0] frame_id,
    input  wire [255:0]              s_data,
    input  wire                      s_sof,
    input  wire                      s_eol,
    input  wire                      s_eof,
    input  wire [FRAME_ID_WIDTH-1:0] s_frame_id,
    input  wire                      s_error,
    input  wire                      s_valid,
    output wire                      s_ready,
    output reg                       busy,
    output reg                       done,
    output reg                       error,
    output reg  [31:0]               bytes_written,
    axi4_if.master                   m_axi
);
    localparam integer ROW_BEATS = FRAME_WIDTH * 3 / 32;
    localparam integer FRAME_BEATS = ROW_BEATS * FRAME_HEIGHT;
    localparam integer ROW_WIDTH = (ROW_BEATS <= 1) ? 1 : $clog2(ROW_BEATS);
    localparam [1:0] ST_IDLE=0, ST_AW=1, ST_W=2, ST_B=3;

    reg [1:0] state;
    reg [31:0] write_addr;
    reg [31:0] beats_remaining;
    reg [31:0] beat_index;
    reg [8:0] burst_beats;
    reg [8:0] burst_sent;
    reg [ROW_WIDTH-1:0] row_beat;
    reg [FRAME_ID_WIDTH-1:0] frame_id_q;

    wire w_fire = m_axi.wvalid && m_axi.wready;
    wire b_fire = m_axi.bvalid && m_axi.bready;

    function automatic [8:0] burst_size(input [31:0] remaining,
                                        input [31:0] address);
        reg [31:0] page_beats;
        reg [31:0] selected;
        begin
            page_beats = (32'd4096 - {20'd0, address[11:0]}) >> 5;
            selected = remaining < MAX_BURST_BEATS ? remaining :
                       MAX_BURST_BEATS;
            if (page_beats < selected)
                selected = page_beats;
            burst_size = 9'(selected);
        end
    endfunction

    initial begin
        if (FRAME_WIDTH < 32 || FRAME_WIDTH % 32 != 0 ||
            FRAME_HEIGHT < 1 || MAX_BURST_BEATS < 1 ||
            MAX_BURST_BEATS > 256)
            $error("Invalid tensor frame writer shape or burst size");
    end

    assign s_ready = state == ST_W && m_axi.wready && !abort;
    assign m_axi.aclk = clk;
    assign m_axi.aresetn = resetn;
    assign m_axi.awid = 3'd0;
    assign m_axi.awaddr = write_addr;
    assign m_axi.awlen = 8'(burst_beats - 1'b1);
    assign m_axi.awsize = 3'b101;
    assign m_axi.awburst = 2'b01;
    assign m_axi.awlock = 1'b0;
    assign m_axi.awcache = 4'b0010;
    assign m_axi.awprot = 3'b000;
    assign m_axi.awqos = 4'h6;
    assign m_axi.awvalid = state == ST_AW;
    assign m_axi.wdata = abort ? 256'd0 : s_data;
    assign m_axi.wstrb = 32'hffff_ffff;
    assign m_axi.wlast = state == ST_W &&
                         burst_sent + 1'b1 == burst_beats;
    assign m_axi.wvalid = state == ST_W && (s_valid || abort);
    assign m_axi.bready = state == ST_B;
    assign m_axi.arid = 3'd0;
    assign m_axi.araddr = 32'd0;
    assign m_axi.arlen = 8'd0;
    assign m_axi.arsize = 3'd0;
    assign m_axi.arburst = 2'd0;
    assign m_axi.arlock = 1'b0;
    assign m_axi.arcache = 4'd0;
    assign m_axi.arprot = 3'd0;
    assign m_axi.arqos = 4'd0;
    assign m_axi.arvalid = 1'b0;
    assign m_axi.rready = 1'b0;

    always @(posedge clk) begin
        if (!resetn) begin
            state <= ST_IDLE;
            busy <= 0;
            done <= 0;
            error <= 0;
            bytes_written <= 0;
            write_addr <= 0;
            beats_remaining <= 0;
            beat_index <= 0;
            burst_beats <= 0;
            burst_sent <= 0;
            row_beat <= 0;
            frame_id_q <= 0;
        end else begin
            done <= 0;
            if (busy && abort)
                error <= 1;
            case (state)
            ST_IDLE: if (start) begin
                error <= 0;
                bytes_written <= 0;
                if (tensor_addr[4:0] != 0) begin
                    error <= 1;
                    done <= 1;
                end else begin
                    write_addr <= tensor_addr;
                    frame_id_q <= frame_id;
                    beats_remaining <= FRAME_BEATS;
                    beat_index <= 0;
                    row_beat <= 0;
                    burst_sent <= 0;
                    burst_beats <= burst_size(FRAME_BEATS, tensor_addr);
                    busy <= 1;
                    state <= ST_AW;
                end
            end
            ST_AW: if (m_axi.awvalid && m_axi.awready) begin
                burst_sent <= 0;
                state <= ST_W;
            end
            ST_W: if (w_fire) begin
                if (abort || s_error || s_frame_id != frame_id_q ||
                    s_sof != (beat_index == 0) ||
                    s_eol != (row_beat == ROW_WIDTH'(ROW_BEATS-1)) ||
                    s_eof != (beat_index == FRAME_BEATS-1))
                    error <= 1;
                beat_index <= beat_index + 1'b1;
                beats_remaining <= beats_remaining - 1'b1;
                bytes_written <= bytes_written + 32;
                if (row_beat == ROW_WIDTH'(ROW_BEATS-1))
                    row_beat <= 0;
                else
                    row_beat <= row_beat + 1'b1;
                burst_sent <= burst_sent + 1'b1;
                if (burst_sent + 1'b1 == burst_beats)
                    state <= ST_B;
            end
            ST_B: if (b_fire) begin
                if (m_axi.bresp != 2'b00 || m_axi.bid != 3'd0)
                    error <= 1;
                if (beats_remaining == 0 || abort) begin
                    busy <= 0;
                    done <= 1;
                    state <= ST_IDLE;
                end else begin
                    write_addr <= write_addr + (32'(burst_beats) << 5);
                    burst_beats <= burst_size(
                        beats_remaining,
                        write_addr + (32'(burst_beats) << 5));
                    state <= ST_AW;
                end
            end
            default: state <= ST_IDLE;
            endcase
        end
    end
endmodule
