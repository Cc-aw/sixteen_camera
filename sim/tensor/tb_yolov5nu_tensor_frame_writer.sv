`timescale 1ns/1ps

module tb_yolov5nu_tensor_frame_writer;
    reg clk = 0;
    always #5 clk = ~clk;
    reg resetn = 0, start = 0, abort = 0;
    reg [31:0] tensor_addr;
    reg [47:0] s_pair = 0;
    reg s_sof = 0, s_eol = 0, s_eof = 0, s_error = 0;
    reg s_valid = 0;
    wire s_ready;
    wire [255:0] packed_data;
    wire packed_sof, packed_eol, packed_eof, packed_error, packed_valid;
    wire [31:0] packed_frame_id;
    wire packed_ready;
    wire busy, done, error;
    wire [31:0] bytes_written;
    axi4_if #(.ADDR_WIDTH(32), .DATA_WIDTH(256), .ID_WIDTH(3)) axi();

    integer cycles = 0, aw_seen = 0, w_seen = 0, b_seen = 0;
    integer burst_remaining = 0, b_delay = 0;
    reg write_active = 0, bvalid = 0;
    reg bad_input, bad_response, page_boundary, abort_case;
    reg done_seen = 0;
    wire [31:0] expected_bursts = abort_case ? 1 :
                                  page_boundary ? 3 : 2;

    yolov5nu_tensor_stream_packer #(.FRAME_WIDTH(32), .FRAME_HEIGHT(2)) packer (
        .clk(clk), .resetn(resetn), .s_pair(s_pair), .s_sof(s_sof),
        .s_eol(s_eol), .s_eof(s_eof), .s_frame_id(32'd7),
        .s_error(s_error), .s_valid(s_valid), .s_ready(s_ready),
        .m_data(packed_data), .m_sof(packed_sof), .m_eol(packed_eol),
        .m_eof(packed_eof), .m_frame_id(packed_frame_id),
        .m_error(packed_error), .m_valid(packed_valid),
        .m_ready(packed_ready)
    );

    yolov5nu_tensor_frame_writer #(
        .FRAME_WIDTH(32), .FRAME_HEIGHT(2), .MAX_BURST_BEATS(4)
    ) dut (
        .clk(clk), .resetn(resetn), .start(start), .abort(abort),
        .tensor_addr(tensor_addr), .frame_id(32'd7),
        .s_data(packed_data), .s_sof(packed_sof),
        .s_eol(packed_eol), .s_eof(packed_eof),
        .s_frame_id(packed_frame_id), .s_error(packed_error),
        .s_valid(packed_valid), .s_ready(packed_ready),
        .busy(busy), .done(done), .error(error),
        .bytes_written(bytes_written), .m_axi(axi)
    );

    function automatic [23:0] pixel(input integer index);
        pixel = {8'(index*3+1), 8'(index*3+2), 8'(index*3+3)};
    endfunction

    assign axi.awready = !write_active && !bvalid && b_delay == 0;
    assign axi.wready = write_active && cycles % 3 != 1;
    assign axi.bid = 3'd0;
    assign axi.bresp = bad_response && b_seen == expected_bursts-1 ?
                       2'b10 : 2'b00;
    assign axi.bvalid = bvalid;
    assign axi.arready = 1'b0;
    assign axi.rid = 3'd0;
    assign axi.rdata = 256'd0;
    assign axi.rresp = 2'd0;
    assign axi.rlast = 1'b0;
    assign axi.rvalid = 1'b0;

    always @(posedge clk) if (resetn) begin
        integer byte_offset, pixel_index, channel, expected;
        if (done)
            done_seen <= 1;
        cycles <= cycles + 1;
        if (done && b_seen != expected_bursts)
            $fatal(1, "writer released tensor before final B response");
        if (axi.awvalid && axi.awready) begin
            if (axi.awaddr !== tensor_addr +
                (page_boundary ? (aw_seen == 0 ? 0 :
                                  aw_seen == 1 ? 32 : 160) :
                                 aw_seen*128) ||
                axi.awlen !== (page_boundary ?
                               (aw_seen == 1 ? 8'd3 : 8'd0) :
                               (aw_seen == 0 ? 8'd3 : 8'd1)) ||
                axi.awsize !== 3'd5 || axi.awburst !== 2'd1)
                $fatal(1, "unexpected AW burst %0d", aw_seen);
            burst_remaining <= int'(axi.awlen) + 1;
            write_active <= 1;
            aw_seen <= aw_seen + 1;
        end
        if (axi.wvalid && axi.wready) begin
            if (!write_active || axi.wstrb !== 32'hffff_ffff ||
                axi.wlast !== (burst_remaining == 1))
                $fatal(1, "invalid W beat %0d", w_seen);
            for (int lane=0; lane<32; lane++) begin
                byte_offset = w_seen*32 + lane;
                pixel_index = byte_offset / 3;
                channel = byte_offset % 3;
                case (channel)
                    0: expected = (pixel_index*3+1) & 32'hff;
                    1: expected = (pixel_index*3+3) & 32'hff;
                    default: expected = (pixel_index*3+2) & 32'hff;
                endcase
                if (axi.wdata[lane*8 +: 8] !==
                    (abort_case && w_seen >= 2 ? 8'd0 :
                     8'(expected >> 1)))
                    $fatal(1, "tensor byte mismatch beat=%0d lane=%0d", w_seen, lane);
            end
            burst_remaining <= burst_remaining - 1;
            w_seen <= w_seen + 1;
            if (axi.wlast) begin
                write_active <= 0;
                b_delay <= 4;
            end
            if (abort_case && w_seen == 1)
                abort <= 1;
        end
        if (b_delay > 0)
            b_delay <= b_delay - 1;
        if (b_delay == 1)
            bvalid <= 1;
        if (axi.bvalid && axi.bready) begin
            bvalid <= 0;
            b_seen <= b_seen + 1;
        end
    end

    initial begin
        bad_input = $test$plusargs("bad_input");
        bad_response = $test$plusargs("bad_response");
        page_boundary = $test$plusargs("page_boundary");
        abort_case = $test$plusargs("abort");
        tensor_addr = page_boundary ? 32'h3100_2fe0 : 32'h3100_2000;
        repeat (5) @(negedge clk);
        resetn = 1;
        @(negedge clk);
        start = 1;
        @(negedge clk);
        start = 0;
        for (int pair_index=0; pair_index<32; pair_index++) begin
            @(negedge clk);
            while (!s_ready) @(negedge clk);
            s_pair = {pixel(pair_index*2+1), pixel(pair_index*2)};
            s_sof = pair_index == 0;
            s_eol = pair_index % 16 == 15;
            s_eof = pair_index == 31;
            s_error = bad_input && pair_index == 15;
            s_valid = 1;
            @(negedge clk);
            s_valid = 0;
        end
        wait(done_seen);
        @(negedge clk);
        if (busy || bytes_written != (abort_case ? 128 : 192) ||
            aw_seen != expected_bursts ||
            w_seen != (abort_case ? 4 : 6) ||
            b_seen != expected_bursts ||
            error != (bad_input || bad_response || abort_case))
            $fatal(1, "writer completion mismatch: bytes=%0d AW=%0d W=%0d B=%0d error=%0d",
                   bytes_written, aw_seen, w_seen, b_seen, error);
        $display("YOLOV5NU_TENSOR_FRAME_WRITER=PASS input_error=%0d b_error=%0d",
                 bad_input, bad_response);
        $finish;
    end

    initial begin
        repeat (500) @(posedge clk);
        $fatal(1, "tensor frame writer timeout AW=%0d W=%0d B=%0d", aw_seen, w_seen, b_seen);
    end
endmodule
