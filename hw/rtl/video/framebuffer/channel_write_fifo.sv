`timescale 1ns/1ps

// Converts four 2-PPC RGB888 stream transfers (8 pixels) into one 256-bit
// XRGB8888 DDR word and buffers it together with normalized frame metadata.
module channel_write_fifo #(
    parameter integer FIFO_DEPTH = 1024,
    parameter integer FRAME_ID_WIDTH = 32
) (
    video_stream_if.sink s_stream,

    input  wire                         rd_en,
    output wire [255:0]                 rd_data,
    output wire                         rd_sof,
    output wire                         rd_eol,
    output wire                         rd_eof,
    output wire [FRAME_ID_WIDTH-1:0]    rd_frame_id,
    output wire                         rd_error,
    output wire                         empty,
    output wire                         full,
    output wire [$clog2(FIFO_DEPTH):0]  data_count
);
    localparam integer COUNT_WIDTH = $clog2(FIFO_DEPTH) + 1;
    localparam integer PAYLOAD_WIDTH = 256 + FRAME_ID_WIDTH + 4;

    reg [1:0] pack_count;
    reg [191:0] pack_data;
    reg pack_sof;
    reg pack_error;
    reg [FRAME_ID_WIDTH-1:0] pack_frame_id;

    wire accept = s_stream.valid && s_stream.ready;
    // A new SOF is an authoritative resynchronization point. Do not combine
    // the first pixels of a new frame with an abandoned partial DDR word.
    wire commit = accept && (pack_count == 2'd3) && !s_stream.sof;
    wire metadata_error = ((pack_count != 3) &&
                           (s_stream.eol || s_stream.eof)) ||
                          ((pack_count != 0) && !s_stream.sof &&
                           (s_stream.frame_id != pack_frame_id));

    function automatic [63:0] expand_pair;
        input [47:0] pair;
        begin
            expand_pair = {8'h00, pair[47:24], 8'h00, pair[23:0]};
        end
    endfunction

    wire [PAYLOAD_WIDTH-1:0] fifo_din = {
        pack_error | s_stream.error | metadata_error,
        s_stream.eof,
        s_stream.eol,
        pack_sof,
        pack_frame_id,
        expand_pair(s_stream.data),
        pack_data
    };
    wire [PAYLOAD_WIDTH-1:0] fifo_dout;

    assign s_stream.ready = (pack_count != 2'd3) || !full;
    assign rd_data = fifo_dout[255:0];
    assign rd_frame_id = fifo_dout[256 +: FRAME_ID_WIDTH];
    assign rd_sof = fifo_dout[256 + FRAME_ID_WIDTH];
    assign rd_eol = fifo_dout[257 + FRAME_ID_WIDTH];
    assign rd_eof = fifo_dout[258 + FRAME_ID_WIDTH];
    assign rd_error = fifo_dout[259 + FRAME_ID_WIDTH];

    initial begin
        if ((FIFO_DEPTH & (FIFO_DEPTH-1)) != 0 || FIFO_DEPTH < 16)
            $error("channel_write_fifo depth must be a power of two >= 16");
    end

    always @(posedge s_stream.aclk) begin
        if (!s_stream.aresetn) begin
            pack_count <= 2'd0;
            pack_data <= 192'd0;
            pack_sof <= 1'b0;
            pack_error <= 1'b0;
            pack_frame_id <= {FRAME_ID_WIDTH{1'b0}};
        end else if (accept) begin
            if ((pack_count == 0) || s_stream.sof) begin
                pack_data[63:0] <= expand_pair(s_stream.data);
                pack_sof <= s_stream.sof;
                pack_error <= s_stream.error || metadata_error;
                pack_frame_id <= s_stream.frame_id;
                pack_count <= 2'd1;
            end else if (pack_count == 1) begin
                pack_data[127:64] <= expand_pair(s_stream.data);
                pack_error <= pack_error || s_stream.error || metadata_error;
                pack_count <= 2'd2;
            end else if (pack_count == 2) begin
                pack_data[191:128] <= expand_pair(s_stream.data);
                pack_error <= pack_error || s_stream.error || metadata_error;
                pack_count <= 2'd3;
            end else begin
                pack_count <= 2'd0;
                pack_sof <= 1'b0;
                pack_error <= 1'b0;
            end
        end
    end

`ifdef VERILATOR
    reg [PAYLOAD_WIDTH-1:0] sim_mem [0:FIFO_DEPTH-1];
    reg [$clog2(FIFO_DEPTH)-1:0] sim_wr_ptr;
    reg [$clog2(FIFO_DEPTH)-1:0] sim_rd_ptr;
    reg [COUNT_WIDTH-1:0] sim_count;
    wire do_write = commit && !full;
    wire do_read = rd_en && !empty;

    assign fifo_dout = sim_mem[sim_rd_ptr];
    assign empty = (sim_count == 0);
    assign full = (sim_count == COUNT_WIDTH'(FIFO_DEPTH));
    assign data_count = sim_count;

    always @(posedge s_stream.aclk) begin
        if (!s_stream.aresetn) begin
            sim_wr_ptr <= 0;
            sim_rd_ptr <= 0;
            sim_count <= 0;
        end else begin
            if (do_write) begin
                sim_mem[sim_wr_ptr] <= fifo_din;
                sim_wr_ptr <= sim_wr_ptr + 1'b1;
            end
            if (do_read)
                sim_rd_ptr <= sim_rd_ptr + 1'b1;
            case ({do_write, do_read})
                2'b10: sim_count <= sim_count + 1'b1;
                2'b01: sim_count <= sim_count - 1'b1;
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
        .WR_DATA_COUNT_WIDTH(COUNT_WIDTH), .RD_DATA_COUNT_WIDTH(COUNT_WIDTH),
        .DOUT_RESET_VALUE("0"), .FULL_RESET_VALUE(0),
        .USE_ADV_FEATURES("0707"), .WAKEUP_TIME(0)
    ) u_fifo (
        .sleep(1'b0), .rst(!s_stream.aresetn), .wr_clk(s_stream.aclk),
        .wr_en(commit), .din(fifo_din), .full(full), .prog_full(),
        .wr_data_count(data_count), .overflow(), .wr_ack(), .almost_full(),
        .wr_rst_busy(), .injectsbiterr(1'b0), .injectdbiterr(1'b0),
        .sbiterr(), .dbiterr(), .rd_en(rd_en), .dout(fifo_dout),
        .empty(empty), .rd_data_count(), .underflow(), .data_valid(),
        .almost_empty(), .prog_empty(), .rd_rst_busy()
    );
`endif
endmodule

