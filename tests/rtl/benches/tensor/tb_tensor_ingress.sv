`timescale 1ns/1ps
module tb_tensor_ingress;
    reg clk = 0;
    always #5 clk = ~clk;
    reg reset = 1;
    axi4_if #(.ADDR_WIDTH(33), .DATA_WIDTH(256), .ID_WIDTH(5)) axi();
    assign axi.aclk = clk;
    assign axi.aresetn = !reset;
    wire a_valid, a_last, d_ready;
    wire [4:0] a_source;
    wire [32:0] a_address;
    wire [255:0] a_data;
    reg a_ready;
    reg d_valid;
    reg [4:0] d_source;
    reg d_denied;
    wire [63:0] stats [13];
    tensor_ingress_test_wrapper dut(.*);

    bit pending [32], sent_last [32], got_ack [32];
    int age [32], line [32];
    int a_count = 0, b_count = 0;
    int tick = 0, phase = 0;
    bit early_mode = 0, hold_second = 0, enable_ack = 1, random_stalls = 0;
    bit response_stall = 0;
    int expected_id [2048], expected_resp [2048];
    int queued = 0;

    function automatic [255:0] payload(input int index, input int beat);
        return {8{32'(index * 2 + beat + 32'h51000000)}};
    endfunction

    always_comb begin
        a_ready = !(hold_second && phase == 1) && (!random_stalls || (tick % 7 != 2));
        axi.bready = !response_stall && (!random_stalls || tick % 11 != 0);
        d_valid = 0;
        d_source = 0;
        d_denied = 0;
        if (early_mode) begin
            d_valid = a_valid && a_ready && phase == 0;
            d_source = a_source;
        end else if (enable_ack) begin
            // Highest source first deliberately reverses completion order.
            for (int i = 0; i < 32; i++) begin
                if (pending[i] && sent_last[i] && !got_ack[i] && age[i] == 0) begin
                    d_valid = 1;
                    d_source = 5'(i);
                    d_denied = line[i] == 13;
                end
            end
        end
    end

    always @(posedge clk) begin
        if (!reset) begin
            tick <= tick + 1;
            for (int s = 0; s < 32; s++)
                if (age[s] > 0) age[s] <= age[s] - 1;
            if (a_valid && a_ready) begin
                int index;
                index = int'((a_address - 33'hb0000000) >> 6);
                if (a_address[5:0] != 0 || a_data !== payload(index, phase))
                    $fatal(1, "A payload/address mismatch index=%0d phase=%0d", index, phase);
                if (a_last !== (phase == 1)) $fatal(1, "A beat framing");
                if (phase == 0) begin
                    if (pending[a_source] && !(sent_last[a_source] && got_ack[a_source]))
                        $fatal(1, "TL source reused before both A-last and D");
                    pending[a_source] <= 1;
                    sent_last[a_source] <= 0;
                    got_ack[a_source] <= 0;
                    line[a_source] <= index;
                    age[a_source] <= random_stalls ? (20 + index % 37) : 2;
                end else begin
                    if (line[a_source] != index) $fatal(1, "interleaved multibeat A");
                    sent_last[a_source] <= 1;
                    a_count <= a_count + 1;
                end
                phase <= 1 - phase;
            end
            if (d_valid && d_ready) got_ack[d_source] <= 1;
            if (axi.bvalid && axi.bready) begin
                if (b_count >= queued || axi.bid !== 5'(expected_id[b_count]) ||
                    axi.bresp !== 2'(expected_resp[b_count]))
                    $fatal(1, "B ordering/error mismatch n=%0d id=%0d resp=%0d", b_count, axi.bid, axi.bresp);
                b_count <= b_count + 1;
            end
        end
    end

    task automatic write_line(input int index, input int id = 0, input int len = 1,
                              input int size = 5, input int resp = 0,
                              input bit bad_strb = 0, input bit bad_last = 0,
                              input bit bad_addr = 0);
        expected_id[queued] = id;
        expected_resp[queued] = resp;
        queued++;
        @(negedge clk);
        axi.awaddr = bad_addr ? 33'h10000000 : 33'hb0000000 + 33'(index * 64);
        axi.awid = 5'(id);
        axi.awlen = 8'(len);
        axi.awsize = 3'(size);
        axi.awvalid = 1;
        do @(posedge clk); while (!axi.awready);
        @(negedge clk);
        axi.awvalid = 0;
        for (int beat = 0; beat <= len; beat++) begin
            axi.wvalid = 1;
            axi.wdata = payload(index, beat);
            axi.wstrb = bad_strb && beat == 1 ? 32'hffff_fffe : 32'hffff_ffff;
            axi.wlast = bad_last ? (beat == 0) : (beat == len);
            do @(posedge clk); while (!axi.wready);
            @(negedge clk);
        end
        axi.wvalid = 0;
    endtask

    task automatic wait_b(input int count);
        while (b_count < count) @(negedge clk);
    endtask

    initial begin
        axi.awvalid = 0; axi.wvalid = 0;
        axi.awid = 0; axi.awaddr = 0; axi.awlen = 1; axi.awsize = 5;
        axi.awburst = 1; axi.awlock = 0; axi.awcache = 0; axi.awprot = 0; axi.awqos = 0;
        axi.wdata = 0; axi.wstrb = '1; axi.wlast = 0;
        for (int s = 0; s < 32; s++) begin
            pending[s] = 0; sent_last[s] = 0; got_ack[s] = 0; age[s] = 0;
        end
        repeat (5) @(negedge clk);
        reset = 0;
        early_mode = 1; hold_second = 1;
        write_line(0);
        repeat (15) @(negedge clk);
        if (b_count != 0 || axi.bvalid || !got_ack[a_source])
            $fatal(1, "early AccessAck must not return B before A-last");
        hold_second = 0;
        wait_b(1);
        early_mode = 0; random_stalls = 1;
        for (int n = 1; n <= 120; n++) write_line(n, 0, 1, 5, n == 13 ? 2 : 0);
        wait_b(121);
        random_stalls = 0; enable_ack = 0; response_stall = 1;
        for (int n = 121; n < 185; n++) write_line(n);
        repeat (20) @(negedge clk);
        if (stats[9] != 32 || stats[7] == 0) $fatal(1, "source exhaustion not exercised");
        axi.awvalid = 1;
        repeat (10) begin
            @(negedge clk);
            if (axi.awready) $fatal(1, "record ring accepted a 65th outstanding AW");
        end
        axi.awvalid = 0;
        enable_ack = 1;
        repeat (400) @(negedge clk);
        if (a_count != 185 || stats[9] != 0) $fatal(1, "source release/B stall or record wrap failure");
        if (!axi.bvalid || axi.bresp != 0) $fatal(1, "B must remain valid during backpressure");
        response_stall = 0;
        wait_b(185);
        write_line(185, 7, 1, 5, 2, 1); // Partial strobe: no TL write.
        write_line(186, 3, 0, 5, 2);    // Short burst: drain one W.
        write_line(187, 4, 3, 5, 2);    // Long burst: drain all four W.
        write_line(188, 5, 1, 4, 2);    // Unsupported beat width.
        write_line(189, 6, 1, 5, 3, 0, 0, 1); // Address error.
        write_line(190, 2, 1, 5, 2, 0, 1);    // Bad WLAST.
        write_line(191, 31);
        wait_b(192);
        if (a_count != 186 || stats[3] != 7 || stats[2] != 185 * 64)
            $fatal(1, "invalid requests issued TL writes or telemetry mismatch");
        // Reset with pending work discards the entire pipeline.
        enable_ack = 0;
        write_line(192);
        repeat (10) @(negedge clk);
        reset = 1;
        repeat (5) @(negedge clk);
        reset = 0;
        repeat (10) @(negedge clk);
        if (axi.bvalid || a_valid || stats[9] != 0 || stats[2] != 0)
            $fatal(1, "global reset retained a transaction");
        $display("TENSOR_INGRESS_PROTOCOL=PASS early_ack out_of_order same_id source_exhaustion record_wrap invalid_writes reset");
        $finish;
    end
    initial begin #200000; $fatal(1, "Tensor ingress protocol timeout"); end
endmodule
