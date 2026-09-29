`timescale 1ns/1ps

module tb_axi4_channel_join;
    logic clk = 1'b0;
    logic resetn = 1'b0;
    always #5 clk = ~clk;

    axi4_if #(.ADDR_WIDTH(33), .DATA_WIDTH(256), .ID_WIDTH(4)) write_axi();
    axi4_if #(.ADDR_WIDTH(33), .DATA_WIDTH(256), .ID_WIDTH(4)) read_axi();
    axi4_if #(.ADDR_WIDTH(33), .DATA_WIDTH(256), .ID_WIDTH(4)) m_axi();

    axi4_channel_join dut (
        .write_axi(write_axi), .read_axi(read_axi),
        .clk(clk), .resetn(resetn), .m_axi(m_axi)
    );

    initial begin
        write_axi.awid = 4'ha;
        write_axi.awaddr = 33'h1_1234_5000;
        write_axi.awlen = 8'd3;
        write_axi.awsize = 3'd5;
        write_axi.awburst = 2'b01;
        write_axi.awlock = 1'b0;
        write_axi.awcache = 4'b0011;
        write_axi.awprot = 3'b010;
        write_axi.awqos = 4'h4;
        write_axi.awvalid = 1'b0;
        write_axi.wdata = {8{32'h0123_4567}};
        write_axi.wstrb = 32'hffff_00ff;
        write_axi.wlast = 1'b1;
        write_axi.wvalid = 1'b0;
        write_axi.bready = 1'b0;
        write_axi.arvalid = 1'b0;
        write_axi.rready = 1'b0;

        read_axi.arid = 4'h5;
        read_axi.araddr = 33'h1_7654_3000;
        read_axi.arlen = 8'd7;
        read_axi.arsize = 3'd5;
        read_axi.arburst = 2'b01;
        read_axi.arlock = 1'b0;
        read_axi.arcache = 4'b0010;
        read_axi.arprot = 3'b001;
        read_axi.arqos = 4'h7;
        read_axi.arvalid = 1'b0;
        read_axi.rready = 1'b0;
        read_axi.awvalid = 1'b0;
        read_axi.wvalid = 1'b0;
        read_axi.bready = 1'b0;

        m_axi.awready = 1'b0;
        m_axi.wready = 1'b0;
        m_axi.bid = 4'ha;
        m_axi.bresp = 2'b10;
        m_axi.bvalid = 1'b0;
        m_axi.arready = 1'b0;
        m_axi.rid = 4'h5;
        m_axi.rdata = {8{32'h89ab_cdef}};
        m_axi.rresp = 2'b01;
        m_axi.rlast = 1'b1;
        m_axi.rvalid = 1'b0;

        repeat (2) @(posedge clk);
        resetn = 1'b1;
        write_axi.awvalid = 1'b1;
        write_axi.wvalid = 1'b1;
        write_axi.bready = 1'b1;
        read_axi.arvalid = 1'b1;
        read_axi.rready = 1'b1;
        m_axi.awready = 1'b1;
        m_axi.wready = 1'b1;
        m_axi.arready = 1'b1;
        m_axi.bvalid = 1'b1;
        m_axi.rvalid = 1'b1;
        #1;

        if (m_axi.awaddr !== write_axi.awaddr ||
            m_axi.wdata !== write_axi.wdata ||
            !write_axi.awready || !write_axi.wready)
            $fatal(1, "write channels were not routed");
        if (m_axi.araddr !== read_axi.araddr || !read_axi.arready)
            $fatal(1, "read address channel was not routed");
        if (write_axi.bid !== m_axi.bid || write_axi.bresp !== m_axi.bresp ||
            !write_axi.bvalid || !m_axi.bready)
            $fatal(1, "write response was not routed");
        if (read_axi.rid !== m_axi.rid || read_axi.rdata !== m_axi.rdata ||
            read_axi.rresp !== m_axi.rresp || !read_axi.rvalid ||
            !read_axi.rlast || !m_axi.rready)
            $fatal(1, "read response was not routed");
        if (write_axi.arready || write_axi.rvalid ||
            read_axi.awready || read_axi.wready || read_axi.bvalid)
            $fatal(1, "unused half-interface was not terminated");

        $display("TB_AXI4_CHANNEL_JOIN=PASS");
        $finish;
    end
endmodule
