`timescale 1ns/1ps

// Shared sixteen-channel streaming tensor capture DMA.  Every channel packs
// accepted 2-PPC video directly into a 256-bit elastic FIFO.  The common
// scheduler only emits descriptors whose complete payload is already in the
// FIFO, so an AXI burst can never be starved by the camera source.
module yolov5nu_multi_channel_tensor_dma #(
    parameter integer CHANNELS = 16,
    parameter integer FRAME_WIDTH = 640,
    parameter integer FRAME_HEIGHT = 480,
    parameter integer FIFO_DEPTH = 2048,
    parameter integer BASE_BURST_BEATS = 16,
    parameter integer HIGH_BURST_BEATS = 32,
    parameter integer MAX_BURST_BEATS = 64,
    parameter integer WRITE_OUTSTANDING = 8,
    parameter integer DESCRIPTOR_DEPTH = 32,
    parameter integer AGE_THRESHOLD = 4096,
    parameter [31:0] SLOT_STRIDE = 32'd921600
) (
    input  wire                     clk,
    input  wire                     resetn,
    input  wire                     production_enable,
    input  wire [CHANNELS-1:0]      admission_enable_mask,
    input  wire [4:0]               admission_limit,
    input  wire                     release_pulse,
    input  wire [31:0]              release_mask,
    input  wire                     diagnostic_start,
    input  wire [3:0]               diagnostic_channel,
    input  wire [31:0]              diagnostic_addr,
    input  wire [CHANNELS*48-1:0]   tap_data,
    input  wire [CHANNELS-1:0]      tap_accept,
    input  wire [CHANNELS-1:0]      tap_sof,
    input  wire [CHANNELS-1:0]      tap_eol,
    input  wire [CHANNELS-1:0]      tap_eof,
    input  wire [CHANNELS*32-1:0]   tap_frame_id,
    input  wire [CHANNELS-1:0]      tap_error,

    output wire [31:0]              ready_mask,
    output wire [31:0]              writing_mask,
    output wire [31:0]              error_mask,
    output wire [32*32-1:0]         slot_frame_ids,
    output wire [32*64-1:0]         slot_timestamps,
    output wire [32*32-1:0]         slot_versions,
    output wire [32*8-1:0]          slot_error_codes,
    output wire [32*32-1:0]         slot_byte_counts,
    output wire [CHANNELS*32-1:0]   no_slot_counts,
    output wire [CHANNELS*32-1:0]   missed_frame_counts,
    output wire [CHANNELS*32-1:0]   admission_skip_counts,
    output wire [CHANNELS*32-1:0]   overflow_counts,

    output wire                     diagnostic_busy,
    output reg                      diagnostic_completed,
    output reg                      diagnostic_error,
    output reg  [3:0]               diagnostic_done_channel,
    output reg  [31:0]              diagnostic_frame_id,
    output reg  [31:0]              diagnostic_bytes,
    output reg  [31:0]              diagnostic_overflows,

    output reg  [15:0]              perf_outstanding_current,
    output reg  [15:0]              perf_outstanding_max,
    output reg  [31:0]              perf_source_starvation,
    output reg  [31:0]              perf_aw_stall_cycles,
    output reg  [31:0]              perf_w_stall_cycles,
    output reg  [31:0]              perf_w_transfer_cycles,
    output reg  [31:0]              perf_b_wait_cycles,
    output reg  [31:0]              perf_bursts_issued,
    output reg  [31:0]              perf_bursts_completed,
    output reg  [31:0]              perf_response_errors,
    input  wire [3:0]               perf_channel_index,
    output wire [31:0]              perf_channel_fifo_level,
    output wire [31:0]              perf_channel_fifo_peak,
    output wire [31:0]              perf_channel_wait_max,
    output wire [31:0]              perf_channel_bursts,

    axi4_if.master                  m_axi
);
    localparam integer FRAME_BYTES = FRAME_WIDTH * FRAME_HEIGHT * 3;
    localparam integer FRAME_BEATS = FRAME_BYTES / 32;
    localparam integer FIFO_COUNT_WIDTH = $clog2(FIFO_DEPTH) + 1;
    localparam integer CHANNEL_WIDTH = CHANNELS <= 1 ? 1 : $clog2(CHANNELS);
    localparam integer DESC_PTR_WIDTH = DESCRIPTOR_DEPTH <= 1 ?
                                        1 : $clog2(DESCRIPTOR_DEPTH);
    localparam integer DESC_COUNT_WIDTH = $clog2(DESCRIPTOR_DEPTH + 1);
    localparam integer ACTIVE_COUNT_WIDTH = $clog2(CHANNELS + 1);
    localparam [31:0] ARENA0_BASE = 32'h3000_0000;
    localparam [31:0] ARENA1_BASE = 32'h3100_0000;
    localparam [7:0] SLOT_ERR_STREAM = 8'h01;
    localparam [7:0] SLOT_ERR_OVERFLOW = 8'h02;
    localparam [7:0] SLOT_ERR_AXI = 8'h04;
    localparam [7:0] SLOT_ERR_CANCEL = 8'h08;

    wire [255:0] packed_data [0:CHANNELS-1];
    wire packed_sof [0:CHANNELS-1];
    wire packed_eol [0:CHANNELS-1];
    wire packed_eof [0:CHANNELS-1];
    wire packed_error [0:CHANNELS-1];
    wire [31:0] packed_frame_id [0:CHANNELS-1];
    wire packed_valid [0:CHANNELS-1];
    wire packed_ready [0:CHANNELS-1];
    wire packer_input_ready [0:CHANNELS-1];

    wire [291:0] fifo_dout [0:CHANNELS-1];
    wire fifo_empty [0:CHANNELS-1];
    wire fifo_full [0:CHANNELS-1];
    wire [FIFO_COUNT_WIDTH-1:0] fifo_count [0:CHANNELS-1];
    reg [CHANNELS-1:0] fifo_rd_en;
    reg [3:0] flush_count [0:CHANNELS-1];

    reg ctx_active [0:CHANNELS-1];
    reg ctx_diagnostic [0:CHANNELS-1];
    reg ctx_bad [0:CHANNELS-1];
    reg ctx_plan_done [0:CHANNELS-1];
    reg ctx_slot [0:CHANNELS-1];
    reg [31:0] ctx_base [0:CHANNELS-1];
    reg [31:0] ctx_frame_id [0:CHANNELS-1];
    reg [63:0] ctx_timestamp [0:CHANNELS-1];
    reg [31:0] ctx_version [0:CHANNELS-1];
    reg [7:0] ctx_error_code [0:CHANNELS-1];
    reg [31:0] ctx_plan_beat [0:CHANNELS-1];
    reg [15:0] reserved_beats [0:CHANNELS-1];
    reg [15:0] channel_desc_pending [0:CHANNELS-1];
    reg [15:0] age_count [0:CHANNELS-1];
    reg [31:0] fifo_peak [0:CHANNELS-1];
    reg [31:0] wait_max [0:CHANNELS-1];
    reg [31:0] channel_bursts [0:CHANNELS-1];
    reg [31:0] no_slot_count [0:CHANNELS-1];
    reg [31:0] missed_count [0:CHANNELS-1];
    reg [31:0] admission_skip_count [0:CHANNELS-1];
    reg [31:0] overflow_count [0:CHANNELS-1];
    reg ready0 [0:CHANNELS-1];
    reg ready1 [0:CHANNELS-1];
    reg error0 [0:CHANNELS-1];
    reg error1 [0:CHANNELS-1];
    reg [31:0] frame0 [0:CHANNELS-1];
    reg [31:0] frame1 [0:CHANNELS-1];
    reg [63:0] timestamp0 [0:CHANNELS-1];
    reg [63:0] timestamp1 [0:CHANNELS-1];
    reg [31:0] version0 [0:CHANNELS-1];
    reg [31:0] version1 [0:CHANNELS-1];
    reg [7:0] error_code0 [0:CHANNELS-1];
    reg [7:0] error_code1 [0:CHANNELS-1];
    reg [31:0] bytes0 [0:CHANNELS-1];
    reg [31:0] bytes1 [0:CHANNELS-1];
    reg [31:0] stream_version [0:CHANNELS-1];
    reg [63:0] capture_cycle;

    reg diagnostic_armed;
    reg [3:0] diagnostic_channel_q;
    reg [31:0] diagnostic_addr_q;

    reg [31:0] desc_addr [0:DESCRIPTOR_DEPTH-1];
    reg [31:0] desc_beat [0:DESCRIPTOR_DEPTH-1];
    reg [8:0] desc_beats [0:DESCRIPTOR_DEPTH-1];
    reg [CHANNEL_WIDTH-1:0] desc_channel [0:DESCRIPTOR_DEPTH-1];
    reg desc_last [0:DESCRIPTOR_DEPTH-1];
    reg desc_diagnostic [0:DESCRIPTOR_DEPTH-1];
    reg desc_slot [0:DESCRIPTOR_DEPTH-1];
    reg [DESC_PTR_WIDTH-1:0] alloc_ptr, aw_ptr, w_ptr, b_ptr;
    reg [DESC_COUNT_WIDTH-1:0] desc_count;
    reg [DESC_COUNT_WIDTH-1:0] aw_pending_count;
    reg [DESC_COUNT_WIDTH-1:0] w_pending_count;
    reg [DESC_COUNT_WIDTH-1:0] b_pending_count;

    reg w_desc_valid;
    reg [CHANNEL_WIDTH-1:0] w_channel_q;
    reg [8:0] w_beats_q;
    reg [8:0] w_index;
    reg [31:0] w_beat_q;

    reg [CHANNEL_WIDTH-1:0] rr_channel;
    reg [CHANNEL_WIDTH-1:0] admission_rr;
    reg [CHANNELS-1:0] admission_permit;
    reg [CHANNELS-1:0] admission_permit_next;
    reg [CHANNELS-1:0] admission_eligible;
    reg [CHANNELS-1:0] admission_grant;
    reg [ACTIVE_COUNT_WIDTH-1:0] admission_grant_count;
    reg [ACTIVE_COUNT_WIDTH-1:0] admission_permit_count;
    reg admission_rr_advance;
    reg [ACTIVE_COUNT_WIDTH-1:0] production_active_count;
    reg [ACTIVE_COUNT_WIDTH-1:0] production_finish_count;
    reg [ACTIVE_COUNT_WIDTH-1:0] admission_capacity;
    reg [ACTIVE_COUNT_WIDTH-1:0] admission_capacity_q;
    reg probe_valid;
    reg [CHANNEL_WIDTH-1:0] probe_channel;
    reg [FIFO_COUNT_WIDTH-1:0] probe_fifo_count;
    reg [15:0] probe_reserved_beats;
    reg [15:0] probe_age_count;
    reg [31:0] probe_plan_beat;
    reg [31:0] probe_base;
    reg probe_diagnostic;
    reg probe_slot;
    reg selected_valid;
    reg [CHANNEL_WIDTH-1:0] selected_channel;
    reg [8:0] selected_beats;
    reg [31:0] selected_addr;
    reg [31:0] selected_beat;
    reg selected_last;
    reg schedule_valid;
    reg [CHANNEL_WIDTH-1:0] schedule_channel;
    reg [8:0] schedule_beats;
    reg [31:0] schedule_addr;
    reg [31:0] schedule_beat;
    reg schedule_last;
    reg schedule_diagnostic;
    reg schedule_slot;
    integer i, finish_index, admission_index;
    integer scheduler_candidate;
    integer admission_active_after;
    integer available, remaining, boundary, target;

    wire aw_fire = m_axi.awvalid && m_axi.awready;
    wire w_fire = m_axi.wvalid && m_axi.wready;
    wire w_last_fire = w_fire && m_axi.wlast;
    wire b_fire = m_axi.bvalid && m_axi.bready;
    wire descriptor_space = desc_count < DESC_COUNT_WIDTH'(DESCRIPTOR_DEPTH) ||
                            b_fire;
    wire credit_available = b_pending_count <
                            DESC_COUNT_WIDTH'(WRITE_OUTSTANDING) || b_fire;
    wire allocate_fire = schedule_valid && descriptor_space;
    wire w_desc_load = !w_desc_valid && w_pending_count != 0;
    wire [CHANNEL_WIDTH-1:0] w_channel = w_channel_q;
    wire [CHANNEL_WIDTH-1:0] b_channel = desc_channel[b_ptr];
    wire [255:0] w_fifo_data = fifo_dout[w_channel][255:0];
    wire [31:0] w_fifo_frame = fifo_dout[w_channel][287:256];
    wire w_fifo_sof = fifo_dout[w_channel][288];
    wire w_fifo_eol = fifo_dout[w_channel][289];
    wire w_fifo_eof = fifo_dout[w_channel][290];
    wire w_fifo_error = fifo_dout[w_channel][291];
    wire [31:0] w_absolute_beat = w_beat_q + w_index;
    wire w_data_error = w_fire &&
        (w_fifo_error || w_fifo_frame != ctx_frame_id[w_channel] ||
         w_fifo_sof != (w_absolute_beat == 0) ||
         w_fifo_eol != ((w_absolute_beat % (FRAME_WIDTH*3/32)) ==
                        (FRAME_WIDTH*3/32)-1) ||
         w_fifo_eof != (w_absolute_beat == FRAME_BEATS-1));
    wire b_completion_error = ctx_bad[b_channel] || m_axi.bresp != 0 ||
        (w_data_error && w_channel == b_channel);

    function automatic [CHANNEL_WIDTH-1:0] next_channel(
        input [CHANNEL_WIDTH-1:0] channel);
        if (channel == CHANNEL_WIDTH'(CHANNELS-1))
            next_channel = '0;
        else
            next_channel = channel + 1'b1;
    endfunction

    // A balanced reduction keeps admission accounting out of a sixteen-stage
    // carry chain. CHANNELS is asserted to be 16 below.
    function automatic [ACTIVE_COUNT_WIDTH-1:0] admission_mask_count(
        input [CHANNELS-1:0] mask);
        reg [1:0] pair_count [0:7];
        reg [2:0] quad_count [0:3];
        reg [3:0] octet_count [0:1];
        begin
            pair_count[0] = mask[0] + mask[1];
            pair_count[1] = mask[2] + mask[3];
            pair_count[2] = mask[4] + mask[5];
            pair_count[3] = mask[6] + mask[7];
            pair_count[4] = mask[8] + mask[9];
            pair_count[5] = mask[10] + mask[11];
            pair_count[6] = mask[12] + mask[13];
            pair_count[7] = mask[14] + mask[15];
            quad_count[0] = pair_count[0] + pair_count[1];
            quad_count[1] = pair_count[2] + pair_count[3];
            quad_count[2] = pair_count[4] + pair_count[5];
            quad_count[3] = pair_count[6] + pair_count[7];
            octet_count[0] = quad_count[0] + quad_count[1];
            octet_count[1] = quad_count[2] + quad_count[3];
            admission_mask_count = octet_count[0] + octet_count[1];
        end
    endfunction

    // Count production contexts at their registered start/finish boundaries.
    // Do not recompute this value from all ctx_active bits in the admission
    // cone: that old cross-channel reduction drove another channel's packer
    // CE directly and missed the 150 MHz camera-video clock by 2.5 ns after
    // full-system routing.
    always @(*) begin
        production_finish_count = 0;
        for (finish_index = 0; finish_index < CHANNELS;
             finish_index = finish_index + 1)
            if (ctx_active[finish_index] &&
                !ctx_diagnostic[finish_index] &&
                ((ctx_bad[finish_index] &&
                  channel_desc_pending[finish_index] == 0) ||
                 (b_fire && desc_last[b_ptr] &&
                  !desc_diagnostic[b_ptr] &&
                  b_channel == CHANNEL_WIDTH'(finish_index))))
                production_finish_count = production_finish_count + 1'b1;
    end

    // Reserve capture credits before SOF. The RR allocator visits one channel
    // per clock, while each channel consumes its registered permit locally at
    // SOF. This avoids requiring a one-cycle SOF to collide with a global
    // token and permits several pre-authorized channels to start together.
    always @(*) begin
        if (admission_limit == 0)
            admission_capacity = ACTIVE_COUNT_WIDTH'(1);
        else if (admission_limit > CHANNELS)
            admission_capacity = ACTIVE_COUNT_WIDTH'(CHANNELS);
        else
            admission_capacity = ACTIVE_COUNT_WIDTH'(admission_limit);

        admission_eligible = '0;
        for (admission_index = 0; admission_index < CHANNELS;
             admission_index = admission_index + 1) begin
            admission_eligible[admission_index] =
                production_enable && !diagnostic_armed &&
                admission_enable_mask[admission_index] &&
                !ctx_active[admission_index] &&
                flush_count[admission_index] == 0 &&
                (!ready0[admission_index] || !ready1[admission_index]);
        end

        admission_grant = admission_permit & admission_eligible &
                          tap_accept & tap_sof;
        admission_permit_next = admission_permit & admission_eligible &
                                ~admission_grant;
        // A capacity change invalidates idle reservations atomically. This
        // prevents stale permits from exceeding a newly lowered limit and is
        // cheaper than selecting the first N bits through a serial trim cone.
        if (admission_capacity != admission_capacity_q) begin
            admission_grant = '0;
            admission_permit_next = '0;
        end
        admission_grant_count = admission_mask_count(admission_grant);
        admission_permit_count =
            admission_mask_count(admission_permit_next);
        admission_active_after = production_active_count +
                                 admission_grant_count -
                                 production_finish_count;
        if (admission_active_after < 0)
            admission_active_after = 0;

        // Allocation is off the SOF-to-packer path. Advancing the candidate
        // every clock fills all available permits within one channel rotation.
        admission_rr_advance = 1'b0;
        if (production_enable && !diagnostic_armed &&
            admission_capacity == admission_capacity_q &&
            admission_active_after + admission_permit_count <
                admission_capacity) begin
            admission_rr_advance = 1'b1;
            if (admission_eligible[admission_rr] &&
                !admission_permit_next[admission_rr] &&
                !admission_grant[admission_rr]) begin
                admission_permit_next[admission_rr] = 1'b1;
                admission_permit_count = admission_permit_count + 1'b1;
            end
        end
    end

    function automatic [DESC_PTR_WIDTH-1:0] next_ptr(
        input [DESC_PTR_WIDTH-1:0] pointer);
        if (pointer == DESC_PTR_WIDTH'(DESCRIPTOR_DEPTH-1))
            next_ptr = '0;
        else
            next_ptr = pointer + 1'b1;
    endfunction

    generate
        for (genvar ch = 0; ch < CHANNELS; ch++) begin : g_frontend
            wire start_production = admission_grant[ch];
            wire start_diagnostic = diagnostic_armed &&
                diagnostic_channel_q == 4'(ch) && !ctx_active[ch] &&
                flush_count[ch] == 0 && tap_accept[ch] && tap_sof[ch];
            wire capture_input = tap_accept[ch] &&
                                 (ctx_active[ch] || start_production ||
                                  start_diagnostic);
            wire frontend_resetn = resetn && flush_count[ch] == 0;

            yolov5nu_tensor_stream_packer #(
                .FRAME_WIDTH(FRAME_WIDTH), .FRAME_HEIGHT(FRAME_HEIGHT)
            ) u_packer (
                .clk(clk), .resetn(frontend_resetn),
                .s_pair(tap_data[ch*48 +: 48]), .s_sof(tap_sof[ch]),
                .s_eol(tap_eol[ch]), .s_eof(tap_eof[ch]),
                .s_frame_id(tap_frame_id[ch*32 +: 32]),
                .s_error(tap_error[ch]), .s_valid(capture_input),
                .s_ready(packer_input_ready[ch]), .m_data(packed_data[ch]),
                .m_sof(packed_sof[ch]), .m_eol(packed_eol[ch]),
                .m_eof(packed_eof[ch]), .m_frame_id(packed_frame_id[ch]),
                .m_error(packed_error[ch]), .m_valid(packed_valid[ch]),
                .m_ready(packed_ready[ch])
            );

            assign packed_ready[ch] = !fifo_full[ch];
            wire [291:0] fifo_din = {
                packed_error[ch], packed_eof[ch], packed_eol[ch],
                packed_sof[ch], packed_frame_id[ch], packed_data[ch]
            };

`ifdef VERILATOR
            reg [291:0] sim_mem [0:FIFO_DEPTH-1];
            reg [$clog2(FIFO_DEPTH)-1:0] sim_wr_ptr, sim_rd_ptr;
            reg [FIFO_COUNT_WIDTH-1:0] sim_count;
            wire sim_write = packed_valid[ch] && packed_ready[ch];
            wire sim_read = fifo_rd_en[ch] && !fifo_empty[ch];
            assign fifo_dout[ch] = sim_mem[sim_rd_ptr];
            assign fifo_empty[ch] = sim_count == 0;
            assign fifo_full[ch] = sim_count == FIFO_COUNT_WIDTH'(FIFO_DEPTH);
            assign fifo_count[ch] = sim_count;
            always @(posedge clk) begin
                if (!frontend_resetn) begin
                    sim_wr_ptr <= 0;
                    sim_rd_ptr <= 0;
                    sim_count <= 0;
                end else begin
                    if (sim_write) begin
                        sim_mem[sim_wr_ptr] <= fifo_din;
                        sim_wr_ptr <= sim_wr_ptr + 1'b1;
                    end
                    if (sim_read)
                        sim_rd_ptr <= sim_rd_ptr + 1'b1;
                    case ({sim_write, sim_read})
                        2'b10: sim_count <= sim_count + 1'b1;
                        2'b01: sim_count <= sim_count - 1'b1;
                        default: ;
                    endcase
                end
            end
