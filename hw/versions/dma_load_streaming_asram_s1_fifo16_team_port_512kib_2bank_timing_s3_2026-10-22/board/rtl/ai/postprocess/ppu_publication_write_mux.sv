`timescale 1ns/1ps
// Burst ownership covers AW through WLAST. Responses are independent and may
// reorder: publication uses write ID 0, tensor writes retain IDs 18..31.
// Read ID 0 remains distinct: generated AXI4ToTL appends the R/W source bit.
module ppu_publication_write_mux (
    input wire clk,resetn,
    axi4_if.slave tensor_axi,
    axi4_if.slave publish_axi,
    axi4_if.master m_axi
);
    localparam [1:0] IDLE=0,ADDRESS=1,DATA=2;
    reg [1:0] state;
    reg owner,prefer_publish;
    assign m_axi.aclk=clk;assign m_axi.aresetn=resetn;
    assign m_axi.awid=owner?publish_axi.awid:tensor_axi.awid;
    assign m_axi.awaddr=owner?publish_axi.awaddr:tensor_axi.awaddr;
    assign m_axi.awlen=owner?publish_axi.awlen:tensor_axi.awlen;
    assign m_axi.awsize=owner?publish_axi.awsize:tensor_axi.awsize;
    assign m_axi.awburst=owner?publish_axi.awburst:tensor_axi.awburst;
    assign m_axi.awlock=owner?publish_axi.awlock:tensor_axi.awlock;
    assign m_axi.awcache=owner?publish_axi.awcache:tensor_axi.awcache;
    assign m_axi.awprot=owner?publish_axi.awprot:tensor_axi.awprot;
    assign m_axi.awqos=owner?publish_axi.awqos:tensor_axi.awqos;
    assign m_axi.awvalid=state==ADDRESS && (owner?publish_axi.awvalid:tensor_axi.awvalid);
    assign tensor_axi.awready=state==ADDRESS && !owner && m_axi.awready;
    assign publish_axi.awready=state==ADDRESS && owner && m_axi.awready;
    assign m_axi.wdata=owner?publish_axi.wdata:tensor_axi.wdata;
    assign m_axi.wstrb=owner?publish_axi.wstrb:tensor_axi.wstrb;
    assign m_axi.wlast=owner?publish_axi.wlast:tensor_axi.wlast;
    assign m_axi.wvalid=state==DATA && (owner?publish_axi.wvalid:tensor_axi.wvalid);
    assign tensor_axi.wready=state==DATA && !owner && m_axi.wready;
    assign publish_axi.wready=state==DATA && owner && m_axi.wready;
    assign tensor_axi.bid=m_axi.bid;assign tensor_axi.bresp=m_axi.bresp;
    assign publish_axi.bid=m_axi.bid;assign publish_axi.bresp=m_axi.bresp;
    assign tensor_axi.bvalid=m_axi.bvalid && m_axi.bid!=0;
    assign publish_axi.bvalid=m_axi.bvalid && m_axi.bid==0;
    assign m_axi.bready=m_axi.bid==0?publish_axi.bready:tensor_axi.bready;
    assign m_axi.arid=0;assign m_axi.araddr=0;assign m_axi.arlen=0;
    assign m_axi.arsize=0;assign m_axi.arburst=0;assign m_axi.arlock=0;
    assign m_axi.arcache=0;assign m_axi.arprot=0;assign m_axi.arqos=0;
    assign m_axi.arvalid=0;assign m_axi.rready=1;
    assign tensor_axi.arready=0;assign tensor_axi.rid=0;assign tensor_axi.rdata=0;
    assign tensor_axi.rresp=0;assign tensor_axi.rlast=0;assign tensor_axi.rvalid=0;
    assign publish_axi.arready=0;assign publish_axi.rid=0;assign publish_axi.rdata=0;
    assign publish_axi.rresp=0;assign publish_axi.rlast=0;assign publish_axi.rvalid=0;
    always @(posedge clk) begin
        if(!resetn) begin state<=IDLE;owner<=0;prefer_publish<=1;end
        else case(state)
        IDLE: if(tensor_axi.awvalid || publish_axi.awvalid) begin
            owner<=publish_axi.awvalid && (!tensor_axi.awvalid || prefer_publish);
            state<=ADDRESS;
        end
        ADDRESS: if(m_axi.awvalid && m_axi.awready) begin state<=DATA;prefer_publish<=!owner;end
        DATA: if(m_axi.wvalid && m_axi.wready && m_axi.wlast) state<=IDLE;
        default:state<=IDLE;
        endcase
    end
endmodule
