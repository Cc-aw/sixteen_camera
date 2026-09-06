`timescale 1ns/1ps

module tb_axi4_ui_cdc_mixed;
    localparam integer WRITES = 24;
    localparam integer READS = 12;
    localparam integer READ_BEATS = 4;
    reg video_clk = 0;
    reg ui_clk = 0;
    reg video_resetn = 0;
    reg ui_resetn = 0;
    always #10 video_clk = ~video_clk;
    always #5 ui_clk = ~ui_clk;

    axi4_if #(.ADDR_WIDTH(32), .DATA_WIDTH(256), .ID_WIDTH(3)) wr_s();
    axi4_if #(.ADDR_WIDTH(32), .DATA_WIDTH(256), .ID_WIDTH(3)) wr_m();
    axi4_if #(.ADDR_WIDTH(32), .DATA_WIDTH(256), .ID_WIDTH(3)) rd_s();
    axi4_if #(.ADDR_WIDTH(32), .DATA_WIDTH(256), .ID_WIDTH(3)) rd_m();
    reg [31:0] lfsr = 32'h65a3_19e7;
    integer wr_aw_seen = 0;
    integer wr_w_seen = 0;
    integer wr_b_sent = 0;
    integer wr_b_seen = 0;
    reg [2:0] wr_ids [0:WRITES-1];
    reg wr_bvalid = 0;
    reg [2:0] wr_bid = 0;
    integer rd_ar_seen = 0;
    integer rd_seen = 0;
    reg rd_active = 0;
    reg [31:0] rd_addr = 0;
    reg [2:0] rd_id = 0;
    integer rd_beat = 0;
    reg rd_rvalid = 0;
    reg [255:0] rd_rdata = 0;
    reg rd_rlast = 0;

    assign wr_s.aclk = video_clk;
    assign wr_s.aresetn = video_resetn;
    assign rd_s.aclk = video_clk;
    assign rd_s.aresetn = video_resetn;

    axi4_ui_write_cdc #(
        .COMMAND_DEPTH(16), .DATA_DEPTH(32), .RESPONSE_DEPTH(16)
    ) u_write (
        .s_axi(wr_s), .ui_clk(ui_clk), .ui_resetn(ui_resetn), .m_axi(wr_m)
    );
    axi4_ui_read_cdc #(.COMMAND_DEPTH(16), .DATA_DEPTH(32)) u_read (
        .s_axi(rd_s), .ui_clk(ui_clk), .ui_resetn(ui_resetn), .m_axi(rd_m)
    );

    assign wr_m.awready = lfsr[0] | lfsr[4];
    assign wr_m.wready = lfsr[1] | lfsr[5];
    assign wr_m.bid = wr_bid;
    assign wr_m.bresp = 2'b00;
    assign wr_m.bvalid = wr_bvalid;
    assign rd_m.arready = !rd_active && (lfsr[2] | lfsr[7]);
    assign rd_m.rid = rd_id;
    assign rd_m.rdata = rd_rdata;
    assign rd_m.rresp = 2'b00;
    assign rd_m.rlast = rd_rlast;
    assign rd_m.rvalid = rd_rvalid;

    always @(posedge ui_clk) begin
        lfsr <= {lfsr[30:0], lfsr[31] ^ lfsr[21] ^ lfsr[1] ^ lfsr[0]};
        if (!ui_resetn) begin
            wr_aw_seen <= 0;
            wr_w_seen <= 0;
            wr_b_sent <= 0;
            wr_bvalid <= 0;
            rd_ar_seen <= 0;
            rd_active <= 0;
            rd_rvalid <= 0;
            rd_beat <= 0;
        end else begin
            if (wr_m.awvalid && wr_m.awready) begin
                if (wr_m.awaddr !== 32'h1000_0000 + 32'(wr_aw_seen*32) ||
                    wr_m.awlen != 0 || wr_m.awsize != 3'd5)
                    $fatal(1, "write AW %0d mismatch", wr_aw_seen);
                wr_ids[wr_aw_seen] <= wr_m.awid;
                wr_aw_seen <= wr_aw_seen + 1;
            end
            if (wr_m.wvalid && wr_m.wready) begin
                if (wr_m.wdata[31:0] !== 32'hcafe_0000 + 32'(wr_w_seen) ||
                    wr_m.wstrb != 32'hffff_ffff || !wr_m.wlast)
                    $fatal(1, "write W %0d mismatch", wr_w_seen);
                wr_w_seen <= wr_w_seen + 1;
            end
            if (wr_bvalid && wr_m.bready) begin
                wr_bvalid <= 0;
                wr_b_sent <= wr_b_sent + 1;
            end
            if (!wr_bvalid && wr_b_sent < wr_aw_seen &&
                wr_b_sent < wr_w_seen && lfsr[9]) begin
                wr_bid <= wr_ids[wr_b_sent];
                wr_bvalid <= 1;
            end

            if (rd_m.arvalid && rd_m.arready) begin
                if (rd_m.araddr !== 32'h2000_0000 + 32'(rd_ar_seen*128) ||
                    rd_m.arlen != 8'(READ_BEATS-1) ||
                    rd_m.arsize != 3'd5)
                    $fatal(1, "read AR %0d mismatch", rd_ar_seen);
                rd_addr <= rd_m.araddr;
                rd_id <= rd_m.arid;
                rd_active <= 1;
                rd_beat <= 0;
                rd_ar_seen <= rd_ar_seen + 1;
            end
            if (rd_rvalid && rd_m.rready) begin
                rd_rvalid <= 0;
                if (rd_rlast)
                    rd_active <= 0;
                else
                    rd_beat <= rd_beat + 1;
            end
            if (rd_active && !rd_rvalid && lfsr[10]) begin
                rd_rdata <= {192'd0, rd_addr, 32'(rd_beat)};
                rd_rlast <= (rd_beat == READ_BEATS-1);
                rd_rvalid <= 1;
            end
        end
    end

    always @(posedge video_clk) begin
        wr_s.bready <= lfsr[11] | lfsr[15];
        rd_s.rready <= lfsr[12] | lfsr[16];
        if (video_resetn && wr_s.bvalid && wr_s.bready) begin
            if (wr_s.bid !== 3'(wr_b_seen % 8) || wr_s.bresp != 2'b00)
                $fatal(1, "write B %0d mismatch", wr_b_seen);
            wr_b_seen <= wr_b_seen + 1;
        end
        if (video_resetn && rd_s.rvalid && rd_s.rready) begin
            if (rd_s.rdata !== {192'd0,
                    32'h2000_0000 + 32'((rd_seen/READ_BEATS)*128),
                    32'(rd_seen % READ_BEATS)} ||
                rd_s.rid !== 3'((rd_seen/READ_BEATS) % 8) ||
                rd_s.rresp != 2'b00 ||
                rd_s.rlast !== ((rd_seen % READ_BEATS) == READ_BEATS-1))
                $fatal(1, "read R beat %0d mismatch", rd_seen);
            rd_seen <= rd_seen + 1;
        end
    end

    task automatic send_writes;
        integer i;
        begin
            for (i = 0; i < WRITES; i = i + 1) begin
                @(negedge video_clk);
                wr_s.awid = 3'(i % 8);
                wr_s.awaddr = 32'h1000_0000 + 32'(i*32);
                wr_s.awvalid = 1;
                do @(posedge video_clk); while (!wr_s.awready);
                @(negedge video_clk);
                wr_s.awvalid = 0;
                wr_s.wdata = {224'd0, 32'hcafe_0000 + 32'(i)};
                wr_s.wvalid = 1;
                do @(posedge video_clk); while (!wr_s.wready);
                @(negedge video_clk);
                wr_s.wvalid = 0;
            end
        end
    endtask

    task automatic send_reads;
        integer i;
        begin
            for (i = 0; i < READS; i = i + 1) begin
                @(negedge video_clk);
                rd_s.arid = 3'(i % 8);
                rd_s.araddr = 32'h2000_0000 + 32'(i*128);
                rd_s.arvalid = 1;
                do @(posedge video_clk); while (!rd_s.arready);
                @(negedge video_clk);
                rd_s.arvalid = 0;
            end
        end
    endtask

    initial begin
        wr_s.awid = 0; wr_s.awaddr = 0; wr_s.awlen = 0;
        wr_s.awsize = 5; wr_s.awburst = 1; wr_s.awlock = 0;
        wr_s.awcache = 2; wr_s.awprot = 0; wr_s.awqos = 14;
        wr_s.awvalid = 0; wr_s.wdata = 0; wr_s.wstrb = '1;
        wr_s.wlast = 1; wr_s.wvalid = 0; wr_s.bready = 0;
        wr_s.arid = 0; wr_s.araddr = 0; wr_s.arlen = 0;
        wr_s.arsize = 0; wr_s.arburst = 0; wr_s.arlock = 0;
        wr_s.arcache = 0; wr_s.arprot = 0; wr_s.arqos = 0;
        wr_s.arvalid = 0; wr_s.rready = 0;
        rd_s.awid = 0; rd_s.awaddr = 0; rd_s.awlen = 0;
        rd_s.awsize = 0; rd_s.awburst = 0; rd_s.awlock = 0;
        rd_s.awcache = 0; rd_s.awprot = 0; rd_s.awqos = 0;
        rd_s.awvalid = 0; rd_s.wdata = 0; rd_s.wstrb = 0;
        rd_s.wlast = 0; rd_s.wvalid = 0; rd_s.bready = 0;
        rd_s.arid = 0; rd_s.araddr = 0;
        rd_s.arlen = 8'(READ_BEATS-1);
        rd_s.arsize = 5; rd_s.arburst = 1; rd_s.arlock = 0;
        rd_s.arcache = 2; rd_s.arprot = 0; rd_s.arqos = 15;
        rd_s.arvalid = 0; rd_s.rready = 0;
        repeat (6) @(posedge ui_clk);
        ui_resetn = 1;
        video_resetn = 1;
        repeat (12) @(posedge video_clk);
        fork send_writes(); send_reads(); join
        wait (wr_b_seen == WRITES && rd_seen == READS*READ_BEATS);
        if (wr_aw_seen != WRITES || wr_w_seen != WRITES ||
            rd_ar_seen != READS)
            $fatal(1, "transaction count mismatch");
        $display("TB_AXI4_UI_CDC_MIXED=PASS writes=%0d read_beats=%0d",
                 wr_b_seen, rd_seen);
        $finish;
    end

    initial begin
        #500000;
        $fatal(1, "timeout aw=%0d w=%0d b=%0d ar=%0d r=%0d",
               wr_aw_seen, wr_w_seen, wr_b_seen, rd_ar_seen, rd_seen);
    end
endmodule
