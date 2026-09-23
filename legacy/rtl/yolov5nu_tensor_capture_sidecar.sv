`timescale 1ns/1ps

// One-shot, non-blocking tap of any accepted capture stream.  The video path
// never sees this module's backpressure.  Overflow aborts the tensor write
// after the current AXI burst and is reported to software.
module yolov5nu_tensor_capture_sidecar #(
    parameter integer CHANNELS = 16,
    parameter integer FRAME_WIDTH = 640,
    parameter integer FRAME_HEIGHT = 480,
    parameter integer FIFO_DEPTH = 1024,
    parameter integer WATCHDOG_CYCLES = 150000000
) (
    input  wire                     clk,
    input  wire                     resetn,
    input  wire                     command_start,
    input  wire                     cancel,
    input  wire [3:0]               command_channel,
    input  wire [31:0]              command_addr,
    input  wire [CHANNELS*48-1:0]   tap_data,
    input  wire [CHANNELS-1:0]      tap_accept,
    input  wire [CHANNELS-1:0]      tap_sof,
    input  wire [CHANNELS-1:0]      tap_eol,
    input  wire [CHANNELS-1:0]      tap_eof,
    input  wire [CHANNELS*32-1:0]   tap_frame_id,
    input  wire [CHANNELS-1:0]      tap_error,
    output wire                     busy,
    output wire                     ready_for_frame,
    output reg                      completed,
    output reg                      completion_error,
    output reg  [3:0]               completion_channel,
    output reg  [31:0]              completion_frame_id,
    output reg  [31:0]              completion_bytes,
    output reg  [31:0]              overflow_count,
    axi4_if.master                  m_axi
);
    localparam integer PAYLOAD_WIDTH = 84;
    localparam integer CHANNEL_INDEX_WIDTH =
        CHANNELS <= 1 ? 1 : $clog2(CHANNELS);
    localparam [2:0] ST_IDLE=0, ST_ARMED=1, ST_CAPTURE=2,
                     ST_DRAIN=3, ST_ABORT=4, ST_FLUSH=5;
    reg [2:0] state;
    reg [3:0] channel_q;
    wire [CHANNEL_INDEX_WIDTH-1:0] channel_index =
        channel_q[CHANNEL_INDEX_WIDTH-1:0];
    reg [31:0] addr_q, frame_id_q;
    reg writer_start, writer_abort, capture_error;
    reg [31:0] watchdog;
    reg [3:0] flush_cycles;
    wire [47:0] selected_data = tap_data[channel_index*48 +: 48];
    wire [31:0] selected_frame_id = tap_frame_id[channel_index*32 +: 32];
    wire selected_accept = tap_accept[channel_index];
    wire selected_sof = tap_sof[channel_index];
    wire selected_eol = tap_eol[channel_index];
    wire selected_eof = tap_eof[channel_index];
    wire selected_error = tap_error[channel_index];

    wire [PAYLOAD_WIDTH-1:0] fifo_din = {
        selected_frame_id, selected_error, selected_eof,
        selected_eol, selected_sof, selected_data
    };
    wire [PAYLOAD_WIDTH-1:0] fifo_dout;
    wire fifo_empty, fifo_full;
    wire fifo_write = selected_accept && !fifo_full &&
        ((state == ST_ARMED && selected_sof) ||
         (state == ST_CAPTURE && !selected_sof));
    wire fifo_reset = !resetn || state == ST_FLUSH;
    wire packer_ready, packed_valid, packed_ready;
    wire [255:0] packed_data;
    wire packed_sof, packed_eol, packed_eof, packed_error;
    wire [31:0] packed_frame_id;
    wire writer_busy, writer_done, writer_error;
    wire [31:0] writer_bytes;
    wire fifo_read = !fifo_empty && packer_ready && !writer_abort &&
                     (state == ST_CAPTURE || state == ST_DRAIN);

    assign busy = state != ST_IDLE;
    assign ready_for_frame = state == ST_ARMED;

`ifdef VERILATOR
    reg [PAYLOAD_WIDTH-1:0] sim_mem [0:FIFO_DEPTH-1];
    reg [$clog2(FIFO_DEPTH)-1:0] wr_ptr, rd_ptr;
    reg [$clog2(FIFO_DEPTH):0] fifo_count;
    assign fifo_dout = sim_mem[rd_ptr];
    assign fifo_empty = fifo_count == 0;
    assign fifo_full = fifo_count == ($clog2(FIFO_DEPTH)+1)'(FIFO_DEPTH);
    always @(posedge clk) begin
        if (fifo_reset) begin
            wr_ptr <= 0;
            rd_ptr <= 0;
            fifo_count <= 0;
        end else begin
            if (fifo_write) begin
                sim_mem[wr_ptr] <= fifo_din;
                wr_ptr <= wr_ptr + 1'b1;
            end
            if (fifo_read)
                rd_ptr <= rd_ptr + 1'b1;
            case ({fifo_write, fifo_read})
                2'b10: fifo_count <= fifo_count + 1'b1;
                2'b01: fifo_count <= fifo_count - 1'b1;
                default: ;
            endcase
        end
    end
