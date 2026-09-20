`timescale 1ns/1ps

// AXI4 write-only asynchronous bridge. AW, W and B use XPM-backed payload
// FIFOs; up to MAX_OUTSTANDING address transactions may be in flight.
module axi4_write_cdc #(
    parameter integer FIFO_ADDR_WIDTH = 4,
    parameter integer FBUS_WRITE_ID = -1,
    parameter integer MAX_OUTSTANDING = 8
) (
    axi4_if.slave  s_axi,
    input  wire    m_clk,
    input  wire    m_resetn,
    axi4_if.master m_axi
);
    localparam integer FIFO_DEPTH = 1 << FIFO_ADDR_WIDTH;
    localparam integer AW_WIDTH = 60;
    localparam integer W_WIDTH = 289;
    localparam integer B_WIDTH = 5;
    localparam integer COUNT_WIDTH = $clog2(MAX_OUTSTANDING + 1);
    localparam integer ID_PTR_WIDTH = MAX_OUTSTANDING <= 1 ?
                                      1 : $clog2(MAX_OUTSTANDING);

    wire [AW_WIDTH-1:0] aw_data;
    wire [W_WIDTH-1:0] w_data;
    wire [B_WIDTH-1:0] b_data;
    wire aw_s_ready, aw_m_valid, w_s_ready, w_m_valid;
    wire b_m_ready, b_s_valid;
    reg [COUNT_WIDTH-1:0] outstanding_count;
    reg [COUNT_WIDTH-1:0] write_credit_count;
    reg [2:0] original_id [0:MAX_OUTSTANDING-1];
    reg [ID_PTR_WIDTH-1:0] id_wr_ptr, id_rd_ptr;

    wire s_aw_fire = s_axi.awvalid && s_axi.awready;
    wire s_w_fire = s_axi.wvalid && s_axi.wready;
    wire s_b_fire = s_axi.bvalid && s_axi.bready;
    wire m_aw_fire = m_axi.awvalid && m_axi.awready;
    wire m_w_fire = m_axi.wvalid && m_axi.wready;
    wire m_b_fire = m_axi.bvalid && m_axi.bready;
    wire outstanding_room = outstanding_count <
                            COUNT_WIDTH'(MAX_OUTSTANDING);

    function automatic [ID_PTR_WIDTH-1:0] next_id_ptr(
        input [ID_PTR_WIDTH-1:0] pointer);
        if (pointer == ID_PTR_WIDTH'(MAX_OUTSTANDING-1))
            next_id_ptr = '0;
        else
            next_id_ptr = pointer + 1'b1;
    endfunction

    initial begin
        if (MAX_OUTSTANDING < 1 || MAX_OUTSTANDING > FIFO_DEPTH)
            $error("Invalid axi4_write_cdc outstanding limit");
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
                       $bits(m_axi.awid)'(FBUS_WRITE_ID) :
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
    assign m_axi.awvalid = aw_m_valid && outstanding_room;
    assign m_axi.wdata = w_data[288:33];
    assign m_axi.wstrb = w_data[32:1];
    assign m_axi.wlast = w_data[0];
    assign m_axi.wvalid = w_m_valid && write_credit_count != 0;
    assign m_axi.bready = b_m_ready && outstanding_count != 0;

    assign m_axi.arid = 4'd0;
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

    // camera_video_clk and the 100 MHz SoC/FBus clock are asynchronous.
    // Do not let XPM optimize these FIFOs as related-clock crossings.
    cdc_payload_fifo #(
        .WIDTH(AW_WIDTH), .DEPTH(FIFO_DEPTH), .RELATED_CLOCKS(0)
    ) u_aw_fifo (
        .w_clk(s_axi.aclk), .w_resetn(s_axi.aresetn),
        .w_valid(s_axi.awvalid), .w_ready(aw_s_ready),
        .w_data({s_axi.awid, s_axi.awaddr, s_axi.awlen, s_axi.awsize,
                 s_axi.awburst, s_axi.awlock, s_axi.awcache, s_axi.awprot,
                 s_axi.awqos}),
        .r_clk(m_clk), .r_resetn(m_resetn), .r_valid(aw_m_valid),
        .r_ready(m_axi.awready && outstanding_room), .r_data(aw_data)
    );

    cdc_payload_fifo #(
        .WIDTH(W_WIDTH), .DEPTH(FIFO_DEPTH), .RELATED_CLOCKS(0)
    ) u_w_fifo (
        .w_clk(s_axi.aclk), .w_resetn(s_axi.aresetn),
        .w_valid(s_axi.wvalid), .w_ready(w_s_ready),
        .w_data({s_axi.wdata, s_axi.wstrb, s_axi.wlast}),
        .r_clk(m_clk), .r_resetn(m_resetn), .r_valid(w_m_valid),
        .r_ready(m_axi.wready && write_credit_count != 0), .r_data(w_data)
    );

    cdc_payload_fifo #(
        .WIDTH(B_WIDTH), .DEPTH(FIFO_DEPTH), .RELATED_CLOCKS(0)
    ) u_b_fifo (
        .w_clk(m_clk), .w_resetn(m_resetn),
        .w_valid(m_axi.bvalid && outstanding_count != 0),
        .w_ready(b_m_ready),
        .w_data({FBUS_WRITE_ID >= 0 ? original_id[id_rd_ptr] :
                 m_axi.bid[2:0], m_axi.bresp}),
        .r_clk(s_axi.aclk), .r_resetn(s_axi.aresetn),
        .r_valid(b_s_valid), .r_ready(s_axi.bready), .r_data(b_data)
    );

    always @(posedge m_clk or negedge m_resetn) begin
        if (!m_resetn) begin
            outstanding_count <= 0;
            write_credit_count <= 0;
            id_wr_ptr <= 0;
            id_rd_ptr <= 0;
        end else begin
            case ({m_aw_fire, m_b_fire})
                2'b10: outstanding_count <= outstanding_count + 1'b1;
                2'b01: outstanding_count <= outstanding_count - 1'b1;
                default: ;
            endcase
            case ({m_aw_fire, m_w_fire && m_axi.wlast})
                2'b10: write_credit_count <= write_credit_count + 1'b1;
                2'b01: write_credit_count <= write_credit_count - 1'b1;
                default: ;
            endcase
            if (m_aw_fire) begin
                original_id[id_wr_ptr] <= aw_data[59:57];
                id_wr_ptr <= next_id_ptr(id_wr_ptr);
            end
            if (m_b_fire)
                id_rd_ptr <= next_id_ptr(id_rd_ptr);
        end
    end

    wire unused = &{1'b0, s_aw_fire, s_w_fire, m_axi.bid, m_axi.rid,
                    m_axi.rdata, m_axi.rresp, m_axi.rlast, m_axi.rvalid};
endmodule
