`timescale 1ns/1ps

module tb_axi4_write_cdc #(parameter integer TEST_REMAP_ID = 31);
    reg s_clk = 1'b0;
    reg m_clk = 1'b0;
    reg s_resetn = 1'b0;
    reg m_resetn = 1'b0;
    always #5 s_clk = ~s_clk;
    always #7 m_clk = ~m_clk;

    axi4_if #(.ADDR_WIDTH(32), .DATA_WIDTH(256), .ID_WIDTH(3)) s_axi();
    axi4_if #(.ADDR_WIDTH(33), .DATA_WIDTH(256), .ID_WIDTH(5)) m_axi();
    reg m_bvalid;
    reg [4:0] m_bid;
    reg [1:0] m_bresp;
    reg m_aw_seen;
    reg [32:0] m_awaddr_seen;
    reg [4:0] m_awid_seen;
    reg [4:0] m_current_id;
    reg m_w_seen;
    reg [255:0] m_wdata_seen;
    reg m_wlast_seen;
    integer timeout;

    axi4_write_cdc #(.FIFO_ADDR_WIDTH(4), .FBUS_WRITE_ID(TEST_REMAP_ID)) dut (
        .s_axi(s_axi), .m_clk(m_clk), .m_resetn(m_resetn), .m_axi(m_axi)
    );

    assign s_axi.aclk = s_clk;
    assign s_axi.aresetn = s_resetn;
    assign m_axi.awready = 1'b1;
    assign m_axi.wready = 1'b1;
    assign m_axi.bid = m_bid;
    assign m_axi.bresp = m_bresp;
    assign m_axi.bvalid = m_bvalid;
    assign m_axi.arready = 1'b0;
    assign m_axi.rid = 4'd0;
    assign m_axi.rdata = 256'd0;
    assign m_axi.rresp = 2'b00;
    assign m_axi.rlast = 1'b0;
    assign m_axi.rvalid = 1'b0;

    always @(posedge m_clk) begin
        if (!m_resetn) begin
            m_bvalid <= 1'b0;
            m_bid <= 4'd0;
            m_bresp <= 2'b00;
            m_aw_seen <= 1'b0;
            m_awaddr_seen <= 33'd0;
            m_awid_seen <= 4'd0;
            m_current_id <= 4'd0;
            m_w_seen <= 1'b0;
            m_wdata_seen <= 256'd0;
            m_wlast_seen <= 1'b0;
        end else begin
            if (m_axi.awvalid && m_axi.awready) begin
                m_aw_seen <= 1'b1;
                m_awaddr_seen <= m_axi.awaddr;
                m_awid_seen <= m_axi.awid;
                m_current_id <= m_axi.awid;
            end
            if (m_axi.wvalid && m_axi.wready) begin
                m_w_seen <= 1'b1;
                m_wdata_seen <= m_axi.wdata;
                m_wlast_seen <= m_axi.wlast;
            end
            if (m_axi.wvalid && m_axi.wready && m_axi.wlast) begin
                m_bvalid <= 1'b1;
                m_bid <= m_current_id;
                m_bresp <= 2'b00;
            end else if (m_bvalid && m_axi.bready) begin
                m_bvalid <= 1'b0;
            end
        end
    end

    task automatic send_single_write(
        input [31:0] address,
        input [2:0] id,
        input [255:0] data
    );
        begin
            @(negedge s_clk);
            s_axi.awid = id;
            s_axi.awaddr = address;
            s_axi.awlen = 8'd0;
            s_axi.awsize = 3'd5;
            s_axi.awburst = 2'b01;
            s_axi.awlock = 1'b0;
            s_axi.awcache = 4'd0;
            s_axi.awprot = 3'd0;
            s_axi.awqos = 4'd0;
            s_axi.awvalid = 1'b1;
            timeout = 0;
            do begin
                @(posedge s_clk);
                timeout = timeout + 1;
                if (timeout > 100)
                    $fatal(1, "source AW timeout");
            end while (!s_axi.awready);
            @(negedge s_clk);
            s_axi.awvalid = 1'b0;

            s_axi.wdata = data;
            s_axi.wstrb = 32'hffff_ffff;
            s_axi.wlast = 1'b1;
            s_axi.wvalid = 1'b1;
            timeout = 0;
            do begin
                @(posedge s_clk);
                timeout = timeout + 1;
                if (timeout > 100)
                    $fatal(1, "source W timeout");
            end while (!s_axi.wready);
            @(negedge s_clk);
            s_axi.wvalid = 1'b0;
        end
    endtask

    task automatic expect_write(input [32:0] expected_address,
                                input [2:0] expected_id,
                                input [255:0] expected_data);
        begin
            timeout = 0;
            while (!m_aw_seen || m_awaddr_seen !== expected_address) begin
                @(posedge m_clk);
                timeout = timeout + 1;
                if (timeout > 200)
                    $fatal(1, "destination AW timeout");
            end
            if (m_awaddr_seen !== expected_address ||
                m_awid_seen !== (TEST_REMAP_ID >= 0 ? 5'(TEST_REMAP_ID) : {2'b0, expected_id}))
                $fatal(1, "FBus address/id mismatch: addr=%h id=%h",
                       m_awaddr_seen, m_awid_seen);

            timeout = 0;
            while (!m_w_seen || m_wdata_seen !== expected_data) begin
                @(posedge m_clk);
                timeout = timeout + 1;
                if (timeout > 200)
                    $fatal(1, "destination W timeout");
            end
            if (m_wdata_seen !== expected_data || !m_wlast_seen)
                $fatal(1, "FBus write payload mismatch");
        end
    endtask

    task automatic expect_response(input [2:0] expected_id);
        begin
            timeout = 0;
            while (!s_axi.bvalid) begin
                @(posedge s_clk);
                timeout = timeout + 1;
                if (timeout > 200)
                    $fatal(1, "source B timeout");
            end
            if (s_axi.bid !== expected_id || s_axi.bresp !== 2'b00)
                $fatal(1, "source B mismatch: got id=%0d resp=%0d expected id=%0d",
                       s_axi.bid, s_axi.bresp, expected_id);
            s_axi.bready = 1'b1;
            @(posedge s_clk);
            @(negedge s_clk);
            s_axi.bready = 1'b0;
        end
    endtask

    initial begin
        s_axi.awid = 3'd0;
        s_axi.awaddr = 32'd0;
        s_axi.awlen = 8'd0;
        s_axi.awsize = 3'd0;
        s_axi.awburst = 2'd0;
        s_axi.awlock = 1'b0;
        s_axi.awcache = 4'd0;
        s_axi.awprot = 3'd0;
        s_axi.awqos = 4'd0;
        s_axi.awvalid = 1'b0;
        s_axi.wdata = 256'd0;
        s_axi.wstrb = 32'd0;
        s_axi.wlast = 1'b0;
        s_axi.wvalid = 1'b0;
        s_axi.bready = 1'b0;
        repeat (4) @(posedge s_clk);
        s_resetn = 1'b1;
        repeat (4) @(posedge m_clk);
        m_resetn = 1'b1;

        send_single_write(32'h3000_0020, 3'd5, 256'h1234);
        expect_write(33'h0_b000_0020, 3'd5, 256'h1234);
        expect_response(3'd5);
        send_single_write(32'h3000_0040, 3'd2, 256'h5678);
        expect_write(33'h0_b000_0040, 3'd2, 256'h5678);
        expect_response(3'd2);
        send_single_write(32'h3000_0060, 3'd7, 256'h9abc);
        expect_write(33'h0_b000_0060, 3'd7, 256'h9abc);
        expect_response(3'd7);
        $display("tb_axi4_write_cdc PASS remap=%0d", TEST_REMAP_ID);
        $finish;
    end
endmodule
