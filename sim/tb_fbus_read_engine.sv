`timescale 1ns/1ps

module tb_fbus_read_engine #(
    parameter integer SLOT_COUNT = 16,
    parameter integer REORDER_SLOTS = 32
);
    localparam integer ADDR_WIDTH = 33;
    localparam integer DATA_WIDTH = 256;
    localparam integer BYTE_LANES = DATA_WIDTH / 8;
    localparam integer ID_INDEX_WIDTH = $clog2(SLOT_COUNT);

    reg clk = 1'b0;
    reg resetn = 1'b0;
    always #5 clk = ~clk;

    reg start = 1'b0;
    reg [ADDR_WIDTH-1:0] base_addr = '0;
    reg [31:0] byte_count = 0;
    reg [8:0] burst_beats_limit = 9'd128;
    wire busy, done, error;
    wire [31:0] bytes_read, ar_requests, read_beats;
    wire [31:0] active_cycles, ar_stall_cycles, r_wait_cycles;
    wire [31:0] r_backpressure_cycles, max_outstanding_observed;
    wire [31:0] max_reorder_occupancy, active_id_mask_observed;
    wire [DATA_WIDTH-1:0] stream_data;
    wire [BYTE_LANES-1:0] stream_keep;
    wire stream_valid;
    reg stream_ready = 1'b0;
    wire stream_last;
    axi4_if #(.ADDR_WIDTH(ADDR_WIDTH), .DATA_WIDTH(DATA_WIDTH),
              .ID_WIDTH(4)) axi();

    fbus_read_engine #(.ID_WIDTH(4), .MAX_OUTSTANDING(REORDER_SLOTS)) dut (
        .clk(clk), .resetn(resetn), .start(start), .base_addr(base_addr),
        .byte_count(byte_count), .busy(busy), .done(done), .error(error),
        .burst_beats_limit(burst_beats_limit),
        .error_flags(), .bytes_read(bytes_read), .ar_requests(ar_requests),
        .read_beats(read_beats), .active_cycles(active_cycles),
        .ar_stall_cycles(ar_stall_cycles),
        .r_wait_cycles(r_wait_cycles),
        .r_backpressure_cycles(r_backpressure_cycles),
        .max_outstanding_observed(max_outstanding_observed),
        .max_reorder_occupancy(max_reorder_occupancy),
        .active_id_mask_observed(active_id_mask_observed),
        .stream_data(stream_data), .stream_keep(stream_keep),
        .stream_valid(stream_valid), .stream_ready(stream_ready),
        .stream_last(stream_last), .m_axi(axi)
    );

    reg [31:0] lfsr = 32'h91e1_0da5;
    reg inject_error = 1'b0;
    integer request_count = 0;
    reg [ADDR_WIDTH-1:0] request_addr [0:2047];
    reg [8:0] request_beats [0:2047];

    reg response_active [0:SLOT_COUNT-1];
    reg [ADDR_WIDTH-1:0] response_addr [0:SLOT_COUNT-1];
    reg [8:0] response_left [0:SLOT_COUNT-1];
    reg [4:0] pending_count = 0;
    reg [5:0] response_holdoff = 0;
    reg rvalid = 1'b0;
    reg [3:0] rid = 0;
    reg [DATA_WIDTH-1:0] rdata = '0;
    reg rlast = 1'b0;
    reg out_of_order_seen = 1'b0;
    integer selected_id;

    function automatic [DATA_WIDTH-1:0] memory_word(
        input [ADDR_WIDTH-1:0] address);
        integer lane;
        begin
            for (lane = 0; lane < BYTE_LANES; lane = lane + 1)
                memory_word[lane*8 +: 8] = 8'((address + lane) ^ ((address + lane) >> 8) ^ ((address + lane) >> 16));
        end
    endfunction

    always @* begin
        selected_id = -1;
        // Highest ID wins. Once eight requests are queued this deliberately
        // completes later requests before ID 0 and exercises the reorder RAM.
        for (integer candidate = 0; candidate < SLOT_COUNT;
             candidate = candidate + 1)
            if (response_active[candidate])
                selected_id = candidate;
    end

    wire ar_accept = axi.arvalid && axi.arready;
    wire r_accept = axi.rvalid && axi.rready;
    assign axi.arready = !response_active[axi.arid[ID_INDEX_WIDTH-1:0]] && (lfsr[0] || lfsr[8]);
    assign axi.rid = rid;
    assign axi.rdata = rdata;
    assign axi.rresp = inject_error && rlast ? 2'b10 : 2'b00;
    assign axi.rlast = rlast;
    assign axi.rvalid = rvalid;
    assign axi.awready = 1'b0;
    assign axi.wready = 1'b0;
    assign axi.bid = 4'd0;
    assign axi.bresp = 2'b00;
    assign axi.bvalid = 1'b0;

    integer response_index;
    always @(posedge clk) begin
        lfsr <= {lfsr[30:0], lfsr[31] ^ lfsr[21] ^ lfsr[1] ^ lfsr[0]};
        stream_ready <= lfsr[3] || lfsr[11];
        if (!resetn) begin
            rvalid <= 1'b0;
            request_count <= 0;
            pending_count <= 0;
            response_holdoff <= 0;
            out_of_order_seen <= 1'b0;
            for (response_index = 0; response_index < SLOT_COUNT;
                 response_index = response_index + 1)
                response_active[response_index] <= 1'b0;
        end else begin
            if (ar_accept) begin
                if (32'(axi.arid) >= SLOT_COUNT || axi.araddr[4:0] != 0 ||
                    axi.arsize != 3'd5 || axi.arburst != 2'b01)
                    $fatal(1, "illegal AR request id=%0d", axi.arid);
                if (32'(axi.araddr[11:0]) +
                    (32'(axi.arlen) + 1'b1) * BYTE_LANES > 4096)
                    $fatal(1, "burst crosses 4 KiB boundary");
                request_addr[request_count] <= axi.araddr;
                request_beats[request_count] <= {1'b0, axi.arlen} + 1'b1;
                request_count <= request_count + 1;
                response_active[axi.arid[ID_INDEX_WIDTH-1:0]] <= 1'b1;
                response_addr[axi.arid[ID_INDEX_WIDTH-1:0]] <= axi.araddr;
                response_left[axi.arid[ID_INDEX_WIDTH-1:0]] <=
                    {1'b0, axi.arlen} + 1'b1;
                if (pending_count == 0)
                    response_holdoff <= 6'd48;
            end

            if (response_holdoff != 0)
                response_holdoff <= response_holdoff - 1'b1;

            if (r_accept) begin
                rvalid <= 1'b0;
                if (rlast) begin
                    response_active[rid[ID_INDEX_WIDTH-1:0]] <= 1'b0;
                    if (rid != 0)
                        out_of_order_seen <= 1'b1;
                end else begin
                    response_addr[rid[ID_INDEX_WIDTH-1:0]] <=
                        response_addr[rid[ID_INDEX_WIDTH-1:0]] + BYTE_LANES;
                    response_left[rid[ID_INDEX_WIDTH-1:0]] <=
                        response_left[rid[ID_INDEX_WIDTH-1:0]] - 1'b1;
                end
            end

            if (!rvalid && response_holdoff == 0 && selected_id >= 0 &&
                (lfsr[2] || lfsr[7])) begin
                rid <= 4'(selected_id);
                rdata <= memory_word(response_addr[selected_id]);
                rlast <= response_left[selected_id] == 1;
                rvalid <= 1'b1;
            end

            case ({ar_accept, r_accept && rlast})
            2'b10: pending_count <= pending_count + 1'b1;
            2'b01: pending_count <= pending_count - 1'b1;
            default: pending_count <= pending_count;
            endcase
        end
    end

    integer received;
    reg [ADDR_WIDTH-1:0] expected_addr;
    always @(posedge clk) begin
        if (resetn && stream_valid && stream_ready) begin
            for (integer lane = 0; lane < BYTE_LANES; lane = lane + 1) begin
                if (stream_keep[lane]) begin
                    if (stream_data[lane*8 +: 8] !== 8'(expected_addr ^ (expected_addr >> 8) ^ (expected_addr >> 16)))
                        $fatal(1,
                            "ordered data mismatch byte=%0d expected=%02x got=%02x",
                            received, expected_addr[7:0],
                            stream_data[lane*8 +: 8]);
                    expected_addr = expected_addr + 1'b1;
                    received = received + 1;
                end
            end
            if (stream_last !== (received == byte_count))
                $fatal(1, "stream_last mismatch received=%0d total=%0d",
                       received, byte_count);
        end
    end

    task automatic run_case(input [ADDR_WIDTH-1:0] address,
                            input [31:0] length,
                            input bit expect_error);
        integer requests_before;
        integer expected_read_beats;
        begin
            wait (!busy);
            @(negedge clk);
            base_addr = address;
            byte_count = length;
            expected_addr = address;
            received = 0;
            inject_error = expect_error;
            requests_before = request_count;
            expected_read_beats = (32'(address[4:0]) + length +
                                  BYTE_LANES - 1) / BYTE_LANES;
            start = 1'b1;
            @(negedge clk);
            start = 1'b0;
            wait (done);
            if (received != length || bytes_read != length)
                $fatal(1, "byte count mismatch got=%0d counter=%0d expected=%0d",
                       received, bytes_read, length);
            if (error !== expect_error)
                $fatal(1, "error mismatch got=%0b expected=%0b",
                       error, expect_error);
            if (length != 0 && ar_requests != request_count-requests_before)
                $fatal(1, "AR counter mismatch");
            if (read_beats != expected_read_beats)
                $fatal(1, "read beat mismatch got=%0d expected=%0d",
                       read_beats, expected_read_beats);
            if (length != 0 && active_cycles == 0)
                $fatal(1, "active cycle counter did not run");
            @(posedge clk);
        end
    endtask

    initial begin
        repeat (6) @(posedge clk);
        resetn = 1'b1;
        run_case(33'h0_1000_0040, 64, 1'b0);
        burst_beats_limit = 9'd2;
        run_case(33'h0_1000_0080, 160, 1'b0);
        if (request_beats[1] != 2 || request_beats[2] != 2 ||
            request_beats[3] != 1)
            $fatal(1, "runtime burst limit was not applied");
        burst_beats_limit = 9'd128;
        run_case(33'h0_1000_001d, 70, 1'b0);
        run_case(33'h0_1000_1ff5, 100, 1'b0);
        if (request_addr[5][11:0] != 12'hfe0 || request_beats[5] != 1 ||
            request_addr[6][11:0] != 12'h000)
            $fatal(1, "4 KiB split mismatch");
        out_of_order_seen = 1'b0;
        run_case(33'h0_1800_0000, 4096*SLOT_COUNT, 1'b0);
        if (max_outstanding_observed != SLOT_COUNT ||
            max_reorder_occupancy != SLOT_COUNT)
            $fatal(1, "ID slots were not exercised outstanding=%0d reorder=%0d",
                   max_outstanding_observed, max_reorder_occupancy);
        if (active_id_mask_observed != (32'd1 << SLOT_COUNT)-1 || !out_of_order_seen)
            $fatal(1, "multi-ID out-of-order response was not exercised mask=%08x",
                   active_id_mask_observed);
        // Reuse IDs while earlier completed data remains in the ordered RAM.
        burst_beats_limit = 9'd2;
        run_case(33'h0_1800_0000, 32768, 1'b0);
        if (max_reorder_occupancy <= SLOT_COUNT ||
            max_outstanding_observed > SLOT_COUNT)
            $fatal(1, "ID lifetime was not decoupled from reorder slots");
        burst_beats_limit = 9'd128;
        run_case(33'h1_0000_0013, 40, 1'b0);
        run_case(33'h0_2000_0000, 32, 1'b1);
        run_case(33'h0_3000_0000, 0, 1'b0);
        $display("TB_FBUS_READ_ENGINE=PASS requests=%0d", request_count);
        $finish;
    end

    initial begin
        #2000000;
        $fatal(1, "timeout state busy=%0b requests=%0d pending=%0d",
               busy, request_count, pending_count);
    end
endmodule
