`timescale 1ns/1ps
module tb_memory_v3_counters;
    reg soc_clk=0, ddr_clk=0, resetn=0;
    always #5 soc_clk=~soc_clk;
    always #1.667 ddr_clk=~ddr_clk;
    reg request=0;
    reg [2:0] command=0;
    wire acknowledge,available;
    reg [1535:0] events=0;
    wire [6143:0] snapshots;
    memory_perf_async_group dut(.*,.dst_clk(soc_clk),.src_clk(ddr_clk));
    reg arvalid=0, rvalid=0;
    wire [511:0] axi_events;
    memory_perf_axi_events axi (
        .clk(ddr_clk),.resetn(resetn),.arvalid(arvalid),.arready(1'b1),
        .awvalid(1'b0),.awready(1'b0),.rvalid(rvalid),.rready(1'b1),.rlast(1'b1),
        .wvalid(1'b0),.wready(1'b0),.bvalid(1'b0),.bready(1'b0),
        .arlen(8'd0),.arsize(3'd6),.wstrb(64'd0),.events(axi_events)
    );
    task automatic cmd(input [2:0] value);
        @(negedge soc_clk);command=value;request=~request;
        do @(negedge soc_clk);while(acknowledge!=request);
    endtask
    reg [6143:0] saved;
    reg [63:0] cycle_count, timestamp;
    initial begin
        for(integer b=0;b<3;b++) begin
            events[b*512+:16]=1;
            events[b*512+16+:16]=16'(b+2);
            events[b*512+15*16+:16]=7;
        end
        repeat(7) @(negedge soc_clk);resetn=1;
        wait(available);
        cmd(1);
        repeat(41) @(negedge ddr_clk);
        cmd(2);cmd(4);
        cycle_count=snapshots[0+:64];timestamp=snapshots[31*64+:64];
        if(cycle_count<41 || timestamp<=cycle_count) $fatal(1,"clock/window count");
        for(integer b=0;b<3;b++) begin
            if(snapshots[b*2048+:64]!==cycle_count ||
               snapshots[b*2048+64+:64]!==cycle_count*(b+2) ||
               snapshots[b*2048+15*64+:64]!==64'd7 ||
               snapshots[b*2048+31*64+:64]!==timestamp) $fatal(1,"snapshot incoherent bank=%0d",b);
        end
        saved=snapshots;
        repeat(35) @(negedge soc_clk);
        if(snapshots!==saved) $fatal(1,"frozen data changed");
        // Tracking survives a measurement clear while reads are outstanding.
        @(negedge ddr_clk);arvalid=1;
        repeat(2) @(negedge ddr_clk);arvalid=0;
        if(axi_events[13*16+:16]!=2) $fatal(1,"AR tracking");
        cmd(3);cmd(4);
        if(snapshots[0+:64]!=0 || snapshots[64+:64]!=0) $fatal(1,"clear failed");
        if(axi_events[13*16+:16]!=2) $fatal(1,"measurement clear changed credits");
        @(negedge ddr_clk);rvalid=1;
        repeat(2) @(negedge ddr_clk);rvalid=0;
        if(axi_events[13*16+:16]!=0) $fatal(1,"R tracking after clear");
        // Snapshot while running, then ensure counting continues afterward.
        cmd(1);repeat(13) @(negedge soc_clk);cmd(4);
        cycle_count=snapshots[0+:64];saved=snapshots;
        repeat(17) @(negedge soc_clk);
        if(snapshots!==saved) $fatal(1,"live count leaked into snapshot");
        cmd(4);if(snapshots[0+:64]<=cycle_count) $fatal(1,"snapshot stopped counting");
        // Reset during a request, as the SoC and DDR reset handshake requires.
        @(negedge soc_clk);command=4;request=~request;
        #1;resetn=0;request=0;command=0;
        repeat(6) @(negedge soc_clk);resetn=1;wait(available);cmd(4);
        if(snapshots[0+:64]!=0) $fatal(1,"reset did not stop counters");
        $display("MEMORY_V3_COUNTERS_PASS cdc=100/300MHz count=yes frozen=yes clear_inflight=yes reset_inflight=yes");
        $finish;
    end
    initial begin #100000; $fatal(1,"counter timeout"); end
endmodule
