`timescale 1ns/1ps

// Converts the OV5645 ISP's one-pixel RGB888 stream into the framebuffer's
// two-pixel AXIS format and crosses into the DDR UI clock domain.
module camera_axis_cdc #(
    parameter integer FRAME_WIDTH = 1920,
    parameter integer FIFO_DEPTH = 4096
) (
    input  wire         camera_clk,
    input  wire         camera_resetn,
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
    // XPM FIFO reset is synchronous to wr_clk.  Synchronize the DDR-side
    // reset into the camera domain before combining it with camera_resetn;
    // this prevents DDR calibration/reset signals from directly driving
    // camera-domain data registers and the XPM reset network.
    (* ASYNC_REG = "TRUE", SHREG_EXTRACT = "NO" *) reg [2:0] ddr_resetn_cam_sync;
    wire fifo_reset = !(camera_resetn && ddr_resetn_cam_sync[2]);
    // In FWFT mode, dout is valid whenever the FIFO is non-empty.  Do not
    // gate reads with XPM's optional data_valid output: the proven reference
    // design leaves that port unused, and synthesized hardware can otherwise
    // deadlock with rd_en permanently low.
    wire fifo_rd_en = m_axis.tready && !fifo_empty &&
                       ddr_resetn && !fifo_rd_rst_busy;
    wire [COUNT_WIDTH-1:0] unused_wr_count;
    wire [COUNT_WIDTH-1:0] unused_rd_count;
    (* ASYNC_REG = "TRUE", SHREG_EXTRACT = "NO" *) reg diag_clear_sync1;
    (* ASYNC_REG = "TRUE", SHREG_EXTRACT = "NO" *) reg diag_clear_sync2;
    reg diag_clear_seen;
    wire diag_clear = (diag_clear_sync2 != diag_clear_seen);

    initial begin
        if ((FRAME_WIDTH & 1) != 0)
            $error("camera_axis_cdc requires an even FRAME_WIDTH");
        if ((FIFO_DEPTH & (FIFO_DEPTH-1)) != 0)
            $error("camera_axis_cdc FIFO_DEPTH must be a power of two");
    end

    // Asynchronous assertion, synchronous release in the FIFO write domain.
    always @(posedge camera_clk or negedge ddr_resetn) begin
        if (!ddr_resetn)
            ddr_resetn_cam_sync <= 3'b000;
        else
            ddr_resetn_cam_sync <= {ddr_resetn_cam_sync[1:0], 1'b1};
    end

    always @(posedge camera_clk) begin
        if (!camera_resetn || fifo_reset || fifo_wr_rst_busy) begin
            first_pixel <= 24'd0;
            first_user <= 1'b0;
            have_first <= 1'b0;
            pixel_x <= {X_WIDTH{1'b0}};
            fifo_din <= 50'd0;
            fifo_wr_en <= 1'b0;
        end else begin
            fifo_wr_en <= 1'b0;
            if (line_end) begin
                // Never carry an orphan pixel or a short-line position into
                // the next physical HREF interval.
                have_first <= 1'b0;
                first_user <= 1'b0;
                pixel_x <= {X_WIDTH{1'b0}};
            end else if (pixel_valid && pixel_ready) begin
                if (frame_start) begin
                    first_pixel <= pixel_data;
                    first_user <= 1'b1;
                    have_first <= 1'b1;
                    pixel_x <= {{(X_WIDTH-1){1'b0}}, 1'b1};
                end else begin
                    if (!have_first) begin
                        first_pixel <= pixel_data;
                        first_user <= 1'b0;
                        have_first <= 1'b1;
                    end else begin
                        fifo_din <= {line_last, first_user,
                                     pixel_data, first_pixel};
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
        if (!camera_resetn || fifo_reset || fifo_wr_rst_busy) begin
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
            if (unused_wr_count > diag_fifo_max_level[COUNT_WIDTH-1:0])
                diag_fifo_max_level <= {{(32-COUNT_WIDTH){1'b0}},
                                         unused_wr_count};
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

    xpm_fifo_async #(
        .CDC_SYNC_STAGES(2),
        .FIFO_MEMORY_TYPE("block"),
        .FIFO_READ_LATENCY(0),
        .FIFO_WRITE_DEPTH(FIFO_DEPTH),
        .READ_DATA_WIDTH(50),
        .READ_MODE("fwft"),
        .USE_ADV_FEATURES("0707"),
        .WRITE_DATA_WIDTH(50),
        .WR_DATA_COUNT_WIDTH(COUNT_WIDTH),
        .RD_DATA_COUNT_WIDTH(COUNT_WIDTH)
    ) u_fifo (
        .rst(fifo_reset),
        .wr_clk(camera_clk),
        .wr_en(fifo_wr_en),
        .din(fifo_din),
        .full(fifo_full),
        .overflow(),
        .wr_rst_busy(fifo_wr_rst_busy),
        .wr_data_count(unused_wr_count),
        .almost_full(),
        .prog_full(),
        .wr_ack(),
        .rd_clk(ddr_clk),
        .rd_en(fifo_rd_en),
        .dout(fifo_dout),
        .empty(fifo_empty),
        .data_valid(),
        .underflow(),
        .rd_rst_busy(fifo_rd_rst_busy),
        .rd_data_count(unused_rd_count),
        .almost_empty(),
        .prog_empty(),
        .sleep(1'b0),
        .injectsbiterr(1'b0),
        .injectdbiterr(1'b0),
        .sbiterr(),
        .dbiterr()
    );

    assign m_axis.aclk = ddr_clk;
    assign m_axis.aresetn = ddr_resetn;
    assign m_axis.tdata = fifo_dout[47:0];
    assign m_axis.tuser = fifo_dout[48];
    assign m_axis.tlast = fifo_dout[49];
    assign m_axis.tvalid = !fifo_empty && ddr_resetn &&
                           !fifo_rd_rst_busy;
    // Only release the ISP when both sides of the asynchronous FIFO have left
    // reset.  The DDR-side consumer is faster than this packed camera stream,
    // so full is not expected during normal operation.
    assign pixel_ready = camera_resetn && !fifo_reset &&
                         !fifo_wr_rst_busy && (!have_first || !fifo_full);

    always @(posedge ddr_clk) begin
        if (!ddr_resetn) begin
            diag_fire_count <= 0;
            diag_sof_count <= 0;
            diag_eol_count <= 0;
        end else if (fifo_rd_en) begin
            diag_fire_count <= diag_fire_count + 1'b1;
            if (fifo_dout[48]) diag_sof_count <= diag_sof_count + 1'b1;
            if (fifo_dout[49]) diag_eol_count <= diag_eol_count + 1'b1;
        end
    end

    wire unused = &{1'b0, fifo_empty, unused_wr_count, unused_rd_count};
endmodule
