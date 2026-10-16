    integer probe_cycle=0, probe_delay=0;
    integer probe_start, probe_reads, probe_done, probe_ar_cycle, probe_last_cycle;
    integer probe_issue [IDS][64];
    integer probe_iw [IDS];
    integer probe_min, probe_max, probe_sum;
    reg probe_serial=0;
    always @(posedge clk) begin
        probe_cycle=probe_cycle+1;
        if(!resetn) begin
            for(integer p=0;p<IDS;p++) probe_iw[p]=0;
        end else begin
            if(d.arvalid && d.arready) begin
                probe_issue[d.arid][probe_iw[d.arid]%64]=probe_cycle;
                probe_iw[d.arid]++;
            end
            if(probe_serial && s.arvalid && s.arready) probe_ar_cycle=probe_cycle;
            if(probe_serial && s.rvalid && s.rready && s.rlast) begin
                probe_last_cycle=probe_cycle;
                if(probe_cycle-probe_ar_cycle<probe_min) probe_min=probe_cycle-probe_ar_cycle;
                if(probe_cycle-probe_ar_cycle>probe_max) probe_max=probe_cycle-probe_ar_cycle;
                probe_sum+=probe_cycle-probe_ar_cycle;
            end
        end
    end
