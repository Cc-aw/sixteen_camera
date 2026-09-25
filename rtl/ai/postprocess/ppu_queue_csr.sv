`timescale 1ns/1ps
module ppu_queue_csr(
    input wire clk,resetn,write_valid,
    input wire [9:0] write_addr,read_addr,
    input wire [31:0] write_data,input wire [3:0] write_strb,
    input wire admission_ready,active,completion_valid,
    input wire [2:0] queued,input wire [31:0] rejected,
    output reg enable,enqueue,completion_pop,
    output reg [3:0] stream,
    output reg [63:0] frame,
    output reg [31:0] version,flags,
    input wire [363:0] active_descriptor,
    output reg read_hit,output reg [31:0] read_data
);
    always @(posedge clk) begin
        if(!resetn) begin enable<=0;enqueue<=0;completion_pop<=0;stream<=0;frame<=0;version<=0;flags<=0;end
        else begin
            enqueue<=0;completion_pop<=0;
            if(write_valid && write_strb==15) case(write_addr)
            10'h200:if(!active && queued==0) enable<=write_data[0];
            10'h204:begin enqueue<=write_data[0]&&enable;completion_pop<=write_data[1];end
            10'h20c:stream<=write_data[3:0];
            10'h210:frame[31:0]<=write_data;
            10'h214:frame[63:32]<=write_data;
            10'h218:version<=write_data;
            10'h21c:flags<=write_data;
            default:;
            endcase
        end
    end
    always @* begin
        read_hit=1;read_data=0;
        case(read_addr)
        10'h200:read_data={31'd0,enable};
        10'h204:read_data=32'h50505132;
        10'h208:read_data={24'd0,completion_valid,active,admission_ready,2'd0,queued};
        10'h20c:read_data={28'd0,stream};
        10'h210:read_data=frame[31:0];10'h214:read_data=frame[63:32];
        10'h218:read_data=version;10'h21c:read_data=flags;
        10'h220:read_data=rejected;
        10'h224:read_data={26'd0,active_descriptor[199:198],active_descriptor[235:232]};
        10'h228:read_data=active_descriptor[267:236];
        10'h22c:read_data=active_descriptor[299:268];
        10'h230:read_data=active_descriptor[331:300];
        default:read_hit=0;
        endcase
    end
endmodule
