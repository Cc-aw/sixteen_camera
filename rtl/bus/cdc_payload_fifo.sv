`timescale 1ns/1ps

// Ready/valid payload FIFO for the related 150/300 MHz video/UI boundary.
// Reset is initiated in the write domain and observed in the read domain
// before either side is allowed to handshake.
module cdc_payload_fifo #(
    parameter integer WIDTH = 8,
    parameter integer DEPTH = 16
) (
    input  wire             w_clk,
    input  wire             w_resetn,
    input  wire             w_valid,
    output wire             w_ready,
    input  wire [WIDTH-1:0] w_data,
    input  wire             r_clk,
    input  wire             r_resetn,
    output wire             r_valid,
    input  wire             r_ready,
    output wire [WIDTH-1:0] r_data
);
    localparam integer COUNT_WIDTH = $clog2(DEPTH) + 1;
    wire fifo_full, fifo_empty, wr_busy, rd_busy;
    (* ASYNC_REG = "TRUE", SHREG_EXTRACT = "NO" *) reg [1:0]
        r_resetn_wsync = 2'b00;
    (* ASYNC_REG = "TRUE", SHREG_EXTRACT = "NO" *) reg [1:0]
        fifo_reset_rsync = 2'b11;
    reg [3:0] fifo_reset_pipe = 4'hf;
    wire fifo_reset = |fifo_reset_pipe;

    initial begin
        if (DEPTH < 16 || (DEPTH & (DEPTH-1)) != 0)
            $error("cdc_payload_fifo DEPTH must be a power of two >= 16");
    end

    always @(posedge w_clk) begin
        r_resetn_wsync <= {r_resetn_wsync[0], r_resetn};
        if (!w_resetn || !r_resetn_wsync[1])
            fifo_reset_pipe <= 4'hf;
        else
            fifo_reset_pipe <= {fifo_reset_pipe[2:0], 1'b0};
    end

    always @(posedge r_clk) begin
        if (!r_resetn)
            fifo_reset_rsync <= 2'b11;
        else
            fifo_reset_rsync <= {fifo_reset_rsync[0], fifo_reset};
    end

    assign w_ready = w_resetn && !fifo_reset && !fifo_full && !wr_busy;
    assign r_valid = r_resetn && !fifo_reset_rsync[1] &&
                     !fifo_empty && !rd_busy;

`ifdef VERILATOR
    localparam integer PTR_WIDTH = $clog2(DEPTH);
    reg [WIDTH-1:0] sim_mem [0:DEPTH-1];
    reg [PTR_WIDTH:0] sim_wr_count;
    reg [PTR_WIDTH:0] sim_rd_count;
    wire sim_write = w_valid && w_ready;
    wire sim_read = r_valid && r_ready;
    assign fifo_full = ((sim_wr_count - sim_rd_count) ==
                        (PTR_WIDTH+1)'(DEPTH));
    assign fifo_empty = (sim_wr_count == sim_rd_count);
    assign r_data = sim_mem[sim_rd_count[PTR_WIDTH-1:0]];
    assign wr_busy = 1'b0;
    assign rd_busy = 1'b0;
    always @(posedge w_clk) begin
        if (fifo_reset)
            sim_wr_count <= 0;
        else if (sim_write) begin
            sim_mem[sim_wr_count[PTR_WIDTH-1:0]] <= w_data;
            sim_wr_count <= sim_wr_count + 1'b1;
        end
    end
    always @(posedge r_clk) begin
        if (!r_resetn || fifo_reset_rsync[1])
            sim_rd_count <= 0;
        else if (sim_read)
            sim_rd_count <= sim_rd_count + 1'b1;
    end
`else
    xpm_fifo_async #(
        .CDC_SYNC_STAGES(2), .FIFO_MEMORY_TYPE("auto"),
        .FIFO_READ_LATENCY(0), .FIFO_WRITE_DEPTH(DEPTH),
        .READ_DATA_WIDTH(WIDTH), .READ_MODE("fwft"),
        .RELATED_CLOCKS(1), .USE_ADV_FEATURES("0707"),
        .WRITE_DATA_WIDTH(WIDTH),
        .WR_DATA_COUNT_WIDTH(COUNT_WIDTH),
        .RD_DATA_COUNT_WIDTH(COUNT_WIDTH)
    ) u_fifo (
        .rst(fifo_reset), .wr_clk(w_clk),
        .wr_en(w_valid && w_ready), .din(w_data),
        .full(fifo_full), .overflow(), .wr_rst_busy(wr_busy),
        .wr_data_count(), .almost_full(), .prog_full(), .wr_ack(),
        .rd_clk(r_clk), .rd_en(r_valid && r_ready), .dout(r_data),
        .empty(fifo_empty), .data_valid(), .underflow(),
        .rd_rst_busy(rd_busy), .rd_data_count(), .almost_empty(),
        .prog_empty(), .sleep(1'b0), .injectsbiterr(1'b0),
        .injectdbiterr(1'b0), .sbiterr(), .dbiterr()
    );
`endif
endmodule
