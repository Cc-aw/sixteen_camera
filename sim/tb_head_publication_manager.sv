`timescale 1ns/1ps
module tb_head_publication_manager #(parameter TEST_HEAD_BYTES=128);
    reg clk=0;always #5 clk=~clk;
    reg resetn=0,allocate=0,publish=0,abort_slot=0,release_slot=0,acquire=0;
    reg [1:0] command_bank=0,lease_bank=0;
    reg [31:0] command_version=0,lease_version=0;
    reg [5:0] publish_mask=0;
    wire [3:0] allocated,reading,fault;
    wire [127:0] versions;
    wire [23:0] ready_heads,producer_heads;
    wire [31:0] rejected_commands;
    wire clean_start,clean_abort,clean_busy,clean_done,clean_error,active;
    wire [32:0] clean_base;
    wire [31:0] clean_bytes,cycles,lines_completed;
    axi4_if #(.ADDR_WIDTH(33),.DATA_WIDTH(256),.ID_WIDTH(5)) bus();
    head_publication_manager #(.TEST_HEAD_BYTES(TEST_HEAD_BYTES)) dut(.*);
    ppu_cache_publish_engine #(.TIMEOUT_CYCLES(1000000)) engine(
        .clk(clk),.resetn(resetn),.start(clean_start),.abort(clean_abort),.base(clean_base),.bytes(clean_bytes),
        .busy(clean_busy),.done(clean_done),.error(clean_error),.cycles(cycles),.lines_completed(lines_completed),.m_axi(bus));
    reg hold_response=0,inject_error=0;
    integer delay_count=0,accepted=0,completed=0,tick=0;
    reg waiting=0,have_aw=0;
    reg [32:0] expected_addr;
    reg [31:0] expected_lines;
    reg [31:0] committed[0:3][0:5];
    reg [1:0] bank_q;
    reg [2:0] head_q;
    function automatic integer bytes_for(input integer h);
        if(TEST_HEAD_BYTES!=0) bytes_for=TEST_HEAD_BYTES;
        else case(h)
        0:bytes_for=384000;1:bytes_for=96000;2:bytes_for=24000;
        3:bytes_for=307200;4:bytes_for=76800;default:bytes_for=19200;
        endcase
    endfunction
    function automatic integer offset_for(input integer h);
        case(h)
        0:offset_for='h0;1:offset_for='h5dc00;2:offset_for='h75300;
        3:offset_for='h7b0c0;4:offset_for='hc60c0;default:offset_for='hd8cc0;
        endcase
    endfunction
    assign bus.awready=!have_aw && tick%3!=0;
    assign bus.wready=have_aw && !waiting && tick%5!=0;
    assign bus.arready=0;assign bus.rvalid=0;assign bus.rid=0;assign bus.rdata=0;assign bus.rresp=0;assign bus.rlast=0;
    always @(posedge clk) begin
        tick<=tick+1;
        if(!resetn) begin
            bus.bvalid<=0;bus.bresp<=0;bus.bid<=0;waiting<=0;have_aw<=0;accepted<=0;completed<=0;
            for(integer b=0;b<4;b=b+1) for(integer h=0;h<6;h=h+1) committed[b][h]<=0;
        end else begin
            if(allocate && !allocated[command_bank])
                for(integer h=0;h<6;h=h+1) committed[command_bank][h]<=0;
            if(clean_start) begin
                expected_addr<=clean_base;expected_lines<=clean_bytes/64;
                if(clean_base[5:0]!=0 || clean_bytes%64!=0) $fatal(1,"unaligned clean");
            end
            if(bus.awvalid && bus.awready) begin
                if(bus.awaddr!=33'h02010200 || bus.awid!=0 || bus.awlen!=0 || bus.awsize!=3)
                    $fatal(1,"Flush64 request attributes");
                have_aw<=1;
            end
            if(bus.wvalid && bus.wready) begin
                if(!bus.wlast || bus.wstrb!=32'hff || bus.wdata[32:0]!=expected_addr)
                    $fatal(1,"clean line address/strobe mismatch got=%h expected=%h",bus.wdata[32:0],expected_addr);
                expected_addr<=expected_addr+64;accepted<=accepted+1;waiting<=1;delay_count<=4;
                case(bus.wdata[31:20])
                'hb20:bank_q<=0;'hb21:bank_q<=1;'hb24:bank_q<=2;'hb25:bank_q<=3;
                default:$fatal(1,"invalid publication bank");
                endcase
                for(integer h=0;h<6;h=h+1)
                    if(bus.wdata[19:0]>=offset_for(h) && bus.wdata[19:0]<offset_for(h)+bytes_for(h)) head_q<=3'(h);
            end
            if(waiting && !bus.bvalid && !hold_response) begin
                if(delay_count!=0) delay_count<=delay_count-1;
                else begin bus.bvalid<=1;bus.bresp<=inject_error?2'b10:2'b00;end
            end
            if(bus.bvalid && bus.bready) begin
                bus.bvalid<=0;waiting<=0;have_aw<=0;completed<=completed+1;
                if(bus.bresp==0) committed[bank_q][head_q]<=committed[bank_q][head_q]+1;
            end
            for(integer b=0;b<4;b=b+1) for(integer h=0;h<6;h=h+1)
                if(ready_heads[b*6+h] && committed[b][h]<bytes_for(h)/64)
                    $fatal(1,"READY before cache completion bank=%0d head=%0d",b,h);
        end
    end
    task automatic alloc(input integer b,input reg [31:0] v);
        @(negedge clk);command_bank=2'(b);command_version=v;allocate=1;
        @(negedge clk);allocate=0;@(negedge clk);
    endtask
    task automatic commit(input integer b,input reg [31:0] v,input reg [5:0] mask);
        @(negedge clk);command_bank=2'(b);command_version=v;publish_mask=mask;publish=1;
        @(negedge clk);publish=0;@(negedge clk);
    endtask
    task automatic release_bank(input integer b,input reg [31:0] v);
        @(negedge clk);lease_bank=2'(b);lease_version=v;release_slot=1;
        @(negedge clk);release_slot=0;@(negedge clk);
    endtask
    initial begin
        integer before_reject;
        repeat(4) @(negedge clk);resetn=1;
        alloc(0,32'hffffffff);hold_response=1;commit(0,32'hffffffff,1);
        wait(accepted!=0);repeat(20) @(negedge clk);
        if(ready_heads[5:0]!=0 || !active) $fatal(1,"WLAST incorrectly published");
        hold_response=0;commit(0,32'hffffffff,6'h3e);
        alloc(1,7);commit(1,7,6'h3f);
        alloc(2,9);commit(2,9,6'h3f);
        alloc(3,11);commit(3,11,6'h3f);
        wait(ready_heads==24'hffffff);@(negedge clk);
        if(fault!=0) $fatal(1,"unexpected clean error");
        for(integer b=0;b<4;b=b+1) release_bank(b,b==0?32'hffffffff:b==1?7:b==2?9:11);
        if(allocated!=0) $fatal(1,"release failed");
        alloc(0,0);before_reject=rejected_commands;commit(0,32'hffffffff,6'h3f);
        if(rejected_commands!=before_reject+1 || producer_heads[5:0]!=0) $fatal(1,"stale generation accepted");
        hold_response=1;commit(0,0,1);wait(waiting);
        @(negedge clk);command_bank=0;command_version=0;abort_slot=1;
        @(negedge clk);abort_slot=0;
        release_bank(0,0);
        if(!allocated[0]) $fatal(1,"abort reused an outstanding slot");
        hold_response=0;wait(!active);release_bank(0,0);
        if(allocated[0] || ready_heads[5:0]!=0) $fatal(1,"abort drain/release failed");
        alloc(0,1);inject_error=1;commit(0,1,1);wait(fault[0]);wait(!active);
        if(ready_heads[5:0]!=0) $fatal(1,"error published a head");
        release_bank(0,1);inject_error=0;
        alloc(0,2);hold_response=1;commit(0,2,1);wait(waiting);
        @(negedge clk);resetn=0;repeat(3) @(negedge clk);resetn=1;hold_response=0;
        if(allocated!=0 || ready_heads!=0 || active) $fatal(1,"reset did not clear ownership");
        $display("HEAD_PUBLICATION_MANAGER=PASS bytes_override=%0d completion/version/wrap/abort/error/reset",TEST_HEAD_BYTES);$finish;
    end
    initial begin repeat(1500000) @(posedge clk);$fatal(1,"publication timeout");end
endmodule
