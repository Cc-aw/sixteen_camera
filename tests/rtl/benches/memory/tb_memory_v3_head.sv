`timescale 1ns/1ps
module tb_memory_v3_head #(parameter bit READ_DECOUPLE = 1'b0);
    reg clk=0, resetn=0;
    always #5 clk=~clk;
    axi4_if #(.ADDR_WIDTH(33),.DATA_WIDTH(512),.ID_WIDTH(2)) s(), d();
    reg [2:0] bank=0;
    reg req=0, ready=0;
    wire req_ready, valid;
    reg [6:0] word_addr=0;
    wire [255:0] data;
    wire [31:0] perf;
    axi4_head_uram_router_v3 #(.DATA_WIDTH(512),.ID_WIDTH(2),.SLOT_BYTES(4096),.READ_DECOUPLE(READ_DECOUPLE)) dut (
        .clk(clk),.resetn(resetn),.s_axi(s),.m_ddr_axi(d),
        .local_read_bank(bank),.local_read_req_valid(req),.local_read_req_ready(req_ready),
        .local_read_req_word_addr(word_addr),.local_read_rsp_data(data),
        .local_read_rsp_valid(valid),.local_read_rsp_ready(ready),.perf_events(perf)
    );
    reg [511:0] expected [0:5];
    function automatic [32:0] base(input integer n);
        case(n)
            0:base=33'h32000000; 1:base=33'h32100000; 2:base=33'h32400000;
            3:base=33'h32500000; 4:base=33'h32800000; default:base=33'h32900000;
        endcase
    endfunction
    task automatic write_word(input integer n,input [511:0] payload,input [63:0] strb,input bit narrow);
        @(negedge clk); s.awaddr=base(n)+(narrow?32:0);s.awsize=narrow?5:6;s.awvalid=1;
        do @(posedge clk); while(!s.awready);
        @(negedge clk);s.awvalid=0;s.wdata=payload;s.wstrb=strb;s.wvalid=1;s.wlast=1;
        do @(posedge clk); while(!s.wready);
        @(negedge clk);s.wvalid=0;
        do @(posedge clk); while(!s.bvalid);
        if(s.bresp!=0 || s.bid!=2) $fatal(1,"head write response");
        for(integer b=0;b<64;b++) if(strb[b]) expected[n][b*8+:8]=payload[b*8+:8];
    endtask
    task automatic local_word(input integer n,input integer half);
        @(negedge clk);bank=3'(n);word_addr=7'(half);req=1;ready=0;
        do @(posedge clk); while(!req_ready);
        @(negedge clk);req=0;
        do @(posedge clk); while(!valid);
        repeat(4) begin
            @(negedge clk);
            if(!valid || data!==expected[n][half*256+:256]) $fatal(1,"local half/stall data bank=%0d half=%0d",n,half);
            // Address may change during response backpressure.
            word_addr=7'(!half);bank=3'((n+1)%6);
        end
        ready=1;@(posedge clk);@(negedge clk);ready=0;
    endtask
    initial begin
        s.awvalid=0;s.wvalid=0;s.arvalid=0;s.bready=1;s.rready=0;
        s.awid=2;s.awlen=0;s.awburst=1;s.awlock=0;s.awcache=0;s.awprot=0;s.awqos=0;
        s.arid=1;s.arlen=0;s.arburst=1;s.arlock=0;s.arcache=0;s.arprot=0;s.arqos=0;
        d.awready=1;d.wready=1;d.arready=1;d.rvalid=0;d.bvalid=0;
        d.rid=0;d.rdata=0;d.rresp=0;d.rlast=0;d.bid=0;d.bresp=0;
        repeat(6) @(negedge clk);resetn=1;
        for(integer n=0;n<6;n++) begin
            write_word(n,{{32{8'(n+64)}},{32{8'(n+1)}}},'1,0);
            write_word(n,{64{8'haa}},64'haaaaaaaa00000000,1);
            local_word(n,0);local_word(n,1);
            @(negedge clk);s.araddr=base(n)+32;s.arsize=5;s.arvalid=1;
            do @(posedge clk);while(!s.arready);
            @(negedge clk);s.arvalid=0;
            do @(posedge clk);while(!s.rvalid);
            repeat(3) begin
                @(negedge clk);
                if(s.rdata!==expected[n] || s.rid!=1 || s.rresp!=0 || !s.rlast) $fatal(1,"narrow read lane mapping");
            end
            s.rready=1;@(posedge clk);@(negedge clk);s.rready=0;
        end
        // Consecutive alternating half/slot requests must sustain 32 B/cycle.
        @(negedge clk);ready=1;req=1;bank=0;word_addr=0;
        for(integer n=0;n<40;n++) begin
            @(posedge clk);
            if(!req_ready) $fatal(1,"local interface throughput bubble");
            if(n>0 && (!valid || data!==expected[((n-1)/2)%6][((n-1)%2)*256+:256])) $fatal(1,"pipelined half metadata");
            @(negedge clk);bank=3'(((n+1)/2)%6);word_addr=7'((n+1)%2);
        end
        req=0;@(posedge clk);
        if(!valid || data!==expected[(39/2)%6][256+:256]) $fatal(1,"last local beat");
        $display("MEMORY_V3_HEAD_PASS six_slots=yes masked_narrow_write=yes narrow_read=yes half_stall=yes throughput=32B/cycle");
        $finish;
    end
    initial begin #100000; $fatal(1,"timeout"); end
    always @(posedge clk) if(resetn && (d.awvalid || d.arvalid || d.wvalid)) $fatal(1,"Head leaked to DDR");
endmodule
