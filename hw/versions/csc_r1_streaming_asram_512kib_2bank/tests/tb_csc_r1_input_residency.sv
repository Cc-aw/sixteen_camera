`timescale 1ns/1ps
module tb_csc_r1_input_residency;
    reg clock=0;
    always #5 clock=~clock;
    reg reset=1, enabled=1, clear=0, fault=0, core_idle=1, quiescent=1;
    reg passthrough=0, req_valid=0, engine_ready=1, req_supported=1, req_preserves=0, req_half=0;
    reg [231:0] req_key=232'h123;
    reg [14:0] req_rows=64;
    reg [39:0] req_source=40'h20000000;
    reg [40:0] req_source_end=41'h20001000;
    reg generator_idle=0, generator_half=0;
    reg [7:0] write_valid=0, write_input=0;
    reg [111:0] write_rows=0;
    reg source_write=0;
    reg [39:0] source_write_address=0;
    reg [6:0] source_write_bytes=32;
    wire req_ready, hit, wait_for_commit, accepted, skipped, completion;
    wire [1:0] resident_valid, resident_building;
    wire [63:0] resident_owner;
    wire [31:0] engine_owner;
    CscR1InputResidency dut(.*);
    integer checks=0, skips=0, completions=0;
    always @(posedge clock) if(!reset) begin
        skips=skips+skipped;
        completions=completions+completion;
    end
    task tick;
        begin @(posedge clock); #1; @(negedge clock); #1; end
    endtask
    task check(input reg condition, input [511:0] message);
        begin checks=checks+1; if(!condition) $fatal(1,"%0s",message); end
    endtask
    task reboot;
        begin
            reset=1; req_valid=0; fault=0; source_write=0; write_valid=0;
            clear=0; enabled=1; passthrough=0; quiescent=1; core_idle=1;
            generator_idle=0; req_supported=1; req_preserves=0; engine_ready=1;
            tick; reset=0; repeat(4) tick;
        end
    endtask
    task fill(input reg half);
        begin
            req_half=half; generator_half=half; generator_idle=0;
            req_valid=1; #1; check(accepted&&!hit,"cold miss must use real engine");
            tick; req_valid=0; quiescent=0;
            generator_idle=1; tick;
            check(!resident_valid[half],"credits without commits cannot promote");
            repeat(3) tick;
            quiescent=1; tick;
            check(resident_valid[half],"fully committed tile must promote");
            generator_idle=0;
        end
    endtask
    task perform_skip;
        begin
            req_valid=1; #1; check(hit&&skipped,"exact full tile must skip");
            tick; req_valid=0; generator_idle=1;
            #1; check(completion,"skip must produce one null-generator completion");
            tick; check(!completion,"replacement completion duplicated");
            generator_idle=0;
        end
    endtask
    initial begin
        reboot; fill(0); perform_skip;
        req_preserves=1; req_supported=0; req_valid=1; tick; req_valid=0;
        check(resident_valid[0],"native null Input must preserve residency");
        req_preserves=0; req_supported=1;
        engine_ready=0; req_valid=1; #1;
        check(!accepted&&!skipped,"engine backpressure must hold replacement request");
        tick; req_valid=0; engine_ready=1;
        // Same source, other physical half: no relocation.
        req_half=1; #1; check(!hit,"same source other half must miss");
        fill(1); perform_skip;
        req_half=0; generator_half=0;
        #1; check(hit,"other-half fill must retain first half");
        // Request shape, source version/range and format are exact, not hashed.
        for(integer bit_index=0;bit_index<232;bit_index=bit_index+1) begin
            req_key[bit_index]=!req_key[bit_index]; #1;
            check(!hit,"every signature bit must participate");
            req_key[bit_index]=!req_key[bit_index];
        end
        req_source=req_source+1; #1; check(!hit,"source address mismatch"); req_source=req_source-1;
        req_source_end=req_source_end+1; #1; check(!hit,"source extent mismatch"); req_source_end=req_source_end-1;
        req_rows=65; #1; check(!hit,"physical extent mismatch"); req_rows=64;
        req_supported=0; req_valid=1; #1;
        check(!hit,"unsupported geometry fallback");
        check(req_ready&&accepted&&!wait_for_commit,"unsafe future Store must reload without waiting for its consumer");
        req_valid=0; req_supported=1;
        // A busy bank or outstanding store delays a potential hit.
        quiescent=0; req_valid=1; #1;
        check(wait_for_commit&&!req_ready&&!skipped,"pending bank commit must block exact hit");
        repeat(3) tick; req_valid=0; quiescent=1;
        // A foreign writer invalidates even if it would write equal data.
        write_valid=1; write_input=0; write_rows=0; #1;
        check(!hit,"same-cycle foreign writer must block skip"); tick; write_valid=0;
        check(!resident_valid[0]&&resident_valid[1],"physical half isolation");
        fill(0);
        // Equal Input writes also invalidate an already resident descriptor.
        write_valid=1; write_input=1; tick; write_valid=0;
        check(!resident_valid[0],"resident Input overwrite must invalidate");
        fill(0);
        source_write=1; source_write_address=req_source_end; #1;
        check(hit,"adjacent disjoint source writer must retain tile"); tick;
        source_write_address=req_source-32; #1;
        check(hit,"writer ending at source start is disjoint"); tick;
        source_write_address=req_source_end-1; #1;
        check(!hit,"same-cycle source overlap must block hit"); tick; source_write=0;
        check(resident_valid==0,"both descriptors sharing changed source must invalidate");
        // Invalidations win over simultaneous last-commit promotion.
        req_valid=1; generator_idle=0; tick; req_valid=0;
        quiescent=0; generator_idle=1; tick;
        quiescent=1; write_valid=1; write_input=0; tick; write_valid=0;
        check(!resident_valid[0]&&!resident_building[0],"writer wins promotion race");
        generator_idle=0; fill(0);
        clear=1; #1; check(!hit,"HOST/DRAIN/frame clear blocks same-cycle hit"); tick; clear=0;
        check(resident_valid==0,"boundary clears descriptors"); repeat(3) tick;
        fill(0); enabled=0; req_valid=1; #1;
        check(!hit&&req_ready,"disabled mode must preserve original ready"); tick; req_valid=0;
        check(resident_valid==0,"disable clears residency"); enabled=1; repeat(4) tick;
        fill(0); passthrough=1; core_idle=0; tick; passthrough=0;
        req_valid=1; #1; check(!hit&&req_ready,"raw/WS command quarantine fallback");
        tick; req_valid=0; check(!resident_building[0],"quarantine cannot create descriptors");
        core_idle=1; repeat(3) tick; fill(0);
        fault=1; #1; check(!hit,"late denied/corrupt blocks hit"); tick; fault=0;
        clear=1; tick; clear=0; repeat(4) tick;
        req_valid=1; tick; req_valid=0;
        check(!resident_valid[0]&&!resident_building[0],"fault stays disabled until real reset");
        reboot;
        req_half=0; generator_half=0; req_valid=1; tick; req_valid=0;
        quiescent=0; generator_idle=1; req_valid=1; #1;
        check(!accepted&&wait_for_commit,"duplicate tile must wait for its in-flight fill");
        tick; quiescent=1; tick;
        #1; check(hit&&accepted,"completed fill must release waiting exact request");
        tick; req_valid=0; tick;
        generator_idle=0;
        check(skips==completions,"waited fill completion ledger");
        reboot; fill(0); perform_skip;
        check(engine_owner!=0&&resident_owner[31:0]!=0,"writer generation cannot be unowned");
        // A recycled Input tag from an older tile is foreign to this build.
        req_key=req_key+1; req_valid=1; generator_idle=0; tick; req_valid=0;
        check(engine_owner==resident_owner[31:0],"accepted tile owns its writes");
        write_input=1; write_valid=1; tick;
        check(resident_building[0],"own Input writer must not cancel build");
        write_input=0; tick; write_valid=0;
        check(!resident_building[0],"old Input generation must cancel build");
        // Exhaustion disables the fast path rather than aliasing generation 1.
        dut.next_owner=32'hffffffff; req_valid=1; tick; req_valid=0;
        generator_idle=1; repeat(4) tick;
        check(!hit,"generation exhaustion must fail closed");
        check(skips==completions,"replacement completion ledger");
        $display("CSC_R1_UNIT_PASS checks=%0d skips=%0d completions=%0d",checks,skips,completions);
        $finish;
    end
    initial begin #100000; $fatal(1,"unit deadlock"); end
endmodule
