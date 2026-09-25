`timescale 1ns/1ps
// L2 Flush64 writes are completion-bearing: InclusiveCacheControl does not
// acknowledge them until io_flush_resp. Therefore each B commits one cache line
// to the downstream Head store. WLAST alone never publishes a line.
module ppu_cache_publish_engine #(
    parameter integer TIMEOUT_CYCLES=16777216
)(
    input wire clk,resetn,start,abort,
    input wire [32:0] base,
    input wire [31:0] bytes,
    output wire busy,
    output reg done,error,
    output reg [31:0] cycles,lines_completed,
    axi4_if.master m_axi
);
    localparam [1:0] IDLE=0,AW=1,W=2,B=3;
    reg [1:0] state;
    reg [32:0] line_addr;
    reg [33:0] end_addr;
    reg cancelled;
    reg [31:0] wait_cycles;
    assign busy=state!=IDLE;
    assign m_axi.aclk=clk;assign m_axi.aresetn=resetn;
    assign m_axi.awid=0;assign m_axi.awaddr=33'h002010200;
    assign m_axi.awlen=0;assign m_axi.awsize=3;assign m_axi.awburst=1;
    assign m_axi.awlock=0;assign m_axi.awcache=0;assign m_axi.awprot=0;assign m_axi.awqos=0;
    assign m_axi.awvalid=state==AW;
    assign m_axi.wdata={223'd0,line_addr};assign m_axi.wstrb=32'hff;
    assign m_axi.wlast=1;assign m_axi.wvalid=state==W;
    assign m_axi.bready=state==B;
    assign m_axi.arid=0;assign m_axi.araddr=0;assign m_axi.arlen=0;
    assign m_axi.arsize=0;assign m_axi.arburst=0;assign m_axi.arlock=0;
    assign m_axi.arcache=0;assign m_axi.arprot=0;assign m_axi.arqos=0;
    assign m_axi.arvalid=0;assign m_axi.rready=1;
    always @(posedge clk) begin
        if(!resetn) begin state<=IDLE;done<=0;error<=0;cancelled<=0;cycles<=0;lines_completed<=0;wait_cycles<=0;end
        else begin
            done<=0;
            if(busy) begin
                cycles<=cycles+1'b1;
                if(wait_cycles<TIMEOUT_CYCLES) wait_cycles<=wait_cycles+1'b1;
                else begin error<=1;cancelled<=1;end
                if(abort) begin cancelled<=1;error<=1;end
            end
            case(state)
            IDLE: if(start) begin
                error<=0;cancelled<=0;cycles<=0;lines_completed<=0;wait_cycles<=0;
                line_addr<={base[32:6],6'd0};
                end_addr<={1'b0,base}+{2'd0,bytes};
                if(bytes==0 || base[5:0]!=0 || bytes[5:0]!=0 ||
                   ({1'b0,base}+{2'd0,bytes})>34'h200000000) begin error<=1;done<=1;end
                else state<=AW;
            end
            AW: if(m_axi.awready) state<=W;
            W: if(m_axi.wready) state<=B;
            B: if(m_axi.bvalid) begin
                wait_cycles<=0;
                if(m_axi.bresp!=0 || m_axi.bid!=0 || cancelled || abort) begin
                    error<=1;done<=1;state<=IDLE;
                end else begin
                    lines_completed<=lines_completed+1'b1;
                    if({1'b0,line_addr}+64>=end_addr) begin done<=1;state<=IDLE;end
                    else begin line_addr<=line_addr+64;state<=AW;end
                end
            end
            endcase
        end
    end
endmodule
