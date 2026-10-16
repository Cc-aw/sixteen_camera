`timescale 1ns/1ps

// Splits the SoC memory AXI into unchanged DDR traffic and six local Head
// slots. Bit 31 is ignored only for Head decode, matching the Rocket CPU DDR
// alias. DDR requests remain pipelined independently in both directions.
// Legacy reads drain DDR globally. READ_DECOUPLE uses per-ID destination
// ownership, request queues and independent registered response channels.
module axi4_head_uram_router_v3 #(
    parameter integer ADDR_WIDTH = 33,
    parameter integer DATA_WIDTH = 256,
    parameter integer LOCAL_DATA_WIDTH = 256,
    parameter integer ID_WIDTH = 4,
    parameter integer DDR_OUTSTANDING = 32,
    parameter bit READ_DECOUPLE = 1'b0,
    parameter integer READ_QUEUE_DEPTH_PER_ID = 8,
    parameter integer READ_ACCEPT_LIMIT = 32,
    // P3 integration mode: Head writes are committed to both DDR and URAM,
    // AXI reads remain DDR-backed, and only the dedicated local port reads
    // URAM.  DDR therefore remains a live, software-selectable fallback.
    parameter bit SHADOW_DDR = 1'b0,
    parameter integer HEAD_BANK_COUNT = 6,
    parameter integer SLOT_BYTES = 1024 * 1024,
    parameter [HEAD_BANK_COUNT*ADDR_WIDTH-1:0] HEAD_BASE_ADDRS = {
        33'h0_3290_0000,
        33'h0_3280_0000,
        33'h0_3250_0000,
        33'h0_3240_0000,
        33'h0_3210_0000,
        33'h0_3200_0000
    }
) (
    input  wire                         clk,
    input  wire                         resetn,
    axi4_if.slave                       s_axi,
    axi4_if.master                      m_ddr_axi,

    input  wire [$clog2(HEAD_BANK_COUNT)-1:0] local_read_bank,
    input  wire                         local_read_req_valid,
    output wire                         local_read_req_ready,
    input  wire [$clog2(SLOT_BYTES/(LOCAL_DATA_WIDTH/8))-1:0]
                                             local_read_req_word_addr,
    output wire [LOCAL_DATA_WIDTH-1:0]  local_read_rsp_data,
    output wire                         local_read_rsp_valid,
    input  wire                         local_read_rsp_ready,
    output wire [31:0]                  perf_events
);
    localparam bit DECOUPLED = READ_DECOUPLE && !SHADOW_DDR;
    localparam integer LOCAL_RATIO = DATA_WIDTH / LOCAL_DATA_WIDTH;
    localparam integer LOCAL_SHIFT = $clog2(LOCAL_RATIO);
    localparam integer HALF_BITS = (LOCAL_SHIFT == 0) ? 1 : LOCAL_SHIFT;
    reg [HALF_BITS-1:0] local_half_q;
    localparam integer BYTE_LANES = DATA_WIDTH / 8;
    localparam integer BYTE_SHIFT = $clog2(BYTE_LANES);
    localparam integer OFFSET_WIDTH = $clog2(SLOT_BYTES);
    localparam integer WORD_ADDR_WIDTH =
        $clog2(SLOT_BYTES / BYTE_LANES);
    localparam integer BANK_WIDTH = $clog2(HEAD_BANK_COUNT);
    localparam integer DDR_COUNT_WIDTH = $clog2(DDR_OUTSTANDING + 1);

    localparam [2:0] W_IDLE = 3'd0;
    localparam [2:0] W_DDR_DATA = 3'd1;
    localparam [2:0] W_DDR_RESP = 3'd2;
    localparam [2:0] W_HEAD_DATA = 3'd3;
    localparam [2:0] W_ERROR_DATA = 3'd4;
    localparam [2:0] W_LOCAL_RESP = 3'd5;
    localparam [2:0] R_IDLE = 3'd0;
    localparam [2:0] R_DDR_DATA = 3'd1;
    localparam [2:0] R_HEAD_DATA = 3'd2;
    localparam [2:0] R_ERROR_DATA = 3'd3;

    function automatic [ADDR_WIDTH-1:0] canonical_addr(
        input [ADDR_WIDTH-1:0] address);
        begin
            canonical_addr = address;
            canonical_addr[31] = 1'b0;
        end
    endfunction

    function automatic integer decode_head_bank(
        input [ADDR_WIDTH-1:0] address);
        reg [ADDR_WIDTH-1:0] canonical;
        reg [ADDR_WIDTH-1:0] bank_base;
        begin
            canonical = canonical_addr(address);
            decode_head_bank = -1;
            for (integer bank = 0; bank < HEAD_BANK_COUNT;
                 bank = bank + 1) begin
                bank_base = HEAD_BASE_ADDRS[bank*ADDR_WIDTH +: ADDR_WIDTH];
                if (canonical >= bank_base &&
                    canonical < bank_base + ADDR_WIDTH'(SLOT_BYTES))
                    decode_head_bank = bank;
            end
        end
    endfunction

    function automatic [ADDR_WIDTH:0] burst_end_exclusive(
        input [ADDR_WIDTH-1:0] address,
        input [7:0] length,
        input [2:0] size,
        input [1:0] burst);
        reg [ADDR_WIDTH:0] transfer_bytes;
        begin
            transfer_bytes = (ADDR_WIDTH+1)'(1) << size;
            if (burst == 2'b01)
                burst_end_exclusive = {1'b0, canonical_addr(address)} +
                    transfer_bytes * (ADDR_WIDTH+1)'({1'b0, length} + 1'b1);
            else
                burst_end_exclusive = {1'b0, canonical_addr(address)} +
                    transfer_bytes;
        end
    endfunction

    integer aw_bank_decode;
    integer ar_bank_decode;
    reg aw_head_valid;
    reg ar_head_valid;
    reg [ADDR_WIDTH-1:0] aw_bank_base;
    reg [ADDR_WIDTH-1:0] ar_bank_base;
    reg [ADDR_WIDTH:0] aw_end;
    reg [ADDR_WIDTH:0] ar_end;
    always @* begin
        aw_bank_decode = decode_head_bank(s_axi.awaddr);
        ar_bank_decode = decode_head_bank(s_axi.araddr);
        aw_bank_base = '0;
        ar_bank_base = '0;
        if (aw_bank_decode >= 0)
            aw_bank_base = HEAD_BASE_ADDRS[
                aw_bank_decode*ADDR_WIDTH +: ADDR_WIDTH];
        if (ar_bank_decode >= 0)
            ar_bank_base = HEAD_BASE_ADDRS[
                ar_bank_decode*ADDR_WIDTH +: ADDR_WIDTH];
        aw_end = burst_end_exclusive(s_axi.awaddr, s_axi.awlen,
                                     s_axi.awsize, s_axi.awburst);
        ar_end = burst_end_exclusive(s_axi.araddr, s_axi.arlen,
                                     s_axi.arsize, s_axi.arburst);
        aw_head_valid = aw_bank_decode >= 0 &&
            s_axi.awsize <= 3'(BYTE_SHIFT) &&
            (s_axi.awburst == 2'b00 || s_axi.awburst == 2'b01) &&
            aw_end <= {1'b0, aw_bank_base} + (ADDR_WIDTH+1)'(SLOT_BYTES);
        ar_head_valid = ar_bank_decode >= 0 &&
            s_axi.arsize <= 3'(BYTE_SHIFT) &&
            (s_axi.arburst == 2'b00 || s_axi.arburst == 2'b01) &&
            ar_end <= {1'b0, ar_bank_base} + (ADDR_WIDTH+1)'(SLOT_BYTES);
    end

    reg [2:0] write_state;
    reg [BANK_WIDTH-1:0] write_bank_q;
    reg [ID_WIDTH-1:0] write_id_q;
    reg [ADDR_WIDTH-1:0] write_addr_q;
    reg [2:0] write_size_q;
    reg [1:0] write_burst_q;
    reg [8:0] write_beats_q;
    reg write_error_q;
    reg [1:0] local_bresp_q;

    reg [2:0] read_state;
    reg [BANK_WIDTH-1:0] read_bank_q;
    reg [ID_WIDTH-1:0] read_id_q;
    reg [ADDR_WIDTH-1:0] read_addr_q;
    reg [2:0] read_size_q;
    reg [1:0] read_burst_q;
    reg [8:0] read_issue_beats_q;
    reg [8:0] read_return_beats_q;

    // AW-to-B credits and AW-to-WLAST data obligations are different: a new
    // address need not wait for either the preceding data burst or its B.
    // AXI4 W ordering is supplied by the upstream master and the DDR endpoint.
    reg [DDR_COUNT_WIDTH-1:0] ddr_write_pending;
    reg [DDR_COUNT_WIDTH-1:0] ddr_write_data_pending;
    reg [DDR_COUNT_WIDTH-1:0] ddr_read_pending;
    wire ddr_write_room = ddr_write_pending < DDR_COUNT_WIDTH'(DDR_OUTSTANDING);
    wire ddr_read_room = ddr_read_pending < DDR_COUNT_WIDTH'(DDR_OUTSTANDING);
    wire ddr_write_response = !SHADOW_DDR && write_state == W_IDLE &&
                              ddr_write_pending != 0;
    wire ddr_read_response = !SHADOW_DDR && read_state == R_IDLE &&
                             ddr_read_pending != 0;

    wire [HEAD_BANK_COUNT-1:0] bank_write_ready;
    wire [HEAD_BANK_COUNT-1:0] bank_read_req_ready;
    wire [HEAD_BANK_COUNT-1:0] bank_read_rsp_valid;
    wire [DATA_WIDTH-1:0] bank_read_rsp_data [0:HEAD_BANK_COUNT-1];
    wire [HEAD_BANK_COUNT-1:0] bank_read_req_valid;
    wire [HEAD_BANK_COUNT-1:0] bank_read_rsp_ready;
    wire [WORD_ADDR_WIDTH-1:0] bank_read_req_addr [0:HEAD_BANK_COUNT-1];

    wire aw_is_head = aw_bank_decode >= 0;
    wire ar_is_head = ar_bank_decode >= 0;
    wire aw_fire = s_axi.awvalid && s_axi.awready;
    wire w_fire = s_axi.wvalid && s_axi.wready;
    wire b_fire = s_axi.bvalid && s_axi.bready;
    wire ar_fire = s_axi.arvalid && s_axi.arready;
    wire r_fire = s_axi.rvalid && s_axi.rready;
    wire write_expected_last = write_beats_q == 1;
    wire write_finish = w_fire && (write_expected_last || s_axi.wlast);
    wire write_last_mismatch = s_axi.wlast != write_expected_last;

    wire head_read_request = read_state == R_HEAD_DATA &&
                             read_issue_beats_q != 0;
    wire head_read_req_ready = bank_read_req_ready[read_bank_q];
    wire head_read_req_fire = head_read_request && head_read_req_ready;
    wire head_read_rsp_valid = bank_read_rsp_valid[read_bank_q];
    wire head_read_rsp_fire = read_state == R_HEAD_DATA &&
                              head_read_rsp_valid && s_axi.rready;

    reg local_read_outstanding;
    reg [BANK_WIDTH-1:0] local_read_bank_q;
    wire local_bank_in_range =
        (BANK_WIDTH+1)'(local_read_bank) < (BANK_WIDTH+1)'(HEAD_BANK_COUNT);
    wire local_read_rsp_valid_i = local_read_outstanding &&
        bank_read_rsp_valid[local_read_bank_q];
    wire local_read_rsp_fire = local_read_rsp_valid_i &&
                               local_read_rsp_ready;
    wire dec_local_active, dec_local_claim, dec_req_valid, dec_rsp_ready;
    wire [BANK_WIDTH-1:0] dec_bank;
    wire [WORD_ADDR_WIDTH-1:0] dec_word_addr;
    wire head_active = DECOUPLED ? dec_local_active : read_state == R_HEAD_DATA;
    wire head_ar_claim = DECOUPLED ? dec_local_claim : read_state == R_IDLE && s_axi.arvalid && ar_is_head &&
                         (SHADOW_DDR || ddr_read_pending == 0);
    wire local_slot_available = !local_read_outstanding || local_read_rsp_fire;
    wire local_may_request = !head_active &&
                             !head_ar_claim && local_slot_available &&
                             local_bank_in_range;
    assign local_read_req_ready = local_may_request &&
        bank_read_req_ready[local_read_bank];
    wire local_read_req_fire = local_read_req_valid &&
                               local_read_req_ready;
    assign local_read_rsp_valid = local_read_rsp_valid_i;
    assign local_read_rsp_data =
        bank_read_rsp_data[local_read_bank_q][local_half_q*LOCAL_DATA_WIDTH +: LOCAL_DATA_WIDTH];

    assign perf_events = {24'd0,
        (local_read_req_valid && !local_read_req_ready),
        (local_read_rsp_valid && !local_read_rsp_ready),
        local_read_rsp_fire, local_read_req_fire,
        (s_axi.arvalid && ar_is_head && ddr_read_pending != 0),
        (s_axi.awvalid && aw_is_head && ddr_write_pending != 0),
        (ar_fire && ar_is_head), (aw_fire && aw_is_head)};

    genvar bank_index;
    generate
        for (bank_index = 0; bank_index < HEAD_BANK_COUNT;
             bank_index = bank_index + 1) begin : g_head_bank
            localparam [BANK_WIDTH-1:0] BANK = BANK_WIDTH'(bank_index);
            wire selected_write = write_state == W_HEAD_DATA &&
                                  write_bank_q == BANK;
            wire selected_head_read = head_active &&
                (DECOUPLED ? dec_bank : read_bank_q) == BANK;
            wire selected_local_read = local_may_request &&
                                       local_read_bank == BANK;
            assign bank_read_req_valid[bank_index] =
                selected_head_read ? (DECOUPLED ? dec_req_valid : head_read_request) :
                selected_local_read ? local_read_req_valid : 1'b0;
            assign bank_read_req_addr[bank_index] = selected_head_read ?
                (DECOUPLED ? dec_word_addr : read_addr_q[OFFSET_WIDTH-1:BYTE_SHIFT]) :
                WORD_ADDR_WIDTH'(local_read_req_word_addr >> LOCAL_SHIFT);
            assign bank_read_rsp_ready[bank_index] = selected_head_read ?
                (DECOUPLED ? dec_rsp_ready : s_axi.rready) :
                (local_read_outstanding && local_read_bank_q == BANK) ?
                    local_read_rsp_ready : 1'b0;

            head_uram_store #(
                .DATA_WIDTH(DATA_WIDTH), .SLOT_BYTES(SLOT_BYTES)
            ) u_store (
                .clk(clk), .resetn(resetn),
                .write_valid(selected_write && s_axi.wvalid &&
                             (!SHADOW_DDR || m_ddr_axi.wready)),
                .write_ready(bank_write_ready[bank_index]),
                .write_addr(write_addr_q[OFFSET_WIDTH-1:0]),
                .write_data(s_axi.wdata), .write_strb(s_axi.wstrb),
                .read_req_valid(bank_read_req_valid[bank_index]),
                .read_req_ready(bank_read_req_ready[bank_index]),
                .read_req_word_addr(bank_read_req_addr[bank_index]),
                .read_rsp_data(bank_read_rsp_data[bank_index]),
                .read_rsp_valid(bank_read_rsp_valid[bank_index]),
                .read_rsp_ready(bank_read_rsp_ready[bank_index])
            );
        end
    endgenerate

    assign m_ddr_axi.aclk = clk;
    assign m_ddr_axi.aresetn = resetn;
    assign m_ddr_axi.awid = s_axi.awid;
    assign m_ddr_axi.awaddr = s_axi.awaddr;
    assign m_ddr_axi.awlen = s_axi.awlen;
    assign m_ddr_axi.awsize = s_axi.awsize;
    assign m_ddr_axi.awburst = s_axi.awburst;
    assign m_ddr_axi.awlock = s_axi.awlock;
    assign m_ddr_axi.awcache = s_axi.awcache;
    assign m_ddr_axi.awprot = s_axi.awprot;
    assign m_ddr_axi.awqos = s_axi.awqos;
    assign m_ddr_axi.awvalid = write_state == W_IDLE && s_axi.awvalid &&
                               (!aw_is_head || SHADOW_DDR) &&
                               (SHADOW_DDR || ddr_write_room);
    assign s_axi.awready = write_state == W_IDLE &&
        (aw_is_head && !SHADOW_DDR ? ddr_write_pending == 0 :
         m_ddr_axi.awready && (SHADOW_DDR || ddr_write_room));

    assign m_ddr_axi.wdata = s_axi.wdata;
    assign m_ddr_axi.wstrb = s_axi.wstrb;
    assign m_ddr_axi.wlast = s_axi.wlast;
    assign m_ddr_axi.wvalid =
        (!SHADOW_DDR && write_state == W_IDLE &&
         ddr_write_data_pending != 0 && s_axi.wvalid) ||
        (write_state == W_DDR_DATA && s_axi.wvalid) ||
        (write_state == W_HEAD_DATA && SHADOW_DDR && s_axi.wvalid &&
         bank_write_ready[write_bank_q]);
    assign s_axi.wready = (!SHADOW_DDR && write_state == W_IDLE &&
                          ddr_write_data_pending != 0) ? m_ddr_axi.wready :
        write_state == W_DDR_DATA ? m_ddr_axi.wready :
        write_state == W_HEAD_DATA ?
            (SHADOW_DDR ? (bank_write_ready[write_bank_q] &&
                           m_ddr_axi.wready) :
                          bank_write_ready[write_bank_q]) :
        write_state == W_ERROR_DATA;
    assign m_ddr_axi.bready = (ddr_write_response || write_state == W_DDR_RESP) && s_axi.bready;
    assign s_axi.bid = (ddr_write_response || write_state == W_DDR_RESP) ? m_ddr_axi.bid : write_id_q;
    assign s_axi.bresp = (ddr_write_response || write_state == W_DDR_RESP) ?
                         m_ddr_axi.bresp : local_bresp_q;
    assign s_axi.bvalid = (ddr_write_response || write_state == W_DDR_RESP) ? m_ddr_axi.bvalid :
                          write_state == W_LOCAL_RESP;

    generate if (DECOUPLED) begin : g_read_decouple
        head_read_decoupler #(
            .ADDR_WIDTH(ADDR_WIDTH), .DATA_WIDTH(DATA_WIDTH), .ID_WIDTH(ID_WIDTH),
            .BANK_WIDTH(BANK_WIDTH), .WORD_ADDR_WIDTH(WORD_ADDR_WIDTH),
            .BYTE_SHIFT(BYTE_SHIFT), .OFFSET_WIDTH(OFFSET_WIDTH),
            .QUEUE_DEPTH(READ_QUEUE_DEPTH_PER_ID), .ACCEPT_LIMIT(READ_ACCEPT_LIMIT),
            .DDR_OUTSTANDING(DDR_OUTSTANDING)
        ) u_read (
            .clk(clk), .resetn(resetn), .s_axi(s_axi), .m_axi(m_ddr_axi),
            .ar_local(ar_is_head), .ar_legal(ar_head_valid),
            .ar_bank(BANK_WIDTH'(ar_bank_decode)),
            .ppu_outstanding(local_read_outstanding),
            .local_active(dec_local_active), .local_claim(dec_local_claim),
            .local_bank(dec_bank), .local_word_addr(dec_word_addr),
            .local_req_valid(dec_req_valid),
            .local_req_ready(bank_read_req_ready[dec_bank]),
            .local_rsp_valid(bank_read_rsp_valid[dec_bank]),
            .local_rsp_ready(dec_rsp_ready),
            .local_rsp_data(bank_read_rsp_data[dec_bank])
        );
    end else begin : g_read_legacy
        assign dec_local_active = 1'b0;
        assign dec_local_claim = 1'b0;
        assign dec_req_valid = 1'b0;
        assign dec_rsp_ready = 1'b0;
        assign dec_bank = '0;
        assign dec_word_addr = '0;
    assign m_ddr_axi.arid = s_axi.arid;
    assign m_ddr_axi.araddr = s_axi.araddr;
    assign m_ddr_axi.arlen = s_axi.arlen;
    assign m_ddr_axi.arsize = s_axi.arsize;
    assign m_ddr_axi.arburst = s_axi.arburst;
    assign m_ddr_axi.arlock = s_axi.arlock;
    assign m_ddr_axi.arcache = s_axi.arcache;
    assign m_ddr_axi.arprot = s_axi.arprot;
    assign m_ddr_axi.arqos = s_axi.arqos;
    assign m_ddr_axi.arvalid = read_state == R_IDLE && s_axi.arvalid &&
                               (!ar_is_head || SHADOW_DDR) &&
                               (SHADOW_DDR || ddr_read_room);
    assign s_axi.arready = read_state == R_IDLE &&
        (ar_is_head && !SHADOW_DDR ?
             (!local_read_outstanding && ddr_read_pending == 0) :
             m_ddr_axi.arready && (SHADOW_DDR || ddr_read_room));
    assign m_ddr_axi.rready = (ddr_read_response || read_state == R_DDR_DATA) && s_axi.rready;
    assign s_axi.rid = (ddr_read_response || read_state == R_DDR_DATA) ? m_ddr_axi.rid : read_id_q;
    assign s_axi.rdata = (ddr_read_response || read_state == R_DDR_DATA) ? m_ddr_axi.rdata :
                         read_state == R_HEAD_DATA ?
                         bank_read_rsp_data[read_bank_q] : '0;
    assign s_axi.rresp = (ddr_read_response || read_state == R_DDR_DATA) ? m_ddr_axi.rresp :
                         read_state == R_ERROR_DATA ? 2'b11 : 2'b00;
    assign s_axi.rlast = (ddr_read_response || read_state == R_DDR_DATA) ? m_ddr_axi.rlast :
                         (read_state == R_HEAD_DATA ||
                          read_state == R_ERROR_DATA) &&
                         read_return_beats_q == 1;
    assign s_axi.rvalid = (ddr_read_response || read_state == R_DDR_DATA) ? m_ddr_axi.rvalid :
                          read_state == R_HEAD_DATA ? head_read_rsp_valid :
                          read_state == R_ERROR_DATA;
    end endgenerate

    initial begin
        if (LOCAL_DATA_WIDTH > DATA_WIDTH || LOCAL_DATA_WIDTH < 8 ||
            (LOCAL_DATA_WIDTH & (LOCAL_DATA_WIDTH - 1)) != 0 ||
            ADDR_WIDTH < 32 || DATA_WIDTH < 8 ||
            (DATA_WIDTH & (DATA_WIDTH - 1)) != 0 ||
            (DATA_WIDTH % 8) != 0 || HEAD_BANK_COUNT < 2 ||
            DDR_OUTSTANDING < 1 || SLOT_BYTES < BYTE_LANES ||
            (SLOT_BYTES & (SLOT_BYTES - 1)) != 0)
            $error("axi4_head_uram_router parameters are invalid");
        for (integer bank = 0; bank < HEAD_BANK_COUNT; bank = bank + 1)
            if ((HEAD_BASE_ADDRS[bank*ADDR_WIDTH +: ADDR_WIDTH] &
                 ADDR_WIDTH'(SLOT_BYTES - 1)) != 0)
                $error("Head bank base must be slot aligned");
    end

    always @(posedge clk or negedge resetn) begin
        if (!resetn) begin
            write_state <= W_IDLE;
            write_bank_q <= '0;
            write_id_q <= '0;
            write_addr_q <= '0;
            write_size_q <= '0;
            write_burst_q <= '0;
            write_beats_q <= '0;
            write_error_q <= 1'b0;
            local_bresp_q <= 2'b00;
        end else begin
            case (write_state)
            W_IDLE: if (aw_fire) begin
                write_id_q <= s_axi.awid;
                if (aw_is_head) begin
                    write_bank_q <= BANK_WIDTH'(aw_bank_decode);
                    write_addr_q <= canonical_addr(s_axi.awaddr);
                    write_size_q <= s_axi.awsize;
                    write_burst_q <= s_axi.awburst;
                    write_beats_q <= {1'b0, s_axi.awlen} + 1'b1;
                    write_error_q <= 1'b0;
                    write_state <= aw_head_valid ? W_HEAD_DATA :
                                   (SHADOW_DDR ? W_DDR_DATA : W_ERROR_DATA);
                end else if (SHADOW_DDR) begin
                    write_state <= W_DDR_DATA;
                end
            end
            W_DDR_DATA: if (w_fire && s_axi.wlast)
                write_state <= W_DDR_RESP;
            W_DDR_RESP: if (b_fire)
                write_state <= W_IDLE;
            W_HEAD_DATA: if (w_fire) begin
                write_error_q <= write_error_q || write_last_mismatch;
                if (write_finish) begin
                    local_bresp_q <=
                        (write_error_q || write_last_mismatch) ?
                        2'b10 : 2'b00;
                    write_state <= SHADOW_DDR ? W_DDR_RESP : W_LOCAL_RESP;
                end else begin
                    write_beats_q <= write_beats_q - 1'b1;
                    if (write_burst_q == 2'b01)
                        write_addr_q <= write_addr_q +
                                        (ADDR_WIDTH'(1) << write_size_q);
                end
            end
            W_ERROR_DATA: if (w_fire) begin
                if (write_finish) begin
                    local_bresp_q <= 2'b11;
                    write_state <= W_LOCAL_RESP;
                end else begin
                    write_beats_q <= write_beats_q - 1'b1;
                end
            end
            W_LOCAL_RESP: if (b_fire)
                write_state <= W_IDLE;
            default: write_state <= W_IDLE;
            endcase
        end
    end

    generate if (!DECOUPLED) begin : g_legacy_read_state
    always @(posedge clk or negedge resetn) begin
        if (!resetn) begin
            read_state <= R_IDLE;
            read_bank_q <= '0;
            read_id_q <= '0;
            read_addr_q <= '0;
            read_size_q <= '0;
            read_burst_q <= '0;
            read_issue_beats_q <= '0;
            read_return_beats_q <= '0;
        end else begin
            case (read_state)
            R_IDLE: if (ar_fire) begin
                read_id_q <= s_axi.arid;
                if (ar_is_head && !SHADOW_DDR) begin
                    read_bank_q <= BANK_WIDTH'(ar_bank_decode);
                    read_addr_q <= canonical_addr(s_axi.araddr);
                    read_size_q <= s_axi.arsize;
                    read_burst_q <= s_axi.arburst;
                    read_issue_beats_q <= {1'b0, s_axi.arlen} + 1'b1;
                    read_return_beats_q <= {1'b0, s_axi.arlen} + 1'b1;
                    read_state <= ar_head_valid ?
                                  R_HEAD_DATA : R_ERROR_DATA;
                end else if (SHADOW_DDR) begin
                    read_state <= R_DDR_DATA;
                end
            end
            R_DDR_DATA: if (r_fire && m_ddr_axi.rlast)
                read_state <= R_IDLE;
            R_HEAD_DATA: begin
                if (head_read_req_fire) begin
                    read_issue_beats_q <= read_issue_beats_q - 1'b1;
                    if (read_burst_q == 2'b01)
                        read_addr_q <= read_addr_q +
                                       (ADDR_WIDTH'(1) << read_size_q);
                end
                if (head_read_rsp_fire) begin
                    read_return_beats_q <= read_return_beats_q - 1'b1;
                    if (read_return_beats_q == 1)
                        read_state <= R_IDLE;
                end
            end
            R_ERROR_DATA: if (r_fire) begin
                read_return_beats_q <= read_return_beats_q - 1'b1;
                if (read_return_beats_q == 1)
                    read_state <= R_IDLE;
            end
            default: read_state <= R_IDLE;
            endcase
        end
    end
    end else begin : g_unused_legacy_state
        assign read_state = R_IDLE;
        assign read_bank_q = '0;
        assign read_id_q = '0;
        assign read_addr_q = '0;
        assign read_size_q = '0;
        assign read_burst_q = '0;
        assign read_issue_beats_q = '0;
        assign read_return_beats_q = '0;
    end endgenerate

    wire ddr_aw_fire = m_ddr_axi.awvalid && m_ddr_axi.awready;
    wire ddr_wlast_fire = m_ddr_axi.wvalid && m_ddr_axi.wready && m_ddr_axi.wlast;
    wire ddr_b_fire = m_ddr_axi.bvalid && m_ddr_axi.bready;
    wire ddr_ar_fire = m_ddr_axi.arvalid && m_ddr_axi.arready;
    wire ddr_rlast_fire = m_ddr_axi.rvalid && m_ddr_axi.rready && m_ddr_axi.rlast;
    always @(posedge clk or negedge resetn) begin
        if (!resetn) begin
            ddr_write_pending <= '0;
            ddr_write_data_pending <= '0;
            ddr_read_pending <= '0;
        end else if (!SHADOW_DDR) begin
            case ({ddr_aw_fire, ddr_b_fire})
                2'b10: ddr_write_pending <= ddr_write_pending + 1'b1;
                2'b01: ddr_write_pending <= ddr_write_pending - 1'b1;
                default: ;
            endcase
            case ({ddr_aw_fire, ddr_wlast_fire})
                2'b10: ddr_write_data_pending <= ddr_write_data_pending + 1'b1;
                2'b01: ddr_write_data_pending <= ddr_write_data_pending - 1'b1;
                default: ;
            endcase
            case ({ddr_ar_fire, ddr_rlast_fire})
                2'b10: ddr_read_pending <= ddr_read_pending + 1'b1;
                2'b01: ddr_read_pending <= ddr_read_pending - 1'b1;
                default: ;
            endcase
        end
    end

    always @(posedge clk or negedge resetn) begin
        if (!resetn) begin
            local_read_outstanding <= 1'b0;
            local_read_bank_q <= '0;
            local_half_q <= '0;
        end else begin
            case ({local_read_req_fire, local_read_rsp_fire})
            2'b10: begin
                local_read_outstanding <= 1'b1;
                local_read_bank_q <= local_read_bank;
                local_half_q <= HALF_BITS'(local_read_req_word_addr & (LOCAL_RATIO - 1));
            end
            2'b01: local_read_outstanding <= 1'b0;
            2'b11: begin
                local_read_outstanding <= 1'b1;
                local_read_bank_q <= local_read_bank;
                local_half_q <= HALF_BITS'(local_read_req_word_addr & (LOCAL_RATIO - 1));
            end
            default: local_read_outstanding <= local_read_outstanding;
            endcase
        end
    end
endmodule

// Read-only engine. A descriptor reserves its ID destination before entering
// either executor. Ownership survives internal R buffering until upstream LAST.
module head_read_decoupler #(
    parameter integer ADDR_WIDTH = 33,
    parameter integer DATA_WIDTH = 512,
    parameter integer ID_WIDTH = 2,
    parameter integer BANK_WIDTH = 3,
    parameter integer WORD_ADDR_WIDTH = 14,
    parameter integer BYTE_SHIFT = 6,
    parameter integer OFFSET_WIDTH = 20,
    parameter integer QUEUE_DEPTH = 8,
    parameter integer ACCEPT_LIMIT = 32,
    parameter integer DDR_OUTSTANDING = 32
) (
    input wire clk, resetn,
    axi4_if.slave s_axi,
    axi4_if.master m_axi,
    input wire ar_local, ar_legal,
    input wire [BANK_WIDTH-1:0] ar_bank,
    input wire ppu_outstanding,
    output wire local_active, local_claim,
    output wire [BANK_WIDTH-1:0] local_bank,
    output wire [WORD_ADDR_WIDTH-1:0] local_word_addr,
    output wire local_req_valid,
    input wire local_req_ready, local_rsp_valid,
    output wire local_rsp_ready,
    input wire [DATA_WIDTH-1:0] local_rsp_data
);
    localparam integer IDS = 2**ID_WIDTH;
    localparam integer PTR_W = QUEUE_DEPTH > 1 ? $clog2(QUEUE_DEPTH) : 1;
    localparam integer QCOUNT_W = $clog2(QUEUE_DEPTH+1);
    localparam integer COUNT_W = $clog2(ACCEPT_LIMIT+1);
    typedef struct packed {
        logic [ID_WIDTH-1:0] id;
        logic [ADDR_WIDTH-1:0] addr;
        logic [7:0] len;
        logic [2:0] size;
        logic [1:0] burst;
        logic lock;
        logic [3:0] cache;
        logic [2:0] prot;
        logic [3:0] qos;
        logic target_local, legal;
        logic [BANK_WIDTH-1:0] bank;
    } descriptor_t;
    typedef struct packed {
        logic [ID_WIDTH-1:0] id;
        logic [DATA_WIDTH-1:0] data;
        logic [1:0] resp;
        logic last;
    } response_t;

    descriptor_t requests [IDS][QUEUE_DEPTH];
    descriptor_t heads [IDS];
    reg [PTR_W-1:0] rd_ptr [IDS], wr_ptr [IDS];
    reg [QCOUNT_W-1:0] queued [IDS];
    reg [COUNT_W-1:0] issued_pending [IDS];
    reg [IDS-1:0] active_target;
    reg [COUNT_W-1:0] accepted_total, ddr_reserved;
    reg [ID_WIDTH-1:0] round_robin;
    descriptor_t ar_stage, executor;
    reg ar_stage_valid, executor_valid;
    reg [8:0] issue_beats, return_beats;
    reg [ADDR_WIDTH-1:0] read_address;

    // Each response channel terminates reverse ready on a two-beat occupancy
    // register. The URAM itself retains an additional irrevocable pending read.
    response_t response_mem [2][2];
    response_t response_in [2];
    response_t response_out [2];
    reg [1:0] response_count [2];
    reg [1:0] response_rd, response_wr;
    wire [1:0] response_push, response_pop, response_ready, response_valid;
    reg r_locked, r_source, r_prefer_local;
    wire selected_source = r_locked ? r_source :
        (response_valid[1] && (!response_valid[0] || r_prefer_local));
    wire r_valid = response_valid[selected_source];
    wire r_fire = r_valid && s_axi.rready;
    wire retire = r_fire && s_axi.rlast;
    wire ar_fire = s_axi.arvalid && s_axi.arready;

    integer selected;
    integer candidate;
    reg dispatch;
    descriptor_t chosen;
    wire stage_room = !ar_stage_valid || m_axi.arready;
    always @* begin
        selected = 0;
        candidate = 0;
        chosen = '0;
        dispatch = 1'b0;
        for (integer offset = 0; offset < IDS; offset = offset+1) begin
            candidate = (integer'(round_robin) + offset) % IDS;
            if (!dispatch && queued[candidate] != 0 &&
                (issued_pending[candidate] == 0 ||
                 active_target[candidate] == heads[candidate].target_local) &&
                (heads[candidate].target_local ?
                    (!executor_valid && !ppu_outstanding) :
                    (stage_room && ddr_reserved < COUNT_W'(DDR_OUTSTANDING)))) begin
                dispatch = 1'b1;
                selected = candidate;
                chosen = heads[candidate];
            end
        end
    end
    assign s_axi.arready = resetn && accepted_total < COUNT_W'(ACCEPT_LIMIT) &&
                           queued[s_axi.arid] < QCOUNT_W'(QUEUE_DEPTH);
    assign local_claim = dispatch && chosen.target_local;
    assign local_active = executor_valid;
    assign local_bank = executor.bank;
    assign local_word_addr = read_address[OFFSET_WIDTH-1:BYTE_SHIFT];
    assign local_req_valid = executor_valid && executor.legal && issue_beats != 0;
    assign local_rsp_ready = executor_valid && executor.legal && response_ready[1];
    wire local_request = local_req_valid && local_req_ready;
    wire local_return = response_push[1];

    assign m_axi.arid = ar_stage.id;
    assign m_axi.araddr = ar_stage.addr;
    assign m_axi.arlen = ar_stage.len;
    assign m_axi.arsize = ar_stage.size;
    assign m_axi.arburst = ar_stage.burst;
    assign m_axi.arlock = ar_stage.lock;
    assign m_axi.arcache = ar_stage.cache;
    assign m_axi.arprot = ar_stage.prot;
    assign m_axi.arqos = ar_stage.qos;
    assign m_axi.arvalid = ar_stage_valid;
    assign m_axi.rready = resetn && response_ready[0];
    assign response_in[0] = {m_axi.rid, m_axi.rdata, m_axi.rresp, m_axi.rlast};
    assign response_in[1] = {executor.id,
        (executor.legal ? local_rsp_data : {DATA_WIDTH{1'b0}}),
        (executor.legal ? 2'b00 : 2'b11), (return_beats == 1)};
    assign response_push[0] = m_axi.rvalid && m_axi.rready;
    assign response_push[1] = executor_valid && response_ready[1] &&
                             (!executor.legal || local_rsp_valid);
    assign s_axi.rvalid = r_valid;
    assign {s_axi.rid, s_axi.rdata, s_axi.rresp, s_axi.rlast} = response_out[selected_source];

    function automatic [PTR_W-1:0] next_ptr(input [PTR_W-1:0] ptr);
        next_ptr = ptr == PTR_W'(QUEUE_DEPTH-1) ? '0 : ptr + 1'b1;
    endfunction
    for (genvar id = 0; id < IDS; id = id+1) begin : g_id
        assign heads[id] = requests[id][rd_ptr[id]];
        wire push = ar_fire && s_axi.arid == ID_WIDTH'(id);
        wire pop = dispatch && selected == id;
        wire done = retire && s_axi.rid == ID_WIDTH'(id);
        always @(posedge clk) begin
            if (push)
                requests[id][wr_ptr[id]] <= '{
                    id:s_axi.arid, addr:s_axi.araddr, len:s_axi.arlen,
                    size:s_axi.arsize, burst:s_axi.arburst, lock:s_axi.arlock,
                    cache:s_axi.arcache, prot:s_axi.arprot, qos:s_axi.arqos,
                    target_local:ar_local, legal:ar_legal, bank:ar_bank};
        end
        always @(posedge clk or negedge resetn) begin
            if (!resetn) begin
                rd_ptr[id] <= '0;
                wr_ptr[id] <= '0;
                queued[id] <= '0;
                issued_pending[id] <= '0;
                active_target[id] <= 1'b0;
            end else begin
                if (push) wr_ptr[id] <= next_ptr(wr_ptr[id]);
                if (pop) rd_ptr[id] <= next_ptr(rd_ptr[id]);
                case ({push,pop})
                    2'b10: queued[id] <= queued[id] + 1'b1;
                    2'b01: queued[id] <= queued[id] - 1'b1;
                    default: ;
                endcase
                case ({pop,done})
                    2'b10: issued_pending[id] <= issued_pending[id] + 1'b1;
                    2'b01: issued_pending[id] <= issued_pending[id] - 1'b1;
                    default: ;
                endcase
                if (pop) active_target[id] <= chosen.target_local;
            end
        end
    end
    for (genvar source = 0; source < 2; source = source+1) begin : g_response
        assign response_ready[source] = response_count[source] < 2;
        assign response_valid[source] = response_count[source] != 0;
        assign response_out[source] = response_mem[source][response_rd[source]];
        assign response_pop[source] = r_fire && selected_source == 1'(source);
        always @(posedge clk) begin
            if (response_push[source])
                response_mem[source][response_wr[source]] <= response_in[source];
        end
        always @(posedge clk or negedge resetn) begin
            if (!resetn) begin
                response_rd[source] <= 1'b0;
                response_wr[source] <= 1'b0;
                response_count[source] <= '0;
            end else begin
                if (response_push[source]) response_wr[source] <= ~response_wr[source];
                if (response_pop[source]) response_rd[source] <= ~response_rd[source];
                case ({response_push[source],response_pop[source]})
                    2'b10: response_count[source] <= response_count[source] + 1'b1;
                    2'b01: response_count[source] <= response_count[source] - 1'b1;
                    default: ;
                endcase
            end
        end
    end
    wire reserve_ddr = dispatch && !chosen.target_local;
    wire retire_ddr = retire && !selected_source;
    always @(posedge clk or negedge resetn) begin
        if (!resetn) begin
            accepted_total <= '0;
            ddr_reserved <= '0;
            round_robin <= '0;
            ar_stage_valid <= 1'b0;
            ar_stage <= '0;
            executor_valid <= 1'b0;
            executor <= '0;
            issue_beats <= '0;
            return_beats <= '0;
            read_address <= '0;
            r_locked <= 1'b0;
            r_source <= 1'b0;
            r_prefer_local <= 1'b0;
        end else begin
            case ({ar_fire,retire})
                2'b10: accepted_total <= accepted_total + 1'b1;
                2'b01: accepted_total <= accepted_total - 1'b1;
                default: ;
            endcase
            case ({reserve_ddr,retire_ddr})
                2'b10: ddr_reserved <= ddr_reserved + 1'b1;
                2'b01: ddr_reserved <= ddr_reserved - 1'b1;
                default: ;
            endcase
            if (ar_stage_valid && m_axi.arready) ar_stage_valid <= 1'b0;
            if (dispatch) begin
                round_robin <= ID_WIDTH'(selected+1);
                if (chosen.target_local) begin
                    executor_valid <= 1'b1;
                    executor <= chosen;
                    issue_beats <= {1'b0,chosen.len}+9'd1;
                    return_beats <= {1'b0,chosen.len}+9'd1;
                    read_address <= chosen.addr;
                end else begin
                    ar_stage <= chosen;
                    ar_stage_valid <= 1'b1;
                end
            end
            if (local_request) begin
                issue_beats <= issue_beats - 1'b1;
                if (executor.burst == 2'b01)
                    read_address <= read_address + (ADDR_WIDTH'(1) << executor.size);
            end
            if (local_return) begin
                return_beats <= return_beats - 1'b1;
                if (return_beats == 1) executor_valid <= 1'b0;
            end
            if (r_valid) begin
                r_locked <= !retire;
                r_source <= selected_source;
                if (retire) r_prefer_local <= !selected_source;
            end
        end
    end

    initial begin
        if (QUEUE_DEPTH < 1 || ACCEPT_LIMIT < 1 || DDR_OUTSTANDING < 1 ||
            DDR_OUTSTANDING > ACCEPT_LIMIT)
            $error("invalid Head read queue/credit parameters");
    end
`ifndef SYNTHESIS
    // Simulation-only acceptance ledger checks every ID's burst boundary,
    // including ARLEN=255, without adding production control or data paths.
    reg [8:0] lengths [IDS][ACCEPT_LIMIT];
    integer ledger_rd [IDS], ledger_wr [IDS];
    reg stalled_r, stalled_ar;
    response_t saved_r;
    descriptor_t saved_ar;
    integer conserved;
    always @* begin
        conserved = 0;
        for (integer id = 0; id < IDS; id=id+1)
            conserved = conserved + integer'(queued[id]) + integer'(issued_pending[id]);
    end
    always @(posedge clk) begin
        if (!resetn) begin
            stalled_r <= 0;
            stalled_ar <= 0;
            for (integer id=0; id<IDS; id=id+1) begin
                ledger_rd[id] <= 0;
                ledger_wr[id] <= 0;
            end
        end else begin
            assert (conserved == integer'(accepted_total)) else $fatal(1,"Head credit conservation");
            assert (integer'(accepted_total) <= ACCEPT_LIMIT) else $fatal(1,"Head acceptance overflow");
            if (stalled_r) assert (s_axi.rvalid && response_out[selected_source] == saved_r)
                else $fatal(1,"Head stalled R changed");
            if (stalled_ar) assert (m_axi.arvalid && ar_stage == saved_ar)
                else $fatal(1,"Head stalled AR changed");
            stalled_r <= s_axi.rvalid && !s_axi.rready;
            stalled_ar <= m_axi.arvalid && !m_axi.arready;
            saved_r <= response_out[selected_source];
            saved_ar <= ar_stage;
            for (integer id=0; id<IDS; id=id+1) begin
                assert (integer'(queued[id]) <= QUEUE_DEPTH && integer'(rd_ptr[id]) < QUEUE_DEPTH &&
                        integer'(wr_ptr[id]) < QUEUE_DEPTH) else $fatal(1,"Head FIFO bounds");
                if (dispatch && selected == id && issued_pending[id] != 0)
                    assert (chosen.target_local == active_target[id]) else $fatal(1,"Head ID target changed");
            end
            if (ar_fire) begin
                lengths[s_axi.arid][ledger_wr[s_axi.arid]] <= {1'b0,s_axi.arlen}+9'd1;
                ledger_wr[s_axi.arid] <= (ledger_wr[s_axi.arid]+1) % ACCEPT_LIMIT;
            end
            if (r_fire) begin
                assert (issued_pending[s_axi.rid] != 0 && accepted_total != 0)
                    else $fatal(1,"Head response without issued request");
                assert (active_target[s_axi.rid] == selected_source)
                    else $fatal(1,"Head response target violates ID ownership");
                assert (s_axi.rlast == (lengths[s_axi.rid][ledger_rd[s_axi.rid]] == 1))
                    else $fatal(1,"Head RLAST/length mismatch");
                if (s_axi.rlast) ledger_rd[s_axi.rid] <= (ledger_rd[s_axi.rid]+1) % ACCEPT_LIMIT;
                else lengths[s_axi.rid][ledger_rd[s_axi.rid]] <= lengths[s_axi.rid][ledger_rd[s_axi.rid]]-1'b1;
            end
        end
    end
`endif
endmodule
