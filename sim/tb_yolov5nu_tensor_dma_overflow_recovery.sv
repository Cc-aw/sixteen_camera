`timescale 1ns/1ps

module tb_yolov5nu_tensor_dma_overflow_recovery;
    localparam integer CHANNELS = 16;
    localparam integer ACTIVE_CHANNELS = 4;
    localparam integer PAIRS_PER_FRAME = 32 * 8 / 2;

    reg clk = 0;
    reg resetn = 0;
    always #5 clk = ~clk;

    reg production_enable = 0;
    reg [CHANNELS-1:0] admission_enable_mask = 16'h000f;
    reg [4:0] admission_limit = ACTIVE_CHANNELS;
    reg release_pulse = 0;
    reg [31:0] release_mask = 0;
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
    wire [15:0] perf_outstanding_current, perf_outstanding_max;
    wire [31:0] perf_source_starvation, perf_aw_stall_cycles;
    wire [31:0] perf_w_stall_cycles, perf_w_transfer_cycles;
    wire [31:0] perf_b_wait_cycles, perf_bursts_issued;
    wire [31:0] perf_bursts_completed, perf_response_errors;
    axi4_if #(.ADDR_WIDTH(32), .DATA_WIDTH(256), .ID_WIDTH(3)) axi();

    integer aw_count = 0;
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
        .admission_enable_mask(admission_enable_mask),
        .admission_limit(admission_limit),
        .release_pulse(release_pulse), .release_mask(release_mask),
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
        .perf_outstanding_max(perf_outstanding_max),
        .perf_source_starvation(perf_source_starvation),
        .perf_aw_stall_cycles(perf_aw_stall_cycles),
        .perf_w_stall_cycles(perf_w_stall_cycles),
        .perf_w_transfer_cycles(perf_w_transfer_cycles),
        .perf_b_wait_cycles(perf_b_wait_cycles),
        .perf_bursts_issued(perf_bursts_issued),
        .perf_bursts_completed(perf_bursts_completed),
        .perf_response_errors(perf_response_errors),
        .perf_channel_index(4'd0), .perf_channel_fifo_level(),
        .perf_channel_fifo_peak(), .perf_channel_wait_max(),
        .perf_channel_bursts(), .m_axi(axi)
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
        if (axi.awvalid && axi.awready)
            aw_count <= aw_count + 1;
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
        timeout = 0;
        while ((dut.admission_permit & 16'h000f) != 16'h000f &&
               timeout < 200) begin
            @(posedge clk);
            timeout = timeout + 1;
        end
        if ((dut.admission_permit & 16'h000f) != 16'h000f)
            $fatal(1, "four admission permits were not allocated");

        for (integer pair_index = 0; pair_index < PAIRS_PER_FRAME;
             pair_index = pair_index + 1) begin
            @(negedge clk);
            tap_accept = 16'h000f;
            tap_sof = pair_index == 0 ? 16'h000f : 0;
            tap_eol = pair_index % 16 == 15 ? 16'h000f : 0;
            tap_eof = pair_index == PAIRS_PER_FRAME-1 ? 16'h000f : 0;
            for (integer channel = 0; channel < ACTIVE_CHANNELS; channel++) begin
                tap_frame_id[channel*32 +: 32] = 32'h100 + channel;
                tap_data[channel*48 +: 48] =
                    {24'(pair_index*2+channel+1),
                     24'(pair_index*2+channel)};
            end
            @(posedge clk);
        end
        @(negedge clk);
        tap_accept = 0;
        tap_sof = 0;
        tap_eol = 0;
        tap_eof = 0;

        repeat (20) @(posedge clk);
        if (overflow_counts[0 +: 32] == 0 &&
            overflow_counts[32 +: 32] == 0 &&
            overflow_counts[64 +: 32] == 0 &&
            overflow_counts[96 +: 32] == 0)
            $fatal(1, "backpressure did not reproduce a tensor FIFO overflow");
        if (aw_count == 0)
            $fatal(1, "test did not issue an AXI descriptor before overflow");

        allow_w = 1'b1;
        timeout = 0;
        while ((writing_mask != 0 || perf_outstanding_current != 0 ||
                aw_count != b_count) && timeout < 3000) begin
            @(posedge clk);
            timeout = timeout + 1;
        end
        if (writing_mask != 0 || perf_outstanding_current != 0 ||
            aw_count != b_count)
            $fatal(1,
                "overflow recovery deadlocked writing=%h out=%0d aw/b=%0d/%0d starve=%0d",
                writing_mask, perf_outstanding_current, aw_count, b_count,
                perf_source_starvation);
        if ((error_mask & 32'h0000_000f) == 0)
            $fatal(1, "overflowed contexts did not publish an error");

        $display("tb_yolov5nu_tensor_dma_overflow_recovery PASS aw=%0d overflow=%0d/%0d/%0d/%0d",
                 aw_count, overflow_counts[0 +: 32],
                 overflow_counts[32 +: 32], overflow_counts[64 +: 32],
                 overflow_counts[96 +: 32]);
        $finish;
    end
endmodule
