`timescale 1ns/1ps

module tb_yolov5nu_dfl_decoder;
    reg clk = 0;
    always #5 clk=~clk;
    reg resetn=0, start=0;
    reg [1:0] head=0;
    reg [511:0] logits=0;
    wire busy, valid;
    wire [31:0] distances;
    yolov5nu_dfl_decoder dut (
        .clk(clk), .resetn(resetn), .start(start), .head(head),
        .logits(logits), .busy(busy), .valid(valid),
        .ready(1'b1), .distances(distances)
    );
    initial begin
        repeat (3) @(negedge clk);
        resetn=1;
        start=1;
        @(negedge clk);
        start=0;
        wait(valid);
        // Uniform logits: 16 probabilities are each round(127/16)=8.
        // The quantized DFL convolution sums to 8*1016=8128.
        if (distances !== 32'h43434343)
            $fatal(1, "uniform DFL mismatch %h", distances);
        $display("yolov5nu DFL uniform PASS");
        $finish;
    end
    initial begin
        repeat (1000) @(posedge clk);
        $fatal(1, "timeout");
    end
endmodule
