`timescale 1ns/1ps

module tb_yolov5nu_dfl_random;
    reg clk=0;
    always #5 clk=~clk;
    reg resetn=0, start=0, ready=0;
    reg [1:0] head=0;
    reg [511:0] logits=0;
    reg [511:0] raw [0:47];
    reg [31:0] expected [0:47];
    wire busy, valid;
    wire [31:0] distances;
    yolov5nu_dfl_decoder dut (
        .clk(clk), .resetn(resetn), .start(start), .head(head),
        .logits(logits), .busy(busy), .valid(valid),
        .ready(ready), .distances(distances)
    );
    initial begin
        $readmemh("dfl_raw.mem", raw);
        $readmemh("dfl_expected.mem", expected);
        repeat (4) @(negedge clk);
        resetn=1;
        for (int trial=0; trial<48; trial++) begin
            while (busy || valid) @(negedge clk);
            ready=0;
            logits=raw[trial];
            head=2'(trial % 3);
            start=1;
            @(negedge clk);
            start=0;
            wait(valid);
            if (distances !== expected[trial])
                $fatal(1, "DFL float32 mismatch trial=%0d head=%0d expected=%h actual=%h",
                       trial, head, expected[trial], distances);
            repeat(5) begin
                @(negedge clk);
                if(!valid || distances!==expected[trial]) $fatal(1,"DFL output changed under backpressure");
            end
            ready=1;
            @(negedge clk);
        end
        $display("yolov5nu DFL float32 comparison PASS: 48 random locations");
        $finish;
    end
    initial begin
        repeat (50000) @(posedge clk);
        $fatal(1, "DFL random timeout");
    end
endmodule
