`timescale 1ns/1ps

// Fixed 9/16 display reduction of the canonical 640x480 two-pixel stream.
// A source pair maps to floor(output_pair*16/9), matching the old mosaic
// reader's pair-based nearest-neighbour sampling.  The output is 360x270.
module display_scaler (
    video_stream_if.sink   s_video,
    video_stream_if.source m_video
);
    localparam [8:0] LAST_SOURCE_PAIR = 9'd319;
    localparam [8:0] LAST_SOURCE_LINE = 9'd479;
    localparam [7:0] LAST_OUTPUT_PAIR = 8'd179;
    localparam [8:0] LAST_OUTPUT_LINE = 9'd269;

    reg [8:0] source_pair;
    reg [8:0] source_line;
    reg [8:0] next_pair;
    reg [8:0] next_line;
    reg [3:0] pair_phase;
    reg [3:0] line_phase;
    reg [7:0] output_pair;
    reg [8:0] output_line;

    reg valid_q;
    reg [31:0] data_q;
    reg sof_q, eol_q, eof_q, error_q;
    reg [3:0] stream_id_q;
    reg [31:0] frame_id_q;
    reg tail_wait_q;
    reg frame_error_q;

    wire [31:0] converted_pair;
    rgb888_to_rgb565 u_rgb565 (
        .rgb888_pair(s_video.data), .rgb565_pair(converted_pair)
    );

    wire can_advance = !valid_q || m_video.ready;
    wire accept = s_video.valid && s_video.ready;
    wire [8:0] current_pair = s_video.sof ? 9'd0 : source_pair;
    wire [8:0] current_line = s_video.sof ? 9'd0 : source_line;
    wire [8:0] target_pair = s_video.sof ? 9'd0 : next_pair;
    wire [8:0] target_line = s_video.sof ? 9'd0 : next_line;
    wire select_pair = (current_pair == target_pair) &&
                       (current_line == target_line);
    wire [7:0] current_output_pair = s_video.sof ? 8'd0 : output_pair;
    wire [8:0] current_output_line = s_video.sof ? 9'd0 : output_line;
    wire [3:0] current_pair_phase = s_video.sof ? 4'd0 : pair_phase;
    wire [3:0] current_line_phase = s_video.sof ? 4'd0 : line_phase;
    wire final_sample = select_pair &&
        (current_output_pair == LAST_OUTPUT_PAIR) &&
        (current_output_line == LAST_OUTPUT_LINE);
    wire malformed = (s_video.eol && current_pair != LAST_SOURCE_PAIR) ||
                     (s_video.eof &&
                      (!s_video.eol || current_line != LAST_SOURCE_LINE));

    // The final display beat is held until the physical input EOF confirms
    // that the discarded tail of the 640x480 frame was also received cleanly.
    assign s_video.ready = can_advance && !(tail_wait_q && s_video.sof);
    assign m_video.aclk = s_video.aclk;
    assign m_video.aresetn = s_video.aresetn;
    assign m_video.valid = valid_q;
    assign m_video.data = data_q;
    assign m_video.sof = sof_q;
    assign m_video.eol = eol_q;
    assign m_video.eof = eof_q;
    assign m_video.error = error_q;
    assign m_video.stream_id = stream_id_q;
    assign m_video.frame_id = frame_id_q;

    always @(posedge s_video.aclk) begin
        if (!s_video.aresetn) begin
            source_pair <= 0;
            source_line <= 0;
            next_pair <= 0;
            next_line <= 0;
            pair_phase <= 0;
            line_phase <= 0;
            output_pair <= 0;
            output_line <= 0;
            valid_q <= 1'b0;
            data_q <= 0;
            sof_q <= 1'b0;
            eol_q <= 1'b0;
            eof_q <= 1'b0;
            error_q <= 1'b0;
            stream_id_q <= 0;
            frame_id_q <= 0;
            tail_wait_q <= 0;
            frame_error_q <= 0;
        end else if (can_advance) begin
            valid_q <= accept && select_pair && !final_sample;
            if (tail_wait_q && s_video.valid && s_video.sof) begin
                valid_q <= 1'b1;
                error_q <= 1'b1;
                tail_wait_q <= 1'b0;
            end
            if (accept) begin
                if (s_video.sof)
                    frame_error_q <= s_video.error | malformed;
                else
                    frame_error_q <= frame_error_q | s_video.error | malformed;
                if (s_video.eof && tail_wait_q) begin
                    valid_q <= 1'b1;
                    error_q <= frame_error_q | s_video.error | malformed;
                    tail_wait_q <= 1'b0;
                end
                if (s_video.eol) begin
                    source_pair <= 0;
                    source_line <= current_line + 1'b1;
                    next_pair <= 0;
                    pair_phase <= 0;
                    output_pair <= 0;
                    if (current_line == target_line) begin
                        next_line <= target_line +
                            ((current_line_phase + 4'd7 >= 4'd9) ? 9'd2 : 9'd1);
                        line_phase <= (current_line_phase + 4'd7 >= 4'd9) ?
                            current_line_phase - 4'd2 : current_line_phase + 4'd7;
                        output_line <= current_output_line + 1'b1;
                    end
                end else begin
                    source_pair <= current_pair + 1'b1;
                    source_line <= current_line;
                    if (s_video.sof) begin
                        next_line <= 0;
                        line_phase <= 0;
                        output_line <= 0;
                    end
                    if (select_pair) begin
                        next_pair <= target_pair +
                            ((current_pair_phase + 4'd7 >= 4'd9) ? 9'd2 : 9'd1);
                        pair_phase <= (current_pair_phase + 4'd7 >= 4'd9) ?
                            current_pair_phase - 4'd2 : current_pair_phase + 4'd7;
                        output_pair <= current_output_pair + 1'b1;
                    end
                end
                if (select_pair) begin
                    data_q <= converted_pair;
                    sof_q <= (current_output_pair == 0) &&
                             (current_output_line == 0);
                    eol_q <= (current_output_pair == LAST_OUTPUT_PAIR);
                    eof_q <= (current_output_pair == LAST_OUTPUT_PAIR) &&
                             (current_output_line == LAST_OUTPUT_LINE);
                    error_q <= (s_video.sof ? 1'b0 : frame_error_q) |
                               s_video.error | malformed;
                    stream_id_q <= s_video.stream_id;
                    frame_id_q <= s_video.frame_id;
                    if (final_sample)
                        tail_wait_q <= 1'b1;
                end
            end
        end
    end
endmodule
