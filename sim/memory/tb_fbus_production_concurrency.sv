`timescale 1ns/1ps

// Production-shaped FBus concurrency test. The instantiated coupling is the
// generated AXI4-to-TL path; the responder models the shared downstream DDR
// path with independent read/write acceptance limits and one shared D channel.
module tb_fbus_production_concurrency #(
    parameter integer AXI_ID_WIDTH = 5,
    parameter integer READ_ID_COUNT = 18,
    parameter integer FIRST_WRITE_ID = 18,
    parameter integer WRITE_ID_COUNT = 14,
    parameter integer READ_BYTES = 65536,
    parameter integer WRITE_BYTES = 65536,
    parameter integer MEMORY_LATENCY = 18,
    parameter integer MEMORY_DATA_WIDTH = 256,
    parameter integer READ_ACCEPTANCE = 8,
    parameter integer WRITE_ACCEPTANCE = 8,
    parameter integer MIN_READ_MBPS = 0,
    parameter integer MIN_WRITE_MBPS = 0,
    parameter integer EXPECT_DISJOINT_IDS = 1
);
    localparam integer WRITE_TRANSACTIONS = WRITE_BYTES / 64;
    localparam integer MEMORY_BYTES = MEMORY_DATA_WIDTH / 8;
    localparam [32:0] READ_BASE = 33'h0_b200_0000;

    reg clk = 1'b0;
    reg resetn = 1'b0;
    reg start = 1'b0;
    reg write_enable = 1'b0;
    always #5 clk = ~clk;

    axi4_if #(.ADDR_WIDTH(33), .DATA_WIDTH(256),
              .ID_WIDTH(AXI_ID_WIDTH)) axi();
    axi4_if #(.ADDR_WIDTH(33), .DATA_WIDTH(256),
              .ID_WIDTH(AXI_ID_WIDTH)) read_axi();
    axi4_if #(.ADDR_WIDTH(33), .DATA_WIDTH(256),
              .ID_WIDTH(AXI_ID_WIDTH)) write_axi();
    axi4_if #(.ADDR_WIDTH(32), .DATA_WIDTH(256), .ID_WIDTH(3)) source_write_axi();

    axi4_channel_join join_channels (
        .clk(clk), .resetn(resetn), .read_axi(read_axi),
        .write_axi(write_axi), .m_axi(axi)
    );

    wire [31:0] write_outstanding_current;
    wire [31:0] write_outstanding_max;
    wire [31:0] write_id_mask;
    wire [31:0] write_protocol_errors;
    axi4_write_cdc #(
        .FIFO_ADDR_WIDTH(5),
        .FBUS_WRITE_ID(FIRST_WRITE_ID),
        .FBUS_WRITE_ID_COUNT(WRITE_ID_COUNT)
    ) write_cdc (
        .s_axi(source_write_axi), .m_clk(clk), .m_resetn(resetn),
        .m_axi(write_axi), .perf_aw_count(), .perf_w_count(),
        .perf_b_count(), .perf_aw_stall_cycles(), .perf_w_stall_cycles(),
        .perf_b_stall_cycles(),
        .perf_outstanding_current(write_outstanding_current),
        .perf_outstanding_max(write_outstanding_max),
        .perf_write_id_mask(write_id_mask),
        .perf_protocol_errors(write_protocol_errors)
    );

    reg [1:0] write_state = 0;
    integer writes_issued = 0;
    integer writes_completed = 0;
    integer write_start_tick = 0;
    integer write_end_tick = 0;

    assign source_write_axi.aclk = clk;
    assign source_write_axi.aresetn = resetn;
    assign source_write_axi.awid = 3'd0;
    assign source_write_axi.awaddr = 32'h3100_0000 + 32'(writes_issued * 64);
    assign source_write_axi.awlen = 8'd1;
    assign source_write_axi.awsize = 3'd5;
    assign source_write_axi.awburst = 2'b01;
    assign source_write_axi.awlock = 1'b0;
    assign source_write_axi.awcache = 4'd2;
    assign source_write_axi.awprot = 3'd0;
    assign source_write_axi.awqos = 4'd0;
    assign source_write_axi.awvalid = write_enable &&
                                      writes_issued < WRITE_TRANSACTIONS &&
                                      write_state == 0;
    assign source_write_axi.wvalid = write_state == 1 || write_state == 2;
    assign source_write_axi.wdata = {32{8'h5a}};
    assign source_write_axi.wstrb = '1;
    assign source_write_axi.wlast = write_state == 2;
    assign source_write_axi.bready = 1'b1;
    assign source_write_axi.arid = '0;
    assign source_write_axi.araddr = '0;
    assign source_write_axi.arlen = '0;
    assign source_write_axi.arsize = 3'd5;
    assign source_write_axi.arburst = 2'b01;
    assign source_write_axi.arlock = 1'b0;
    assign source_write_axi.arcache = 4'd2;
    assign source_write_axi.arprot = '0;
    assign source_write_axi.arqos = '0;
    assign source_write_axi.arvalid = 1'b0;
    assign source_write_axi.rready = 1'b0;

    always @(posedge clk) begin
        if (!resetn) begin
            write_state <= 0;
            writes_issued <= 0;
            writes_completed <= 0;
            write_start_tick <= 0;
            write_end_tick <= 0;
        end else begin
            if (start)
                write_start_tick <= tick;
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
            if (source_write_axi.bvalid && source_write_axi.bready) begin
                if (source_write_axi.bresp != 2'b00 ||
                    source_write_axi.bid != 3'd0)
                    $fatal(1, "upstream BID/BRESP mismatch bid=%0d resp=%0d",
                           source_write_axi.bid, source_write_axi.bresp);
                writes_completed <= writes_completed + 1;
                if (writes_completed + 1 == WRITE_TRANSACTIONS)
                    write_end_tick <= tick;
            end
        end
    end

    wire reader_busy;
    wire reader_done;
    reg reader_done_seen = 1'b0;
    wire reader_error;
    wire [2:0] reader_error_flags;
    wire [31:0] read_cycles;
    wire [31:0] bytes_read;
    wire [31:0] read_max_outstanding;
    wire [31:0] read_id_mask;
    wire [255:0] stream_data;
    wire [31:0] stream_keep;
    wire stream_valid;
    wire stream_last;
    integer consumed = 0;

    fbus_read_engine #(
        .ID_WIDTH(AXI_ID_WIDTH),
        .READ_ID_COUNT(READ_ID_COUNT),
        .MAX_OUTSTANDING(32)
    ) reader (
        .clk(clk), .resetn(resetn), .start(start), .base_addr(READ_BASE),
        .byte_count(32'(READ_BYTES)), .busy(reader_busy), .done(reader_done),
        .error(reader_error), .burst_beats_limit(9'd2),
        .error_flags(reader_error_flags), .bytes_read(bytes_read),
        .ar_requests(), .read_beats(), .active_cycles(read_cycles),
        .ar_stall_cycles(), .r_wait_cycles(), .r_backpressure_cycles(),
        .max_outstanding_observed(read_max_outstanding),
        .max_reorder_occupancy(), .active_id_mask_observed(read_id_mask),
        .stream_data(stream_data), .stream_keep(stream_keep),
        .stream_valid(stream_valid), .stream_ready(1'b1),
        .stream_last(stream_last), .m_axi(read_axi)
    );

    function automatic [7:0] payload(input [32:0] address);
        payload = 8'(address ^ (address >> 8) ^ (address >> 16));
    endfunction

    always @(posedge clk) begin
        if (!resetn) begin
            consumed <= 0;
            reader_done_seen <= 1'b0;
        end else begin
            if (reader_done)
                reader_done_seen <= 1'b1;
            if (stream_valid) begin
                if (stream_keep != 32'hffff_ffff ||
                    stream_last != (consumed + 32 == READ_BYTES))
                    $fatal(1, "read stream framing mismatch consumed=%0d", consumed);
                for (integer lane = 0; lane < 32; lane++)
                    if (stream_data[lane*8 +: 8] !=
                        payload(READ_BASE + 33'(consumed + lane)))
                        $fatal(1, "read stream data mismatch byte=%0d", consumed + lane);
                consumed <= consumed + 32;
            end
        end
    end

    wire a_valid;
    wire a_ready;
    wire d_ready;
    wire [2:0] a_opcode;
    wire [3:0] a_size;
    wire [6:0] a_source;
    wire [32:0] a_address;
    wire fixer_stall;
    reg [127:0] pending = 0;
    reg [127:0] is_write = 0;
    reg [32:0] addresses [0:127];
    integer due [0:127];
    integer tick = 0;
    integer peak_total = 0;
    integer peak_reads = 0;
    integer peak_writes = 0;
    integer pending_reads;
    integer pending_writes;
    integer write_beat = 0;
    integer selected = -1;
    integer response_beat = 0;
    integer chosen_response;
    reg response_valid = 1'b0;
    reg [MEMORY_DATA_WIDTH-1:0] d_data;
    wire incoming_write = a_opcode != 3'd4;

    always @* begin
        pending_reads = 0;
        pending_writes = 0;
        for (integer i = 0; i < 128; i++) begin
            if (pending[i] && is_write[i])
                pending_writes = pending_writes + 1;
            if (pending[i] && !is_write[i])
                pending_reads = pending_reads + 1;
        end
    end

    // Once the first beat of a multibeat Put is admitted, its remaining beat
    // must not be blocked by the acceptance count it has just consumed.
    assign a_ready = !pending[a_source] &&
        (incoming_write ?
            (write_beat != 0 || pending_writes < WRITE_ACCEPTANCE) :
            pending_reads < READ_ACCEPTANCE);

    always @* begin
        chosen_response = -1;
        for (integer i = 0; i < 128; i++)
            if (pending[i] && due[i] <= tick &&
                (chosen_response < 0 || due[i] < due[chosen_response]))
                chosen_response = i;
    end

    always @* begin
        d_data = '0;
        if (selected >= 0)
            for (integer lane = 0; lane < MEMORY_BYTES; lane++)
                d_data[lane*8 +: 8] = payload(
                    addresses[selected] +
                    33'(response_beat * MEMORY_BYTES + lane));
    end

    fbus_generated_wrapper coupling (
        .clk(clk), .resetn(resetn), .axi(axi),
        .a_ready(a_ready), .a_valid(a_valid), .a_opcode(a_opcode),
        .a_size(a_size), .a_source(a_source), .a_address(a_address),
        .fixer_stall(fixer_stall),
        .d_ready(d_ready), .d_valid(response_valid),
        .d_opcode(selected >= 0 && is_write[selected] ? 3'd0 : 3'd1),
        .d_source(7'(selected)), .d_data(d_data)
    );

    always @(posedge clk) begin
        if (!resetn) begin
            tick <= 0;
            pending <= 0;
            is_write <= 0;
            write_beat <= 0;
            selected <= -1;
            response_beat <= 0;
            response_valid <= 1'b0;
            peak_total <= 0;
            peak_reads <= 0;
            peak_writes <= 0;
        end else begin
            tick <= tick + 1;
            if ($countones(pending) > peak_total)
                peak_total <= $countones(pending);
            if (pending_reads > peak_reads)
                peak_reads <= pending_reads;
            if (pending_writes > peak_writes)
                peak_writes <= pending_writes;

            if (a_valid && a_ready) begin
                if ((a_opcode != 3'd4 && a_opcode != 3'd0 &&
                     a_opcode != 3'd1) || a_size != 4'd6)
                    $fatal(1, "unexpected TL-A opcode/size opcode=%0d size=%0d",
                           a_opcode, a_size);
                if (incoming_write && write_beat != 64/MEMORY_BYTES-1) begin
                    write_beat <= write_beat + 1;
                end else begin
                    write_beat <= 0;
                    pending[a_source] <= 1'b1;
                    is_write[a_source] <= incoming_write;
                    addresses[a_source] <= a_address;
                    due[a_source] <= tick + MEMORY_LATENCY;
                end
            end

            if (selected < 0) begin
                if (chosen_response >= 0) begin
                    selected <= chosen_response;
                    response_valid <= 1'b1;
                end
                response_beat <= 0;
            end else if (response_valid && d_ready) begin
                if (is_write[selected] ||
                    response_beat == 64/MEMORY_BYTES-1) begin
                    pending[selected] <= 1'b0;
                    selected <= -1;
                    response_valid <= 1'b0;
                    response_beat <= 0;
                end else begin
                    response_beat <= response_beat + 1;
                end
            end
        end
    end

    reg [31:0] observed_read_ids = 0;
    reg [31:0] observed_write_ids = 0;
    integer fixer_stall_cycles = 0;
    always @(posedge clk) begin
        if (!resetn) begin
            observed_read_ids <= 0;
            observed_write_ids <= 0;
            fixer_stall_cycles <= 0;
        end else begin
            if (fixer_stall)
                fixer_stall_cycles <= fixer_stall_cycles + 1;
            if (read_axi.arvalid && read_axi.arready)
                observed_read_ids[read_axi.arid] <= 1'b1;
            if (write_axi.awvalid && write_axi.awready)
                observed_write_ids[write_axi.awid] <= 1'b1;
        end
    end

    integer write_cycles;
    integer read_mbps;
    integer write_mbps;
    initial begin
        if (READ_BYTES <= 0 || READ_BYTES % 64 != 0 ||
            WRITE_BYTES <= 0 || WRITE_BYTES % 64 != 0)
            $fatal(1, "read/write byte counts must be positive multiples of 64");
        if (READ_ACCEPTANCE < 1 || WRITE_ACCEPTANCE < 1)
            $fatal(1, "acceptance must be positive");

        repeat (5) @(negedge clk);
        resetn = 1'b1;
        @(negedge clk);
        write_enable = 1'b1;
        start = 1'b1;
        @(negedge clk);
        start = 1'b0;

        wait(reader_done_seen && writes_completed == WRITE_TRANSACTIONS);
        @(negedge clk);
        write_enable = 1'b0;
        wait(pending == 0 && selected < 0 &&
             write_outstanding_current == 0);
        @(negedge clk);

        write_cycles = write_end_tick - write_start_tick + 1;
        read_mbps = READ_BYTES * 100 / read_cycles;
        write_mbps = WRITE_BYTES * 100 / write_cycles;

        if (reader_error || reader_error_flags != 0 ||
            consumed != READ_BYTES || bytes_read != READ_BYTES)
            $fatal(1, "reader protocol/data failure flags=%08x consumed=%0d bytes=%0d",
                   reader_error_flags, consumed, bytes_read);
        if (write_protocol_errors != 0 ||
            writes_issued != WRITE_TRANSACTIONS ||
            writes_completed != WRITE_TRANSACTIONS)
            $fatal(1, "writer protocol/count failure errors=%0d issued=%0d completed=%0d",
                   write_protocol_errors, writes_issued, writes_completed);
        if (EXPECT_DISJOINT_IDS != 0 &&
            (observed_read_ids & observed_write_ids) != 0)
            $fatal(1, "read/write AXI IDs overlap read=%08x write=%08x",
                   observed_read_ids, observed_write_ids);
        if (EXPECT_DISJOINT_IDS == 0 &&
            (observed_read_ids & observed_write_ids) == 0)
            $fatal(1, "shared-ID case did not exercise an overlapping ID");
        if (read_mbps < MIN_READ_MBPS)
            $fatal(1, "read bandwidth %0d MB/s is below %0d MB/s",
                   read_mbps, MIN_READ_MBPS);
        if (write_mbps < MIN_WRITE_MBPS)
            $fatal(1, "write bandwidth %0d MB/s is below %0d MB/s",
                   write_mbps, MIN_WRITE_MBPS);

        $display("FBUS_PRODUCTION read_ids=%0d write_ids=%0d..%0d acceptance=%0d/%0d",
                 READ_ID_COUNT, FIRST_WRITE_ID,
                 FIRST_WRITE_ID + WRITE_ID_COUNT - 1,
                 READ_ACCEPTANCE, WRITE_ACCEPTANCE);
        $display("FBUS_PRODUCTION_BW read=%0dMBps write=%0dMBps read_cycles=%0d write_cycles=%0d",
                 read_mbps, write_mbps, read_cycles, write_cycles);
        $display("FBUS_PRODUCTION_CONCURRENCY read_max=%0d write_max=%0d tl_total=%0d tl_read=%0d tl_write=%0d",
                 read_max_outstanding, write_outstanding_max,
                 peak_total, peak_reads, peak_writes);
        $display("FBUS_PRODUCTION_IDS read=%08x write=%08x overlap=%08x",
                 observed_read_ids, observed_write_ids,
                 observed_read_ids & observed_write_ids);
        $display("FBUS_PRODUCTION_FIXER stall_cycles=%0d", fixer_stall_cycles);
        $display("TB_FBUS_PRODUCTION_CONCURRENCY=PASS");
        $finish;
    end

    initial begin
        #1000000;
        $display("FBUS_TIMEOUT tick=%0d reader_busy=%0b reader_done=%0b read_bytes=%0d consumed=%0d",
                 tick, reader_busy, reader_done, bytes_read, consumed);
        $display("FBUS_TIMEOUT writes_issued=%0d writes_completed=%0d write_state=%0d write_outstanding=%0d",
                 writes_issued, writes_completed, write_state,
                 write_outstanding_current);
        $display("FBUS_TIMEOUT pending=%0d reads=%0d writes=%0d selected=%0d a=%0b/%0b d=%0b/%0b",
                 $countones(pending), pending_reads, pending_writes, selected,
                 a_valid, a_ready, response_valid, d_ready);
        $display("FBUS_TIMEOUT axi_ar=%0b/%0b axi_r=%0b/%0b axi_aw=%0b/%0b axi_w=%0b/%0b axi_b=%0b/%0b",
                 axi.arvalid, axi.arready, axi.rvalid, axi.rready,
                 axi.awvalid, axi.awready, axi.wvalid, axi.wready,
                 axi.bvalid, axi.bready);
        $fatal(1, "deadlock/timeout");
    end
endmodule
