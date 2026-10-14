`timescale 1ns/1ps
module tb_event_pipeline;
    reg clk=0; always #2 clk=~clk;
    reg resetn=0, enable=0, valid=0, boundary=0, fault=0, ready=0;
    reg [7:0] data=0;
    wire accepted, out_valid, out_boundary, out_resync, fault_pulse;
    wire [7:0] out_data;
    wire [31:0] overflow;
    reg [13:0] expected[$];
    integer cycles=0, received=0, sent=0;
    reg compare=1;
    dvp_event_bridge #(.FIFO_DEPTH(16)) dut(
      .capture_clk(clk),.capture_resetn(resetn),.capture_enable(enable),
      .event_valid(valid),.event_ready(accepted),.event_data(data),.event_byte_valid(!boundary),
      .event_line_start(1'b0),.event_line_last(1'b0),.event_line_end(1'b0),
      .event_frame_boundary(boundary),.event_fault(fault),
      .video_clk(clk),.video_resetn(resetn),.video_event_valid(out_valid),
      .video_event_ready(ready),.video_event_data(out_data),.video_byte_valid(),
      .video_line_start(),.video_line_last(),.video_line_end(),
      .video_frame_boundary(out_boundary),.video_resync(out_resync),
      .video_fault_pulse(fault_pulse),.overflow_count(overflow));
    always @(posedge clk) if(resetn) begin
        reg [13:0] item;
        cycles++;
        if(cycles>10000) $fatal(1,"event timeout");
        if(valid && accepted) begin
            item={dut.restart_record || fault,boundary,3'b0,!boundary,data};
            expected.push_back(item); sent++;
        end
        if(out_valid && ready) begin
            if(expected.size()==0) $fatal(1,"unexpected FIFO event");
            item=expected.pop_front();
            if(dut.fifo_dout!==item) $fatal(1,"event ordering/payload mismatch actual=%h expected=%h",dut.fifo_dout,item);
            received++;
        end
        if(dut.fifo_write_q && dut.fifo_full && !dut.fifo_reset)
            $fatal(1,"registered event overflowed reserved FIFO slot");
    end
    task automatic drive(input bit v,b,input integer d,input bit r);
        @(negedge clk); valid=v; boundary=b; data=8'(d); ready=r;
    endtask
    initial begin
        repeat(8) @(negedge clk);
        resetn=1; enable=1;
        repeat(12) @(negedge clk);
        drive(1,1,0,1); drive(0,0,0,1);
        for(integer i=0;i<500;i++) drive(1,i%17==0,i,$urandom_range(0,2)!=0);
        // Force full-FIFO recovery, then restart at a frame boundary.
        for(integer i=0;i<40;i++) drive(1,0,100+i,0);
        drive(0,0,0,1);
        repeat(40) @(negedge clk);
        if(overflow==0) $fatal(1,"overflow case was not exercised");
        drive(1,1,224,1); drive(0,0,0,1);
        for(integer i=0;i<100;i++) drive(1,0,i,1);
        drive(0,0,0,1);
        repeat(40) @(negedge clk);
        if(expected.size()!=0 || sent!=received) $fatal(1,"events lost sent=%0d received=%0d",sent,received);
        $display("EVENT_PIPELINE=PASS sent=%0d received=%0d overflow=%0d",sent,received,overflow);
        $finish;
    end
endmodule
