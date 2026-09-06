`timescale 1ns/1ps

// Ordered recovery-event transport from the 300 MHz DVP sampling domain to
// the 150 MHz camera video domain.  Boundary and fault records share the data
// FIFO so their ordering cannot diverge from the recovered bytes.  A separate
// toggle/ack channel reports overflow even while that FIFO is full.
module dvp_event_bridge #(
    parameter integer FIFO_DEPTH = 1024
) (
    input  wire       capture_clk,
    input  wire       capture_resetn,
    input  wire       capture_enable,
    input  wire       event_valid,
    output wire       event_ready,
    input  wire [7:0] event_data,
    input  wire       event_byte_valid,
    input  wire       event_line_start,
    input  wire       event_line_last,
    input  wire       event_line_end,
    input  wire       event_frame_boundary,
    input  wire       event_fault,

    input  wire       video_clk,
    input  wire       video_resetn,
    output wire       video_event_valid,
    input  wire       video_event_ready,
    output wire [7:0] video_event_data,
    output wire       video_byte_valid,
    output wire       video_line_start,
    output wire       video_line_last,
    output wire       video_line_end,
    output wire       video_frame_boundary,
    output wire       video_resync,
    output wire       video_fault_pulse,
    output reg [31:0] overflow_count
);
    localparam integer EVENT_WIDTH = 14;
    localparam integer COUNT_WIDTH = $clog2(FIFO_DEPTH) + 1;
    wire [EVENT_WIDTH-1:0] fifo_din;
    wire [EVENT_WIDTH-1:0] fifo_dout;
    wire fifo_full;
    wire fifo_empty;
    wire fifo_wr_busy;
    wire fifo_rd_busy;
    reg drop_until_frame;
    reg fault_req_toggle;
    reg fault_pending;
    (* ASYNC_REG = "TRUE", SHREG_EXTRACT = "NO" *) reg [1:0] fault_ack_sync;
    (* ASYNC_REG = "TRUE", SHREG_EXTRACT = "NO" *) reg [1:0] fault_req_sync;
    reg fault_req_seen;
    reg fault_ack_toggle;
    (* ASYNC_REG = "TRUE", SHREG_EXTRACT = "NO" *) reg [1:0] video_resetn_sync;
    (* ASYNC_REG = "TRUE", SHREG_EXTRACT = "NO" *) reg [1:0] fifo_reset_video_sync;
    reg [3:0] fifo_reset_pipe = 4'hf;
    wire fifo_reset = |fifo_reset_pipe;
    wire restart_record = drop_until_frame && event_frame_boundary;
    wire accept_record = event_valid && !fifo_full && !fifo_wr_busy &&
                         capture_enable && (!drop_until_frame || restart_record);
    wire overflow_event = capture_enable &&
                          ((event_valid && fifo_full) || event_fault);

    assign fifo_din = {restart_record || event_fault,
                       event_frame_boundary, event_line_end,
                       event_line_last, event_line_start,
                       event_byte_valid, event_data};
    assign event_ready = capture_enable && !fifo_full && !fifo_wr_busy &&
                         (!drop_until_frame || event_frame_boundary) &&
                         !fifo_reset;

    always @(posedge capture_clk) begin
        video_resetn_sync <= {video_resetn_sync[0], video_resetn};
        if (!capture_resetn || !capture_enable || !video_resetn_sync[1])
            fifo_reset_pipe <= 4'hf;
        else
            fifo_reset_pipe <= {fifo_reset_pipe[2:0], 1'b0};
    end

    always @(posedge capture_clk) begin
        if (!capture_resetn || !capture_enable) begin
            drop_until_frame <= 1'b1;
            overflow_count <= 32'd0;
            fault_req_toggle <= 1'b0;
            fault_pending <= 1'b0;
            fault_ack_sync <= 2'b00;
        end else begin
            fault_ack_sync <= {fault_ack_sync[0], fault_ack_toggle};
            if (fault_pending && fault_ack_sync[1] == fault_req_toggle)
                fault_pending <= 1'b0;
            if (overflow_event) begin
                drop_until_frame <= 1'b1;
                if (overflow_count != 32'hffff_ffff)
                    overflow_count <= overflow_count + 1'b1;
                if (!fault_pending) begin
                    fault_req_toggle <= ~fault_req_toggle;
                    fault_pending <= 1'b1;
                end
            end else if (accept_record && restart_record) begin
                drop_until_frame <= 1'b0;
            end
        end
    end

    always @(posedge video_clk) begin
        if (!video_resetn) begin
            fifo_reset_video_sync <= 2'b11;
            fault_req_sync <= 2'b00;
            fault_req_seen <= 1'b0;
            fault_ack_toggle <= 1'b0;
        end else begin
            fifo_reset_video_sync <= {fifo_reset_video_sync[0], fifo_reset};
            fault_req_sync <= {fault_req_sync[0], fault_req_toggle};
            if (fault_req_sync[1] != fault_req_seen) begin
                fault_req_seen <= fault_req_sync[1];
                fault_ack_toggle <= fault_req_sync[1];
            end
        end
    end

    assign video_fault_pulse = video_resetn &&
                              (fault_req_sync[1] != fault_req_seen);

`ifdef VERILATOR
    localparam integer PTR_WIDTH = $clog2(FIFO_DEPTH);
    reg [EVENT_WIDTH-1:0] sim_mem [0:FIFO_DEPTH-1];
    reg [PTR_WIDTH:0] sim_wr_count;
    reg [PTR_WIDTH:0] sim_rd_count;
    wire sim_write = accept_record && !fifo_reset;
    wire sim_read = video_event_valid && video_event_ready;
    assign fifo_full = ((sim_wr_count - sim_rd_count) ==
                        (PTR_WIDTH+1)'(FIFO_DEPTH));
    assign fifo_empty = (sim_wr_count == sim_rd_count);
    assign fifo_dout = sim_mem[sim_rd_count[PTR_WIDTH-1:0]];
    assign fifo_wr_busy = 1'b0;
    assign fifo_rd_busy = 1'b0;
    always @(posedge capture_clk) begin
        if (fifo_reset)
            sim_wr_count <= 0;
        else if (sim_write) begin
            sim_mem[sim_wr_count[PTR_WIDTH-1:0]] <= fifo_din;
            sim_wr_count <= sim_wr_count + 1'b1;
        end
    end
    always @(posedge video_clk) begin
        if (!video_resetn || fifo_reset_video_sync[1])
            sim_rd_count <= 0;
        else if (sim_read)
            sim_rd_count <= sim_rd_count + 1'b1;
    end
`else
    xpm_fifo_async #(
        .CDC_SYNC_STAGES(2), .FIFO_MEMORY_TYPE("block"),
        .FIFO_READ_LATENCY(0), .FIFO_WRITE_DEPTH(FIFO_DEPTH),
        .READ_DATA_WIDTH(EVENT_WIDTH), .READ_MODE("fwft"),
        .USE_ADV_FEATURES("0707"), .WRITE_DATA_WIDTH(EVENT_WIDTH),
        .WR_DATA_COUNT_WIDTH(COUNT_WIDTH), .RD_DATA_COUNT_WIDTH(COUNT_WIDTH)
    ) u_event_fifo (
        .rst(fifo_reset), .wr_clk(capture_clk), .wr_en(accept_record),
        .din(fifo_din), .full(fifo_full), .overflow(),
        .wr_rst_busy(fifo_wr_busy), .wr_data_count(), .almost_full(),
        .prog_full(), .wr_ack(), .rd_clk(video_clk),
        .rd_en(video_event_valid && video_event_ready), .dout(fifo_dout),
        .empty(fifo_empty), .data_valid(), .underflow(),
        .rd_rst_busy(fifo_rd_busy), .rd_data_count(), .almost_empty(),
        .prog_empty(), .sleep(1'b0), .injectsbiterr(1'b0),
        .injectdbiterr(1'b0), .sbiterr(), .dbiterr()
    );
`endif

    assign video_event_valid = video_resetn && !fifo_reset_video_sync[1] &&
                               !fifo_empty && !fifo_rd_busy;
    assign {video_resync, video_frame_boundary, video_line_end,
            video_line_last, video_line_start, video_byte_valid,
            video_event_data} = fifo_dout;
endmodule
