`timescale 1ns/1ps

// Packs RGB888 video (two pixels/beat) into XRGB8888 DDR words.  Capture and
// AXI run in the DDR UI clock domain; complete frames are either accepted into
// an owned buffer or discarded when the pool is full.
module axis_frame_writer #(
    parameter integer BURST_MAX_BEATS = 64,
    parameter integer FIFO_DEPTH = 4096
) (
    axis_video_if.sink s_axis,
    axi4_if.master     m_axi,

    output wire        buffer_acquire,
    input  wire        buffer_grant,
    input  wire        buffer_drop,
    input  wire [31:0] buffer_base,
    output reg         buffer_done,
    output reg         buffer_error,
    input  wire [31:0] frame_width,
    input  wire [31:0] frame_height,
    input  wire [31:0] frame_stride_bytes,
    output reg  [31:0] malformed_frame_count
);
    localparam integer FIFO_COUNT_WIDTH = $clog2(FIFO_DEPTH) + 1;
    localparam [2:0] WR_IDLE = 3'd0;
    localparam [2:0] WR_PREP = 3'd1;
    localparam [2:0] WR_ADDR = 3'd2;
    localparam [2:0] WR_DATA = 3'd3;
    localparam [2:0] WR_RESP = 3'd4;
    localparam [2:0] WR_FINISH = 3'd5;
    localparam [2:0] WR_DRAIN = 3'd6;

    reg capture_active;
    reg discard_active;
    reg awaiting_buffer;
    reg capture_bad;
    reg [1:0] pack_count;
    reg [191:0] pack_data;
    reg [31:0] capture_line;
    reg [31:0] capture_line_beat;
    reg [31:0] discard_line;
    reg capture_complete;
    reg [31:0] base_latched;
    reg [31:0] width_latched;
    reg [31:0] height_latched;
    reg [31:0] stride_latched;

    wire [FIFO_COUNT_WIDTH-1:0] fifo_count;
    wire fifo_empty;
    wire fifo_full;
    wire [255:0] fifo_dout;

    reg [2:0] wr_state;
    reg [31:0] write_line;
    reg [31:0] write_line_beat;
    reg [31:0] write_line_addr;
    reg [31:0] write_burst_addr;
    reg [8:0] burst_beats;
    reg [8:0] burst_sent;
    reg awvalid;
    reg axi_error_seen;

    // RX must never be backpressured.  A full FIFO invalidates the current
    // frame, but the remaining AXIS traffic is still consumed through EOL.
    assign buffer_acquire = awaiting_buffer;
    assign s_axis.tready = 1'b1;
    wire axis_fire = s_axis.tvalid && s_axis.tready;

    function automatic [63:0] expand_pair;
        input [47:0] pair;
        begin
            expand_pair = {8'h00, pair[47:24], 8'h00, pair[23:0]};
        end
    endfunction

    wire fifo_write_candidate = axis_fire && capture_active &&
                                (pack_count == 2'd3) && !capture_bad &&
                                !axi_error_seen &&
                                !(buffer_drop && awaiting_buffer);
    wire fifo_write = fifo_write_candidate && !fifo_full;
    wire fifo_overflow_event = fifo_write_candidate && fifo_full;
    wire [255:0] fifo_din = {expand_pair(s_axis.tdata), pack_data};
    wire w_fire = m_axi.wvalid && m_axi.wready;
    wire fifo_drain = (wr_state == WR_DRAIN) && !fifo_empty;
    wire fifo_read = w_fire || fifo_drain;

    wire [31:0] line_beats = width_latched >> 3;
    wire [31:0] line_beats_left = line_beats - write_line_beat;
    wire [31:0] beats_to_4k = (32'h1000 - {20'd0, write_burst_addr[11:0]}) >> 5;
    wire [31:0] burst_limit = (line_beats_left > BURST_MAX_BEATS) ?
                              BURST_MAX_BEATS : line_beats_left;
    wire [31:0] planned_beats = (burst_limit > beats_to_4k) ?
                                beats_to_4k : burst_limit;
    wire final_burst = (write_line_beat + burst_beats >= line_beats) &&
                       (write_line == height_latched-1);

    assign m_axi.aclk = s_axis.aclk;
    assign m_axi.aresetn = s_axis.aresetn;
    assign m_axi.awid = 3'd0;
    assign m_axi.awaddr = write_burst_addr;
    assign m_axi.awlen = burst_beats[7:0] - 1'b1;
    assign m_axi.awsize = 3'b101;
    assign m_axi.awburst = 2'b01;
    assign m_axi.awlock = 1'b0;
    assign m_axi.awcache = 4'b0010;
    assign m_axi.awprot = 3'b000;
    assign m_axi.awqos = 4'he;
    assign m_axi.awvalid = awvalid;
    assign m_axi.wdata = fifo_dout;
    assign m_axi.wstrb = 32'hffff_ffff;
    assign m_axi.wlast = (wr_state == WR_DATA) && !fifo_empty &&
                         (burst_sent == burst_beats-1);
    assign m_axi.wvalid = (wr_state == WR_DATA) && !fifo_empty;
    assign m_axi.bready = (wr_state == WR_RESP);
    assign m_axi.arid = 3'd0;
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
        if ((FIFO_DEPTH & (FIFO_DEPTH-1)) != 0 || FIFO_DEPTH < BURST_MAX_BEATS+8)
            $error("axis_frame_writer FIFO_DEPTH must be power-of-two and cover one burst");
    end

    always @(posedge s_axis.aclk) begin
        if (!s_axis.aresetn) begin
            capture_active <= 1'b0;
            discard_active <= 1'b0;
            awaiting_buffer <= 1'b0;
            capture_bad <= 1'b0;
            pack_count <= 2'd0;
            pack_data <= 192'd0;
            capture_line <= 32'd0;
            capture_line_beat <= 32'd0;
            discard_line <= 32'd0;
            capture_complete <= 1'b0;
            base_latched <= 32'd0;
            width_latched <= 32'd0;
            height_latched <= 32'd0;
            stride_latched <= 32'd0;
            malformed_frame_count <= 32'd0;
        end else begin
            if (buffer_done) begin
                capture_complete <= 1'b0;
                capture_bad <= 1'b0;
            end

            if (buffer_grant && awaiting_buffer) begin
                awaiting_buffer <= 1'b0;
                base_latched <= buffer_base;
            end else if (buffer_drop && awaiting_buffer) begin
                awaiting_buffer <= 1'b0;
                capture_active <= 1'b0;
                discard_active <= 1'b1;
                discard_line <= capture_line;
                pack_count <= 2'd0;
            end

            if (axis_fire && discard_active && s_axis.tlast) begin
                if (discard_line >= frame_height-1)
                    discard_active <= 1'b0;
                else
                    discard_line <= discard_line + 1'b1;
            end

            // Start packing immediately at SOF.  The manager answers the
            // buffer request on the following cycle, while ingress continues.
            if (axis_fire && !capture_active && !discard_active &&
                s_axis.tuser && (wr_state == WR_IDLE) && !capture_complete) begin
                capture_active <= 1'b1;
                awaiting_buffer <= 1'b1;
                capture_bad <= 1'b0;
                capture_line <= 32'd0;
                capture_line_beat <= 32'd1;
                capture_complete <= 1'b0;
                pack_count <= 2'd1;
                pack_data[0 +: 64] <= expand_pair(s_axis.tdata);
                width_latched <= frame_width;
                height_latched <= frame_height;
                stride_latched <= frame_stride_bytes;
                if (s_axis.tlast && (frame_height == 1)) begin
                    capture_active <= 1'b0;
                    capture_complete <= 1'b1;
                    if ((frame_width >> 1) != 1)
                        malformed_frame_count <= malformed_frame_count + 1'b1;
                end
            end else if (axis_fire && capture_active && !s_axis.tuser) begin
                if (pack_count != 2'd3) begin
                    pack_data[pack_count*64 +: 64] <= expand_pair(s_axis.tdata);
                    pack_count <= pack_count + 1'b1;
                end else begin
                    pack_count <= 2'd0;
                end

                if (fifo_overflow_event)
                    capture_bad <= 1'b1;

                if (s_axis.tlast &&
                    (capture_line_beat != (width_latched >> 1)-1))
                    capture_bad <= 1'b1;
                if (!s_axis.tlast &&
                    (capture_line_beat == (width_latched >> 1)-1))
                    capture_bad <= 1'b1;

                if (s_axis.tlast) begin
                    if (capture_line == height_latched-1) begin
                        capture_complete <= 1'b1;
                        capture_active <= 1'b0;
                        if (capture_bad || fifo_overflow_event || s_axis.tuser ||
                            (capture_line_beat != (width_latched >> 1)-1) ||
                            (pack_count != 2'd3))
                            malformed_frame_count <= malformed_frame_count + 1'b1;
                    end else begin
                        capture_line <= capture_line + 1'b1;
                        capture_line_beat <= 32'd0;
                    end
                end else
                    capture_line_beat <= capture_line_beat + 1'b1;
            end else if (axis_fire && capture_active && s_axis.tuser) begin
                capture_bad <= 1'b1;
                capture_active <= 1'b0;
                capture_complete <= 1'b1;
                discard_active <= !(s_axis.tlast && (height_latched == 1));
                discard_line <= 32'd0;
                malformed_frame_count <= malformed_frame_count + 1'b1;
            end else if (axis_fire && !capture_active && !discard_active &&
                         s_axis.tuser) begin
                // A previous owned frame is still being committed.  Drain
                // this entire new frame instead of allowing RX backpressure.
                discard_active <= !(s_axis.tlast && (frame_height == 1));
                discard_line <= 32'd0;
            end
        end
    end

`ifdef VERILATOR
    reg [255:0] sim_fifo [0:FIFO_DEPTH-1];
    reg [$clog2(FIFO_DEPTH)-1:0] sim_wr_ptr;
    reg [$clog2(FIFO_DEPTH)-1:0] sim_rd_ptr;
    reg [FIFO_COUNT_WIDTH-1:0] sim_fifo_count;
    assign fifo_count = sim_fifo_count;
    assign fifo_empty = (sim_fifo_count == 0);
    assign fifo_full = (sim_fifo_count == FIFO_DEPTH);
    assign fifo_dout = sim_fifo[sim_rd_ptr];
    always @(posedge s_axis.aclk) begin
        if (!s_axis.aresetn) begin
            sim_wr_ptr <= 0;
            sim_rd_ptr <= 0;
            sim_fifo_count <= 0;
        end else begin
            if (fifo_write) begin
                sim_fifo[sim_wr_ptr] <= fifo_din;
                sim_wr_ptr <= sim_wr_ptr + 1'b1;
            end
            if (fifo_read)
                sim_rd_ptr <= sim_rd_ptr + 1'b1;
            case ({fifo_write, fifo_read})
                2'b10: sim_fifo_count <= sim_fifo_count + 1'b1;
                2'b01: sim_fifo_count <= sim_fifo_count - 1'b1;
                default: ;
            endcase
        end
    end
