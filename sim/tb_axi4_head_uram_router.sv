`timescale 1ns/1ps

module tb_axi4_head_uram_router #(
    parameter bit TEST_SHADOW_DDR = 1'b0
);
    localparam integer DATA_WIDTH = 256;
    localparam integer BYTE_LANES = DATA_WIDTH / 8;
    localparam integer SLOT_BYTES = 4096;
    localparam [32:0] BANK0_BASE = 33'h0_3200_0000;
    localparam [32:0] BANK1_BASE = 33'h0_3200_1000;
    localparam [32:0] BANK2_BASE = 33'h0_3240_0000;
    localparam [32:0] BANK3_BASE = 33'h0_3240_1000;
    localparam [4*33-1:0] BANK_BASES = {
        BANK3_BASE, BANK2_BASE, BANK1_BASE, BANK0_BASE
    };

    reg clk = 1'b0;
    reg resetn = 1'b0;
    always #5 clk = ~clk;

    axi4_if #(.ADDR_WIDTH(33), .DATA_WIDTH(256), .ID_WIDTH(4)) s_axi();
    axi4_if #(.ADDR_WIDTH(33), .DATA_WIDTH(256), .ID_WIDTH(4)) ddr_axi();
    reg [1:0] local_bank = 0;
    reg local_req_valid = 0;
    wire local_req_ready;
    reg [6:0] local_req_word_addr = 0;
    wire [255:0] local_rsp_data;
    wire local_rsp_valid;
    reg local_rsp_ready = 0;

    axi4_head_uram_router #(
        .SLOT_BYTES(SLOT_BYTES), .HEAD_BASE_ADDRS(BANK_BASES),
        .SHADOW_DDR(TEST_SHADOW_DDR)
    ) dut (
        .clk(clk), .resetn(resetn), .s_axi(s_axi), .m_ddr_axi(ddr_axi),
        .local_read_bank(local_bank),
        .local_read_req_valid(local_req_valid),
        .local_read_req_ready(local_req_ready),
        .local_read_req_word_addr(local_req_word_addr),
        .local_read_rsp_data(local_rsp_data),
        .local_read_rsp_valid(local_rsp_valid),
        .local_read_rsp_ready(local_rsp_ready)
    );

    reg [7:0] expected [0:4*SLOT_BYTES-1];
    integer ddr_aw_count = 0;
    integer ddr_w_count = 0;
    integer ddr_ar_count = 0;
    reg [32:0] ddr_last_awaddr = 0;
    reg [32:0] ddr_last_araddr = 0;
    reg ddr_bvalid = 0;
    reg [3:0] ddr_bid = 0;
    reg ddr_rvalid = 0;
    reg [3:0] ddr_rid = 0;
    reg [32:0] ddr_read_addr = 0;
    reg [8:0] ddr_read_left = 0;
    reg [2:0] ddr_read_size = 0;
    reg [1:0] ddr_read_burst = 0;
    reg [31:0] lfsr = 32'h1357_9bdf;

    function automatic [255:0] ddr_word(input [32:0] address);
        begin
            for (integer lane = 0; lane < BYTE_LANES; lane = lane + 1)
                ddr_word[lane*8 +: 8] =
                    8'(address + lane + (address >> 8));
        end
    endfunction

    assign ddr_axi.awready = lfsr[0] || lfsr[4];
    assign ddr_axi.wready = lfsr[1] || lfsr[6];
    assign ddr_axi.bid = ddr_bid;
    assign ddr_axi.bresp = 2'b00;
    assign ddr_axi.bvalid = ddr_bvalid;
    assign ddr_axi.arready = lfsr[2] || lfsr[7];
    assign ddr_axi.rid = ddr_rid;
    assign ddr_axi.rdata = ddr_word(ddr_read_addr);
    assign ddr_axi.rresp = 2'b00;
    assign ddr_axi.rlast = ddr_read_left == 1;
    assign ddr_axi.rvalid = ddr_rvalid;

    always @(posedge clk) begin
        lfsr <= {lfsr[30:0], lfsr[31] ^ lfsr[21] ^ lfsr[1] ^ lfsr[0]};
        if (!resetn) begin
            ddr_aw_count <= 0;
            ddr_w_count <= 0;
            ddr_ar_count <= 0;
            ddr_bvalid <= 0;
            ddr_rvalid <= 0;
        end else begin
            if (ddr_axi.awvalid && ddr_axi.awready) begin
                if ((!TEST_SHADOW_DDR &&
                     (ddr_axi.awid != 4'h3 ||
                      ddr_axi.awaddr != 33'h0_3220_0040 ||
                      ddr_axi.awlen != 0)) ||
                    ddr_axi.awsize != 3'd5 || ddr_axi.awburst != 2'b01)
                    $fatal(1, "DDR AW fields changed by router");
                ddr_aw_count <= ddr_aw_count + 1;
                ddr_last_awaddr <= ddr_axi.awaddr;
                ddr_bid <= ddr_axi.awid;
            end
            if (ddr_axi.wvalid && ddr_axi.wready) begin
                if (!TEST_SHADOW_DDR &&
                    (ddr_axi.wdata != {32{8'hd4}} ||
                     ddr_axi.wstrb != 32'hffff_ffff || !ddr_axi.wlast))
                    $fatal(1, "DDR W fields changed by router");
                ddr_w_count <= ddr_w_count + 1;
                if (ddr_axi.wlast)
                    ddr_bvalid <= 1'b1;
            end
            if (ddr_bvalid && ddr_axi.bready)
                ddr_bvalid <= 1'b0;

            if (ddr_axi.arvalid && ddr_axi.arready) begin
                if (ddr_axi.arid != 4'ha ||
                    (!TEST_SHADOW_DDR &&
                     ddr_axi.araddr != 33'h0_3220_0080) ||
                    ddr_axi.arlen != 0 || ddr_axi.arsize != 3'd5 ||
                    ddr_axi.arburst != 2'b01)
                    $fatal(1, "DDR AR fields changed by router");
                ddr_ar_count <= ddr_ar_count + 1;
                ddr_last_araddr <= ddr_axi.araddr;
                ddr_rid <= ddr_axi.arid;
                ddr_read_addr <= ddr_axi.araddr;
                ddr_read_left <= {1'b0, ddr_axi.arlen} + 1'b1;
                ddr_read_size <= ddr_axi.arsize;
                ddr_read_burst <= ddr_axi.arburst;
                ddr_rvalid <= 1'b1;
            end else if (ddr_rvalid && ddr_axi.rready) begin
                if (ddr_read_left == 1) begin
                    ddr_rvalid <= 1'b0;
                end else begin
                    ddr_read_left <= ddr_read_left - 1'b1;
                    if (ddr_read_burst == 2'b01)
                        ddr_read_addr <= ddr_read_addr +
                                         (33'(1) << ddr_read_size);
                end
            end
        end
    end

    task automatic drive_aw(input [32:0] address, input [7:0] length,
                            input [3:0] id, input bit early_w);
        begin
            @(negedge clk);
            s_axi.awid = id;
            s_axi.awaddr = address;
            s_axi.awlen = length;
            s_axi.awsize = 3'd5;
            s_axi.awburst = 2'b01;
            s_axi.awlock = 0;
            s_axi.awcache = 4'b0010;
            s_axi.awprot = 0;
            s_axi.awqos = 0;
            s_axi.awvalid = 1;
            if (early_w) begin
                s_axi.wvalid = 1;
                s_axi.wlast = length == 0;
                if (s_axi.wready)
                    $fatal(1, "W accepted before AW");
            end
            do @(posedge clk); while (!s_axi.awready);
            @(negedge clk);
            s_axi.awvalid = 0;
            if (early_w)
                s_axi.wvalid = 0;
        end
    endtask

    task automatic head_write(input [32:0] address, input integer beats,
                              input integer bank, input integer offset,
                              input [31:0] last_strobe, input integer salt,
                              input bit early_w, input [1:0] expected_resp);
        reg [31:0] strobes;
        begin
            drive_aw(address, 8'(beats - 1), 4'h9, early_w);
            for (integer beat = 0; beat < beats; beat = beat + 1) begin
                @(negedge clk);
                strobes = beat == beats - 1 ? last_strobe : 32'hffff_ffff;
                for (integer lane = 0; lane < BYTE_LANES; lane = lane + 1)
                    s_axi.wdata[lane*8 +: 8] = 8'(salt + beat*32 + lane);
                s_axi.wstrb = strobes;
                s_axi.wlast = beat == beats - 1;
                s_axi.wvalid = 1;
                do @(posedge clk); while (!s_axi.wready);
                if (expected_resp == 0)
                    for (integer lane = 0; lane < BYTE_LANES;
                         lane = lane + 1)
                        if (strobes[lane])
                            expected[bank*SLOT_BYTES + offset +
                                     beat*BYTE_LANES + lane] =
                                8'(salt + beat*32 + lane);
                @(negedge clk);
                s_axi.wvalid = 0;
            end
            s_axi.bready = 1;
            do @(posedge clk); while (!s_axi.bvalid);
            if (s_axi.bid != 4'h9 || s_axi.bresp != expected_resp)
                $fatal(1, "Head B mismatch id=%x resp=%b expected=%b",
                       s_axi.bid, s_axi.bresp, expected_resp);
            @(negedge clk);
            s_axi.bready = 0;
        end
    endtask

    task automatic head_read(input [32:0] address, input integer beats,
                             input integer bank, input integer offset,
                             input [1:0] expected_resp);
        begin
            @(negedge clk);
            s_axi.arid = 4'h6;
            s_axi.araddr = address;
            s_axi.arlen = 8'(beats - 1);
            s_axi.arsize = 3'd5;
            s_axi.arburst = 2'b01;
            s_axi.arlock = 0;
            s_axi.arcache = 4'b0010;
            s_axi.arprot = 0;
            s_axi.arqos = 0;
            s_axi.arvalid = 1;
            do @(posedge clk); while (!s_axi.arready);
            @(negedge clk);
            s_axi.arvalid = 0;
            for (integer beat = 0; beat < beats; beat = beat + 1) begin
                s_axi.rready = lfsr[3];
                while (!(s_axi.rvalid && s_axi.rready)) begin
                    @(negedge clk);
                    s_axi.rready = lfsr[3] || lfsr[9];
                end
                if (s_axi.rid != 4'h6 || s_axi.rresp != expected_resp ||
                    s_axi.rlast != (beat == beats - 1))
                    $fatal(1, "Head R metadata mismatch beat=%0d", beat);
                if (expected_resp == 0)
                    for (integer lane = 0; lane < BYTE_LANES;
                         lane = lane + 1)
                        if (s_axi.rdata[lane*8 +: 8] !==
                            expected[bank*SLOT_BYTES + offset +
                                     beat*BYTE_LANES + lane])
                            $fatal(1,
                                "Head R data mismatch beat=%0d lane=%0d got=%02x expected=%02x",
                                beat, lane, s_axi.rdata[lane*8 +: 8],
                                expected[bank*SLOT_BYTES + offset +
                                         beat*BYTE_LANES + lane]);
                @(negedge clk);
                s_axi.rready = 0;
            end
        end
    endtask

    task automatic ddr_write(input [32:0] address);
        begin
            drive_aw(address, 0, 4'h3, 1'b0);
            @(negedge clk);
            s_axi.wdata = {32{8'hd4}};
            s_axi.wstrb = 32'hffff_ffff;
            s_axi.wlast = 1;
            s_axi.wvalid = 1;
            do @(posedge clk); while (!s_axi.wready);
            @(negedge clk);
            s_axi.wvalid = 0;
            s_axi.bready = 1;
            do @(posedge clk); while (!s_axi.bvalid);
            if (s_axi.bid != 4'h3 || s_axi.bresp != 0)
                $fatal(1, "DDR B response changed by router");
            @(negedge clk);
            s_axi.bready = 0;
        end
    endtask

    task automatic ddr_read(input [32:0] address);
        begin
            @(negedge clk);
            s_axi.arid = 4'ha;
            s_axi.araddr = address;
            s_axi.arlen = 0;
            s_axi.arsize = 3'd5;
            s_axi.arburst = 2'b01;
            s_axi.arvalid = 1;
            do @(posedge clk); while (!s_axi.arready);
            @(negedge clk);
            s_axi.arvalid = 0;
            s_axi.rready = 1;
            do @(posedge clk); while (!s_axi.rvalid);
            if (s_axi.rid != 4'ha || s_axi.rresp != 0 || !s_axi.rlast ||
                s_axi.rdata !== ddr_word(address))
                $fatal(1, "DDR R response changed by router");
            @(negedge clk);
            s_axi.rready = 0;
        end
    endtask

    task automatic local_read(input [1:0] bank, input [6:0] word_addr,
                              input integer expected_offset);
        begin
            @(negedge clk);
            local_bank = bank;
            local_req_word_addr = word_addr;
            local_req_valid = 1;
            do @(posedge clk); while (!local_req_ready);
            @(negedge clk);
            local_req_valid = 0;
            local_rsp_ready = 1;
            do @(posedge clk); while (!local_rsp_valid);
            for (integer lane = 0; lane < BYTE_LANES; lane = lane + 1)
                if (local_rsp_data[lane*8 +: 8] !==
                    expected[bank*SLOT_BYTES + expected_offset + lane])
                    $fatal(1, "Local R mismatch bank=%0d lane=%0d",
                           bank, lane);
            @(negedge clk);
            local_rsp_ready = 0;
        end
    endtask

    initial begin
        s_axi.aclk = clk;
        s_axi.aresetn = resetn;
        s_axi.awid = 0;
        s_axi.awaddr = 0;
        s_axi.awlen = 0;
        s_axi.awsize = 0;
        s_axi.awburst = 0;
        s_axi.awlock = 0;
        s_axi.awcache = 0;
        s_axi.awprot = 0;
        s_axi.awqos = 0;
        s_axi.awvalid = 0;
        s_axi.wdata = 0;
        s_axi.wstrb = 0;
        s_axi.wlast = 0;
        s_axi.wvalid = 0;
        s_axi.bready = 0;
        s_axi.arid = 0;
        s_axi.araddr = 0;
        s_axi.arlen = 0;
        s_axi.arsize = 0;
        s_axi.arburst = 0;
        s_axi.arlock = 0;
        s_axi.arcache = 0;
        s_axi.arprot = 0;
        s_axi.arqos = 0;
        s_axi.arvalid = 0;
        s_axi.rready = 0;
        for (integer index = 0; index < 4*SLOT_BYTES; index = index + 1)
            expected[index] = 0;

        repeat (5) @(negedge clk);
        resetn = 1;

        head_write(BANK0_BASE + 64, 4, 0, 64, 32'hffff_ffff,
                   32'h0000_0010, 1'b1, 2'b00);
        head_write(33'h0_b200_1000 + 96, 2, 1, 96, 32'h00ff_0f0f,
                   32'h0000_0080, 1'b0, 2'b00);
        if (!TEST_SHADOW_DDR) begin
            head_read(BANK0_BASE + 64, 4, 0, 64, 2'b00);
            head_read(33'h0_b200_1000 + 96, 2, 1, 96, 2'b00);
        end
        local_read(0, 7'd2, 64);
        local_read(1, 7'd3, 96);

        // A burst beginning in a Head slot may not cross its boundary and
        // must not leak to DDR.
        if (!TEST_SHADOW_DDR) begin
            head_write(BANK0_BASE + SLOT_BYTES - 32, 2, 0,
                       SLOT_BYTES - 32, 32'hffff_ffff, 32'h0000_00e0,
                       1'b0, 2'b11);
            head_read(BANK0_BASE + SLOT_BYTES - 32, 2, 0,
                      SLOT_BYTES - 32, 2'b11);
        end

        // Diagnostic space between worker windows remains DDR traffic.
        ddr_write(33'h0_3220_0040);
        ddr_read(33'h0_3220_0080);
        if ((!TEST_SHADOW_DDR &&
             (ddr_aw_count != 1 || ddr_w_count != 1 ||
              ddr_ar_count != 1)) ||
            (TEST_SHADOW_DDR &&
             (ddr_aw_count != 3 || ddr_w_count != 7 ||
              ddr_ar_count != 1)) ||
            ddr_last_awaddr != 33'h0_3220_0040 ||
            ddr_last_araddr != 33'h0_3220_0080)
            $fatal(1, "Head traffic leaked to DDR aw/w/ar=%0d/%0d/%0d",
                   ddr_aw_count, ddr_w_count, ddr_ar_count);

        $display("AXI4_HEAD_URAM_ROUTER=PASS ddr_aw/w/ar=%0d/%0d/%0d",
                 ddr_aw_count, ddr_w_count, ddr_ar_count);
        $finish;
    end

    initial begin
        repeat (5000) @(posedge clk);
        $fatal(1, "AXI Head URAM router timeout");
    end
endmodule
