`timescale 1ns/1ps

module tb_yolov5nu_tensor_capture_sidecar;
    reg clk = 0;
    always #5 clk = ~clk;
    reg resetn = 0, command_start = 0;
    reg [16*48-1:0] tap_data = 0;
    reg [15:0] tap_accept = 0, tap_sof = 0, tap_eol = 0;
    reg [15:0] tap_eof = 0, tap_error = 0;
    reg [16*32-1:0] tap_frame_id = 0;
    wire busy, completed, completion_error;
    wire [3:0] completion_channel;
    wire [31:0] completion_frame_id, completion_bytes, overflow_count;
    axi4_if #(.ADDR_WIDTH(32), .DATA_WIDTH(256), .ID_WIDTH(3)) axi();
    reg overflow_case;
    reg bvalid = 0;
    integer beat = 0, bursts = 0, burst_left = 0;
    integer cycles = 0;

    yolov5nu_tensor_capture_sidecar #(
        .CHANNELS(16), .FRAME_WIDTH(32), .FRAME_HEIGHT(4),
        .FIFO_DEPTH(16), .WATCHDOG_CYCLES(1000)
    ) dut (
        .clk(clk), .resetn(resetn), .command_start(command_start),
        .cancel(1'b0),
        .command_channel(4'd15), .command_addr(32'h3100_0000),
        .tap_data(tap_data), .tap_accept(tap_accept),
        .tap_sof(tap_sof), .tap_eol(tap_eol), .tap_eof(tap_eof),
        .tap_frame_id(tap_frame_id), .tap_error(tap_error),
        .busy(busy), .ready_for_frame(), .completed(completed),
        .completion_error(completion_error),
        .completion_channel(completion_channel),
        .completion_frame_id(completion_frame_id),
        .completion_bytes(completion_bytes),
        .overflow_count(overflow_count), .m_axi(axi)
    );

    function automatic [23:0] pixel(input integer index);
        pixel = {8'(index*3+1), 8'(index*3+2), 8'(index*3+3)};
    endfunction

    assign axi.awready = !overflow_case || cycles > 100;
    assign axi.wready = 1'b1;
    assign axi.bid = 3'd0;
    assign axi.bresp = 2'd0;
    assign axi.bvalid = bvalid;
    assign axi.arready = 1'b0;
    assign axi.rid = 3'd0;
    assign axi.rdata = 256'd0;
    assign axi.rresp = 2'd0;
    assign axi.rlast = 1'b0;
    assign axi.rvalid = 1'b0;

    always @(posedge clk) if (resetn) begin
        integer pixel_index, channel, expected;
        cycles <= cycles + 1;
        if (axi.awvalid && axi.awready) begin
            if (axi.awaddr !== 32'h3100_0000 + beat*32)
                $fatal(1, "sidecar AW address mismatch");
            burst_left <= int'(axi.awlen) + 1;
            bursts <= bursts + 1;
        end
        if (axi.wvalid && axi.wready) begin
            if (axi.wlast !== (burst_left == 1))
                $fatal(1, "sidecar WLAST mismatch");
            if (!overflow_case)
                for (int lane=0; lane<32; lane++) begin
                    pixel_index = (beat*32 + lane) / 3;
                    channel = (beat*32 + lane) % 3;
                    case (channel)
                        0: expected = (pixel_index*3+1) & 32'hff;
                        1: expected = (pixel_index*3+3) & 32'hff;
                        default: expected = (pixel_index*3+2) & 32'hff;
                    endcase
                    if (axi.wdata[lane*8 +: 8] !== 8'(expected >> 1))
                        $fatal(1, "sidecar tensor byte mismatch beat=%0d lane=%0d",
                               beat, lane);
                end
            beat <= beat + 1;
            burst_left <= burst_left - 1;
            if (axi.wlast)
                bvalid <= 1;
        end
        if (axi.bvalid && axi.bready)
            bvalid <= 0;
    end

    initial begin
        overflow_case = $test$plusargs("overflow");
        tap_frame_id[15*32 +: 32] = 32'd7;
        tap_frame_id[0 +: 32] = 32'd99;
        repeat (5) @(negedge clk);
        resetn = 1;
        @(negedge clk);
        command_start = 1;
        @(negedge clk);
        command_start = 0;
        for (int pair_index=0; pair_index<64; pair_index++) begin
            @(negedge clk);
            tap_data[15*48 +: 48] =
                {pixel(pair_index*2+1), pixel(pair_index*2)};
            tap_data[0 +: 48] = 48'habcdef123456;
            tap_accept = 16'h8001;
            tap_sof = pair_index == 0 ? 16'h8001 : 0;
            tap_eol = pair_index % 16 == 15 ? 16'h8001 : 0;
            tap_eof = pair_index == 63 ? 16'h8001 : 0;
        end
        @(negedge clk);
        tap_accept = 0;
        wait(completed);
        @(negedge clk);
        if (completion_channel != 15 || completion_frame_id != 7 ||
            completion_error != overflow_case ||
            (overflow_case && overflow_count != 1) ||
            (!overflow_case && (completion_bytes != 384 || beat != 12)))
            $fatal(1, "sidecar completion mismatch error=%0d bytes=%0d beats=%0d overflow=%0d",
                   completion_error, completion_bytes, beat, overflow_count);
        $display("YOLOV5NU_TENSOR_CAPTURE_SIDECAR=PASS overflow=%0d bytes=%0d",
                 overflow_case, completion_bytes);
        $finish;
    end
    initial begin
        repeat (1200) @(posedge clk);
        $fatal(1, "sidecar timeout state=%0d beats=%0d", dut.state, beat);
    end
endmodule
