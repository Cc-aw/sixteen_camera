`timescale 1ns/1ps

module video_mmio_fabric (
    input  wire         aclk,
    input  wire         aresetn,

    input  wire [3:0]   s_awid,
    input  wire [30:0]  s_awaddr,
    input  wire [7:0]   s_awlen,
    input  wire [2:0]   s_awsize,
    input  wire [1:0]   s_awburst,
    input  wire         s_awlock,
    input  wire [3:0]   s_awcache,
    input  wire [2:0]   s_awprot,
    input  wire [3:0]   s_awqos,
    input  wire         s_awvalid,
    output wire         s_awready,
    input  wire [63:0]  s_wdata,
    input  wire [7:0]   s_wstrb,
    input  wire         s_wlast,
    input  wire         s_wvalid,
    output wire         s_wready,
    output wire [3:0]   s_bid,
    output wire [1:0]   s_bresp,
    output wire         s_bvalid,
    input  wire         s_bready,
    input  wire [3:0]   s_arid,
    input  wire [30:0]  s_araddr,
    input  wire [7:0]   s_arlen,
    input  wire [2:0]   s_arsize,
    input  wire [1:0]   s_arburst,
    input  wire         s_arlock,
    input  wire [3:0]   s_arcache,
    input  wire [2:0]   s_arprot,
    input  wire [3:0]   s_arqos,
    input  wire         s_arvalid,
    output wire         s_arready,
    output wire [3:0]   s_rid,
    output wire [63:0]  s_rdata,
    output wire [1:0]   s_rresp,
    output wire         s_rlast,
    output wire         s_rvalid,
    input  wire         s_rready,

    output wire [5:0][17:0] m_awaddr,
    output wire [5:0][2:0]  m_awprot,
    output wire [5:0]       m_awvalid,
    input  wire [5:0]       m_awready,
    output wire [5:0][31:0] m_wdata,
    output wire [5:0][3:0]  m_wstrb,
    output wire [5:0]       m_wvalid,
    input  wire [5:0]       m_wready,
    input  wire [5:0][1:0]  m_bresp,
    input  wire [5:0]       m_bvalid,
    output wire [5:0]       m_bready,
    output wire [5:0][17:0] m_araddr,
    output wire [5:0][2:0]  m_arprot,
    output wire [5:0]       m_arvalid,
    input  wire [5:0]       m_arready,
    input  wire [5:0][31:0] m_rdata,
    input  wire [5:0][1:0]  m_rresp,
    input  wire [5:0]       m_rvalid,
    output wire [5:0]       m_rready
);

    localparam logic [2:0] SEL_ERROR = 3'd7;
    // Taihang's CPU-visible AXI aperture is rooted at 0x10040000, while the
    // existing peripheral decode is rooted at 0x40000000. Normalize the
    // aperture before decode and before forwarding the peripheral offset.
    localparam logic [30:0] EXT_MMIO_BASE = 31'h10040000;
    localparam logic [30:0] VIDEO_MMIO_BASE = 31'h40000000;

    logic [30:0] awaddr_hold, araddr_hold;
    logic [3:0]  awid_hold, arid_hold;
    logic [2:0]  awprot_hold, arprot_hold;
    logic [63:0] wdata_hold;
    logic [7:0]  wstrb_hold;
    logic [2:0]  aw_sel, ar_sel;
    logic        aw_lane, ar_lane;
    logic        aw_hold, w_hold, write_active, write_aw_done, write_w_done;
    logic        ar_hold, read_active, read_ar_done;
    logic        write_error, read_error;

    function automatic logic [30:0] normalize_address(input logic [30:0] address);
        begin
            if ((address >= EXT_MMIO_BASE) &&
                (address < (EXT_MMIO_BASE + 31'h00200000)))
                normalize_address = address - EXT_MMIO_BASE + VIDEO_MMIO_BASE;
            else
                normalize_address = address;
        end
    endfunction

    function automatic logic [2:0] decode_address(input logic [30:0] address);
        begin
            case (address[30:16])
                15'h4000: decode_address = 3'd0; // GPIO
                15'h4001: decode_address = 3'd1; // IIC
                15'h4002: decode_address = 3'd2; // VPHY
                15'h4003: decode_address = 3'd3; // HDMI RX
                15'h4004,
                15'h4005: decode_address = 3'd4; // HDMI TX + VTC
                default: begin
                    if ((address >= 31'h40100000) &&
                        (address <  31'h40140000))
                        decode_address = 3'd5; // framebuffer + cameras
                    else
                        decode_address = SEL_ERROR;
                end
            endcase
        end
    endfunction

    assign s_awready = !aw_hold && !write_active;
    assign s_wready  = !w_hold && !write_active;
    assign s_arready = !ar_hold && !read_active;

    assign s_bid    = awid_hold;
    assign s_bvalid = write_active &&
                      (write_error || (write_aw_done && write_w_done &&
                                       m_bvalid[aw_sel]));
    assign s_bresp  = write_error ? 2'b11 : m_bresp[aw_sel];

    assign s_rid    = arid_hold;
    assign s_rlast  = 1'b1;
    assign s_rvalid = read_active &&
                      (read_error || (read_ar_done && m_rvalid[ar_sel]));
    assign s_rresp  = read_error ? 2'b11 : m_rresp[ar_sel];
    assign s_rdata  = read_error ? 64'b0 :
                      (ar_lane ? {m_rdata[ar_sel], 32'b0} :
                                 {32'b0, m_rdata[ar_sel]});

    genvar i;
    generate
        for (i = 0; i < 6; i = i + 1) begin : g_targets
            assign m_awaddr[i]  = awaddr_hold[17:0];
            assign m_awprot[i]  = awprot_hold;
            assign m_awvalid[i] = write_active && !write_error &&
                                  (aw_sel == i) && !write_aw_done;
            assign m_wdata[i]   = aw_lane ? wdata_hold[63:32] :
                                             wdata_hold[31:0];
            assign m_wstrb[i]   = aw_lane ? wstrb_hold[7:4] :
                                             wstrb_hold[3:0];
            assign m_wvalid[i]  = write_active && !write_error &&
                                  (aw_sel == i) && !write_w_done;
            assign m_bready[i]  = write_active && !write_error &&
                                  (aw_sel == i) && write_aw_done &&
                                  write_w_done && s_bready;

            assign m_araddr[i]  = araddr_hold[17:0];
            assign m_arprot[i]  = arprot_hold;
            assign m_arvalid[i] = read_active && !read_error &&
                                  (ar_sel == i) && !read_ar_done;
            assign m_rready[i]  = read_active && !read_error &&
                                  (ar_sel == i) && read_ar_done && s_rready;
        end
    endgenerate

    always_ff @(posedge aclk) begin
        if (!aresetn) begin
            aw_hold       <= 1'b0;
            w_hold        <= 1'b0;
            write_active  <= 1'b0;
            write_aw_done <= 1'b0;
            write_w_done  <= 1'b0;
            write_error   <= 1'b0;
            ar_hold       <= 1'b0;
            read_active   <= 1'b0;
            read_ar_done  <= 1'b0;
            read_error    <= 1'b0;
        end else begin
            if (s_awvalid && s_awready) begin
                aw_hold      <= 1'b1;
                awaddr_hold  <= normalize_address(s_awaddr);
                awid_hold    <= s_awid;
                awprot_hold  <= s_awprot;
                aw_sel       <= decode_address(normalize_address(s_awaddr));
                aw_lane      <= s_awaddr[2];
                write_error  <= (decode_address(normalize_address(s_awaddr)) == SEL_ERROR) ||
                                (s_awlen != 8'd0) || (s_awsize > 3'd2);
            end
            if (s_wvalid && s_wready) begin
                w_hold     <= 1'b1;
                wdata_hold <= s_wdata;
                wstrb_hold <= s_wstrb;
            end
            if (!write_active && aw_hold && w_hold) begin
                write_active  <= 1'b1;
                write_aw_done <= 1'b0;
                write_w_done  <= 1'b0;
            end
            if (write_active && !write_error && !write_aw_done &&
                m_awready[aw_sel])
                write_aw_done <= 1'b1;
            if (write_active && !write_error && !write_w_done &&
                m_wready[aw_sel])
                write_w_done <= 1'b1;
            if (s_bvalid && s_bready) begin
                aw_hold      <= 1'b0;
                w_hold       <= 1'b0;
                write_active <= 1'b0;
            end

            if (s_arvalid && s_arready) begin
                ar_hold      <= 1'b1;
                araddr_hold  <= normalize_address(s_araddr);
                arid_hold    <= s_arid;
                arprot_hold  <= s_arprot;
                ar_sel       <= decode_address(normalize_address(s_araddr));
                ar_lane      <= s_araddr[2];
                read_error   <= (decode_address(normalize_address(s_araddr)) == SEL_ERROR) ||
                                (s_arlen != 8'd0) || (s_arsize > 3'd2);
            end
            if (!read_active && ar_hold) begin
                read_active  <= 1'b1;
                read_ar_done <= 1'b0;
            end
            if (read_active && !read_error && !read_ar_done &&
                m_arready[ar_sel])
                read_ar_done <= 1'b1;
            if (s_rvalid && s_rready) begin
                ar_hold     <= 1'b0;
                read_active <= 1'b0;
            end
        end
    end

endmodule
