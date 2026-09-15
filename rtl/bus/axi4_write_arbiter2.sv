`timescale 1ns/1ps

// Serializes two single-outstanding AXI4 write masters at burst boundaries.
// Ownership is held through B, so identical upstream IDs remain unambiguous.
module axi4_write_arbiter2 (
    input wire clk,
    input wire resetn,
    axi4_if.slave s0_axi,
    axi4_if.slave s1_axi,
    axi4_if.master m_axi
);
    localparam [1:0] ST_AW=0, ST_W=1, ST_B=2;
    reg [1:0] state;
    reg owner, turn;
    reg aw_locked, aw_owner;
    wire select_1 = aw_locked ? aw_owner :
                    s1_axi.awvalid && (!s0_axi.awvalid || turn);
    wire aw_fire = m_axi.awvalid && m_axi.awready;
    wire w_fire = m_axi.wvalid && m_axi.wready && m_axi.wlast;
    wire b_fire = m_axi.bvalid && m_axi.bready;

    assign m_axi.aclk = clk;
    assign m_axi.aresetn = resetn;
    assign m_axi.awid = select_1 ? s1_axi.awid : s0_axi.awid;
    assign m_axi.awaddr = select_1 ? s1_axi.awaddr : s0_axi.awaddr;
    assign m_axi.awlen = select_1 ? s1_axi.awlen : s0_axi.awlen;
    assign m_axi.awsize = select_1 ? s1_axi.awsize : s0_axi.awsize;
    assign m_axi.awburst = select_1 ? s1_axi.awburst : s0_axi.awburst;
    assign m_axi.awlock = select_1 ? s1_axi.awlock : s0_axi.awlock;
    assign m_axi.awcache = select_1 ? s1_axi.awcache : s0_axi.awcache;
    assign m_axi.awprot = select_1 ? s1_axi.awprot : s0_axi.awprot;
    assign m_axi.awqos = select_1 ? s1_axi.awqos : s0_axi.awqos;
    assign m_axi.awvalid = state == ST_AW &&
                           (select_1 ? s1_axi.awvalid : s0_axi.awvalid);
    assign s0_axi.awready = state == ST_AW && !select_1 && m_axi.awready;
    assign s1_axi.awready = state == ST_AW && select_1 && m_axi.awready;

    assign m_axi.wdata = owner ? s1_axi.wdata : s0_axi.wdata;
    assign m_axi.wstrb = owner ? s1_axi.wstrb : s0_axi.wstrb;
    assign m_axi.wlast = owner ? s1_axi.wlast : s0_axi.wlast;
    assign m_axi.wvalid = state == ST_W &&
                          (owner ? s1_axi.wvalid : s0_axi.wvalid);
    assign s0_axi.wready = state == ST_W && !owner && m_axi.wready;
    assign s1_axi.wready = state == ST_W && owner && m_axi.wready;

    assign s0_axi.bid = m_axi.bid;
    assign s0_axi.bresp = m_axi.bresp;
    assign s0_axi.bvalid = state == ST_B && !owner && m_axi.bvalid;
    assign s1_axi.bid = m_axi.bid;
    assign s1_axi.bresp = m_axi.bresp;
    assign s1_axi.bvalid = state == ST_B && owner && m_axi.bvalid;
    assign m_axi.bready = state == ST_B &&
                          (owner ? s1_axi.bready : s0_axi.bready);

    assign m_axi.arid = 3'd0;
    assign m_axi.araddr = 32'd0;
    assign m_axi.arlen = 8'd0;
    assign m_axi.arsize = 3'd0;
    assign m_axi.arburst = 2'd0;
    assign m_axi.arlock = 1'b0;
    assign m_axi.arcache = 4'd0;
    assign m_axi.arprot = 3'd0;
    assign m_axi.arqos = 4'd0;
    assign m_axi.arvalid = 1'b0;
    assign m_axi.rready = 1'b0;
    assign s0_axi.arready = 1'b0;
    assign s0_axi.rid = 3'd0;
    assign s0_axi.rdata = 256'd0;
    assign s0_axi.rresp = 2'd0;
    assign s0_axi.rlast = 1'b0;
    assign s0_axi.rvalid = 1'b0;
    assign s1_axi.arready = 1'b0;
    assign s1_axi.rid = 3'd0;
    assign s1_axi.rdata = 256'd0;
    assign s1_axi.rresp = 2'd0;
    assign s1_axi.rlast = 1'b0;
    assign s1_axi.rvalid = 1'b0;

    always @(posedge clk) begin
        if (!resetn) begin
            state <= ST_AW;
            owner <= 0;
            turn <= 0;
            aw_locked <= 0;
            aw_owner <= 0;
        end else begin
            case (state)
            ST_AW: begin
                if (m_axi.awvalid && !m_axi.awready) begin
                    aw_locked <= 1;
                    aw_owner <= select_1;
                end
                if (aw_fire) begin
                    aw_locked <= 0;
                    owner <= select_1;
                    state <= ST_W;
                end
            end
            ST_W: if (w_fire)
                state <= ST_B;
            ST_B: if (b_fire) begin
                turn <= !owner;
                state <= ST_AW;
            end
            default: state <= ST_AW;
            endcase
        end
    end
endmodule
