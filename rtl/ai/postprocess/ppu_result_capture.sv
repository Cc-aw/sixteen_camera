`timescale 1ns/1ps
// Snapshot the complete result before allowing the next descriptor to run.
// Record: boxes[1279:0], count[1285:1280], cycles[1343:1312],
// status[1375:1344], descriptor metadata[1541:1376].
module ppu_result_capture(
 input wire clk,resetn,completion_valid,
 output wire completion_ready,
 input wire [363:0] descriptor,
 input wire [5:0] result_count,input wire [31:0] cycles,input wire error,
 output reg [4:0] result_index,input wire [127:0] result_word,
 output wire valid,input wire ready,output reg [1567:0] record
);
 reg [1:0] state;
 assign valid=state==2;
 assign completion_ready=valid&&ready;
 always @(posedge clk) begin
  if(!resetn) begin state<=0;result_index<=0;record<=0;end
  else case(state)
  0:if(completion_valid) begin
   record<=0;record[1285:1280]<=error?0:result_count;
   record[1343:1312]<=cycles;record[1375:1344]<={31'd0,error};
   record[1541:1376]<=descriptor[363:198];result_index<=0;state<=1;
  end
  1:begin
   record[result_index*128+:128]<=error?128'd0:result_word;
   if(result_index==9) state<=2;else result_index<=result_index+1'b1;
  end
  2:if(ready) state<=3;
  3:if(!completion_valid) state<=0;
  endcase
 end
endmodule
