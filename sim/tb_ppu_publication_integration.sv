`timescale 1ns/1ps
// Coherent-cache responder writes each cleaned line through the real Head
// router before returning Flush64 B. The guarded PPU then reads actual URAM.
module tb_ppu_publication_integration #(parameter ABORT_CASE=0, parameter QUEUED_CASE=0, parameter MULTI_CASE=0);
    reg clk=0;always #5 clk=~clk;
    reg resetn=0;
    axi4_if #(.ADDR_WIDTH(33),.DATA_WIDTH(256),.ID_WIDTH(4)) soc(),ddr();
    axi4_if #(.ADDR_WIDTH(33),.DATA_WIDTH(256),.ID_WIDTH(5)) tensor(),fbus();
    axi_lite_if axil();
    postprocess_memory_bridge dut(.soc_clk(clk),.soc_resetn(resetn),.ppu_overlay_ready(1'b1),.soc_mem_axi(soc),
        .tensor_fbus_write_axi(tensor),.soc_ddr_axi(ddr),.fbus_axi(fbus),.postprocess_axil(axil));
    assign axil.aclk=clk;assign axil.aresetn=resetn;
    assign soc.aclk=clk;assign soc.aresetn=resetn;
    assign tensor.aclk=clk;assign tensor.aresetn=resetn;
    assign tensor.awid=18;assign tensor.awaddr=0;assign tensor.awlen=0;assign tensor.awsize=5;
    assign tensor.awburst=1;assign tensor.awlock=0;assign tensor.awcache=0;assign tensor.awprot=0;assign tensor.awqos=0;assign tensor.awvalid=0;
    assign tensor.wdata=0;assign tensor.wstrb=0;assign tensor.wlast=0;assign tensor.wvalid=0;assign tensor.bready=1;
    assign tensor.arid=0;assign tensor.araddr=0;assign tensor.arlen=0;assign tensor.arsize=0;
    assign tensor.arburst=0;assign tensor.arlock=0;assign tensor.arcache=0;assign tensor.arprot=0;assign tensor.arqos=0;assign tensor.arvalid=0;assign tensor.rready=1;
    assign ddr.awready=0;assign ddr.wready=0;assign ddr.bid=0;assign ddr.bresp=0;assign ddr.bvalid=0;
    assign ddr.arready=0;assign ddr.rid=0;assign ddr.rdata=0;assign ddr.rresp=0;assign ddr.rlast=0;assign ddr.rvalid=0;
    assign fbus.arready=0;assign fbus.rid=0;assign fbus.rdata=0;assign fbus.rresp=0;assign fbus.rlast=0;assign fbus.rvalid=0;
    reg [2:0] cache_state=0;
    reg [32:0] line_address=0;
    integer lines=0;
    assign fbus.awready=cache_state==0;
    assign fbus.wready=cache_state==1;
    assign fbus.bvalid=cache_state==6;assign fbus.bid=0;assign fbus.bresp=0;
    assign soc.awid=0;assign soc.awaddr=line_address;assign soc.awlen=1;assign soc.awsize=5;
    assign soc.awburst=1;assign soc.awlock=0;assign soc.awcache=0;assign soc.awprot=0;assign soc.awqos=0;
    assign soc.awvalid=cache_state==2;
    assign soc.wdata={32{8'h80}};assign soc.wstrb='1;
    assign soc.wvalid=cache_state==3 || cache_state==4;assign soc.wlast=cache_state==4;
    assign soc.bready=cache_state==5;
    assign soc.arid=0;assign soc.araddr=0;assign soc.arlen=0;assign soc.arsize=0;assign soc.arburst=0;
    assign soc.arlock=0;assign soc.arcache=0;assign soc.arprot=0;assign soc.arqos=0;assign soc.arvalid=0;assign soc.rready=1;
    always @(posedge clk) begin
        if(!resetn) begin cache_state<=0;lines<=0;end
        else begin
            case(cache_state)
            0:if(fbus.awvalid && fbus.awready) begin
                if(fbus.awaddr!=33'h02010200 || fbus.awid!=0) $fatal(1,"unexpected FBus write");
                cache_state<=1;
            end
            1:if(fbus.wvalid && fbus.wready) begin line_address<=fbus.wdata[32:0];cache_state<=2;end
            2:if(soc.awready) cache_state<=3;
            3:if(soc.wready) cache_state<=4;
            4:if(soc.wready) cache_state<=5;
            5:if(soc.bvalid) begin if(soc.bresp!=0) $fatal(1,"Head writeback error");cache_state<=6;end
            6:if(fbus.bready) begin cache_state<=0;lines<=lines+1;end
            endcase
            if(dut.u_postprocess_read_diagnostic.production_start && dut.u_postprocess_read_diagnostic.u_publication_gate.guarded && !dut.pub_ready_heads[dut.pub_lease_bank*6])
                $fatal(1,"PPU read before hardware publication");
        end
    end
    task automatic write32(input [31:0] addr,data);
        @(negedge clk);axil.awaddr=addr;axil.awvalid=1;axil.wdata=data;axil.wstrb=15;axil.wvalid=1;axil.bready=1;
        do @(posedge clk);while(!axil.awready || !axil.wready);
        @(negedge clk);axil.awvalid=0;axil.wvalid=0;
        wait(axil.bvalid);@(negedge clk);axil.bready=0;
    endtask
    task automatic read32(input [31:0] addr,output reg [31:0] data);
        @(negedge clk);axil.araddr=addr;axil.arvalid=1;axil.rready=1;
        do @(posedge clk);while(!axil.arready);
        @(negedge clk);axil.arvalid=0;wait(axil.rvalid);data=axil.rdata;
        @(negedge clk);axil.rready=0;
    endtask
    initial begin
        reg [31:0] status,value,base;
        axil.awvalid=0;axil.wvalid=0;axil.bready=0;axil.arvalid=0;axil.rready=0;axil.awprot=0;axil.arprot=0;
        repeat(5) @(negedge clk);resetn=1;
        if(MULTI_CASE) begin
            write32('h1a4,1);write32('h200,1);
            for(integer bank=0;bank<4;bank=bank+1) begin
                base=32'h32000000+(bank/2)*32'h400000+(bank%2)*32'h100000;
                write32('h1a8,bank);write32('h1ac,7+bank);write32('h1b0,1);
                write32('h104,base);write32('h108,base+'h5dc00);write32('h10c,base+'h75300);
                write32('h110,base+'h7b0c0);write32('h114,base+'hc60c0);write32('h118,base+'hd8cc0);
                write32('h20c,bank);write32('h210,123+bank);write32('h218,9);write32('h204,1);
            end
            for(integer bank=0;bank<4;bank=bank+1) begin
                write32('h1a8,bank);write32('h1ac,7+bank);write32('h1b0,'h3f00);
            end
            for(integer bank=0;bank<4;bank=bank+1) begin
                value=0;while(!(value&1)) begin repeat(200) @(negedge clk);read32('h240,value);end
                read32('h250,value);if(value!=bank) $fatal(1,"four-task FIFO order");
                read32('h258,value);if(value!=123+bank) $fatal(1,"four-task frame");
                read32('h268,value);if(value!=7+bank) $fatal(1,"four-task generation");
                read32('h254,value);if(value!=(bank<<10)) $fatal(1,"four-task result status/count");
                write32('h24c,1);
            end
            if(lines!=56700 || dut.pub_allocated!=0) $fatal(1,"four-task ownership/visibility");
            read32('h26c,value);if(value!=4) $fatal(1,"four-task overlay commits");
            $display("PPU_FOUR_TASK_INTEGRATION=PASS workers=2 slots=4 heads=24 lines=56700 positions=25200");$finish;
        end
        write32('h1a4,1);write32('h1a8,0);write32('h1ac,1);write32('h1b0,1);
        write32('h104,'h32000000);write32('h108,'h3205dc00);write32('h10c,'h32075300);
        write32('h110,'h3207b0c0);write32('h114,'h320c60c0);write32('h118,'h320d8cc0);
        write32('h1b0,'h0100);
        if(QUEUED_CASE) begin
            write32('h200,1);write32('h20c,3);write32('h210,123);write32('h218,9);write32('h204,1);
            // Configuration writes for the next task must not mutate the active descriptor.
            write32('h104,0);write32('h108,0);write32('h10c,0);write32('h20c,8);write32('h210,999);
        end else write32('h100,'h101);
        wait(dut.u_postprocess_read_diagnostic.production_read_start);
        if(dut.pub_ready_heads[5:0]!=1) $fatal(1,"class0 failed to overlap later heads");
        wait(dut.u_postprocess_read_diagnostic.production_positions>=4800);
        repeat(100) @(negedge clk);
        if(dut.u_postprocess_read_diagnostic.production_positions!=4800) $fatal(1,"unpublished class1 accessed");
        if(ABORT_CASE) begin
            write32('h1b0,4);status=0;
            while(!(status&2)) begin repeat(20) @(negedge clk);read32('h11c,status);end
            if(!(status&4) || dut.pub_allocated!=0) $fatal(1,"abort did not drain/release");
            $display("PPU_PUBLICATION_ABORT=PASS");$finish;
        end
        write32('h1b0,'h3e00);
        status=0;
        while(!(status&2)) begin repeat(50) @(negedge clk);read32('h11c,status);end
        if(status&5) $fatal(1,"guarded PPU failed status=%h",status);
        read32('h138,value);if(value!=6300) $fatal(1,"wrong positions %0d",value);
        read32('h124,value);if(value!=0) $fatal(1,"empty raw heads produced detections");
        if(lines!=14175 || dut.pub_allocated!=0) $fatal(1,"publication count/ownership lines=%0d",lines);
        if(QUEUED_CASE) begin
            value=0;while(!(value&1)) begin repeat(30) @(negedge clk);read32('h240,value);end
            read32('h258,value);if(value!=123) $fatal(1,"frame metadata changed");
            read32('h254,value);if(value[17:14]!=0 || value[13:10]!=3 || value[5:0]!=0) $fatal(1,"result status/stream/count %h",value);
            read32('h26c,value);if(value!=1) $fatal(1,"overlay not published");
            write32('h24c,1);read32('h240,value);if(value&1) $fatal(1,"observation did not pop");
            write32('h104,'h32000000);write32('h108,'h3205dc00);write32('h10c,'h32075300);
            write32('h100,1);status=0;
            while(!(status&2)) begin repeat(50) @(negedge clk);read32('h11c,status);end
            if(status&5) $fatal(1,"legacy command failed with queue enabled");
            read32('h138,value);if(value!=6300) $fatal(1,"legacy positions with queue enabled");
        end
        $display("PPU_PUBLICATION_INTEGRATION=PASS lines=14175 positions=6300 results=0 CPU_flush=0");$finish;
    end
    initial begin repeat(4000000) @(posedge clk);$fatal(1,"guarded PPU timeout cache=%0d lines=%0d",cache_state,lines);end
endmodule
