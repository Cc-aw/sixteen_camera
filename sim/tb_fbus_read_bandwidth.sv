`timescale 1ns/1ps

// I: A byte-range read command and a parameterized AXI read responder.
// P: Measure the reader without generated FBus adapters while checking payload,
//    keep, last, 4 KiB splitting, AR stability and legal cross-ID ordering.
// O: A structured performance/correctness snapshot for one controlled case.
// A: hlk
// T: 2026-09-21 12:36:00 CST
module tb_fbus_read_bandwidth #(
    parameter integer READ_ID_COUNT = 31,
    parameter integer READER_SLOTS = 64,
    parameter integer BYTES = 65536,
    parameter integer BURST_BEATS = 2,
    parameter integer RESPONSE_LATENCY = 48,
    parameter integer AR_STALL_PERIOD = 0,
    parameter integer RVALID_PERIOD = 1,
    parameter integer CONSUMER_PERIOD = 1,
    parameter integer RESPONSE_MODE = 0,
    parameter integer ERROR_MODE = 0,
    parameter [32:0] BASE_ADDR = 33'h0_1800_0000
);
    localparam integer ID_WIDTH = 5;
    localparam integer DATA_WIDTH = 256;
    localparam integer BYTE_LANES = DATA_WIDTH / 8;

    reg clk = 1'b0;
    reg resetn = 1'b0;
    reg start = 1'b0;
    always #5 clk = ~clk;

    axi4_if #(.ADDR_WIDTH(33), .DATA_WIDTH(DATA_WIDTH),
              .ID_WIDTH(ID_WIDTH)) axi();
    wire busy, done, error;
    wire [2:0] error_flags;
    wire [31:0] bytes_read, ar_requests, read_beats, active_cycles;
    wire [31:0] ar_stall_cycles, r_wait_cycles, r_backpressure_cycles;
    wire [31:0] max_outstanding_observed, max_reorder_occupancy;
    wire [31:0] active_id_mask_observed;
    wire [DATA_WIDTH-1:0] stream_data;
    wire [BYTE_LANES-1:0] stream_keep;
    wire stream_valid, stream_last;
    integer tick = 0;
    wire stream_ready = CONSUMER_PERIOD <= 1 ||
                        tick % CONSUMER_PERIOD == 0;

    fbus_read_engine #(
        .ID_WIDTH(ID_WIDTH), .READ_ID_COUNT(READ_ID_COUNT),
        .MAX_OUTSTANDING(READER_SLOTS)
    ) dut (
        .clk(clk), .resetn(resetn), .start(start), .base_addr(BASE_ADDR),
        .byte_count(32'(BYTES)), .burst_beats_limit(9'(BURST_BEATS)),
        .busy(busy), .done(done), .error(error), .error_flags(error_flags),
        .bytes_read(bytes_read), .ar_requests(ar_requests),
        .read_beats(read_beats), .active_cycles(active_cycles),
        .ar_stall_cycles(ar_stall_cycles), .r_wait_cycles(r_wait_cycles),
        .r_backpressure_cycles(r_backpressure_cycles),
        .max_outstanding_observed(max_outstanding_observed),
        .max_reorder_occupancy(max_reorder_occupancy),
        .active_id_mask_observed(active_id_mask_observed),
        .stream_data(stream_data), .stream_keep(stream_keep),
        .stream_valid(stream_valid), .stream_ready(stream_ready),
        .stream_last(stream_last), .m_axi(axi)
    );

    reg response_active [0:31];
    reg [32:0] response_addr [0:31];
    reg [8:0] response_left [0:31];
    integer response_due [0:31];
    integer response_sequence [0:31];
    integer next_sequence = 0;
    integer selected_id;
    integer selected_sequence;
    integer round_robin_id = 0;
    integer pending_count = 0;
    integer max_pending = 0;
    integer response_id_changes = 0;
    integer previous_response_id = -1;
    reg out_of_order_seen = 1'b0;
    // I: The first accepted AR and the selected protocol-error mode.
    // P: Inject exactly one RRESP, invalid RID beat, or incorrect RLAST while
    //    leaving all valid response data available to finish the command.
    // O: Deterministic coverage of reader error_flags[0], [1], and [2].
    // A: hlk
    // T: 2026-09-21 12:45:52 CST
    reg error_injection_armed = 1'b0;
    reg error_injection_done = 1'b0;

    function automatic [DATA_WIDTH-1:0] memory_word(input [32:0] address);
        for (integer lane = 0; lane < BYTE_LANES; lane++)
            memory_word[lane*8 +: 8] =
                8'((address + lane) ^ ((address + lane) >> 8) ^
                   ((address + lane) >> 16));
    endfunction

    always @* begin
        selected_id = -1;
        selected_sequence = RESPONSE_MODE == 1 ? -1 : 32'h7fff_ffff;
        if (RESPONSE_MODE == 2) begin
            for (integer offset = 0; offset < 32; offset++) begin
                if (selected_id < 0 &&
                    response_active[(round_robin_id + offset) % 32] &&
                    response_due[(round_robin_id + offset) % 32] <= tick)
                    selected_id = (round_robin_id + offset) % 32;
            end
        end else begin
            for (integer id = 0; id < 32; id++) begin
                if (response_active[id] && response_due[id] <= tick &&
                    ((RESPONSE_MODE == 1 &&
                      response_sequence[id] > selected_sequence) ||
                     (RESPONSE_MODE != 1 &&
                      response_sequence[id] < selected_sequence))) begin
                    selected_id = id;
                    selected_sequence = response_sequence[id];
                end
            end
        end
    end

    wire ar_gate = AR_STALL_PERIOD == 0 ||
                   tick % AR_STALL_PERIOD != 0;
    assign axi.arready = ar_gate && !response_active[axi.arid];
    wire response_gate = RVALID_PERIOD <= 1 ||
                         tick % RVALID_PERIOD == 0;
    wire inject_invalid_id = ERROR_MODE == 2 && error_injection_armed &&
                             !error_injection_done;
    wire inject_normal_error = (ERROR_MODE == 1 || ERROR_MODE == 3) &&
                               error_injection_armed &&
                               !error_injection_done && selected_id >= 0;
    assign axi.rvalid = inject_invalid_id ||
                        (selected_id >= 0 && response_gate);
    assign axi.rid = inject_invalid_id ? ID_WIDTH'(READ_ID_COUNT) :
                     ID_WIDTH'(selected_id);
    assign axi.rdata = selected_id >= 0 && !inject_invalid_id ?
                       memory_word(response_addr[selected_id]) : '0;
    assign axi.rlast = inject_invalid_id ? 1'b0 :
                       ((selected_id >= 0 && response_left[selected_id] == 1) ^
                        (ERROR_MODE == 3 && inject_normal_error));
    assign axi.rresp = ERROR_MODE == 1 && inject_normal_error ? 2'b10 : 2'b00;
    assign axi.awready = 1'b0;
    assign axi.wready = 1'b0;
    assign axi.bid = '0;
    assign axi.bresp = 2'b00;
    assign axi.bvalid = 1'b0;

    reg ar_stalled = 1'b0;
    reg [ID_WIDTH-1:0] held_arid;
    reg [32:0] held_araddr;
    reg [7:0] held_arlen;
    integer response_index;
    always @(posedge clk) begin
        if (!resetn) begin
            tick <= 0;
            next_sequence <= 0;
            round_robin_id <= 0;
            pending_count <= 0;
            max_pending <= 0;
            response_id_changes <= 0;
            previous_response_id <= -1;
            out_of_order_seen <= 1'b0;
            error_injection_armed <= 1'b0;
            error_injection_done <= 1'b0;
            ar_stalled <= 1'b0;
            for (response_index = 0; response_index < 32;
                 response_index++)
                response_active[response_index] <= 1'b0;
        end else begin
            tick <= tick + 1;
            if (pending_count > max_pending)
                max_pending <= pending_count;

            if (axi.arvalid && !axi.arready) begin
                if (ar_stalled &&
                    (axi.arid != held_arid || axi.araddr != held_araddr ||
                     axi.arlen != held_arlen))
                    $fatal(1, "AR changed while stalled");
                held_arid <= axi.arid;
                held_araddr <= axi.araddr;
                held_arlen <= axi.arlen;
                ar_stalled <= 1'b1;
            end else begin
                ar_stalled <= 1'b0;
            end

            if (axi.arvalid && axi.arready) begin
                if (32'(axi.arid) >= READ_ID_COUNT || axi.araddr[4:0] != 0 ||
                    axi.arsize != 3'd5 || axi.arburst != 2'b01)
                    $fatal(1, "illegal AR id=%0d addr=%h", axi.arid,
                           axi.araddr);
                if (32'(axi.araddr[11:0]) +
                    (32'(axi.arlen) + 1) * BYTE_LANES > 4096)
                    $fatal(1, "AR crossed 4 KiB addr=%h len=%0d",
                           axi.araddr, axi.arlen);
                response_active[axi.arid] <= 1'b1;
                response_addr[axi.arid] <= axi.araddr;
                response_left[axi.arid] <= {1'b0, axi.arlen} + 1'b1;
                response_due[axi.arid] <= tick + RESPONSE_LATENCY;
                response_sequence[axi.arid] <= next_sequence;
                next_sequence <= next_sequence + 1;
                if (ERROR_MODE != 0 && !error_injection_done)
                    error_injection_armed <= 1'b1;
            end

            if (axi.rvalid && axi.rready) begin
                if (inject_invalid_id || inject_normal_error) begin
                    error_injection_armed <= 1'b0;
                    error_injection_done <= 1'b1;
                end
                if (inject_invalid_id) begin
                    // The invalid response is intentionally not part of any
                    // valid burst and must not advance responder state.
                end else begin
                    if (previous_response_id >= 0 &&
                        previous_response_id != selected_id)
                        response_id_changes <= response_id_changes + 1;
                    previous_response_id <= selected_id;
                    round_robin_id <= selected_id == 31 ? 0 : selected_id + 1;
                    for (integer older_id = 0; older_id < 32; older_id++)
                        if (response_active[older_id] &&
                            response_sequence[older_id] <
                            response_sequence[selected_id])
                            out_of_order_seen <= 1'b1;
                    if (response_left[selected_id] == 1) begin
                        response_active[selected_id] <= 1'b0;
                    end else begin
                        response_addr[selected_id] <=
                            response_addr[selected_id] + BYTE_LANES;
                        response_left[selected_id] <=
                            response_left[selected_id] - 1'b1;
                    end
                end
            end

            case ({axi.arvalid && axi.arready,
                   axi.rvalid && axi.rready && axi.rlast})
            2'b10: pending_count <= pending_count + 1;
            2'b01: pending_count <= pending_count - 1;
            default: pending_count <= pending_count;
            endcase
        end
    end

    function automatic [31:0] crc32_byte(
        input [31:0] current, input [7:0] value);
        reg [31:0] next;
        begin
            next = current ^ {24'd0, value};
            for (integer bit_index = 0; bit_index < 8; bit_index++)
                next = next[0] ? (next >> 1) ^ 32'hEDB8_8320 : next >> 1;
            crc32_byte = next;
        end
    endfunction

    integer received = 0;
    reg [32:0] expected_addr = BASE_ADDR;
    reg [31:0] crc_state = 32'hffff_ffff;
    longint unsigned byte_sum = 0;
    reg [31:0] next_crc;
    longint unsigned next_byte_sum;
    always @(posedge clk) begin
        if (!resetn) begin
            received = 0;
            expected_addr = BASE_ADDR;
            crc_state <= 32'hffff_ffff;
            byte_sum <= 0;
        end else if (stream_valid && stream_ready) begin
            next_crc = crc_state;
            next_byte_sum = byte_sum;
            for (integer lane = 0; lane < BYTE_LANES; lane++) begin
                if (stream_keep[lane]) begin
                    if (stream_data[lane*8 +: 8] !==
                        8'(expected_addr ^ (expected_addr >> 8) ^
                           (expected_addr >> 16)))
                        $fatal(1, "payload mismatch byte=%0d addr=%h",
                               received, expected_addr);
                    next_crc = crc32_byte(next_crc,
                                          stream_data[lane*8 +: 8]);
                    next_byte_sum = next_byte_sum +
                                    64'(stream_data[lane*8 +: 8]);
                    expected_addr = expected_addr + 1'b1;
                    received = received + 1;
                end
            end
            crc_state <= next_crc;
            byte_sum <= next_byte_sum;
            if (stream_last !== (received == BYTES))
                $fatal(1, "stream_last mismatch received=%0d bytes=%0d",
                       received, BYTES);
        end
    end

    initial begin
        if (READER_SLOTS < 2 ||
            (READER_SLOTS & (READER_SLOTS - 1)) != 0)
            $fatal(1, "READER_SLOTS must be a power of two >= 2");
        if (ERROR_MODE < 0 || ERROR_MODE > 3 ||
            (ERROR_MODE == 2 && READ_ID_COUNT >= (1 << ID_WIDTH)))
            $fatal(1, "ERROR_MODE requires a legal unallocated RID");
        repeat (6) @(posedge clk);
        resetn = 1'b1;
        @(negedge clk);
        start = 1'b1;
        @(negedge clk);
        start = 1'b0;
        wait (done);
        @(negedge clk);
        if (bytes_read != BYTES || received != BYTES)
            $fatal(1, "reader failed error=%b flags=%b bytes=%0d received=%0d",
                   error, error_flags, bytes_read, received);
        if ((ERROR_MODE == 0 && (error || error_flags != 3'b000)) ||
            (ERROR_MODE == 1 && (!error || error_flags != 3'b001)) ||
            (ERROR_MODE == 2 && (!error || error_flags != 3'b010)) ||
            (ERROR_MODE == 3 && (!error || error_flags != 3'b100)))
            $fatal(1, "error injection mismatch mode=%0d error=%b flags=%b",
                   ERROR_MODE, error, error_flags);
        if (ERROR_MODE != 0 && !error_injection_done)
            $fatal(1, "requested error injection did not occur");
        if (RESPONSE_MODE != 0 && !out_of_order_seen)
            $fatal(1, "requested response reordering was not observed");
        $display("READER_ONLY mode=%0d error_mode=%0d burstB=%0d bytes=%0d cycles=%0d MBps_at_100MHz=%0d crc=%08x byte_sum=%0d",
                 RESPONSE_MODE, ERROR_MODE, BURST_BEATS*BYTE_LANES, bytes_read,
                 active_cycles, BYTES*100/active_cycles,
                 crc_state ^ 32'hffff_ffff, byte_sum);
        $display("READER_COUNTERS ar=%0d r_beats=%0d ar_stall=%0d r_wait=%0d r_backpressure=%0d max_outstanding=%0d max_reorder=%0d active_id_mask=%08x responder_pending=%0d response_id_changes=%0d",
                 ar_requests, read_beats, ar_stall_cycles, r_wait_cycles,
                 r_backpressure_cycles, max_outstanding_observed,
                 max_reorder_occupancy, active_id_mask_observed,
                 max_pending, response_id_changes);
        $display("TB_FBUS_READ_BANDWIDTH=PASS");
        $finish;
    end

    initial begin
        #100000000;
        $fatal(1, "timeout busy=%0b pending=%0d received=%0d",
               busy, pending_count, received);
    end
endmodule
