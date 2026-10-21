`timescale 1ns/1ps

// Reads one CPU-selected XRGB8888 frame and emits RGB888, two pixels/beat.
// Fixed-ID AXI responses are consumed in issue order through a descriptor ring.
module ddr_frame_reader #(
    parameter integer BURST_MAX_BEATS = 64,
    parameter integer FIFO_DEPTH = 4096,
    parameter integer START_LEVEL = 128,
    parameter integer READ_OUTSTANDING = 8,
    parameter integer DESCRIPTOR_DEPTH = 8,
    parameter integer FIFO_SAFETY_MARGIN = 8
) (
    input  wire          clk,
    input  wire          resetn,
    output wire          buffer_acquire,
    input  wire          buffer_grant,
    input  wire [31:0]   buffer_base,
    output reg           buffer_done,
    input  wire [31:0]   frame_width,
    input  wire [31:0]   frame_height,
    input  wire [31:0]   frame_stride_bytes,

    axi4_if.master       m_axi,
    axis_video_if.source m_axis,
    output reg           axi_error,
    output reg           fifo_underflow,
    output wire [31:0]   debug_active_base,
    output wire [31:0]   debug_status
);
    localparam integer FIFO_COUNT_WIDTH = $clog2(FIFO_DEPTH) + 1;
    localparam integer DESC_PTR_WIDTH = (DESCRIPTOR_DEPTH <= 1) ?
                                        1 : $clog2(DESCRIPTOR_DEPTH);
    localparam integer DESC_COUNT_WIDTH = $clog2(DESCRIPTOR_DEPTH + 1);
    localparam [DESC_COUNT_WIDTH-1:0] DESC_DEPTH_VALUE =
        DESC_COUNT_WIDTH'(DESCRIPTOR_DEPTH);
    localparam [DESC_COUNT_WIDTH-1:0] READ_CREDIT_VALUE =
        DESC_COUNT_WIDTH'(READ_OUTSTANDING);

    localparam [2:0] RD_IDLE = 3'd0;
    localparam [2:0] RD_PLAN = 3'd1;
    localparam [2:0] RD_BOUNDARY = 3'd2;
    localparam [2:0] RD_FLAGS = 3'd3;
    localparam [2:0] RD_WAIT_CREDIT = 3'd4;
    localparam [2:0] RD_ISSUE = 3'd5;
    localparam [2:0] RD_DRAIN = 3'd6;
    localparam [2:0] RD_FETCH_DONE = 3'd7;

    reg active;
    reg [31:0] base_latched;
    reg [31:0] width_latched;
    reg [31:0] height_latched;
    reg [31:0] stride_latched;
    reg [2:0] rd_state;

    reg [31:0] plan_line;
    reg [31:0] plan_line_beat;
    reg [31:0] plan_line_addr;
    reg [31:0] plan_burst_addr;
    reg [31:0] reserved_return_beats;

    reg [31:0] ar_addr_q;
    reg [8:0] ar_beats_q;
    reg ar_finishes_line_q;
    reg ar_finishes_frame_q;

    reg [8:0] desc_beats [0:DESCRIPTOR_DEPTH-1];
    reg [DESC_PTR_WIDTH-1:0] desc_alloc_ptr;
    reg [DESC_PTR_WIDTH-1:0] desc_return_ptr;
    reg [DESC_COUNT_WIDTH-1:0] desc_count;
    reg [8:0] return_beat_index;

    wire [31:0] line_ddr_beats = width_latched >> 3;
    wire [31:0] line_axis_beats = width_latched >> 1;
    wire [31:0] plan_line_beats_left =
        line_ddr_beats - plan_line_beat;
    wire [31:0] plan_beats_to_4k =
        (32'h1000 - {20'd0, plan_burst_addr[11:0]}) >> 5;
    wire [31:0] plan_line_limited =
        (plan_line_beats_left > BURST_MAX_BEATS) ?
        BURST_MAX_BEATS : plan_line_beats_left;
    wire [8:0] plan_beats_to_4k_short = plan_beats_to_4k[8:0];
    wire [8:0] plan_line_limited_short = plan_line_limited[8:0];
    wire ar_finishes_line =
        (32'(ar_beats_q) == plan_line_beats_left);

    wire [255:0] fifo_dout;
    wire fifo_full;
    wire fifo_empty;
    wire [FIFO_COUNT_WIDTH-1:0] fifo_count;
    wire fifo_read;
    wire [31:0] fifo_committed_beats =
        32'(fifo_count) + reserved_return_beats;
    wire ar_fifo_credit_available =
        (fifo_committed_beats + 32'(ar_beats_q) +
         FIFO_SAFETY_MARGIN <= FIFO_DEPTH);

    wire ar_fire = m_axi.arvalid && m_axi.arready;
    wire r_fire = m_axi.rvalid && m_axi.rready;
    wire r_last_fire = r_fire && m_axi.rlast;
    wire descriptor_credit_available =
        (desc_count < DESC_DEPTH_VALUE || r_last_fire) &&
        (desc_count < READ_CREDIT_VALUE || r_last_fire);
    wire expected_r_last = (desc_count != 0) &&
        (return_beat_index == desc_beats[desc_return_ptr]-1'b1);
    wire read_protocol_error = r_fire &&
        ((m_axi.rid != 0) || (m_axi.rlast != expected_r_last));

    reg [255:0] axis_word;
    reg axis_word_valid;
    reg [1:0] axis_pair;
    reg [31:0] axis_x;
    reg [31:0] axis_y;
    reg output_started;
    reg underflow_active;
    reg displaying_active_buffer;

    wire axis_fire = m_axis.tvalid && m_axis.tready;
    wire frame_end_fire = axis_fire &&
                          (axis_x == line_axis_beats-1) &&
                          (axis_y == height_latched-1);
    wire prefetch_ready = (fifo_count >= START_LEVEL) ||
                          (rd_state == RD_FETCH_DONE);
    wire start_output = active && !displaying_active_buffer && prefetch_ready;
    wire load_next_word = active &&
                          (start_output || (displaying_active_buffer &&
                           (!axis_word_valid || (axis_fire &&
                            (axis_pair == 2'd3))))) &&
                          !fifo_empty;
    wire flush_stale_word = !active && !fifo_empty;
    wire [12:0] debug_fifo_count = fifo_count[12:0];

    function automatic [DESC_PTR_WIDTH-1:0] next_desc_ptr;
        input [DESC_PTR_WIDTH-1:0] pointer;
        begin
            if (pointer == DESC_PTR_WIDTH'(DESCRIPTOR_DEPTH-1))
                next_desc_ptr = {DESC_PTR_WIDTH{1'b0}};
            else
                next_desc_ptr = pointer + 1'b1;
        end
    endfunction

    assign buffer_acquire = !active && (rd_state == RD_IDLE) &&
                            fifo_empty && (desc_count == 0);
    assign m_axis.aclk = clk;
    assign m_axis.aresetn = resetn;
    assign m_axis.tvalid = displaying_active_buffer && axis_word_valid;
    assign m_axis.tdata = {
        axis_word[axis_pair*64 + 32 +: 24],
        axis_word[axis_pair*64      +: 24]
    };
    assign m_axis.tuser = m_axis.tvalid && (axis_x == 0) && (axis_y == 0);
    assign m_axis.tlast = m_axis.tvalid && (axis_x == line_axis_beats-1);
    assign debug_active_base = base_latched;
    assign debug_status = {axi_error, active, displaying_active_buffer,
                           output_started, rd_state, debug_fifo_count,
                           axis_pair, plan_line[9:0]};

    assign m_axi.aclk = clk;
    assign m_axi.aresetn = resetn;
    assign m_axi.arid = 3'd0;
    assign m_axi.araddr = ar_addr_q;
    assign m_axi.arlen = ar_beats_q[7:0] - 1'b1;
    assign m_axi.arsize = 3'b101;
    assign m_axi.arburst = 2'b01;
    assign m_axi.arlock = 1'b0;
    assign m_axi.arcache = 4'b0010;
    assign m_axi.arprot = 3'b000;
    assign m_axi.arqos = 4'hf;
    assign m_axi.arvalid = (rd_state == RD_ISSUE);
    assign m_axi.rready = (desc_count != 0) && !fifo_full;

    assign m_axi.awid = 3'd0;
    assign m_axi.awaddr = 32'd0;
    assign m_axi.awlen = 8'd0;
    assign m_axi.awsize = 3'b101;
    assign m_axi.awburst = 2'b01;
    assign m_axi.awlock = 1'b0;
    assign m_axi.awcache = 4'd0;
    assign m_axi.awprot = 3'd0;
    assign m_axi.awqos = 4'd0;
    assign m_axi.awvalid = 1'b0;
    assign m_axi.wdata = 256'd0;
    assign m_axi.wstrb = 32'd0;
    assign m_axi.wlast = 1'b0;
    assign m_axi.wvalid = 1'b0;
    assign m_axi.bready = 1'b0;

`ifdef VERILATOR
    reg [255:0] sim_fifo [0:FIFO_DEPTH-1];
    reg [$clog2(FIFO_DEPTH)-1:0] sim_wr_ptr;
    reg [$clog2(FIFO_DEPTH)-1:0] sim_rd_ptr;
    reg [FIFO_COUNT_WIDTH-1:0] sim_fifo_count;
    assign fifo_dout = sim_fifo[sim_rd_ptr];
    assign fifo_full = (sim_fifo_count == FIFO_COUNT_WIDTH'(FIFO_DEPTH));
    assign fifo_empty = (sim_fifo_count == 0);
    assign fifo_count = sim_fifo_count;
    always @(posedge clk) begin
        if (!resetn) begin
            sim_wr_ptr <= 0;
            sim_rd_ptr <= 0;
            sim_fifo_count <= 0;
        end else begin
            if (r_fire) begin
                sim_fifo[sim_wr_ptr] <= m_axi.rdata;
                sim_wr_ptr <= sim_wr_ptr + 1'b1;
            end
            if (fifo_read)
                sim_rd_ptr <= sim_rd_ptr + 1'b1;
            case ({r_fire, fifo_read})
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
        .PROG_FULL_THRESH(FIFO_DEPTH-BURST_MAX_BEATS-FIFO_SAFETY_MARGIN),
        .WR_DATA_COUNT_WIDTH(FIFO_COUNT_WIDTH),
        .RD_DATA_COUNT_WIDTH(FIFO_COUNT_WIDTH), .DOUT_RESET_VALUE("0"),
        .FULL_RESET_VALUE(0), .USE_ADV_FEATURES("0707"), .WAKEUP_TIME(0)
    ) u_read_fifo (
        .sleep(1'b0), .rst(!resetn), .wr_clk(clk),
        .wr_en(r_fire), .din(m_axi.rdata),
        .full(fifo_full), .prog_full(),
        .wr_data_count(fifo_count), .overflow(), .wr_ack(), .almost_full(),
        .wr_rst_busy(), .injectsbiterr(1'b0), .injectdbiterr(1'b0),
        .sbiterr(), .dbiterr(), .rd_en(fifo_read), .dout(fifo_dout),
        .empty(fifo_empty), .rd_data_count(), .underflow(), .data_valid(),
        .almost_empty(), .prog_empty(), .rd_rst_busy()
    );
`endif
    assign fifo_read = load_next_word || flush_stale_word;

    initial begin
        if ((FIFO_DEPTH & (FIFO_DEPTH-1)) != 0 ||
            FIFO_DEPTH < BURST_MAX_BEATS+FIFO_SAFETY_MARGIN ||
            START_LEVEL >= FIFO_DEPTH || BURST_MAX_BEATS < 1 ||
            BURST_MAX_BEATS > 128 || READ_OUTSTANDING < 1 ||
            READ_OUTSTANDING > DESCRIPTOR_DEPTH || DESCRIPTOR_DEPTH < 1)
            $error("ddr_frame_reader parameters are invalid");
    end

    always @(posedge clk) begin
        if (!resetn) begin
            active <= 1'b0;
            base_latched <= 32'd0;
            width_latched <= 32'd0;
            height_latched <= 32'd0;
            stride_latched <= 32'd0;
            rd_state <= RD_IDLE;
            plan_line <= 32'd0;
            plan_line_beat <= 32'd0;
            plan_line_addr <= 32'd0;
            plan_burst_addr <= 32'd0;
            reserved_return_beats <= 32'd0;
            ar_addr_q <= 32'd0;
            ar_beats_q <= 9'd0;
            ar_finishes_line_q <= 1'b0;
            ar_finishes_frame_q <= 1'b0;
            desc_alloc_ptr <= {DESC_PTR_WIDTH{1'b0}};
            desc_return_ptr <= {DESC_PTR_WIDTH{1'b0}};
            desc_count <= {DESC_COUNT_WIDTH{1'b0}};
            return_beat_index <= 9'd0;
            axi_error <= 1'b0;
        end else begin
            if (frame_end_fire && displaying_active_buffer)
                active <= 1'b0;

            case ({ar_fire, r_last_fire})
                2'b10: desc_count <= desc_count + 1'b1;
                2'b01: desc_count <= desc_count - 1'b1;
                default: ;
            endcase
            case ({ar_fire, r_fire})
                2'b10: reserved_return_beats <=
                    reserved_return_beats + ar_beats_q;
                2'b01: if (reserved_return_beats != 0)
                    reserved_return_beats <= reserved_return_beats - 1'b1;
                2'b11: reserved_return_beats <=
                    reserved_return_beats + ar_beats_q - 1'b1;
                default: ;
            endcase

            if (ar_fire) begin
                desc_beats[desc_alloc_ptr] <= ar_beats_q;
                desc_alloc_ptr <= next_desc_ptr(desc_alloc_ptr);
                if (ar_finishes_frame_q) begin
                    rd_state <= RD_DRAIN;
                end else if (ar_finishes_line_q) begin
                    plan_line <= plan_line + 1'b1;
                    plan_line_beat <= 32'd0;
                    plan_line_addr <= plan_line_addr + stride_latched;
                    plan_burst_addr <= plan_line_addr + stride_latched;
                    rd_state <= RD_PLAN;
                end else begin
                    plan_line_beat <= plan_line_beat + ar_beats_q;
                    plan_burst_addr <= plan_burst_addr +
                                       {18'd0, ar_beats_q, 5'b0};
                    rd_state <= RD_PLAN;
                end
            end

            if (r_last_fire) begin
                desc_return_ptr <= next_desc_ptr(desc_return_ptr);
                return_beat_index <= 9'd0;
                if ((rd_state == RD_DRAIN) && (desc_count == 1))
                    rd_state <= RD_FETCH_DONE;
            end else if (r_fire) begin
                return_beat_index <= return_beat_index + 1'b1;
            end

            if (read_protocol_error ||
                (r_fire && (m_axi.rresp != 2'b00)))
                axi_error <= 1'b1;

            case (rd_state)
                RD_IDLE: begin
                    if (buffer_grant) begin
                        active <= 1'b1;
                        base_latched <= buffer_base;
                        width_latched <= frame_width;
                        height_latched <= frame_height;
                        stride_latched <= frame_stride_bytes;
                        plan_line <= 32'd0;
                        plan_line_beat <= 32'd0;
                        plan_line_addr <= buffer_base;
                        plan_burst_addr <= buffer_base;
                        reserved_return_beats <= 32'd0;
                        axi_error <= 1'b0;
                        rd_state <= RD_PLAN;
                    end
                end
                RD_PLAN: begin
                    if (plan_line_limited_short != 0) begin
                        ar_addr_q <= plan_burst_addr;
                        ar_beats_q <= plan_line_limited_short;
                        rd_state <= RD_BOUNDARY;
                    end
                end
                RD_BOUNDARY: begin
                    if (ar_beats_q > plan_beats_to_4k_short)
                        ar_beats_q <= plan_beats_to_4k_short;
                    rd_state <= RD_FLAGS;
                end
                RD_FLAGS: begin
                    ar_finishes_line_q <= ar_finishes_line;
                    ar_finishes_frame_q <= ar_finishes_line &&
                                           (plan_line == height_latched-1);
                    rd_state <= RD_WAIT_CREDIT;
                end
                RD_WAIT_CREDIT: begin
                    if (descriptor_credit_available &&
                        ar_fifo_credit_available)
                        rd_state <= RD_ISSUE;
                end
                RD_FETCH_DONE: begin
                    if (!active)
                        rd_state <= RD_IDLE;
                end
                default: ;
            endcase
        end
    end

    always @(posedge clk) begin
        if (!resetn) begin
            axis_word <= 256'd0;
            axis_word_valid <= 1'b0;
            axis_pair <= 2'd0;
            axis_x <= 32'd0;
            axis_y <= 32'd0;
            output_started <= 1'b0;
            underflow_active <= 1'b0;
            displaying_active_buffer <= 1'b0;
            buffer_done <= 1'b0;
            fifo_underflow <= 1'b0;
        end else begin
            buffer_done <= 1'b0;
            fifo_underflow <= 1'b0;

            if (start_output) begin
                output_started <= 1'b1;
                displaying_active_buffer <= 1'b1;
            end

            if (load_next_word) begin
                axis_word <= fifo_dout;
                axis_word_valid <= 1'b1;
                axis_pair <= 2'd0;
                underflow_active <= 1'b0;
            end else if (axis_fire) begin
                if (axis_pair != 2'd3)
                    axis_pair <= axis_pair + 1'b1;
                else
                    axis_word_valid <= 1'b0;
            end

            if (output_started && displaying_active_buffer &&
                (!axis_word_valid ||
                (axis_fire && axis_word_valid &&
                 (axis_pair == 2'd3) && fifo_empty)) &&
                !frame_end_fire && !underflow_active) begin
                fifo_underflow <= 1'b1;
                underflow_active <= 1'b1;
            end

            if (axis_fire) begin
                if (axis_x == line_axis_beats-1) begin
                    axis_x <= 32'd0;
                    if (axis_y == height_latched-1) begin
                        axis_y <= 32'd0;
                        if (displaying_active_buffer) begin
                            buffer_done <= 1'b1;
                            displaying_active_buffer <= 1'b0;
                        end
                    end else
                        axis_y <= axis_y + 1'b1;
                end else
                    axis_x <= axis_x + 1'b1;
            end
        end
    end

    wire unused = &{1'b0, m_axi.bid, m_axi.bresp, m_axi.bvalid,
                    plan_line_addr};
endmodule
