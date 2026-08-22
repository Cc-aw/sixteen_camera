`timescale 1ns/1ps

module ddr_axis_frame_reader #(
    parameter [31:0] FRAME_BASE_ADDR = 32'h0800_0000,
    parameter integer FRAME_WIDTH = 1920,
    parameter integer FRAME_HEIGHT = 1080,
    parameter integer FRAME_STRIDE_BYTES = FRAME_WIDTH * 4,
    parameter integer BURST_MAX_BEATS = 64,
    parameter integer FIFO_DEPTH = 1024
) (
    input  wire         clk,
    input  wire         resetn,
    input  wire         enable,

    output wire [2:0]   m_axi_arid,
    output wire [31:0]  m_axi_araddr,
    output wire [7:0]   m_axi_arlen,
    output wire [2:0]   m_axi_arsize,
    output wire [1:0]   m_axi_arburst,
    output wire         m_axi_arlock,
    output wire [3:0]   m_axi_arcache,
    output wire [2:0]   m_axi_arprot,
    output wire [3:0]   m_axi_arqos,
    output wire         m_axi_arvalid,
    input  wire         m_axi_arready,
    input  wire [2:0]   m_axi_rid,
    input  wire [255:0] m_axi_rdata,
    input  wire [1:0]   m_axi_rresp,
    input  wire         m_axi_rlast,
    input  wire         m_axi_rvalid,
    output wire         m_axi_rready,

    output wire [47:0]  m_axis_tdata,
    output wire         m_axis_tvalid,
    input  wire         m_axis_tready,
    output wire         m_axis_tuser,
    output wire         m_axis_tlast,

    output reg          axi_error,
    output reg          fifo_underflow,
    output wire [15:0]  debug_fifo_count
);
    localparam integer PIXELS_PER_DDR_BEAT = 8;
    localparam integer BYTES_PER_DDR_BEAT = 32;
    localparam integer LINE_DDR_BEATS = FRAME_WIDTH / PIXELS_PER_DDR_BEAT;
    localparam integer LINE_AXIS_BEATS = FRAME_WIDTH / 2;
    localparam integer FIFO_COUNT_WIDTH = $clog2(FIFO_DEPTH) + 1;
    localparam integer FIFO_START_LIMIT = FIFO_DEPTH - BURST_MAX_BEATS - 8;

    localparam [2:0] RD_IDLE  = 3'd0;
    localparam [2:0] RD_PREP  = 3'd1;
    localparam [2:0] RD_START = 3'd2;
    localparam [2:0] RD_WAIT  = 3'd3;
    localparam [2:0] RD_NEXT  = 3'd4;

    reg [2:0] rd_state;
    reg [15:0] rd_line;
    reg [15:0] rd_line_beat;
    reg [15:0] rd_burst_beats;
    reg rd_start;

    wire [31:0] next_addr = FRAME_BASE_ADDR +
                            rd_line * FRAME_STRIDE_BYTES +
                            rd_line_beat * BYTES_PER_DDR_BEAT;
    wire [15:0] line_beats_left = LINE_DDR_BEATS - rd_line_beat;
    wire [15:0] beats_to_4k = (16'h1000 - {4'd0, next_addr[11:0]}) /
                               BYTES_PER_DDR_BEAT;
    wire [15:0] line_limited = (line_beats_left > BURST_MAX_BEATS) ?
                               BURST_MAX_BEATS : line_beats_left;
    wire [15:0] planned_beats = (line_limited > beats_to_4k) ?
                                beats_to_4k : line_limited;

    wire rd_ready;
    wire rd_fifo_we;
    wire [255:0] rd_fifo_data;
    wire rd_done;
    wire [5:0] arid_full;
    wire [5:0] rid_full = {3'd0, m_axi_rid};

    wire [255:0] fifo_dout;
    wire fifo_full;
    wire fifo_empty;
    wire fifo_prog_full;
    wire [FIFO_COUNT_WIDTH-1:0] fifo_count;
    wire fifo_read;

    reg [255:0] axis_word;
    reg axis_word_valid;
    reg [1:0] axis_pair;
    reg [15:0] axis_x;
    reg [15:0] axis_y;
    wire axis_fire = m_axis_tvalid && m_axis_tready;
    wire load_next_word = (!axis_word_valid ||
                           (axis_fire && axis_pair == 2'd3)) && !fifo_empty;

    axi_master_read #(.AXI_QOS(4'hf)) u_axi_master_read (
        .ARESETN(resetn), .ACLK(clk),
        .M_AXI_ARID(arid_full), .M_AXI_ARADDR(m_axi_araddr),
        .M_AXI_ARLEN(m_axi_arlen), .M_AXI_ARSIZE(m_axi_arsize),
        .M_AXI_ARBURST(m_axi_arburst), .M_AXI_ARLOCK(),
        .M_AXI_ARCACHE(m_axi_arcache), .M_AXI_ARPROT(m_axi_arprot),
        .M_AXI_ARQOS(m_axi_arqos), .M_AXI_ARUSER(),
        .M_AXI_ARVALID(m_axi_arvalid), .M_AXI_ARREADY(m_axi_arready),
        .M_AXI_RID(rid_full), .M_AXI_RDATA(m_axi_rdata),
        .M_AXI_RRESP(m_axi_rresp), .M_AXI_RLAST(m_axi_rlast),
        .M_AXI_RUSER(1'b0), .M_AXI_RVALID(m_axi_rvalid),
        .M_AXI_RREADY(m_axi_rready),
        .RD_START(rd_start), .RD_ADRS(next_addr),
        .RD_LEN({16'd0, rd_burst_beats}), .RD_READY(rd_ready),
        .RD_FIFO_WE(rd_fifo_we), .RD_FIFO_DATA(rd_fifo_data),
        .RD_DONE(rd_done)
    );

    assign m_axi_arid = arid_full[2:0];
    assign m_axi_arlock = 1'b0;

    xpm_fifo_sync #(
        .FIFO_MEMORY_TYPE("block"),
        .ECC_MODE("no_ecc"),
        .FIFO_WRITE_DEPTH(FIFO_DEPTH),
        .WRITE_DATA_WIDTH(256),
        .READ_DATA_WIDTH(256),
        .READ_MODE("fwft"),
        .FIFO_READ_LATENCY(0),
        .PROG_FULL_THRESH(FIFO_START_LIMIT),
        .WR_DATA_COUNT_WIDTH(FIFO_COUNT_WIDTH),
        .RD_DATA_COUNT_WIDTH(FIFO_COUNT_WIDTH),
        .DOUT_RESET_VALUE("0"),
        .FULL_RESET_VALUE(0),
        .USE_ADV_FEATURES("0707"),
        .WAKEUP_TIME(0)
    ) u_read_fifo (
        .sleep(1'b0), .rst(!resetn),
        .wr_clk(clk), .wr_en(rd_fifo_we && !fifo_full),
        .din(rd_fifo_data), .full(fifo_full), .prog_full(fifo_prog_full),
        .wr_data_count(fifo_count), .overflow(), .wr_ack(),
        .almost_full(), .wr_rst_busy(), .injectsbiterr(1'b0),
        .injectdbiterr(1'b0), .sbiterr(), .dbiterr(),
        .rd_en(fifo_read), .dout(fifo_dout), .empty(fifo_empty),
        .rd_data_count(), .underflow(), .data_valid(),
        .almost_empty(), .prog_empty(), .rd_rst_busy()
    );

    assign fifo_read = load_next_word;
    assign debug_fifo_count = {{(16-FIFO_COUNT_WIDTH){1'b0}}, fifo_count};
    assign m_axis_tvalid = axis_word_valid;
    assign m_axis_tdata = {
        axis_word[axis_pair*64 + 32 +: 24],
        axis_word[axis_pair*64      +: 24]
    };
    assign m_axis_tuser = axis_word_valid && (axis_x == 0) && (axis_y == 0);
    assign m_axis_tlast = axis_word_valid && (axis_x == LINE_AXIS_BEATS-1);

    always @(posedge clk) begin
        if (!resetn) begin
            rd_state <= RD_IDLE;
            rd_line <= 0;
            rd_line_beat <= 0;
            rd_burst_beats <= 0;
            rd_start <= 1'b0;
            axi_error <= 1'b0;
        end else begin
            rd_start <= 1'b0;
            if (m_axi_rvalid && m_axi_rready && m_axi_rresp != 2'b00)
                axi_error <= 1'b1;
            if (rd_fifo_we && fifo_full)
                axi_error <= 1'b1;

            case (rd_state)
                RD_IDLE: begin
                    if (enable)
                        rd_state <= RD_PREP;
                end
                RD_PREP: begin
                    rd_burst_beats <= planned_beats;
                    rd_state <= RD_START;
                end
                RD_START: begin
                    if (rd_ready && !fifo_prog_full) begin
                        rd_start <= 1'b1;
                        rd_state <= RD_WAIT;
                    end
                end
                RD_WAIT: begin
                    if (rd_done)
                        rd_state <= RD_NEXT;
                end
                RD_NEXT: begin
                    if (rd_line_beat + rd_burst_beats >= LINE_DDR_BEATS) begin
                        rd_line_beat <= 0;
                        if (rd_line == FRAME_HEIGHT-1)
                            rd_line <= 0;
                        else
                            rd_line <= rd_line + 1'b1;
                    end else begin
                        rd_line_beat <= rd_line_beat + rd_burst_beats;
                    end
                    rd_state <= RD_PREP;
                end
                default: rd_state <= RD_IDLE;
            endcase
        end
    end

    always @(posedge clk) begin
        if (!resetn) begin
            axis_word <= 0;
            axis_word_valid <= 1'b0;
            axis_pair <= 0;
            axis_x <= 0;
            axis_y <= 0;
            fifo_underflow <= 1'b0;
        end else begin
            if (load_next_word) begin
                axis_word <= fifo_dout;
                axis_word_valid <= 1'b1;
                axis_pair <= 0;
            end else if (axis_fire) begin
                if (axis_pair == 2'd3) begin
                    axis_word_valid <= 1'b0;
                    axis_pair <= 0;
                    if (fifo_empty)
                        fifo_underflow <= 1'b1;
                end else begin
                    axis_pair <= axis_pair + 1'b1;
                end
            end

            if (axis_fire) begin
                if (axis_x == LINE_AXIS_BEATS-1) begin
                    axis_x <= 0;
                    if (axis_y == FRAME_HEIGHT-1)
                        axis_y <= 0;
                    else
                        axis_y <= axis_y + 1'b1;
                end else begin
                    axis_x <= axis_x + 1'b1;
                end
            end
        end
    end
endmodule
