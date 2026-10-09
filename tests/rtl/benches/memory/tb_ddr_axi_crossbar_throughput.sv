`timescale 1ns/1ps

module tb_ddr_axi_crossbar_throughput #(
    parameter integer ACCEPTANCE = 8,
    parameter integer MODE = 0,
    parameter integer TRANSACTIONS = 4096,
    parameter integer SOURCE_PERIOD = 6,
    parameter integer RESPONSE_LATENCY = 48
);
    localparam integer MODE_READ = 0;
    localparam integer MODE_WRITE = 1;
    localparam integer MODE_READ_WRITE = 2;
    localparam [31:0] ACCEPTANCE_WORD = ACCEPTANCE;

    reg aclk = 1'b0;
    reg aresetn = 1'b0;
    always #1.667 aclk = ~aclk;

    reg [63:0] cycle_count;
    reg [63:0] first_cycle;
    reg first_seen;
    reg reported;
    reg failed;

    reg read_valid;
    reg [1:0] read_id;
    reg [31:0] read_addr;
    integer read_issued;
    integer read_completed;
    reg [63:0] next_read_cycle;
    integer read_max_outstanding;

    reg write_awvalid;
    reg write_wvalid;
    reg [1:0] write_id;
    reg [31:0] write_addr;
    reg write_aw_done;
    reg write_w_done;
    integer write_issued;
    integer write_completed;
    reg [63:0] next_write_cycle;
    integer write_max_outstanding;

    wire [5:0] s_axi_awid = {4'd0, write_id};
    wire [95:0] s_axi_awaddr = {64'd0, write_addr};
    wire [23:0] s_axi_awlen = 24'd0;
    wire [8:0] s_axi_awsize = {6'd0, 3'd6};
    wire [5:0] s_axi_awburst = {4'd0, 2'b01};
    wire [2:0] s_axi_awlock = 3'd0;
    wire [11:0] s_axi_awcache = 12'd0;
    wire [8:0] s_axi_awprot = 9'd0;
    wire [11:0] s_axi_awqos = 12'd0;
    wire [2:0] s_axi_awvalid = {2'b00, write_awvalid};
    wire [2:0] s_axi_awready;
    wire [1535:0] s_axi_wdata = {1024'd0, 512'h1};
    wire [191:0] s_axi_wstrb = {128'd0, 64'hffff_ffff_ffff_ffff};
    wire [2:0] s_axi_wlast = {2'b00, 1'b1};
    wire [2:0] s_axi_wvalid = {2'b00, write_wvalid};
    wire [2:0] s_axi_wready;
    wire [5:0] s_axi_bid;
    wire [5:0] s_axi_bresp;
    wire [2:0] s_axi_bvalid;
    wire [2:0] s_axi_bready = 3'b001;

    wire [5:0] s_axi_arid = {4'd0, read_id};
    wire [95:0] s_axi_araddr = {64'd0, read_addr};
    wire [23:0] s_axi_arlen = 24'd0;
    wire [8:0] s_axi_arsize = {6'd0, 3'd6};
    wire [5:0] s_axi_arburst = {4'd0, 2'b01};
    wire [2:0] s_axi_arlock = 3'd0;
    wire [11:0] s_axi_arcache = 12'd0;
    wire [8:0] s_axi_arprot = 9'd0;
    wire [11:0] s_axi_arqos = 12'd0;
    wire [2:0] s_axi_arvalid = {2'b00, read_valid};
    wire [2:0] s_axi_arready;
    wire [5:0] s_axi_rid;
    wire [1535:0] s_axi_rdata;
    wire [5:0] s_axi_rresp;
    wire [2:0] s_axi_rlast;
    wire [2:0] s_axi_rvalid;
    wire [2:0] s_axi_rready = 3'b001;

    wire [1:0] m_axi_awid;
    wire [31:0] m_axi_awaddr;
    wire [7:0] m_axi_awlen;
    wire [2:0] m_axi_awsize;
    wire [1:0] m_axi_awburst;
    wire [0:0] m_axi_awlock;
    wire [3:0] m_axi_awcache;
    wire [2:0] m_axi_awprot;
    wire [3:0] m_axi_awregion;
    wire [3:0] m_axi_awqos;
    wire [0:0] m_axi_awvalid;
    wire [0:0] m_axi_awready = 1'b1;
    wire [511:0] m_axi_wdata;
    wire [63:0] m_axi_wstrb;
    wire [0:0] m_axi_wlast;
    wire [0:0] m_axi_wvalid;
    wire [0:0] m_axi_wready = 1'b1;
    wire [1:0] m_axi_bid;
    wire [1:0] m_axi_bresp = 2'b00;
    wire [0:0] m_axi_bvalid;
    wire [0:0] m_axi_bready;
    wire [1:0] m_axi_arid;
    wire [31:0] m_axi_araddr;
    wire [7:0] m_axi_arlen;
    wire [2:0] m_axi_arsize;
    wire [1:0] m_axi_arburst;
    wire [0:0] m_axi_arlock;
    wire [3:0] m_axi_arcache;
    wire [2:0] m_axi_arprot;
    wire [3:0] m_axi_arregion;
    wire [3:0] m_axi_arqos;
    wire [0:0] m_axi_arvalid;
    wire [0:0] m_axi_arready = 1'b1;
    wire [1:0] m_axi_rid;
    wire [511:0] m_axi_rdata = 512'd0;
    wire [1:0] m_axi_rresp = 2'b00;
    wire [0:0] m_axi_rlast = 1'b1;
    wire [0:0] m_axi_rvalid;
    wire [0:0] m_axi_rready;

    reg [1:0] read_response_id [0:TRANSACTIONS-1];
    reg [63:0] read_response_due [0:TRANSACTIONS-1];
    integer read_response_head;
    integer read_response_tail;
    reg [1:0] write_response_id [0:TRANSACTIONS-1];
    reg [63:0] write_response_due [0:TRANSACTIONS-1];
    integer write_response_head;
    integer write_response_tail;

    assign m_axi_rvalid[0] = read_response_head < read_response_tail &&
        cycle_count >= read_response_due[read_response_head];
    assign m_axi_rid = read_response_id[read_response_head];
    assign m_axi_bvalid[0] = write_response_head < write_response_tail &&
        cycle_count >= write_response_due[write_response_head];
    assign m_axi_bid = write_response_id[write_response_head];

    axi_crossbar_v2_1_30_axi_crossbar #(
        .C_FAMILY("virtexuplus"),
        .C_NUM_SLAVE_SLOTS(3), .C_NUM_MASTER_SLOTS(1),
        .C_AXI_ID_WIDTH(2), .C_AXI_ADDR_WIDTH(32),
        .C_AXI_DATA_WIDTH(512), .C_AXI_PROTOCOL(0),
        .C_NUM_ADDR_RANGES(1),
        .C_M_AXI_BASE_ADDR(64'h0000000000000000),
        .C_M_AXI_ADDR_WIDTH(32'h00000020),
        .C_S_AXI_BASE_ID(96'h000000020000000100000000),
        .C_S_AXI_THREAD_ID_WIDTH(96'd0),
        .C_AXI_SUPPORTS_USER_SIGNALS(0),
        .C_AXI_AWUSER_WIDTH(1), .C_AXI_ARUSER_WIDTH(1),
        .C_AXI_WUSER_WIDTH(1), .C_AXI_RUSER_WIDTH(1),
        .C_AXI_BUSER_WIDTH(1),
        .C_M_AXI_WRITE_CONNECTIVITY(32'h00000007),
        .C_M_AXI_READ_CONNECTIVITY(32'h00000007),
        .C_R_REGISTER(0), .C_S_AXI_SINGLE_THREAD(96'd0),
        .C_S_AXI_WRITE_ACCEPTANCE({32'd1, 32'd8, ACCEPTANCE_WORD}),
        .C_S_AXI_READ_ACCEPTANCE({32'd8, 32'd1, ACCEPTANCE_WORD}),
        .C_M_AXI_WRITE_ISSUING(32'd8),
        .C_M_AXI_READ_ISSUING(32'd8),
        .C_S_AXI_ARB_PRIORITY(96'h0000000e0000000f00000000),
        .C_M_AXI_SECURE(32'd0), .C_CONNECTIVITY_MODE(1)
    ) dut (
        .aclk(aclk), .aresetn(aresetn),
        .s_axi_awid(s_axi_awid), .s_axi_awaddr(s_axi_awaddr),
        .s_axi_awlen(s_axi_awlen), .s_axi_awsize(s_axi_awsize),
        .s_axi_awburst(s_axi_awburst), .s_axi_awlock(s_axi_awlock),
        .s_axi_awcache(s_axi_awcache), .s_axi_awprot(s_axi_awprot),
        .s_axi_awqos(s_axi_awqos), .s_axi_awuser(3'd0),
        .s_axi_awvalid(s_axi_awvalid), .s_axi_awready(s_axi_awready),
        .s_axi_wid(6'd0), .s_axi_wdata(s_axi_wdata),
        .s_axi_wstrb(s_axi_wstrb), .s_axi_wlast(s_axi_wlast),
        .s_axi_wuser(3'd0), .s_axi_wvalid(s_axi_wvalid),
        .s_axi_wready(s_axi_wready), .s_axi_bid(s_axi_bid),
        .s_axi_bresp(s_axi_bresp), .s_axi_buser(),
        .s_axi_bvalid(s_axi_bvalid), .s_axi_bready(s_axi_bready),
        .s_axi_arid(s_axi_arid), .s_axi_araddr(s_axi_araddr),
        .s_axi_arlen(s_axi_arlen), .s_axi_arsize(s_axi_arsize),
        .s_axi_arburst(s_axi_arburst), .s_axi_arlock(s_axi_arlock),
        .s_axi_arcache(s_axi_arcache), .s_axi_arprot(s_axi_arprot),
        .s_axi_arqos(s_axi_arqos), .s_axi_aruser(3'd0),
        .s_axi_arvalid(s_axi_arvalid), .s_axi_arready(s_axi_arready),
        .s_axi_rid(s_axi_rid), .s_axi_rdata(s_axi_rdata),
        .s_axi_rresp(s_axi_rresp), .s_axi_rlast(s_axi_rlast),
        .s_axi_ruser(), .s_axi_rvalid(s_axi_rvalid),
        .s_axi_rready(s_axi_rready),
        .m_axi_awid(m_axi_awid), .m_axi_awaddr(m_axi_awaddr),
        .m_axi_awlen(m_axi_awlen), .m_axi_awsize(m_axi_awsize),
        .m_axi_awburst(m_axi_awburst), .m_axi_awlock(m_axi_awlock),
        .m_axi_awcache(m_axi_awcache), .m_axi_awprot(m_axi_awprot),
        .m_axi_awregion(m_axi_awregion), .m_axi_awqos(m_axi_awqos),
        .m_axi_awuser(), .m_axi_awvalid(m_axi_awvalid),
        .m_axi_awready(m_axi_awready), .m_axi_wid(),
        .m_axi_wdata(m_axi_wdata), .m_axi_wstrb(m_axi_wstrb),
        .m_axi_wlast(m_axi_wlast), .m_axi_wuser(),
        .m_axi_wvalid(m_axi_wvalid), .m_axi_wready(m_axi_wready),
        .m_axi_bid(m_axi_bid), .m_axi_bresp(m_axi_bresp),
        .m_axi_buser(1'b0), .m_axi_bvalid(m_axi_bvalid),
        .m_axi_bready(m_axi_bready), .m_axi_arid(m_axi_arid),
        .m_axi_araddr(m_axi_araddr), .m_axi_arlen(m_axi_arlen),
        .m_axi_arsize(m_axi_arsize), .m_axi_arburst(m_axi_arburst),
        .m_axi_arlock(m_axi_arlock), .m_axi_arcache(m_axi_arcache),
        .m_axi_arprot(m_axi_arprot), .m_axi_arregion(m_axi_arregion),
        .m_axi_arqos(m_axi_arqos), .m_axi_aruser(),
        .m_axi_arvalid(m_axi_arvalid), .m_axi_arready(m_axi_arready),
        .m_axi_rid(m_axi_rid), .m_axi_rdata(m_axi_rdata),
        .m_axi_rresp(m_axi_rresp), .m_axi_rlast(m_axi_rlast),
        .m_axi_ruser(1'b0), .m_axi_rvalid(m_axi_rvalid),
        .m_axi_rready(m_axi_rready)
    );

    initial begin
        repeat (12) @(posedge aclk);
        aresetn <= 1'b1;
    end

    always @(posedge aclk) begin
        if (!aresetn) begin
            cycle_count <= 0;
            first_cycle <= 0;
            first_seen <= 1'b0;
            reported <= 1'b0;
            failed <= 1'b0;
            read_valid <= 1'b0;
            read_id <= 0;
            read_addr <= 0;
            read_issued <= 0;
            read_completed <= 0;
            next_read_cycle <= 0;
            read_max_outstanding <= 0;
            write_awvalid <= 1'b0;
            write_wvalid <= 1'b0;
            write_id <= 0;
            write_addr <= 0;
            write_aw_done <= 1'b0;
            write_w_done <= 1'b0;
            write_issued <= 0;
            write_completed <= 0;
            next_write_cycle <= 0;
            write_max_outstanding <= 0;
            read_response_head <= 0;
            read_response_tail <= 0;
            write_response_head <= 0;
            write_response_tail <= 0;
        end else begin
            cycle_count <= cycle_count + 1'b1;

            if ((MODE == MODE_READ || MODE == MODE_READ_WRITE) &&
                !read_valid && read_issued < TRANSACTIONS &&
                cycle_count >= next_read_cycle) begin
                read_valid <= 1'b1;
                read_id <= read_issued[1:0];
                read_addr <= read_issued * 64;
            end
            if (read_valid && s_axi_arready[0]) begin
                read_valid <= 1'b0;
                read_issued <= read_issued + 1;
                next_read_cycle <= cycle_count + SOURCE_PERIOD - 1;
                if (!first_seen) begin
                    first_seen <= 1'b1;
                    first_cycle <= cycle_count;
                end
            end
            if (s_axi_rvalid[0] && s_axi_rready[0]) begin
                read_completed <= read_completed + 1;
                if (s_axi_rresp[1:0] != 2'b00 || !s_axi_rlast[0])
                    failed <= 1'b1;
            end
            if (read_issued - read_completed > read_max_outstanding)
                read_max_outstanding <= read_issued - read_completed;

            if ((MODE == MODE_WRITE || MODE == MODE_READ_WRITE) &&
                !write_awvalid && !write_wvalid &&
                !write_aw_done && !write_w_done &&
                write_issued < TRANSACTIONS &&
                cycle_count >= next_write_cycle) begin
                write_awvalid <= 1'b1;
                write_wvalid <= 1'b1;
                write_id <= write_issued[1:0];
                write_addr <= 32'h1000_0000 + write_issued * 64;
            end
            if (write_awvalid && s_axi_awready[0]) begin
                write_awvalid <= 1'b0;
                write_aw_done <= 1'b1;
            end
            if (write_wvalid && s_axi_wready[0]) begin
                write_wvalid <= 1'b0;
                write_w_done <= 1'b1;
            end
            if ((write_aw_done || (write_awvalid && s_axi_awready[0])) &&
                (write_w_done || (write_wvalid && s_axi_wready[0]))) begin
                write_aw_done <= 1'b0;
                write_w_done <= 1'b0;
                write_issued <= write_issued + 1;
                next_write_cycle <= cycle_count + SOURCE_PERIOD - 1;
                if (!first_seen) begin
                    first_seen <= 1'b1;
                    first_cycle <= cycle_count;
                end
            end
            if (s_axi_bvalid[0] && s_axi_bready[0]) begin
                write_completed <= write_completed + 1;
                if (s_axi_bresp[1:0] != 2'b00)
                    failed <= 1'b1;
            end
            if (write_issued - write_completed > write_max_outstanding)
                write_max_outstanding <= write_issued - write_completed;

            if (m_axi_arvalid[0] && m_axi_arready[0]) begin
                read_response_id[read_response_tail] <= m_axi_arid;
                read_response_due[read_response_tail] <=
                    cycle_count + RESPONSE_LATENCY;
                read_response_tail <= read_response_tail + 1;
            end
            if (m_axi_rvalid[0] && m_axi_rready[0])
                read_response_head <= read_response_head + 1;

            if (m_axi_awvalid[0] && m_axi_awready[0]) begin
                write_response_id[write_response_tail] <= m_axi_awid;
                write_response_due[write_response_tail] <=
                    cycle_count + RESPONSE_LATENCY;
                write_response_tail <= write_response_tail + 1;
            end
            if (m_axi_bvalid[0] && m_axi_bready[0])
                write_response_head <= write_response_head + 1;

            if (!reported && first_seen &&
                (MODE == MODE_WRITE || read_completed == TRANSACTIONS) &&
                (MODE == MODE_READ || write_completed == TRANSACTIONS)) begin
                reported <= 1'b1;
                $display("CROSSBAR_RESULT acceptance=%0d mode=%0d txns=%0d latency=%0d source_period=%0d cycles=%0d read_MBps=%0.3f write_MBps=%0.3f aggregate_MBps=%0.3f read_max=%0d write_max=%0d failed=%0d",
                    ACCEPTANCE, MODE, TRANSACTIONS, RESPONSE_LATENCY,
                    SOURCE_PERIOD, cycle_count - first_cycle + 1,
                    (MODE == MODE_WRITE) ? 0.0 :
                        (read_completed * 64.0 * 300.0) /
                        (cycle_count - first_cycle + 1),
                    (MODE == MODE_READ) ? 0.0 :
                        (write_completed * 64.0 * 300.0) /
                        (cycle_count - first_cycle + 1),
                    ((read_completed + write_completed) * 64.0 * 300.0) /
                        (cycle_count - first_cycle + 1),
                    read_max_outstanding, write_max_outstanding, failed);
                if (failed)
                    $fatal(1, "AXI protocol check failed");
                else
                    $finish;
            end

            if (cycle_count > TRANSACTIONS * (RESPONSE_LATENCY + 32))
                $fatal(1, "crossbar throughput test timed out");
        end
    end
endmodule