`else
    xpm_fifo_sync #(
        .FIFO_MEMORY_TYPE("block"), .ECC_MODE("no_ecc"),
        .FIFO_WRITE_DEPTH(FIFO_DEPTH), .WRITE_DATA_WIDTH(PAYLOAD_WIDTH),
        .READ_DATA_WIDTH(PAYLOAD_WIDTH), .READ_MODE("fwft"),
        .FIFO_READ_LATENCY(0), .PROG_FULL_THRESH(FIFO_DEPTH-8),
        .WR_DATA_COUNT_WIDTH($clog2(FIFO_DEPTH)+1),
        .RD_DATA_COUNT_WIDTH($clog2(FIFO_DEPTH)+1),
        .DOUT_RESET_VALUE("0"), .FULL_RESET_VALUE(0),
        .USE_ADV_FEATURES("0707"), .WAKEUP_TIME(0)
    ) u_capture_fifo (
        .sleep(1'b0), .rst(fifo_reset), .wr_clk(clk),
        .wr_en(fifo_write), .din(fifo_din), .full(fifo_full),
        .prog_full(), .wr_data_count(), .overflow(), .wr_ack(),
        .almost_full(), .wr_rst_busy(), .injectsbiterr(1'b0),
        .injectdbiterr(1'b0), .sbiterr(), .dbiterr(),
        .rd_en(fifo_read), .dout(fifo_dout), .empty(fifo_empty),
        .rd_data_count(), .underflow(), .data_valid(),
        .almost_empty(), .prog_empty(), .rd_rst_busy()
    );
`endif

    yolov5nu_tensor_stream_packer #(
        .FRAME_WIDTH(FRAME_WIDTH), .FRAME_HEIGHT(FRAME_HEIGHT)
    ) u_packer (
        .clk(clk), .resetn(resetn && state != ST_FLUSH),
        .s_pair(fifo_dout[47:0]), .s_sof(fifo_dout[48]),
        .s_eol(fifo_dout[49]), .s_eof(fifo_dout[50]),
        .s_error(fifo_dout[51]), .s_frame_id(fifo_dout[83:52]),
        .s_valid(fifo_read), .s_ready(packer_ready),
        .m_data(packed_data), .m_sof(packed_sof),
        .m_eol(packed_eol), .m_eof(packed_eof),
        .m_frame_id(packed_frame_id), .m_error(packed_error),
        .m_valid(packed_valid), .m_ready(packed_ready)
    );

    yolov5nu_tensor_frame_writer #(
        .FRAME_WIDTH(FRAME_WIDTH), .FRAME_HEIGHT(FRAME_HEIGHT)
    ) u_writer (
        .clk(clk), .resetn(resetn), .start(writer_start),
        .abort(writer_abort), .tensor_addr(addr_q), .frame_id(frame_id_q),
        .s_data(packed_data), .s_sof(packed_sof),
        .s_eol(packed_eol), .s_eof(packed_eof),
        .s_frame_id(packed_frame_id), .s_error(packed_error),
        .s_valid(packed_valid), .s_ready(packed_ready),
        .busy(writer_busy), .done(writer_done), .error(writer_error),
        .bytes_written(writer_bytes), .m_axi(m_axi)
    );

    initial begin
        if (CHANNELS < 1 || CHANNELS > 16 || FIFO_DEPTH < 16 ||
            (FIFO_DEPTH & (FIFO_DEPTH-1)) != 0 || WATCHDOG_CYCLES < 1)
            $error("Invalid tensor capture sidecar parameters");
    end

    always @(posedge clk) begin
        if (!resetn) begin
            state <= ST_IDLE;
            channel_q <= 0;
            addr_q <= 0;
            frame_id_q <= 0;
            writer_start <= 0;
            writer_abort <= 0;
            capture_error <= 0;
            watchdog <= 0;
            flush_cycles <= 0;
            completed <= 0;
            completion_error <= 0;
            completion_channel <= 0;
            completion_frame_id <= 0;
            completion_bytes <= 0;
            overflow_count <= 0;
        end else begin
            writer_start <= 0;
            case (state)
            ST_IDLE: if (command_start) begin
                completed <= 0;
                completion_error <= 0;
                completion_bytes <= 0;
                completion_channel <= command_channel;
                channel_q <= command_channel;
                addr_q <= command_addr;
                watchdog <= 0;
                writer_abort <= 0;
                capture_error <= 0;
                if (int'(command_channel) >= CHANNELS ||
                    command_addr[4:0] != 0) begin
                    completed <= 1;
                    completion_error <= 1;
                end else
                    state <= ST_ARMED;
            end
            ST_ARMED: begin
                if (cancel) begin
                    state <= ST_FLUSH;
                    flush_cycles <= 0;
                end else if (selected_accept && selected_sof) begin
                    frame_id_q <= selected_frame_id;
                    completion_frame_id <= selected_frame_id;
                    writer_start <= 1;
                    watchdog <= 0;
                    if (fifo_full || selected_error || selected_eof) begin
                        writer_abort <= 1;
                        capture_error <= 1;
                        if (fifo_full)
                            overflow_count <= overflow_count + 1'b1;
                        state <= ST_ABORT;
                    end else
                        state <= ST_CAPTURE;
                end else if (watchdog == WATCHDOG_CYCLES-1) begin
                    completed <= 1;
                    completion_error <= 1;
                    state <= ST_FLUSH;
                    flush_cycles <= 0;
                end else
                    watchdog <= watchdog + 1'b1;
            end
            ST_CAPTURE: begin
                if (writer_done) begin
                    completion_error <= 1;
                    completion_bytes <= writer_bytes;
                    completed <= 1;
                    state <= ST_FLUSH;
                    flush_cycles <= 0;
                end else if (selected_accept) begin
                    watchdog <= 0;
                    if (fifo_full || selected_sof ||
                        selected_frame_id != frame_id_q) begin
                        writer_abort <= 1;
                        capture_error <= 1;
                        if (fifo_full)
                            overflow_count <= overflow_count + 1'b1;
                        state <= ST_ABORT;
                    end else if (selected_eof)
                        state <= ST_DRAIN;
                end else if (watchdog == WATCHDOG_CYCLES-1) begin
                    writer_abort <= 1;
                    capture_error <= 1;
                    state <= ST_ABORT;
                end else
                    watchdog <= watchdog + 1'b1;
            end
            ST_DRAIN: begin
                if (writer_done) begin
                    completion_error <= writer_error || capture_error;
                    completion_bytes <= writer_bytes;
                    completed <= 1;
                    state <= ST_FLUSH;
                    flush_cycles <= 0;
                end else if (watchdog == WATCHDOG_CYCLES-1) begin
                    writer_abort <= 1;
                    capture_error <= 1;
                    state <= ST_ABORT;
                end else
                    watchdog <= watchdog + 1'b1;
            end
            ST_ABORT: if (writer_done) begin
                completion_error <= 1;
                completion_bytes <= writer_bytes;
                completed <= 1;
                state <= ST_FLUSH;
                flush_cycles <= 0;
            end
            ST_FLUSH: begin
                flush_cycles <= flush_cycles + 1'b1;
                if (flush_cycles == 8)
                    state <= ST_IDLE;
            end
            default: state <= ST_IDLE;
            endcase
        end
    end
endmodule
