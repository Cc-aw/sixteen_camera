`timescale 1ns/1ps
module tb_ppu_descriptor_fifo;
 reg clk=0;always #5 clk=~clk;
 reg resetn=0,enable=0,enqueue=0,engine_busy=0,engine_done=0,completion_ready=0;
 reg [363:0] descriptor=0;
 wire admission_ready,request,completion_valid,active;wire [2:0] queued;
 wire [31:0] rejected;wire [363:0] active_descriptor;
 ppu_command_queue dut(.*);
 task submit(input integer id);
  @(negedge clk);enqueue=1;descriptor=id;
  @(negedge clk);enqueue=0;
 endtask
 initial begin
  repeat(3) @(negedge clk);resetn=1;
  for(integer i=1;i<=4;i=i+1) submit(i);
  if(admission_ready||queued!=4) $fatal(1,"FIFO capacity");
  submit(99);if(rejected!=1||queued!=4) $fatal(1,"full must reject, never overwrite");
  enable=1;
  for(integer i=1;i<=4;i=i+1) begin
   wait(request);@(negedge clk);if(active_descriptor!=i) $fatal(1,"FIFO order/metadata");
   engine_busy=1;engine_done=0;repeat(i*3) @(negedge clk);
   engine_busy=0;engine_done=1;wait(completion_valid);
   repeat(15) begin @(negedge clk);if(!completion_valid||active_descriptor!=i||request) $fatal(1,"completion backpressure");end
   completion_ready=1;@(negedge clk);completion_ready=0;
  end
  repeat(5) @(negedge clk);if(active||queued) $fatal(1,"drain failed");
  enable=0;submit(7);resetn=0;@(negedge clk);resetn=1;
  if(queued||active||rejected) $fatal(1,"reset");
  $display("PPU_DESCRIPTOR_FIFO=PASS four_tasks full slow_producer slow_consumer reset");$finish;
 end
 initial begin repeat(1000) @(posedge clk);$fatal(1,"queue timeout");end
endmodule
