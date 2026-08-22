`timescale 1ns/1ps

module tb_camera_axis_to_stream_recovery;
    reg clk = 1'b0;
    reg resetn = 1'b0;
    reg clear_toggle = 1'b0;
    always #2 clk = ~clk;

    axis_video_if #(.DATA_WIDTH(48)) input_axis();
    video_stream_if #(.DATA_WIDTH(48)) output_stream();
    wire [31:0] malformed_count;
    wire [255:0] diag_counts;
    wire [31:0] timeout_abort_count;
    integer output_beat = 0;
    integer output_frames = 0;
    reg frame_had_error = 1'b0;
    reg completed_error [0:7];
    integer timeout;

    assign input_axis.aclk = clk;
    assign input_axis.aresetn = resetn;

    camera_axis_to_stream #(
        .FRAME_WIDTH(4), .FRAME_HEIGHT(3), .STREAM_ID(2),
        .NO_DATA_TIMEOUT_CYCLES(8)
    ) dut (
        .s_axis(input_axis), .m_stream(output_stream),
        .diag_clear_toggle(clear_toggle),
        .malformed_frame_count(malformed_count), .diag_counts(diag_counts),
        .timeout_abort_count(timeout_abort_count)
    );

    task automatic send_beat(input [47:0] data, input bit sof,
                             input bit eol);
        begin
            @(negedge clk);
            input_axis.tdata = data;
            input_axis.tuser = sof;
            input_axis.tlast = eol;
            input_axis.tvalid = 1'b1;
            do @(posedge clk); while (!input_axis.tready);
            @(negedge clk);
            input_axis.tvalid = 1'b0;
            input_axis.tuser = 1'b0;
            input_axis.tlast = 1'b0;
        end
    endtask

    task automatic send_good_frame(input [15:0] tag);
        integer beat;
        begin
            for (beat = 0; beat < 6; beat = beat + 1)
                send_beat({16'd0, tag, beat[15:0]}, beat == 0,
                          (beat & 1) != 0);
        end
    endtask

    task automatic wait_frames(input integer target);
        begin
            timeout = 0;
            while (output_frames < target) begin
                @(posedge clk);
                timeout = timeout + 1;
                if (timeout > 200)
                    $fatal(1, "timeout waiting for frame %0d", target);
            end
        end
    endtask

    always @(posedge clk) begin
        if (resetn && output_stream.valid && output_stream.ready) begin
            if (output_stream.sof !== (output_beat == 0))
                $fatal(1, "bad normalized SOF at beat %0d", output_beat);
            if (output_stream.eol !== ((output_beat & 1) != 0))
                $fatal(1, "bad normalized EOL at beat %0d", output_beat);
            if (output_stream.eof !== (output_beat == 5))
                $fatal(1, "bad normalized EOF at beat %0d", output_beat);
            frame_had_error = frame_had_error | output_stream.error;
            if (output_beat == 5) begin
                completed_error[output_frames] =
                    frame_had_error | output_stream.error;
                output_frames = output_frames + 1;
                output_beat = 0;
                frame_had_error = 1'b0;
            end else begin
                output_beat = output_beat + 1;
            end
        end
    end

    initial begin
        input_axis.tdata = 48'd0;
        input_axis.tvalid = 1'b0;
        input_axis.tuser = 1'b0;
        input_axis.tlast = 1'b0;
        output_stream.ready = 1'b1;
        repeat (5) @(posedge clk);
        resetn = 1'b1;

        // 1: unmodified good frame.
        send_good_frame(16'h1000);
        wait_frames(1);
        if (completed_error[0]) $fatal(1, "good frame marked bad");

        // 2: early EOL on the SOF beat. The remaining five beats are padded.
        send_beat(48'h2000, 1'b1, 1'b1);
        wait_frames(2);
        if (!completed_error[1]) $fatal(1, "early-EOL frame not marked bad");

        // 3/4: a new SOF interrupts a partial frame. It must remain at the
        // FIFO head while the old frame is padded, then become a full good frame.
        send_beat(48'h3000, 1'b1, 1'b0);
        send_beat(48'h4000, 1'b1, 1'b0);
        send_beat(48'h4001, 1'b0, 1'b1);
        send_beat(48'h4002, 1'b0, 1'b0);
        send_beat(48'h4003, 1'b0, 1'b1);
        send_beat(48'h4004, 1'b0, 1'b0);
        send_beat(48'h4005, 1'b0, 1'b1);
        wait_frames(4);
        if (!completed_error[2] || completed_error[3])
            $fatal(1, "unexpected-SOF recovery failed");

        // 5: missing EOL at the expected line boundary.
        send_beat(48'h5000, 1'b1, 1'b0);
        send_beat(48'h5001, 1'b0, 1'b0);
        wait_frames(5);
        if (!completed_error[4]) $fatal(1, "missing-EOL frame not marked bad");

        // A stale tail beat is discarded; the following good SOF resynchronizes.
        send_beat(48'h5bad, 1'b0, 1'b0);
        send_good_frame(16'h6000);
        wait_frames(6);
        if (completed_error[5]) $fatal(1, "post-recovery frame marked bad");

        // 7/8: stop delivering data in the middle of a frame. The watchdog
        // must finish it, then accept the following good frame.
        send_beat(48'h7000, 1'b1, 1'b0);
        wait_frames(7);
        if (!completed_error[6] || timeout_abort_count != 1)
            $fatal(1, "no-data watchdog failed");
        send_good_frame(16'h8000);
        wait_frames(8);
        if (completed_error[7]) $fatal(1, "post-timeout frame marked bad");

        if (malformed_count != 4 || diag_counts[31:0] != 1 ||
            diag_counts[63:32] != 1 || diag_counts[95:64] != 1 ||
            diag_counts[127:96] != 4 || diag_counts[159:128] != 1 ||
            diag_counts[191:160] != 19 || diag_counts[223:192] != 4 ||
            diag_counts[255:224] != 4)
            $fatal(1, "diagnostic counters wrong: mal=%0d diag=%064x",
                   malformed_count, diag_counts);

        // MMIO clear crosses as a toggle and must not reset functional state.
        @(negedge clk); clear_toggle = ~clear_toggle;
        repeat (5) @(posedge clk);
        if (malformed_count != 0 || diag_counts != 0 ||
            timeout_abort_count != 0)
            $fatal(1, "diagnostic clear failed");

        $display("TB_CAMERA_AXIS_TO_STREAM_RECOVERY=PASS");
        $finish;
    end
endmodule
