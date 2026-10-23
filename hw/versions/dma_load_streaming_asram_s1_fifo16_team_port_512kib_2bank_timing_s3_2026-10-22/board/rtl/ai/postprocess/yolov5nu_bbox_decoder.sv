`timescale 1ns/1ps

// Decode the board model's quantized DFL distances into the fixed 16-byte
// candidate ABI. tensor_252 uses scale 0.1129496917. Coordinates reproduce
// the runtime's (grid + 0.5 +/- distance) * stride equations and round to the
// nearest output pixel before clipping to 640x480.
module yolov5nu_bbox_decoder (
    input  wire [12:0] position,
    input  wire [6:0]  class_id,
    input  wire [7:0]  score_i8,
    input  wire signed [7:0] distance_left,
    input  wire signed [7:0] distance_top,
    input  wire signed [7:0] distance_right,
    input  wire signed [7:0] distance_bottom,
    output wire [127:0] candidate
);
    localparam signed [31:0] DFL_SCALE_Q24 = 32'sd1894981;
    localparam [31:0] SCORE_SCALE_Q31 = 32'd16171270;

    reg [5:0] stride;
    reg [12:0] local_position;
    reg [6:0] grid_x;
    reg [5:0] grid_y;
    reg signed [47:0] base_x_q24, base_y_q24;
    reg signed [47:0] x_min_q24, y_min_q24, x_max_q24, y_max_q24;
    reg [15:0] x_min, y_min, x_max, y_max;
    reg [15:0] score_q15;
    reg [47:0] score_product;

    function automatic [15:0] clip_round_x(input signed [47:0] value);
        reg signed [47:0] rounded;
        begin
            rounded = (value + 48'sd8388608) >>> 24;
            if (value <= 0)
                clip_round_x = 16'd0;
            else if (rounded >= 640)
                clip_round_x = 16'd640;
            else
                clip_round_x = rounded[15:0];
        end
    endfunction

    function automatic [15:0] clip_round_y(input signed [47:0] value);
        reg signed [47:0] rounded;
        begin
            rounded = (value + 48'sd8388608) >>> 24;
            if (value <= 0)
                clip_round_y = 16'd0;
            else if (rounded >= 480)
                clip_round_y = 16'd480;
            else
                clip_round_y = rounded[15:0];
        end
    endfunction

    always @* begin
        if (position < 13'd4800) begin
            local_position = position;
            stride = 6'd8;
        end else if (position < 13'd6000) begin
            local_position = position - 13'd4800;
            stride = 6'd16;
        end else begin
            local_position = position - 13'd6000;
            stride = 6'd32;
        end
        // Constant divisors permit strength reduction by synthesis; a
        // variable divider on the location path is prohibitively expensive.
        if (position < 13'd4800) begin
            grid_x = 7'(local_position % 13'd80);
            grid_y = 6'(local_position / 13'd80);
        end else if (position < 13'd6000) begin
            grid_x = 7'(local_position % 13'd40);
            grid_y = 6'(local_position / 13'd40);
        end else begin
            grid_x = 7'(local_position % 13'd20);
            grid_y = 6'(local_position / 13'd20);
        end
        base_x_q24 = ($signed({1'b0, grid_x}) * $signed({1'b0, stride}) +
                      $signed({1'b0, stride}) / 2) <<< 24;
        base_y_q24 = ($signed({1'b0, grid_y}) * $signed({1'b0, stride}) +
                      $signed({1'b0, stride}) / 2) <<< 24;
        x_min_q24 = base_x_q24 -
            $signed(distance_left) * $signed({1'b0, stride}) * DFL_SCALE_Q24;
        y_min_q24 = base_y_q24 -
            $signed(distance_top) * $signed({1'b0, stride}) * DFL_SCALE_Q24;
        x_max_q24 = base_x_q24 +
            $signed(distance_right) * $signed({1'b0, stride}) * DFL_SCALE_Q24;
        y_max_q24 = base_y_q24 +
            $signed(distance_bottom) * $signed({1'b0, stride}) * DFL_SCALE_Q24;
        x_min = clip_round_x(x_min_q24);
        y_min = clip_round_y(y_min_q24);
        x_max = clip_round_x(x_max_q24);
        y_max = clip_round_y(y_max_q24);
        score_product = score_i8 * SCORE_SCALE_Q31;
        score_q15 = 16'((score_product + 48'd32768) >> 16);
    end

    assign candidate = {
        28'd0, position, class_id, score_q15,
        y_max, x_max, y_min, x_min
    };
endmodule
