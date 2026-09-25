`timescale 1ns/1ps
// Producer control bank. Commands use bank+version; flags are one-cycle pulses.
module ppu_publication_csr (
    input wire clk,resetn,write_valid,
    input wire [9:0] write_addr,read_addr,
    input wire [31:0] write_data,
    input wire [3:0] write_strb,
    output reg read_hit,
    output reg [31:0] read_data,
    output reg enable,
    output reg [1:0] bank,
    output reg [31:0] version,
    output reg allocate,publish,abort_slot,manual_release,
    output reg [5:0] publish_mask,
    input wire [3:0] allocated,reading,fault,
    input wire [127:0] versions,
    input wire [23:0] ready_heads,producer_heads,
    input wire [31:0] rejected_commands,clean_cycles,clean_lines,
    input wire clean_active,command_busy
);
    always @(posedge clk) begin
        if(!resetn) begin enable<=0;bank<=0;version<=0;allocate<=0;publish<=0;abort_slot<=0;manual_release<=0;publish_mask<=0;end
        else begin
            allocate<=0;publish<=0;abort_slot<=0;manual_release<=0;
            if(write_valid) case(write_addr)
            10'h1a4:if(write_strb[0] && allocated==0 && !clean_active) enable<=write_data[0];
            10'h1a8:if(write_strb[0]) bank<=write_data[1:0];
            10'h1ac:for(integer i=0;i<4;i=i+1) if(write_strb[i]) version[i*8+:8]<=write_data[i*8+:8];
            10'h1b0:begin
                if(write_strb[0]) begin allocate<=write_data[0] && enable;abort_slot<=write_data[2] && enable;
                    manual_release<=write_data[1] && enable && !command_busy;end
                if(write_strb[1]) begin publish<=|write_data[13:8] && enable;publish_mask<=write_data[13:8];end
            end
            endcase
        end
    end
    always @* begin
        read_hit=1;read_data=0;
        case(read_addr)
        10'h1a0:read_data=32'h50505532;
        10'h1a4:read_data={31'd0,enable};
        10'h1a8:read_data={30'd0,bank};
        10'h1ac:read_data=version;
        10'h1b4:read_data={28'd0,clean_active,fault[bank],reading[bank],allocated[bank]};
        10'h1b8:read_data={18'd0,producer_heads[bank*6+:6],2'd0,ready_heads[bank*6+:6]};
        10'h1bc:read_data=versions[bank*32+:32];
        10'h1d4:read_data=rejected_commands;
        10'h1d8:read_data=clean_cycles;
        10'h1dc:read_data=clean_lines;
        default:read_hit=0;
        endcase
    end
endmodule
