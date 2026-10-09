`timescale 1ns/1ps
module tb_ppu_publication_write_mux;
    reg clk=0;always #5 clk=~clk;
    reg resetn=0,start=0;
    axi4_if #(.ADDR_WIDTH(33),.DATA_WIDTH(256),.ID_WIDTH(5)) tensor_axi(),publish_axi(),bus();
    wire busy,done,error;wire [31:0] cycles,lines_completed;
    ppu_cache_publish_engine engine(.clk(clk),.resetn(resetn),.start(start),.abort(1'b0),
        .base(33'hb2000000),.bytes(32'd512),.busy(busy),.done(done),.error(error),
        .cycles(cycles),.lines_completed(lines_completed),.m_axi(publish_axi));
    ppu_publication_write_mux dut(.clk(clk),.resetn(resetn),.tensor_axi(tensor_axi),.publish_axi(publish_axi),.m_axi(bus));
    integer tick=0,tx=0,tx_state=0,tx_beat=0,received=0,pub_received=0;
    reg [31:0] outstanding=0,pending_b=0;
    reg have_aw=0;
    reg [4:0] id_q;
    reg [32:0] addr_q;
    integer beats_left;
    wire [4:0] tensor_id=5'(18+tx%14);
    assign tensor_axi.aclk=clk;assign tensor_axi.aresetn=resetn;
    assign tensor_axi.awid=tensor_id;assign tensor_axi.awaddr=33'hb1000000+33'(tx*64);
    assign tensor_axi.awlen=1;assign tensor_axi.awsize=5;assign tensor_axi.awburst=1;
    assign tensor_axi.awlock=0;assign tensor_axi.awcache=0;assign tensor_axi.awprot=0;assign tensor_axi.awqos=0;
    assign tensor_axi.awvalid=tx_state==0 && tx<32 && !outstanding[tensor_id];
    assign tensor_axi.wvalid=tx_state==1;assign tensor_axi.wlast=tx_beat==1;
    assign tensor_axi.wstrb='1;assign tensor_axi.wdata=256'(tx*2+tx_beat);
    assign tensor_axi.bready=tick%5!=0;
    assign tensor_axi.arvalid=0;assign tensor_axi.arid=0;assign tensor_axi.araddr=0;
    assign tensor_axi.arlen=0;assign tensor_axi.arsize=0;assign tensor_axi.arburst=0;
    assign tensor_axi.arlock=0;assign tensor_axi.arcache=0;assign tensor_axi.arprot=0;assign tensor_axi.arqos=0;assign tensor_axi.rready=1;
    assign bus.awready=!have_aw && tick%4>1;
    assign bus.wready=have_aw && tick%3!=0;
    assign bus.arready=0;assign bus.rvalid=0;assign bus.rid=0;assign bus.rdata=0;assign bus.rresp=0;assign bus.rlast=0;
    reg stalled_aw=0,stalled_w=0;
    reg [45:0] aw_held;
    reg [288:0] w_held;
    reg pub_done=0;
    always @(posedge clk) begin
        tick<=tick+1;
        if(!resetn) begin bus.bvalid<=0;bus.bid<=0;bus.bresp<=0;end
        else begin
            if(done) pub_done<=1;
            if(stalled_aw && (!bus.awvalid || {bus.awid,bus.awaddr,bus.awlen}!==aw_held)) $fatal(1,"AW changed under stall");
            if(stalled_w && (!bus.wvalid || {bus.wlast,bus.wstrb,bus.wdata}!==w_held)) $fatal(1,"W changed under stall");
            stalled_aw<=bus.awvalid&&!bus.awready;aw_held<={bus.awid,bus.awaddr,bus.awlen};
            stalled_w<=bus.wvalid&&!bus.wready;w_held<={bus.wlast,bus.wstrb,bus.wdata};
            if(tensor_axi.awvalid && tensor_axi.awready) begin tx_state<=1;tx_beat<=0;outstanding[tensor_id]<=1;end
            if(tensor_axi.wvalid && tensor_axi.wready) begin
                if(tx_beat==1) begin tx<=tx+1;tx_state<=0;end else tx_beat<=1;
            end
            if(tensor_axi.bvalid && tensor_axi.bready) begin
                if(tensor_axi.bid<18 || !outstanding[tensor_axi.bid] || tensor_axi.bresp!=0) $fatal(1,"tensor B routing");
                outstanding[tensor_axi.bid]<=0;received<=received+1;
            end
            if(bus.awvalid && bus.awready) begin
                have_aw<=1;id_q<=bus.awid;addr_q<=bus.awaddr;beats_left<=int'(bus.awlen)+1;
            end
            if(bus.wvalid && bus.wready) begin
                if(bus.wlast!=(beats_left==1)) $fatal(1,"burst ownership WLAST");
                if(id_q==0) begin
                    if(addr_q!=33'h02010200 || bus.wdata[63:0]!=64'hb2000000+64'(pub_received)*64) $fatal(1,"publication W routing");
                    pub_received<=pub_received+1;
                end else if(bus.wdata!=256'(((addr_q-33'hb1000000)/64)*2+2-beats_left)) $fatal(1,"tensor W routing");
                beats_left<=beats_left-1;
                if(beats_left==1) begin have_aw<=0;pending_b[id_q]<=1;end
            end
            if(!bus.bvalid && tick%3==0) begin
                // Return higher tensor IDs before publication ID 0.
                for(integer id=0;id<32;id=id+1) if(pending_b[id]) begin bus.bvalid<=1;bus.bid<=5'(id);end
            end
            if(bus.bvalid && bus.bready) begin pending_b[bus.bid]<=0;bus.bvalid<=0;end
        end
    end
    initial begin
        repeat(4) @(negedge clk);resetn=1;start=1;@(negedge clk);start=0;
        wait(pub_done && received==32);@(negedge clk);
        if(error || lines_completed!=8 || pub_received!=8 || outstanding!=0) $fatal(1,"write mux completion");
        $display("PUBLICATION_WRITE_MUX=PASS tensor=32 publication=8 reordered_B/backpressure");$finish;
    end
    initial begin repeat(10000) @(posedge clk);$fatal(1,"write mux timeout");end
endmodule
