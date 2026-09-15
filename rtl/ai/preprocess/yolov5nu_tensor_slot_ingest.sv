`timescale 1ns/1ps

// Sixteen independent, non-backpressuring video taps. Each channel owns two
// tensor slots in the existing Arena0/Arena1 layout. READY slots are immutable
// until software releases them; no slot is reused while an AXI B is pending.
module yolov5nu_tensor_slot_ingest #(
    parameter integer FRAME_WIDTH = 640,
    parameter integer FRAME_HEIGHT = 480,
    parameter integer FIFO_DEPTH = 1024,
    parameter [31:0] SLOT_STRIDE = 32'd921600
) (
    input wire clk,
    input wire resetn,
    input wire enable,
    input wire release_pulse,
    input wire [31:0] release_mask,
    input wire [16*48-1:0] tap_data,
    input wire [15:0] tap_accept,
    input wire [15:0] tap_sof,
    input wire [15:0] tap_eol,
    input wire [15:0] tap_eof,
    input wire [16*32-1:0] tap_frame_id,
    input wire [15:0] tap_error,
    output wire [31:0] ready_mask,
    output wire [31:0] writing_mask,
    output wire [31:0] error_mask,
    output wire [32*32-1:0] slot_frame_ids,
    output wire [32*32-1:0] slot_byte_counts,
    output wire [16*32-1:0] no_slot_counts,
    output wire [16*32-1:0] missed_frame_counts,
    output wire [16*32-1:0] overflow_counts,
    axi4_if.master m_axi
);
    localparam [31:0] ARENA0_BASE = 32'h3000_0000;
    localparam [31:0] ARENA1_BASE = 32'h3100_0000;
    localparam [31:0] FRAME_BYTES = FRAME_WIDTH*FRAME_HEIGHT*3;

    initial begin
        if (SLOT_STRIDE < FRAME_BYTES || SLOT_STRIDE[4:0] != 0)
            $error("Invalid tensor slot stride");
    end

    axi4_if #(.ADDR_WIDTH(32), .DATA_WIDTH(256), .ID_WIDTH(3))
        leaf_axi [16] ();
    axi4_if #(.ADDR_WIDTH(32), .DATA_WIDTH(256), .ID_WIDTH(3))
        level1_axi [8] ();
    axi4_if #(.ADDR_WIDTH(32), .DATA_WIDTH(256), .ID_WIDTH(3))
        level2_axi [4] ();
    axi4_if #(.ADDR_WIDTH(32), .DATA_WIDTH(256), .ID_WIDTH(3))
        level3_axi [2] ();
    wire [15:0] channel_pending;
    wire any_capture_pending = |channel_pending;
    reg [3:0] next_channel;

    // A capture cannot be backpressured once its source frame begins. The
    // sixteen writers share one AXI port, so admitting all sixteen on the
    // same SOF can overrun their small input FIFOs before arbitration reaches
    // them. Rotate admission across channels and keep one frame in flight.
    always @(posedge clk) begin
        if (!resetn)
            next_channel <= 0;
        else if (enable && !any_capture_pending)
            next_channel <= next_channel + 1'b1;
    end

    for (genvar ch = 0; ch < 16; ch = ch + 1) begin : g_channel
        reg command_start;
        reg pending, seen_busy, bank;
        reg ready0, ready1, error0, error1;
        reg [31:0] frame0, frame1, bytes0, bytes1;
        reg [31:0] command_addr;
        reg [31:0] no_slot_count, missed_frame_count;
        wire busy, ready_for_frame, completed, completion_error;
        wire [3:0] unused_completion_channel;
        wire [31:0] completed_frame, completed_bytes, overflow_count;
        wire choose0 = !ready0;
        wire choose1 = !ready1;
        wire [31:0] selected_addr =
            (choose0 ? ARENA0_BASE : ARENA1_BASE) + ch*SLOT_STRIDE;
        assign channel_pending[ch] = pending;

        assign ready_mask[ch] = ready0;
        assign ready_mask[ch+16] = ready1;
        assign writing_mask[ch] = pending && !bank;
        assign writing_mask[ch+16] = pending && bank;
        assign error_mask[ch] = error0;
        assign error_mask[ch+16] = error1;
        assign slot_frame_ids[ch*32 +: 32] = frame0;
        assign slot_frame_ids[(ch+16)*32 +: 32] = frame1;
        assign slot_byte_counts[ch*32 +: 32] = bytes0;
        assign slot_byte_counts[(ch+16)*32 +: 32] = bytes1;
        assign no_slot_counts[ch*32 +: 32] = no_slot_count;
        assign missed_frame_counts[ch*32 +: 32] = missed_frame_count;
        assign overflow_counts[ch*32 +: 32] = overflow_count;

        yolov5nu_tensor_capture_sidecar #(
            .CHANNELS(1), .FRAME_WIDTH(FRAME_WIDTH),
            .FRAME_HEIGHT(FRAME_HEIGHT), .FIFO_DEPTH(FIFO_DEPTH)
        ) u_capture (
            .clk(clk), .resetn(resetn),
            .command_start(command_start), .cancel(!enable),
            .command_channel(4'd0),
            .command_addr(command_addr),
            .tap_data(tap_data[ch*48 +: 48]),
            .tap_accept(tap_accept[ch +: 1]),
            .tap_sof(tap_sof[ch +: 1]),
            .tap_eol(tap_eol[ch +: 1]),
            .tap_eof(tap_eof[ch +: 1]),
            .tap_frame_id(tap_frame_id[ch*32 +: 32]),
            .tap_error(tap_error[ch +: 1]),
            .busy(busy), .ready_for_frame(ready_for_frame),
            .completed(completed),
            .completion_error(completion_error),
            .completion_channel(unused_completion_channel),
            .completion_frame_id(completed_frame),
            .completion_bytes(completed_bytes),
            .overflow_count(overflow_count),
            .m_axi(leaf_axi[ch])
        );

        always @(posedge clk) begin
            if (!resetn) begin
                command_start <= 0;
                pending <= 0;
                seen_busy <= 0;
                bank <= 0;
                ready0 <= 0;
                ready1 <= 0;
                error0 <= 0;
                error1 <= 0;
                frame0 <= 0;
                frame1 <= 0;
                bytes0 <= 0;
                bytes1 <= 0;
                command_addr <= 0;
                no_slot_count <= 0;
                missed_frame_count <= 0;
            end else begin
                command_start <= 0;
                if (enable && tap_accept[ch] && tap_sof[ch] &&
                    !ready_for_frame)
                    missed_frame_count <= missed_frame_count + 1'b1;
                if (enable && tap_accept[ch] && tap_sof[ch] &&
                    ready0 && ready1)
                    no_slot_count <= no_slot_count + 1'b1;
                if (release_pulse) begin
                    if (release_mask[ch]) ready0 <= 0;
                    if (release_mask[ch+16]) ready1 <= 0;
                end
                if (pending) begin
                    if (busy)
                        seen_busy <= 1;
                    if (seen_busy && !busy && completed) begin
                        pending <= 0;
                        seen_busy <= 0;
                        if (!bank) begin
                            frame0 <= completed_frame;
                            bytes0 <= completed_bytes;
                            ready0 <= !completion_error &&
                                      completed_bytes == FRAME_BYTES;
                            error0 <= completion_error ||
                                      completed_bytes != FRAME_BYTES;
                        end else begin
                            frame1 <= completed_frame;
                            bytes1 <= completed_bytes;
                            ready1 <= !completion_error &&
                                      completed_bytes == FRAME_BYTES;
                            error1 <= completion_error ||
                                      completed_bytes != FRAME_BYTES;
                        end
                    end else if (seen_busy && !busy && !enable) begin
                        pending <= 0;
                        seen_busy <= 0;
                    end
                end else if (enable && !busy && !any_capture_pending &&
                             next_channel == 4'(ch)) begin
                    if (choose0 || choose1) begin
                        bank <= !choose0;
                        command_addr <= selected_addr;
                        pending <= 1;
                        command_start <= 1;
                    end
                end
            end
        end
    end

    for (genvar i = 0; i < 8; i = i + 1) begin : g_level1
        axi4_write_arbiter2 u_arbiter (
            .clk(clk), .resetn(resetn),
            .s0_axi(leaf_axi[2*i]), .s1_axi(leaf_axi[2*i+1]),
            .m_axi(level1_axi[i])
        );
    end
    for (genvar i = 0; i < 4; i = i + 1) begin : g_level2
        axi4_write_arbiter2 u_arbiter (
            .clk(clk), .resetn(resetn),
            .s0_axi(level1_axi[2*i]), .s1_axi(level1_axi[2*i+1]),
            .m_axi(level2_axi[i])
        );
    end
    for (genvar i = 0; i < 2; i = i + 1) begin : g_level3
        axi4_write_arbiter2 u_arbiter (
            .clk(clk), .resetn(resetn),
            .s0_axi(level2_axi[2*i]), .s1_axi(level2_axi[2*i+1]),
            .m_axi(level3_axi[i])
        );
    end
    axi4_write_arbiter2 u_root_arbiter (
        .clk(clk), .resetn(resetn),
        .s0_axi(level3_axi[0]), .s1_axi(level3_axi[1]),
        .m_axi(m_axi)
    );
endmodule
