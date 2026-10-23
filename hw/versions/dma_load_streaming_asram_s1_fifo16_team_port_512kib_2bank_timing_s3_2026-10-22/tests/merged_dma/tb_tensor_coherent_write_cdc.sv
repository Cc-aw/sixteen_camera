`timescale 1ns/1ps

module tb_tensor_coherent_write_cdc;
    localparam integer COUNT = 48;
    reg video_clk = 0, soc_clk = 0, resetn = 0;
    always #7 video_clk = ~video_clk;
    always #5 soc_clk = ~soc_clk;
    axi4_if #(.ADDR_WIDTH(32), .DATA_WIDTH(256), .ID_WIDTH(3)) source_axi();
    axi4_if #(.ADDR_WIDTH(33), .DATA_WIDTH(256), .ID_WIDTH(5)) sink_axi();
    assign source_axi.aclk = video_clk;
    assign source_axi.aresetn = resetn;
    tensor_coherent_write_cdc dut (
        .tensor_write_axi(source_axi), .soc_clk(soc_clk),
        .soc_resetn(resetn), .tensor_soc_axi(sink_axi)
    );
    integer aw_seen = 0, w_seen = 0, b_sent = 0, b_seen = 0;
    integer soc_cycles = 0, video_cycles = 0;
    reg response_valid = 0;
    reg [4:0] response_id = 0;
    reg [1:0] response_code = 0;
    assign sink_axi.awready = resetn && (soc_cycles % 5 == 1 || soc_cycles % 5 == 3);
    assign sink_axi.wready = resetn && soc_cycles % 7 < 3;
    assign sink_axi.bid = response_id;
    assign sink_axi.bresp = response_code;
    assign sink_axi.bvalid = response_valid;
    assign sink_axi.arready = 0;
    assign sink_axi.rid = 0;
    assign sink_axi.rdata = 0;
    assign sink_axi.rresp = 0;
    assign sink_axi.rlast = 0;
    assign sink_axi.rvalid = 0;
    assign source_axi.bready = resetn && video_cycles > 220 && video_cycles % 4 != 1;
    function automatic [255:0] payload(input integer n);
        payload = {8{32'hcafe_0000 + 32'(n)}};
    endfunction
    always @(posedge soc_clk) begin
        soc_cycles <= soc_cycles + 1;
        if (resetn) begin
            if (sink_axi.awvalid && sink_axi.awready) begin
                if (sink_axi.awaddr !== 33'h09000_0000 + 33'(aw_seen * 32) ||
                    sink_axi.awid !== 5'(aw_seen % 8) || sink_axi.awlen !== 0 ||
                    sink_axi.awsize !== 5 || sink_axi.awburst !== 1 ||
                    sink_axi.awprot !== 3'(aw_seen % 8) || sink_axi.awqos !== 4'(aw_seen % 16))
                    $fatal(1, "Tensor AW mismatch at %0d", aw_seen);
                aw_seen <= aw_seen + 1;
            end
            if (sink_axi.wvalid && sink_axi.wready) begin
                if (sink_axi.wdata !== payload(w_seen) ||
                    sink_axi.wstrb !== (32'hffff_ffff << (w_seen % 8)) || !sink_axi.wlast)
                    $fatal(1, "Tensor W mismatch at %0d", w_seen);
                w_seen <= w_seen + 1;
            end
            if (response_valid && sink_axi.bready) begin
                response_valid <= 0;
                b_sent <= b_sent + 1;
            end
            if (!response_valid && b_sent < aw_seen && b_sent < w_seen) begin
                response_valid <= 1;
                response_id <= 5'(b_sent % 8);
                response_code <= 2'(b_sent % 3);
            end
        end
    end
    always @(posedge video_clk) begin
        video_cycles <= video_cycles + 1;
        if (resetn && source_axi.bvalid && source_axi.bready) begin
            if (source_axi.bid !== 3'(b_seen % 8) || source_axi.bresp !== 2'(b_seen % 3))
                $fatal(1, "Tensor B mismatch at %0d", b_seen);
            b_seen <= b_seen + 1;
        end
    end
    task automatic send_addresses;
        for (integer i = 0; i < COUNT; i++) begin
            @(negedge video_clk);
            source_axi.awid = 3'(i % 8);
            source_axi.awaddr = 32'h1000_0000 + 32'(i * 32);
            source_axi.awprot = 3'(i % 8);
            source_axi.awqos = 4'(i % 16);
            source_axi.awvalid = 1;
            do @(posedge video_clk); while (!source_axi.awready);
            @(negedge video_clk);
            source_axi.awvalid = 0;
        end
    endtask
    task automatic send_data;
        for (integer i = 0; i < COUNT; i++) begin
            @(negedge video_clk);
            source_axi.wdata = payload(i);
            source_axi.wstrb = 32'hffff_ffff << (i % 8);
            source_axi.wvalid = 1;
            do @(posedge video_clk); while (!source_axi.wready);
            @(negedge video_clk);
            source_axi.wvalid = 0;
        end
    endtask
    initial begin
`ifndef VERILATOR
        if (dut.u_cdc.u_aw.u_fifo.RELATED_CLOCKS != 0 ||
            dut.u_cdc.u_w.u_fifo.RELATED_CLOCKS != 0 ||
            dut.u_cdc.u_b.u_fifo.RELATED_CLOCKS != 0)
            $fatal(1, "Tensor XPM FIFO must use independent clocks on all three channels");
`endif
        source_axi.awid = 0; source_axi.awaddr = 0; source_axi.awlen = 0;
        source_axi.awsize = 5; source_axi.awburst = 1; source_axi.awlock = 0;
        source_axi.awcache = 0; source_axi.awprot = 0; source_axi.awqos = 0;
        source_axi.awvalid = 0; source_axi.wdata = 0; source_axi.wstrb = 0;
        source_axi.wlast = 1; source_axi.wvalid = 0;
        source_axi.arid = 0; source_axi.araddr = 0; source_axi.arlen = 0;
        source_axi.arsize = 0; source_axi.arburst = 0; source_axi.arlock = 0;
        source_axi.arcache = 0; source_axi.arprot = 0; source_axi.arqos = 0;
        source_axi.arvalid = 0; source_axi.rready = 0;
        repeat (12) @(negedge video_clk);
        resetn = 1;
        fork send_addresses(); send_data(); join
        wait (b_seen == COUNT);
        if (aw_seen != COUNT || w_seen != COUNT || b_sent != COUNT)
            $fatal(1, "Tensor transfer count mismatch");
        $display("TENSOR_COHERENT_CDC_PASS writes=48 address_id_mapping=checked backpressure=checked");
        $finish;
    end
    initial begin
        #1000000;
        $fatal(1, "Tensor CDC timeout");
    end
endmodule
