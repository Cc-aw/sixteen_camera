`timescale 1ns/1ps

// Eight RGB565 pixel pairs make one 256-bit DDR beat.  Each 360-pixel line
// ends after four pairs in its last beat; the upper four pairs are zero.
module display_frame_packer #(
    parameter integer FIFO_DEPTH = 1024,
    parameter integer FRAME_ID_WIDTH = 32
) (
    video_stream_if.sink s_stream,
    input  wire rd_en,
    output wire [255:0] rd_data,
    output wire rd_sof, rd_eol, rd_eof,
    output wire [FRAME_ID_WIDTH-1:0] rd_frame_id,
    output wire rd_error,
    output wire empty, full,
    output wire [$clog2(FIFO_DEPTH):0] data_count
);
    localparam integer COUNT_WIDTH = $clog2(FIFO_DEPTH) + 1;
    localparam integer PAYLOAD_WIDTH = 256 + FRAME_ID_WIDTH + 4;

    reg [2:0] pair_count;
    reg [223:0] pack_data;
    reg pack_sof, pack_error;
    reg [FRAME_ID_WIDTH-1:0] pack_frame_id;
    wire accept = s_stream.valid && s_stream.ready;
    wire commit = accept && !s_stream.sof &&
                  ((pair_count == 3'd7) || s_stream.eol);
    wire malformed = (s_stream.eol && (pair_count != 3'd3)) ||
                     (s_stream.eof && !s_stream.eol) ||
                     ((pair_count != 0) && !s_stream.sof &&
                      (s_stream.frame_id != pack_frame_id));
    wire [255:0] complete_word = s_stream.eol ?
        {128'd0, s_stream.data[31:0], pack_data[95:0]} :
        {s_stream.data[31:0], pack_data};
    wire [PAYLOAD_WIDTH-1:0] fifo_din = {
        pack_error | s_stream.error | malformed,
        s_stream.eof, s_stream.eol, pack_sof, pack_frame_id,
        complete_word
    };
    wire [PAYLOAD_WIDTH-1:0] fifo_dout;

    assign s_stream.ready = !full;
    assign rd_data = fifo_dout[255:0];
    assign rd_frame_id = fifo_dout[256 +: FRAME_ID_WIDTH];
    assign rd_sof = fifo_dout[256 + FRAME_ID_WIDTH];
    assign rd_eol = fifo_dout[257 + FRAME_ID_WIDTH];
    assign rd_eof = fifo_dout[258 + FRAME_ID_WIDTH];
    assign rd_error = fifo_dout[259 + FRAME_ID_WIDTH];

    initial begin
        if ((FIFO_DEPTH & (FIFO_DEPTH-1)) != 0 || FIFO_DEPTH < 16)
            $error("display_frame_packer depth must be a power of two >= 16");
    end

    always @(posedge s_stream.aclk) begin
        if (!s_stream.aresetn) begin
            pair_count <= 0;
            pack_data <= 0;
            pack_sof <= 0;
            pack_error <= 0;
            pack_frame_id <= 0;
        end else if (accept) begin
            if (s_stream.sof || pair_count == 0) begin
                pack_data <= {192'd0, s_stream.data[31:0]};
                pack_sof <= s_stream.sof;
                pack_error <= s_stream.error;
                pack_frame_id <= s_stream.frame_id;
                pair_count <= 3'd1;
            end else if (commit) begin
                pair_count <= 0;
                pack_sof <= 0;
                pack_error <= 0;
            end else begin
                pack_data[pair_count*32 +: 32] <= s_stream.data[31:0];
                pack_error <= pack_error | s_stream.error | malformed;
                pair_count <= pair_count + 1'b1;
            end
        end
    end

`ifdef VERILATOR
    reg [PAYLOAD_WIDTH-1:0] sim_mem [0:FIFO_DEPTH-1];
    reg [$clog2(FIFO_DEPTH)-1:0] sim_wr_ptr, sim_rd_ptr;
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