`else
            xpm_fifo_sync #(
                .FIFO_MEMORY_TYPE("block"), .ECC_MODE("no_ecc"),
                .FIFO_WRITE_DEPTH(FIFO_DEPTH), .WRITE_DATA_WIDTH(292),
                .READ_DATA_WIDTH(292), .READ_MODE("fwft"),
                .FIFO_READ_LATENCY(0), .PROG_FULL_THRESH(FIFO_DEPTH-8),
                .WR_DATA_COUNT_WIDTH(FIFO_COUNT_WIDTH),
                .RD_DATA_COUNT_WIDTH(FIFO_COUNT_WIDTH),
                .DOUT_RESET_VALUE("0"), .FULL_RESET_VALUE(0),
                .USE_ADV_FEATURES("0707"), .WAKEUP_TIME(0)
            ) u_fifo (
                .sleep(1'b0), .rst(!frontend_resetn), .wr_clk(clk),
                .wr_en(packed_valid[ch] && packed_ready[ch]), .din(fifo_din),
                .full(fifo_full[ch]), .prog_full(),
                .wr_data_count(fifo_count[ch]), .overflow(), .wr_ack(),
                .almost_full(), .wr_rst_busy(), .injectsbiterr(1'b0),
                .injectdbiterr(1'b0), .sbiterr(), .dbiterr(),
                .rd_en(fifo_rd_en[ch]), .dout(fifo_dout[ch]),
                .empty(fifo_empty[ch]), .rd_data_count(), .underflow(),
                .data_valid(), .almost_empty(), .prog_empty(), .rd_rst_busy()
            );
`endif

            assign ready_mask[ch] = ready0[ch];
            assign ready_mask[ch+16] = ready1[ch];
            assign writing_mask[ch] = ctx_active[ch] &&
                                      !ctx_diagnostic[ch] && !ctx_slot[ch];
            assign writing_mask[ch+16] = ctx_active[ch] &&
                                         !ctx_diagnostic[ch] && ctx_slot[ch];
            assign error_mask[ch] = error0[ch];
            assign error_mask[ch+16] = error1[ch];
            assign slot_frame_ids[ch*32 +: 32] = frame0[ch];
            assign slot_frame_ids[(ch+16)*32 +: 32] = frame1[ch];
            assign slot_timestamps[ch*64 +: 64] = timestamp0[ch];
            assign slot_timestamps[(ch+16)*64 +: 64] = timestamp1[ch];
            assign slot_versions[ch*32 +: 32] = version0[ch];
            assign slot_versions[(ch+16)*32 +: 32] = version1[ch];
            assign slot_error_codes[ch*8 +: 8] = error_code0[ch];
            assign slot_error_codes[(ch+16)*8 +: 8] = error_code1[ch];
            assign slot_byte_counts[ch*32 +: 32] = bytes0[ch];
            assign slot_byte_counts[(ch+16)*32 +: 32] = bytes1[ch];
            assign no_slot_counts[ch*32 +: 32] = no_slot_count[ch];
            assign missed_frame_counts[ch*32 +: 32] = missed_count[ch];
            assign admission_skip_counts[ch*32 +: 32] =
                admission_skip_count[ch];
            assign overflow_counts[ch*32 +: 32] = overflow_count[ch];
        end
    endgenerate

    assign diagnostic_busy = diagnostic_armed ||
        (diagnostic_channel_q < CHANNELS &&
         ctx_active[diagnostic_channel_q] &&
         ctx_diagnostic[diagnostic_channel_q]);
    assign perf_channel_fifo_level =
        {{(32-FIFO_COUNT_WIDTH){1'b0}}, fifo_count[perf_channel_index]};
    assign perf_channel_fifo_peak = fifo_peak[perf_channel_index];
    assign perf_channel_wait_max = wait_max[perf_channel_index];
    assign perf_channel_bursts = channel_bursts[perf_channel_index];

    always @* begin
        selected_valid = 1'b0;
        selected_channel = '0;
        selected_beats = 0;
        selected_addr = 0;
        selected_beat = 0;
        selected_last = 0;
        boundary = 0;
        target = 0;
        available = probe_fifo_count - probe_reserved_beats;
        remaining = FRAME_BEATS - probe_plan_beat;
        // The array lookup for one RR candidate is registered in probe_*.
        // This second stage only sizes that captured candidate, keeping the
        // channel mux and burst/boundary arithmetic in separate 150 MHz
        // cycles.
        if (probe_valid &&
            (available >= MAX_BURST_BEATS ||
             (remaining < MAX_BURST_BEATS && available >= remaining) ||
             (probe_age_count >= AGE_THRESHOLD &&
              available >= BASE_BURST_BEATS))) begin
            selected_valid = 1'b1;
            selected_channel = probe_channel;
        end
        if (selected_valid) begin
            selected_addr = probe_base + probe_plan_beat*32;
            selected_beat = probe_plan_beat;
            boundary = 128 - (selected_addr[11:5]);
            // Normal traffic waits for a complete maximum-size burst.  Only
            // an all-present frame tail or an aged channel may fall back to
            // 32/16 beats; this prevents eager 16-beat draining from making
            // the larger burst thresholds unreachable.
            if (remaining < MAX_BURST_BEATS && available >= remaining)
                target = remaining;
            else if (available >= MAX_BURST_BEATS)
                target = MAX_BURST_BEATS;
            else if (available >= HIGH_BURST_BEATS)
                target = HIGH_BURST_BEATS;
            else
                target = BASE_BURST_BEATS;
            if (available < target) target = available;
            if (remaining < target) target = remaining;
            if (boundary < target) target = boundary;
            selected_beats = 9'(target);
            selected_last = target == remaining;
        end
    end

    always @* begin
        fifo_rd_en = '0;
        if (w_fire)
            fifo_rd_en[w_channel] = 1'b1;
    end

    assign m_axi.aclk = clk;
    assign m_axi.aresetn = resetn;
    assign m_axi.awid = 3'd0;
    assign m_axi.awaddr = desc_addr[aw_ptr];
    assign m_axi.awlen = desc_beats[aw_ptr][7:0] - 1'b1;
    assign m_axi.awsize = 3'b101;
    assign m_axi.awburst = 2'b01;
    assign m_axi.awlock = 1'b0;
    assign m_axi.awcache = 4'b0010;
    assign m_axi.awprot = 3'b000;
    assign m_axi.awqos = 4'h6;
    assign m_axi.awvalid = aw_pending_count != 0 && credit_available;
    assign m_axi.wdata = w_fifo_data;
    assign m_axi.wstrb = 32'hffff_ffff;
    assign m_axi.wlast = w_desc_valid && w_index == w_beats_q-1'b1;
    assign m_axi.wvalid = w_desc_valid && !fifo_empty[w_channel];
    assign m_axi.bready = b_pending_count != 0;
    assign m_axi.arid = 3'd0;
    assign m_axi.araddr = 32'd0;
    assign m_axi.arlen = 8'd0;
    assign m_axi.arsize = 3'd0;
    assign m_axi.arburst = 2'd0;
    assign m_axi.arlock = 1'b0;
    assign m_axi.arcache = 4'd0;
    assign m_axi.arprot = 3'd0;
    assign m_axi.arqos = 4'd0;
    assign m_axi.arvalid = 1'b0;
    assign m_axi.rready = 1'b0;

    initial begin
        if (CHANNELS != 16 || FRAME_WIDTH < 32 || FRAME_WIDTH % 32 != 0 ||
            (FRAME_BYTES % 32) != 0 || SLOT_STRIDE < FRAME_BYTES ||
            SLOT_STRIDE[4:0] != 0 || FIFO_DEPTH < MAX_BURST_BEATS ||
            (FIFO_DEPTH & (FIFO_DEPTH-1)) != 0 ||
            BASE_BURST_BEATS < 1 || BASE_BURST_BEATS > HIGH_BURST_BEATS ||
            HIGH_BURST_BEATS > MAX_BURST_BEATS ||
            WRITE_OUTSTANDING < 1 ||
            WRITE_OUTSTANDING > DESCRIPTOR_DEPTH)
            $error("Invalid multi-channel tensor DMA parameters");
    end

    always @(posedge clk) begin
        if (!resetn) begin
            alloc_ptr <= 0; aw_ptr <= 0; w_ptr <= 0; b_ptr <= 0;
            desc_count <= 0; aw_pending_count <= 0;
            w_pending_count <= 0; b_pending_count <= 0;
            w_desc_valid <= 0; w_channel_q <= 0; w_beats_q <= 0;
            w_beat_q <= 0;
            w_index <= 0; rr_channel <= CHANNEL_WIDTH'(CHANNELS-1);
            schedule_valid <= 1'b0;
            schedule_channel <= '0;
            schedule_beats <= 0;
            schedule_addr <= 0;
            schedule_beat <= 0;
            schedule_last <= 1'b0;
            schedule_diagnostic <= 1'b0;
            schedule_slot <= 1'b0;
            probe_valid <= 1'b0;
            probe_channel <= '0;
            probe_fifo_count <= 0;
            probe_reserved_beats <= 0;
            probe_age_count <= 0;
            probe_plan_beat <= 0;
            probe_base <= 0;
            probe_diagnostic <= 1'b0;
            probe_slot <= 1'b0;
            admission_rr <= '0;
            admission_permit <= '0;
            admission_capacity_q <= ACTIVE_COUNT_WIDTH'(1);
            production_active_count <= '0;
            diagnostic_armed <= 0; diagnostic_channel_q <= 0;
            diagnostic_addr_q <= 0; diagnostic_completed <= 0;
            diagnostic_error <= 0; diagnostic_done_channel <= 0;
            diagnostic_frame_id <= 0; diagnostic_bytes <= 0;
            diagnostic_overflows <= 0;
            perf_outstanding_current <= 0; perf_outstanding_max <= 0;
            perf_source_starvation <= 0; perf_aw_stall_cycles <= 0;
            perf_w_stall_cycles <= 0; perf_w_transfer_cycles <= 0;
            perf_b_wait_cycles <= 0; perf_bursts_issued <= 0;
            perf_bursts_completed <= 0; perf_response_errors <= 0;
            capture_cycle <= 0;
            for (i = 0; i < CHANNELS; i = i + 1) begin
                ctx_active[i] <= 0; ctx_diagnostic[i] <= 0;
                ctx_bad[i] <= 0; ctx_plan_done[i] <= 0; ctx_slot[i] <= 0;
                ctx_base[i] <= 0; ctx_frame_id[i] <= 0;
                ctx_timestamp[i] <= 0; ctx_version[i] <= 0;
                ctx_error_code[i] <= 0;
                ctx_plan_beat[i] <= 0; reserved_beats[i] <= 0;
                channel_desc_pending[i] <= 0; age_count[i] <= 0;
                flush_count[i] <= 4'hf; fifo_peak[i] <= 0;
                wait_max[i] <= 0; channel_bursts[i] <= 0;
                no_slot_count[i] <= 0; missed_count[i] <= 0;
                admission_skip_count[i] <= 0;
                overflow_count[i] <= 0;
                ready0[i] <= 0; ready1[i] <= 0;
                error0[i] <= 0; error1[i] <= 0;
                frame0[i] <= 0; frame1[i] <= 0;
                timestamp0[i] <= 0; timestamp1[i] <= 0;
                version0[i] <= 0; version1[i] <= 0;
                error_code0[i] <= 0; error_code1[i] <= 0;
                bytes0[i] <= 0; bytes1[i] <= 0;
                stream_version[i] <= 0;
            end
        end else begin
            capture_cycle <= capture_cycle + 1'b1;
            production_active_count <= ACTIVE_COUNT_WIDTH'(
                production_active_count +
                admission_grant_count -
                production_finish_count);
            admission_permit <= admission_permit_next;
            admission_capacity_q <= admission_capacity;
            rr_channel <= next_channel(rr_channel);
            // Probe one channel per clock.  The descriptor queue normally
            // stays ahead of W data, so a full 16-channel rotation fits in
            // the minimum burst while avoiding a channel-wide priority cone.
            scheduler_candidate = next_channel(rr_channel);
            probe_valid <= ctx_active[scheduler_candidate] &&
                           !ctx_bad[scheduler_candidate] &&
                           !ctx_plan_done[scheduler_candidate];
            probe_channel <= CHANNEL_WIDTH'(scheduler_candidate);
            probe_fifo_count <= fifo_count[scheduler_candidate];
            probe_reserved_beats <= reserved_beats[scheduler_candidate];
            probe_age_count <= age_count[scheduler_candidate];
            probe_plan_beat <= ctx_plan_beat[scheduler_candidate];
            probe_base <= ctx_base[scheduler_candidate];
            probe_diagnostic <= ctx_diagnostic[scheduler_candidate];
            probe_slot <= ctx_slot[scheduler_candidate];
            // Register the complete scheduling proposal before it reaches
            // descriptor allocation and per-channel accounting.  The prior
            // direct path combined channel muxing, FIFO arithmetic, burst
            // sizing and a second per-channel update in one 150 MHz cycle.
            if (!schedule_valid || allocate_fire) begin
                schedule_valid <= selected_valid;
                schedule_channel <= selected_channel;
                schedule_beats <= selected_beats;
                schedule_addr <= selected_addr;
                schedule_beat <= selected_beat;
                schedule_last <= selected_last;
                schedule_diagnostic <= probe_diagnostic;
                schedule_slot <= probe_slot;
            end
            if (!production_enable)
                admission_rr <= '0;
            else if (admission_rr_advance)
                admission_rr <= next_channel(admission_rr);
            if (diagnostic_start && !production_enable && !diagnostic_busy) begin
                diagnostic_armed <= 1'b1;
                diagnostic_channel_q <= diagnostic_channel;
                diagnostic_addr_q <= diagnostic_addr;
                diagnostic_done_channel <= diagnostic_channel;
                diagnostic_completed <= 1'b0;
                diagnostic_error <= 1'b0;
                diagnostic_bytes <= 0;
                if (diagnostic_channel >= CHANNELS || diagnostic_addr[4:0]) begin
                    diagnostic_armed <= 1'b0;
                    diagnostic_completed <= 1'b1;
                    diagnostic_error <= 1'b1;
                end
            end

            perf_outstanding_current <= 16'(b_pending_count);
            if (b_pending_count > perf_outstanding_max)
                perf_outstanding_max <= 16'(b_pending_count);
            if (m_axi.awvalid && !m_axi.awready)
                perf_aw_stall_cycles <= perf_aw_stall_cycles + 1'b1;
            if (m_axi.wvalid && !m_axi.wready)
                perf_w_stall_cycles <= perf_w_stall_cycles + 1'b1;
            if (w_desc_valid && m_axi.wready && !m_axi.wvalid)
                perf_source_starvation <= perf_source_starvation + 1'b1;
            if (w_fire)
                perf_w_transfer_cycles <= perf_w_transfer_cycles + 1'b1;
            if (b_pending_count != 0 && !m_axi.bvalid)
                perf_b_wait_cycles <= perf_b_wait_cycles + 1'b1;
            if (aw_fire)
                perf_bursts_issued <= perf_bursts_issued + 1'b1;
            if (b_fire) begin
                perf_bursts_completed <= perf_bursts_completed + 1'b1;
                if (m_axi.bresp != 0)
                    perf_response_errors <= perf_response_errors + 1'b1;
            end

            case ({allocate_fire, b_fire})
                2'b10: desc_count <= desc_count + 1'b1;
                2'b01: desc_count <= desc_count - 1'b1;
                default: ;
            endcase
            case ({allocate_fire, aw_fire})
                2'b10: aw_pending_count <= aw_pending_count + 1'b1;
                2'b01: aw_pending_count <= aw_pending_count - 1'b1;
                default: ;
            endcase
            case ({aw_fire, w_last_fire})
                2'b10: w_pending_count <= w_pending_count + 1'b1;
                2'b01: w_pending_count <= w_pending_count - 1'b1;
                default: ;
            endcase
            case ({aw_fire, b_fire})
                2'b10: b_pending_count <= b_pending_count + 1'b1;
                2'b01: b_pending_count <= b_pending_count - 1'b1;
                default: ;
            endcase

            if (allocate_fire) begin
                desc_addr[alloc_ptr] <= schedule_addr;
                desc_beat[alloc_ptr] <= schedule_beat;
                desc_beats[alloc_ptr] <= schedule_beats;
                desc_channel[alloc_ptr] <= schedule_channel;
                desc_last[alloc_ptr] <= schedule_last;
                desc_diagnostic[alloc_ptr] <= schedule_diagnostic;
                desc_slot[alloc_ptr] <= schedule_slot;
                alloc_ptr <= next_ptr(alloc_ptr);
                ctx_plan_beat[schedule_channel] <=
                    ctx_plan_beat[schedule_channel] + schedule_beats;
                ctx_plan_done[schedule_channel] <= schedule_last;
                channel_bursts[schedule_channel] <=
                    channel_bursts[schedule_channel] + 1'b1;
                if (age_count[schedule_channel] > wait_max[schedule_channel])
                    wait_max[schedule_channel] <= age_count[schedule_channel];
                age_count[schedule_channel] <= 0;
            end
            if (aw_fire)
                aw_ptr <= next_ptr(aw_ptr);
            if (w_desc_load) begin
                w_desc_valid <= 1'b1;
                w_channel_q <= desc_channel[w_ptr];
                w_beats_q <= desc_beats[w_ptr];
                w_beat_q <= desc_beat[w_ptr];
                w_index <= 0;
            end else if (w_last_fire) begin
                w_desc_valid <= 1'b0;
                w_ptr <= next_ptr(w_ptr);
                w_index <= 0;
            end else if (w_fire)
                w_index <= w_index + 1'b1;
            if (b_fire)
                b_ptr <= next_ptr(b_ptr);

            for (i = 0; i < CHANNELS; i = i + 1) begin
                if (flush_count[i] != 0)
                    flush_count[i] <= flush_count[i] - 1'b1;
                if (fifo_count[i] > fifo_peak[i])
                    fifo_peak[i] <= fifo_count[i];
                if (ctx_active[i] && !ctx_bad[i] && !ctx_plan_done[i] &&
                    fifo_count[i] >= reserved_beats[i] + BASE_BURST_BEATS &&
                    !(allocate_fire && schedule_channel == CHANNEL_WIDTH'(i))) begin
                    if (age_count[i] != 16'hffff)
                        age_count[i] <= age_count[i] + 1'b1;
                end

                if (release_pulse) begin
                    if (release_mask[i]) begin
                        ready0[i] <= 0; error0[i] <= 0; error_code0[i] <= 0;
                    end
                    if (release_mask[i+16]) begin
                        ready1[i] <= 0; error1[i] <= 0; error_code1[i] <= 0;
                    end
                end

                if (admission_grant[i]) begin
                        ctx_active[i] <= 1'b1;
                        ctx_diagnostic[i] <= 1'b0;
                        ctx_bad[i] <= tap_error[i];
                        ctx_plan_done[i] <= 1'b0;
                        ctx_slot[i] <= ready0[i];
                        ctx_base[i] <= (!ready0[i] ? ARENA0_BASE : ARENA1_BASE)
                                       + i*SLOT_STRIDE;
                        ctx_frame_id[i] <= tap_frame_id[i*32 +: 32];
                        ctx_timestamp[i] <= capture_cycle;
                        ctx_version[i] <= stream_version[i] + 1'b1;
                        ctx_error_code[i] <= tap_error[i] ?
                                             SLOT_ERR_STREAM : 8'd0;
                        stream_version[i] <= stream_version[i] + 1'b1;
                        ctx_plan_beat[i] <= 0;
                        reserved_beats[i] <= 0;
                        channel_desc_pending[i] <= 0;
                        if (!ready0[i]) error0[i] <= 0;
                        else error1[i] <= 0;
                end else if (production_enable && !diagnostic_armed &&
                             admission_enable_mask[i] && tap_accept[i] &&
                             tap_sof[i]) begin
                    if (!ctx_active[i] && flush_count[i] == 0 &&
                        ready0[i] && ready1[i])
                        no_slot_count[i] <= no_slot_count[i] + 1'b1;
                    else if (!ctx_active[i] && flush_count[i] == 0 &&
                             (!ready0[i] || !ready1[i]))
                        admission_skip_count[i] <=
                            admission_skip_count[i] + 1'b1;
                    if (!admission_grant[i])
                        missed_count[i] <= missed_count[i] + 1'b1;
                end

                if (diagnostic_armed && diagnostic_channel_q == 4'(i) &&
                    tap_accept[i] && tap_sof[i] && !ctx_active[i] &&
                    flush_count[i] == 0) begin
                    ctx_active[i] <= 1'b1;
                    ctx_diagnostic[i] <= 1'b1;
                    ctx_bad[i] <= tap_error[i];
                    ctx_plan_done[i] <= 1'b0;
                    ctx_slot[i] <= 1'b0;
                    ctx_base[i] <= diagnostic_addr_q;
                    ctx_frame_id[i] <= tap_frame_id[i*32 +: 32];
                    ctx_timestamp[i] <= capture_cycle;
                    ctx_version[i] <= 0;
                    ctx_error_code[i] <= tap_error[i] ?
                                             SLOT_ERR_STREAM : 8'd0;
                    ctx_plan_beat[i] <= 0;
                    reserved_beats[i] <= 0;
                    channel_desc_pending[i] <= 0;
                    diagnostic_frame_id <= tap_frame_id[i*32 +: 32];
                    diagnostic_armed <= 1'b0;
                end

                if (ctx_active[i] && tap_accept[i] &&
                    !packer_input_ready[i]) begin
                    ctx_bad[i] <= 1'b1;
                    ctx_error_code[i] <=
                        ctx_error_code[i] | SLOT_ERR_OVERFLOW;
                    overflow_count[i] <= overflow_count[i] + 1'b1;
                    if (ctx_diagnostic[i])
                        diagnostic_overflows <= diagnostic_overflows + 1'b1;
                end
                if (ctx_active[i] && !ctx_diagnostic[i] &&
                    !production_enable) begin
                    ctx_bad[i] <= 1'b1;
                    ctx_error_code[i] <=
                        ctx_error_code[i] | SLOT_ERR_CANCEL;
                end

                case ({allocate_fire &&
                       schedule_channel == CHANNEL_WIDTH'(i),
                       w_fire && w_channel == CHANNEL_WIDTH'(i)})
                    2'b10: reserved_beats[i] <=
                        reserved_beats[i] + schedule_beats;
                    2'b01: reserved_beats[i] <= reserved_beats[i] - 1'b1;
                    2'b11: reserved_beats[i] <=
                        reserved_beats[i] + schedule_beats - 1'b1;
                    default: ;
                endcase
                case ({allocate_fire &&
                       schedule_channel == CHANNEL_WIDTH'(i),
                       b_fire && b_channel == CHANNEL_WIDTH'(i)})
                    2'b10: channel_desc_pending[i] <=
                        channel_desc_pending[i] + 1'b1;
                    2'b01: channel_desc_pending[i] <=
                        channel_desc_pending[i] - 1'b1;
                    default: ;
                endcase

                if (ctx_bad[i] && channel_desc_pending[i] == 0) begin
                    ctx_active[i] <= 1'b0;
                    ctx_plan_done[i] <= 1'b0;
                    reserved_beats[i] <= 0;
                    flush_count[i] <= 4'd8;
                    if (ctx_diagnostic[i]) begin
                        diagnostic_completed <= 1'b1;
                        diagnostic_error <= 1'b1;
                        diagnostic_bytes <= 0;
                    end else if (ctx_slot[i]) begin
                        frame1[i] <= ctx_frame_id[i];
                        timestamp1[i] <= ctx_timestamp[i];
                        version1[i] <= ctx_version[i];
                        bytes1[i] <= 0;
                        error_code1[i] <= ctx_error_code[i];
                        ready1[i] <= 1'b0; error1[i] <= 1'b1;
                    end else begin
                        frame0[i] <= ctx_frame_id[i];
                        timestamp0[i] <= ctx_timestamp[i];
                        version0[i] <= ctx_version[i];
                        bytes0[i] <= 0;
                        error_code0[i] <= ctx_error_code[i];
                        ready0[i] <= 1'b0; error0[i] <= 1'b1;
                    end
                end
            end

            if (w_data_error) begin
                ctx_bad[w_channel] <= 1'b1;
                ctx_error_code[w_channel] <=
                    ctx_error_code[w_channel] | SLOT_ERR_STREAM;
            end

            if (b_fire) begin
                if (m_axi.bresp != 0) begin
                    ctx_bad[b_channel] <= 1'b1;
                    ctx_error_code[b_channel] <=
                        ctx_error_code[b_channel] | SLOT_ERR_AXI;
                end
                if (desc_last[b_ptr]) begin
                    ctx_active[b_channel] <= 1'b0;
                    ctx_plan_done[b_channel] <= 1'b0;
                    reserved_beats[b_channel] <= 0;
                    if (desc_diagnostic[b_ptr]) begin
                        diagnostic_completed <= 1'b1;
                        diagnostic_error <= b_completion_error;
                        diagnostic_bytes <= FRAME_BYTES;
                    end else if (desc_slot[b_ptr]) begin
                        frame1[b_channel] <= ctx_frame_id[b_channel];
                        timestamp1[b_channel] <= ctx_timestamp[b_channel];
                        version1[b_channel] <= ctx_version[b_channel];
                        bytes1[b_channel] <= FRAME_BYTES;
                        error_code1[b_channel] <= ctx_error_code[b_channel] |
                            (m_axi.bresp != 0 ? SLOT_ERR_AXI : 8'd0) |
                            (w_data_error && w_channel == b_channel ?
                             SLOT_ERR_STREAM : 8'd0);
                        ready1[b_channel] <= !b_completion_error;
                        error1[b_channel] <= b_completion_error;
                    end else begin
                        frame0[b_channel] <= ctx_frame_id[b_channel];
                        timestamp0[b_channel] <= ctx_timestamp[b_channel];
                        version0[b_channel] <= ctx_version[b_channel];
                        bytes0[b_channel] <= FRAME_BYTES;
                        error_code0[b_channel] <= ctx_error_code[b_channel] |
                            (m_axi.bresp != 0 ? SLOT_ERR_AXI : 8'd0) |
                            (w_data_error && w_channel == b_channel ?
                             SLOT_ERR_STREAM : 8'd0);
                        ready0[b_channel] <= !b_completion_error;
                        error0[b_channel] <= b_completion_error;
                    end
                end
            end
        end
    end

`ifndef SYNTHESIS
    always @(posedge clk) begin
        if (resetn) begin
            if (allocate_fire && (schedule_beats == 0 ||
                schedule_beats > MAX_BURST_BEATS))
                $fatal(1, "invalid tensor DMA descriptor length");
            if (allocate_fire && schedule_addr[11:0] +
                (schedule_beats << 5) > 4096)
                $fatal(1, "tensor DMA descriptor crosses 4 KiB boundary");
            if (w_fire && fifo_empty[w_channel])
                $fatal(1, "tensor DMA W transfer without FIFO payload");
            if (b_pending_count > WRITE_OUTSTANDING)
                $fatal(1, "tensor DMA outstanding credit overflow");
            if (production_finish_count > production_active_count +
                admission_grant_count)
                $fatal(1, "tensor DMA production active-count underflow");
            if ((admission_active_after >= admission_capacity &&
                 admission_permit_count != 0) ||
                (admission_active_after < admission_capacity &&
                 admission_active_after + admission_permit_count >
                    admission_capacity))
                $fatal(1, "tensor DMA admission credit overflow");
        end
    end
`endif

    wire unused = &{1'b0, m_axi.bid, m_axi.rid, m_axi.rdata,
                    m_axi.rresp, m_axi.rlast, m_axi.rvalid};
endmodule
