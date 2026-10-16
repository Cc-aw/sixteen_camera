        if($test$plusargs("DDR_PROBE")) begin
            if($value$plusargs("DELAY=%d",probe_delay)) begin end
            probe_serial=1;probe_min=100000;probe_max=0;probe_sum=0;
            for(integer n=0;n<128;n++) begin
                send(0,33'h11000000+33'(n*BYTES));
                wait(completed==accepted);@(negedge clk);
            end
            probe_serial=0;
            $display("DDR_PROBE decouple=%0d delay=%0d case=serial_1beat count=128 min_latency=%0d max_latency=%0d total_latency=%0d",READ_DECOUPLE,probe_delay,probe_min,probe_max,probe_sum);
            for(integer burst=1;burst<=4;burst=burst*4) begin
                probe_start=probe_cycle;probe_done=completed;
                for(integer n=0;n<256;n++) send(n%IDS,33'h12000000+33'(n*4096),burst-1);
                wait(completed==accepted);@(negedge clk);
                $display("DDR_PROBE decouple=%0d delay=%0d case=pipelined_%0dbeat count=%0d elapsed=%0d",READ_DECOUPLE,probe_delay,burst,completed-probe_done,probe_cycle-probe_start);
            end
            // One AR every cycle when the endpoint and credits permit it.
            probe_start=probe_cycle;probe_done=completed;
            @(negedge clk);s.arvalid=1;s.arlen=0;s.arsize=3'(SHIFT);s.arburst=1;
            for(integer n=0;n<256;n++) begin
                s.arid=ID_WIDTH'(n%IDS);s.araddr=33'h14000000+33'(n*4096);
                do @(posedge clk);while(!s.arready);
                @(negedge clk);
            end
            s.arvalid=0;wait(completed==accepted);@(negedge clk);
            $display("DDR_PROBE decouple=%0d delay=%0d case=continuous_1beat count=%0d elapsed=%0d",READ_DECOUPLE,probe_delay,completed-probe_done,probe_cycle-probe_start);
            $display("DDR_PROBE_SCOREBOARD=PASS accepted=%0d completed=%0d beats=%0d",accepted,completed,beats);
            $finish;
        end
