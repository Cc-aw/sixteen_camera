`timescale 1ns/1ps
// Input contract: <=256 threshold-qualified candidates in ascending location.
// FIFO append within each score bucket preserves stable location ordering.
module yolov5nu_candidate_buckets (
    input wire clk, resetn, start,
    input wire [159:0] candidate_data,
    input wire [7:0] candidate_score,
    input wire candidate_valid,
    output wire candidate_ready,
    input wire candidates_finished,
    output reg [159:0] sorted_data,
    output wire sorted_valid,
    input wire sorted_ready,
    output reg done, error,
    output wire sort_active,
    output reg [8:0] count
);
    localparam [2:0] IDLE=0,CLEAR=1,COLLECT=2,SCAN=3,FETCH=4,EMIT=5;
    reg [2:0] state;
    reg [7:0] score, cursor;
    reg [159:0] entries [0:255];
    reg [8:0] next_entry [0:255];
    reg [7:0] heads [0:127], tails [0:127];
    reg [127:0] occupied;
    reg [8:0] next_q;
    reg finish_pending;
    reg [12:0] last_location;
    assign candidate_ready = state == COLLECT && !finish_pending;
    assign sorted_valid = state == EMIT;
    assign sort_active = state == SCAN || state == FETCH || state == EMIT;
    always @(posedge clk) begin
        if (!resetn) begin
            state<=IDLE; done<=0; error<=0; count<=0;
            occupied<=0; finish_pending<=0; sorted_data<=0;
        end else begin
            done<=0;
            case(state)
            IDLE: if(start) begin
                state<=CLEAR; score<=0; occupied<=0; count<=0;
                error<=0; finish_pending<=0; last_location<=0;
            end
            CLEAR: begin
                heads[score[6:0]]<=0; tails[score[6:0]]<=0;
                if(score==127) state<=COLLECT;
                else score<=score+1'b1;
            end
            COLLECT: begin
                if(candidates_finished) finish_pending<=1;
                if(candidate_valid && candidate_ready) begin
                    if(count==256 || candidate_score<34 || candidate_score>127 ||
                       (count!=0 && candidate_data[99:87]<=last_location)) error<=1;
                    else begin
                        entries[count[7:0]]<=candidate_data;
                        next_entry[count[7:0]]<=9'd256;
                        if(occupied[candidate_score[6:0]])
                            next_entry[tails[candidate_score[6:0]]]<=count;
                        else heads[candidate_score[6:0]]<=count[7:0];
                        tails[candidate_score[6:0]]<=count[7:0];
                        occupied[candidate_score[6:0]]<=1;
                        last_location<=candidate_data[99:87];
                        count<=count+1'b1;
                    end
                end else if(finish_pending || candidates_finished) begin
                    score<=127; state<=SCAN;
                end
            end
            SCAN: begin
                if(occupied[score[6:0]]) begin
                    cursor<=heads[score[6:0]]; state<=FETCH;
                end else if(score==34) begin done<=1; state<=IDLE; end
                else score<=score-1'b1;
            end
            FETCH: begin
                sorted_data<=entries[cursor]; next_q<=next_entry[cursor]; state<=EMIT;
            end
            EMIT: if(sorted_ready) begin
                if(next_q!=256) begin cursor<=next_q[7:0]; state<=FETCH; end
                else if(score==34) begin done<=1; state<=IDLE; end
                else begin score<=score-1'b1; state<=SCAN; end
            end
            default: state<=IDLE;
            endcase
        end
    end
endmodule
