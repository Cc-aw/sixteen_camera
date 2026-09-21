`timescale 1ns/1ps

module tb_axi4_write_cdc;
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
    integer destination_aw_count;
    integer destination_w_count;
    integer source_b_count;
    integer timeout;
    reg destination_w_active;

    wire [31:0] perf_aw_count, perf_w_count, perf_b_count;
    wire [31:0] perf_aw_stall_cycles, perf_w_stall_cycles;
    wire [31:0] perf_b_stall_cycles;
    wire [31:0] perf_outstanding_current, perf_outstanding_max;
    wire [31:0] perf_write_id_mask, perf_protocol_errors;

    axi4_write_cdc #(
        .FIFO_ADDR_WIDTH(4), .FBUS_WRITE_ID(24),
        .FBUS_WRITE_ID_COUNT(8)
    ) dut (
        .s_axi(s_axi), .m_clk(m_clk), .m_resetn(m_resetn), .m_axi(m_axi),
        .perf_aw_count(perf_aw_count), .perf_w_count(perf_w_count),
        .perf_b_count(perf_b_count),
        .perf_aw_stall_cycles(perf_aw_stall_cycles),
        .perf_w_stall_cycles(perf_w_stall_cycles),
        .perf_b_stall_cycles(perf_b_stall_cycles),
        .perf_outstanding_current(perf_outstanding_current),
        .perf_outstanding_max(perf_outstanding_max),
        .perf_write_id_mask(perf_write_id_mask),
        .perf_protocol_errors(perf_protocol_errors)
    );

    assign s_axi.aclk = s_clk;
    assign s_axi.aresetn = s_resetn;
    assign m_axi.awready = 1'b1;
    assign m_axi.wready = 1'b1;
    assign m_axi.bid = m_bid;
    assign m_axi.bresp = m_bresp;
    assign m_axi.bvalid = m_bvalid;
    assign m_axi.arready = 1'b0;
    assign m_axi.rid = 5'd0;
    assign m_axi.rdata = 256'd0;
    assign m_axi.rresp = 2'b00;
    assign m_axi.rlast = 1'b0;
    assign m_axi.rvalid = 1'b0;

    function automatic [2:0] original_id(input integer index);
        case (index)
        0: original_id = 3'd5;
        1: original_id = 3'd2;
        2: original_id = 3'd7;
        3: original_id = 3'd1;
        4: original_id = 3'd4;
        5: original_id = 3'd3;
        6: original_id = 3'd6;
        default: original_id = 3'd0;
        endcase
    endfunction

    always @(posedge m_clk) begin
        if (!m_resetn) begin
            destination_aw_count <= 0;
            destination_w_count <= 0;
            destination_w_active <= 1'b0;
        end else begin
            if (m_axi.awvalid && m_axi.awready) begin
                if (destination_w_active)
                    $fatal(1, "AW accepted before previous WLAST");
                if (m_axi.awid !== 5'(24 + destination_aw_count) ||
                    m_axi.awaddr !==
                        (33'(32'h3000_0000 + destination_aw_count * 32) |
                         33'h0_8000_0000) || m_axi.awlen !== 8'd0)
                    $fatal(1, "destination AW mismatch index=%0d id=%0d addr=%h",
                           destination_aw_count, m_axi.awid, m_axi.awaddr);
                destination_w_active <= 1'b1;
                destination_aw_count <= destination_aw_count + 1;
            end
            if (m_axi.wvalid && m_axi.wready) begin
                if (!destination_w_active || !m_axi.wlast ||
                    m_axi.wdata !== 256'(destination_w_count + 1))
                    $fatal(1, "destination W mismatch index=%0d",
                           destination_w_count);
                destination_w_active <= 1'b0;
                destination_w_count <= destination_w_count + 1;
            end
        end
    end

    always @(posedge s_clk) begin
        if (!s_resetn)
            source_b_count <= 0;
        else if (s_axi.bvalid && s_axi.bready) begin
            if (s_axi.bid !== original_id(source_b_count))
                $fatal(1, "source BID order mismatch index=%0d got=%0d",
                       source_b_count, s_axi.bid);
            if (s_axi.bresp !== (source_b_count == 2 ? 2'b10 : 2'b00))
                $fatal(1, "source BRESP mismatch index=%0d got=%0d",
                       source_b_count, s_axi.bresp);
            source_b_count <= source_b_count + 1;
        end
    end

    task automatic send_single_write(input integer index);
        begin
            @(negedge s_clk);
            s_axi.awid = original_id(index);
            s_axi.awaddr = 32'h3000_0000 + index * 32;
            s_axi.awlen = 8'd0;
            s_axi.awsize = 3'd5;
            s_axi.awburst = 2'b01;
            s_axi.awvalid = 1'b1;
            while (!s_axi.awready)
                @(negedge s_clk);
            @(negedge s_clk);
            s_axi.awvalid = 1'b0;
            s_axi.wdata = 256'(index + 1);
            s_axi.wstrb = 32'hffff_ffff;
            s_axi.wlast = 1'b1;
            s_axi.wvalid = 1'b1;
            while (!s_axi.wready)
                @(negedge s_clk);
            @(negedge s_clk);
            s_axi.wvalid = 1'b0;
        end
    endtask

    task automatic send_response(input [4:0] id, input [1:0] response);
        begin
            @(negedge m_clk);
            m_bid = id;
            m_bresp = response;
            m_bvalid = 1'b1;
            while (!m_axi.bready)
                @(negedge m_clk);
            @(negedge m_clk);
            m_bvalid = 1'b0;
        end
    endtask

    initial begin
        s_axi.awid = 3'd0;
        s_axi.awaddr = 32'd0;
        s_axi.awlen = 8'd0;
        s_axi.awsize = 3'd5;
        s_axi.awburst = 2'b01;
        s_axi.awlock = 1'b0;
        s_axi.awcache = 4'd0;
        s_axi.awprot = 3'd0;
        s_axi.awqos = 4'd0;
        s_axi.awvalid = 1'b0;
        s_axi.wdata = 256'd0;
        s_axi.wstrb = 32'd0;
        s_axi.wlast = 1'b0;
        s_axi.wvalid = 1'b0;
        s_axi.bready = 1'b1;
        m_bvalid = 1'b0;
        m_bid = 5'd0;
        m_bresp = 2'b00;

        repeat (5) @(negedge s_clk);
        s_resetn = 1'b1;
        repeat (5) @(negedge m_clk);
        m_resetn = 1'b1;

        for (integer write_index = 0; write_index < 8;
             write_index = write_index + 1)
            send_single_write(write_index);

        timeout = 0;
        while (destination_aw_count != 8 || destination_w_count != 8) begin
            @(posedge m_clk);
            timeout = timeout + 1;
            if (timeout > 300)
                $fatal(1, "destination write timeout AW=%0d W=%0d",
                       destination_aw_count, destination_w_count);
        end
        if (perf_outstanding_max !== 32'd8 ||
            perf_outstanding_current !== 32'd8)
            $fatal(1, "eight writes not outstanding: cur=%0d max=%0d",
                   perf_outstanding_current, perf_outstanding_max);

        // Cross-ID B order is intentionally scrambled. ID 26 carries SLVERR.
        send_response(5'd31, 2'b00);
        send_response(5'd29, 2'b00);
        send_response(5'd30, 2'b00);
        send_response(5'd24, 2'b00);
        send_response(5'd26, 2'b10);
        send_response(5'd25, 2'b00);
        send_response(5'd27, 2'b00);
        send_response(5'd28, 2'b00);

        timeout = 0;
        while (source_b_count != 8) begin
            @(posedge s_clk);
            timeout = timeout + 1;
            if (timeout > 300)
                $fatal(1, "ordered source B timeout count=%0d", source_b_count);
        end
        repeat (4) @(posedge m_clk);
        if (perf_aw_count !== 32'd8 || perf_w_count !== 32'd8 ||
            perf_b_count !== 32'd8 || perf_outstanding_current !== 0 ||
            perf_outstanding_max !== 8 ||
            perf_write_id_mask !== 32'hff00_0000 ||
            perf_protocol_errors !== 0)
            $fatal(1, "counter mismatch AW/W/B=%0d/%0d/%0d cur/max=%0d/%0d mask=%h proto=%0d",
                   perf_aw_count, perf_w_count, perf_b_count,
                   perf_outstanding_current, perf_outstanding_max,
                   perf_write_id_mask, perf_protocol_errors);
        $display("AXI4_WRITE_CDC_MULTI_OUTSTANDING=PASS AW=%0d W=%0d B=%0d max=%0d mask=%h",
                 perf_aw_count, perf_w_count, perf_b_count,
                 perf_outstanding_max, perf_write_id_mask);
        $finish;
    end

    initial begin
        #200000;
        $fatal(1, "CDC test timeout");
    end
endmodule
