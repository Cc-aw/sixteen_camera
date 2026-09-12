`timescale 1ns/1ps

module tb_postprocess_read_diagnostic;
    reg clk = 1'b0;
    reg resetn = 1'b0;
    always #5 clk = ~clk;

    axi_lite_if #(.ADDR_WIDTH(18)) axil();
    axi4_if #(.ADDR_WIDTH(33), .DATA_WIDTH(256), .ID_WIDTH(4)) axi();
    postprocess_read_diagnostic dut(.axil(axil), .m_axi(axi));
    assign axil.aclk = clk;
    assign axil.aresetn = resetn;

    reg read_active = 1'b0;
    reg [32:0] read_addr = 33'd0;
    reg [8:0] read_left = 9'd0;
    reg [3:0] read_id = 4'd0;
    reg rvalid = 1'b0;
    reg [255:0] rdata = 256'd0;
    reg rlast = 1'b0;
    reg [1:0] r_gap = 2'd0;
    reg [31:0] lfsr = 32'h1234_5678;
    reg production_mode = 1'b0;
    reg production_positive_mode = 1'b0;
    reg production_early_candidates = 1'b0;

    function automatic [255:0] memory_word(input [32:0] address);
        begin
            for (integer lane = 0; lane < 32; lane = lane + 1)
                memory_word[lane*8 +: 8] = production_mode ?
                    (address[30:0] < 31'h000a0000 ?
                        (production_early_candidates &&
                         address[30:0] + 31'(lane) >= 31'h0001_0000 &&
                         address[30:0] + 31'(lane) <
                             31'h0001_0000 + 31'd9*80 &&
                         (address[30:0] + 31'(lane) -
                             31'h0001_0000) % 80 == 23 ? 8'h00 :
                         production_positive_mode &&
                         address[30:0] + 31'(lane) ==
                         31'h00090000 + 31'd155*80 + 31'd23 ?
                         8'h00 : 8'h80) : 8'h00) : 8'(address + lane);
        end
    endfunction

    function automatic [31:0] crc_byte(input [31:0] current,
                                        input [7:0] value);
        reg [31:0] next;
        begin
            next = current ^ {24'd0, value};
            for (integer bit_index = 0; bit_index < 8;
                 bit_index = bit_index + 1)
                next = next[0] ? (next >> 1) ^ 32'hEDB8_8320 : next >> 1;
            crc_byte = next;
        end
    endfunction

    assign axi.arready = !read_active && (lfsr[0] || lfsr[3]);
    assign axi.rid = read_id;
    assign axi.rdata = rdata;
    assign axi.rresp = 2'b00;
    assign axi.rlast = rlast;
    assign axi.rvalid = rvalid;
    assign axi.awready = 1'b0;
    assign axi.wready = 1'b0;
    assign axi.bid = 4'd0;
    assign axi.bresp = 2'b00;
    assign axi.bvalid = 1'b0;

    always @(posedge clk) begin
        lfsr <= {lfsr[30:0], lfsr[31] ^ lfsr[21] ^ lfsr[1] ^ lfsr[0]};
        if (!resetn) begin
            read_active <= 1'b0;
            rvalid <= 1'b0;
            r_gap <= 2'd0;
        end else begin
            if (axi.arvalid && axi.arready) begin
                if (axi.araddr[4:0] != 0 ||
                    32'(axi.araddr[11:0]) +
                    (32'(axi.arlen) + 1) * 32 > 4096)
                    $fatal(1, "bad burst address=%h len=%0d",
                           axi.araddr, axi.arlen);
                if (!axi.araddr[31])
                    $fatal(1, "FBus DDR alias bit is missing: %h",
                           axi.araddr);
                read_active <= 1'b1;
                read_addr <= axi.araddr;
                read_id <= axi.arid;
                read_left <= {1'b0, axi.arlen} + 1'b1;
            end
            if (rvalid && axi.rready) begin
                rvalid <= 1'b0;
                // The generated width adapter needs four 64-bit FBus cycles
                // to assemble one 256-bit AXI beat.
                r_gap <= 2'd2;
                if (rlast)
                    read_active <= 1'b0;
                else begin
                    read_addr <= read_addr + 32;
                    read_left <= read_left - 1'b1;
                end
            end
            if (!(rvalid && axi.rready) && r_gap != 0)
                r_gap <= r_gap - 1'b1;
            if (read_active && !rvalid && r_gap == 0 &&
                (lfsr[2] || lfsr[7])) begin
                rdata <= memory_word(read_addr);
                rlast <= read_left == 1;
                rvalid <= 1'b1;
            end
        end
    end

    task automatic write_reg(input [15:0] address, input [31:0] value);
        begin
            @(negedge clk);
            axil.awaddr = {2'd0, address};
            axil.awvalid = 1'b1;
            axil.wdata = value;
            axil.wstrb = 4'hf;
            axil.wvalid = 1'b1;
            wait (axil.awready && axil.wready);
            @(posedge clk);
            @(negedge clk);
            axil.awvalid = 1'b0;
            axil.wvalid = 1'b0;
            axil.bready = 1'b1;
            do @(posedge clk); while (!axil.bvalid);
            @(negedge clk);
            axil.bready = 1'b0;
        end
    endtask

    task automatic read_reg(input [15:0] address, output [31:0] value);
        begin
            @(negedge clk);
            axil.araddr = {2'd0, address};
            axil.arvalid = 1'b1;
            wait (axil.arready);
            @(posedge clk);
            @(negedge clk);
            axil.arvalid = 1'b0;
            axil.rready = 1'b1;
            do @(posedge clk); while (!axil.rvalid);
            value = axil.rdata;
            @(negedge clk);
            axil.rready = 1'b0;
        end
    endtask

    reg [31:0] value;
    reg [31:0] expected_crc;
    reg [31:0] expected_sum;
    reg [31:0] expected_nonzero;
    localparam [32:0] TEST_ADDR = 33'h1_0000_1ff5;
    localparam integer TEST_BYTES = 100;
    initial begin
        axil.awaddr = 0; axil.awprot = 0; axil.awvalid = 0;
        axil.wdata = 0; axil.wstrb = 0; axil.wvalid = 0;
        axil.bready = 0; axil.araddr = 0; axil.arprot = 0;
        axil.arvalid = 0; axil.rready = 0;
        repeat (6) @(posedge clk);
        resetn = 1'b1;

        read_reg(16'h0000, value);
        if (value != 32'h5050_4431)
            $fatal(1, "ID mismatch %h", value);
        read_reg(16'h0004, value);
        if (value != 32'h0020_2205)
            $fatal(1, "P1C capability mismatch %h", value);
        read_reg(16'h0100, value);
        if (value != 32'h5050_5531)
            $fatal(1, "production capability mismatch %h", value);
        write_reg(16'h005c, 32'd2);
        read_reg(16'h005c, value);
        if (value != 2)
            $fatal(1, "burst limit register mismatch %0d", value);

        expected_crc = 32'hFFFF_FFFF;
        expected_sum = 0;
        expected_nonzero = 0;
        for (integer index = 0; index < TEST_BYTES; index = index + 1) begin
            value = {24'd0, 8'(TEST_ADDR + index)};
            expected_crc = crc_byte(expected_crc, value[7:0]);
            expected_sum = expected_sum + {24'd0, value[7:0]};
            if (value[7:0] != 0)
                expected_nonzero = expected_nonzero + 1;
        end
        expected_crc = expected_crc ^ 32'hFFFF_FFFF;

        write_reg(16'h0010, TEST_ADDR[31:0]);
        write_reg(16'h0014, {31'd0, TEST_ADDR[32]});
        write_reg(16'h0018, TEST_BYTES);
        write_reg(16'h0008, 32'd1);
        wait (dut.done_sticky);

        read_reg(16'h000c, value);
        if (value[2:0] != 3'b010)
            $fatal(1, "status mismatch %h", value);
        read_reg(16'h001c, value);
        if (value != expected_crc)
            $fatal(1, "CRC mismatch got=%h expected=%h", value, expected_crc);
        read_reg(16'h0020, value);
        if (value != expected_sum)
            $fatal(1, "sum mismatch got=%0d expected=%0d", value, expected_sum);
        read_reg(16'h0024, value);
        if (value != expected_nonzero)
            $fatal(1, "nonzero mismatch got=%0d expected=%0d",
                   value, expected_nonzero);
        read_reg(16'h0028, value);
        if (value != TEST_BYTES)
            $fatal(1, "bytes_read mismatch %0d", value);
        read_reg(16'h0034, value);
        if (value != 1)
            $fatal(1, "completion count mismatch %0d", value);
        read_reg(16'h003c, value);
        if (value != 0)
            $fatal(1, "unexpected error flags %h", value);
        write_reg(16'h0008, 32'd2);
        read_reg(16'h000c, value);
        if (value[1] != 0)
            $fatal(1, "done clear failed");

        // Fast mode must preserve the exact CRC while accepting every
        // available R beat without diagnostic-induced backpressure.
        write_reg(16'h0008, 32'd5);
        wait (dut.done_sticky);
        read_reg(16'h001c, value);
        if (value != expected_crc)
            $fatal(1, "fast CRC mismatch got=%h expected=%h",
                   value, expected_crc);
        read_reg(16'h0028, value);
        if (value != TEST_BYTES)
            $fatal(1, "fast bytes_read mismatch %0d", value);
        read_reg(16'h0040, value);
        if (value == 0)
            $fatal(1, "fast active cycle counter did not run");
        read_reg(16'h004c, value);
        if (value != 0)
            $fatal(1, "fast mode applied R backpressure for %0d cycles",
                   value);
        read_reg(16'h0050, value);
        if (value != 1)
            $fatal(1, "maximum outstanding register mismatch %0d", value);
        read_reg(16'h0054, value);
        if (value != 2)
            $fatal(1, "reorder occupancy register mismatch %0d", value);
        read_reg(16'h0058, value);
        if (value != 7)
            $fatal(1, "active ID mask register mismatch %h", value);
        read_reg(16'h0034, value);
        if (value != 2)
            $fatal(1, "fast completion count mismatch %0d", value);

        // Exercise six production descriptors through the same reader, while
        // leaving the original diagnostic CRC and completion counters intact.
        production_mode = 1'b1;
        write_reg(16'h0104, 32'h0001_0000);
        write_reg(16'h0108, 32'h0007_0000);
        write_reg(16'h010c, 32'h0009_0000);
        write_reg(16'h0110, 32'h000b_0000);
        write_reg(16'h0114, 32'h0010_0000);
        write_reg(16'h0118, 32'h0012_0000);
        write_reg(16'h0100, 32'd1);
        wait(dut.production_done);
        read_reg(16'h011c, value);
        if (value != 32'd2)
            $fatal(1, "production status mismatch %h", value);
        read_reg(16'h0138, value);
        if (value != 6300)
            $fatal(1, "production class positions mismatch %0d", value);
        read_reg(16'h013c, value);
        if (value != 0)
            $fatal(1, "production class candidates mismatch %0d", value);
        read_reg(16'h0124, value);
        if (value != 0)
            $fatal(1, "unexpected negative-score detection %0d", value);
        read_reg(16'h0034, value);
        if (value != 2)
            $fatal(1, "production contaminated diagnostic counter %0d", value);

        // One raw head class at location 6155 now scores above threshold.
        // Its DFL must stall/resume the real reader and survive AXI R gaps.
        production_positive_mode = 1'b1;
        write_reg(16'h0100, 32'd1);
        wait(dut.production_busy);
        wait(dut.production_done);
        read_reg(16'h011c, value);
        if (value != 32'd2) $fatal(1, "positive production status %h", value);
        read_reg(16'h0124, value);
        if (value != 1) $fatal(1, "positive detection count %0d", value);
        read_reg(16'h013c, value);
        if (value != 1) $fatal(1, "positive threshold count %0d", value);
        read_reg(16'h0140, value);
        if (value != 1) $fatal(1, "positive NMS count %0d", value);
        write_reg(16'h0120, 32'd0);
        read_reg(16'h0130, value);
        if (((value >> 16) & 7'h7f) != 23 ||
            (value & 16'hffff) < 16'd16000)
            $fatal(1, "positive dog score/class mismatch %h", value);

        // Early, consecutive candidates repeatedly stall the DFL stream
        // while the heap inserts them.  This is closer to a live frame than
        // a single candidate at the end of the last class head.
        production_positive_mode = 1'b0;
        production_early_candidates = 1'b1;
        write_reg(16'h0100, 32'd1);
        wait(dut.production_busy);
        wait(dut.production_done);
        read_reg(16'h011c, value);
        if (value != 32'd2) $fatal(1, "early candidates status %h", value);
        read_reg(16'h013c, value);
        if (value != 9) $fatal(1, "early threshold count %0d", value);
        read_reg(16'h0140, value);
        if (value != 9) $fatal(1, "early NMS count %0d", value);

        $display("TB_POSTPROCESS_READ_DIAGNOSTIC=PASS crc=%08h", expected_crc);
        $finish;
    end

    initial begin
        #10000000;
        $fatal(1, "timeout");
    end
endmodule
