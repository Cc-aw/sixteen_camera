    integer cycle=0, sent=0, completed=0, outer_sent=0, outer_done=0;
    integer schedule_count=0, eligible_bubbles=0, pool_peak=0;
    integer scenario=0, memory_delay=32, count=512, source_window=24, seed=151034;
    integer start_cycle, measure_schedule, measure_bubbles;
    integer issue_index=0, qwrite=0, qread=0;
    integer ack_write=0, ack_read=0, clean_ack_delay=0;
    integer ack_source[128];
    reg returning_ack=0, endpoint_locked=0, prefer_ack=1;
    integer return_cycle[4096], return_source[4096], return_opcode[4096];
    reg [32:0] return_address[4096], expected_address[256];
    reg source_busy[256];
    integer received_beats[256];
    reg [31:0] rng=32'h170719;
    reg random_stalls=0, measuring=0;
    reg [32:0] address_now;
    reg [255:0] expected_data;
    function automatic [511:0] line_data(input [32:0] addr);
        for(integer i=0;i<64;i++) line_data[i*8+:8]=8'((addr>>6)*17+i*3+(addr>>28));
    endfunction
    function automatic [32:0] address_for(input integer n, input integer kind);
        case(kind)
        0: address_for=33'h80000000+33'((n%64)*64);
        1: address_for=33'h80000000+33'((n%4)*131072);
        2: address_for=33'h81000000+33'((n%64)*64+(n/64)*16384);
        default: address_for=33'h82000000+33'(((n/3)%4)*131072);
        endcase
    endfunction
    always @(posedge clock) begin
        cycle=cycle+1;
        if(!reset) begin
            if(io_in_a_valid && io_in_a_ready) begin
                if(source_busy[io_in_a_bits_source]) $fatal(1,"source reused");
                source_busy[io_in_a_bits_source]=1;
                expected_address[io_in_a_bits_source]=io_in_a_bits_address;
                received_beats[io_in_a_bits_source]=0;
                sent++;
            end
            if(io_out_a_valid && io_out_a_ready) begin
                if(io_out_a_bits_opcode!=6) $fatal(1,"unexpected outer A opcode=%d",io_out_a_bits_opcode);
                return_source[qwrite%4096]=io_out_a_bits_source;
                return_address[qwrite%4096]=io_out_a_bits_address;
                return_opcode[qwrite%4096]=5;
                return_cycle[qwrite%4096]=cycle+memory_delay;
                qwrite++;outer_sent++;
            end
            if(io_out_c_valid && io_out_c_ready) begin
                if(io_out_c_bits_opcode!=6) $fatal(1,"unexpected dirty release in read-only workload");
                if(clean_ack_delay!=0) begin
                    return_source[qwrite%4096]=io_out_c_bits_source;
                    return_address[qwrite%4096]=io_out_c_bits_address;
                    return_opcode[qwrite%4096]=6;
                    return_cycle[qwrite%4096]=cycle+memory_delay;
                    qwrite++;
                end else begin
                    // TLCacheCork answers clean Release locally. It does not
                    // send one to DDR or wait behind a pending DDR read.
                    ack_source[ack_write%128]=io_out_c_bits_source;ack_write++;
                end
            end
            endpoint_locked=io_out_d_valid && !io_out_d_ready;
            if(io_out_d_valid && io_out_d_ready) begin
                if(returning_ack) ack_read++;else qread++;
                prefer_ack=!returning_ack;outer_done++;
            end
            if(io_in_b_valid) $fatal(1,"unexpected probe in noncoherent Get workload");
            if(io_in_d_valid && io_in_d_ready) begin
                if(io_in_d_bits_source>=source_window || !source_busy[io_in_d_bits_source]) $fatal(1,"unexpected source");
                if(io_in_d_bits_opcode!=1 || io_in_d_bits_denied || io_in_d_bits_corrupt) $fatal(1,"bad response status");
                address_now=expected_address[io_in_d_bits_source];
                expected_data=256'(line_data(address_now)>>(256*received_beats[io_in_d_bits_source]));
                if(io_in_d_bits_data!==expected_data) $fatal(1,"data mismatch src=%0d beat=%0d addr=%h got=%h expected=%h",io_in_d_bits_source,received_beats[io_in_d_bits_source],address_now,io_in_d_bits_data,expected_data);
                received_beats[io_in_d_bits_source]++;
                if(received_beats[io_in_d_bits_source]==2) begin source_busy[io_in_d_bits_source]=0;completed++;end
            end
            if(measuring) begin
                if(|dut.mshr_selectOH) schedule_count++;
                if(bench_eligible && !(|dut.mshr_selectOH)) eligible_bubbles++;
                if($countones(dut.requests.used)>pool_peak) pool_peak=$countones(dut.requests.used);
            end
        end
        if(cycle>500000) $fatal(1,"timeout sent=%0d completed=%0d q=%0d/%0d",sent,completed,qread,qwrite);
    end
    always @(negedge clock) begin
        if(!reset) begin
            rng={rng[30:0],rng[31]^rng[21]^rng[1]^rng[0]};
            io_in_d_ready=!random_stalls || (rng[0] || rng[3]);
            io_out_a_ready=!random_stalls || (rng[1] || rng[6]);
            io_out_c_ready=1;
            if(!endpoint_locked) returning_ack=ack_write>ack_read &&
                (prefer_ack || !(qwrite>qread && cycle>=return_cycle[qread%4096]));
            io_out_d_valid=returning_ack ? ack_write>ack_read : qwrite>qread && cycle>=return_cycle[qread%4096];
            io_out_d_bits_source=returning_ack ? 5'(ack_source[ack_read%128]) : 5'(return_source[qread%4096]);
            io_out_d_bits_opcode=returning_ack ? 6 : 3'(return_opcode[qread%4096]);
            io_out_d_bits_param=0;
            io_out_d_bits_size=6;
            io_out_d_bits_data=returning_ack ? '0 : line_data(return_address[qread%4096]);
        end
    end
    task automatic request(input integer n,input integer kind);
        @(negedge clock);
        while(source_busy[n%source_window]) @(negedge clock);
        io_in_a_bits_source=SOURCE_BITS'(n%source_window);
        io_in_a_bits_address=address_for(n,kind);
        io_in_a_bits_opcode=4;io_in_a_bits_size=6;io_in_a_bits_mask='1;
        io_in_a_valid=1;
        do @(posedge clock);while(!io_in_a_ready);
        @(negedge clock);io_in_a_valid=0;
    endtask
    initial begin
        if($value$plusargs("DELAY=%d",memory_delay)) begin end
        if($value$plusargs("WINDOW=%d",source_window)) begin end
        if($value$plusargs("COUNT=%d",count)) begin end
        if($value$plusargs("SEED=%d",seed)) begin end
        if($value$plusargs("CLEAN_ACK_DELAY=%d",clean_ack_delay)) begin end
        if(source_window<1 || source_window>256) $fatal(1,"invalid window");
        random_stalls=$test$plusargs("STALLS");
        for(integer s=0;s<256;s++) begin source_busy[s]=0;received_beats[s]=0;end
        repeat(6) @(negedge clock);reset=0;
        repeat(530) @(negedge clock);
        for(integer kind=0;kind<4;kind++) begin
            // Isolate replacement history and warm-up from the measured phase.
            wait(qwrite==qread && ack_write==ack_read);@(negedge clock);reset=1;
            repeat(4) @(negedge clock);reset=0;
            repeat(530) @(negedge clock);
            // First pass fills the cache for the hot-line scenarios.
            if(kind!=2) begin
                for(integer n=0;n<64;n++) request(n,kind);
                wait(completed==sent);repeat(12) @(negedge clock);
            end
            start_cycle=cycle;measure_schedule=schedule_count;measure_bubbles=eligible_bubbles;pool_peak=0;
            rng=32'(seed) ^ 32'(kind) ^ 32'(memory_delay<<8);
            measuring=1;
            for(integer n=0;n<count;n++) begin
                request(n,kind);
                if(source_window==1) begin wait(completed==sent);@(negedge clock);end
            end
            wait(completed==sent);@(negedge clock);measuring=0;
            $display("L2_PERF case=%0d window=%0d delay=%0d stalls=%0d seed=%0d requests=%0d cycles=%0d schedules=%0d eligible_bubbles=%0d secondary_peak=%0d",kind,source_window,memory_delay,random_stalls,seed,count,cycle-start_cycle,schedule_count-measure_schedule,eligible_bubbles-measure_bubbles,pool_peak);
            repeat(12) @(negedge clock);
        end
        $display("L2_PERF_SCOREBOARD=PASS accepted=%0d completed=%0d outer=%0d",sent,completed,outer_sent);
        $finish;
    end
