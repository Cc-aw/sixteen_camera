`timescale 1ns/1ps

// Temporary P3 bridge from the new 150 MHz camera-video domain back to the
// still-300 MHz DDR writer.  P4 may absorb this boundary into its UI adapter.
module video_stream_cdc #(
    parameter integer FIFO_DEPTH = 1024,
    parameter integer STREAM_ID_WIDTH = 4,
    parameter integer FRAME_ID_WIDTH = 32
) (
    video_stream_if.sink   s_stream,
    input wire             m_clk,
    input wire             m_resetn,
    video_stream_if.source m_stream
);
    localparam integer WIDTH = 4 + 48 + STREAM_ID_WIDTH + FRAME_ID_WIDTH;
    localparam integer COUNT_WIDTH = $clog2(FIFO_DEPTH) + 1;
    wire [WIDTH-1:0] fifo_din = {
        s_stream.error, s_stream.frame_id, s_stream.stream_id,
        s_stream.eof, s_stream.eol, s_stream.sof, s_stream.data
    };
    wire [WIDTH-1:0] fifo_dout;
    wire fifo_full, fifo_empty, wr_busy, rd_busy;
    (* ASYNC_REG = "TRUE", SHREG_EXTRACT = "NO" *) reg [1:0] m_resetn_sync;
    (* ASYNC_REG = "TRUE", SHREG_EXTRACT = "NO" *) reg [1:0] fifo_reset_m_sync;
    reg [3:0] fifo_reset_pipe = 4'hf;
    wire fifo_reset = |fifo_reset_pipe;

    always @(posedge s_stream.aclk) begin
        m_resetn_sync <= {m_resetn_sync[0], m_resetn};
        if (!s_stream.aresetn || !m_resetn_sync[1])
            fifo_reset_pipe <= 4'hf;
        else
            fifo_reset_pipe <= {fifo_reset_pipe[2:0], 1'b0};
    end

    always @(posedge m_clk) begin
        if (!m_resetn)
            fifo_reset_m_sync <= 2'b11;
        else
            fifo_reset_m_sync <= {fifo_reset_m_sync[0], fifo_reset};
    end

    assign s_stream.ready = s_stream.aresetn && !fifo_reset &&
                            !fifo_full && !wr_busy;

`ifdef VERILATOR
    localparam integer PTR_WIDTH = $clog2(FIFO_DEPTH);
    reg [WIDTH-1:0] sim_mem [0:FIFO_DEPTH-1];
    reg [PTR_WIDTH:0] sim_wr_count;
    reg [PTR_WIDTH:0] sim_rd_count;
    wire sim_write = s_stream.valid && s_stream.ready;
    wire sim_read = m_stream.valid && m_stream.ready;
    assign fifo_full = ((sim_wr_count - sim_rd_count) ==
                        (PTR_WIDTH+1)'(FIFO_DEPTH));
    assign fifo_empty = (sim_wr_count == sim_rd_count);
    assign fifo_dout = sim_mem[sim_rd_count[PTR_WIDTH-1:0]];
    assign wr_busy = 1'b0;
    assign rd_busy = 1'b0;
    always @(posedge s_stream.aclk) begin
        if (fifo_reset)
            sim_wr_count <= 0;
        else if (sim_write) begin
            sim_mem[sim_wr_count[PTR_WIDTH-1:0]] <= fifo_din;
            sim_wr_count <= sim_wr_count + 1'b1;
        end
    end
    always @(posedge m_clk) begin
        if (!m_resetn || fifo_reset_m_sync[1])
            sim_rd_count <= 0;
        else if (sim_read)
            sim_rd_count <= sim_rd_count + 1'b1;
    end
`else
    xpm_fifo_async #(
        .CDC_SYNC_STAGES(2), .FIFO_MEMORY_TYPE("block"),
        .FIFO_READ_LATENCY(0), .FIFO_WRITE_DEPTH(FIFO_DEPTH),
        .READ_DATA_WIDTH(WIDTH), .READ_MODE("fwft"),
        .USE_ADV_FEATURES("0707"), .WRITE_DATA_WIDTH(WIDTH),
        .WR_DATA_COUNT_WIDTH(COUNT_WIDTH), .RD_DATA_COUNT_WIDTH(COUNT_WIDTH)
    ) u_stream_fifo (
        .rst(fifo_reset), .wr_clk(s_stream.aclk),
        .wr_en(s_stream.valid && s_stream.ready), .din(fifo_din),
        .full(fifo_full), .overflow(), .wr_rst_busy(wr_busy),
        .wr_data_count(), .almost_full(), .prog_full(), .wr_ack(),
        .rd_clk(m_clk), .rd_en(m_stream.valid && m_stream.ready),
        .dout(fifo_dout), .empty(fifo_empty), .data_valid(), .underflow(),
        .rd_rst_busy(rd_busy), .rd_data_count(), .almost_empty(),
        .prog_empty(), .sleep(1'b0), .injectsbiterr(1'b0),
        .injectdbiterr(1'b0), .sbiterr(), .dbiterr()
    );
`endif

    assign m_stream.aclk = m_clk;
    assign m_stream.aresetn = m_resetn;
    assign m_stream.valid = m_resetn && !fifo_reset_m_sync[1] &&
                            !fifo_empty && !rd_busy;
    assign {m_stream.error, m_stream.frame_id, m_stream.stream_id,
            m_stream.eof, m_stream.eol, m_stream.sof,
            m_stream.data} = fifo_dout;
endmodule
