`timescale 1ns/1ps
module tb_ppu_overlay_label;
 reg clk=0;always #5 clk=~clk;
 reg [7:0] class_id=255;reg [15:0] score=0;wire [127:0] label;
 reg [127:0] expected[0:65535];reg [1023:0] filename;
 ppu_overlay_label dut(.*);
 initial begin
  if(!$value$plusargs("GOLDEN=%s",filename)) $fatal(1,"missing label golden");
  $readmemh(filename,expected);
  for(integer i=0;i<65536;i=i+1) begin
   @(negedge clk);score=i;class_id=i%81;
   repeat(3) @(negedge clk);
   if(label!==expected[i]) $fatal(1,"label mismatch class=%0d score=%0d actual=%h expected=%h",class_id,score,label,expected[i]);
  end
  $display("PPU_OVERLAY_LABEL=PASS scores=65536 classes=80+unknown");$finish;
 end
endmodule
