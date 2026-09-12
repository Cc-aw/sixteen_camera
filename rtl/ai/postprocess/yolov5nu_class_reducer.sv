`timescale 1ns/1ps

// YOLOv5nu location-major class reducer.
//
// The active model stores 80 signed INT8 sigmoid scores for each of 6300
// locations.  Lane 0 is the earliest byte in the tensor stream.  One AXI
// beat may straddle a location boundary, so the fold below carries the new
// location's partial maximum into the next beat.  Four lanes are folded per
// clock; this bounds the LUT + comparison path at 100 MHz.  Ties retain the
// lowest class ID, matching the software implementation.
module yolov5nu_class_reducer #(
    parameter integer DATA_WIDTH = 256,
    parameter integer CLASS_COUNT = 80,
    parameter integer POSITION_COUNT = 6300
) (
    input  wire                  clk,
    input  wire                  resetn,
    input  wire                  start,
    input  wire signed [7:0]     score_threshold,

    input  wire [DATA_WIDTH-1:0] s_data,
    input  wire [DATA_WIDTH/8-1:0] s_keep,
    input  wire                  s_valid,
    output wire                  s_ready,
    input  wire                  s_last,

    output reg                   result_valid,
    input  wire                  result_ready,
    output reg  [12:0]           result_position,
    output reg  [6:0]            result_class,
    output reg signed [7:0]      result_score,
    output reg                   result_candidate,
    output reg                   result_last,

    output reg                   busy,
    output reg                   done,
    output reg                   error,
    output reg  [2:0]            error_flags,
    output reg  [12:0]           positions_seen,
    output reg  [12:0]           candidates_seen
);
    localparam integer LANES = DATA_WIDTH / 8;
    localparam [LANES-1:0] FULL_KEEP = {LANES{1'b1}};
    localparam [6:0] LAST_CLASS = 7'(CLASS_COUNT - 1);
    localparam [12:0] LAST_POSITION = 13'(POSITION_COUNT - 1);

    reg [6:0] class_index;
    reg signed [7:0] best_score;
    reg [6:0] best_class;
    reg input_complete;
    reg beat_active;
    reg [DATA_WIDTH-1:0] beat_data;
    reg [LANES-1:0] beat_keep;
    reg beat_last;
    reg [2:0] beat_group;

    integer lane;
    reg [6:0] fold_class_index;
    reg signed [7:0] fold_best_score;
    reg [6:0] fold_best_class;
    reg fold_emits;
    reg signed [7:0] fold_result_score;
    reg [6:0] fold_result_class;

    assign s_ready = busy && !input_complete && !beat_active &&
                     (!result_valid || result_ready);

    // A four-byte group can complete at most one 80-byte class vector.
    always @* begin
        fold_class_index = class_index;
        fold_best_score = best_score;
        fold_best_class = best_class;
        fold_emits = 1'b0;
        fold_result_score = best_score;
        fold_result_class = best_class;
        for (lane = 0; lane < 4; lane = lane + 1) begin
            if (beat_keep[beat_group*4 + lane]) begin
                if ($signed(beat_data[(beat_group*4+lane)*8 +: 8]) >
                    fold_best_score) begin
                    fold_best_score =
                        $signed(beat_data[(beat_group*4+lane)*8 +: 8]);
                    fold_best_class = fold_class_index;
                end
                if (fold_class_index == LAST_CLASS) begin
                    fold_emits = 1'b1;
                    fold_result_score = fold_best_score;
                    fold_result_class = fold_best_class;
                    fold_class_index = 7'd0;
                    fold_best_score = -8'sd128;
                    fold_best_class = 7'd0;
                end else begin
                    fold_class_index = fold_class_index + 1'b1;
                end
            end
        end
    end

    always @(posedge clk) begin
        if (!resetn) begin
            class_index <= 7'd0;
            best_score <= -8'sd128;
            best_class <= 7'd0;
            input_complete <= 1'b0;
            beat_active <= 1'b0;
            beat_group <= 3'd0;
            result_valid <= 1'b0;
            result_position <= 13'd0;
            result_class <= 7'd0;
            result_score <= -8'sd128;
            result_candidate <= 1'b0;
            result_last <= 1'b0;
            busy <= 1'b0;
            done <= 1'b0;
            error <= 1'b0;
            error_flags <= 3'b000;
            positions_seen <= 13'd0;
            candidates_seen <= 13'd0;
        end else begin
            done <= 1'b0;
            if (result_valid && result_ready)
                result_valid <= 1'b0;

            if (start && !busy) begin
                class_index <= 7'd0;
                best_score <= -8'sd128;
                best_class <= 7'd0;
                input_complete <= 1'b0;
                beat_active <= 1'b0;
                beat_group <= 3'd0;
                result_valid <= 1'b0;
                busy <= 1'b1;
                error <= 1'b0;
                error_flags <= 3'b000;
                positions_seen <= 13'd0;
                candidates_seen <= 13'd0;
            end

            if (s_valid && s_ready) begin
                beat_data <= s_data;
                beat_keep <= s_keep;
                beat_last <= s_last;
                beat_group <= 3'd0;
                beat_active <= 1'b1;
                if (s_keep != FULL_KEEP) begin
                    error <= 1'b1;
                    error_flags[0] <= 1'b1;
                end
            end

            if (beat_active && (!result_valid || result_ready)) begin
                class_index <= fold_class_index;
                best_score <= fold_best_score;
                best_class <= fold_best_class;
                beat_group <= beat_group + 1'b1;
                if (beat_group == 3'd7) beat_active <= 1'b0;

                if (fold_emits) begin
                    result_valid <= 1'b1;
                    result_position <= positions_seen;
                    result_class <= fold_result_class;
                    result_score <= fold_result_score;
                    result_candidate <=
                        fold_result_score >= score_threshold;
                    result_last <= positions_seen == LAST_POSITION;
                    positions_seen <= positions_seen + 1'b1;
                    if (fold_result_score >= score_threshold)
                        candidates_seen <= candidates_seen + 1'b1;
                end

                if (beat_last && beat_group == 3'd7) begin
                    input_complete <= 1'b1;
                    if (!fold_emits ||
                        positions_seen != LAST_POSITION ||
                        fold_class_index != 0) begin
                        error <= 1'b1;
                        error_flags[1] <= 1'b1;
                    end
                end else if (fold_emits &&
                             positions_seen == LAST_POSITION) begin
                    error <= 1'b1;
                    error_flags[2] <= 1'b1;
                end
            end

            if (result_valid && result_ready && result_last) begin
                busy <= 1'b0;
                done <= 1'b1;
            end
        end
    end
endmodule
