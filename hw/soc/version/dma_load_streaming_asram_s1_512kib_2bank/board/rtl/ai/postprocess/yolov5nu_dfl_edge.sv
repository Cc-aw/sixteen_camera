`timescale 1ns/1ps
// One exact edge. Four instances run in parallel; each sends one bin per cycle
// through the restoring divider and accumulates exact INT8 probabilities.
module yolov5nu_dfl_edge (
    input wire clk,resetn,start,
    input wire [1:0] head,
    input wire [127:0] logits,
    output wire busy,
    output reg valid,
    input wire ready,
    output reg [7:0] distance_out
);
    localparam [2:0] IDLE=0,MAXIMUM=1,SUM=2,FEED=3,DRAIN=4;
    reg [2:0] state;
    reg [1:0] head_q;
    reg [127:0] logits_q;
    reg [3:0] bin;
    reg signed [7:0] maximum;
    reg [29:0] sum;
    reg [18:0] dot;
    wire signed [7:0] requant;
    wire [24:0] exponent;
    yolov5nu_dfl_lut u_lut(
        .head(head_q),.raw(logits_q[bin*8+:8]),
        .exponent_difference(8'(maximum-requant)),
        .requant(requant),.exponent_q24(exponent));
    wire probability_valid;
    wire [3:0] probability_bin;
    wire [7:0] probability;
    yolov5nu_probability_pipeline u_divider(
        .clk(clk),.resetn(resetn),.in_valid(state==FEED),.exponent(exponent),.total(sum),
        .in_bin(bin),.out_valid(probability_valid),.out_bin(probability_bin),
        .probability(probability));
    function automatic [7:0] weight(input [3:0] index);
        case (index)
        0: weight=0; 1: weight=8; 2: weight=17; 3: weight=25;
        4: weight=34; 5: weight=42; 6: weight=51; 7: weight=59;
        8: weight=68; 9: weight=76; 10: weight=85; 11: weight=93;
        12: weight=102; 13: weight=110; 14: weight=119;
        default: weight=127;
        endcase
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



    assign busy=state!=IDLE;
    wire [18:0] next_dot=dot+probability*weight(probability_bin);
    always @(posedge clk) begin
        if(!resetn) begin
            state<=IDLE;valid<=0;distance_out<=0;bin<=0;maximum<=-8'sd128;sum<=0;dot<=0;
        end else begin
            if(valid && ready) valid<=0;
            case(state)
            IDLE: if(start && (!valid || ready)) begin
                head_q<=head;logits_q<=logits;bin<=0;maximum<=-8'sd128;
                sum<=0;dot<=0;valid<=0;state<=MAXIMUM;
            end
            MAXIMUM: begin
                if(requant>maximum) maximum<=requant;
                bin<=bin+1'b1;if(bin==15) state<=SUM;
            end
            SUM: begin
                sum<=sum+exponent;bin<=bin+1'b1;if(bin==15) state<=FEED;
            end
            FEED: begin bin<=bin+1'b1;if(bin==15) state<=DRAIN;end
            DRAIN: begin end
            default:state<=IDLE;
            endcase
            if(probability_valid) begin
                dot<=next_dot;
                if(probability_bin==15) begin
                    distance_out<=distance(next_dot);valid<=1;state<=IDLE;
                end
            end
        end
    end
endmodule
