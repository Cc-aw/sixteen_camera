`timescale 1ns/1ps

// Reproduce the board-observed terminal state: an AW descriptor is already
// outstanding when an overflow/stream abort invalidates the promised FIFO
// payload.  The DMA must terminate that burst and retire the bad context.
module tb_yolov5nu_tensor_dma_abort_drain;
    localparam integer CHANNELS = 16;
    reg clk = 0;
    reg resetn = 0;
    always #5 clk = ~clk;

    reg production_enable = 0;
    reg [CHANNELS*48-1:0] tap_data = 0;
    reg [CHANNELS-1:0] tap_accept = 0;
    reg [CHANNELS-1:0] tap_sof = 0;
    reg [CHANNELS-1:0] tap_eol = 0;
    reg [CHANNELS-1:0] tap_eof = 0;
    reg [CHANNELS*32-1:0] tap_frame_id = 0;
    reg [CHANNELS-1:0] tap_error = 0;
    reg allow_w = 0;

    wire [31:0] ready_mask, writing_mask, error_mask;
    wire [1023:0] slot_frame_ids, slot_byte_counts, slot_versions;
    wire [2047:0] slot_timestamps;
    wire [255:0] slot_error_codes;
    wire [511:0] no_slot_counts, missed_frame_counts;
    wire [511:0] admission_skip_counts, overflow_counts;
    wire [15:0] perf_outstanding_current;
    wire [31:0] perf_source_starvation;
    axi4_if #(.ADDR_WIDTH(32), .DATA_WIDTH(256), .ID_WIDTH(3)) axi();
    integer completed_w = 0;
    integer b_count = 0;
    integer timeout;

    yolov5nu_multi_channel_tensor_dma #(
        .FRAME_WIDTH(32), .FRAME_HEIGHT(8), .FIFO_DEPTH(16),
        .BASE_BURST_BEATS(2), .HIGH_BURST_BEATS(3),
        .MAX_BURST_BEATS(4), .WRITE_OUTSTANDING(8),
        .DESCRIPTOR_DEPTH(16), .AGE_THRESHOLD(1000),
        .SLOT_STRIDE(32'd1024)
    ) dut (
        .clk(clk), .resetn(resetn), .production_enable(production_enable),
        .admission_enable_mask(16'h0001), .admission_limit(5'd1),
        .release_pulse(1'b0), .release_mask(32'd0),
        .tap_data(tap_data), .tap_accept(tap_accept), .tap_sof(tap_sof),
        .tap_eol(tap_eol), .tap_eof(tap_eof),
        .tap_frame_id(tap_frame_id), .tap_error(tap_error),
        .ready_mask(ready_mask), .writing_mask(writing_mask),
        .error_mask(error_mask), .slot_frame_ids(slot_frame_ids),
        .slot_timestamps(slot_timestamps), .slot_versions(slot_versions),
        .slot_error_codes(slot_error_codes),
        .slot_byte_counts(slot_byte_counts), .no_slot_counts(no_slot_counts),
        .missed_frame_counts(missed_frame_counts),
        .admission_skip_counts(admission_skip_counts),
        .overflow_counts(overflow_counts),
        .perf_outstanding_current(perf_outstanding_current),
        .perf_outstanding_max(),
        .perf_source_starvation(perf_source_starvation),
        .perf_aw_stall_cycles(), .perf_w_stall_cycles(),
        .perf_w_transfer_cycles(), .perf_b_wait_cycles(),
        .perf_bursts_issued(), .perf_bursts_completed(),
        .perf_response_errors(), .perf_channel_index(4'd0),
        .perf_channel_fifo_level(), .perf_channel_fifo_peak(),
        .perf_channel_wait_max(), .perf_channel_bursts(), .m_axi(axi)
    );

    assign axi.awready = 1'b1;
    assign axi.wready = allow_w;
    assign axi.bid = 3'd0;
    assign axi.bresp = 2'b00;
    assign axi.bvalid = completed_w > b_count;
    assign axi.arready = 1'b0;
    assign axi.rid = 3'd0;
    assign axi.rdata = 256'd0;
    assign axi.rresp = 2'd0;
    assign axi.rlast = 1'b0;
    assign axi.rvalid = 1'b0;

    always @(posedge clk) begin
        if (axi.wvalid && axi.wready && axi.wlast)
            completed_w <= completed_w + 1;
        if (axi.bvalid && axi.bready)
            b_count <= b_count + 1;
    end

    initial begin
        repeat (4) @(posedge clk);
        resetn = 1'b1;
        repeat (24) @(posedge clk);
        production_enable = 1'b1;
        while (!dut.admission_permit[0]) @(posedge clk);

        // Produce enough complete groups for at least one outstanding burst.
        for (integer pair_index = 0; pair_index < 80; pair_index++) begin
            @(negedge clk);
            tap_accept[0] = 1'b1;
            tap_sof[0] = pair_index == 0;
            tap_eol[0] = pair_index % 16 == 15;
            tap_eof[0] = 1'b0;
            tap_frame_id[0 +: 32] = 32'h55;
            tap_data[0 +: 48] = {24'(pair_index*2+1), 24'(pair_index*2)};
            @(posedge clk);
        end
        @(negedge clk);
        tap_accept = 0;
        tap_sof = 0;
        tap_eol = 0;

        timeout = 0;
        while ((!dut.w_desc_valid || perf_outstanding_current == 0) &&
               timeout < 500) begin
            @(posedge clk);
            timeout = timeout + 1;
        end
        if (!dut.w_desc_valid || perf_outstanding_current == 0)
            $fatal(1, "fault injection did not reach an outstanding W burst");

        // Model the payload loss observed after the capture context faults.
        force dut.ctx_bad[0] = 1'b1;
        force dut.ctx_error_code[0] = 8'h03;
        force dut.g_frontend[0].sim_count = 0;
        allow_w = 1'b1;

        timeout = 0;
        while ((writing_mask != 0 || perf_outstanding_current != 0) &&
               timeout < 500) begin
            @(posedge clk);
            timeout = timeout + 1;
        end
        if (writing_mask != 0 || perf_outstanding_current != 0)
            $fatal(1,
                "bad context failed to drain writing=%h out=%0d starve=%0d",
                writing_mask, perf_outstanding_current,
                perf_source_starvation);
        if ((error_mask & 1) == 0 || (slot_error_codes[0 +: 8] & 8'h03) == 0)
            $fatal(1, "drained context did not publish its error");

        release dut.g_frontend[0].sim_count;
        release dut.ctx_error_code[0];
        release dut.ctx_bad[0];
        $display("tb_yolov5nu_tensor_dma_abort_drain PASS");
        $finish;
    end
endmodule
