`timescale 1ns/1ps

// YOLOv5nu location-major class reducer.
//
// The active model stores 80 signed INT8 sigmoid scores for each of 6300
// locations.  Lane 0 is the earliest byte in the tensor stream.  One AXI
// beat may straddle a location boundary, so the fold below carries the new
// location's partial maximum into the next beat.  FOLD_BYTES lanes are
// folded per clock.  Ties retain the
// lowest class ID, matching the software implementation.
module yolov5nu_class_reducer #(
    parameter integer DATA_WIDTH = 256,
    parameter integer CLASS_COUNT = 80,
    parameter integer POSITION_COUNT = 6300,
    parameter integer FOLD_BYTES = 4
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

    output wire                   result_valid,
    input  wire                  result_ready,
    output wire  [12:0]           result_position,
    output wire  [6:0]            result_class,
    output wire signed [7:0]      result_score,
    output wire                   result_candidate,
    output wire                   result_last,

    output wire                  compute_active,
    output wire                   busy,
    output wire                   done,
    output wire                   error,
    output wire  [2:0]            error_flags,
    output wire  [12:0]           positions_seen,
    output wire  [12:0]           candidates_seen
);
    generate if(FOLD_BYTES==32 && DATA_WIDTH==256) begin : g_wide
        yolov5nu_class_reducer_wide #(.CLASS_COUNT(CLASS_COUNT),.POSITION_COUNT(POSITION_COUNT)) impl(.*);
    end else begin : g_folded
        yolov5nu_class_reducer_folded #(.DATA_WIDTH(DATA_WIDTH),.CLASS_COUNT(CLASS_COUNT),
            .POSITION_COUNT(POSITION_COUNT),.FOLD_BYTES(FOLD_BYTES)) impl(.*);
    end endgenerate
endmodule

`timescale 1ns/1ps

// YOLOv5nu location-major class reducer.
//
// The active model stores 80 signed INT8 sigmoid scores for each of 6300
// locations.  Lane 0 is the earliest byte in the tensor stream.  One AXI
// beat may straddle a location boundary, so the fold below carries the new
// location's partial maximum into the next beat.  FOLD_BYTES lanes are
// folded per clock.  Ties retain the
// lowest class ID, matching the software implementation.
module yolov5nu_class_reducer_folded #(
    parameter integer DATA_WIDTH = 256,
    parameter integer CLASS_COUNT = 80,
    parameter integer POSITION_COUNT = 6300,
    parameter integer FOLD_BYTES = 4
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

    output wire                  compute_active,
    output reg                   busy,
    output reg                   done,
    output reg                   error,
    output reg  [2:0]            error_flags,
    output reg  [12:0]           positions_seen,
    output reg  [12:0]           candidates_seen
);
    localparam integer LANES = DATA_WIDTH / 8;
    localparam integer GROUP_COUNT = LANES / FOLD_BYTES;
    localparam integer GROUP_WIDTH = (GROUP_COUNT <= 1) ? 1 : $clog2(GROUP_COUNT);
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
    reg [GROUP_WIDTH-1:0] beat_group;

    assign compute_active = beat_active && (!result_valid || result_ready);

    wire [6:0] fold_class_index;
    wire signed [7:0] fold_best_score;
    wire [6:0] fold_best_class;
    wire fold_emits;
    wire signed [7:0] fold_result_score;
    wire [6:0] fold_result_class;

    // I: Current beat/group state, terminal marker and result backpressure.
    // P: Accept the next beat while the final group of a nonterminal beat drains.
    // O: A continuous four-cycle beat cadence without changing fold width.
    // A: hlk
    // T: 2026-09-22 10:48:34 +0800
    wire final_group = beat_active &&
        beat_group == GROUP_WIDTH'(GROUP_COUNT-1);
    assign s_ready = busy && !input_complete &&
                     (!beat_active || (final_group && !beat_last)) &&
                     (!result_valid || result_ready);

    initial begin
        if (FOLD_BYTES < 1 || LANES % FOLD_BYTES != 0 ||
            FOLD_BYTES > CLASS_COUNT)
            $error("FOLD_BYTES must divide one beat and fit within a class vector");
    end

    yolov5nu_class_fold_tree #(.BYTES(FOLD_BYTES), .CLASSES(CLASS_COUNT)) u_fold (
        .data(beat_data[beat_group*FOLD_BYTES*8+:FOLD_BYTES*8]),
        .keep(beat_keep[beat_group*FOLD_BYTES+:FOLD_BYTES]),
        .class_index(class_index), .best_class(best_class), .best_score(best_score),
        .next_index(fold_class_index), .next_class(fold_best_class),
        .next_score(fold_best_score), .emits(fold_emits),
        .result_class(fold_result_class), .result_score(fold_result_score)
    );

    always @(posedge clk) begin
        if (!resetn) begin
            class_index <= 7'd0;
            best_score <= -8'sd128;
            best_class <= 7'd0;
            input_complete <= 1'b0;
            beat_active <= 1'b0;
            beat_group <= '0;
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
                beat_group <= '0;
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
                beat_group <= '0;
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
                // I: Final-group completion and a simultaneous input handshake.
                // P: Retain the newly loaded beat, otherwise release the old beat.
                // O: Group zero is ready on the cycle after a beat-to-beat handoff.
                // A: hlk
                // T: 2026-09-22 10:48:34 +0800
                if (final_group) begin
                    if (s_valid && s_ready) begin
                        beat_group <= '0;
                        beat_active <= 1'b1;
                    end else begin
                        beat_active <= 1'b0;
                    end
                end else begin
                    beat_group <= beat_group + 1'b1;
                end

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

                if (beat_last && beat_group == GROUP_WIDTH'(GROUP_COUNT-1)) begin
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
