`timescale 1ns/1ps

module tb_camera_axis_cdc_backpressure;
    reg clk = 1'b0;
    reg resetn = 1'b0;
    reg camera_enable = 1'b1;
    reg pixel_valid = 1'b0;
    wire pixel_ready;
    reg [23:0] pixel_data = 0;
    reg frame_start = 1'b0;
    reg line_last = 1'b0;
    reg line_end = 1'b0;
    reg ready_q = 1'b0;
    reg random_ready = 1'b0;
    reg [15:0] lfsr = 16'h1ace;
    wire [31:0] fifo_max_level;
    axis_video_if #(.DATA_WIDTH(48)) axis();

    reg [49:0] expected [0:255];
    integer expected_write = 0;
    integer expected_read = 0;
    integer timeout;
    integer beat;
    integer near_full_level;
    reg stalled = 1'b0;
    reg [49:0] stalled_payload;

    always #2 clk = ~clk;
    assign axis.tready = ready_q;

    camera_axis_cdc #(.FRAME_WIDTH(20), .FIFO_DEPTH(8)) dut (
        .camera_clk(clk), .camera_resetn(resetn),
        .camera_enable(camera_enable),
        .pixel_valid(pixel_valid), .pixel_ready(pixel_ready),
        .pixel_data(pixel_data), .frame_start(frame_start),
        .line_last(line_last), .line_end(line_end),
        .diag_clear_toggle(1'b0),
        .ddr_clk(clk), .ddr_resetn(resetn),
        .diag_fire_count(), .diag_sof_count(), .diag_eol_count(),
        .diag_fifo_full_stall_count(), .diag_ready_low_count(),
        .diag_fifo_max_level(fifo_max_level), .diag_line_flush_count(),
        .m_axis(axis)
    );

    task automatic send_pixel(input [23:0] value, input bit sof,
                              input bit last);
        begin
            @(negedge clk);
            pixel_data = value;
            frame_start = sof;
            line_last = last;
            pixel_valid = 1'b1;
            do @(posedge clk); while (!pixel_ready);
            @(negedge clk);
            pixel_valid = 1'b0;
            frame_start = 1'b0;
            line_last = 1'b0;
        end
    endtask

    task automatic send_pair(input integer index, input bit sof,
                             input bit last);
        reg [23:0] p0;
        reg [23:0] p1;
        begin
            p0 = 24'h100000 + 24'(index * 2);
            p1 = p0 + 1'b1;
            send_pixel(p0, sof, 1'b0);
            send_pixel(p1, 1'b0, last);
            expected[expected_write] = {last, sof, p1, p0};
            expected_write = expected_write + 1;
        end
    endtask

    task automatic wait_consumed(input integer target);
        begin
            timeout = 0;
            while (expected_read < target) begin
                @(posedge clk);
                timeout = timeout + 1;
                if (timeout > 4000)
                    $fatal(1, "output timeout read=%0d target=%0d",
                           expected_read, target);
            end
        end
    endtask

    always @(negedge clk) begin
        lfsr <= {lfsr[14:0], lfsr[15] ^ lfsr[13] ^ lfsr[12] ^ lfsr[10]};
        if (random_ready)
            ready_q <= lfsr[0] | lfsr[3];
    end

    always @(posedge clk) begin
        if (!resetn || !camera_enable) begin
            stalled <= 1'b0;
        end else begin
            if (axis.tvalid && !axis.tready) begin
                if (stalled && ({axis.tlast, axis.tuser, axis.tdata} !==
                                stalled_payload))
                    $fatal(1, "AXIS payload changed while stalled");
                stalled <= 1'b1;
                stalled_payload <= {axis.tlast, axis.tuser, axis.tdata};
            end else begin
                stalled <= 1'b0;
            end

            if (axis.tvalid && axis.tready) begin
                if (expected_read >= expected_write)
                    $fatal(1, "unexpected output beat");
                if ({axis.tlast, axis.tuser, axis.tdata} !==
                    expected[expected_read])
                    $fatal(1, "beat %0d mismatch got=%h expected=%h",
                           expected_read,
                           {axis.tlast, axis.tuser, axis.tdata},
                           expected[expected_read]);
                expected_read <= expected_read + 1;
            end
        end
    end

    initial begin
        repeat (5) @(posedge clk);
        resetn = 1'b1;
        wait (pixel_ready);

        // Random backpressure: order, sidebands and stall stability.
        random_ready = 1'b1;
        for (beat = 0; beat < 80; beat = beat + 1)
            send_pair(beat, beat == 0, (beat % 10) == 9);
        wait_consumed(80);

        // Fill the two prefetch registers plus most of the eight-word FIFO.
        // Once released, nine buffered beats must drain at one beat/clock.
        @(negedge clk);
        random_ready = 1'b0;
        ready_q = 1'b0;
        for (beat = 80; beat < 89; beat = beat + 1)
            send_pair(beat, 1'b0, beat == 88);
        repeat (12) @(posedge clk);
        if (fifo_max_level < 8)
            $fatal(1, "near-full occupancy not reached: %0d", fifo_max_level);
        near_full_level = fifo_max_level;
        @(negedge clk); ready_q = 1'b1;
        repeat (9) begin
            @(posedge clk);
            if (!(axis.tvalid && axis.tready))
                $fatal(1, "throughput bubble while draining prefetch FIFO");
        end
        wait_consumed(89);

        // Disable with queued data.  Old beats must be flushed before the
        // next enable transaction and may not leak into the new stream.
        @(negedge clk); ready_q = 1'b0;
        for (beat = 89; beat < 93; beat = beat + 1)
            send_pair(beat, 1'b0, beat == 92);
        @(negedge clk); camera_enable = 1'b0;
        expected_read = expected_write;
        repeat (4) @(posedge clk);
        @(negedge clk); camera_enable = 1'b1;
        wait (pixel_ready);
        repeat (4) begin
            @(posedge clk);
            if (axis.tvalid)
                $fatal(1, "pre-disable beat leaked after re-enable");
        end
        @(negedge clk); ready_q = 1'b1;
        send_pair(93, 1'b1, 1'b1);
        wait_consumed(94);

        $display("TB_CAMERA_AXIS_CDC_BACKPRESSURE=PASS max_level=%0d",
                 near_full_level);
        $finish;
    end
endmodule
