`timescale 1ns/1ps

// A frame that stops after SOF must not retain the only production admission
// credit.  Reproduce the board state (writing != 0, AXI outstanding == 0),
// then prove that a second channel can be admitted and completed.
module tb_yolov5nu_tensor_dma_stall_recovery;
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

    wire [31:0] ready_mask, writing_mask, error_mask;
    wire [1023:0] slot_frame_ids, slot_byte_counts, slot_versions;
    wire [2047:0] slot_timestamps;
    wire [255:0] slot_error_codes;
    wire [511:0] no_slot_counts, missed_frame_counts;
    wire [511:0] admission_skip_counts, overflow_counts;
    wire [15:0] perf_outstanding_current;
    axi4_if #(.ADDR_WIDTH(32), .DATA_WIDTH(256), .ID_WIDTH(3)) axi();
    integer completed_w = 0;
    integer b_count = 0;
    integer timeout;

    yolov5nu_multi_channel_tensor_dma #(
        .FRAME_WIDTH(32), .FRAME_HEIGHT(1), .FIFO_DEPTH(16),
        .BASE_BURST_BEATS(2), .HIGH_BURST_BEATS(2),
        .MAX_BURST_BEATS(2), .WRITE_OUTSTANDING(8),
        .DESCRIPTOR_DEPTH(16), .AGE_THRESHOLD(1000),
        .CAPTURE_STALL_TIMEOUT(40), .SLOT_STRIDE(32'd128)
    ) dut (
        .clk(clk), .resetn(resetn), .production_enable(production_enable),
        .admission_enable_mask(16'h0003), .admission_limit(5'd1),
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
        .perf_outstanding_max(), .perf_source_starvation(),
        .perf_aw_stall_cycles(), .perf_w_stall_cycles(),
        .perf_w_transfer_cycles(), .perf_b_wait_cycles(),
        .perf_bursts_issued(), .perf_bursts_completed(),
        .perf_response_errors(), .perf_channel_index(4'd0),
        .perf_channel_fifo_level(), .perf_channel_fifo_peak(),
        .perf_channel_wait_max(), .perf_channel_bursts(), .m_axi(axi)
    );

    assign axi.awready = 1'b1;
    assign axi.wready = 1'b1;
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

    task automatic send_group(
        input integer channel,
        input [31:0] frame,
        input bit finish_frame
    );
        for (integer pair_index = 0; pair_index < 16; pair_index++) begin
            @(negedge clk);
            tap_accept[channel] = 1'b1;
            tap_sof[channel] = pair_index == 0;
            tap_eol[channel] = finish_frame && pair_index == 15;
            tap_eof[channel] = finish_frame && pair_index == 15;
            tap_frame_id[channel*32 +: 32] = frame;
            tap_data[channel*48 +: 48] =
                {24'(pair_index*2+1), 24'(pair_index*2)};
            @(posedge clk);
        end
        @(negedge clk);
        tap_accept = 0;
        tap_sof = 0;
        tap_eol = 0;
        tap_eof = 0;
    endtask

    initial begin
        repeat (4) @(posedge clk);
        resetn = 1'b1;
        repeat (24) @(posedge clk);
        production_enable = 1'b1;
        while (!dut.admission_permit[0]) @(posedge clk);

        // Three packed beats are produced. One 2-beat burst drains and the
        // final beat remains forever without the watchdog.
        send_group(0, 32'h100, 1'b0);
        timeout = 0;
        while ((writing_mask[0] == 0 || perf_outstanding_current != 0) &&
               timeout < 100) begin
            @(posedge clk);
            timeout = timeout + 1;
        end
        if (!writing_mask[0] || perf_outstanding_current != 0)
            $fatal(1, "did not reproduce stalled capture context");

        timeout = 0;
        while ((writing_mask[0] || !error_mask[0]) && timeout < 150) begin
            @(posedge clk);
            timeout = timeout + 1;
        end
        if (writing_mask[0] || !error_mask[0] ||
            slot_error_codes[0 +: 8] != 8'h01)
            $fatal(1, "stalled context did not recover writing=%h error=%h code=%h",
                   writing_mask, error_mask, slot_error_codes[0 +: 8]);

        timeout = 0;
        while (!dut.admission_permit[1] && timeout < 100) begin
            @(posedge clk);
            timeout = timeout + 1;
        end
        if (!dut.admission_permit[1])
            $fatal(1, "admission credit was not released to channel 1");

        send_group(1, 32'h200, 1'b1);
        timeout = 0;
        while (!ready_mask[1] && timeout < 200) begin
            @(posedge clk);
            timeout = timeout + 1;
        end
        if (!ready_mask[1] || error_mask[1])
            $fatal(1, "next channel did not complete after stall recovery");

        $display("tb_yolov5nu_tensor_dma_stall_recovery PASS");
        $finish;
    end
endmodule
