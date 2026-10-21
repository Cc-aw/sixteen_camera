`timescale 1ns/1ps

// Converts the normalized 2-PPC video format into the existing YOLOv5nu
// NHWC RGB INT8 input contract.  The video pixel is {R,B,G}; byte lane zero
// in the output is R>>1.  One group of sixteen pairs produces three 256-bit
// beats.  Place an independent FIFO before this module when tapping a video
// stream: backpressure here must never propagate into capture/display.
module yolov5nu_tensor_stream_packer #(
    parameter integer FRAME_WIDTH = 640,
    parameter integer FRAME_HEIGHT = 480,
    parameter integer FRAME_ID_WIDTH = 32
) (
    input  wire                      clk,
    input  wire                      resetn,
    input  wire [47:0]               s_pair,
    input  wire                      s_sof,
    input  wire                      s_eol,
    input  wire                      s_eof,
    input  wire [FRAME_ID_WIDTH-1:0] s_frame_id,
    input  wire                      s_error,
    input  wire                      s_valid,
    output wire                      s_ready,
    output wire [255:0]              m_data,
    output wire                      m_sof,
    output wire                      m_eol,
    output wire                      m_eof,
    output wire [FRAME_ID_WIDTH-1:0] m_frame_id,
    output wire                      m_error,
    output wire                      m_valid,
    input  wire                      m_ready
);
    localparam integer GROUPS_PER_LINE = FRAME_WIDTH / 32;
    localparam integer GROUP_WIDTH = (GROUPS_PER_LINE <= 1) ?
                                     1 : $clog2(GROUPS_PER_LINE);
    localparam integer LINE_WIDTH = (FRAME_HEIGHT <= 1) ?
                                    1 : $clog2(FRAME_HEIGHT);

    reg [1:0] output_beat;
    reg [3:0] pair_count;
    reg [767:0] group_data [0:1];
    reg group_sof [0:1];
    reg group_eol [0:1];
    reg group_eof [0:1];
    reg group_error [0:1];
    reg [FRAME_ID_WIDTH-1:0] group_frame_id [0:1];
    reg group_ready [0:1];
    reg fill_bank, drain_bank;
    reg [GROUP_WIDTH-1:0] group_in_line;
    reg [LINE_WIDTH-1:0] line_index;
    reg frame_open;

    function automatic [47:0] quantize_pair(input [47:0] pair);
        reg [23:0] p0, p1;
        begin
            p0 = pair[23:0];
            p1 = pair[47:24];
            quantize_pair = {
                1'b0, p1[15:9], 1'b0, p1[7:1], 1'b0, p1[23:17],
                1'b0, p0[15:9], 1'b0, p0[7:1], 1'b0, p0[23:17]
            };
        end
    endfunction

    initial begin
        if (FRAME_WIDTH < 32 || FRAME_WIDTH % 32 != 0 || FRAME_HEIGHT < 1)
            $error("Tensor stream shape must have a 32-pixel aligned row");
    end

    assign s_ready = !group_ready[fill_bank];
    assign m_valid = group_ready[drain_bank];
    assign m_data = group_data[drain_bank][output_beat*256 +: 256];
    assign m_sof = m_valid && output_beat == 0 && group_sof[drain_bank];
    assign m_eol = m_valid && output_beat == 2 && group_eol[drain_bank];
    assign m_eof = m_valid && output_beat == 2 && group_eof[drain_bank];
    assign m_frame_id = group_frame_id[drain_bank];
    assign m_error = group_error[drain_bank];

    always @(posedge clk) begin
        if (!resetn) begin
            output_beat <= 0;
            pair_count <= 0;
            fill_bank <= 0;
            drain_bank <= 0;
            for (int bank=0; bank<2; bank++) begin
                group_data[bank] <= 0;
                group_sof[bank] <= 0;
                group_eol[bank] <= 0;
                group_eof[bank] <= 0;
                group_error[bank] <= 0;
                group_frame_id[bank] <= 0;
                group_ready[bank] <= 0;
            end
            group_in_line <= 0;
            line_index <= 0;
            frame_open <= 0;
        end else begin
            if (s_valid && s_ready) begin
                group_data[fill_bank][pair_count*48 +: 48] <=
                    quantize_pair(s_pair);
                if (s_sof) begin
                    pair_count <= 4'd1;
                    group_data[fill_bank][47:0] <= quantize_pair(s_pair);
                    group_sof[fill_bank] <= 1'b1;
                    group_eol[fill_bank] <= 1'b0;
                    group_eof[fill_bank] <= 1'b0;
                    group_error[fill_bank] <=
                        s_error || pair_count != 0 || frame_open;
                    group_frame_id[fill_bank] <= s_frame_id;
                    group_in_line <= 0;
                    line_index <= 0;
                    frame_open <= 1'b1;
                end else if (pair_count == 0) begin
                    pair_count <= 4'd1;
                    group_sof[fill_bank] <= 1'b0;
                    group_eol[fill_bank] <= 1'b0;
                    group_eof[fill_bank] <= 1'b0;
                    group_error[fill_bank] <= s_error || !frame_open ||
                                              s_eol || s_eof;
                    group_frame_id[fill_bank] <= s_frame_id;
                end else if (pair_count == 4'd15) begin
                    group_ready[fill_bank] <= 1'b1;
                    fill_bank <= !fill_bank;
                    pair_count <= 0;
                    group_eol[fill_bank] <= s_eol;
                    group_eof[fill_bank] <= s_eof;
                    group_error[fill_bank] <= group_error[fill_bank] || s_error ||
                        s_frame_id != group_frame_id[fill_bank] ||
                        s_eol != (group_in_line == GROUP_WIDTH'(GROUPS_PER_LINE-1)) ||
                        s_eof != (group_in_line == GROUP_WIDTH'(GROUPS_PER_LINE-1) &&
                                  line_index == LINE_WIDTH'(FRAME_HEIGHT-1));
                    if (s_eof)
                        frame_open <= 1'b0;
                    if (group_in_line == GROUP_WIDTH'(GROUPS_PER_LINE-1)) begin
                        group_in_line <= 0;
                        if (line_index == LINE_WIDTH'(FRAME_HEIGHT-1))
                            line_index <= 0;
                        else
                            line_index <= line_index + 1'b1;
                    end else
                        group_in_line <= group_in_line + 1'b1;
                end else begin
                    pair_count <= pair_count + 1'b1;
                    group_error[fill_bank] <= group_error[fill_bank] || s_error ||
                        s_frame_id != group_frame_id[fill_bank] || s_eol || s_eof ||
                        !frame_open;
                end
            end
            if (m_valid && m_ready) begin
                if (output_beat == 2) begin
                    group_ready[drain_bank] <= 1'b0;
                    drain_bank <= !drain_bank;
                    output_beat <= 0;
                end else
                    output_beat <= output_beat + 1'b1;
            end
        end
    end
endmodule
