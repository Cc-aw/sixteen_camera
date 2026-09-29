// Minimal FWFT model used only by camera_axis_cdc unit tests.
module xpm_fifo_async #(
    parameter integer CDC_SYNC_STAGES = 2,
    parameter FIFO_MEMORY_TYPE = "auto",
    parameter integer FIFO_READ_LATENCY = 0,
    parameter integer FIFO_WRITE_DEPTH = 16,
    parameter integer READ_DATA_WIDTH = 8,
    parameter READ_MODE = "fwft",
    parameter USE_ADV_FEATURES = "0000",
    parameter integer WRITE_DATA_WIDTH = 8,
    parameter integer WR_DATA_COUNT_WIDTH = 5,
    parameter integer RD_DATA_COUNT_WIDTH = 5
) (
    input wire rst, input wire wr_clk, input wire wr_en,
    input wire [WRITE_DATA_WIDTH-1:0] din, output wire full,
    output wire overflow, output wire wr_rst_busy,
    output wire [WR_DATA_COUNT_WIDTH-1:0] wr_data_count,
    output wire almost_full, output wire prog_full, output wire wr_ack,
    input wire rd_clk, input wire rd_en,
    output wire [READ_DATA_WIDTH-1:0] dout, output wire empty,
    output wire data_valid, output wire underflow, output wire rd_rst_busy,
    output wire [RD_DATA_COUNT_WIDTH-1:0] rd_data_count,
    output wire almost_empty, output wire prog_empty, input wire sleep,
    input wire injectsbiterr, input wire injectdbiterr,
    output wire sbiterr, output wire dbiterr
);
    localparam integer PTR_WIDTH = $clog2(FIFO_WRITE_DEPTH);
    reg [WRITE_DATA_WIDTH-1:0] mem [0:FIFO_WRITE_DEPTH-1];
    reg [PTR_WIDTH-1:0] wr_ptr = 0;
    reg [PTR_WIDTH-1:0] rd_ptr = 0;
    reg [WR_DATA_COUNT_WIDTH-1:0] count = 0;
    wire do_write = wr_en && !full;
    wire do_read = rd_en && !empty;
    assign full = (count == WR_DATA_COUNT_WIDTH'(FIFO_WRITE_DEPTH));
    assign empty = (count == 0);
    assign dout = mem[rd_ptr];
    assign wr_data_count = count;
    assign rd_data_count = RD_DATA_COUNT_WIDTH'(count);
    assign data_valid = !empty;
    assign overflow = wr_en && full;
    assign underflow = rd_en && empty;
    assign wr_rst_busy = 1'b0;
    assign rd_rst_busy = 1'b0;
    assign almost_full = 1'b0;
    assign prog_full = 1'b0;
    assign wr_ack = do_write;
    assign almost_empty = 1'b0;
    assign prog_empty = 1'b0;
    assign sbiterr = 1'b0;
    assign dbiterr = 1'b0;

    // The unit test connects wr_clk and rd_clk to the same clock.
    always @(posedge wr_clk) begin
        if (rst) begin
            wr_ptr <= 0;
            rd_ptr <= 0;
            count <= 0;
        end else begin
            if (do_write) begin
                mem[wr_ptr] <= din;
                wr_ptr <= wr_ptr + 1'b1;
            end
            if (do_read)
                rd_ptr <= rd_ptr + 1'b1;
            case ({do_write, do_read})
                2'b10: count <= count + 1'b1;
                2'b01: count <= count - 1'b1;
                default: ;
            endcase
        end
    end
    wire unused = &{1'b0, rd_clk, sleep, injectsbiterr, injectdbiterr,
                    CDC_SYNC_STAGES[0], FIFO_READ_LATENCY[0],
                    FIFO_MEMORY_TYPE[0], READ_MODE[0], USE_ADV_FEATURES[0]};
endmodule
