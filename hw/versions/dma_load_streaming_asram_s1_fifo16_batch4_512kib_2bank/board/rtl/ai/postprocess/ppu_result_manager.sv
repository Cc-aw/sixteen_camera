`timescale 1ns/1ps
// Validates stream/frame/version at the actual overlay handshake. Admission
// updates can supersede a record even while the overlay is backpressured.
module ppu_result_manager(
 input wire clk,resetn,
 input wire expect_valid,input wire [3:0] expect_stream,
 input wire [63:0] expect_frame,input wire [31:0] expect_version,
 input wire in_valid,output wire in_ready,input wire [1567:0] in_record,
 output wire observation_valid,input wire observation_ready,output wire [1567:0] observation_record,
 output wire overlay_valid,input wire overlay_ready,
 output wire [3:0] overlay_stream,overlay_count,
 output reg [511:0] overlay_boxes,output reg [1023:0] overlay_labels,
 output reg [31:0] published,stale
);
 reg [63:0] latest_frame[0:15];reg [31:0] latest_version[0:15];reg [15:0] known;
 reg [1567:0] held;reg [2:0] state;reg [1:0] label_wait;reg [3:0] index;
 wire [3:0] stream=held[1413:1410];
 wire [63:0] frame=held[1477:1414];wire [31:0] version=held[1509:1478];
 wire accept_expect=expect_valid && (!known[expect_stream] || expect_frame>latest_frame[expect_stream] ||
    (expect_frame==latest_frame[expect_stream] && $signed(expect_version-latest_version[expect_stream])>=0));
 wire superseded=accept_expect && expect_stream==stream && (expect_frame!=frame || expect_version!=version);
 wire fresh=known[stream] && latest_frame[stream]==frame && latest_version[stream]==version && !superseded;
 wire bad=held[1375:1344]!=0 || !fresh;
 reg [127:0] box;
 wire [127:0] label;
 ppu_overlay_label u_label(.clk(clk),.class_id({1'b0,box[86:80]}),.score(box[79:64]),.label(label));
 function automatic [10:0] mapped(input [15:0] value,input vertical,ceil_value);
  reg [15:0] clipped;reg [19:0] scaled;reg [10:0] origin;
  begin
   clipped=$signed(value)<0?0:(value>(vertical?480:640)?(vertical?480:640):value);
   scaled=(clipped<<3)+clipped+(ceil_value?15:0);
   origin=vertical?({9'd0,stream[3:2]}*270):({9'd0,stream[1:0]}*480+60);
   mapped=origin+(scaled>>4);
  end
 endfunction
 assign in_ready=state==0;
 assign overlay_stream=stream;
 assign overlay_count=held[1285:1280]>8?8:held[1283:1280];
 // Reserve observation capacity before publishing; never repeat an overlay.
 assign overlay_valid=state==2 && !bad && observation_ready;
 assign observation_valid=state==2 && observation_ready && (bad || overlay_ready);
 assign observation_record=bad ? (held | (1568'd2<<1344)) : held;
 always @(posedge clk) begin
  if(!resetn) begin state<=0;known<=0;held<=0;index<=0;box<=0;label_wait<=0;overlay_boxes<=0;overlay_labels<=0;published<=0;stale<=0;end
  else begin
   if(accept_expect) begin known[expect_stream]<=1;latest_frame[expect_stream]<=expect_frame;latest_version[expect_stream]<=expect_version;end
   case(state)
   0:if(in_valid) begin held<=in_record;index<=0;overlay_boxes<=0;overlay_labels<=0;state<=1;end
   1:begin box<=held[index[2:0]*128+:128];label_wait<=0;state<=3;end
   3:if(label_wait==2) state<=4;else label_wait<=label_wait+1'b1;
   4:begin
    overlay_boxes[index*64+:64]<={12'd0,{1'b0,box[86:80]},mapped(box[63:48],1,1),mapped(box[47:32],0,1),mapped(box[31:16],1,0),mapped(box[15:0],0,0)};
    overlay_labels[index*128+:128]<=label;
    if(index==7) state<=2;else begin index<=index+1'b1;state<=1;end
   end
   2:if(observation_valid && observation_ready) begin
    if(bad) stale<=stale+1'b1;else published<=published+1'b1;
    state<=0;
   end
   endcase
  end
 end
endmodule
