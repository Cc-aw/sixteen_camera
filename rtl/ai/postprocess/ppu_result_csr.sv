`timescale 1ns/1ps
module ppu_result_csr(
 input wire clk,resetn,write_valid,input wire [9:0] write_addr,read_addr,
 input wire [31:0] write_data,input wire [3:0] write_strb,
 input wire observation_valid,input wire [1567:0] observation_record,
 output wire observation_pop,input wire [2:0] result_count,observation_count,
 input wire [31:0] published,stale,
 output reg expect_valid,output reg observation_enable,
 output reg read_hit,output reg [31:0] read_data
);
 reg [5:0] index;
 assign observation_pop=write_valid&&write_addr==10'h24c&&write_strb==15&&write_data[0]&&observation_valid;
 always @(posedge clk) begin
  if(!resetn) begin index<=0;expect_valid<=0;observation_enable<=1;end
  else begin
   expect_valid<=write_valid&&write_addr==10'h234&&write_strb==15&&write_data[0];
   if(write_valid&&write_strb==15) begin
    if(write_addr==10'h244 && write_data<49) index<=write_data[5:0];
    if(write_addr==10'h24c && !observation_valid) observation_enable<=!write_data[1];
   end
  end
 end
 always @* begin
  read_hit=1;read_data=0;
  case(read_addr)
  10'h238:read_data=32'h50505232;
  10'h240:read_data={22'd0,observation_enable,result_count,observation_count,2'd0,observation_valid};
  10'h244:read_data={26'd0,index};
  10'h248:read_data=observation_valid?observation_record[index*32+:32]:0;
  10'h250:read_data={30'd0,observation_record[1377:1376]};
  10'h254:read_data={14'd0,observation_record[1347:1344],observation_record[1413:1410],4'd0,observation_record[1285:1280]};
  10'h258:read_data=observation_record[1445:1414];
  10'h25c:read_data=observation_record[1477:1446];
  10'h260:read_data=observation_record[1509:1478];
  10'h264:read_data=observation_record[1343:1312];
  10'h268:read_data=observation_record[1409:1378];
  10'h26c:read_data=published;10'h270:read_data=stale;
  default:read_hit=0;
  endcase
 end
endmodule
