`timescale 1ns/1ps
// The real generated AXI/TL adapters feed a delayed, out-of-order memory
// responder. This is a controlled concurrency test, not a DDR model.
module tb_fbus_generated_path #(
    parameter integer READER_SLOTS = 64,
    parameter integer BYTES = 32768,
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
    parameter bit FAIR_MEMORY = 0,
    parameter integer CONTENTION_PERIOD = 0
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
    wire [31:0] write_outstanding_max;
    wire [31:0] write_id_mask;
    axi4_write_cdc #(
        .FIFO_ADDR_WIDTH(5), .FBUS_WRITE_ID(FIRST_WRITE_ID),
        .FBUS_WRITE_ID_COUNT(WRITE_ID_COUNT)
    ) write_cdc (
        .s_axi(source_write_axi), .m_clk(clk), .m_resetn(resetn),
        .m_axi(write_axi), .perf_aw_count(), .perf_w_count(),
        .perf_b_count(), .perf_aw_stall_cycles(), .perf_w_stall_cycles(),
        .perf_b_stall_cycles(), .perf_outstanding_current(),
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
    assign source_write_axi.awvalid = WRITE_TRAFFIC && write_state == 0 && busy;
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
    wire [31:0] stream_keep, cycles, bytes_read;
    wire stream_valid, stream_last;
    wire stream_ready = tick % CONSUMER_PERIOD == 0;
    integer tick = 0, consumed = 0, peak = 0;
    localparam [32:0] BASE = 33'h0b2000000;
    fbus_read_engine #(.ID_WIDTH(AXI_ID_WIDTH), .READ_ID_COUNT(READ_ID_COUNT), .MAX_OUTSTANDING(READER_SLOTS)) reader (
        .clk(clk), .resetn(resetn), .start(start), .base_addr(BASE),
        .byte_count(32'(BYTES)), .burst_beats_limit(burst_limit),
        .busy(busy), .done(done), .error(error), .error_flags(),
        .bytes_read(bytes_read), .ar_requests(), .read_beats(),
        .active_cycles(cycles), .ar_stall_cycles(), .r_wait_cycles(),
        .r_backpressure_cycles(), .max_outstanding_observed(),
        .max_reorder_occupancy(), .active_id_mask_observed(),
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
    integer due [0:127];
    integer selected = -1, beat = 0, cooldown = 0;
    reg response_valid = 0;
    wire d_valid = response_valid;
    localparam integer MEMORY_BYTES = MEMORY_DATA_WIDTH / 8;
    reg [MEMORY_DATA_WIDTH-1:0] d_data;
    assign a_ready = !pending[a_source];
    function automatic [7:0] payload(input [32:0] address);
        payload = 8'(address ^ (address >> 8) ^ (address >> 16));
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
        .d_opcode(selected >= 0 && is_write[selected] ? 3'd0 : 3'd1), .d_source(7'(selected)),
        .d_data(d_data)
    );
    integer chosen_response;
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
        end else begin
            tick <= tick + 1;
            if (cooldown != 0) cooldown <= cooldown - 1;
            if ($countones(pending) > peak) peak <= $countones(pending);
            if (a_valid && a_ready) begin
                if ((a_opcode != 4 && a_opcode != 0 && a_opcode != 1) || a_size != 6)
                    $fatal(1, "expected a 64-byte Get/Put opcode=%0d size=%0d", a_opcode, a_size);
                if (a_opcode != 4 && write_beat != 64/MEMORY_BYTES-1) begin
                    write_beat <= write_beat + 1;
                end else begin
                    write_beat <= 0;
                    pending[a_source] <= 1;
                    is_write[a_source] <= a_opcode != 4;
                    addresses[a_source] <= a_address;
                    due[a_source] <= tick + MEMORY_LATENCY + (a_address[8:6] == 0 ? 24 : 0);
                end
            end
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
                if (is_write[selected] || beat == 64/MEMORY_BYTES-1) begin
                    pending[selected] <= 0;
                    selected <= -1;
                    response_valid <= 0;
                    cooldown <= MEMORY_GAP_CYCLES;
                    beat <= 0;
                end else beat <= beat + 1;
            end
            if (stream_valid && stream_ready) begin
                if (stream_keep != 32'hffffffff ||
                    stream_last != (consumed + 32 == BYTES))
                    $fatal(1, "stream framing mismatch");
                for (integer lane = 0; lane < 32; lane++)
                    if (stream_data[lane*8 +: 8] != payload(BASE + 33'(consumed + lane)))
                        $fatal(1, "stream byte mismatch at %0d", consumed + lane);
                consumed <= consumed + 32;
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
            if (error || consumed != BYTES || bytes_read != BYTES)
                $fatal(1, "reader failed error=%b consumed=%0d", error, consumed);
            if (WRITE_TRAFFIC && writes_completed == 0)
                $fatal(1, "concurrent write traffic was not exercised");
            if (WRITE_TRAFFIC && write_outstanding_max < WRITE_ID_COUNT)
                $fatal(1, "write ID partition was not filled max=%0d expected=%0d",
                       write_outstanding_max, WRITE_ID_COUNT);
            $display("FBUS_WRITES issued=%0d completed=%0d max=%0d mask=%08x",
                     writes_issued, writes_completed, write_outstanding_max,
                     write_id_mask);
            $display("FBUS_PATH burstB=%0d cycles=%0d peak_TL_requests=%0d MBps_at_100MHz=%0d",
                     limit*32, cycles, peak, BYTES*100/cycles);
        end
    endtask
    initial begin
        if (!SHORT_ONLY) begin run_case(128); large_cycles = cycles; end
        run_case(2); small_cycles = cycles;
        if ($test$plusargs("require_eight")) begin
            if (peak < 8) $fatal(1, "eight ID groups are not concurrent: peak=%0d", peak);
            if (!SHORT_ONLY && small_cycles >= large_cycles) $fatal(1, "short bursts did not improve throughput");
        end
        if (BYTES*100/small_cycles < MIN_MBPS)
            $fatal(1, "throughput gate missed: %0d < %0d MB/s", BYTES*100/small_cycles, MIN_MBPS);
        $display("TB_FBUS_GENERATED_PATH=PASS"); $finish;
    end
    initial begin #100000000; $fatal(1, "timeout"); end
endmodule
