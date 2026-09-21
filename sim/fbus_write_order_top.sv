module fbus_write_order_top (
    input wire s_clk,
    input wire m_clk,
    input wire s_resetn,
    input wire m_resetn,
    output wire done,
    output wire failed,
    output wire [31:0] aw_count,
    output wire [31:0] w_count,
    output wire [31:0] b_count,
    output wire [31:0] outstanding_current,
    output wire [31:0] outstanding_max,
    output wire [31:0] write_id_mask,
    output wire [31:0] protocol_errors,
    output wire [31:0] destination_aw_count_debug,
    output wire [31:0] destination_w_count_debug,
    output wire [31:0] source_b_count_debug
);
    axi4_if #(.ADDR_WIDTH(32), .DATA_WIDTH(256), .ID_WIDTH(3)) s_axi();
    axi4_if #(.ADDR_WIDTH(33), .DATA_WIDTH(256), .ID_WIDTH(5)) m_axi();
    wire [31:0] unused_aw_stall, unused_w_stall, unused_b_stall;

    axi4_write_cdc #(
        .FIFO_ADDR_WIDTH(4), .FBUS_WRITE_ID(24),
        .FBUS_WRITE_ID_COUNT(8)
    ) dut (
        .s_axi(s_axi), .m_clk(m_clk), .m_resetn(m_resetn), .m_axi(m_axi),
        .perf_aw_count(aw_count), .perf_w_count(w_count),
        .perf_b_count(b_count),
        .perf_aw_stall_cycles(unused_aw_stall),
        .perf_w_stall_cycles(unused_w_stall),
        .perf_b_stall_cycles(unused_b_stall),
        .perf_outstanding_current(outstanding_current),
        .perf_outstanding_max(outstanding_max),
        .perf_write_id_mask(write_id_mask),
        .perf_protocol_errors(protocol_errors)
    );

    function automatic [2:0] original_id(input [3:0] index);
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

    function automatic [4:0] response_id(input [3:0] index);
        case (index)
        0: response_id = 5'd31;
        1: response_id = 5'd29;
        2: response_id = 5'd30;
        3: response_id = 5'd24;
        4: response_id = 5'd26;
        5: response_id = 5'd25;
        6: response_id = 5'd27;
        default: response_id = 5'd28;
        endcase
    endfunction

    localparam [1:0] SOURCE_AW = 0, SOURCE_W = 1, SOURCE_WAIT = 2;
    reg [1:0] source_state;
    reg [3:0] source_write_index;
    reg [3:0] source_b_count;
    reg failed_source;

    assign s_axi.aclk = s_clk;
    assign s_axi.aresetn = s_resetn;
    assign s_axi.awid = original_id(source_write_index);
    assign s_axi.awaddr = 32'h3000_0000 +
                          {23'd0, source_write_index, 5'd0};
    assign s_axi.awlen = 8'd0;
    assign s_axi.awsize = 3'd5;
    assign s_axi.awburst = 2'b01;
    assign s_axi.awlock = 1'b0;
    assign s_axi.awcache = 4'd0;
    assign s_axi.awprot = 3'd0;
    assign s_axi.awqos = 4'd0;
    assign s_axi.awvalid = source_state == SOURCE_AW;
    assign s_axi.wdata = {{252{1'b0}}, source_write_index} + 1'b1;
    assign s_axi.wstrb = 32'hffff_ffff;
    assign s_axi.wlast = 1'b1;
    assign s_axi.wvalid = source_state == SOURCE_W;
    assign s_axi.bready = 1'b1;
    assign s_axi.arid = 3'd0;
    assign s_axi.araddr = 32'd0;
    assign s_axi.arlen = 8'd0;
    assign s_axi.arsize = 3'd0;
    assign s_axi.arburst = 2'd0;
    assign s_axi.arlock = 1'b0;
    assign s_axi.arcache = 4'd0;
    assign s_axi.arprot = 3'd0;
    assign s_axi.arqos = 4'd0;
    assign s_axi.arvalid = 1'b0;
    assign s_axi.rready = 1'b0;

    always @(posedge s_clk or negedge s_resetn) begin
        if (!s_resetn) begin
            source_state <= SOURCE_AW;
            source_write_index <= 4'd0;
            source_b_count <= 4'd0;
            failed_source <= 1'b0;
        end else begin
            if (s_axi.awvalid && s_axi.awready)
                source_state <= SOURCE_W;
            if (s_axi.wvalid && s_axi.wready) begin
                if (source_write_index == 7)
                    source_state <= SOURCE_WAIT;
                else begin
                    source_write_index <= source_write_index + 1'b1;
                    source_state <= SOURCE_AW;
                end
            end
            if (s_axi.bvalid && s_axi.bready) begin
                if (s_axi.bid != original_id(source_b_count) ||
                    s_axi.bresp != (source_b_count == 2 ? 2'b10 : 2'b00))
                    failed_source <= 1'b1;
                source_b_count <= source_b_count + 1'b1;
            end
        end
    end

    reg [3:0] destination_aw_count;
    reg [3:0] destination_w_count;
    reg [3:0] response_index;
    reg destination_w_active;
    reg response_started;
    reg failed_destination;
    reg [3:0] destination_cycle;
    reg stalled_aw_valid;
    reg [4:0] stalled_awid;
    reg [32:0] stalled_awaddr;

    assign m_axi.awready = destination_cycle[1:0] != 2'b00;
    assign m_axi.wready = 1'b1;
    assign m_axi.bid = response_id(response_index);
    assign m_axi.bresp = response_id(response_index) == 26 ? 2'b10 : 2'b00;
    assign m_axi.bvalid = response_started && response_index < 8;
    assign m_axi.arready = 1'b0;
    assign m_axi.rid = 5'd0;
    assign m_axi.rdata = 256'd0;
    assign m_axi.rresp = 2'b00;
    assign m_axi.rlast = 1'b0;
    assign m_axi.rvalid = 1'b0;

    always @(posedge m_clk or negedge m_resetn) begin
        if (!m_resetn) begin
            destination_aw_count <= 4'd0;
            destination_w_count <= 4'd0;
            response_index <= 4'd0;
            destination_w_active <= 1'b0;
            response_started <= 1'b0;
            failed_destination <= 1'b0;
            destination_cycle <= 4'd0;
            stalled_aw_valid <= 1'b0;
            stalled_awid <= '0;
            stalled_awaddr <= '0;
        end else begin
            destination_cycle <= destination_cycle + 1'b1;
            if (m_axi.awvalid && !m_axi.awready) begin
                if (stalled_aw_valid &&
                    (m_axi.awid != stalled_awid ||
                     m_axi.awaddr != stalled_awaddr))
                    failed_destination <= 1'b1;
                stalled_aw_valid <= 1'b1;
                stalled_awid <= m_axi.awid;
                stalled_awaddr <= m_axi.awaddr;
            end
            if (m_axi.awvalid && m_axi.awready) begin
                if ((stalled_aw_valid &&
                     (m_axi.awid != stalled_awid ||
                      m_axi.awaddr != stalled_awaddr)) ||
                    destination_w_active ||
                    m_axi.awid != 24 + destination_aw_count ||
                    m_axi.awaddr !=
                        ({1'b0, 32'h3000_0000 +
                          {23'd0, destination_aw_count, 5'd0}} |
                         33'h0_8000_0000) || m_axi.awlen != 0)
                    failed_destination <= 1'b1;
                stalled_aw_valid <= 1'b0;
                destination_w_active <= 1'b1;
                destination_aw_count <= destination_aw_count + 1'b1;
            end
            if (m_axi.wvalid && m_axi.wready) begin
                if (!destination_w_active || !m_axi.wlast ||
                    m_axi.wdata !=
                        ({{252{1'b0}}, destination_w_count} + 1'b1))
                    failed_destination <= 1'b1;
                destination_w_active <= 1'b0;
                destination_w_count <= destination_w_count + 1'b1;
            end
            if (destination_w_count == 8 && outstanding_current == 8)
                response_started <= 1'b1;
            if (m_axi.bvalid && m_axi.bready)
                response_index <= response_index + 1'b1;
        end
    end

    assign done = source_b_count == 8;
    assign failed = failed_source || failed_destination;
    assign destination_aw_count_debug = {28'd0, destination_aw_count};
    assign destination_w_count_debug = {28'd0, destination_w_count};
    assign source_b_count_debug = {28'd0, source_b_count};
endmodule
