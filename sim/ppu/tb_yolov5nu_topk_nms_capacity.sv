`timescale 1ns/1ps

module tb_yolov5nu_topk_nms_capacity;
    logic clk = 0;
    always #5 clk = ~clk;
    logic resetn = 0, start = 0, candidate_valid = 0;
    logic [127:0] candidate_data = 0;
    wire candidate_ready;
    logic candidates_finished = 0;
    wire [127:0] result_data;
    wire result_valid, result_last, busy, done;
    logic result_ready = 1;
    wire [15:0] candidates_seen;
    wire [8:0] retained_count;
    wire [5:0] result_count;
    integer received = 0;

    wire sort_active, nms_active;
    yolov5nu_topk_nms #(.CAPACITY(256), .RESULT_LIMIT(10)) dut (.*);

    always @(posedge clk) if (result_valid && result_ready) begin
        if (result_data[99:87] !== 13'(299-received) ||
            result_data[79:64] !== 16'(300-received))
            $fatal(1, "wrong sorted result %0d: index=%0d score=%0d",
                   received, result_data[99:87], result_data[79:64]);
        received <= received + 1;
    end

    initial begin
        repeat (4) @(negedge clk);
        resetn = 1;
        start = 1;
        @(negedge clk);
        start = 0;
        for (integer i = 0; i < 300; i = i + 1) begin
            while (!candidate_ready) @(negedge clk);
            // Zero-area boxes avoid NMS suppression and expose TopK ordering.
            candidate_data = {28'd0, 13'(i), 7'd0, 16'(i+1), 64'd0};
            candidate_valid = 1;
            @(negedge clk);
            candidate_valid = 0;
        end
        while (!candidate_ready) @(negedge clk);
        candidates_finished = 1;
        @(negedge clk);
        candidates_finished = 0;
        wait(done);
        if (received != 10 || candidates_seen != 300 ||
            retained_count != 256 || result_count != 10)
            $fatal(1, "wrong counters results=%0d seen=%0d retained=%0d",
                   received, candidates_seen, retained_count);
        $display("yolov5nu TopK/NMS capacity PASS");
        $finish;
    end

    initial begin
        repeat (200000) @(posedge clk);
        $fatal(1, "capacity test timeout");
    end
endmodule
