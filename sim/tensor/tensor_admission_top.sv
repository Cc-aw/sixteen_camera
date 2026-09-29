module tensor_admission_top (
    input  wire        clk,
    input  wire        resetn,
    output wire        done,
    output wire        failed,
    output wire [7:0]  failure_code,
    output wire [15:0] permit_debug,
    output wire [31:0] ready_debug,
    output wire [31:0] aw_count_debug,
    output wire [31:0] w_count_debug,
    output wire [31:0] b_count_debug,
    output wire [31:0] max_outstanding_debug,
    output wire [2:0]  state_debug
);
    localparam integer CHANNELS = 16;
    reg production_enable;
    reg [CHANNELS-1:0] admission_enable_mask;
    reg [4:0] admission_limit;
    reg [CHANNELS*48-1:0] tap_data;
    reg [CHANNELS-1:0] tap_accept;
    reg [CHANNELS-1:0] tap_sof;
    reg [CHANNELS-1:0] tap_eol;
    reg [CHANNELS-1:0] tap_eof;
    reg [CHANNELS*32-1:0] tap_frame_id;
    wire [31:0] ready_mask, writing_mask, error_mask;
    wire [1023:0] slot_frame_ids, slot_byte_counts;
    wire [2047:0] slot_timestamps;
    wire [1023:0] slot_versions;
    wire [255:0] slot_error_codes;
    wire [511:0] no_slot_counts, missed_frame_counts;
    wire [511:0] admission_skip_counts, overflow_counts;
    axi4_if #(.ADDR_WIDTH(32), .DATA_WIDTH(256), .ID_WIDTH(3)) axi();

    integer aw_count;
    integer w_count;
    integer b_count;
    integer completed_w;
    integer max_outstanding;
    reg [7:0] failed_q;
    reg done_q;
    reg [5:0] pair_index;
    reg [2:0] state;
    localparam [2:0] ST_FILL_HIGH = 0, ST_TRIM = 1, ST_REFILL = 2,
                     ST_SEND = 3, ST_DRAIN = 4, ST_DONE = 5;

    yolov5nu_multi_channel_tensor_dma #(
        .FRAME_WIDTH(32), .FRAME_HEIGHT(2), .FIFO_DEPTH(16),
        .BASE_BURST_BEATS(2), .HIGH_BURST_BEATS(3),
        .MAX_BURST_BEATS(4), .WRITE_OUTSTANDING(8),
        .DESCRIPTOR_DEPTH(16), .AGE_THRESHOLD(1000),
        .SLOT_STRIDE(32'd192)
    ) dut (
        .clk(clk), .resetn(resetn), .production_enable(production_enable),
        .admission_enable_mask(admission_enable_mask),
        .admission_limit(admission_limit),
        .release_pulse(1'b0), .release_mask(32'd0),
        .tap_data(tap_data),
        .tap_accept(tap_accept), .tap_sof(tap_sof), .tap_eol(tap_eol),
        .tap_eof(tap_eof), .tap_frame_id(tap_frame_id),
        .tap_error(16'd0), .ready_mask(ready_mask),
        .writing_mask(writing_mask), .error_mask(error_mask),
        .slot_frame_ids(slot_frame_ids), .slot_timestamps(slot_timestamps),
        .slot_versions(slot_versions), .slot_error_codes(slot_error_codes),
        .slot_byte_counts(slot_byte_counts),
        .no_slot_counts(no_slot_counts),
        .missed_frame_counts(missed_frame_counts),
        .admission_skip_counts(admission_skip_counts),
        .overflow_counts(overflow_counts),
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
    assign axi.bvalid = state == ST_DRAIN && completed_w > b_count;
    assign axi.arready = 1'b0;
    assign axi.rid = 3'd0;
    assign axi.rdata = 256'd0;
    assign axi.rresp = 2'd0;
    assign axi.rlast = 1'b0;
    assign axi.rvalid = 1'b0;

    always @* begin
        production_enable = resetn;
        admission_enable_mask = 16'hffff;
        admission_limit = 5'd8;
        if (state == ST_TRIM)
            admission_limit = 5'd1;
        else if (state >= ST_REFILL) begin
            admission_enable_mask = 16'h0003;
            admission_limit = 5'd2;
        end
        tap_data = '0;
        tap_accept = '0;
        tap_sof = '0;
        tap_eol = '0;
        tap_eof = '0;
        tap_frame_id = '0;
        tap_frame_id[0 +: 32] = 32'd100;
        tap_frame_id[32 +: 32] = 32'd200;
        if (state == ST_SEND) begin
            tap_accept[1:0] = 2'b11;
            tap_sof[1:0] = pair_index == 0 ? 2'b11 : 2'b00;
            tap_eol[1:0] = pair_index == 15 || pair_index == 31 ?
                             2'b11 : 2'b00;
            tap_eof[1:0] = pair_index == 31 ? 2'b11 : 2'b00;
            tap_data[0 +: 48] =
                {24'(pair_index*2+1), 24'(pair_index*2)};
            tap_data[48 +: 48] =
                {24'(pair_index*2+3), 24'(pair_index*2+2)};
        end
    end

    always @(posedge clk or negedge resetn) begin
        if (!resetn) begin
            aw_count <= 0;
            w_count <= 0;
            b_count <= 0;
            completed_w <= 0;
            max_outstanding <= 0;
            failed_q <= 8'd0;
            done_q <= 1'b0;
            pair_index <= 0;
            state <= ST_FILL_HIGH;
        end else begin
            if (axi.awvalid && axi.awready) begin
                aw_count <= aw_count + 1;
                if (axi.awlen > 3)
                    failed_q[0] <= 1'b1;
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

            case (state)
            ST_FILL_HIGH: begin
                if (dut.admission_permit_count == 8)
                    state <= ST_TRIM;
            end
            ST_TRIM: begin
                if (dut.admission_permit != 0 &&
                    (dut.admission_permit &
                     (dut.admission_permit - 1'b1)) == 0)
                    state <= ST_REFILL;
            end
            ST_REFILL: begin
                if (dut.admission_permit == 16'h0003) begin
                    pair_index <= 0;
                    state <= ST_SEND;
                end
            end
            ST_SEND: begin
                if (pair_index == 31) begin
                    pair_index <= 0;
                    state <= ST_DRAIN;
                end else
                    pair_index <= pair_index + 1'b1;
            end
            ST_DRAIN: begin
                if (ready_mask[1:0] == 2'b11 &&
                    b_count + (axi.bvalid && axi.bready ? 1 : 0) != aw_count)
                    failed_q[1] <= 1'b1;
                if (ready_mask[1:0] == 2'b11) begin
                    if (error_mask[1:0] != 0 ||
                        aw_count != b_count +
                            (axi.bvalid && axi.bready ? 1 : 0) ||
                        slot_frame_ids[0 +: 32] != 100 ||
                        slot_frame_ids[32 +: 32] != 200 ||
                        slot_byte_counts[0 +: 32] != 192 ||
                        slot_byte_counts[32 +: 32] != 192 ||
                        max_outstanding < 2)
                        failed_q[2] <= 1'b1;
                    done_q <= 1'b1;
                    state <= ST_DONE;
                end
            end
            default: ;
            endcase
        end
    end

    assign done = done_q;
    assign failed = |failed_q;
    assign failure_code = failed_q;
    assign permit_debug = dut.admission_permit;
    assign ready_debug = ready_mask;
    assign aw_count_debug = aw_count;
    assign w_count_debug = w_count;
    assign b_count_debug = b_count;
    assign max_outstanding_debug = max_outstanding;
    assign state_debug = state;
endmodule
