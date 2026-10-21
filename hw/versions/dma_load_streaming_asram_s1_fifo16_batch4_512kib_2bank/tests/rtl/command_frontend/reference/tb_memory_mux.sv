`timescale 1ns/1ps
module tb_memory_mux;
  reg clock=0; always #5 clock=~clock;
  reg reset=1;
  reg f_req_valid=0; wire f_req_ready; reg [31:0] f_req_address=32'h80001000;
  wire f_resp_valid; reg f_resp_ready=1; wire [255:0] f_resp_data; wire f_resp_error;
  reg g_a_valid=0; wire g_a_ready; reg [2:0] g_a_opcode=4,g_a_param=0;
  reg [3:0] g_a_size=5; reg [4:0] g_a_source=0;
  reg [31:0] g_a_address=32'h80002000,g_a_mask='1; reg [255:0] g_a_data=0; reg g_a_corrupt=0;
  wire g_d_valid; reg g_d_ready=1; wire [2:0] g_d_opcode; wire [1:0] g_d_param;
  wire [3:0] g_d_size; wire [4:0] g_d_source,g_d_sink; wire g_d_denied,g_d_corrupt; wire [255:0] g_d_data;
  wire a_valid; reg a_ready=0; wire [2:0] a_opcode,a_param; wire [3:0] a_size;
  wire [4:0] a_source; wire [31:0] a_address,a_mask; wire [255:0] a_data; wire a_corrupt;
  reg d_valid=0; wire d_ready; reg [2:0] d_opcode=1; reg [1:0] d_param=0;
  reg [3:0] d_size=5; reg [4:0] d_source=0,d_sink=0; reg d_denied=0,d_corrupt=0; reg [255:0] d_data=0;
  GemminiFrontendMemoryMux dut(.*);
  task tick; @(posedge clock); #1; @(negedge clock); endtask
  task response(input [4:0] source,input [3:0] size,input [2:0] opcode,input integer beats);
    d_source=source;d_size=size;d_opcode=opcode;d_valid=1;
    repeat(beats) tick();
    d_valid=0;
  endtask
  initial begin
    repeat(3) tick();reset=0;
    // A stall must lock a selected DMA producer when a fetch arrives later.
    g_a_valid=1;g_a_source=31;g_a_size=6;
    tick();f_req_valid=1;#1;
    if(a_source!=31 || a_address!=g_a_address) $fatal(1,"stalled A changed owner");
    a_ready=1;tick();g_a_valid=0;#1;
    if(f_req_ready) $fatal(1,"fetch reused DMA source31");
    // Two-beat DMA response: source is not released after first beat.
    d_source=31;d_size=6;d_opcode=1;d_valid=1;#1;
    if(!g_d_valid || f_resp_valid) $fatal(1,"DMA routed to fetcher");
    tick();#1;if(f_req_ready) $fatal(1,"early source31 release");
    tick();d_valid=0;#1;
    if(!f_req_ready) $fatal(1,"fetch did not acquire released ID");
    tick();f_req_valid=0;
    // Concurrent source0 DMA must pass while fetch owns source31.
    g_a_valid=1;g_a_source=0;g_a_size=5;tick();g_a_valid=0;
    response(0,5,1,1);
    d_source=31;d_size=5;d_opcode=1;d_valid=1;f_resp_ready=0;d_data=256'habc;
    #1;if(!f_resp_valid || g_d_valid || d_ready) $fatal(1,"fetch response backpressure");
    tick();f_resp_ready=1;tick();d_valid=0;
    // Multibeat Put is not interleaved with FE requests.
    g_a_valid=1;g_a_opcode=0;g_a_size=6;g_a_source=31;g_a_data=11;
    tick();f_req_valid=1;g_a_data=22;#1;
    if(a_opcode!=0 || a_data!=22 || f_req_ready) $fatal(1,"Put burst interrupted");
    tick();g_a_valid=0;response(31,6,0,1);
    tick();f_req_valid=0;response(31,5,1,1);
    // Zero-latency response and denial propagation.
    f_req_valid=1;d_source=31;d_size=5;d_opcode=1;d_denied=1;d_valid=1;
    #1;if(!f_resp_valid || !f_resp_error || g_d_valid) $fatal(1,"same cycle response lost");
    tick();f_req_valid=0;d_valid=0;d_denied=0;
    if(dut.id31_busy) $fatal(1,"same cycle request did not retire");
    $display("MEMORY_MUX_PASS,source31_collision=covered,multibeat=covered,backpressure=covered,zero_latency=covered");
    $finish;
  end
  initial begin #50000;$fatal(1,"timeout");end
endmodule
