`timescale 1ns/1ps

// Builds a 3x3 1080p mosaic from eight native 640x480 frame buffers.  Tiles
// preserve all 640 horizontal pixels and reduce 480 lines to 360 with a 4:3
// nearest-neighbor mapping.  The unused bottom-right tile is black.
module mosaic_frame_reader #(
    parameter integer CHANNELS = 8,
    parameter integer SOURCE_WIDTH = 640,
    parameter integer SOURCE_HEIGHT = 480,
    parameter integer SOURCE_STRIDE_BYTES = SOURCE_WIDTH * 4,
    parameter integer BURST_MAX_BEATS = 64,
    parameter integer READ_OUTSTANDING = 8,
    parameter integer DESCRIPTOR_DEPTH = 8,
    parameter integer READ_FIFO_DEPTH = 512,
    parameter integer FIFO_SAFETY_MARGIN = 8
) (
    input  wire                     clk,
    input  wire                     resetn,
    output wire                     buffer_acquire,
    input  wire                     buffer_grant,
    input  wire [CHANNELS*32-1:0]   buffer_bases,
    input  wire [CHANNELS-1:0]      buffer_valid_mask,
    output reg                      buffer_done,
    axi4_if.master                  m_axi,
    axis_video_if.source            m_axis,
    output reg                      axi_error,
    output reg                      fifo_underflow,
    output wire [31:0]              debug_status
);
    localparam integer TILE_WIDTH = 640;
    localparam integer TILE_HEIGHT = 360;
    localparam integer OUTPUT_WIDTH = 1920;
    localparam integer OUTPUT_HEIGHT = 1080;
    localparam integer OUTPUT_BEATS = OUTPUT_WIDTH / 2;
    localparam integer TILE_BEATS = TILE_WIDTH / 2;
    localparam integer LINE_DDR_BEATS = SOURCE_WIDTH / 8;
    localparam integer READ_FIFO_COUNT_WIDTH = $clog2(READ_FIFO_DEPTH) + 1;
    localparam integer CREDIT_COUNT_WIDTH = READ_FIFO_COUNT_WIDTH + 1;
    localparam integer DESC_PTR_WIDTH = (DESCRIPTOR_DEPTH <= 1) ?
                                        1 : $clog2(DESCRIPTOR_DEPTH);
    localparam integer DESC_COUNT_WIDTH = $clog2(DESCRIPTOR_DEPTH + 1);
    localparam [DESC_COUNT_WIDTH-1:0] DESC_DEPTH_VALUE =
        DESC_COUNT_WIDTH'(DESCRIPTOR_DEPTH);
    localparam [DESC_COUNT_WIDTH-1:0] READ_CREDIT_VALUE =
        DESC_COUNT_WIDTH'(READ_OUTSTANDING);

    localparam [1:0] BANK_FREE = 2'd0;
    localparam [1:0] BANK_FILL = 2'd1;
    localparam [1:0] BANK_READY = 2'd2;
    localparam [1:0] BANK_DISPLAY = 2'd3;

    localparam [2:0] F_IDLE = 3'd0;
    localparam [2:0] F_TILE = 3'd1;
    localparam [2:0] F_READ = 3'd2;
    localparam [2:0] F_PROCESS = 3'd3;
    localparam [2:0] F_TILE_DONE = 3'd4;
    localparam [2:0] F_LINE_DONE = 3'd5;

    localparam integer LINE_BANK_DEPTH = TILE_BEATS / 4;
    // A 256-bit DDR word contains four RGB pixel pairs. Packing those pairs
    // into one line entry lets the fill engine sustain one DDR beat/clock.
    (* ram_style = "distributed" *) reg [191:0] line_b0_t0 [0:LINE_BANK_DEPTH-1];
    (* ram_style = "distributed" *) reg [191:0] line_b0_t1 [0:LINE_BANK_DEPTH-1];
    (* ram_style = "distributed" *) reg [191:0] line_b0_t2 [0:LINE_BANK_DEPTH-1];
    (* ram_style = "distributed" *) reg [191:0] line_b1_t0 [0:LINE_BANK_DEPTH-1];
    (* ram_style = "distributed" *) reg [191:0] line_b1_t1 [0:LINE_BANK_DEPTH-1];
    (* ram_style = "distributed" *) reg [191:0] line_b1_t2 [0:LINE_BANK_DEPTH-1];
    reg [1:0] bank_state [0:1];
    reg [10:0] bank_line [0:1];

    reg frame_active;
    reg [CHANNELS*32-1:0] frame_bases;
    reg [CHANNELS-1:0] frame_valid_mask;
    reg [10:0] next_fill_line;

    reg [2:0] fill_state;
    reg fill_bank;
    reg [1:0] fill_tile_row;
    reg [1:0] fill_tile;
    reg [10:0] fill_source_y;
    reg [10:0] next_source_y;
    reg [1:0] source_y_phase;
    reg fill_channel_valid;
    reg [31:0] read_addr;
    reg [8:0] issue_beat;
    reg [8:0] line_beat;
    reg plan_valid;
    reg plan_approved;
    reg [31:0] plan_addr_q;
    reg [8:0] plan_beats_q;
    reg ar_pending;
    reg [31:0] ar_addr_q;
    reg [8:0] ar_beats_q;

    reg [8:0] desc_beats [0:DESCRIPTOR_DEPTH-1];
    reg [DESC_PTR_WIDTH-1:0] desc_alloc_ptr;
    reg [DESC_PTR_WIDTH-1:0] desc_return_ptr;
    reg [DESC_COUNT_WIDTH-1:0] desc_count;
    reg [8:0] return_beat_index;
    reg [CREDIT_COUNT_WIDTH-1:0] reserved_return_beats;

    wire [255:0] read_fifo_dout;
    wire read_fifo_full;
    wire read_fifo_empty;
    wire [READ_FIFO_COUNT_WIDTH-1:0] read_fifo_count;
    wire read_fifo_read;

    reg [255:0] source_word;
    reg [8:0] pair_write_index;

    reg output_active;
    reg display_bank;
    reg [9:0] output_x;
    reg [10:0] output_y;
    reg axis_valid_q;
    reg [47:0] axis_data_q;
    reg axis_user_q;
    reg axis_last_q;
    reg axis_frame_last_q;

    wire axis_pipeline_ready = !axis_valid_q || m_axis.tready;
    wire axis_fire = axis_valid_q && m_axis.tready;
    wire source_fire = output_active && axis_pipeline_ready;
    wire [1:0] output_tile = (output_x < TILE_BEATS) ? 2'd0 :
                             (output_x < TILE_BEATS*2) ? 2'd1 : 2'd2;
    wire [8:0] output_tile_x = (output_tile == 2'd0) ? output_x[8:0] :
                               (output_tile == 2'd1) ?
                                   output_x - TILE_BEATS :
                                   output_x - TILE_BEATS*2;
    wire [6:0] output_tile_addr = output_tile_x[8:2];
    wire [2:0] output_channel = (output_y < TILE_HEIGHT) ?
                                {1'b0, output_tile} :
                                (output_y < TILE_HEIGHT*2) ?
                                    (3'd3 + output_tile) :
                                    (output_tile == 2'd2 ? 3'd0 :
                                     3'd6 + output_tile);
    wire output_layout_valid = (output_y < TILE_HEIGHT*2) ||
                               (output_tile != 2'd2);
    wire output_source_valid = output_layout_valid &&
                               frame_valid_mask[output_channel];
    reg [47:0] mosaic_pixels;

    always @* begin
        case ({display_bank, output_tile})
            3'b000: mosaic_pixels = line_b0_t0[output_tile_addr]
                                      [output_tile_x[1:0]*48 +: 48];
            3'b001: mosaic_pixels = line_b0_t1[output_tile_addr]
                                      [output_tile_x[1:0]*48 +: 48];
            3'b010: mosaic_pixels = line_b0_t2[output_tile_addr]
                                      [output_tile_x[1:0]*48 +: 48];
            3'b100: mosaic_pixels = line_b1_t0[output_tile_addr]
                                      [output_tile_x[1:0]*48 +: 48];
            3'b101: mosaic_pixels = line_b1_t1[output_tile_addr]
                                      [output_tile_x[1:0]*48 +: 48];
            default: mosaic_pixels = line_b1_t2[output_tile_addr]
                                      [output_tile_x[1:0]*48 +: 48];
        endcase
    end

    wire [47:0] source_pixels0 = {source_word[32 +: 24], source_word[0 +: 24]};
    wire [47:0] source_pixels1 = {source_word[96 +: 24], source_word[64 +: 24]};
    wire [47:0] source_pixels2 = {source_word[160 +: 24], source_word[128 +: 24]};
    wire [47:0] source_pixels3 = {source_word[224 +: 24], source_word[192 +: 24]};

    wire tile_read_active = fill_channel_valid &&
                            ((fill_state == F_READ) ||
                             (fill_state == F_PROCESS));
    wire [8:0] issue_beats_left = LINE_DDR_BEATS - issue_beat;
    wire [8:0] beats_to_4k = 9'd128 - {2'b00, read_addr[11:5]};
    wire [8:0] burst_limited = (issue_beats_left > BURST_MAX_BEATS) ?
                               9'(BURST_MAX_BEATS) : issue_beats_left;
    wire [8:0] planned_beats = (burst_limited > beats_to_4k) ?
                               beats_to_4k : burst_limited;
    // Keep the credit arithmetic narrow.  It is evaluated after the burst
    // length has been registered, breaking the old issue_beat -> burst min ->
    // 4 KiB min -> FIFO credit -> AR register-enable combinational chain.
    wire [CREDIT_COUNT_WIDTH-1:0] fifo_committed_beats =
        CREDIT_COUNT_WIDTH'(read_fifo_count) + reserved_return_beats;
    wire [CREDIT_COUNT_WIDTH-1:0] planned_fifo_commit =
        fifo_committed_beats + CREDIT_COUNT_WIDTH'(plan_beats_q) +
        CREDIT_COUNT_WIDTH'(FIFO_SAFETY_MARGIN);
    wire fifo_credit_available =
        (planned_fifo_commit <= CREDIT_COUNT_WIDTH'(READ_FIFO_DEPTH));

    wire ar_fire = m_axi.arvalid && m_axi.arready;
    wire r_fire = m_axi.rvalid && m_axi.rready;
    wire r_last_fire = r_fire && m_axi.rlast;
    wire descriptor_credit_available =
        (desc_count < DESC_DEPTH_VALUE || r_last_fire) &&
        (desc_count < READ_CREDIT_VALUE || r_last_fire);
    wire expected_r_last = (desc_count != 0) &&
        (return_beat_index == desc_beats[desc_return_ptr]-1'b1);
    wire read_protocol_error = r_fire &&
        ((m_axi.rid != 0) || (m_axi.rlast != expected_r_last));

    function automatic [DESC_PTR_WIDTH-1:0] next_desc_ptr;
        input [DESC_PTR_WIDTH-1:0] pointer;
        begin
            if (pointer == DESC_PTR_WIDTH'(DESCRIPTOR_DEPTH-1))
                next_desc_ptr = {DESC_PTR_WIDTH{1'b0}};
            else
                next_desc_ptr = pointer + 1'b1;
        end
    endfunction

    assign buffer_acquire = !frame_active && !output_active && !axis_valid_q &&
                            (fill_state == F_IDLE) && !plan_valid &&
                            !plan_approved && !ar_pending &&
                            (desc_count == 0) && read_fifo_empty;

    assign m_axis.aclk = clk;
    assign m_axis.aresetn = resetn;
    // The registered source stage breaks the distributed line-store lookup and
    // tile-selection path before the display-reader mux and HDMI AXIS slice.
    // It is a one-entry elastic buffer: all fields remain stable under
    // downstream backpressure and the source advances only when this stage can
    // accept a new beat.
    assign m_axis.tvalid = axis_valid_q;
    assign m_axis.tdata = axis_data_q;
    assign m_axis.tuser = axis_user_q;
    assign m_axis.tlast = axis_last_q;

    assign m_axi.aclk = clk;
    assign m_axi.aresetn = resetn;
    assign m_axi.awid = 3'd0;
    assign m_axi.awaddr = 32'd0;
    assign m_axi.awlen = 8'd0;
    assign m_axi.awsize = 3'b101;
    assign m_axi.awburst = 2'b01;
    assign m_axi.awlock = 1'b0;
    assign m_axi.awcache = 4'd0;
    assign m_axi.awprot = 3'd0;
    assign m_axi.awqos = 4'd0;
    assign m_axi.awvalid = 1'b0;
    assign m_axi.wdata = 256'd0;
    assign m_axi.wstrb = 32'd0;
    assign m_axi.wlast = 1'b0;
    assign m_axi.wvalid = 1'b0;
    assign m_axi.bready = 1'b0;
    assign m_axi.arid = 3'd0;
    assign m_axi.araddr = ar_addr_q;
    assign m_axi.arlen = ar_beats_q[7:0] - 1'b1;
    assign m_axi.arsize = 3'b101;
    assign m_axi.arburst = 2'b01;
    assign m_axi.arlock = 1'b0;
    assign m_axi.arcache = 4'b0011;
    assign m_axi.arprot = 3'd0;
    assign m_axi.arqos = 4'hf;
    assign m_axi.arvalid = ar_pending;
    assign m_axi.rready = (desc_count != 0) && !read_fifo_full;

    assign debug_status = {1'b0, axi_error, fifo_underflow, frame_active,
                           output_active, fill_state, bank_state[1],
                           bank_state[0], output_y[9:0], output_x[9:0]};

`ifdef VERILATOR
    reg [255:0] sim_read_fifo [0:READ_FIFO_DEPTH-1];
    reg [$clog2(READ_FIFO_DEPTH)-1:0] sim_read_wr_ptr;
    reg [$clog2(READ_FIFO_DEPTH)-1:0] sim_read_rd_ptr;
    reg [READ_FIFO_COUNT_WIDTH-1:0] sim_read_count;
    assign read_fifo_dout = sim_read_fifo[sim_read_rd_ptr];
    assign read_fifo_full =
        (sim_read_count == READ_FIFO_COUNT_WIDTH'(READ_FIFO_DEPTH));
    assign read_fifo_empty = (sim_read_count == 0);
    assign read_fifo_count = sim_read_count;
    always @(posedge clk) begin
        if (!resetn) begin
            sim_read_wr_ptr <= 0;
            sim_read_rd_ptr <= 0;
            sim_read_count <= 0;
        end else begin
            if (r_fire) begin
                sim_read_fifo[sim_read_wr_ptr] <= m_axi.rdata;
                sim_read_wr_ptr <= sim_read_wr_ptr + 1'b1;
            end
            if (read_fifo_read)
                sim_read_rd_ptr <= sim_read_rd_ptr + 1'b1;
            case ({r_fire, read_fifo_read})
                2'b10: sim_read_count <= sim_read_count + 1'b1;
                2'b01: sim_read_count <= sim_read_count - 1'b1;
                default: ;
            endcase
        end
    end
`else
    xpm_fifo_sync #(
        .FIFO_MEMORY_TYPE("block"), .ECC_MODE("no_ecc"),
        .FIFO_WRITE_DEPTH(READ_FIFO_DEPTH), .WRITE_DATA_WIDTH(256),
        .READ_DATA_WIDTH(256), .READ_MODE("fwft"), .FIFO_READ_LATENCY(0),
        .PROG_FULL_THRESH(
            READ_FIFO_DEPTH-BURST_MAX_BEATS-FIFO_SAFETY_MARGIN),
        .WR_DATA_COUNT_WIDTH(READ_FIFO_COUNT_WIDTH),
        .RD_DATA_COUNT_WIDTH(READ_FIFO_COUNT_WIDTH), .DOUT_RESET_VALUE("0"),
        .FULL_RESET_VALUE(0), .USE_ADV_FEATURES("0707"), .WAKEUP_TIME(0)
    ) u_axi_read_fifo (
        .sleep(1'b0), .rst(!resetn), .wr_clk(clk),
        .wr_en(r_fire), .din(m_axi.rdata),
        .full(read_fifo_full), .prog_full(),
        .wr_data_count(read_fifo_count), .overflow(), .wr_ack(),
        .almost_full(), .wr_rst_busy(), .injectsbiterr(1'b0),
        .injectdbiterr(1'b0), .sbiterr(), .dbiterr(),
        .rd_en(read_fifo_read), .dout(read_fifo_dout),
        .empty(read_fifo_empty), .rd_data_count(), .underflow(),
        .data_valid(), .almost_empty(), .prog_empty(), .rd_rst_busy()
    );
`endif
    assign read_fifo_read = (fill_state == F_READ) && !read_fifo_empty;

    initial begin
        if (CHANNELS != 8 || SOURCE_WIDTH != 640 || SOURCE_HEIGHT != 480 ||
            SOURCE_STRIDE_BYTES < SOURCE_WIDTH*4 ||
            LINE_DDR_BEATS != 80 || TILE_BEATS != 320 ||
            BURST_MAX_BEATS < 1 || BURST_MAX_BEATS > 128 ||
            READ_OUTSTANDING < 1 ||
            READ_OUTSTANDING > DESCRIPTOR_DEPTH ||
            DESCRIPTOR_DEPTH < 1 ||
            (READ_FIFO_DEPTH & (READ_FIFO_DEPTH-1)) != 0 ||
            READ_FIFO_DEPTH < BURST_MAX_BEATS+FIFO_SAFETY_MARGIN)
            $error("mosaic_frame_reader parameters are invalid");
    end

    always @(posedge clk) begin
        if (!resetn) begin
            frame_active <= 1'b0;
            frame_bases <= {CHANNELS*32{1'b0}};
            frame_valid_mask <= {CHANNELS{1'b0}};
            next_fill_line <= 11'd0;
            fill_state <= F_IDLE;
            fill_bank <= 1'b0;
            fill_tile_row <= 2'd0;
            fill_tile <= 2'd0;
            fill_source_y <= 11'd0;
            next_source_y <= 11'd0;
            source_y_phase <= 2'd0;
            fill_channel_valid <= 1'b0;
            read_addr <= 32'd0;
            issue_beat <= 9'd0;
            line_beat <= 9'd0;
            plan_valid <= 1'b0;
            plan_approved <= 1'b0;
            plan_addr_q <= 32'd0;
            plan_beats_q <= 9'd0;
            ar_pending <= 1'b0;
            ar_addr_q <= 32'd0;
            ar_beats_q <= 9'd0;
            desc_alloc_ptr <= {DESC_PTR_WIDTH{1'b0}};
            desc_return_ptr <= {DESC_PTR_WIDTH{1'b0}};
            desc_count <= {DESC_COUNT_WIDTH{1'b0}};
            return_beat_index <= 9'd0;
            reserved_return_beats <= {CREDIT_COUNT_WIDTH{1'b0}};
            source_word <= 256'd0;
            pair_write_index <= 9'd0;
            output_active <= 1'b0;
            display_bank <= 1'b0;
            output_x <= 10'd0;
            output_y <= 11'd0;
            axis_valid_q <= 1'b0;
            axis_data_q <= 48'd0;
            axis_user_q <= 1'b0;
            axis_last_q <= 1'b0;
            axis_frame_last_q <= 1'b0;
            buffer_done <= 1'b0;
            axi_error <= 1'b0;
            fifo_underflow <= 1'b0;
            bank_state[0] <= BANK_FREE;
            bank_state[1] <= BANK_FREE;
            bank_line[0] <= 11'd0;
            bank_line[1] <= 11'd0;
        end else begin
            buffer_done <= 1'b0;
            fifo_underflow <= 1'b0;

            if (axis_pipeline_ready) begin
                axis_valid_q <= output_active;
                if (output_active) begin
                    axis_data_q <= output_source_valid ? mosaic_pixels : 48'd0;
                    axis_user_q <= (output_x == 0) && (output_y == 0);
                    axis_last_q <= (output_x == OUTPUT_BEATS-1);
                    axis_frame_last_q <=
                        (output_x == OUTPUT_BEATS-1) &&
                        (output_y == OUTPUT_HEIGHT-1);
                end else begin
                    axis_user_q <= 1'b0;
                    axis_last_q <= 1'b0;
                    axis_frame_last_q <= 1'b0;
                end
            end

            // A buffer is complete only after the downstream accepts the
            // registered final beat.  Completing when the source merely loads
            // that beat makes ownership advance one cycle too early and can
            // drop the bottom-right pixel pair under backpressure.
            if (axis_fire && axis_frame_last_q) begin
                frame_active <= 1'b0;
                buffer_done <= 1'b1;
            end

            if (buffer_grant && buffer_acquire) begin
                frame_active <= 1'b1;
                frame_bases <= buffer_bases;
                frame_valid_mask <= buffer_valid_mask;
                next_fill_line <= 11'd0;
                next_source_y <= 11'd0;
                source_y_phase <= 2'd0;
                output_active <= 1'b0;
                output_x <= 10'd0;
                output_y <= 11'd0;
                fill_state <= F_IDLE;
                bank_state[0] <= BANK_FREE;
                bank_state[1] <= BANK_FREE;
                plan_valid <= 1'b0;
                plan_approved <= 1'b0;
                reserved_return_beats <= {CREDIT_COUNT_WIDTH{1'b0}};
                axi_error <= 1'b0;
            end

            // Stage 1: calculate and hold the next legal line/4 KiB-limited
            // burst. read_addr and issue_beat cannot advance until AR fires,
            // so the snapshot remains valid while later stages wait.
            if (!plan_valid && !plan_approved && !ar_pending &&
                tile_read_active && (issue_beat < LINE_DDR_BEATS)) begin
                plan_valid <= 1'b1;
                plan_addr_q <= read_addr;
                plan_beats_q <= planned_beats;
            end

            // Stage 2: wait for both descriptor and FIFO capacity. With no AR
            // pending, committed capacity cannot get worse before stage 3;
            // returning/draining data can only preserve or increase credit.
            if (plan_valid && !plan_approved &&
                descriptor_credit_available && fifo_credit_available)
                plan_approved <= 1'b1;

            // Stage 3: present the registered request to AXI. The AXI address
            // and length registers remain unchanged throughout backpressure.
            if (plan_valid && plan_approved && !ar_pending) begin
                ar_pending <= 1'b1;
                ar_addr_q <= plan_addr_q;
                ar_beats_q <= plan_beats_q;
                plan_valid <= 1'b0;
                plan_approved <= 1'b0;
            end
            if (ar_fire) begin
                ar_pending <= 1'b0;
                desc_beats[desc_alloc_ptr] <= ar_beats_q;
                desc_alloc_ptr <= next_desc_ptr(desc_alloc_ptr);
                issue_beat <= issue_beat + ar_beats_q;
                read_addr <= read_addr + {18'd0, ar_beats_q, 5'b0};
            end

            case ({ar_fire, r_last_fire})
                2'b10: desc_count <= desc_count + 1'b1;
                2'b01: desc_count <= desc_count - 1'b1;
                default: ;
            endcase
            case ({ar_fire, r_fire})
                2'b10: reserved_return_beats <=
                    reserved_return_beats + ar_beats_q;
                2'b01: if (reserved_return_beats != 0)
                    reserved_return_beats <= reserved_return_beats - 1'b1;
                2'b11: reserved_return_beats <=
                    reserved_return_beats + ar_beats_q - 1'b1;
                default: ;
            endcase

            if (r_last_fire) begin
                desc_return_ptr <= next_desc_ptr(desc_return_ptr);
                return_beat_index <= 9'd0;
            end else if (r_fire) begin
                return_beat_index <= return_beat_index + 1'b1;
            end
            if (read_protocol_error ||
                (r_fire && (m_axi.rresp != 2'b00)))
                axi_error <= 1'b1;

            case (fill_state)
                F_IDLE: begin
                    if (frame_active && (next_fill_line < OUTPUT_HEIGHT)) begin
                        if (bank_state[0] == BANK_FREE) begin
                            fill_bank <= 1'b0;
                            bank_state[0] <= BANK_FILL;
                            bank_line[0] <= next_fill_line;
                            fill_source_y <= next_source_y;
                            if (next_fill_line < TILE_HEIGHT) begin
                                fill_tile_row <= 2'd0;
                            end else if (next_fill_line < TILE_HEIGHT*2) begin
                                fill_tile_row <= 2'd1;
                            end else begin
                                fill_tile_row <= 2'd2;
                            end
                            // floor(line*4/3) advances by 1, 1, then 2.
                            // Reset at each 360-line tile-row boundary.
                            if ((next_fill_line == TILE_HEIGHT-1) ||
                                (next_fill_line == TILE_HEIGHT*2-1)) begin
                                next_source_y <= 11'd0;
                                source_y_phase <= 2'd0;
                            end else begin
                                next_source_y <= next_source_y +
                                    ((source_y_phase == 2'd2) ? 11'd2 : 11'd1);
                                source_y_phase <= (source_y_phase == 2'd2) ?
                                                  2'd0 : source_y_phase + 1'b1;
                            end
                            fill_tile <= 2'd0;
                            next_fill_line <= next_fill_line + 1'b1;
                            fill_state <= F_TILE;
                        end else if (bank_state[1] == BANK_FREE) begin
                            fill_bank <= 1'b1;
                            bank_state[1] <= BANK_FILL;
                            bank_line[1] <= next_fill_line;
                            fill_source_y <= next_source_y;
                            if (next_fill_line < TILE_HEIGHT) begin
                                fill_tile_row <= 2'd0;
                            end else if (next_fill_line < TILE_HEIGHT*2) begin
                                fill_tile_row <= 2'd1;
                            end else begin
                                fill_tile_row <= 2'd2;
                            end
                            if ((next_fill_line == TILE_HEIGHT-1) ||
                                (next_fill_line == TILE_HEIGHT*2-1)) begin
                                next_source_y <= 11'd0;
                                source_y_phase <= 2'd0;
                            end else begin
                                next_source_y <= next_source_y +
                                    ((source_y_phase == 2'd2) ? 11'd2 : 11'd1);
                                source_y_phase <= (source_y_phase == 2'd2) ?
                                                  2'd0 : source_y_phase + 1'b1;
                            end
                            fill_tile <= 2'd0;
                            next_fill_line <= next_fill_line + 1'b1;
                            fill_state <= F_TILE;
                        end
                    end
                end

                F_TILE: begin
                    issue_beat <= 9'd0;
                    line_beat <= 9'd0;
                    pair_write_index <= 9'd0;
                    plan_valid <= 1'b0;
                    plan_approved <= 1'b0;
                    if ((fill_tile_row == 2'd2) && (fill_tile == 2'd2)) begin
                        fill_channel_valid <= 1'b0;
                        fill_state <= F_TILE_DONE;
                    end else if ((fill_tile_row == 2'd0 &&
                                  frame_valid_mask[{1'b0, fill_tile}]) ||
                                 (fill_tile_row == 2'd1 &&
                                  frame_valid_mask[3'd3 + fill_tile]) ||
                                 (fill_tile_row == 2'd2 &&
                                  fill_tile != 2'd2 &&
                                  frame_valid_mask[3'd6 + fill_tile])) begin
                        fill_channel_valid <= 1'b1;
                        if (fill_tile_row == 2'd0)
                            read_addr <= frame_bases[
                                ({1'b0, fill_tile})*32 +: 32] +
                                fill_source_y * SOURCE_STRIDE_BYTES;
                        else if (fill_tile_row == 2'd1)
                            read_addr <= frame_bases[
                                (3'd3 + fill_tile)*32 +: 32] +
                                fill_source_y * SOURCE_STRIDE_BYTES;
                        else
                            read_addr <= frame_bases[
                                (3'd6 + fill_tile)*32 +: 32] +
                                fill_source_y * SOURCE_STRIDE_BYTES;
                        fill_state <= F_READ;
                    end else begin
                        fill_channel_valid <= 1'b0;
                        fill_state <= F_TILE_DONE;
                    end
                end

                F_READ: begin
                    if (!read_fifo_empty) begin
                        source_word <= read_fifo_dout;
                        fill_state <= F_PROCESS;
                    end
                end

                F_PROCESS: begin
                    case ({fill_bank, fill_tile})
                        3'b000: line_b0_t0[pair_write_index[8:2]] <=
                            {source_pixels3, source_pixels2,
                             source_pixels1, source_pixels0};
                        3'b001: line_b0_t1[pair_write_index[8:2]] <=
                            {source_pixels3, source_pixels2,
                             source_pixels1, source_pixels0};
                        3'b010: line_b0_t2[pair_write_index[8:2]] <=
                            {source_pixels3, source_pixels2,
                             source_pixels1, source_pixels0};
                        3'b100: line_b1_t0[pair_write_index[8:2]] <=
                            {source_pixels3, source_pixels2,
                             source_pixels1, source_pixels0};
                        3'b101: line_b1_t1[pair_write_index[8:2]] <=
                            {source_pixels3, source_pixels2,
                             source_pixels1, source_pixels0};
                        default: line_b1_t2[pair_write_index[8:2]] <=
                            {source_pixels3, source_pixels2,
                             source_pixels1, source_pixels0};
                    endcase
                    pair_write_index <= pair_write_index + 9'd4;

                    if (line_beat == LINE_DDR_BEATS-1) begin
                        fill_state <= F_TILE_DONE;
                    end else begin
                        line_beat <= line_beat + 1'b1;
                        fill_state <= F_READ;
                    end
                end

                F_TILE_DONE: begin
                    if (fill_channel_valid &&
                        (pair_write_index != TILE_BEATS ||
                         issue_beat != LINE_DDR_BEATS || desc_count != 0 ||
                         plan_valid || plan_approved || ar_pending ||
                         !read_fifo_empty))
                        axi_error <= 1'b1;
                    if (fill_tile == 2'd2)
                        fill_state <= F_LINE_DONE;
                    else begin
                        fill_tile <= fill_tile + 1'b1;
                        fill_state <= F_TILE;
                    end
                end

                F_LINE_DONE: begin
                    bank_state[fill_bank] <= BANK_READY;
                    fill_state <= F_IDLE;
                end

                default: fill_state <= F_IDLE;
            endcase

            if (!output_active && frame_active) begin
                if ((bank_state[0] == BANK_READY) &&
                    (bank_line[0] == output_y)) begin
                    bank_state[0] <= BANK_DISPLAY;
                    display_bank <= 1'b0;
                    output_active <= 1'b1;
                end else if ((bank_state[1] == BANK_READY) &&
                             (bank_line[1] == output_y)) begin
                    bank_state[1] <= BANK_DISPLAY;
                    display_bank <= 1'b1;
                    output_active <= 1'b1;
                end
            end

            if (source_fire) begin
                if (output_x == OUTPUT_BEATS-1) begin
                    output_x <= 10'd0;
                    bank_state[display_bank] <= BANK_FREE;
                    if (output_y == OUTPUT_HEIGHT-1) begin
                        output_y <= 11'd0;
                        output_active <= 1'b0;
                    end else begin
                        output_y <= output_y + 1'b1;
                        if ((bank_state[!display_bank] == BANK_READY) &&
                            (bank_line[!display_bank] == output_y + 1'b1)) begin
                            bank_state[!display_bank] <= BANK_DISPLAY;
                            display_bank <= !display_bank;
                        end else begin
                            output_active <= 1'b0;
                            fifo_underflow <= 1'b1;
                        end
                    end
                end else begin
                    output_x <= output_x + 1'b1;
                end
            end
        end
    end

    wire unused = &{1'b0, m_axi.awready, m_axi.wready, m_axi.bid,
                    m_axi.bresp, m_axi.bvalid};
endmodule
