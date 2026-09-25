`timescale 1ns/1ps
module tb_yolov5nu_probability_pipeline;
    reg clk=0;always #5 clk=~clk;
    reg resetn=0,in_valid=0;
    reg [24:0] exponent;
    reg [29:0] total;
    reg [3:0] in_bin;
    wire out_valid;
    wire [3:0] out_bin;
    wire [7:0] probability;
    reg [7:0] expected[0:4095];
    integer sent=0,received=0;
    yolov5nu_probability_pipeline dut(.*);
    always @(posedge clk) if(resetn && out_valid) begin
        if(probability!==expected[received] || out_bin!==4'(received))
            $fatal(1,"probability mismatch n=%0d got=%0d expected=%0d",received,probability,expected[received]);
        received=received+1;
    end
    initial begin
        reg [63:0] numerator,whole,fraction;
        repeat(3) @(negedge clk);resetn=1;
        for(integer i=0;i<4096;i=i+1) begin
            if(i%5==0) begin in_valid=0;@(negedge clk);end
            exponent=25'($urandom_range(0,16777216));
            total=30'(exponent)+30'($urandom_range(1,200000000));
            case(i)
            0:begin exponent=1;total=2;end
            1:begin exponent=1;total=254;end
            2:begin exponent=3;total=254;end
            3:begin exponent=16777216;total=16777216;end
            endcase
            numerator=64'(exponent)*127;whole=numerator/total;fraction=numerator%total;
            if(2*fraction>total || (2*fraction==total && whole[0])) whole=whole+1;
            expected[i]=whole>127?8'd127:8'(whole);
            in_valid=1;in_bin=4'(i);sent=sent+1;@(negedge clk);
        end
        in_valid=0;wait(received==4096);
        $display("PROBABILITY_PIPELINE=PASS cases=4096 nearest_even=PASS");$finish;
    end
    initial begin repeat(10000) @(posedge clk);$fatal(1,"probability timeout");end
endmodule
