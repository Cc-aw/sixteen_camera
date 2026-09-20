`timescale 1ps/1ps

module tb_axi4_write_cdc_stress #(
    parameter integer TEST_REMAP_ID = 31,
    parameter integer TRANSACTIONS = 256
);
    // Production clocks: camera_video_clk ~= 150.06 MHz, SoC/FBus = 100 MHz.
    reg s_clk = 1'b0;
    reg m_clk = 1'b0;
    reg s_resetn = 1'b0;
    reg m_resetn = 1'b0;
    always #3332 s_clk = ~s_clk;
    always #5000 m_clk = ~m_clk;

    axi4_if #(.ADDR_WIDTH(32), .DATA_WIDTH(256), .ID_WIDTH(3)) s_axi();
    axi4_if #(.ADDR_WIDTH(33), .DATA_WIDTH(256), .ID_WIDTH(5)) m_axi();

    integer s_cycle;
    integer m_cycle;
    integer aw_sent;
    integer w_sent;
    integer b_received;
    integer aw_received;
    integer w_received;
    integer b_issued;
    integer pending_responses;
    integer timeout;
    reg [4:0] destination_ids [0:TRANSACTIONS-1];

    function automatic [31:0] source_address(input integer index);
        source_address = 32'h3000_0000 + index * 32;
    endfunction

    function automatic [255:0] source_data(input integer index);
        source_data = {8{32'h51a0_0000 + index}};
    endfunction

    axi4_write_cdc #(
        .FIFO_ADDR_WIDTH(4), .FBUS_WRITE_ID(TEST_REMAP_ID),
        .MAX_OUTSTANDING(8)
    ) dut (
        .s_axi(s_axi), .m_clk(m_clk), .m_resetn(m_resetn), .m_axi(m_axi)
    );

    assign s_axi.aclk = s_clk;
    assign s_axi.aresetn = s_resetn;

    // Deterministic, unrelated backpressure patterns exercise every channel
    // without relying on simulator-specific random seeds.
    assign m_axi.awready = m_resetn && (m_cycle % 7 != 1);
    assign m_axi.wready = m_resetn && (m_cycle % 5 != 2);
    assign m_axi.bid = destination_ids[b_issued];
    assign m_axi.bresp = 2'b00;
    assign m_axi.bvalid = m_resetn && pending_responses != 0;
    assign m_axi.arready = 1'b0;
    assign m_axi.rid = '0;
    assign m_axi.rdata = '0;
    assign m_axi.rresp = 2'b00;
    assign m_axi.rlast = 1'b0;
    assign m_axi.rvalid = 1'b0;

    always @(*) begin
        s_axi.awid = aw_sent[2:0];
        s_axi.awaddr = source_address(aw_sent);
        s_axi.awlen = 8'd0;
        s_axi.awsize = 3'd5;
        s_axi.awburst = 2'b01;
        s_axi.awlock = 1'b0;
        s_axi.awcache = 4'b0010;
        s_axi.awprot = 3'b000;
        s_axi.awqos = 4'h6;
        s_axi.awvalid = s_resetn && aw_sent < TRANSACTIONS;
        s_axi.wdata = source_data(w_sent);
        s_axi.wstrb = 32'hffff_ffff;
        s_axi.wlast = 1'b1;
        s_axi.wvalid = s_resetn && w_sent < TRANSACTIONS;
        s_axi.bready = s_resetn && (s_cycle % 11 != 3);
    end

    always @(posedge s_clk) begin
        if (!s_resetn) begin
            s_cycle <= 0;
            aw_sent <= 0;
            w_sent <= 0;
            b_received <= 0;
        end else begin
            s_cycle <= s_cycle + 1;
            if (s_axi.awvalid && s_axi.awready)
                aw_sent <= aw_sent + 1;
            if (s_axi.wvalid && s_axi.wready)
                w_sent <= w_sent + 1;
            if (s_axi.bvalid && s_axi.bready) begin
                if (s_axi.bresp != 2'b00 ||
                    s_axi.bid != b_received[2:0])
                    $fatal(1, "source B mismatch index=%0d id=%0d resp=%0d",
                           b_received, s_axi.bid, s_axi.bresp);
                b_received <= b_received + 1;
            end
        end
    end

    always @(posedge m_clk) begin
        if (!m_resetn) begin
            m_cycle <= 0;
            aw_received <= 0;
            w_received <= 0;
            b_issued <= 0;
            pending_responses <= 0;
        end else begin
            m_cycle <= m_cycle + 1;
            if (m_axi.awvalid && m_axi.awready) begin
                if (m_axi.awaddr !==
                        {1'b0, source_address(aw_received) | 32'h8000_0000} ||
                    m_axi.awid !== (TEST_REMAP_ID >= 0 ?
                        5'(TEST_REMAP_ID) : {2'b00, aw_received[2:0]}))
                    $fatal(1, "destination AW mismatch index=%0d addr=%h id=%0d",
                           aw_received, m_axi.awaddr, m_axi.awid);
                destination_ids[aw_received] <= m_axi.awid;
                aw_received <= aw_received + 1;
            end
            if (m_axi.wvalid && m_axi.wready) begin
                if (m_axi.wdata !== source_data(w_received) ||
                    m_axi.wstrb !== 32'hffff_ffff || !m_axi.wlast)
                    $fatal(1, "destination W mismatch index=%0d", w_received);
                w_received <= w_received + 1;
            end
            case ({m_axi.wvalid && m_axi.wready && m_axi.wlast,
                   m_axi.bvalid && m_axi.bready})
                2'b10: pending_responses <= pending_responses + 1;
                2'b01: pending_responses <= pending_responses - 1;
                default: ;
            endcase
            if (m_axi.bvalid && m_axi.bready)
                b_issued <= b_issued + 1;
        end
    end

    initial begin
        s_cycle = 0;
        m_cycle = 0;
        aw_sent = 0;
        w_sent = 0;
        b_received = 0;
        aw_received = 0;
        w_received = 0;
        b_issued = 0;
        pending_responses = 0;
        repeat (8) @(posedge s_clk);
        s_resetn = 1'b1;
        repeat (8) @(posedge m_clk);
        m_resetn = 1'b1;
        timeout = 0;
        while (b_received != TRANSACTIONS) begin
            @(posedge s_clk);
            timeout = timeout + 1;
            if (timeout > TRANSACTIONS * 200)
                $fatal(1, "stress timeout aw/w/b=%0d/%0d/%0d",
                       aw_sent, w_sent, b_received);
        end
        repeat (20) @(posedge m_clk);
        if (aw_sent != TRANSACTIONS || w_sent != TRANSACTIONS ||
            aw_received != TRANSACTIONS || w_received != TRANSACTIONS ||
            b_issued != TRANSACTIONS || pending_responses != 0)
            $fatal(1, "final counts source=%0d/%0d/%0d dest=%0d/%0d/%0d pending=%0d",
                   aw_sent, w_sent, b_received, aw_received, w_received,
                   b_issued, pending_responses);
        $display("tb_axi4_write_cdc_stress PASS remap=%0d transactions=%0d",
                 TEST_REMAP_ID, TRANSACTIONS);
        $finish;
    end
endmodule
