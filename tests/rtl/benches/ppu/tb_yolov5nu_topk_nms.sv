`timescale 1ns/1ps

module tb_yolov5nu_topk_nms;
    logic clk = 0;
    always #5 clk = ~clk;
    logic resetn = 0, start = 0, candidate_valid = 0;
    logic [127:0] candidate_data = 0;
    logic candidate_ready, candidates_finished = 0;
    logic [127:0] result_data;
    logic result_valid, result_ready = 1, result_last, busy, done;
    logic [15:0] candidates_seen;
    logic [8:0] retained_count;
    logic [5:0] result_count;

    wire sort_active, nms_active;
    yolov5nu_topk_nms #(.CAPACITY(4), .RESULT_LIMIT(3)) dut (.*);

    function automatic [127:0] pack(input int index, input int cls,
                                    input int score, input int x0,
                                    input int y0, input int x1, input int y1);
        pack = {28'd0, 13'(index), 7'(cls), 16'(score),
                16'(y1), 16'(x1), 16'(y0), 16'(x0)};
    endfunction

    task automatic submit(input [127:0] value);
        while (!candidate_ready) @(negedge clk);
        candidate_data = value;
        candidate_valid = 1;
        @(negedge clk);
        candidate_valid = 0;
    endtask

    int received;
    always @(posedge clk) if (result_valid && result_ready) begin
        case (received)
        0: if (result_data[99:87] != 13'd2) $fatal(1, "best candidate");
        1: if (result_data[99:87] != 13'd4) $fatal(1, "tie by location");
        2: if (result_data[99:87] != 13'd5) $fatal(1, "class-aware NMS");
        default: $fatal(1, "too many results");
        endcase
        received <= received + 1;
    end

    initial begin
        repeat (4) @(negedge clk);
        resetn = 1;
        start = 1;
        @(negedge clk);
        start = 0;
        // Capacity overflow evicts the lowest score.  Equal scores use
        // ascending original location, independent of class identity.
        submit(pack(1, 5, 200, 1, 1, 41, 41));
        submit(pack(2, 5, 400, 1, 1, 41, 41));
        submit(pack(3, 5, 300, 2, 2, 42, 42)); // suppressed by 2
        submit(pack(5, 8, 250, 2, 2, 42, 42)); // other class
        submit(pack(4, 9, 300, 200, 200, 230, 230));
        // A still lower candidate cannot displace a retained member.
        submit(pack(6, 0, 100, 0, 0, 5, 5));
        while (!candidate_ready) @(negedge clk);
        candidates_finished = 1;
        @(negedge clk);
        candidates_finished = 0;
        wait(done);
        if (received != 3 || candidates_seen != 6 || retained_count != 4 ||
            result_count != 3) $fatal(1, "result counters");
        $display("yolov5nu TopK/NMS PASS");
        $finish;
    end

    initial begin
        repeat (5000) @(posedge clk);
        $display("state=%d heap=%d sort=%d hole=%d pick=%d scan=%d received=%d", dut.state, dut.heap_size, dut.sort_size, dut.hole, dut.nms_pick, dut.nms_scan, received);
        $fatal(1, "timeout");
    end
endmodule
