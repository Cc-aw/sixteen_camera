`timescale 1ns/1ps

module control_soc_subsystem (
    input  wire sys_rstn,
    input  wire clk_25m,
    input  wire clk_100m_p,
    input  wire clk_100m_n,
    inout  wire si5338_scl1,
    inout  wire si5338_sda1,
    inout  wire si5338_scl2,
    inout  wire si5338_sda2,
    output wire uart_txd,
    input  wire uart_rxd,
    input  wire ddr_init_done,
    input  wire [7:0] video_interrupts,
    output wire ref_clk_100m,
    axi4_if.master mem_axi,
    axi4_if.master mmio_axi
);
    wire clk_100m_ibuf;
    wire ref_clk_100m_int;
    wire soc_clk;
    (* ASYNC_REG = "TRUE" *) reg [1:0] ddr_calib_sync;
    wire soc_resetn;

    si5338top u_si5338top (
        .clk_25m(clk_25m),
        .sys_rstn(sys_rstn),
        .si5338_scl1(si5338_scl1),
        .si5338_sda1(si5338_sda1),
        .si5338_scl2(si5338_scl2),
        .si5338_sda2(si5338_sda2)
    );

    IBUFDS u_clk_100m_ibufds (
        .I(clk_100m_p),
        .IB(clk_100m_n),
        .O(clk_100m_ibuf)
    );

    BUFG u_ref_clk_100m_bufg (
        .I(clk_100m_ibuf),
        .O(ref_clk_100m_int)
    );

    // Keep the Rocket, Gemmini and AXI control domain at the board 100 MHz
    // clock. Timing closure is handled with pipelining/physical optimization;
    // dividing this clock would also invalidate the original video ABI timing.
    assign soc_clk = ref_clk_100m_int;

    always @(posedge soc_clk or negedge sys_rstn) begin
        if (!sys_rstn)
            ddr_calib_sync <= 2'b00;
        else
            ddr_calib_sync <= {ddr_calib_sync[0], ddr_init_done};
    end

    assign soc_resetn = sys_rstn && ddr_calib_sync[1];
    assign ref_clk_100m = ref_clk_100m_int;
    assign mem_axi.aclk = soc_clk;
    assign mem_axi.aresetn = soc_resetn;
    assign mmio_axi.aclk = soc_clk;
    assign mmio_axi.aresetn = soc_resetn;

    TaihangSoCFPGATestHarness u_rocket (
        .clock(soc_clk),
        .reset(~soc_resetn),
        .uart_txd(uart_txd),
        .uart_rxd(uart_rxd),

        .axi4_mem_aw_ready(mem_axi.awready),
        .axi4_mem_aw_valid(mem_axi.awvalid),
        .axi4_mem_aw_bits_id(mem_axi.awid),
        .axi4_mem_aw_bits_addr(mem_axi.awaddr),
        .axi4_mem_aw_bits_len(mem_axi.awlen),
        .axi4_mem_aw_bits_size(mem_axi.awsize),
        .axi4_mem_aw_bits_burst(mem_axi.awburst),
        .axi4_mem_aw_bits_lock(mem_axi.awlock),
        .axi4_mem_aw_bits_cache(mem_axi.awcache),
        .axi4_mem_aw_bits_prot(mem_axi.awprot),
        .axi4_mem_aw_bits_qos(mem_axi.awqos),
        .axi4_mem_w_ready(mem_axi.wready),
        .axi4_mem_w_valid(mem_axi.wvalid),
        .axi4_mem_w_bits_data(mem_axi.wdata),
        .axi4_mem_w_bits_strb(mem_axi.wstrb),
        .axi4_mem_w_bits_last(mem_axi.wlast),
        .axi4_mem_b_ready(mem_axi.bready),
        .axi4_mem_b_valid(mem_axi.bvalid),
        .axi4_mem_b_bits_id(mem_axi.bid),
        .axi4_mem_b_bits_resp(mem_axi.bresp),
        .axi4_mem_ar_ready(mem_axi.arready),
        .axi4_mem_ar_valid(mem_axi.arvalid),
        .axi4_mem_ar_bits_id(mem_axi.arid),
        .axi4_mem_ar_bits_addr(mem_axi.araddr),
        .axi4_mem_ar_bits_len(mem_axi.arlen),
        .axi4_mem_ar_bits_size(mem_axi.arsize),
        .axi4_mem_ar_bits_burst(mem_axi.arburst),
        .axi4_mem_ar_bits_lock(mem_axi.arlock),
        .axi4_mem_ar_bits_cache(mem_axi.arcache),
        .axi4_mem_ar_bits_prot(mem_axi.arprot),
        .axi4_mem_ar_bits_qos(mem_axi.arqos),
        .axi4_mem_r_ready(mem_axi.rready),
        .axi4_mem_r_valid(mem_axi.rvalid),
        .axi4_mem_r_bits_id(mem_axi.rid),
        .axi4_mem_r_bits_data(mem_axi.rdata),
        .axi4_mem_r_bits_resp(mem_axi.rresp),
        .axi4_mem_r_bits_last(mem_axi.rlast),

        .axi4_mmio_aw_ready(mmio_axi.awready),
        .axi4_mmio_aw_valid(mmio_axi.awvalid),
        .axi4_mmio_aw_bits_id(mmio_axi.awid),
        .axi4_mmio_aw_bits_addr(mmio_axi.awaddr),
        .axi4_mmio_aw_bits_len(mmio_axi.awlen),
        .axi4_mmio_aw_bits_size(mmio_axi.awsize),
        .axi4_mmio_aw_bits_burst(mmio_axi.awburst),
        .axi4_mmio_aw_bits_lock(mmio_axi.awlock),
        .axi4_mmio_aw_bits_cache(mmio_axi.awcache),
        .axi4_mmio_aw_bits_prot(mmio_axi.awprot),
        .axi4_mmio_aw_bits_qos(mmio_axi.awqos),
        .axi4_mmio_w_ready(mmio_axi.wready),
        .axi4_mmio_w_valid(mmio_axi.wvalid),
        .axi4_mmio_w_bits_data(mmio_axi.wdata),
        .axi4_mmio_w_bits_strb(mmio_axi.wstrb),
        .axi4_mmio_w_bits_last(mmio_axi.wlast),
        .axi4_mmio_b_ready(mmio_axi.bready),
        .axi4_mmio_b_valid(mmio_axi.bvalid),
        .axi4_mmio_b_bits_id(mmio_axi.bid),
        .axi4_mmio_b_bits_resp(mmio_axi.bresp),
        .axi4_mmio_ar_ready(mmio_axi.arready),
        .axi4_mmio_ar_valid(mmio_axi.arvalid),
        .axi4_mmio_ar_bits_id(mmio_axi.arid),
        .axi4_mmio_ar_bits_addr(mmio_axi.araddr),
        .axi4_mmio_ar_bits_len(mmio_axi.arlen),
        .axi4_mmio_ar_bits_size(mmio_axi.arsize),
        .axi4_mmio_ar_bits_burst(mmio_axi.arburst),
        .axi4_mmio_ar_bits_lock(mmio_axi.arlock),
        .axi4_mmio_ar_bits_cache(mmio_axi.arcache),
        .axi4_mmio_ar_bits_prot(mmio_axi.arprot),
        .axi4_mmio_ar_bits_qos(mmio_axi.arqos),
        .axi4_mmio_r_ready(mmio_axi.rready),
        .axi4_mmio_r_valid(mmio_axi.rvalid),
        .axi4_mmio_r_bits_id(mmio_axi.rid),
        .axi4_mmio_r_bits_data(mmio_axi.rdata),
        .axi4_mmio_r_bits_resp(mmio_axi.rresp),
        .axi4_mmio_r_bits_last(mmio_axi.rlast)
        // The Taihang harness has no external interrupt bundle. Video IRQs
        // remain handled by the control-side logic.
    );
endmodule
