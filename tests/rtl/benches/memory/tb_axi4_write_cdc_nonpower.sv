`timescale 1ns/1ps

module tb_axi4_write_cdc_nonpower;
    localparam integer WRITE_ID_BASE = 18;
    localparam integer WRITE_ID_COUNT = 14;
    localparam integer TRANSACTIONS = WRITE_ID_COUNT * 2;

    reg s_clk = 1'b0;
    reg m_clk = 1'b0;
    reg s_resetn = 1'b0;
    reg m_resetn = 1'b0;
    always #5 s_clk = ~s_clk;
    always #7 m_clk = ~m_clk;

    axi4_if #(.ADDR_WIDTH(32), .DATA_WIDTH(256), .ID_WIDTH(3)) s_axi();
    axi4_if #(.ADDR_WIDTH(33), .DATA_WIDTH(256), .ID_WIDTH(5)) m_axi();

    wire [31:0] perf_aw_count;
    wire [31:0] perf_w_count;
    wire [31:0] perf_b_count;
    wire [31:0] perf_outstanding_current;
    wire [31:0] perf_outstanding_max;
    wire [31:0] perf_write_id_mask;
    wire [31:0] perf_protocol_errors;

    axi4_write_cdc #(
        .FIFO_ADDR_WIDTH(5),
        .FBUS_WRITE_ID(WRITE_ID_BASE),
        .FBUS_WRITE_ID_COUNT(WRITE_ID_COUNT)
    ) dut (
        .s_axi(s_axi), .m_clk(m_clk), .m_resetn(m_resetn), .m_axi(m_axi),
        .perf_aw_count(perf_aw_count), .perf_w_count(perf_w_count),
        .perf_b_count(perf_b_count), .perf_aw_stall_cycles(),
        .perf_w_stall_cycles(), .perf_b_stall_cycles(),
        .perf_outstanding_current(perf_outstanding_current),
        .perf_outstanding_max(perf_outstanding_max),
        .perf_write_id_mask(perf_write_id_mask),
        .perf_protocol_errors(perf_protocol_errors)
    );

    reg source_w_active;
    integer source_aw_index;
    integer source_b_count;
    integer destination_aw_count;
    integer destination_w_count;
    integer response_count;

    function automatic [2:0] source_id(input integer index);
        source_id = 3'(index % 8);
    endfunction

    function automatic [4:0] response_id(input integer index);
        response_id = 5'(WRITE_ID_BASE + WRITE_ID_COUNT - 1 -
                         (index % WRITE_ID_COUNT));
    endfunction

    assign s_axi.aclk = s_clk;
    assign s_axi.aresetn = s_resetn;
    assign s_axi.awid = source_id(source_aw_index);
    assign s_axi.awaddr = 32'h3000_0000 + 32'(source_aw_index * 64);
    assign s_axi.awlen = 8'd0;
    assign s_axi.awsize = 3'd5;
    assign s_axi.awburst = 2'b01;
    assign s_axi.awlock = 1'b0;
    assign s_axi.awcache = 4'b0010;
    assign s_axi.awprot = 3'b000;
    assign s_axi.awqos = 4'h0;
    assign s_axi.awvalid = source_aw_index < TRANSACTIONS && !source_w_active;
    assign s_axi.wdata = {8{32'(source_aw_index)}};
    assign s_axi.wstrb = 32'hffff_ffff;
    assign s_axi.wlast = 1'b1;
    assign s_axi.wvalid = source_w_active;
    assign s_axi.bready = 1'b1;
    assign s_axi.arid = '0;
    assign s_axi.araddr = '0;
    assign s_axi.arlen = '0;
    assign s_axi.arsize = '0;
    assign s_axi.arburst = '0;
    assign s_axi.arlock = '0;
    assign s_axi.arcache = '0;
    assign s_axi.arprot = '0;
    assign s_axi.arqos = '0;
    assign s_axi.arvalid = 1'b0;
    assign s_axi.rready = 1'b0;

    assign m_axi.awready = 1'b1;
    assign m_axi.wready = 1'b1;
    assign m_axi.bid = response_id(response_count);
    assign m_axi.bresp = 2'b00;
    assign m_axi.bvalid = response_count < TRANSACTIONS &&
                          destination_w_count >=
                              ((response_count / WRITE_ID_COUNT) + 1) *
                              WRITE_ID_COUNT;
    assign m_axi.arready = 1'b0;
    assign m_axi.rid = '0;
    assign m_axi.rdata = '0;
    assign m_axi.rresp = 2'b00;
    assign m_axi.rlast = 1'b0;
    assign m_axi.rvalid = 1'b0;

    always @(posedge s_clk or negedge s_resetn) begin
        if (!s_resetn) begin
            source_w_active <= 1'b0;
            source_aw_index <= 0;
            source_b_count <= 0;
        end else begin
            if (s_axi.awvalid && s_axi.awready)
                source_w_active <= 1'b1;
            if (s_axi.wvalid && s_axi.wready) begin
                source_w_active <= 1'b0;
                source_aw_index <= source_aw_index + 1;
            end
            if (s_axi.bvalid && s_axi.bready) begin
                if (s_axi.bid !== source_id(source_b_count) ||
                    s_axi.bresp !== 2'b00)
                    $fatal(1, "source response mismatch index=%0d id=%0d",
                           source_b_count, s_axi.bid);
                source_b_count <= source_b_count + 1;
            end
        end
    end

    always @(posedge m_clk or negedge m_resetn) begin
        if (!m_resetn) begin
            destination_aw_count <= 0;
            destination_w_count <= 0;
            response_count <= 0;
        end else begin
            if (m_axi.awvalid && m_axi.awready) begin
                if (m_axi.awid !==
                    5'(WRITE_ID_BASE + destination_aw_count % WRITE_ID_COUNT))
                    $fatal(1, "write ID rotation mismatch index=%0d id=%0d",
                           destination_aw_count, m_axi.awid);
                destination_aw_count <= destination_aw_count + 1;
            end
            if (m_axi.wvalid && m_axi.wready) begin
                if (!m_axi.wlast)
                    $fatal(1, "expected a one-beat test burst");
                destination_w_count <= destination_w_count + 1;
            end
            if (m_axi.bvalid && m_axi.bready)
                response_count <= response_count + 1;
        end
    end

    initial begin
        repeat (6) @(negedge s_clk);
        s_resetn = 1'b1;
        m_resetn = 1'b1;
        wait (source_b_count == TRANSACTIONS);
        repeat (4) @(negedge m_clk);
        if (perf_aw_count != TRANSACTIONS || perf_w_count != TRANSACTIONS ||
            perf_b_count != TRANSACTIONS || perf_outstanding_current != 0 ||
            perf_outstanding_max != WRITE_ID_COUNT ||
            perf_write_id_mask != 32'hfffc_0000 ||
            perf_protocol_errors != 0)
            $fatal(1, "writer counters mismatch aw/w/b=%0d/%0d/%0d current/max=%0d/%0d mask=%h errors=%0d",
                   perf_aw_count, perf_w_count, perf_b_count,
                   perf_outstanding_current, perf_outstanding_max,
                   perf_write_id_mask, perf_protocol_errors);
        $display("AXI4_WRITE_CDC_NONPOWER=PASS transactions=%0d max=%0d mask=%h",
                 TRANSACTIONS, perf_outstanding_max, perf_write_id_mask);
        $finish;
    end

    initial begin
        #2000000;
        $fatal(1, "timeout aw/w/b=%0d/%0d/%0d responses=%0d",
               destination_aw_count, destination_w_count,
               source_b_count, response_count);
    end
endmodule
