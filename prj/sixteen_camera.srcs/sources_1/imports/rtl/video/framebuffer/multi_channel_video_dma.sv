`timescale 1ns/1ps

// A configurable number of capture channels share one ordered AXI4 writer.
// A descriptor ring decouples burst planning, AW issue, W transfer and B
// completion. All channels share one global outstanding credit pool.
module multi_channel_video_dma #(
    parameter integer CHANNELS = 3,
    parameter integer FRAME_WIDTH = 1920,
    parameter integer FRAME_HEIGHT = 1080,
    parameter integer FRAME_STRIDE_BYTES = FRAME_WIDTH * 4,
    parameter integer FIFO_DEPTH = 1024,
    parameter integer BURST_MAX_BEATS = 64,
    parameter integer FRAME_ID_WIDTH = 32,
    parameter integer WRITE_OUTSTANDING = 8,
    parameter integer DESCRIPTOR_DEPTH = 16
) (
    video_stream_if.sink channels [CHANNELS],
    axi4_if.master       m_axi,

    output wire [CHANNELS-1:0]    buffer_acquire,
    input  wire [CHANNELS-1:0]    buffer_grant,
    input  wire [CHANNELS-1:0]    buffer_drop,
    input  wire [CHANNELS*32-1:0] buffer_base,
    output reg  [CHANNELS-1:0]    frame_done,
    output reg  [CHANNELS-1:0]    frame_error,

    output wire [CHANNELS-1:0] channel_active,
    output wire [CHANNELS*($clog2(FIFO_DEPTH)+1)-1:0] fifo_levels,
    output wire [CHANNELS*FRAME_ID_WIDTH-1:0] active_frame_ids,

    output reg  [15:0] perf_outstanding_current,
    output reg  [15:0] perf_outstanding_max,
    output reg  [31:0] perf_aw_stall_cycles,
    output reg  [31:0] perf_w_stall_cycles,
    output reg  [31:0] perf_b_stall_cycles,
    output reg  [31:0] perf_bursts_issued,
    output reg  [31:0] perf_bursts_completed,
    output reg  [31:0] perf_response_errors
);
    localparam integer WORDS_PER_LINE = FRAME_WIDTH / 8;
    localparam integer FIFO_COUNT_WIDTH = $clog2(FIFO_DEPTH) + 1;
    localparam integer CHANNEL_WIDTH = (CHANNELS <= 1) ?
                                       1 : $clog2(CHANNELS);
    localparam integer DESC_PTR_WIDTH = (DESCRIPTOR_DEPTH <= 1) ?
                                        1 : $clog2(DESCRIPTOR_DEPTH);
    localparam integer DESC_COUNT_WIDTH = $clog2(DESCRIPTOR_DEPTH + 1);
    localparam [DESC_COUNT_WIDTH-1:0] DESC_DEPTH_VALUE =
        DESC_COUNT_WIDTH'(DESCRIPTOR_DEPTH);
    localparam [DESC_COUNT_WIDTH-1:0] WRITE_CREDIT_VALUE =
        DESC_COUNT_WIDTH'(WRITE_OUTSTANDING);

    localparam [2:0] PLAN_IDLE = 3'd0;
    localparam [2:0] PLAN_CAPTURE = 3'd1;
    localparam [2:0] PLAN_SIZE = 3'd2;
    localparam [2:0] PLAN_DATA_CREDIT = 3'd3;
    localparam [2:0] PLAN_ADDRESS = 3'd4;
    localparam [2:0] PLAN_BOUNDARY = 3'd5;
    localparam [2:0] PLAN_FLAGS = 3'd6;
    localparam [2:0] PLAN_ENQUEUE = 3'd7;

    wire [255:0] fifo_data [0:CHANNELS-1];
    wire fifo_sof [0:CHANNELS-1];
    wire fifo_eol [0:CHANNELS-1];
    wire fifo_eof [0:CHANNELS-1];
    wire fifo_error_bit [0:CHANNELS-1];
    wire [FRAME_ID_WIDTH-1:0] fifo_frame_id [0:CHANNELS-1];
    wire fifo_empty [0:CHANNELS-1];
    wire fifo_full [0:CHANNELS-1];
    wire [FIFO_COUNT_WIDTH-1:0] fifo_count [0:CHANNELS-1];
    reg [CHANNELS-1:0] fifo_rd_en;

    reg ctx_active [0:CHANNELS-1];
    reg ctx_drop [0:CHANNELS-1];
    reg ctx_bad [0:CHANNELS-1];
    reg ctx_plan_done [0:CHANNELS-1];
    reg [31:0] ctx_line_addr [0:CHANNELS-1];
    reg [15:0] ctx_line [0:CHANNELS-1];
    reg [15:0] ctx_word [0:CHANNELS-1];
    reg [15:0] reserved_words [0:CHANNELS-1];
    reg [FRAME_ID_WIDTH-1:0] ctx_frame_id [0:CHANNELS-1];

    reg [31:0] desc_addr [0:DESCRIPTOR_DEPTH-1];
    reg [8:0] desc_beats [0:DESCRIPTOR_DEPTH-1];
    reg [CHANNEL_WIDTH-1:0] desc_channel [0:DESCRIPTOR_DEPTH-1];
    reg [15:0] desc_line [0:DESCRIPTOR_DEPTH-1];
    reg [15:0] desc_word [0:DESCRIPTOR_DEPTH-1];
    reg desc_finishes_frame [0:DESCRIPTOR_DEPTH-1];

    reg [DESC_PTR_WIDTH-1:0] alloc_ptr;
    reg [DESC_PTR_WIDTH-1:0] aw_ptr;
    reg [DESC_PTR_WIDTH-1:0] w_ptr;
    reg [DESC_PTR_WIDTH-1:0] b_ptr;
    reg [DESC_COUNT_WIDTH-1:0] desc_count;
    reg [DESC_COUNT_WIDTH-1:0] aw_pending_count;
    reg [DESC_COUNT_WIDTH-1:0] w_pending_count;
    reg [DESC_COUNT_WIDTH-1:0] b_pending_count;
    reg w_desc_valid;
    reg [CHANNEL_WIDTH-1:0] w_channel_q;
    reg [8:0] w_beats_q;
    reg [15:0] w_line_q;
    reg [15:0] w_word_q;
    reg [8:0] w_beat_index;

    reg [2:0] planner_state;
    reg [CHANNEL_WIDTH-1:0] planner_channel;
    reg [CHANNEL_WIDTH-1:0] round_robin_last;
    reg [31:0] planner_line_addr;
    reg [31:0] planner_addr;
    reg [8:0] planner_beats;
    reg [15:0] planner_line;
    reg [15:0] planner_word;
    reg planner_finishes_line;
    reg planner_finishes_frame;

    integer i;

    function automatic [DESC_PTR_WIDTH-1:0] next_desc_ptr;
        input [DESC_PTR_WIDTH-1:0] pointer;
        begin
            if (pointer == DESC_PTR_WIDTH'(DESCRIPTOR_DEPTH-1))
                next_desc_ptr = {DESC_PTR_WIDTH{1'b0}};
            else
                next_desc_ptr = pointer + 1'b1;
        end
    endfunction

    generate
        genvar status_ch;
        for (status_ch = 0; status_ch < CHANNELS;
             status_ch = status_ch + 1) begin : g_channels
            channel_write_fifo #(
                .FIFO_DEPTH(FIFO_DEPTH),
                .FRAME_ID_WIDTH(FRAME_ID_WIDTH)
            ) u_fifo (
                .s_stream(channels[status_ch]),
                .rd_en(fifo_rd_en[status_ch]),
                .rd_data(fifo_data[status_ch]),
                .rd_sof(fifo_sof[status_ch]),
                .rd_eol(fifo_eol[status_ch]),
                .rd_eof(fifo_eof[status_ch]),
                .rd_frame_id(fifo_frame_id[status_ch]),
                .rd_error(fifo_error_bit[status_ch]),
                .empty(fifo_empty[status_ch]),
                .full(fifo_full[status_ch]),
                .data_count(fifo_count[status_ch])
            );
            assign buffer_acquire[status_ch] =
                !ctx_active[status_ch] && !ctx_drop[status_ch] &&
                !fifo_empty[status_ch] && fifo_sof[status_ch];
            assign channel_active[status_ch] = ctx_active[status_ch];
            assign fifo_levels[
                status_ch*FIFO_COUNT_WIDTH +: FIFO_COUNT_WIDTH] =
                fifo_count[status_ch];
            assign active_frame_ids[
                status_ch*FRAME_ID_WIDTH +: FRAME_ID_WIDTH] =
                ctx_frame_id[status_ch];
        end
    endgenerate

    wire aw_fire = m_axi.awvalid && m_axi.awready;
    wire w_fire = m_axi.wvalid && m_axi.wready;
    wire w_last_fire = w_fire && m_axi.wlast;
    wire b_fire = m_axi.bvalid && m_axi.bready;
    wire descriptor_space = (desc_count < DESC_DEPTH_VALUE) || b_fire;
    wire write_credit_available =
        (b_pending_count < WRITE_CREDIT_VALUE) || b_fire;
    wire allocate_fire = (planner_state == PLAN_ENQUEUE) && descriptor_space;
    // The descriptor arrays infer distributed RAM.  Register the descriptor
    // selected by w_ptr before using it on the AXI W path; otherwise the
    // asynchronous RAM read and channel mux sit in the same 300 MHz cycle as
    // the FIFO enable and frame-integrity checks.
    wire w_desc_load = !w_desc_valid && (w_pending_count != 0);
    wire [CHANNEL_WIDTH-1:0] w_channel = w_channel_q;
    wire [CHANNEL_WIDTH-1:0] b_channel = desc_channel[b_ptr];
    wire [15:0] w_absolute_word = w_word_q + w_beat_index;
    wire w_data_error = w_fire &&
        (fifo_error_bit[w_channel] ||
         (fifo_frame_id[w_channel] != ctx_frame_id[w_channel]) ||
         (fifo_sof[w_channel] !=
             ((w_line_q == 0) && (w_absolute_word == 0))) ||
         (fifo_eol[w_channel] != (w_absolute_word == WORDS_PER_LINE-1)) ||
         (fifo_eof[w_channel] !=
             ((w_line_q == FRAME_HEIGHT-1) &&
              (w_absolute_word == WORDS_PER_LINE-1))));

    always @* begin
        fifo_rd_en = {CHANNELS{1'b0}};
        for (i = 0; i < CHANNELS; i = i + 1)
            if (!fifo_empty[i] &&
                (ctx_drop[i] || (!ctx_active[i] && !fifo_sof[i])))
                fifo_rd_en[i] = 1'b1;
        if (w_fire)
            fifo_rd_en[w_channel] = 1'b1;
    end

    assign m_axi.aclk = channels[0].aclk;
    assign m_axi.aresetn = channels[0].aresetn;
    assign m_axi.awid = '0;
    assign m_axi.awaddr = desc_addr[aw_ptr];
    assign m_axi.awlen = desc_beats[aw_ptr][7:0] - 1'b1;
    assign m_axi.awsize = 3'b101;
    assign m_axi.awburst = 2'b01;
    assign m_axi.awlock = 1'b0;
    assign m_axi.awcache = 4'b0010;
    assign m_axi.awprot = 3'b000;
    assign m_axi.awqos = 4'he;
    assign m_axi.awvalid = (aw_pending_count != 0) &&
                           write_credit_available;
    assign m_axi.wdata = fifo_data[w_channel];
    assign m_axi.wstrb = 32'hffff_ffff;
    assign m_axi.wlast = w_desc_valid &&
                         (w_beat_index == w_beats_q-1'b1);
    assign m_axi.wvalid = w_desc_valid && !fifo_empty[w_channel];
    assign m_axi.bready = (b_pending_count != 0);
    assign m_axi.arid = '0;
    assign m_axi.araddr = 32'd0;
    assign m_axi.arlen = 8'd0;
    assign m_axi.arsize = 3'b101;
    assign m_axi.arburst = 2'b01;
    assign m_axi.arlock = 1'b0;
    assign m_axi.arcache = 4'd0;
    assign m_axi.arprot = 3'd0;
    assign m_axi.arqos = 4'd0;
    assign m_axi.arvalid = 1'b0;
    assign m_axi.rready = 1'b0;

    initial begin
        if (CHANNELS < 1 || CHANNELS > 16 ||
            (FRAME_WIDTH % 8) != 0 || FRAME_HEIGHT <= 0 ||
            (FRAME_STRIDE_BYTES < FRAME_WIDTH*4) ||
            ((FRAME_STRIDE_BYTES % 32) != 0) ||
            BURST_MAX_BEATS < 1 || BURST_MAX_BEATS > 256 ||
            FIFO_DEPTH < BURST_MAX_BEATS || WRITE_OUTSTANDING < 1 ||
            WRITE_OUTSTANDING > DESCRIPTOR_DEPTH ||
            DESCRIPTOR_DEPTH < 1)
            $error("multi_channel_video_dma parameters are invalid");
    end

    always @(posedge channels[0].aclk) begin
        if (!channels[0].aresetn) begin
            planner_state <= PLAN_IDLE;
            planner_channel <= {CHANNEL_WIDTH{1'b0}};
            round_robin_last <= CHANNEL_WIDTH'(CHANNELS-1);
            planner_line_addr <= 32'd0;
            planner_addr <= 32'd0;
            planner_beats <= 9'd0;
            planner_line <= 16'd0;
            planner_word <= 16'd0;
            planner_finishes_line <= 1'b0;
            planner_finishes_frame <= 1'b0;
            alloc_ptr <= {DESC_PTR_WIDTH{1'b0}};
            aw_ptr <= {DESC_PTR_WIDTH{1'b0}};
            w_ptr <= {DESC_PTR_WIDTH{1'b0}};
            b_ptr <= {DESC_PTR_WIDTH{1'b0}};
            desc_count <= {DESC_COUNT_WIDTH{1'b0}};
            aw_pending_count <= {DESC_COUNT_WIDTH{1'b0}};
            w_pending_count <= {DESC_COUNT_WIDTH{1'b0}};
            b_pending_count <= {DESC_COUNT_WIDTH{1'b0}};
            w_desc_valid <= 1'b0;
            w_channel_q <= {CHANNEL_WIDTH{1'b0}};
            w_beats_q <= 9'd0;
            w_line_q <= 16'd0;
            w_word_q <= 16'd0;
            w_beat_index <= 9'd0;
            frame_done <= {CHANNELS{1'b0}};
            frame_error <= {CHANNELS{1'b0}};
            perf_outstanding_current <= 16'd0;
            perf_outstanding_max <= 16'd0;
            perf_aw_stall_cycles <= 32'd0;
            perf_w_stall_cycles <= 32'd0;
            perf_b_stall_cycles <= 32'd0;
            perf_bursts_issued <= 32'd0;
            perf_bursts_completed <= 32'd0;
            perf_response_errors <= 32'd0;
            for (i = 0; i < CHANNELS; i = i + 1) begin
                ctx_active[i] <= 1'b0;
                ctx_drop[i] <= 1'b0;
                ctx_bad[i] <= 1'b0;
                ctx_plan_done[i] <= 1'b0;
                ctx_line_addr[i] <= 32'd0;
                ctx_line[i] <= 16'd0;
                ctx_word[i] <= 16'd0;
                reserved_words[i] <= 16'd0;
                ctx_frame_id[i] <= {FRAME_ID_WIDTH{1'b0}};
            end
        end else begin
            frame_done <= {CHANNELS{1'b0}};
            frame_error <= {CHANNELS{1'b0}};

            // Performance counters observe the functional queue state but do
            // not participate in credit or descriptor control.
            perf_outstanding_current <= 16'(b_pending_count);
            if (perf_outstanding_current > perf_outstanding_max)
                perf_outstanding_max <= perf_outstanding_current;
            if (m_axi.awvalid && !m_axi.awready)
                perf_aw_stall_cycles <= perf_aw_stall_cycles + 1'b1;
            if (m_axi.wvalid && !m_axi.wready)
                perf_w_stall_cycles <= perf_w_stall_cycles + 1'b1;
            if (m_axi.bvalid && !m_axi.bready)
                perf_b_stall_cycles <= perf_b_stall_cycles + 1'b1;
            if (aw_fire)
                perf_bursts_issued <= perf_bursts_issued + 1'b1;
            if (b_fire) begin
                perf_bursts_completed <= perf_bursts_completed + 1'b1;
                if (m_axi.bresp != 2'b00)
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

            if (allocate_fire)
                alloc_ptr <= next_desc_ptr(alloc_ptr);
            if (aw_fire)
                aw_ptr <= next_desc_ptr(aw_ptr);
            if (w_desc_load) begin
                w_desc_valid <= 1'b1;
                w_channel_q <= desc_channel[w_ptr];
                w_beats_q <= desc_beats[w_ptr];
                w_line_q <= desc_line[w_ptr];
                w_word_q <= desc_word[w_ptr];
            end
            if (w_last_fire) begin
                w_ptr <= next_desc_ptr(w_ptr);
                w_desc_valid <= 1'b0;
                w_beat_index <= 9'd0;
            end else if (w_fire) begin
                w_beat_index <= w_beat_index + 1'b1;
            end
            if (b_fire)
                b_ptr <= next_desc_ptr(b_ptr);

            for (i = 0; i < CHANNELS; i = i + 1) begin
                if (buffer_grant[i] && buffer_acquire[i]) begin
                    ctx_active[i] <= 1'b1;
                    ctx_drop[i] <= 1'b0;
                    ctx_bad[i] <= fifo_error_bit[i];
                    ctx_plan_done[i] <= 1'b0;
                    ctx_line_addr[i] <= buffer_base[i*32 +: 32];
                    ctx_line[i] <= 16'd0;
                    ctx_word[i] <= 16'd0;
                    reserved_words[i] <= 16'd0;
                    ctx_frame_id[i] <= fifo_frame_id[i];
                end else if (buffer_drop[i] && buffer_acquire[i]) begin
                    ctx_drop[i] <= 1'b1;
                end

                if (fifo_rd_en[i] && ctx_drop[i] && fifo_eof[i])
                    ctx_drop[i] <= 1'b0;

                case ({allocate_fire &&
                       (planner_channel == CHANNEL_WIDTH'(i)),
                       w_fire && (w_channel == CHANNEL_WIDTH'(i))})
                    2'b10: reserved_words[i] <=
                        reserved_words[i] + planner_beats;
                    2'b01: reserved_words[i] <= reserved_words[i] - 1'b1;
                    2'b11: reserved_words[i] <=
                        reserved_words[i] + planner_beats - 1'b1;
                    default: ;
                endcase
            end

            if (w_data_error)
                ctx_bad[w_channel] <= 1'b1;

            if (b_fire) begin
                if (m_axi.bresp != 2'b00)
                    ctx_bad[b_channel] <= 1'b1;
                if (desc_finishes_frame[b_ptr]) begin
                    if (ctx_bad[b_channel] || (m_axi.bresp != 2'b00) ||
                        (w_data_error && (w_channel == b_channel)))
                        frame_error[b_channel] <= 1'b1;
                    else
                        frame_done[b_channel] <= 1'b1;
                    ctx_active[b_channel] <= 1'b0;
                    ctx_plan_done[b_channel] <= 1'b0;
                    ctx_word[b_channel] <= 16'd0;
                    ctx_line[b_channel] <= 16'd0;
                    reserved_words[b_channel] <= 16'd0;
                end
            end

            case (planner_state)
                PLAN_IDLE: begin
                    if (round_robin_last == CHANNEL_WIDTH'(CHANNELS-1))
                        planner_channel <= {CHANNEL_WIDTH{1'b0}};
                    else
                        planner_channel <= round_robin_last + 1'b1;
                    if (round_robin_last == CHANNEL_WIDTH'(CHANNELS-1))
                        round_robin_last <= {CHANNEL_WIDTH{1'b0}};
                    else
                        round_robin_last <= round_robin_last + 1'b1;
                    planner_state <= PLAN_CAPTURE;
                end
                PLAN_CAPTURE: begin
                    if (ctx_active[planner_channel] &&
                        !ctx_drop[planner_channel] &&
                        !ctx_plan_done[planner_channel]) begin
                        planner_line_addr <= ctx_line_addr[planner_channel];
                        planner_line <= ctx_line[planner_channel];
                        planner_word <= ctx_word[planner_channel];
                        planner_state <= PLAN_SIZE;
                    end else begin
                        planner_state <= PLAN_IDLE;
                    end
                end
                PLAN_SIZE: begin
                    if ((WORDS_PER_LINE - planner_word) > BURST_MAX_BEATS)
                        planner_beats <= 9'(BURST_MAX_BEATS);
                    else
                        planner_beats <=
                            9'(WORDS_PER_LINE - planner_word);
                    planner_state <= PLAN_DATA_CREDIT;
                end
                PLAN_DATA_CREDIT: begin
                    if ((planner_beats != 0) &&
                        (fifo_count[planner_channel] >=
                         reserved_words[planner_channel] + planner_beats)) begin
                        planner_state <= PLAN_ADDRESS;
                    end else begin
                        planner_state <= PLAN_IDLE;
                    end
                end
                PLAN_ADDRESS: begin
                    planner_addr <= planner_line_addr +
                                    {planner_word, 5'b0};
                    planner_state <= PLAN_BOUNDARY;
                end
                PLAN_BOUNDARY: begin
                    if (planner_beats >
                        (9'd128 - {2'b00, planner_addr[11:5]}))
                        planner_beats <=
                            9'd128 - {2'b00, planner_addr[11:5]};
                    planner_state <= PLAN_FLAGS;
                end
                PLAN_FLAGS: begin
                    planner_finishes_line <=
                        (planner_word + planner_beats == WORDS_PER_LINE);
                    planner_finishes_frame <=
                        (planner_word + planner_beats == WORDS_PER_LINE) &&
                        (planner_line == FRAME_HEIGHT-1);
                    planner_state <= PLAN_ENQUEUE;
                end
                PLAN_ENQUEUE: begin
                    if (descriptor_space) begin
                        desc_addr[alloc_ptr] <= planner_addr;
                        desc_beats[alloc_ptr] <= planner_beats;
                        desc_channel[alloc_ptr] <= planner_channel;
                        desc_line[alloc_ptr] <= planner_line;
                        desc_word[alloc_ptr] <= planner_word;
                        desc_finishes_frame[alloc_ptr] <=
                            planner_finishes_frame;
                        if (planner_finishes_frame) begin
                            ctx_plan_done[planner_channel] <= 1'b1;
                        end else if (planner_finishes_line) begin
                            ctx_word[planner_channel] <= 16'd0;
                            ctx_line[planner_channel] <=
                                ctx_line[planner_channel] + 1'b1;
                            ctx_line_addr[planner_channel] <=
                                ctx_line_addr[planner_channel] +
                                FRAME_STRIDE_BYTES;
                        end else begin
                            ctx_word[planner_channel] <=
                                ctx_word[planner_channel] + planner_beats;
                        end
                        planner_state <= PLAN_IDLE;
                    end
                end
                default: planner_state <= PLAN_IDLE;
            endcase
        end
    end

    wire unused = &{1'b0, fifo_full[0], m_axi.bid, m_axi.rid,
                    m_axi.rdata, m_axi.rresp, m_axi.rlast, m_axi.rvalid};
endmodule
