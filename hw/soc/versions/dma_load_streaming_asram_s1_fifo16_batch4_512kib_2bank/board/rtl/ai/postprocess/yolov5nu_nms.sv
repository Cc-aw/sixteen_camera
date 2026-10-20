`timescale 1ns/1ps
// Accepts an already sorted, bounded candidate stream. No second Top-K pass.
module yolov5nu_nms #(parameter integer CAPACITY=256, RESULT_LIMIT=10)(
    input wire clk, resetn, start,
    input wire [159:0] candidate_data,
    input wire candidate_valid, candidates_finished,
    output wire candidate_ready,
    output reg [127:0] result_data,
    output reg result_valid, result_last,
    input wire result_ready,
    output reg busy, done,
    output wire nms_active,
    output reg [8:0] retained_count,
    output reg [5:0] result_count
);
    localparam [3:0] ST_IDLE=0,ST_COLLECT=1,ST_NMS_PICK=2,ST_NMS_OUTPUT=3,
        ST_NMS_SCAN=4,ST_NMS_DRAIN=5,ST_DONE=6;
    reg [3:0] state;
    reg [159:0] entries [0:CAPACITY-1];
    reg [CAPACITY-1:0] suppressed;
    reg [8:0] nms_pick,nms_scan;
    reg [159:0] selected,scan_entry;
    reg compare_launch;
    reg [8:0] compare_index;
    wire compare_busy,compare_valid,compare_suppress;
    wire [8:0] compare_result_index;
    yolov5nu_iou_pipeline u_compare(
        .clk(clk),.resetn(resetn),.in_valid(compare_launch),
        .selected(selected[127:0]),.candidate(scan_entry[127:0]),
        .selected_area(selected[159:128]),.candidate_area(scan_entry[159:128]),
        .in_index(compare_index),.busy(compare_busy),.out_valid(compare_valid),
        .out_index(compare_result_index),.suppress(compare_suppress)
    );
    assign candidate_ready=state==ST_COLLECT && retained_count<CAPACITY;
    assign nms_active=state!=ST_IDLE && state!=ST_COLLECT && state!=ST_DONE;
    always @(posedge clk) begin
        if(!resetn) begin
            state<=ST_IDLE; result_valid<=0; result_last<=0; busy<=0;
            done<=0; compare_launch<=0; retained_count<=0; result_count<=0; suppressed<=0;
        end else begin
            done<=0; compare_launch<=0;
            if(compare_valid && compare_suppress) suppressed[compare_result_index]<=1;
            case(state)
            ST_IDLE: if(start) begin
                state<=ST_COLLECT; result_valid<=0; result_last<=0; busy<=1;
                retained_count<=0; result_count<=0; suppressed<=0;
            end
            ST_COLLECT: begin
                if(candidate_valid && candidate_ready) begin
                    entries[retained_count]<=candidate_data;
                    retained_count<=retained_count+1'b1;
                end
                if(candidates_finished) begin nms_pick<=0; state<=ST_NMS_PICK; end
            end
            ST_NMS_PICK: begin
                if (nms_pick >= retained_count ||
                    result_count >= RESULT_LIMIT) begin
                    state <= ST_DONE;
                end else if (suppressed[nms_pick]) begin
                    nms_pick <= nms_pick + 1'b1;
                end else begin
                    selected <= entries[nms_pick];
                    result_data <= entries[nms_pick][127:0];
                    result_valid <= 1'b1;
                    result_last <= result_count == RESULT_LIMIT-1 ||
                                   nms_pick == retained_count-1;
                    state <= ST_NMS_OUTPUT;
                end
            end
            ST_NMS_OUTPUT: begin
                if (result_valid && result_ready) begin
                    result_valid <= 1'b0;
                    result_count <= result_count + 1'b1;
                    nms_scan <= nms_pick + 1'b1;
                    if (result_count + 1'b1 >= RESULT_LIMIT ||
                        nms_pick + 1'b1 >= retained_count) begin
                        state <= ST_DONE;
                    end else begin
                        state <= ST_NMS_SCAN;
                    end
                end
            end
            ST_NMS_SCAN: begin
                if(nms_scan>=retained_count) state<=ST_NMS_DRAIN;
                else begin
                    scan_entry<=entries[nms_scan];compare_index<=nms_scan;
                    compare_launch<=1;nms_scan<=nms_scan+1'b1;
                end
            end
            ST_NMS_DRAIN: if(!compare_busy && !compare_launch) begin
                nms_pick<=nms_pick+1'b1;state<=ST_NMS_PICK;
            end
            ST_DONE: begin
                busy <= 1'b0;
                done <= 1'b1;
                state <= ST_IDLE;
            end
            default: state<=ST_IDLE;
            endcase
        end
    end
endmodule
