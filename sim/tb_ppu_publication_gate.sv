`timescale 1ns/1ps
module tb_ppu_publication_gate;
    reg clk=0;always #5 clk=~clk;
    reg resetn=0,request=0,enable=1;
    reg [1:0] command_bank=1;
    reg [31:0] command_version=7;
    reg [3:0] allocated=2,fault=0;
    reg [127:0] versions=128'd7<<32;
    reg [23:0] ready_heads=0;
    reg publication_active=0,core_busy=0,core_done=1,core_error=0;
    wire [1:0] lease_bank;wire [31:0] lease_version;
    wire [5:0] core_heads;wire core_abort;
    wire acquire,release_slot,core_start,busy,done,error;
    integer starts=0;
    ppu_publication_gate dut(.*);
    always @(posedge clk) if(core_start) begin
        if(enable && !ready_heads[6]) $fatal(1,"partial head launched");
        starts<=starts+1;
    end
    initial begin
        repeat(3) @(negedge clk);resetn=1;request=1;
        @(negedge clk);request=0;ready_heads[11:6]=6;
        repeat(10) @(negedge clk);
        if(!busy || core_start || done) $fatal(1,"gate ignored readiness");
        command_bank=2;command_version=99; // accepted descriptor must remain stable
        ready_heads[11:6]=63;wait(core_start);@(negedge clk);
        if(lease_bank!=1 || lease_version!=7) $fatal(1,"descriptor changed in flight");
        core_busy=1;core_done=0;repeat(6) @(negedge clk);core_busy=0;core_done=1;
        wait(done);@(negedge clk);if(error || starts!=1) $fatal(1,"normal completion");
        request=1;@(negedge clk);request=0;wait(done);@(negedge clk);
        if(!error || starts!=1) $fatal(1,"invalid generation launched");
        enable=0;request=1;@(negedge clk);request=0;wait(core_start);@(negedge clk);
        core_busy=1;core_done=0;repeat(3) @(negedge clk);core_busy=0;core_done=1;
        wait(done);@(negedge clk);if(error || starts!=2) $fatal(1,"legacy ABI");
        $display("PPU_PUBLICATION_GATE=PASS");$finish;
    end
    initial begin repeat(200) @(posedge clk);$fatal(1,"gate timeout");end
endmodule
