`timescale 1ns/1ps

module tb_yolov5nu_image025_postprocess;
    logic clk = 0;
    always #5 clk = ~clk;
    logic resetn = 0, start = 0, candidate_valid = 0;
    logic [59:0] vectors [0:9];
    logic [59:0] entry = 0;
    wire [127:0] candidate_data;
    wire candidate_ready;
    logic candidates_finished = 0;
    wire [127:0] result_data;
    wire result_valid, result_last, busy, done;
    wire [15:0] candidates_seen;
    wire [8:0] retained_count;
    wire [5:0] result_count;
    int results;

    yolov5nu_bbox_decoder decoder (
        .position(entry[59:47]), .class_id(entry[46:40]),
        .score_i8(entry[39:32]),
        .distance_left(entry[7:0]), .distance_top(entry[15:8]),
        .distance_right(entry[23:16]), .distance_bottom(entry[31:24]),
        .candidate(candidate_data)
    );
    yolov5nu_topk_nms #(.RESULT_LIMIT(10)) nms (
        .clk(clk), .resetn(resetn), .start(start),
        .candidate_data(candidate_data), .candidate_valid(candidate_valid),
        .candidate_ready(candidate_ready),
        .candidates_finished(candidates_finished),
        .result_data(result_data), .result_valid(result_valid),
        .result_ready(1'b1), .result_last(result_last),
        .busy(busy), .done(done), .candidates_seen(candidates_seen),
        .retained_count(retained_count), .result_count(result_count)
    );

    always @(posedge clk) if (result_valid) begin
        results <= results + 1;
        if (results != 0 || result_data[99:87] != 13'd6155 ||
            result_data[86:80] != 7'd23 ||
            result_data[79:64] < 16'd28000 ||
            result_data[15:0] != 16'd388 ||
            result_data[31:16] != 16'd95 ||
            result_data[47:32] != 16'd601 ||
            result_data[63:48] != 16'd385)
            $fatal(1, "image025 dog detection mismatch: %h", result_data);
    end

    initial begin
        $readmemh("candidates.mem", vectors);
        repeat (4) @(negedge clk);
        resetn = 1;
        start = 1;
        @(negedge clk);
        start = 0;
        for (int pos=0; pos<10; pos++) begin
            while (!candidate_ready) @(negedge clk);
            entry = vectors[pos];
            candidate_valid = 1;
            @(negedge clk);
            candidate_valid = 0;
        end
        while (!candidate_ready) @(negedge clk);
        candidates_finished = 1;
        @(negedge clk);
        candidates_finished = 0;
        wait(done);
        if (results != 1 || result_count != 1 || candidates_seen != 10)
            $fatal(1, "image025 result count mismatch: %d", results);
        $display("yolov5nu image025 bbox/TopK/NMS PASS");
        $finish;
    end

    initial begin
        repeat (20000) @(posedge clk);
        $fatal(1, "timeout");
    end
endmodule
