`timescale 1ns/1ps

// Splits the SoC memory AXI into unchanged DDR traffic and four local Head
// slots. Bit 31 is ignored only for Head decode, matching the Rocket CPU DDR
// alias. Transactions are serialized independently on the read and write
// channels; this P2 implementation prioritizes correctness over throughput.
module axi4_head_uram_router #(
    parameter integer ADDR_WIDTH = 33,
    parameter integer DATA_WIDTH = 256,
    parameter integer ID_WIDTH = 4,
    // P3 integration mode: Head writes are committed to both DDR and URAM,
    // AXI reads remain DDR-backed, and only the dedicated local port reads
    // URAM.  DDR therefore remains a live, software-selectable fallback.
    parameter bit SHADOW_DDR = 1'b0,
    parameter integer HEAD_BANK_COUNT = 4,
    parameter integer SLOT_BYTES = 1024 * 1024,
    parameter [HEAD_BANK_COUNT*ADDR_WIDTH-1:0] HEAD_BASE_ADDRS = {
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
    input  wire [$clog2(SLOT_BYTES/(DATA_WIDTH/8))-1:0]
                                             local_read_req_word_addr,
    output wire [DATA_WIDTH-1:0]        local_read_rsp_data,
    output wire                         local_read_rsp_valid,
    input  wire                         local_read_rsp_ready
);
    localparam integer BYTE_LANES = DATA_WIDTH / 8;
    localparam integer BYTE_SHIFT = $clog2(BYTE_LANES);
    localparam integer OFFSET_WIDTH = $clog2(SLOT_BYTES);
    localparam integer WORD_ADDR_WIDTH =
        $clog2(SLOT_BYTES / BYTE_LANES);
    localparam integer BANK_WIDTH = $clog2(HEAD_BANK_COUNT);

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
    wire head_ar_claim = read_state == R_IDLE && s_axi.arvalid && ar_is_head;
    wire local_slot_available = !local_read_outstanding || local_read_rsp_fire;
    wire local_may_request = read_state != R_HEAD_DATA &&
                             !head_ar_claim && local_slot_available &&
                             local_bank_in_range;
    assign local_read_req_ready = local_may_request &&
        bank_read_req_ready[local_read_bank];
    wire local_read_req_fire = local_read_req_valid &&
                               local_read_req_ready;
    assign local_read_rsp_valid = local_read_rsp_valid_i;
    assign local_read_rsp_data =
        bank_read_rsp_data[local_read_bank_q];

    genvar bank_index;
    generate
        for (bank_index = 0; bank_index < HEAD_BANK_COUNT;
             bank_index = bank_index + 1) begin : g_head_bank
            localparam [BANK_WIDTH-1:0] BANK = BANK_WIDTH'(bank_index);
            wire selected_write = write_state == W_HEAD_DATA &&
                                  write_bank_q == BANK;
            wire selected_head_read = read_state == R_HEAD_DATA &&
                                      read_bank_q == BANK;
            wire selected_local_read = local_may_request &&
                                       local_read_bank == BANK;
            assign bank_read_req_valid[bank_index] =
                selected_head_read ? head_read_request :
                selected_local_read ? local_read_req_valid : 1'b0;
            assign bank_read_req_addr[bank_index] = selected_head_read ?
                read_addr_q[OFFSET_WIDTH-1:BYTE_SHIFT] :
                local_read_req_word_addr;
            assign bank_read_rsp_ready[bank_index] = selected_head_read ?
                s_axi.rready :
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
                               (!aw_is_head || SHADOW_DDR);
    assign s_axi.awready = write_state == W_IDLE &&
        (aw_is_head && !SHADOW_DDR ? 1'b1 : m_ddr_axi.awready);

    assign m_ddr_axi.wdata = s_axi.wdata;
    assign m_ddr_axi.wstrb = s_axi.wstrb;
    assign m_ddr_axi.wlast = s_axi.wlast;
    assign m_ddr_axi.wvalid =
        (write_state == W_DDR_DATA && s_axi.wvalid) ||
        (write_state == W_HEAD_DATA && SHADOW_DDR && s_axi.wvalid &&
         bank_write_ready[write_bank_q]);
    assign s_axi.wready = write_state == W_DDR_DATA ? m_ddr_axi.wready :
        write_state == W_HEAD_DATA ?
            (SHADOW_DDR ? (bank_write_ready[write_bank_q] &&
                           m_ddr_axi.wready) :
                          bank_write_ready[write_bank_q]) :
        write_state == W_ERROR_DATA;
    assign m_ddr_axi.bready = write_state == W_DDR_RESP && s_axi.bready;
    assign s_axi.bid = write_state == W_DDR_RESP ? m_ddr_axi.bid : write_id_q;
    assign s_axi.bresp = write_state == W_DDR_RESP ?
                         m_ddr_axi.bresp : local_bresp_q;
    assign s_axi.bvalid = write_state == W_DDR_RESP ? m_ddr_axi.bvalid :
                          write_state == W_LOCAL_RESP;

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
                               (!ar_is_head || SHADOW_DDR);
    assign s_axi.arready = read_state == R_IDLE &&
        (ar_is_head && !SHADOW_DDR ?
             !local_read_outstanding : m_ddr_axi.arready);
    assign m_ddr_axi.rready = read_state == R_DDR_DATA && s_axi.rready;
    assign s_axi.rid = read_state == R_DDR_DATA ? m_ddr_axi.rid : read_id_q;
    assign s_axi.rdata = read_state == R_DDR_DATA ? m_ddr_axi.rdata :
                         read_state == R_HEAD_DATA ?
                         bank_read_rsp_data[read_bank_q] : '0;
    assign s_axi.rresp = read_state == R_DDR_DATA ? m_ddr_axi.rresp :
                         read_state == R_ERROR_DATA ? 2'b11 : 2'b00;
    assign s_axi.rlast = read_state == R_DDR_DATA ? m_ddr_axi.rlast :
                         (read_state == R_HEAD_DATA ||
                          read_state == R_ERROR_DATA) &&
                         read_return_beats_q == 1;
    assign s_axi.rvalid = read_state == R_DDR_DATA ? m_ddr_axi.rvalid :
                          read_state == R_HEAD_DATA ? head_read_rsp_valid :
                          read_state == R_ERROR_DATA;

    initial begin
        if (ADDR_WIDTH < 32 || DATA_WIDTH < 8 ||
            (DATA_WIDTH & (DATA_WIDTH - 1)) != 0 ||
            (DATA_WIDTH % 8) != 0 || HEAD_BANK_COUNT < 2 ||
            (HEAD_BANK_COUNT & (HEAD_BANK_COUNT - 1)) != 0 ||
            SLOT_BYTES < BYTE_LANES ||
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
                end else begin
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
                end else begin
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

    always @(posedge clk or negedge resetn) begin
        if (!resetn) begin
            local_read_outstanding <= 1'b0;
            local_read_bank_q <= '0;
        end else begin
            case ({local_read_req_fire, local_read_rsp_fire})
            2'b10: begin
                local_read_outstanding <= 1'b1;
                local_read_bank_q <= local_read_bank;
            end
            2'b01: local_read_outstanding <= 1'b0;
            2'b11: begin
                local_read_outstanding <= 1'b1;
                local_read_bank_q <= local_read_bank;
            end
            default: local_read_outstanding <= local_read_outstanding;
            endcase
        end
    end
endmodule
