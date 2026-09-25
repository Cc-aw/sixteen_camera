`timescale 1ns/1ps
// Uses the production generated L2 control RTL, not a model of its ack timing.
module tb_ppu_cache_control_completion;
    reg clk=0;always #5 clk=~clk;
    reg resetn=0,start=0;
    axi4_if #(.ADDR_WIDTH(33),.DATA_WIDTH(256),.ID_WIDTH(5)) bus();
    wire busy,done,error;
    wire [31:0] cycles,lines_completed;
    ppu_cache_publish_engine dut(.clk(clk),.resetn(resetn),.start(start),.abort(1'b0),
        .base(33'h0b2000000),.bytes(32'd512),.busy(busy),.done(done),.error(error),
        .cycles(cycles),.lines_completed(lines_completed),.m_axi(bus));
    reg aw_held=0;
    wire ctrl_a_ready,ctrl_d_valid,flush_req_valid;
    wire [63:0] flush_address;
    wire invalidate;
    reg flush_response=0;
    integer delay_count=0,requested=0,committed=0,responded=0;
    assign bus.awready=!aw_held;
    assign bus.wready=aw_held && ctrl_a_ready;
    assign bus.bvalid=ctrl_d_valid;assign bus.bresp=0;assign bus.bid=0;
    assign bus.arready=0;assign bus.rvalid=0;assign bus.rid=0;assign bus.rdata=0;assign bus.rresp=0;assign bus.rlast=0;
    InclusiveCacheControl control(
        .clock(clk),.reset(!resetn),
        .auto_ctrl_in_a_ready(ctrl_a_ready),.auto_ctrl_in_a_valid(aw_held && bus.wvalid),
        .auto_ctrl_in_a_bits_opcode(3'd0),.auto_ctrl_in_a_bits_size(2'd3),
        .auto_ctrl_in_a_bits_source(14'd0),.auto_ctrl_in_a_bits_address(26'h2010200),
        .auto_ctrl_in_a_bits_mask(bus.wstrb[7:0]),.auto_ctrl_in_a_bits_data(bus.wdata[63:0]),
        .auto_ctrl_in_d_ready(bus.bready),.auto_ctrl_in_d_valid(ctrl_d_valid),
        .auto_ctrl_in_d_bits_opcode(),.auto_ctrl_in_d_bits_size(),
        .auto_ctrl_in_d_bits_source(),.auto_ctrl_in_d_bits_data(),
        .io_flush_match(1'b1),.io_flush_req_ready(1'b1),.io_flush_req_valid(flush_req_valid),
        .io_flush_req_bits(flush_address),.io_invalidate_req(invalidate),.io_flush_resp(flush_response));
    always @(posedge clk) begin
        if(!resetn) begin aw_held<=0;flush_response<=0;delay_count<=0;end
        else begin
            flush_response<=0;
            if(bus.awvalid && bus.awready) begin
                if(bus.awaddr!=33'h02010200) $fatal(1,"wrong Flush64 CSR");
                aw_held<=1;
            end
            if(bus.wvalid && bus.wready) aw_held<=0;
            if(flush_req_valid) begin
                if(flush_address!=64'hb2000000+64'(requested)*64 || invalidate || delay_count!=0)
                    $fatal(1,"generated L2 flush request mismatch");
                requested<=requested+1;delay_count<=8;
            end
            if(delay_count>0) begin
                delay_count<=delay_count-1;
                if(delay_count==1) begin flush_response<=1;committed<=committed+1;end
            end
            if(bus.bvalid && bus.bready) begin
                if(committed<=responded) $fatal(1,"L2 acknowledged before writeback completion");
                responded<=responded+1;
            end
        end
    end
    initial begin
        repeat(5) @(negedge clk);resetn=1;start=1;@(negedge clk);start=0;
        wait(done);@(negedge clk);
        if(error || requested!=8 || committed!=8 || responded!=8 || lines_completed!=8)
            $fatal(1,"generated L2 completion mismatch req=%0d commit=%0d B=%0d",requested,committed,responded);
        $display("GENERATED_L2_PUBLICATION_COMPLETION=PASS lines=8");$finish;
    end
    initial begin repeat(3000) @(posedge clk);$fatal(1,"L2 publication timeout");end
endmodule
