`timescale 1ns/1ps
module tb_router;
    reg clock=0;
    always #5 clock=~clock;
    reg reset=1,in_valid=0;
    wire in_ready,busy;
    reg [6:0] in_opcode=0,in_funct=0;
    reg [63:0] in_rs1=0,in_rs2=0;
    reg [3:0] out_ready=0;
    wire [3:0] out_valid;
    wire [27:0] out_funct;
    wire [255:0] out_rs1,out_rs2;
    RouterProbe dut(.*);
    integer received=0,expected=0;
    function automatic [6:0] opcode(input integer lane);
        case(lane)
            0:opcode=7'h0b;
            1:opcode=7'h2b;
            2:opcode=7'h5b;
            3:opcode=7'h7b;
        endcase
    endfunction
    task tick;
        @(posedge clock);#1;@(negedge clock);
    endtask
    always @(posedge clock)if(!reset)begin
        if(!$onehot0(out_valid))$fatal(1,"multiple RoCC routes active");
        for(integer lane=0;lane<4;lane=lane+1)begin
            if(out_valid[lane] && out_ready[lane])begin
                if(out_rs1[64*lane+:64]!==64'(expected) ||
                   out_rs2[64*lane+:64]!==~64'(expected) ||
                   out_funct[7*lane+:7]!==7'(expected%22) || lane!=expected%4)
                    $fatal(1,"RoCC route/payload/order mismatch expected=%0d lane=%0d",expected,lane);
                received=received+1;expected=expected+1;
            end
        end
    end
    initial begin
        repeat(3)tick();reset=0;
        for(integer pair=0;pair<8;pair=pair+1)begin
            // Fill the native Queue(io.in, 2), holding every destination.
            out_ready=0;
            for(integer k=0;k<2;k=k+1)begin
                in_valid=1;in_opcode=opcode((pair*2+k)%4);
                in_funct=7'((pair*2+k)%22);
                in_rs1=64'(pair*2+k);in_rs2=~in_rs1;
                #1;if(!in_ready)$fatal(1,"native RoCC queue capacity lost");
                tick();
            end
            in_valid=0;in_opcode=0;in_rs1='1;in_rs2=0;#1;
            if(in_ready)$fatal(1,"full queue advertised capacity");
            repeat(9)tick();
            if(received!=pair*2)$fatal(1,"RoCC leaked command under stall");
            // Replay has withdrawn valid and opcode. Capacity must recover
            // after drain without requiring a new matching command first.
            out_ready='1;tick();tick();#1;
            if(!in_ready || busy || received!=(pair+1)*2)
                $fatal(1,"native RoCC ready did not recover with valid low");
            repeat(3)tick();
        end
        $display("S1_ROCC_ROUTER_PASS,commands=%0d,routes=4,valid_withdrawal=1,queue_depth=2",received);
        $finish;
    end
    initial begin #100000;$fatal(1,"RoCC router timeout");end
endmodule
