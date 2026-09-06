`timescale 1ns/1ps

// Converts the camera's one-pixel RGB888 stream into the framebuffer's
// two-pixel AXIS format.  In P2 camera_clk and ddr_clk are the same physical
// MIG UI clock; the real capture-to-video CDC is introduced in P3.
module camera_axis_cdc #(
    parameter integer FRAME_WIDTH = 1920,
    parameter integer FIFO_DEPTH = 4096
) (
    input  wire         camera_clk,
    input  wire         camera_resetn,
    input  wire         camera_enable,
    input  wire         pixel_valid,
    output wire         pixel_ready,
    input  wire [23:0]  pixel_data,
    input  wire         frame_start,
    input  wire         line_last,
    input  wire         line_end,
    input  wire         diag_clear_toggle,
    input  wire         ddr_clk,
    input  wire         ddr_resetn,
    output reg  [31:0]  diag_fire_count,
    output reg  [31:0]  diag_sof_count,
    output reg  [31:0]  diag_eol_count,
    output reg  [31:0]  diag_fifo_full_stall_count,
    output reg  [31:0]  diag_ready_low_count,
    output reg  [31:0]  diag_fifo_max_level,
    output reg  [31:0]  diag_line_flush_count,
    axis_video_if.source m_axis
);
    localparam integer COUNT_WIDTH = $clog2(FIFO_DEPTH) + 1;
    localparam integer X_WIDTH = $clog2(FRAME_WIDTH);
    localparam [X_WIDTH-1:0] LAST_PIXEL = X_WIDTH'(FRAME_WIDTH - 1);

    reg [23:0] first_pixel;
    reg        first_user;
    reg        have_first;
    reg [X_WIDTH-1:0] pixel_x;
    reg [49:0] fifo_din;
    reg        fifo_wr_en;
    wire [49:0] fifo_dout;
    wire fifo_full;
    wire fifo_empty;
    wire fifo_wr_rst_busy;
    wire fifo_rd_rst_busy;
    // The P2 implementation is deliberately single-clock.  XPM reset is
    // synchronous to camera_clk and its release is stretched locally.
    reg [3:0] fifo_reset_pipe = 4'hf;
    wire fifo_reset = |fifo_reset_pipe;
    wire [COUNT_WIDTH-1:0] unused_wr_count;
    reg [49:0] output_data_q;
    reg [49:0] output_skid_data_q;
    reg output_valid_q;
    reg output_skid_valid_q;
    // RAM read enable depends only on registered local occupancy.  Remote
    // AXIS ready can consume a prefetched word, but it cannot enter the FIFO
    // BRAM enable cone.
    wire fifo_rd_en = !fifo_empty && !output_skid_valid_q &&
                      !fifo_reset && !fifo_rd_rst_busy;
    wire output_pop = output_valid_q && m_axis.tready && ddr_resetn;
    wire [COUNT_WIDTH-1:0] buffered_level = unused_wr_count +
        COUNT_WIDTH'(output_valid_q) + COUNT_WIDTH'(output_skid_valid_q);
    (* ASYNC_REG = "TRUE", SHREG_EXTRACT = "NO" *) reg diag_clear_sync1;
    (* ASYNC_REG = "TRUE", SHREG_EXTRACT = "NO" *) reg diag_clear_sync2;
    reg diag_clear_seen;
    wire diag_clear = (diag_clear_sync2 != diag_clear_seen);

    // Register the complete camera event before the RGB pair packer.  The
    // recovered pixel_ce in the OV7670 frontend used to feed the packer's
    // payload, control and wide CE cones directly at 300 MHz.  Keeping the
    // event together here both preserves byte/control alignment and gives
    // implementation a local timing boundary before the asynchronous FIFO.
    reg        input_valid_q;
    reg [23:0] input_data_q;
    reg        input_frame_start_q;
    reg        input_line_last_q;
    reg        input_line_end_q;
    // Isolate the wide packer control set from the channel-wide reset and
    // XPM busy nets.  Payload is ignored while this local run qualifier is
    // low, so two independent copies keep fanout and placement local without
    // changing the accepted pixel sequence.
    (* MAX_FANOUT = 16 *) reg input_run_q = 1'b0;
    (* MAX_FANOUT = 16 *) reg packer_run_q = 1'b0;

    initial begin
        if ((FRAME_WIDTH & 1) != 0)
            $error("camera_axis_cdc requires an even FRAME_WIDTH");
        if ((FIFO_DEPTH & (FIFO_DEPTH-1)) != 0)
            $error("camera_axis_cdc FIFO_DEPTH must be a power of two");
    end

    always @(posedge camera_clk) begin
        if (!camera_resetn || !camera_enable || !ddr_resetn)
            fifo_reset_pipe <= 4'hf;
        else
            fifo_reset_pipe <= {fifo_reset_pipe[2:0], 1'b0};
    end

    // Run-time enable is deliberately synchronous.  It flushes a possible
    // half-pixel pair without ever entering an asynchronous CLR network.
    always @(posedge camera_clk) begin
        if (!camera_resetn || !camera_enable) begin
            input_run_q <= 1'b0;
            packer_run_q <= 1'b0;
        end else begin
            input_run_q <= !fifo_reset && !fifo_wr_rst_busy;
            packer_run_q <= !fifo_reset && !fifo_wr_rst_busy;
        end
    end

    always @(posedge camera_clk) begin
        if (!input_run_q) begin
            input_valid_q <= 1'b0;
            input_frame_start_q <= 1'b0;
            input_line_last_q <= 1'b0;
            input_line_end_q <= 1'b0;
        end else begin
            // The physical sensor cannot be stalled.  Match the previous
            // behavior by dropping an event when pixel_ready is low, while
            // retaining the independent line-end recovery pulse.
            input_valid_q <= pixel_valid && pixel_ready;
            input_frame_start_q <= frame_start;
            input_line_last_q <= line_last;
            input_line_end_q <= line_end;
            if (pixel_valid && pixel_ready)
                input_data_q <= pixel_data;
        end
    end

    always @(posedge camera_clk) begin
        if (!packer_run_q) begin
            first_user <= 1'b0;
            have_first <= 1'b0;
            pixel_x <= {X_WIDTH{1'b0}};
            fifo_wr_en <= 1'b0;
        end else begin
            fifo_wr_en <= 1'b0;
            if (input_line_end_q) begin
                // Never carry an orphan pixel or a short-line position into
                // the next physical HREF interval.
                have_first <= 1'b0;
                first_user <= 1'b0;
                pixel_x <= {X_WIDTH{1'b0}};
            end else if (input_valid_q) begin
                if (input_frame_start_q) begin
                    first_pixel <= input_data_q;
                    first_user <= 1'b1;
                    have_first <= 1'b1;
                    pixel_x <= {{(X_WIDTH-1){1'b0}}, 1'b1};
                end else begin
                    if (!have_first) begin
                        first_pixel <= input_data_q;
                        first_user <= 1'b0;
                        have_first <= 1'b1;
                    end else begin
                        fifo_din <= {input_line_last_q, first_user,
                                     input_data_q, first_pixel};
                        fifo_wr_en <= !fifo_full && !fifo_wr_rst_busy;
                        have_first <= 1'b0;
                        first_user <= 1'b0;
                    end

                    if (pixel_x == LAST_PIXEL)
                        pixel_x <= {X_WIDTH{1'b0}};
                    else
                        pixel_x <= pixel_x + 1'b1;
                end
            end
        end
    end

    // Camera-domain backpressure telemetry. These counters observe the
    // producer-side FIFO directly, before the asynchronous clock crossing.
    always @(posedge camera_clk) begin
        if (!camera_resetn || !camera_enable || fifo_reset ||
            fifo_wr_rst_busy) begin
            diag_fifo_full_stall_count <= 32'd0;
            diag_ready_low_count <= 32'd0;
            diag_fifo_max_level <= 32'd0;
            diag_line_flush_count <= 32'd0;
            diag_clear_sync1 <= 1'b0;
            diag_clear_sync2 <= 1'b0;
            diag_clear_seen <= 1'b0;
        end else begin
            diag_clear_sync1 <= diag_clear_toggle;
            diag_clear_sync2 <= diag_clear_sync1;
            if (pixel_valid && fifo_full)
                diag_fifo_full_stall_count <=
                    diag_fifo_full_stall_count + 1'b1;
            if (pixel_valid && !pixel_ready)
                diag_ready_low_count <= diag_ready_low_count + 1'b1;
            if (buffered_level > diag_fifo_max_level[COUNT_WIDTH-1:0])
                diag_fifo_max_level <= {{(32-COUNT_WIDTH){1'b0}},
                                         buffered_level};
            if (line_end &&
                (have_first || (pixel_x != {X_WIDTH{1'b0}})))
                diag_line_flush_count <= diag_line_flush_count + 1'b1;
            if (diag_clear) begin
                diag_clear_seen <= diag_clear_sync2;
                diag_fifo_full_stall_count <= 32'd0;
                diag_ready_low_count <= 32'd0;
                diag_fifo_max_level <= 32'd0;
                diag_line_flush_count <= 32'd0;
            end
        end
    end

`ifdef VERILATOR
    localparam integer PTR_WIDTH = $clog2(FIFO_DEPTH);
    reg [49:0] sim_mem [0:FIFO_DEPTH-1];
    reg [PTR_WIDTH-1:0] sim_wr_ptr;
    reg [PTR_WIDTH-1:0] sim_rd_ptr;
    reg [COUNT_WIDTH-1:0] sim_count;
    wire sim_write = fifo_wr_en && !fifo_full;
    wire sim_read = fifo_rd_en && !fifo_empty;

    assign fifo_dout = sim_mem[sim_rd_ptr];
    assign fifo_empty = (sim_count == 0);
    assign fifo_full = (sim_count == COUNT_WIDTH'(FIFO_DEPTH));
    assign fifo_wr_rst_busy = 1'b0;
    assign fifo_rd_rst_busy = 1'b0;
    assign unused_wr_count = sim_count;

    always @(posedge camera_clk) begin
        if (fifo_reset) begin
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
        .FIFO_WRITE_DEPTH(FIFO_DEPTH), .WRITE_DATA_WIDTH(50),
        .READ_DATA_WIDTH(50), .READ_MODE("fwft"),
        .FIFO_READ_LATENCY(0), .WR_DATA_COUNT_WIDTH(COUNT_WIDTH),
        .RD_DATA_COUNT_WIDTH(COUNT_WIDTH), .DOUT_RESET_VALUE("0"),
        .FULL_RESET_VALUE(0), .USE_ADV_FEATURES("0707"), .WAKEUP_TIME(0)
    ) u_fifo (
        .sleep(1'b0), .rst(fifo_reset), .wr_clk(camera_clk),
        .wr_en(fifo_wr_en), .din(fifo_din), .full(fifo_full),
        .prog_full(), .wr_data_count(unused_wr_count), .overflow(),
        .wr_ack(), .almost_full(), .wr_rst_busy(fifo_wr_rst_busy),
        .injectsbiterr(1'b0), .injectdbiterr(1'b0), .sbiterr(),
        .dbiterr(), .rd_en(fifo_rd_en), .dout(fifo_dout),
        .empty(fifo_empty), .rd_data_count(), .underflow(), .data_valid(),
        .almost_empty(), .prog_empty(), .rd_rst_busy(fifo_rd_rst_busy)
    );
`endif

    // Two registered FWFT prefetch slots.  The first slot is the AXIS output;
    // the second absorbs a prefetched word while the consumer is stalled.
    always @(posedge camera_clk) begin
        if (fifo_reset || fifo_rd_rst_busy || !ddr_resetn) begin
            output_valid_q <= 1'b0;
            output_skid_valid_q <= 1'b0;
        end else begin
            case ({fifo_rd_en, output_pop})
                2'b10: begin
                    if (!output_valid_q) begin
                        output_data_q <= fifo_dout;
                        output_valid_q <= 1'b1;
                    end else begin
                        output_skid_data_q <= fifo_dout;
                        output_skid_valid_q <= 1'b1;
                    end
                end
                2'b01: begin
                    if (output_skid_valid_q) begin
                        output_data_q <= output_skid_data_q;
                        output_skid_valid_q <= 1'b0;
                    end else begin
                        output_valid_q <= 1'b0;
                    end
                end
                2'b11: begin
                    // fifo_rd_en can only be high when the skid slot is free.
                    output_data_q <= fifo_dout;
                    output_valid_q <= 1'b1;
                    output_skid_valid_q <= 1'b0;
                end
                default: ;
            endcase
        end
    end

    assign m_axis.aclk = ddr_clk;
    assign m_axis.aresetn = ddr_resetn;
    assign m_axis.tdata = output_data_q[47:0];
    assign m_axis.tuser = output_data_q[48];
    assign m_axis.tlast = output_data_q[49];
    assign m_axis.tvalid = output_valid_q && ddr_resetn &&
                           !fifo_reset && !fifo_rd_rst_busy;
    // Only release the physical source after the common-clock FIFO is ready.
    assign pixel_ready = camera_resetn && camera_enable && input_run_q &&
                         packer_run_q && !fifo_reset && !fifo_wr_rst_busy &&
                         (!have_first || !fifo_full);

    always @(posedge camera_clk) begin
        if (!ddr_resetn) begin
            diag_fire_count <= 0;
            diag_sof_count <= 0;
            diag_eol_count <= 0;
        end else if (output_pop) begin
            diag_fire_count <= diag_fire_count + 1'b1;
            if (output_data_q[48]) diag_sof_count <= diag_sof_count + 1'b1;
            if (output_data_q[49]) diag_eol_count <= diag_eol_count + 1'b1;
        end
    end

    wire unused = &{1'b0, fifo_empty, unused_wr_count, ddr_clk};
endmodule
