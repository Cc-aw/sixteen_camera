`timescale 1ns/1ps
module yolov5nu_bucket_nms #(parameter integer RESULT_LIMIT=10)(
    input wire clk, resetn, start,
    input wire [127:0] candidate_data,
    input wire [7:0] candidate_score,
    input wire candidate_valid, candidates_finished,
    output wire candidate_ready,
    output wire [127:0] result_data,
    output wire result_valid, result_last,
    input wire result_ready,
    output wire busy, done, error, sort_active, nms_active,
    output wire [15:0] candidates_seen,
    output wire [8:0] retained_count,
    output wire [5:0] result_count
);
    wire [159:0] sorted_data;
    wire [159:0] area_data;
    wire [7:0] area_score;
    wire area_valid,area_ready,area_busy,area_input_ready,bucket_ready;
    reg finish_pending;
    assign candidate_ready=area_input_ready && !finish_pending;
    always @(posedge clk) begin
        if(!resetn || start) finish_pending<=0;
        else if(candidates_finished) finish_pending<=1;
    end
    yolov5nu_candidate_area u_area(
        .clk(clk),.resetn(resetn),.in_valid(candidate_valid && !finish_pending),
        .in_ready(area_input_ready),.in_data(candidate_data),.in_score(candidate_score),
        .out_valid(area_valid),.out_ready(bucket_ready),.out_data(area_data),
        .out_score(area_score),.busy(area_busy)
    );
    wire sorted_valid, sorted_ready, sorted_done;
    wire [8:0] bucket_count;
    assign candidates_seen={7'd0,bucket_count};
    yolov5nu_candidate_buckets u_buckets (
        .clk(clk),.resetn(resetn),.start(start),
        .candidate_data(area_data),.candidate_score(area_score),
        .candidate_valid(area_valid),.candidate_ready(bucket_ready),
        .candidates_finished(finish_pending && !area_busy && bucket_ready),
        .sorted_data(sorted_data),.sorted_valid(sorted_valid),.sorted_ready(sorted_ready),
        .done(sorted_done),.error(error),.sort_active(sort_active),.count(bucket_count)
    );
    yolov5nu_nms #(.RESULT_LIMIT(RESULT_LIMIT)) u_nms (
        .clk(clk),.resetn(resetn),.start(start),
        .candidate_data(sorted_data),.candidate_valid(sorted_valid),
        .candidate_ready(sorted_ready),.candidates_finished(sorted_done),
        .result_data(result_data),.result_valid(result_valid),.result_ready(result_ready),
        .result_last(result_last),.busy(busy),.done(done),.nms_active(nms_active),
        .retained_count(retained_count),.result_count(result_count)
    );
endmodule
