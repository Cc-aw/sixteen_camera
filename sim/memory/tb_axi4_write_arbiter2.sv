`timescale 1ns/1ps

module tb_axi4_write_arbiter2;
    reg clk = 0;
    always #5 clk = ~clk;
    reg resetn = 0, start0 = 0, start1 = 0;
    axi4_if #(.ADDR_WIDTH(32), .DATA_WIDTH(256), .ID_WIDTH(3)) s0();
    axi4_if #(.ADDR_WIDTH(32), .DATA_WIDTH(256), .ID_WIDTH(3)) s1();
    axi4_if #(.ADDR_WIDTH(32), .DATA_WIDTH(256), .ID_WIDTH(3)) m();
    wire ready0, ready1, done0, done1;
    wire busy0, busy1, error0, error1;
    wire [31:0] bytes0, bytes1;
    integer source_beat0 = 0, source_beat1 = 0;
    integer aw_seen = 0, w_seen = 0, b_seen = 0, burst_left = 0;
    reg bvalid = 0;
    reg done_seen0 = 0, done_seen1 = 0;
    reg late_s0;
    integer cycles = 0;

    yolov5nu_tensor_frame_writer #(
        .FRAME_WIDTH(32), .FRAME_HEIGHT(1)
    ) writer0 (
        .clk(clk), .resetn(resetn), .start(start0), .abort(1'b0),
        .tensor_addr(32'h3000_0000), .frame_id(32'd1),
        .s_data({32{8'haa}}), .s_sof(source_beat0 == 0),
        .s_eol(source_beat0 == 2), .s_eof(source_beat0 == 2),
        .s_frame_id(32'd1), .s_error(1'b0), .s_valid(1'b1),
        .s_ready(ready0), .busy(busy0), .done(done0),
        .error(error0), .bytes_written(bytes0), .m_axi(s0)
    );
    yolov5nu_tensor_frame_writer #(
        .FRAME_WIDTH(32), .FRAME_HEIGHT(1)
    ) writer1 (
        .clk(clk), .resetn(resetn), .start(start1), .abort(1'b0),
        .tensor_addr(32'h3100_0000), .frame_id(32'd2),
        .s_data({32{8'hbb}}), .s_sof(source_beat1 == 0),
        .s_eol(source_beat1 == 2), .s_eof(source_beat1 == 2),
        .s_frame_id(32'd2), .s_error(1'b0), .s_valid(1'b1),
        .s_ready(ready1), .busy(busy1), .done(done1),
        .error(error1), .bytes_written(bytes1), .m_axi(s1)
    );
    axi4_write_arbiter2 dut (
        .clk(clk), .resetn(resetn),
        .s0_axi(s0), .s1_axi(s1), .m_axi(m)
    );

    assign m.awready = !late_s0 || cycles >= 10;
    assign m.wready = 1'b1;
    assign m.bid = 3'd0;
    assign m.bresp = 2'd0;
    assign m.bvalid = bvalid;
    assign m.arready = 1'b0;
    assign m.rid = 3'd0;
    assign m.rdata = 256'd0;
    assign m.rresp = 2'd0;
    assign m.rlast = 1'b0;
    assign m.rvalid = 1'b0;

    always @(posedge clk) if (resetn) begin
        cycles <= cycles + 1;
        if (done0)
            done_seen0 <= 1;
        if (done1)
            done_seen1 <= 1;
        if (ready0)
            source_beat0 <= source_beat0 + 1;
        if (ready1)
            source_beat1 <= source_beat1 + 1;
        if (m.awvalid && m.awready) begin
            if (m.awaddr !== ((aw_seen == 0) == late_s0 ?
                              32'h3100_0000 : 32'h3000_0000) ||
                m.awlen !== 8'd2)
                $fatal(1, "arbiter AW order mismatch aw=%0d", aw_seen);
            burst_left <= 3;
            aw_seen <= aw_seen + 1;
        end
        if (m.wvalid && m.wready) begin
            if (m.wdata !== ((w_seen < 3) == late_s0 ?
                              {32{8'hbb}} : {32{8'haa}}) ||
                m.wlast !== (burst_left == 1))
                $fatal(1, "arbiter W interleaving at beat %0d", w_seen);
            burst_left <= burst_left - 1;
            w_seen <= w_seen + 1;
            if (m.wlast)
                bvalid <= 1;
        end
        if (m.bvalid && m.bready) begin
            bvalid <= 0;
            b_seen <= b_seen + 1;
        end
    end

    initial begin
        late_s0 = $test$plusargs("late_s0");
        repeat (5) @(negedge clk);
        resetn = 1;
        @(negedge clk);
        start1 = 1;
        if (!late_s0)
            start0 = 1;
        @(negedge clk);
        start1 = 0;
        start0 = 0;
        if (late_s0) begin
            repeat (3) @(negedge clk);
            start0 = 1;
            @(negedge clk);
            start0 = 0;
        end
        wait(done_seen0 && done_seen1);
        @(negedge clk);
        if (aw_seen != 2 || w_seen != 6 || b_seen != 2 ||
            bytes0 != 96 || bytes1 != 96 || error0 || error1)
            $fatal(1, "arbiter completion mismatch");
        $display("AXI4_WRITE_ARBITER2=PASS AW=%0d W=%0d B=%0d",
                 aw_seen, w_seen, b_seen);
        $finish;
    end
    initial begin
        repeat (100) @(posedge clk);
        $fatal(1, "arbiter timeout AW=%0d W=%0d B=%0d", aw_seen, w_seen, b_seen);
    end
endmodule
