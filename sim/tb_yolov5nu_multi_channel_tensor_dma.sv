`timescale 1ns/1ps

module tb_yolov5nu_multi_channel_tensor_dma;
    localparam integer CHANNELS = 16;
    reg clk = 0;
    reg resetn = 0;
    always #5 clk = ~clk;

    reg production_enable = 0;
    reg [CHANNELS-1:0] admission_enable_mask = 16'h0003;
    reg [4:0] admission_limit = 5'd2;
    reg release_pulse = 0;
    reg [31:0] release_mask = 0;
    reg [CHANNELS*48-1:0] tap_data = 0;
    reg [CHANNELS-1:0] tap_accept = 0;
    reg [CHANNELS-1:0] tap_sof = 0;
    reg [CHANNELS-1:0] tap_eol = 0;
    reg [CHANNELS-1:0] tap_eof = 0;
    reg [CHANNELS*32-1:0] tap_frame_id = 0;
    reg [CHANNELS-1:0] tap_error = 0;
    wire [31:0] ready_mask, writing_mask, error_mask;
    wire [1023:0] slot_frame_ids, slot_byte_counts;
    wire [2047:0] slot_timestamps;
    wire [1023:0] slot_versions;
    wire [255:0] slot_error_codes;
    wire [511:0] no_slot_counts, missed_frame_counts;
    wire [511:0] admission_skip_counts, overflow_counts;
    wire diagnostic_busy, diagnostic_completed, diagnostic_error;
    wire [3:0] diagnostic_done_channel;
    wire [31:0] diagnostic_frame_id, diagnostic_bytes;
    wire [31:0] diagnostic_overflows;
    axi4_if #(.ADDR_WIDTH(32), .DATA_WIDTH(256), .ID_WIDTH(3)) axi();

    integer aw_count = 0;
    integer w_count = 0;
    integer b_count = 0;
    integer completed_w = 0;
    integer max_outstanding = 0;
    integer full_bursts = 0;
    integer timeout;
    integer first_permit;

    yolov5nu_multi_channel_tensor_dma #(
        .FRAME_WIDTH(32), .FRAME_HEIGHT(2), .FIFO_DEPTH(16),
        .BASE_BURST_BEATS(2), .HIGH_BURST_BEATS(3),
        .MAX_BURST_BEATS(4), .WRITE_OUTSTANDING(8),
        .DESCRIPTOR_DEPTH(16), .AGE_THRESHOLD(1000), .SLOT_STRIDE(32'd192)
    ) dut (
        .clk(clk), .resetn(resetn), .production_enable(production_enable),
        .admission_enable_mask(admission_enable_mask),
        .admission_limit(admission_limit),
        .release_pulse(release_pulse), .release_mask(release_mask),
        .diagnostic_start(1'b0), .diagnostic_channel(4'd0),
        .diagnostic_addr(32'd0), .tap_data(tap_data),
        .tap_accept(tap_accept), .tap_sof(tap_sof), .tap_eol(tap_eol),
        .tap_eof(tap_eof), .tap_frame_id(tap_frame_id),
        .tap_error(tap_error), .ready_mask(ready_mask),
        .writing_mask(writing_mask), .error_mask(error_mask),
        .slot_frame_ids(slot_frame_ids), .slot_timestamps(slot_timestamps),
        .slot_versions(slot_versions), .slot_byte_counts(slot_byte_counts),
        .slot_error_codes(slot_error_codes),
        .no_slot_counts(no_slot_counts),
        .missed_frame_counts(missed_frame_counts),
        .admission_skip_counts(admission_skip_counts),
        .overflow_counts(overflow_counts), .diagnostic_busy(diagnostic_busy),
        .diagnostic_completed(diagnostic_completed),
        .diagnostic_error(diagnostic_error),
        .diagnostic_done_channel(diagnostic_done_channel),
        .diagnostic_frame_id(diagnostic_frame_id),
        .diagnostic_bytes(diagnostic_bytes),
        .diagnostic_overflows(diagnostic_overflows),
        .perf_outstanding_current(), .perf_outstanding_max(),
        .perf_source_starvation(), .perf_aw_stall_cycles(),
        .perf_w_stall_cycles(), .perf_w_transfer_cycles(),
        .perf_b_wait_cycles(), .perf_bursts_issued(),
        .perf_bursts_completed(), .perf_response_errors(),
        .perf_channel_index(4'd0), .perf_channel_fifo_level(),
        .perf_channel_fifo_peak(), .perf_channel_wait_max(),
        .perf_channel_bursts(), .m_axi(axi)
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
        if (axi.awvalid && axi.awready) begin
            if (axi.awlen > 8'd3)
                $fatal(1, "burst exceeds configured maximum");
            if (axi.awaddr[11:0] + ((axi.awlen + 1) << 5) > 4096)
                $fatal(1, "burst crosses 4 KiB boundary");
            aw_count <= aw_count + 1;
            if (axi.awlen == 8'd3)
                full_bursts <= full_bursts + 1;
        end
        if (axi.wvalid && axi.wready) begin
            w_count <= w_count + 1;
            if (axi.wlast)
                completed_w <= completed_w + 1;
        end
        if (axi.bvalid && axi.bready)
            b_count <= b_count + 1;
        if (aw_count - b_count > max_outstanding)
            max_outstanding <= aw_count - b_count;
    end

    task automatic send_pair(input integer pair_index,
                             input integer frame0, input integer frame1);
        reg line_last;
        begin
            line_last = (pair_index == 15 || pair_index == 31);
            @(negedge clk);
            tap_accept[0] = 1'b1;
            tap_accept[1] = 1'b1;
            tap_sof[0] = pair_index == 0;
            tap_sof[1] = pair_index == 0;
            tap_eol[0] = line_last;
            tap_eol[1] = line_last;
            tap_eof[0] = pair_index == 31;
            tap_eof[1] = pair_index == 31;
            tap_frame_id[0 +: 32] = frame0;
            tap_frame_id[32 +: 32] = frame1;
            tap_data[0 +: 48] = {24'(pair_index*2+1), 24'(pair_index*2)};
            tap_data[48 +: 48] = {24'(pair_index*2+3), 24'(pair_index*2+2)};
            @(posedge clk);
        end
    endtask

    // Start CH1 and CH2 one clock apart. Both already hold registered permits,
    // so neither SOF depends on the instantaneous RR allocator position.
    task automatic send_offset_frames(input integer frame0,
                                      input integer frame1);
        integer cycle_index;
        integer index0;
        integer index1;
        begin
            for (cycle_index = 0; cycle_index <= 32;
                 cycle_index = cycle_index + 1) begin
                index0 = cycle_index;
                index1 = cycle_index - 1;
                @(negedge clk);
                tap_accept = 0;
                tap_sof = 0;
                tap_eol = 0;
                tap_eof = 0;
                if (index0 < 32) begin
                    tap_accept[0] = 1'b1;
                    tap_sof[0] = index0 == 0;
                    tap_eol[0] = index0 == 15 || index0 == 31;
                    tap_eof[0] = index0 == 31;
                    tap_frame_id[0 +: 32] = frame0;
                    tap_data[0 +: 48] =
                        {24'(index0*2+1), 24'(index0*2)};
                end
                if (index1 >= 0) begin
                    tap_accept[1] = 1'b1;
                    tap_sof[1] = index1 == 0;
                    tap_eol[1] = index1 == 15 || index1 == 31;
                    tap_eof[1] = index1 == 31;
                    tap_frame_id[32 +: 32] = frame1;
                    tap_data[48 +: 48] =
                        {24'(index1*2+3), 24'(index1*2+2)};
                end
                @(posedge clk);
            end
        end
    endtask

    task automatic send_staggered_frame(input integer frame0,
                                        input integer frame1,
                                        input integer first_channel);
        begin
            @(negedge clk);
            tap_accept = 0;
            tap_sof = 0;
            tap_accept[first_channel] = 1'b1;
            tap_sof[first_channel] = 1'b1;
            tap_frame_id[0 +: 32] = frame0;
            tap_frame_id[32 +: 32] = frame1;
            tap_data[first_channel*48 +: 48] = {24'd1, 24'd0};
            @(posedge clk);
            @(negedge clk);
            tap_accept = 0;
            tap_sof = 0;
            tap_accept[1-first_channel] = 1'b1;
            tap_sof[1-first_channel] = 1'b1;
            tap_data[(1-first_channel)*48 +: 48] = {24'd1, 24'd0};
            @(posedge clk);
            for (integer pair_index = 1; pair_index < 32; pair_index++)
                send_pair(pair_index, frame0, frame1);
        end
    endtask

    task automatic release_slots(input reg [31:0] mask);
        begin
            @(negedge clk);
            release_mask = mask;
            release_pulse = 1'b1;
            @(posedge clk);
            @(negedge clk);
            release_pulse = 1'b0;
            release_mask = 0;
            @(posedge clk);
        end
    endtask

    initial begin
        repeat (4) @(posedge clk);
        resetn = 1'b1;
        repeat (20) @(posedge clk);
        production_enable = 1'b1;
        timeout = 0;
        while (dut.admission_permit[1:0] != 2'b11 && timeout < 100) begin
            @(posedge clk);
            timeout = timeout + 1;
        end
        if (dut.admission_permit[1:0] != 2'b11)
            $fatal(1, "admission permits were not preallocated");
        send_offset_frames(100, 200);
        @(negedge clk);
        tap_accept = 0;
        tap_sof = 0;
        tap_eol = 0;
        tap_eof = 0;

        timeout = 0;
        while ((ready_mask[1:0] != 2'b11) && timeout < 1000) begin
            @(posedge clk);
            timeout = timeout + 1;
        end
        if (ready_mask[1:0] != 2'b11 || error_mask[1:0] != 0)
            $fatal(1, "two-channel capture did not complete cleanly");
        if (slot_frame_ids[0 +: 32] != 100 ||
            slot_frame_ids[32 +: 32] != 200)
            $fatal(1, "frame metadata mismatch");
        if (slot_versions[0 +: 32] != 1 ||
            slot_versions[32 +: 32] != 1 ||
            slot_timestamps[0 +: 64] == 0 ||
            slot_timestamps[64 +: 64] <= slot_timestamps[0 +: 64] ||
            slot_error_codes[0 +: 8] != 0 ||
            slot_error_codes[8 +: 8] != 0)
            $fatal(1, "capture timestamp/version metadata mismatch");
        if (slot_byte_counts[0 +: 32] != 192 ||
            slot_byte_counts[32 +: 32] != 192 || w_count != 12)
            $fatal(1, "byte/beat accounting mismatch");
        if (aw_count != 4 || full_bursts != 2)
            $fatal(1, "burst policy mismatch: aw=%0d full=%0d", aw_count,
                   full_bursts);
        if (max_outstanding < 2)
            $fatal(1, "shared DMA never issued multiple outstanding bursts");

        // Completed channels remain eligible for their second slots. Wait for
        // both permits, then present SOFs without aligning them to RR state.
        timeout = 0;
        while (dut.admission_permit[1:0] != 2'b11 && timeout < 100) begin
            @(posedge clk);
            timeout = timeout + 1;
        end
        if (dut.admission_permit[1:0] != 2'b11)
            $fatal(1, "second-slot permits were not preallocated");
        send_offset_frames(101, 201);
        @(negedge clk);
        tap_accept = 0;
        tap_sof = 0;
        tap_eol = 0;
        tap_eof = 0;
        timeout = 0;
        while ((ready_mask[17:16] != 2'b11) && timeout < 1000) begin
            @(posedge clk);
            timeout = timeout + 1;
        end
        if (ready_mask[17:16] != 2'b11 ||
            slot_versions[16*32 +: 32] != 2 ||
            slot_versions[17*32 +: 32] != 2 ||
            slot_frame_ids[16*32 +: 32] != 101 ||
            slot_frame_ids[17*32 +: 32] != 201 ||
            slot_timestamps[16*64 +: 64] <= slot_timestamps[0 +: 64] ||
            slot_timestamps[17*64 +: 64] <= slot_timestamps[64 +: 64] ||
            slot_error_codes[16*8 +: 8] != 0 ||
            slot_error_codes[17*8 +: 8] != 0)
            $fatal(1, "second slot generation metadata mismatch");

        // Restart with one credit. The permit remains stable while the other
        // channel presents an earlier SOF, proving start does not require an
        // RR/SOF collision. After retirement, RR must permit the other channel.
        production_enable = 1'b0;
        repeat (2) @(posedge clk);
        release_slots(32'h0003_0003);
        admission_limit = 5'd1;
        production_enable = 1'b1;
        timeout = 0;
        while (dut.admission_permit[1:0] == 0 && timeout < 100) begin
            @(posedge clk);
            timeout = timeout + 1;
        end
        if (dut.admission_permit[1:0] == 0 ||
            dut.admission_permit[1:0] == 2'b11)
            $fatal(1, "limited admission did not produce one permit");
        first_permit = dut.admission_permit[0] ? 0 : 1;
        send_staggered_frame(102, 202, 1-first_permit);
        @(negedge clk);
        tap_accept = 0; tap_sof = 0; tap_eol = 0; tap_eof = 0;
        timeout = 0;
        while (ready_mask[first_permit] == 0 && timeout < 1000) begin
            @(posedge clk);
            timeout = timeout + 1;
        end
        if (ready_mask[first_permit] == 0 ||
            ready_mask[1-first_permit] != 0)
            $fatal(1, "first limited admission selected the wrong channel");
        if ((first_permit == 0 && slot_frame_ids[0 +: 32] != 102) ||
            (first_permit == 1 && slot_frame_ids[32 +: 32] != 202))
            $fatal(1, "first limited admission metadata mismatch");
        release_slots(32'(1 << first_permit));

        timeout = 0;
        while (!dut.admission_permit[1-first_permit] && timeout < 100) begin
            @(posedge clk);
            timeout = timeout + 1;
        end
        if (!dut.admission_permit[1-first_permit])
            $fatal(1, "limited admission did not advance fairly");

        send_staggered_frame(103, 203, first_permit);
        @(negedge clk);
        tap_accept = 0; tap_sof = 0; tap_eol = 0; tap_eof = 0;
        timeout = 0;
        while (ready_mask[1-first_permit] == 0 && timeout < 1000) begin
            @(posedge clk);
            timeout = timeout + 1;
        end
        if (ready_mask[1-first_permit] == 0 ||
            ready_mask[first_permit] != 0)
            $fatal(1, "second limited admission did not alternate");
        if (admission_skip_counts[0 +: 32] != 1 ||
            admission_skip_counts[32 +: 32] != 1 ||
            overflow_counts[0 +: 64] != 0)
            $fatal(1, "admission accounting mismatch");
        $display("tb_yolov5nu_multi_channel_tensor_dma PASS aw=%0d max_outstanding=%0d",
                 aw_count, max_outstanding);
        $finish;
    end
endmodule
