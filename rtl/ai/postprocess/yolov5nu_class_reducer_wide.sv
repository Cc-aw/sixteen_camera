`timescale 1ns/1ps
// One complete beat per cycle. Balanced group reduction is registered before
// the feedback merge, so no 32-lane comparator chain enters the accumulator.
module yolov5nu_class_reducer_wide #(
    parameter integer CLASS_COUNT=80,POSITION_COUNT=6300
)(
    input wire clk,resetn,start,
    input wire signed [7:0] score_threshold,
    input wire [255:0] s_data,
    input wire [31:0] s_keep,
    input wire s_valid,s_last,
    output wire s_ready,
    output reg result_valid,
    input wire result_ready,
    output reg [12:0] result_position,
    output reg [6:0] result_class,
    output reg signed [7:0] result_score,
    output reg result_candidate,result_last,
    output wire compute_active,
    output reg busy,done,error,
    output reg [2:0] error_flags,
    output reg [12:0] positions_seen,candidates_seen
);
    reg [6:0] front_index,best_class;
    reg signed [7:0] best_score;
    reg input_complete,group_valid,group_emits,group_last;
    reg [6:0] group_next_index,group_class,tail_class;
    reg signed [7:0] group_score,tail_score;
    wire [6:0] next_index,next_class,leading_class;
    wire signed [7:0] next_score,leading_score;
    wire emits;
    yolov5nu_class_fold_tree #(.BYTES(32),.CLASSES(CLASS_COUNT)) u_tree(
        .data(s_data),.keep(s_keep),.class_index(front_index),
        .best_class(7'd0),.best_score(-8'sd128),
        .next_index(next_index),.next_class(next_class),.next_score(next_score),
        .result_class(leading_class),.result_score(leading_score),.emits(emits));
    wire can_merge=!result_valid||result_ready;
    assign compute_active=group_valid && can_merge;
    assign s_ready=busy && !input_complete && (!group_valid || can_merge);
    wire take_group=group_score>best_score ||
                    (group_score==best_score && group_class<best_class);
    wire signed [7:0] merged_score=take_group?group_score:best_score;
    wire [6:0] merged_class=take_group?group_class:best_class;
    always @(posedge clk) begin
        if(!resetn) begin
            busy<=0;done<=0;error<=0;error_flags<=0;positions_seen<=0;candidates_seen<=0;
            result_valid<=0;result_last<=0;result_position<=0;result_class<=0;
            result_score<=-8'sd128;result_candidate<=0;
            front_index<=0;best_score<=-8'sd128;best_class<=0;
            input_complete<=0;group_valid<=0;
        end else begin
            done<=0;
            if(result_valid && result_ready) result_valid<=0;
            if(start && !busy) begin
                busy<=1;error<=0;error_flags<=0;positions_seen<=0;candidates_seen<=0;
                front_index<=0;best_score<=-8'sd128;best_class<=0;
                input_complete<=0;group_valid<=0;result_valid<=0;
            end
            if(compute_active) begin
                group_valid<=0;
                best_score<=group_emits?tail_score:merged_score;
                best_class<=group_emits?tail_class:merged_class;
                if(group_emits) begin
                    result_valid<=1;result_position<=positions_seen;
                    result_class<=merged_class;result_score<=merged_score;
                    result_candidate<=merged_score>=score_threshold;
                    result_last<=positions_seen==POSITION_COUNT-1;
                    positions_seen<=positions_seen+1'b1;
                    if(merged_score>=score_threshold) candidates_seen<=candidates_seen+1'b1;
                end
                if(group_last) begin
                    if(!group_emits || group_next_index!=0 || positions_seen!=POSITION_COUNT-1) begin
                        error<=1;error_flags[1]<=1;
                    end
                end else if(group_emits && positions_seen==POSITION_COUNT-1) begin
                    error<=1;error_flags[2]<=1;
                end
            end
            if(s_valid && s_ready) begin
                group_valid<=1;group_emits<=emits;group_last<=s_last;
                group_next_index<=next_index;front_index<=next_index;
                group_class<=leading_class;group_score<=leading_score;
                tail_class<=next_class;tail_score<=next_score;
                if(s_last) input_complete<=1;
                if(s_keep!=32'hffffffff) begin error<=1;error_flags[0]<=1;end
            end
            if(result_valid && result_ready && result_last) begin busy<=0;done<=1;end
        end
    end
endmodule
