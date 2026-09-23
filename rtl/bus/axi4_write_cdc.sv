`timescale 1ns/1ps

// AXI4 write-only asynchronous bridge. AW and W remain ordered, while a
// pool of destination IDs lets completed bursts wait for B independently.
// Responses are collected by BID and retired in the original AW order.
module axi4_write_cdc #(
    parameter integer FIFO_ADDR_WIDTH = 4,
    parameter integer FBUS_WRITE_ID = -1,
    parameter integer FBUS_WRITE_ID_COUNT = 1
) (
    axi4_if.slave  s_axi,
    input  wire    m_clk,
    input  wire    m_resetn,
    axi4_if.master m_axi,
    output reg [31:0] perf_aw_count,
    output reg [31:0] perf_w_count,
    output reg [31:0] perf_b_count,
    output reg [31:0] perf_aw_stall_cycles,
    output reg [31:0] perf_w_stall_cycles,
    output reg [31:0] perf_b_stall_cycles,
    output reg [31:0] perf_outstanding_current,
    output reg [31:0] perf_outstanding_max,
    output reg [31:0] perf_write_id_mask,
    output reg [31:0] perf_protocol_errors
);
    localparam integer FIFO_DEPTH = 1 << FIFO_ADDR_WIDTH;
    localparam integer AW_WIDTH = 60;
    localparam integer W_WIDTH = 289;
    localparam integer B_WIDTH = 5;
    localparam integer SLOT_WIDTH = FBUS_WRITE_ID_COUNT <= 1 ?
                                    1 : $clog2(FBUS_WRITE_ID_COUNT);
    localparam integer ORDER_COUNT_WIDTH =
        $clog2(FBUS_WRITE_ID_COUNT + 1);

    wire [AW_WIDTH-1:0] aw_data;
    wire [W_WIDTH-1:0] w_data;
    wire [B_WIDTH-1:0] b_data;
    wire aw_s_ready, aw_m_valid, w_s_ready, w_m_valid;
    wire b_m_ready, b_s_valid;

    reg w_active;
    reg [SLOT_WIDTH-1:0] alloc_ptr;
    reg [SLOT_WIDTH-1:0] order_write_ptr, order_read_ptr;
    reg [ORDER_COUNT_WIDTH-1:0] order_count;
    reg [SLOT_WIDTH-1:0] order_fifo [0:FBUS_WRITE_ID_COUNT-1];
    reg id_busy [0:FBUS_WRITE_ID_COUNT-1];
    reg response_complete [0:FBUS_WRITE_ID_COUNT-1];
    reg [2:0] descriptor_awid [0:FBUS_WRITE_ID_COUNT-1];
    reg [1:0] descriptor_bresp [0:FBUS_WRITE_ID_COUNT-1];

    // Allocation and retirement both preserve AW order, so alloc_ptr always
    // names the next reusable slot. It changes only on an AW handshake, which
    // also keeps AWID stable throughout downstream backpressure.
    wire free_id_found = !id_busy[alloc_ptr];
    wire [SLOT_WIDTH-1:0] free_slot = alloc_ptr;

    wire response_id_at_or_above_base = FBUS_WRITE_ID == 0 ? 1'b1 :
        {1'b0, m_axi.bid} >= 6'(FBUS_WRITE_ID);
    wire response_id_below_limit =
        FBUS_WRITE_ID + FBUS_WRITE_ID_COUNT == 32 ? 1'b1 :
        {1'b0, m_axi.bid} < 6'(FBUS_WRITE_ID + FBUS_WRITE_ID_COUNT);
    wire response_id_in_range = FBUS_WRITE_ID < 0 ? 1'b1 :
        response_id_at_or_above_base && response_id_below_limit;
    wire [SLOT_WIDTH-1:0] response_slot = FBUS_WRITE_ID >= 0 ?
        SLOT_WIDTH'(m_axi.bid - $bits(m_axi.bid)'(FBUS_WRITE_ID)) : '0;
    wire response_slot_available = response_id_in_range &&
        id_busy[response_slot] && !response_complete[response_slot];
    wire response_invalid = m_axi.bvalid && !response_slot_available;
    wire [SLOT_WIDTH-1:0] retire_slot = order_fifo[order_read_ptr];
    wire retire_fire = order_count != 0 &&
        response_complete[retire_slot] && b_m_ready;

    wire s_aw_fire = s_axi.awvalid && s_axi.awready;
    wire s_w_fire = s_axi.wvalid && s_axi.wready;
    wire s_b_fire = s_axi.bvalid && s_axi.bready;
    wire m_aw_fire = m_axi.awvalid && m_axi.awready;
    wire m_w_fire = m_axi.wvalid && m_axi.wready;
    wire m_wlast_fire = m_w_fire && m_axi.wlast;
    wire m_b_fire = m_axi.bvalid && m_axi.bready;
    wire valid_b_fire = m_b_fire && response_slot_available;
    wire [31:0] outstanding_after_events =
        perf_outstanding_current + (m_aw_fire ? 32'd1 : 32'd0) -
        (valid_b_fire ? 32'd1 : 32'd0);

    function automatic [SLOT_WIDTH-1:0] next_slot_ptr(
        input [SLOT_WIDTH-1:0] pointer);
        if (pointer == SLOT_WIDTH'(FBUS_WRITE_ID_COUNT-1))
            next_slot_ptr = '0;
        else
            next_slot_ptr = pointer + 1'b1;
    endfunction

    initial begin
        if (FBUS_WRITE_ID_COUNT < 1 ||
            FBUS_WRITE_ID_COUNT > FIFO_DEPTH ||
            (FBUS_WRITE_ID_COUNT & (FBUS_WRITE_ID_COUNT-1)) != 0)
            $error("FBUS_WRITE_ID_COUNT must be a power of two within FIFO depth");
        if (FBUS_WRITE_ID >= 0 &&
            FBUS_WRITE_ID + FBUS_WRITE_ID_COUNT > 32)
            $error("FBus write ID range exceeds the 5-bit AXI ID space");
        if (FBUS_WRITE_ID < 0 && FBUS_WRITE_ID_COUNT != 1)
            $error("Multiple write IDs require a fixed destination ID base");
    end

    assign s_axi.arready = 1'b0;
    assign s_axi.rid = 3'd0;
    assign s_axi.rdata = 256'd0;
    assign s_axi.rresp = 2'b00;
    assign s_axi.rlast = 1'b0;
    assign s_axi.rvalid = 1'b0;
    assign s_axi.awready = aw_s_ready;
    assign s_axi.wready = w_s_ready;
    assign s_axi.bid = b_data[4:2];
    assign s_axi.bresp = b_data[1:0];
    assign s_axi.bvalid = b_s_valid;

    assign m_axi.aclk = m_clk;
    assign m_axi.aresetn = m_resetn;
    assign m_axi.awid = FBUS_WRITE_ID >= 0 ?
        $bits(m_axi.awid)'(FBUS_WRITE_ID) + $bits(m_axi.awid)'(free_slot) :
        $bits(m_axi.awid)'(aw_data[59:57]);
    // Coherent FBus reaches MIG DDR through Rocket's bit-31 alias.
    assign m_axi.awaddr = {1'b0, aw_data[56:25] | 32'h8000_0000};
    assign m_axi.awlen = aw_data[24:17];
    assign m_axi.awsize = aw_data[16:14];
    assign m_axi.awburst = aw_data[13:12];
    assign m_axi.awlock = aw_data[11];
    assign m_axi.awcache = aw_data[10:7];
    assign m_axi.awprot = aw_data[6:4];
    assign m_axi.awqos = aw_data[3:0];
    assign m_axi.awvalid = aw_m_valid && !w_active && free_id_found &&
                           order_count < ORDER_COUNT_WIDTH'(FBUS_WRITE_ID_COUNT);
    assign m_axi.wdata = w_data[288:33];
    assign m_axi.wstrb = w_data[32:1];
    assign m_axi.wlast = w_data[0];
    assign m_axi.wvalid = w_m_valid && w_active;
    // Consume an impossible BID so the external bus cannot deadlock; keep the
    // expected transaction allocated and expose the protocol error counter.
    assign m_axi.bready = response_slot_available || response_invalid;

    assign m_axi.arid = '0;
    assign m_axi.araddr = 33'd0;
    assign m_axi.arlen = 8'd0;
    assign m_axi.arsize = 3'd0;
    assign m_axi.arburst = 2'd0;
    assign m_axi.arlock = 1'b0;
    assign m_axi.arcache = 4'd0;
    assign m_axi.arprot = 3'd0;
    assign m_axi.arqos = 4'd0;
    assign m_axi.arvalid = 1'b0;
    assign m_axi.rready = 1'b0;

    cdc_payload_fifo #(
        .WIDTH(AW_WIDTH), .DEPTH(FIFO_DEPTH), .RELATED_CLOCKS(0)
    ) u_aw_fifo (
        .w_clk(s_axi.aclk), .w_resetn(s_axi.aresetn),
        .w_valid(s_axi.awvalid), .w_ready(aw_s_ready),
        .w_data({s_axi.awid, s_axi.awaddr, s_axi.awlen, s_axi.awsize,
                 s_axi.awburst, s_axi.awlock, s_axi.awcache, s_axi.awprot,
                 s_axi.awqos}),
        .r_clk(m_clk), .r_resetn(m_resetn), .r_valid(aw_m_valid),
        .r_ready(m_aw_fire), .r_data(aw_data)
    );

    cdc_payload_fifo #(
        .WIDTH(W_WIDTH), .DEPTH(FIFO_DEPTH), .RELATED_CLOCKS(0)
    ) u_w_fifo (
        .w_clk(s_axi.aclk), .w_resetn(s_axi.aresetn),
        .w_valid(s_axi.wvalid), .w_ready(w_s_ready),
        .w_data({s_axi.wdata, s_axi.wstrb, s_axi.wlast}),
        .r_clk(m_clk), .r_resetn(m_resetn), .r_valid(w_m_valid),
        .r_ready(m_w_fire), .r_data(w_data)
    );

    cdc_payload_fifo #(
        .WIDTH(B_WIDTH), .DEPTH(FIFO_DEPTH), .RELATED_CLOCKS(0)
    ) u_b_fifo (
        .w_clk(m_clk), .w_resetn(m_resetn),
        .w_valid(retire_fire), .w_ready(b_m_ready),
        .w_data({descriptor_awid[retire_slot],
                 descriptor_bresp[retire_slot]}),
        .r_clk(s_axi.aclk), .r_resetn(s_axi.aresetn),
        .r_valid(b_s_valid), .r_ready(s_axi.bready), .r_data(b_data)
    );

    integer slot_index;
    always @(posedge m_clk or negedge m_resetn) begin
        if (!m_resetn) begin
            w_active <= 1'b0;
            alloc_ptr <= '0;
            order_write_ptr <= '0;
            order_read_ptr <= '0;
            order_count <= '0;
            perf_aw_count <= 0;
            perf_w_count <= 0;
            perf_b_count <= 0;
            perf_aw_stall_cycles <= 0;
            perf_w_stall_cycles <= 0;
            perf_b_stall_cycles <= 0;
            perf_outstanding_current <= 0;
            perf_outstanding_max <= 0;
            perf_write_id_mask <= 0;
            perf_protocol_errors <= 0;
            for (slot_index = 0; slot_index < FBUS_WRITE_ID_COUNT;
                 slot_index = slot_index + 1) begin
                order_fifo[slot_index] <= '0;
                id_busy[slot_index] <= 1'b0;
                response_complete[slot_index] <= 1'b0;
                descriptor_awid[slot_index] <= 3'd0;
                descriptor_bresp[slot_index] <= 2'b00;
            end
        end else begin
            if (m_axi.awvalid && !m_axi.awready)
                perf_aw_stall_cycles <= perf_aw_stall_cycles + 1'b1;
            if (m_axi.wvalid && !m_axi.wready)
                perf_w_stall_cycles <= perf_w_stall_cycles + 1'b1;
            if (m_axi.bvalid && !m_axi.bready)
                perf_b_stall_cycles <= perf_b_stall_cycles + 1'b1;

            if (m_aw_fire) begin
                w_active <= 1'b1;
                alloc_ptr <= next_slot_ptr(free_slot);
                id_busy[free_slot] <= 1'b1;
                response_complete[free_slot] <= 1'b0;
                descriptor_awid[free_slot] <= aw_data[59:57];
                descriptor_bresp[free_slot] <= 2'b00;
                order_fifo[order_write_ptr] <= free_slot;
                order_write_ptr <= next_slot_ptr(order_write_ptr);
                perf_aw_count <= perf_aw_count + 1'b1;
                perf_write_id_mask[m_axi.awid] <= 1'b1;
            end
            if (m_w_fire) begin
                perf_w_count <= perf_w_count + 1'b1;
                if (m_axi.wlast)
                    w_active <= 1'b0;
            end
            if (valid_b_fire) begin
                response_complete[response_slot] <= 1'b1;
                descriptor_bresp[response_slot] <= m_axi.bresp;
                perf_b_count <= perf_b_count + 1'b1;
            end
            if (m_b_fire && !response_slot_available)
                perf_protocol_errors <= perf_protocol_errors + 1'b1;
            if (retire_fire) begin
                id_busy[retire_slot] <= 1'b0;
                response_complete[retire_slot] <= 1'b0;
                order_read_ptr <= next_slot_ptr(order_read_ptr);
            end

            case ({m_aw_fire, retire_fire})
                2'b10: order_count <= order_count + 1'b1;
                2'b01: order_count <= order_count - 1'b1;
                default: ;
            endcase
            case ({m_aw_fire, valid_b_fire})
                2'b10: perf_outstanding_current <=
                    perf_outstanding_current + 1'b1;
                2'b01: perf_outstanding_current <=
                    perf_outstanding_current - 1'b1;
                default: ;
            endcase
            if (perf_outstanding_max < outstanding_after_events)
                perf_outstanding_max <= outstanding_after_events;
        end
    end

    wire unused = &{1'b0, s_aw_fire, s_w_fire, s_b_fire, m_wlast_fire,
                    m_axi.rid, m_axi.rdata, m_axi.rresp, m_axi.rlast,
                    m_axi.rvalid};
endmodule
