`timescale 1ns/1ps

module tb_multi_channel_video_dma_completion;
    reg clk = 0;
    reg resetn = 0;
    always #5 clk = ~clk;

    video_stream_if #(.DATA_WIDTH(48), .STREAM_ID_WIDTH(4)) stream [1]();
    axi4_if #(.ADDR_WIDTH(32), .DATA_WIDTH(256), .ID_WIDTH(3)) axi();
    wire buffer_acquire;
    wire frame_done;
    wire frame_error;
    wire channel_active;
    wire [4:0] fifo_levels;
    wire [31:0] active_frame_ids;
    reg bvalid = 0;
    integer aw_count = 0;
    integer w_count = 0;
    integer done_count = 0;
    integer error_count = 0;
    integer acquire_count = 0;

    assign stream[0].aclk = clk;
    assign stream[0].aresetn = resetn;
    assign axi.awready = 1'b1;
    assign axi.wready = 1'b1;
    assign axi.bid = 3'd0;
    assign axi.bresp = 2'b00;
    assign axi.bvalid = bvalid;
    assign axi.arready = 1'b0;
    assign axi.rid = 3'd0;
    assign axi.rdata = 256'd0;
    assign axi.rresp = 2'b00;
    assign axi.rlast = 1'b0;
    assign axi.rvalid = 1'b0;

    multi_channel_video_dma #(
        .CHANNELS(1), .FRAME_WIDTH(8), .FRAME_HEIGHT(1),
        .FRAME_STRIDE_BYTES(32), .FIFO_DEPTH(16),
        .BURST_MAX_BEATS(1), .WRITE_OUTSTANDING(2),
        .DESCRIPTOR_DEPTH(4)
    ) dut (
        .channels(stream), .m_axi(axi),
        .buffer_acquire(buffer_acquire),
        .buffer_grant(buffer_acquire), .buffer_drop(1'b0),
        .buffer_base(32'h1000_0000),
        .frame_done(frame_done), .frame_error(frame_error),
        .channel_active(channel_active), .fifo_levels(fifo_levels),
        .active_frame_ids(active_frame_ids),
        .perf_outstanding_current(), .perf_outstanding_max(),
        .perf_aw_stall_cycles(), .perf_w_stall_cycles(),
        .perf_b_stall_cycles(), .perf_bursts_issued(),
        .perf_bursts_completed(), .perf_response_errors()
    );

    always @(posedge clk) begin
        if (resetn) begin
            if (buffer_acquire)
                acquire_count <= acquire_count + 1;
            if (axi.awvalid && axi.awready)
                aw_count <= aw_count + 1;
            if (axi.wvalid && axi.wready)
                w_count <= w_count + 1;
            if (frame_done)
                done_count <= done_count + 1;
            if (frame_error)
                error_count <= error_count + 1;
        end
    end

    task automatic send_frame(input [31:0] frame_id,
                              input integer bad_beat);
        integer beat;
        begin
            for (beat = 0; beat < 4; beat = beat + 1) begin
                @(negedge clk);
                stream[0].data = {16'(frame_id), 16'(beat), 16'h55aa};
                stream[0].valid = 1'b1;
                stream[0].sof = (beat == 0);
                stream[0].eol = (beat == 3);
                stream[0].eof = (beat == 3);
                stream[0].stream_id = 4'd0;
                stream[0].frame_id = frame_id;
                stream[0].error = (beat == bad_beat);
                do @(posedge clk); while (!stream[0].ready);
            end
            @(negedge clk);
            stream[0].valid = 1'b0;
            stream[0].sof = 1'b0;
            stream[0].eol = 1'b0;
            stream[0].eof = 1'b0;
            stream[0].error = 1'b0;
        end
    endtask

    task automatic send_b;
        begin
            @(negedge clk);
            bvalid = 1'b1;
            do @(posedge clk); while (!axi.bready);
            @(negedge clk);
            bvalid = 1'b0;
        end
    endtask

    initial begin
        stream[0].data = 0;
        stream[0].valid = 0;
        stream[0].sof = 0;
        stream[0].eol = 0;
        stream[0].eof = 0;
        stream[0].stream_id = 0;
        stream[0].frame_id = 0;
        stream[0].error = 0;
        repeat (5) @(posedge clk);
        resetn = 1;

        send_frame(32'd1, -1);
        wait (w_count == 1);
        send_frame(32'd2, 2);
        repeat (12) @(posedge clk);
        if (frame_done || frame_error || done_count != 0 || error_count != 0)
            $fatal(1, "frame published before final write response");
        if (!channel_active || buffer_acquire)
            $fatal(1, "buffer released/reacquired with write response pending");

        send_b();
        wait (done_count == 1);
        wait (w_count == 2);
        repeat (10) @(posedge clk);
        if (error_count != 0)
            $fatal(1, "bad frame retired before delayed response");
        send_b();
        wait (error_count == 1);
        if (done_count != 1 || aw_count != 2 || w_count != 2 ||
            acquire_count != 2)
            $fatal(1, "completion accounting mismatch");

        $display("TB_MULTI_CHANNEL_VIDEO_DMA_COMPLETION=PASS");
        $finish;
    end

    initial begin
        #200000;
        $fatal(1, "timeout aw=%0d w=%0d done=%0d error=%0d",
               aw_count, w_count, done_count, error_count);
    end
endmodule