`else
    xpm_fifo_sync #(
        .FIFO_MEMORY_TYPE("block"), .ECC_MODE("no_ecc"),
        .FIFO_WRITE_DEPTH(FIFO_DEPTH), .WRITE_DATA_WIDTH(256),
        .READ_DATA_WIDTH(256), .READ_MODE("fwft"), .FIFO_READ_LATENCY(0),
        .PROG_FULL_THRESH(FIFO_DEPTH-8),
        .WR_DATA_COUNT_WIDTH(FIFO_COUNT_WIDTH),
        .RD_DATA_COUNT_WIDTH(FIFO_COUNT_WIDTH), .DOUT_RESET_VALUE("0"),
        .FULL_RESET_VALUE(0), .USE_ADV_FEATURES("0707"), .WAKEUP_TIME(0)
    ) u_write_fifo (
        .sleep(1'b0), .rst(!s_axis.aresetn), .wr_clk(s_axis.aclk),
        .wr_en(fifo_write), .din(fifo_din), .full(fifo_full),
        .prog_full(), .wr_data_count(fifo_count),
        .overflow(), .wr_ack(), .almost_full(), .wr_rst_busy(),
        .injectsbiterr(1'b0), .injectdbiterr(1'b0), .sbiterr(), .dbiterr(),
        .rd_en(fifo_read), .dout(fifo_dout), .empty(fifo_empty),
        .rd_data_count(), .underflow(), .data_valid(), .almost_empty(),
        .prog_empty(), .rd_rst_busy()
    );
`endif

    always @(posedge s_axis.aclk) begin
        if (!s_axis.aresetn) begin
            wr_state <= WR_IDLE;
            write_line <= 32'd0;
            write_line_beat <= 32'd0;
            write_line_addr <= 32'd0;
            write_burst_addr <= 32'd0;
            burst_beats <= 9'd0;
            burst_sent <= 9'd0;
            awvalid <= 1'b0;
            axi_error_seen <= 1'b0;
            buffer_done <= 1'b0;
            buffer_error <= 1'b0;
        end else begin
            buffer_done <= 1'b0;
            buffer_error <= 1'b0;
            case (wr_state)
                WR_IDLE: begin
                    awvalid <= 1'b0;
                    if (buffer_grant) begin
                        write_line <= 32'd0;
                        write_line_beat <= 32'd0;
                        write_line_addr <= buffer_base;
                        write_burst_addr <= buffer_base;
                        axi_error_seen <= 1'b0;
                        wr_state <= capture_bad ? WR_DRAIN : WR_PREP;
                    end
                end
                WR_PREP: begin
                    if (capture_bad || axi_error_seen)
                        wr_state <= WR_DRAIN;
                    else begin
                        burst_beats <= planned_beats[8:0];
                        burst_sent <= 9'd0;
                        wr_state <= WR_ADDR;
                    end
                end
                WR_ADDR: begin
                    if (!awvalid && (capture_bad || axi_error_seen))
                        wr_state <= WR_DRAIN;
                    else if (!awvalid && (fifo_count >= burst_beats))
                        awvalid <= 1'b1;
                    if (awvalid && m_axi.awready) begin
                        awvalid <= 1'b0;
                        wr_state <= WR_DATA;
                    end
                end
                WR_DATA: begin
                    if (w_fire) begin
                        if (burst_sent == burst_beats-1)
                            wr_state <= WR_RESP;
                        else
                            burst_sent <= burst_sent + 1'b1;
                    end
                end
                WR_RESP: begin
                    if (m_axi.bvalid) begin
                        if (m_axi.bresp != 2'b00)
                            axi_error_seen <= 1'b1;
                        if (capture_bad || axi_error_seen ||
                            (m_axi.bresp != 2'b00)) begin
                            wr_state <= WR_DRAIN;
                        end else if (final_burst) begin
                            if (capture_complete) begin
                                buffer_done <= 1'b1;
                                wr_state <= WR_IDLE;
                            end else
                                wr_state <= WR_FINISH;
                        end else if (write_line_beat + burst_beats >= line_beats) begin
                            write_line <= write_line + 1'b1;
                            write_line_beat <= 32'd0;
                            write_line_addr <= write_line_addr + stride_latched;
                            write_burst_addr <= write_line_addr + stride_latched;
                            wr_state <= WR_PREP;
                        end else begin
                            write_line_beat <= write_line_beat + burst_beats;
                            write_burst_addr <= write_burst_addr +
                                                {{18{1'b0}}, burst_beats, 5'b0};
                            wr_state <= WR_PREP;
                        end
                    end
                end
                WR_FINISH: begin
                    if (capture_bad || axi_error_seen)
                        wr_state <= WR_DRAIN;
                    else if (capture_complete) begin
                        buffer_done <= 1'b1;
                        wr_state <= WR_IDLE;
                    end
                end
                WR_DRAIN: begin
                    awvalid <= 1'b0;
                    if (fifo_empty && capture_complete) begin
                        buffer_done <= 1'b1;
                        buffer_error <= 1'b1;
                        wr_state <= WR_IDLE;
                    end
                end
                default: wr_state <= WR_IDLE;
            endcase
        end
    end

    wire unused = &{1'b0, m_axi.bid, m_axi.rid, m_axi.rdata, m_axi.rresp,
                    m_axi.rlast, m_axi.rvalid};
endmodule
