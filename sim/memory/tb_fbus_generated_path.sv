`timescale 1ns/1ps
// The real generated AXI/TL adapters feed a delayed, out-of-order
// memory responder. This is a controlled concurrency test, not a DDR model.
module tb_fbus_generated_path #(
    parameter integer READER_SLOTS = 64,
    parameter integer BYTES = 32768,
    parameter [32:0] BASE_ADDR = 33'h0b2000000,
    parameter bit SHORT_ONLY = 0,
    parameter integer MIN_MBPS = 0,
    parameter integer AXI_ID_WIDTH = 5,
    parameter integer READ_ID_COUNT = 18,
    parameter integer FIRST_WRITE_ID = 18,
    parameter integer WRITE_ID_COUNT = 14,
    parameter integer MEMORY_LATENCY = 48,
    parameter integer MEMORY_DATA_WIDTH = 64,
    parameter integer CONSUMER_PERIOD = 1,
    parameter integer MEMORY_GAP_CYCLES = 0,
    parameter bit WRITE_TRAFFIC = 0,
    parameter bit WRITE_ONLY = 0,
    parameter integer WRITE_COUNT = 64,
    parameter bit FAIR_MEMORY = 0,
    parameter integer CONTENTION_PERIOD = 0,
    parameter integer BURST_BEATS = 0
);
    reg clk = 0, resetn = 0, start = 0;
    always #5 clk = ~clk;
    axi4_if #(.ADDR_WIDTH(33), .DATA_WIDTH(256), .ID_WIDTH(AXI_ID_WIDTH)) axi();
    axi4_if #(.ADDR_WIDTH(33), .DATA_WIDTH(256), .ID_WIDTH(AXI_ID_WIDTH)) read_axi();
    axi4_if #(.ADDR_WIDTH(33), .DATA_WIDTH(256), .ID_WIDTH(AXI_ID_WIDTH)) write_axi();
    axi4_if #(.ADDR_WIDTH(32), .DATA_WIDTH(256), .ID_WIDTH(3)) source_write_axi();
    axi4_channel_join join_channels (
        .clk(clk), .resetn(resetn), .read_axi(read_axi),
        .write_axi(write_axi), .m_axi(axi)
    );
    wire [31:0] write_outstanding_current;
    wire [31:0] write_outstanding_max;
    wire [31:0] write_id_mask;
    axi4_write_cdc #(
        .FIFO_ADDR_WIDTH(5), .FBUS_WRITE_ID(FIRST_WRITE_ID),
        .FBUS_WRITE_ID_COUNT(WRITE_ID_COUNT)
    ) write_cdc (
        .s_axi(source_write_axi), .m_clk(clk), .m_resetn(resetn),
        .m_axi(write_axi), .perf_aw_count(), .perf_w_count(),
        .perf_b_count(), .perf_aw_stall_cycles(), .perf_w_stall_cycles(),
        .perf_b_stall_cycles(), .perf_outstanding_current(write_outstanding_current),
        .perf_outstanding_max(write_outstanding_max),
        .perf_write_id_mask(write_id_mask), .perf_protocol_errors()
    );

    reg [1:0] write_state = 0;
    integer writes_issued = 0;
    integer writes_completed = 0;
    assign source_write_axi.aclk = clk;
    assign source_write_axi.aresetn = resetn;
    assign source_write_axi.awid = 3'd0;
    assign source_write_axi.awaddr = 32'h3100_0000 + 32'(writes_issued * 64);
    assign source_write_axi.awlen = 1;
    assign source_write_axi.awsize = 5;
    assign source_write_axi.awburst = 1;
    assign source_write_axi.awlock = 0;
    assign source_write_axi.awcache = 2;
    assign source_write_axi.awprot = 0;
    assign source_write_axi.awqos = 0;
    assign source_write_axi.awvalid = WRITE_TRAFFIC && write_state == 0 &&
                                    (WRITE_ONLY || busy) &&
                                    (!WRITE_ONLY || writes_issued < WRITE_COUNT);
    assign source_write_axi.wvalid = write_state == 1 || write_state == 2;
    assign source_write_axi.wdata = {32{8'h5a}};
    assign source_write_axi.wstrb = '1;
    assign source_write_axi.wlast = write_state == 2;
    assign source_write_axi.bready = 1;
    assign source_write_axi.arid = 0; assign source_write_axi.araddr = 0;
    assign source_write_axi.arlen = 0; assign source_write_axi.arsize = 5;
    assign source_write_axi.arburst = 1; assign source_write_axi.arlock = 0;
    assign source_write_axi.arcache = 2; assign source_write_axi.arprot = 0;
    assign source_write_axi.arqos = 0; assign source_write_axi.arvalid = 0;
    assign source_write_axi.rready = 0;
    always @(posedge clk) begin
        if (!resetn) begin
            write_state <= 0;
            writes_issued <= 0;
            writes_completed <= 0;
        end
        else begin
            if (source_write_axi.awvalid && source_write_axi.awready)
                write_state <= 1;
            if (source_write_axi.wvalid && source_write_axi.wready) begin
                if (source_write_axi.wlast) begin
                    write_state <= 0;
                    writes_issued <= writes_issued + 1;
                end else begin
                    write_state <= write_state + 1'b1;
                end
            end
            if (source_write_axi.bvalid) begin
                if (source_write_axi.bresp != 0 || source_write_axi.bid != 0)
                    $fatal(1, "concurrent write response failed");
                writes_completed <= writes_completed + 1;
            end
        end
    end
    reg [8:0] burst_limit = 128;
    wire busy, done, error;
    wire [255:0] stream_data;
    // I: Reader status outputs and accepted TL/stream transfers.
    // P: Export one structured counter snapshot for each bandwidth case.
    // O: Comparable request, wait, backpressure, occupancy and payload metrics.
    // A: hlk
    // T: 2026-09-21 12:26:37 CST
    wire [31:0] stream_keep, cycles, bytes_read;
    wire [31:0] ar_requests, read_beats, ar_stall_cycles, r_wait_cycles;
    wire [31:0] r_backpressure_cycles, max_outstanding_observed;
    wire [31:0] max_reorder_occupancy, active_id_mask_observed;
    wire stream_valid, stream_last;
    wire stream_ready = tick % CONSUMER_PERIOD == 0;
    integer tick = 0, consumed = 0, peak = 0;
    integer tl_read_requests = 0, tl_write_beats = 0, tl_response_beats = 0;
    longint unsigned byte_sum = 0;
    fbus_read_engine #(.ID_WIDTH(AXI_ID_WIDTH), .READ_ID_COUNT(READ_ID_COUNT), .MAX_OUTSTANDING(READER_SLOTS)) reader (
        .clk(clk), .resetn(resetn), .start(start), .base_addr(BASE_ADDR),
        .byte_count(32'(BYTES)), .burst_beats_limit(burst_limit),
        .busy(busy), .done(done), .error(error), .error_flags(),
        .bytes_read(bytes_read), .ar_requests(ar_requests),
        .read_beats(read_beats), .active_cycles(cycles),
        .ar_stall_cycles(ar_stall_cycles), .r_wait_cycles(r_wait_cycles),
        .r_backpressure_cycles(r_backpressure_cycles),
        .max_outstanding_observed(max_outstanding_observed),
        .max_reorder_occupancy(max_reorder_occupancy),
        .active_id_mask_observed(active_id_mask_observed),
        .stream_data(stream_data), .stream_keep(stream_keep),
        .stream_valid(stream_valid), .stream_ready(stream_ready),
        .stream_last(stream_last), .m_axi(read_axi)
    );
    wire a_valid, a_ready, d_ready;
    wire [2:0] a_opcode;
    wire [3:0] a_size;
    wire [6:0] a_source;
    wire [32:0] a_address;
    reg [127:0] pending = 0, is_write = 0;
    integer write_beat = 0;
    reg [32:0] addresses [0:127];
    reg [3:0] sizes [0:127];
    integer due [0:127];
    integer selected = -1, beat = 0, cooldown = 0;
    reg response_valid = 0;
    wire d_valid = response_valid;
    wire [3:0] d_size = selected >= 0 ? sizes[selected] : 4'd0;
    localparam integer MEMORY_BYTES = MEMORY_DATA_WIDTH / 8;
    localparam integer MEMORY_BYTE_SHIFT = $clog2(MEMORY_BYTES);
    reg [MEMORY_DATA_WIDTH-1:0] d_data;
    assign a_ready = !pending[a_source];
    function automatic [7:0] payload(input [32:0] address);
        payload = 8'(address ^ (address >> 8) ^ (address >> 16));
    endfunction
    function automatic integer transaction_beats(input [3:0] size);
        transaction_beats = 1 << (32'(size) - MEMORY_BYTE_SHIFT);
    endfunction
    function automatic [15:0] stream_byte_sum(
        input [255:0] data, input [31:0] keep);
        stream_byte_sum = 0;
        for (integer lane = 0; lane < 32; lane++)
            if (keep[lane])
                stream_byte_sum = stream_byte_sum + 16'(data[lane*8 +: 8]);
    endfunction
    always @* begin
        d_data = 0;
        if (selected >= 0)
            for (integer lane = 0; lane < MEMORY_BYTES; lane++)
                d_data[lane*8 +: 8] = payload(addresses[selected] + 33'(beat*MEMORY_BYTES + lane));
    end
    fbus_generated_wrapper coupling (
        .clk(clk), .resetn(resetn), .axi(axi),
        .a_valid(a_valid), .a_ready(a_ready), .a_opcode(a_opcode),
        .a_size(a_size), .a_source(a_source), .a_address(a_address),
        .d_ready(d_ready), .d_valid(d_valid),
        .d_opcode(selected >= 0 && is_write[selected] ? 3'd0 : 3'd1),
        .d_size(d_size), .d_source(7'(selected)),
        .d_data(d_data)
    );
    integer chosen_response;
    // I: Stream data/keep from a generated-path read at an arbitrary address.
    // P: Check every valid lane and the exact first/last keep masks while
    //    advancing across aligned 256-bit output words.
    // O: Payload and byte-sum coverage for unaligned and 4 KiB-split reads.
    // A: hlk
    // T: 2026-09-21 12:45:52 CST
    reg [32:0] output_word_addr = {BASE_ADDR[32:5], 5'b0};
    reg lane_should_be_valid;
    reg [32:0] lane_address;
    integer stream_valid_bytes;
    always @* begin
        chosen_response = -1;
        for (integer i = 0; i < 128; i++) begin
            if (pending[i] && due[i] <= tick && cooldown == 0 &&
                (CONTENTION_PERIOD == 0 || tick % CONTENTION_PERIOD != 0)) begin
                if (!FAIR_MEMORY || chosen_response < 0 || due[i] < due[chosen_response])
                    chosen_response = i;
            end
        end
    end
    always @(posedge clk) begin
        if (!resetn) begin
            tick <= 0; pending <= 0; is_write <= 0; write_beat <= 0; cooldown <= 0; selected <= -1; beat <= 0;
            consumed <= 0; peak <= 0; response_valid <= 0;
            tl_read_requests <= 0; tl_write_beats <= 0;
            tl_response_beats <= 0; byte_sum <= 0;
            output_word_addr <= {BASE_ADDR[32:5], 5'b0};
        end else begin
            tick <= tick + 1;
            if (cooldown != 0) cooldown <= cooldown - 1;
            if ($countones(pending) > peak) peak <= $countones(pending);
            if (a_valid && a_ready) begin
                if ((a_opcode != 4 && a_opcode != 0 && a_opcode != 1) ||
                    32'(a_size) < MEMORY_BYTE_SHIFT || a_size > 6)
                    $fatal(1, "unsupported Get/Put opcode=%0d size=%0d",
                           a_opcode, a_size);
                if (a_opcode == 4)
                    tl_read_requests <= tl_read_requests + 1;
                else
                    tl_write_beats <= tl_write_beats + 1;
                if (a_opcode != 4 &&
                    write_beat != transaction_beats(a_size)-1) begin
                    write_beat <= write_beat + 1;
                end else begin
                    write_beat <= 0;
                    pending[a_source] <= 1;
                    is_write[a_source] <= a_opcode != 4;
                    addresses[a_source] <= a_address;
                    sizes[a_source] <= a_size;
                    due[a_source] <= tick + MEMORY_LATENCY + (a_address[8:6] == 0 ? 24 : 0);
                end
            end
            if (d_valid && d_ready)
                tl_response_beats <= tl_response_beats + 1;
            if (selected < 0) begin
                if (chosen_response >= 0) begin
                    selected <= chosen_response;
                    response_valid <= 1;
                end
                beat <= 0;
            end else if (!response_valid) begin
                if (CONTENTION_PERIOD == 0 || tick % CONTENTION_PERIOD != 0)
                    response_valid <= 1;
            end else if (d_ready) begin
                if (is_write[selected] ||
                    beat == transaction_beats(sizes[selected])-1) begin
                    pending[selected] <= 0;
                    selected <= -1;
                    response_valid <= 0;
                    cooldown <= MEMORY_GAP_CYCLES;
                    beat <= 0;
                end else beat <= beat + 1;
            end
            if (stream_valid && stream_ready) begin
                stream_valid_bytes = 0;
                for (integer lane = 0; lane < 32; lane++) begin
                    lane_address = output_word_addr + 33'(lane);
                    lane_should_be_valid = lane_address >= BASE_ADDR &&
                                           lane_address < BASE_ADDR + 33'(BYTES);
                    if (stream_keep[lane] !== lane_should_be_valid)
                        $fatal(1, "stream keep mismatch address=%h keep=%b expected=%b",
                               lane_address, stream_keep[lane],
                               lane_should_be_valid);
                    if (lane_should_be_valid) begin
                        if (stream_data[lane*8 +: 8] != payload(lane_address))
                            $fatal(1, "stream byte mismatch address=%h",
                                   lane_address);
                        stream_valid_bytes = stream_valid_bytes + 1;
                    end
                end
                if (stream_last != (consumed + stream_valid_bytes == BYTES))
                    $fatal(1, "stream last mismatch consumed=%0d valid=%0d",
                           consumed, stream_valid_bytes);
                consumed <= consumed + stream_valid_bytes;
                output_word_addr <= output_word_addr + 33'd32;
                byte_sum <= byte_sum +
                            64'(stream_byte_sum(stream_data, stream_keep));
            end
        end
    end
    integer large_cycles, small_cycles;
    task automatic run_case(input [8:0] limit);
        begin
            @(negedge clk); resetn = 0;
            repeat (5) @(negedge clk);
            resetn = 1; burst_limit = limit;
            @(negedge clk); start = 1;
            @(negedge clk); start = 0;
            wait(done); @(negedge clk);
            if (WRITE_TRAFFIC)
                wait (write_state == 0 && writes_completed == writes_issued &&
                      write_outstanding_current == 0);
            if (error || consumed != BYTES || bytes_read != BYTES)
                $fatal(1, "reader failed error=%b consumed=%0d", error, consumed);
            if (WRITE_TRAFFIC && writes_completed == 0)
                $fatal(1, "concurrent write traffic was not exercised");
            if (WRITE_TRAFFIC && !WRITE_ONLY && BYTES >= 65536 &&
                write_outstanding_max < WRITE_ID_COUNT)
                $fatal(1, "write ID partition was not filled max=%0d expected=%0d",
                       write_outstanding_max, WRITE_ID_COUNT);
            $display("FBUS_WRITES issued=%0d completed=%0d max=%0d mask=%08x",
                     writes_issued, writes_completed, write_outstanding_max,
                     write_id_mask);
            $display("FBUS_PATH burstB=%0d cycles=%0d peak_TL_requests=%0d MBps_at_100MHz=%0d",
                     limit*32, cycles, peak, BYTES*100/cycles);
            $display("FBUS_COUNTERS bytes=%0d ar=%0d r_beats=%0d ar_stall=%0d r_wait=%0d r_backpressure=%0d max_outstanding=%0d max_reorder=%0d active_id_mask=%08x tl_get=%0d tl_put_beats=%0d tl_d_beats=%0d byte_sum=%0d",
                     bytes_read, ar_requests, read_beats, ar_stall_cycles,
                     r_wait_cycles, r_backpressure_cycles,
                     max_outstanding_observed, max_reorder_occupancy,
                     active_id_mask_observed, tl_read_requests,
                     tl_write_beats, tl_response_beats, byte_sum);
        end
    endtask
    // I: Synthetic write-channel traffic using the same generated FBus path.
    // P: Run a bounded write-only control case without starting the reader.
    // O: Completed AXI writes and TL Put/D counters for coexistence comparison.
    // A: hlk
    // T: 2026-09-21 12:45:52 CST
    initial begin
        if (WRITE_ONLY) begin
            @(negedge clk); resetn = 0;
            repeat (5) @(negedge clk);
            resetn = 1;
            wait (writes_completed == WRITE_COUNT);
            if (writes_issued != WRITE_COUNT || write_id_mask == 0)
                $fatal(1, "write-only count or ID mask mismatch");
            @(negedge clk);
            $display("FBUS_WRITE_ONLY writes=%0d cycles=%0d peak_TL_requests=%0d tl_put_beats=%0d tl_d_beats=%0d",
                     writes_completed, tick, peak, tl_write_beats,
                     tl_response_beats);
        end else if (BURST_BEATS != 0) begin
            run_case(9'(BURST_BEATS));
            small_cycles = cycles;
        end else begin
            if (!SHORT_ONLY) begin run_case(128); large_cycles = cycles; end
            run_case(2); small_cycles = cycles;
        end
        if (!WRITE_ONLY && $test$plusargs("require_eight")) begin
            if (peak < 8) $fatal(1, "eight ID groups are not concurrent: peak=%0d", peak);
            if (BURST_BEATS == 0 && !SHORT_ONLY && small_cycles >= large_cycles)
                $fatal(1, "short bursts did not improve throughput");
        end
        if (!WRITE_ONLY && BYTES*100/small_cycles < MIN_MBPS)
            $fatal(1, "throughput gate missed: %0d < %0d MB/s", BYTES*100/small_cycles, MIN_MBPS);
        $display("TB_FBUS_GENERATED_PATH=PASS"); $finish;
    end
    initial begin #100000000; $fatal(1, "timeout"); end
endmodule
