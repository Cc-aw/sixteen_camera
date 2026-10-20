`timescale 1ns/1ps
module tb_csc_r1_store_disjoint;
    reg active=1, known=1, no_pool=1, transpose=0;
    reg [15:0] batches=1, rows=4, cols=4, outer_cols=4, stride=32, channels=32;
    reg [39:0] base=40'h20002000, source=40'h20000000;
    reg [40:0] source_end=41'h20000200;
    wire disjoint;
    CscR1StoreDisjoint dut(.*);
    integer checks=0;
    task check(input reg expected, input [511:0] message);
        begin #1; checks=checks+1; if(disjoint!==expected) $fatal(1,"%0s",message); end
    endtask
    initial begin
        check(1,"future disjoint Store must allow EX/Store overlap");
        base=source; check(0,"in-place output must fall back to real Input load");
        base=source+511; check(0,"last source byte overlap");
        base=source_end; check(1,"aligned output immediately after input");
        base=source-512; check(1,"aligned output immediately before input");
        base=source-511; check(0,"one byte overlap before input");
        base=source_end+1; source_end=source_end+1;
        check(0,"masked TL beat envelope overlaps source");
        source_end=41'h20000200; base=40'h20002000;
        known=0; check(0,"not-yet-derived slot cannot prove safety");
        active=0; check(1,"inactive slot does not block"); active=1; known=1;
        no_pool=0; check(0,"pool fallback"); no_pool=1;
        transpose=1; check(0,"transpose fallback"); transpose=0;
        batches=2; check(0,"batch fallback"); batches=1;
        rows=0; check(0,"empty geometry fallback"); rows=4;
        cols=5; check(0,"invalid width fallback"); cols=4;
        channels=33; check(0,"invalid stride fallback"); channels=32;
        rows=65535; cols=65535; outer_cols=65535; stride=65535;
        check(0,"generator offset wrap fallback");
        rows=4; cols=4; outer_cols=4; stride=32;
        base=40'h1ffffff00; check(0,"physical source wrap fallback");
        base=0; known=0; check(1,"native null output emits no Store");
        $display("CSC_STORE_DISJOINT_PASS checks=%0d",checks); $finish;
    end
endmodule
