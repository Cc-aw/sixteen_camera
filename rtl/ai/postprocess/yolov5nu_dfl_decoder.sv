`timescale 1ns/1ps

// One sparse 4x16 location at a time.  The three head scales, model exp
// table, and 16 convolution weights are frozen in the generated LUT.  The
// two-pass softmax preserves the CPU kernel's INT8 probability quantization
// before the weighted sum, including nearest-even rounding.
module yolov5nu_dfl_decoder (
    input wire clk, input wire resetn, input wire start,
    input wire [1:0] head,
    input wire [511:0] logits,
    output wire busy, output reg valid,
    input wire ready,
    output reg [31:0] distances
);
    localparam [2:0] IDLE=0, MAXIMUM=1, SUM=2, DOT_LOAD=3,
                     DIVIDE=4, DOT_STORE=5;
    reg [2:0] state;
    reg [1:0] head_q;
    reg [511:0] logits_q;
    reg [5:0] lane;
    reg signed [7:0] maxima [0:3];
    reg [29:0] sums [0:3];
    reg [18:0] dot [0:3];
    reg [32:0] remainder0, remainder1;
    reg [29:0] divisor;
    reg [6:0] quotient0, quotient1;
    reg [2:0] divisor_bit;
    wire [1:0] edge_idx = lane[5:4];
    wire [3:0] bin = lane[3:0];
    wire signed [7:0] requant;
    wire [24:0] exponent;
    wire [7:0] difference = 8'(maxima[edge_idx] - requant);
    wire signed [7:0] requant1;
    wire [24:0] exponent1;
    wire [7:0] difference1 = 8'(maxima[edge_idx] - requant1);
    yolov5nu_dfl_lut u_lut (
        .head(head_q), .raw(logits_q[lane*8 +: 8]),
        .exponent_difference(difference),
        .requant(requant), .exponent_q24(exponent)
    );
    yolov5nu_dfl_lut u_lut1 (
        .head(head_q), .raw(logits_q[(lane+6'd1)*8 +: 8]),
        .exponent_difference(difference1),
        .requant(requant1), .exponent_q24(exponent1)
    );

    function automatic [7:0] weight(input [3:0] index);
        case (index)
        0: weight=0; 1: weight=8; 2: weight=17; 3: weight=25;
        4: weight=34; 5: weight=42; 6: weight=51; 7: weight=59;
        8: weight=68; 9: weight=76; 10: weight=85; 11: weight=93;
        12: weight=102; 13: weight=110; 14: weight=119;
        default: weight=127;
        endcase
    endfunction

    function automatic [7:0] round_probability(
        input [6:0] whole, input [32:0] fraction,
        input [29:0] total
    );
        reg [7:0] rounded;
        begin
            rounded = {1'b0, whole};
            if (fraction * 2 > {3'b0, total} ||
                (fraction * 2 == {3'b0, total} && whole[0]))
                rounded = rounded + 1'b1;
            round_probability = rounded > 127 ? 8'd127 : rounded;
        end
    endfunction

    function automatic [7:0] distance(input [18:0] weighted);
        reg [43:0] value;
        reg [19:0] rounded;
        begin
            // (1/127)*0.1181102395/0.1129496917, Q24.
            value = weighted * 44'd138140;
            rounded = 20'(value >> 24);
            if (value[23:0] > 24'h800000 ||
                (value[23:0] == 24'h800000 && rounded[0]))
                rounded = rounded + 1'b1;
            distance = rounded > 127 ? 8'd127 : 8'(rounded);
        end
    endfunction

    assign busy = state != IDLE;

    // I: one 512-bit four-edge DFL location and its start/ready handshake.
    // P: process adjacent bins in two parallel lanes while preserving the
    //    original maximum, sum, quotient, and nearest-even operations.
    // O: four 8-bit distances with the original valid/busy timing contract.
    // A: hlk
    // T: 2026-09-22 13:48:30 +0800
    always @(posedge clk) begin
        if (!resetn) begin
            state <= IDLE;
            valid <= 0;
            lane <= 0;
            distances <= 0;
            for (integer e=0; e<4; e=e+1) begin
                maxima[e] <= -8'sd128;
                sums[e] <= 0;
                dot[e] <= 0;
            end
        end else begin
            if (state == IDLE && start) begin
                head_q <= head;
                logits_q <= logits;
                lane <= 0;
                distances <= 0;
                valid <= 0;
                state <= MAXIMUM;
                for (integer e=0; e<4; e=e+1) begin
                    maxima[e] <= -8'sd128;
                    sums[e] <= 0;
                    dot[e] <= 0;
                end
            end else case (state)
            MAXIMUM: begin
                if (requant > maxima[edge_idx]) maxima[edge_idx] <= requant;
                lane <= lane + 1'b1;
                if (lane == 6'd63) state <= SUM;
            end
            SUM: begin
                sums[edge_idx] <= sums[edge_idx] + exponent;
                lane <= lane + 1'b1;
                if (lane == 6'd63) state <= DOT_LOAD;
            end
            DOT_LOAD: begin
                remainder0 <= {8'd0, exponent} * 33'd127;
                remainder1 <= {8'd0, exponent1} * 33'd127;
                divisor <= sums[edge_idx];
                quotient0 <= 0;
                quotient1 <= 0;
                divisor_bit <= 3'd6;
                state <= DIVIDE;
            end
            DIVIDE: begin
                if ({4'd0, remainder0} >=
                    ({7'd0, divisor} << divisor_bit)) begin
                    remainder0 <= 33'({4'd0, remainder0} -
                        ({7'd0, divisor} << divisor_bit));
                    quotient0[divisor_bit] <= 1'b1;
                end
                if ({4'd0, remainder1} >=
                    ({7'd0, divisor} << divisor_bit)) begin
                    remainder1 <= 33'({4'd0, remainder1} -
                        ({7'd0, divisor} << divisor_bit));
                    quotient1[divisor_bit] <= 1'b1;
                end
                if (divisor_bit == 0) state <= DOT_STORE;
                else divisor_bit <= divisor_bit - 1'b1;
            end
            DOT_STORE: begin : accumulate
                reg [18:0] next_dot0;
                reg [18:0] next_dot1;
                next_dot0 = dot[edge_idx] +
                    round_probability(quotient0, remainder0, divisor) *
                    weight(bin);
                next_dot1 = next_dot0 +
                    round_probability(quotient1, remainder1, divisor) *
                    weight(bin + 1'b1);
                dot[edge_idx] <= next_dot1;
                if (bin == 4'd14)
                    distances[edge_idx*8 +: 8] <= distance(next_dot1);
                lane <= lane + 6'd2;
                if (lane == 6'd62) begin
                    valid <= 1;
                    state <= IDLE;
                end else state <= DOT_LOAD;
            end
            default: state <= IDLE;
            endcase
            if (valid && ready) valid <= 0;
        end
    end
endmodule
