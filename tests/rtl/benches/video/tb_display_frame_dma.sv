`timescale 1ns/1ps

module tb_display_frame_dma;
    localparam integer LINES = 8;
    reg clk = 0;
    reg resetn = 0;
    always #4 clk = ~clk;
    video_stream_if #(.DATA_WIDTH(32)) stream [1]();
    axi4_if #(.ADDR_WIDTH(32), .DATA_WIDTH(256), .ID_WIDTH(3)) axi();
    wire buffer_acquire, frame_done, frame_error;
    integer input_pair = 0;
    integer output_word = 0;
    integer aw_beats = 0;
    integer aw_bursts = 0;
    integer b_pending = 0;
    integer b_count = 0;
    integer cycles = 0;
    integer lane;
    integer pixel_index;

    assign stream[0].aclk = clk;
    assign stream[0].aresetn = resetn;
    assign axi.awready = (cycles % 7) != 2;
    assign axi.wready = (cycles % 5) != 3;
    assign axi.bid = 0;
    assign axi.bresp = 0;
    assign axi.bvalid = (b_pending != 0) && (cycles % 11 == 0);
    assign axi.arready = 0;
    assign axi.rid = 0;
    assign axi.rdata = 0;
    assign axi.rresp = 0;
    assign axi.rlast = 0;
    assign axi.rvalid = 0;

    multi_channel_video_dma #(
        .CHANNELS(1), .FRAME_WIDTH(368), .FRAME_HEIGHT(LINES),
        .FRAME_STRIDE_BYTES(736), .PIXEL_BYTES(2),
        .FIFO_DEPTH(64), .BURST_MAX_BEATS(8),
        .WRITE_OUTSTANDING(4), .DESCRIPTOR_DEPTH(8)
    ) dut (
        .channels(stream), .m_axi(axi),
        .buffer_acquire(buffer_acquire),
        .buffer_grant(buffer_acquire), .buffer_drop(1'b0),
        .buffer_base(32'h1000_0000),
        .frame_done(frame_done), .frame_error(frame_error),
        .channel_active(), .fifo_levels(), .active_frame_ids(),
        .perf_outstanding_current(), .perf_outstanding_max(),
        .perf_aw_stall_cycles(), .perf_w_stall_cycles(),
        .perf_b_stall_cycles(), .perf_bursts_issued(),
        .perf_bursts_completed(), .perf_response_errors()
    );

    initial begin
        stream[0].valid = 0;
        stream[0].data = 0;
        stream[0].sof = 0;
        stream[0].eol = 0;
        stream[0].eof = 0;
        stream[0].error = 0;
        stream[0].stream_id = 0;
        stream[0].frame_id = 32'h12345678;
        repeat (5) @(negedge clk);
        resetn = 1;
    end

    always @(negedge clk) if (resetn) begin
        stream[0].valid = input_pair < 180*LINES;
        stream[0].data = {16'(input_pair*2+1), 16'(input_pair*2)};
        stream[0].sof = input_pair == 0;
        stream[0].eol = input_pair % 180 == 179;
        stream[0].eof = input_pair == 180*LINES-1;
    end

    always @(posedge clk) if (resetn) begin
        cycles <= cycles + 1;
        if (stream[0].valid && stream[0].ready)
            input_pair <= input_pair + 1;
        if (axi.awvalid && axi.awready) begin
            if (axi.awaddr !== 32'h1000_0000 + aw_beats*32 ||
                axi.awlen > 7 ||
                (axi.awaddr[11:0] + (axi.awlen+1)*32) > 4096)
                $fatal(1, "bad AW address/length %08x/%0d", axi.awaddr, axi.awlen);
            aw_beats <= aw_beats + axi.awlen + 1;
            aw_bursts <= aw_bursts + 1;
        end
        if (axi.wvalid && axi.wready) begin
            for (lane=0; lane<16; lane=lane+1) begin
                pixel_index = (output_word/23)*360 +
                              (output_word%23)*16 + lane;
                if (axi.wdata[lane*16 +: 16] !==
                    (((output_word%23)*16+lane < 360) ?
                     16'(pixel_index) : 16'd0))
                    $fatal(1, "bad pixel word=%0d lane=%0d got=%04x",
                           output_word, lane, axi.wdata[lane*16 +:16]);
            end
            if (axi.wstrb !== 32'hffff_ffff)
                $fatal(1, "partial WSTRB");
            output_word <= output_word + 1;
        end
        case ({axi.wvalid && axi.wready && axi.wlast,
               axi.bvalid && axi.bready})
            2'b10: b_pending <= b_pending + 1;
            2'b01: b_pending <= b_pending - 1;
            default: ;
        endcase
        if (axi.bvalid && axi.bready)
            b_count <= b_count + 1;
        if (frame_error)
            $fatal(1, "valid frame reported error");
        if (frame_done) begin
            if (input_pair != 180*LINES || output_word != 23*LINES ||
                aw_beats != 23*LINES || b_pending != 0 ||
                b_count != aw_bursts)
                $fatal(1, "early/wrong completion in=%0d W=%0d AW=%0d B=%0d",
                       input_pair, output_word, aw_beats, b_count);
            $display("TB_DISPLAY_FRAME_DMA=PASS words=%0d responses=%0d",
                     output_word, b_count);
            $finish;
        end
        if (cycles > 20000)
            $fatal(1, "timeout in=%0d W=%0d AW=%0d B=%0d",
                   input_pair, output_word, aw_beats, b_count);
    end
endmodule
