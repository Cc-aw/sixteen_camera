integer cycle=0, lanes=3, scenario=0, memory_delay=64, count=512, seed=151034;
integer per_lane=0, source_window=24;
integer issued[4], completed[4], response_beat[4][32], accepted_at[4][32];
integer write_beat[4];
reg source_busy[4][32], source_write[4][32];
reg [32:0] expected_address[4][32];
integer qread=0,qwrite=0,awread=0,awwrite=0,wread=0,wwrite=0,bread=0,bwrite=0;
integer return_id[65536],return_cycle[65536],aw_id[65536],b_id[65536],b_cycle[65536];
reg [32:0] return_address[65536],aw_address[65536];
reg [511:0] write_data[65536];
reg [63:0] write_mask[65536];
integer ar_total=0,aw_total=0,ar_start=0,aw_start=0,start_cycle=0,latency_sum=0;
integer a_stalls=0,d_stalls=0,read_peak=0,write_peak=0,parallel2=0,parallel3=0,parallel4=0;
integer id_live[4],id_peak[4],bank_requests[4];
reg [31:0] rng=32'h170719;
reg running=0, measuring=0, random_stalls=0;
reg [511:0] expected_line;

function automatic [511:0] line_data(input [32:0] addr);
    // Encode every physical address bit, including tag bits. A low-byte hash
    // alone aliases lines separated by 128 KiB and weakens replacement checks.
    for(integer i=0;i<64;i++) line_data[i*8+:8]=8'(addr>>(8*(i%8))) ^ 8'(i*3+8'h35);
endfunction
function automatic [32:0] address_for(input integer n,input integer lane);
    case(scenario)
        0: address_for=33'h80000000+33'((n%64)*64+lane*4096);
        1: address_for=33'h80000000+33'((n%4)*131072+lane*64);
        2: address_for=33'h81000000+33'((n*lanes+lane)*64);
        3: address_for=33'h82000000+33'(((n*lanes+lane)%12288)*64);
        4: address_for=33'h83000000+33'(((n*lanes+lane)%20480)*64);
        default: address_for=33'h84000000+33'((n%16)*131072+lane*64);
    endcase
endfunction
function automatic integer total_completed();
    total_completed=completed[0]+completed[1]+completed[2]+completed[3];
endfunction
always @(posedge clock) begin
    cycle++;
    if(cycle>20000000) $fatal(1,"timeout completed=%0d issued=%0d,%0d,%0d,%0d",total_completed(),issued[0],issued[1],issued[2],issued[3]);
    if(!reset) begin
        for(integer lane=0;lane<4;lane++) begin
            if(a_valid[lane] && a_ready[lane]) begin
                if(write_beat[lane]==0) begin
                    if(source_busy[lane][a_source[lane]]) $fatal(1,"source reused lane=%0d",lane);
                    source_busy[lane][a_source[lane]]=1;
                    source_write[lane][a_source[lane]]=a_opcode[lane]==0;
                    expected_address[lane][a_source[lane]]=a_address[lane];
                    response_beat[lane][a_source[lane]]=0;
                    accepted_at[lane][a_source[lane]]=cycle;
                    if(measuring) bank_requests[(a_address[lane]>>12)&3]++;
                end
                if(a_opcode[lane]==0 && write_beat[lane]==0) write_beat[lane]=1;
                else begin write_beat[lane]=0;issued[lane]++;end
            end
            if(d_valid[lane] && d_ready[lane]) begin
                if(d_source[lane]>=source_window || !source_busy[lane][d_source[lane]]) $fatal(1,"unexpected D source lane=%0d src=%0d",lane,d_source[lane]);
                if(d_denied[lane] || d_corrupt[lane]) $fatal(1,"denied/corrupt D");
                if(source_write[lane][d_source[lane]]) begin
                    if(d_opcode[lane]!=0) $fatal(1,"bad write response");
                    response_beat[lane][d_source[lane]]=2;
                end else begin
                    if(d_opcode[lane]!=1) $fatal(1,"bad read response");
                    expected_line=line_data(expected_address[lane][d_source[lane]]);
                    if(d_data[lane]!==256'(expected_line>>(256*response_beat[lane][d_source[lane]])))
                        $fatal(1,"bad data lane=%0d source=%0d address=%h beat=%0d",lane,d_source[lane],expected_address[lane][d_source[lane]],response_beat[lane][d_source[lane]]);
                    response_beat[lane][d_source[lane]]++;
                end
                if(response_beat[lane][d_source[lane]]==2) begin
                    source_busy[lane][d_source[lane]]=0;completed[lane]++;
                    if(measuring) latency_sum+=cycle-accepted_at[lane][d_source[lane]];
                end
            end
            if(measuring) begin
                if(a_valid[lane] && !a_ready[lane]) a_stalls++;
                if(d_valid[lane] && !d_ready[lane]) d_stalls++;
            end
        end
        if(measuring) begin
            if($countones(d_valid & d_ready)>=2) parallel2++;
            if($countones(d_valid & d_ready)>=3) parallel3++;
            if($countones(d_valid & d_ready)==4) parallel4++;
        end
        if(memory.arvalid && memory.arready) begin
            if(memory.arlen!=0 || memory.arsize!=6) $fatal(1,"AXI read shape");
            return_id[qwrite%65536]=memory.arid;return_address[qwrite%65536]=memory.araddr;
            return_cycle[qwrite%65536]=cycle+memory_delay;qwrite++;ar_total++;
            id_live[memory.arid]++;
        end
        if(memory.rvalid && memory.rready) begin id_live[memory.rid]--;qread++;end
        if(memory.awvalid && memory.awready) begin
            if(memory.awlen!=0 || memory.awsize!=6) $fatal(1,"AXI write shape");
            aw_id[awwrite%65536]=memory.awid;aw_address[awwrite%65536]=memory.awaddr;awwrite++;aw_total++;
        end
        if(memory.wvalid && memory.wready) begin
            if(!memory.wlast) $fatal(1,"missing WLAST");
            write_data[wwrite%65536]=memory.wdata;write_mask[wwrite%65536]=memory.wstrb;wwrite++;
        end
        if(awwrite>awread && wwrite>wread) begin
            if(write_data[wread%65536]!==line_data(aw_address[awread%65536]) || write_mask[wread%65536]!==64'hffffffffffffffff)
                $fatal(1,"writeback data/address/strobes corrupted");
            b_id[bwrite%65536]=aw_id[awread%65536];b_cycle[bwrite%65536]=cycle+memory_delay;
            bwrite++;awread++;wread++;
        end
        if(memory.bvalid && memory.bready) bread++;
        if(qwrite-qread>read_peak && measuring) read_peak=qwrite-qread;
        if(awwrite-bread>write_peak && measuring) write_peak=awwrite-bread;
        for(integer i=0;i<4;i++) begin
            if(id_live[i]<0) $fatal(1,"bad AXI RID");
            if(id_live[i]>id_peak[i]) id_peak[i]=id_live[i];
        end
    end
end
always @(negedge clock) begin
    rng={rng[30:0],rng[31]^rng[21]^rng[1]^rng[0]};
    for(integer lane=0;lane<4;lane++) begin
        a_source[lane]=6'(issued[lane]%source_window);
        a_valid[lane]=!reset && running && lane<lanes && issued[lane]<per_lane &&
            (write_beat[lane]!=0 || !source_busy[lane][a_source[lane]]);
        a_opcode[lane]=(scenario==5 && issued[lane]%3==0) ? 0 : 4;
        a_address[lane]=address_for(issued[lane],lane);
        a_data[lane]=256'(line_data(a_address[lane])>>(256*write_beat[lane]));
        d_ready[lane]=!reset && (!random_stalls || rng[(lane+3)%32] || rng[(lane+9)%32]);
    end
    memory.arready=!reset && (!random_stalls || rng[1] || rng[6]);
    memory.awready=!reset && (!random_stalls || rng[2] || rng[7]);
    memory.wready=!reset && (!random_stalls || rng[4] || rng[8]);
    memory.rvalid=!reset && qwrite>qread && cycle>=return_cycle[qread%65536];
    memory.rid=2'(return_id[qread%65536]);memory.rdata=line_data(return_address[qread%65536]);
    memory.rresp=0;memory.rlast=1;
    memory.bvalid=!reset && bwrite>bread && cycle>=b_cycle[bread%65536];
    memory.bid=2'(b_id[bread%65536]);memory.bresp=0;
end
task automatic pass(input integer transactions,input bit measure);
    @(negedge clock);running=0;
    for(integer lane=0;lane<4;lane++) begin issued[lane]=0;completed[lane]=0;write_beat[lane]=0;end
    per_lane=transactions;measuring=measure;start_cycle=cycle;ar_start=ar_total;aw_start=aw_total;
    running=1;
    wait(total_completed()==per_lane*lanes);
    @(negedge clock);running=0;
    wait(qwrite==qread && awwrite==awread && wwrite==wread && bwrite==bread);
    repeat(12) @(negedge clock);
    if(measure) begin
        $display("BANKED_MEMORY_PERF case=%0d lanes=%0d delay=%0d stalls=%0d seed=%0d requests=%0d cycles=%0d refill_lines=%0d writeback_lines=%0d latency_sum=%0d a_stalls=%0d d_stalls=%0d read_peak=%0d write_peak=%0d parallel2=%0d parallel3=%0d parallel4=%0d address_bank0=%0d address_bank1=%0d address_bank2=%0d address_bank3=%0d",
          scenario,lanes,memory_delay,random_stalls,seed,per_lane*lanes,cycle-start_cycle,ar_total-ar_start,aw_total-aw_start,
          latency_sum,a_stalls,d_stalls,read_peak,write_peak,parallel2,parallel3,parallel4,bank_requests[0],bank_requests[1],bank_requests[2],bank_requests[3]);
    end
    measuring=0;
endtask
initial begin
    if($value$plusargs("LANES=%d",lanes)) begin end
    if($value$plusargs("CASE=%d",scenario)) begin end
    if($value$plusargs("DELAY=%d",memory_delay)) begin end
    if($value$plusargs("COUNT=%d",count)) begin end
    if($value$plusargs("SEED=%d",seed)) begin end
    random_stalls=$test$plusargs("STALLS");rng=32'(seed);
    if(lanes<1 || lanes>4 || count<1) $fatal(1,"bad configuration");
    a_valid=0;d_ready=0;
    memory.arready=0;memory.awready=0;memory.wready=0;memory.rvalid=0;memory.bvalid=0;
    for(integer i=0;i<4;i++) begin
        issued[i]=0;completed[i]=0;write_beat[i]=0;id_live[i]=0;id_peak[i]=0;bank_requests[i]=0;
        a_opcode[i]=4;a_source[i]=0;a_address[i]=0;a_data[i]=0;
        for(integer j=0;j<32;j++) begin source_busy[i][j]=0;source_write[i][j]=0;response_beat[i][j]=0;end
    end
    repeat(6) @(negedge clock);reset=0;repeat(540) @(negedge clock);
    if(scenario==0 || scenario==1) pass(64,0);
    if(scenario==3 || scenario==4) begin
        count=((scenario==3 ? 12288 : 20480)+lanes-1)/lanes;
        repeat(4) pass(count,0);
    end
    pass(count,1);
    if(read_peak>32 || write_peak>32) $fatal(1,"Head outstanding limit exceeded");
    $display("BANKED_MEMORY_SCOREBOARD=PASS case=%0d cycles=%0d",scenario,cycle);
    $finish;
end
