`timescale 1ns/1ps
module tb_s1_absent_input_admission;
    reg clk=0;
    always #5 clk=~clk;
    reg resetn=0,production_enable=0;
    reg release_enable=1,allow_expected_error=0;
    reg [15:0] admission_mask=16'hffff;
    reg [31:0] cycle=0;
    reg [767:0] tap_data;
    reg [15:0] tap_accept,tap_sof,tap_eol,tap_eof;
    reg [511:0] tap_frame_id;
    wire [31:0] ready_mask,writing_mask,error_mask;
    integer completed=0,completed_w=0,responses=0,aw_count=0;
    axi4_if #(.ADDR_WIDTH(32),.DATA_WIDTH(256),.ID_WIDTH(3)) axi();
    yolov5nu_multi_channel_tensor_dma #(
        .FRAME_WIDTH(32),.FRAME_HEIGHT(2),.FIFO_DEPTH(16),
        .BASE_BURST_BEATS(2),.HIGH_BURST_BEATS(2),.MAX_BURST_BEATS(2),
        .WRITE_OUTSTANDING(8),.DESCRIPTOR_DEPTH(16),.SLOT_STRIDE(192)
    ) dut (
        .clk(clk),.resetn(resetn),.production_enable(production_enable),
        .admission_enable_mask(admission_mask),.admission_limit(5'd1),
        .release_pulse(release_enable),.release_mask(ready_mask|error_mask),
        .tap_data(tap_data),.tap_accept(tap_accept),.tap_sof(tap_sof),
        .tap_eol(tap_eol),.tap_eof(tap_eof),.tap_frame_id(tap_frame_id),.tap_error(16'd0),
        .ready_mask(ready_mask),.writing_mask(writing_mask),.error_mask(error_mask),
        .slot_frame_ids(),.slot_timestamps(),.slot_versions(),.slot_error_codes(),.slot_byte_counts(),
        .no_slot_counts(),.missed_frame_counts(),.admission_skip_counts(),.overflow_counts(),
        .perf_outstanding_current(),.perf_outstanding_max(),.perf_source_starvation(),
        .perf_aw_stall_cycles(),.perf_w_stall_cycles(),.perf_w_transfer_cycles(),
        .perf_b_wait_cycles(),.perf_bursts_issued(),.perf_bursts_completed(),.perf_response_errors(),
        .perf_channel_index(4'd0),.perf_channel_fifo_level(),.perf_channel_fifo_peak(),
        .perf_channel_wait_max(),.perf_channel_bursts(),.m_axi(axi)
    );
    assign axi.awready=1;
    assign axi.wready=1;
    assign axi.bid=0;
    assign axi.bresp=0;
    assign axi.bvalid=completed_w>responses;
    assign axi.arready=0;
    assign axi.rid=0;
    assign axi.rdata=0;
    assign axi.rresp=0;
    assign axi.rlast=0;
    assign axi.rvalid=0;
    always @(posedge clk) if(resetn) begin
        cycle<=cycle+1;
        completed<=completed+$countones(ready_mask);
        if(axi.awvalid&&axi.awready)aw_count<=aw_count+1;
        if(axi.wvalid&&axi.wready&&axi.wlast)completed_w<=completed_w+1;
        if(axi.bvalid&&axi.bready)responses<=responses+1;
        if(error_mask&&!allow_expected_error)$fatal(1,"Unexpected Tensor capture error %h",error_mask);
    end
    // Eight valid repeated 32x2 RGB frames; HDMI inputs 8..15 remain absent.
    always @* begin
        tap_data=0;tap_frame_id=0;tap_accept=0;tap_sof=0;tap_eol=0;tap_eof=0;
        for(integer ch=0;ch<8;ch=ch+1) begin
            tap_frame_id[ch*32+:32]=cycle/256+1;
            if(cycle[7:0]<32) begin
                tap_accept[ch]=1;
                tap_sof[ch]=cycle[7:0]==0;
                tap_eol[ch]=cycle[7:0]==15||cycle[7:0]==31;
                tap_eof[ch]=cycle[7:0]==31;
                tap_data[ch*48+:48]={24'(cycle+ch),24'(cycle+ch+1)};
            end
        end
    end
    integer before_fix;
    initial begin
        repeat(12)@(negedge clk);resetn=1;production_enable=1;
        repeat(12000)@(negedge clk);
        if(completed>8||(dut.admission_permit&16'hff00)==0||writing_mask!=0)
            $fatal(1,"Reproduction differs completed=%0d permit=%h writing=%h",completed,dut.admission_permit,writing_mask);
        $display("S1_ABSENT_INPUT_REPRO_PASS completed=%0d idle_hdmi_permit=%h",completed,dut.admission_permit);
        production_enable=0;repeat(128)@(negedge clk);
        admission_mask=16'h00ff;production_enable=1;before_fix=completed;
        repeat(12000)@(negedge clk);
        if(completed-before_fix<32||error_mask!=0)
            $fatal(1,"Masked capture did not progress completed=%0d",completed-before_fix);
        $display("S1_INPUT_MASK_RTL_PASS repeated_frames=%0d responses=%0d absent_hdmi_excluded=1",completed-before_fix,responses);
        release_enable=0;
        repeat(20000)@(negedge clk);
        if((ready_mask&32'h00ff00ff)!=32'h00ff00ff||writing_mask!=0)
            $fatal(1,"Could not quiesce capture ready=%h writing=%h",ready_mask,writing_mask);
        production_enable=0;repeat(256)@(negedge clk);
        release_enable=1;repeat(256)@(negedge clk);
        if(ready_mask||writing_mask||error_mask||aw_count!=responses)
            $fatal(1,"Graceful capture stop retained state ready=%h errors=%h",ready_mask,error_mask);
        $display("S1_CAPTURE_STOP_RTL_PASS full_slots_before_disable=1 all_slots_released=1");
        // Contrast with the old immediate stop on the same frozen hardware.
        allow_expected_error=1;admission_mask=1;production_enable=1;
        wait(writing_mask!=0);@(negedge clk);production_enable=0;
        repeat(512)@(negedge clk);
        if(!error_mask)$fatal(1,"Immediate cancellation did not expose ERROR");
        release_enable=1;repeat(256)@(negedge clk);
        if(!error_mask)$fatal(1,"Expected frozen S1 sticky cancellation state");
        $display("S1_CANCEL_ERROR_REPRO_PASS release_cannot_clear_sticky_error=1");
        $finish;
    end
endmodule
