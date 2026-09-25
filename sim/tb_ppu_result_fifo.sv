`timescale 1ns/1ps
module tb_ppu_result_fifo;
 reg clk=0;always #5 clk=~clk;
 reg resetn=0,completion_valid=0,error=0,write_valid=0,admission_valid=0,overlay_ready=0;
 reg [363:0] descriptor=0;reg [5:0] result_count=1;reg [31:0] cycles=1234;
 wire completion_ready;wire [4:0] result_index;
 reg [127:0] result_word={28'd0,13'd7,7'd0,16'd16384,16'd480,16'd640,16'd0,16'd0};
 reg [9:0] write_addr=0,read_addr=0;reg [31:0] write_data=0;reg [3:0] write_strb=15;
 wire read_hit;wire [31:0] read_data;reg [3:0] configured_stream=5;
 reg [63:0] configured_frame=100;reg [31:0] configured_version=1;
 wire overlay_valid;wire [3:0] overlay_stream,overlay_count;wire [511:0] overlay_boxes;wire [1023:0] overlay_labels;
 integer commits=0;
 ppu_result_path dut(.*);
 always @(posedge clk) if(overlay_valid&&overlay_ready) begin
  commits<=commits+1;
  if(overlay_stream!=5) $fatal(1,"stream");
  if(overlay_count!=0) begin
   if(overlay_boxes[10:0]!=(540+result_word[15:0]*9/16)||overlay_boxes[21:11]!=(270+result_word[31:16]*9/16)||
      overlay_boxes[32:22]!=(540+(result_word[47:32]*9+15)/16)||overlay_boxes[43:33]!=(270+(result_word[63:48]*9+15)/16)) $fatal(1,"mosaic coordinates");
   if(overlay_labels[79:0]!=80'h253035206e6f73726570) $fatal(1,"label/score %h",overlay_labels[127:0]);
  end
 end
 task submit(input integer frame,count);
  @(negedge clk);configured_frame=frame;configured_version=frame;admission_valid=1;
  descriptor=0;descriptor[235:232]=5;descriptor[299:236]=frame;descriptor[331:300]=frame;
  result_count=count;completion_valid=1;
  @(negedge clk);admission_valid=0;
  wait(completion_ready);@(negedge clk);completion_valid=0;
  repeat(3) @(negedge clk);
 endtask
 task pop;
  @(negedge clk);write_valid=1;write_addr='h24c;write_data=1;
  @(negedge clk);write_valid=0;
 endtask
 initial begin
  repeat(3) @(negedge clk);resetn=1;
  submit(100,1);wait(overlay_valid);repeat(80) @(negedge clk);
  if(commits) $fatal(1,"overlay must honor backpressure");
  // Supersede while the overlay is blocked: no stale commit may escape.
  admission_valid=1;configured_frame=101;configured_version=101;
  @(negedge clk);admission_valid=0;overlay_ready=1;
  repeat(80) @(negedge clk);read_addr='h254;#1;if(read_data[17:14]!=2||commits!=0) $fatal(1,"stale result leaked");pop();
  submit(102,1);repeat(100) @(negedge clk);submit(103,0);repeat(100) @(negedge clk);submit(104,10);repeat(100) @(negedge clk);submit(105,1);
  repeat(100) @(negedge clk);
  if(dut.cpu_count!=4||commits!=4) $fatal(1,"four observations/commits %0d %0d",dut.cpu_count,commits);
  submit(106,1);submit(107,1);submit(108,1);submit(109,1);submit(110,1);
  repeat(100) @(negedge clk);
  if(dut.fifo_count!=4||dut.cpu_count!=4) $fatal(1,"CPU slow must fill without overwrite");
  read_addr='h258;#1;if(read_data!=102) $fatal(1,"oldest observation overwritten");
  for(integer i=0;i<10;i=i+1) begin pop();repeat(100) @(negedge clk);end
  if(dut.fifo_count!=0||dut.cpu_count!=0) $fatal(1,"FIFO deadlock");
  resetn=0;@(negedge clk);resetn=1;repeat(2) @(negedge clk);
  if(dut.cpu_count||dut.fifo_count||overlay_valid) $fatal(1,"reset");
  overlay_ready=0;submit(200,1);wait(overlay_valid);
  @(negedge clk);configured_frame=200;configured_version=201;admission_valid=1;
  @(negedge clk);admission_valid=0;overlay_ready=1;
  repeat(100) @(negedge clk);read_addr='h254;#1;if(read_data[17:14]!=2) $fatal(1,"same-frame version mismatch");pop();
  overlay_ready=0;result_word[63:0]={16'd19,16'd19,16'd17,16'd17};submit(202,1);wait(overlay_valid);
  @(negedge clk);configured_frame=201;configured_version=999;admission_valid=1;
  @(negedge clk);admission_valid=0;overlay_ready=1;
  repeat(100) @(negedge clk);read_addr='h254;#1;if(read_data[17:14]!=0) $fatal(1,"older frame displaced newer expectation");pop();
  $display("PPU_RESULT_FIFO=PASS multi zero full CPU_slow overlay_slow stale reset");$finish;
 end
 initial begin repeat(6000) @(posedge clk);$fatal(1,"result timeout");end
endmodule
