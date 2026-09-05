`timescale 1ns/1ps

module tb_camera_axis_cdc_line_boundary;
    reg clk = 1'b0;
    reg resetn = 1'b0;
    reg camera_enable = 1'b1;
    reg pixel_valid = 1'b0;
    wire pixel_ready;
    reg [23:0] pixel_data = 24'd0;
    reg frame_start = 1'b0;
    reg line_last = 1'b0;
    reg line_end = 1'b0;
    wire [31:0] line_flush_count;
    axis_video_if #(.DATA_WIDTH(48)) axis();
    reg [47:0] captured [0:7];
    reg captured_last [0:7];
    integer captured_count = 0;
    integer timeout;
    always #2 clk = ~clk;
    assign axis.tready = 1'b1;

    camera_axis_cdc #(.FRAME_WIDTH(4), .FIFO_DEPTH(16)) dut (
        .camera_clk(clk), .camera_resetn(resetn),
        .camera_enable(camera_enable),
        .pixel_valid(pixel_valid), .pixel_ready(pixel_ready),
        .pixel_data(pixel_data), .frame_start(frame_start),
        .line_last(line_last), .line_end(line_end),
        .diag_clear_toggle(1'b0),
        .ddr_clk(clk), .ddr_resetn(resetn),
        .diag_fire_count(), .diag_sof_count(), .diag_eol_count(),
        .diag_fifo_full_stall_count(), .diag_ready_low_count(),
        .diag_fifo_max_level(), .diag_line_flush_count(line_flush_count),
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

    task automatic end_line;
        begin
            @(negedge clk); line_end = 1'b1;
            @(posedge clk);
            @(negedge clk); line_end = 1'b0;
        end
    endtask

    task automatic wait_outputs(input integer target);
        begin
            timeout = 0;
            while (captured_count < target) begin
                @(posedge clk);
                timeout = timeout + 1;
                if (timeout > 100) $fatal(1, "output timeout");
            end
        end
    endtask

    always @(posedge clk) begin
        if (resetn && axis.tvalid && axis.tready) begin
            captured[captured_count] = axis.tdata;
            captured_last[captured_count] = axis.tlast;
            captured_count = captured_count + 1;
        end
    end

    initial begin
        repeat (5) @(posedge clk);
        resetn = 1'b1;
        repeat (5) @(posedge clk);

        // Complete line: two packed beats, EOL only on the second.
        send_pixel(24'h000001, 1'b1, 1'b0);
        send_pixel(24'h000002, 1'b0, 1'b0);
        send_pixel(24'h000003, 1'b0, 1'b0);
        send_pixel(24'h000004, 1'b0, 1'b1);
        end_line();

        // Short odd line: pixel 0a is orphaned and must not reach next line.
        send_pixel(24'h000008, 1'b0, 1'b0);
        send_pixel(24'h000009, 1'b0, 1'b0);
        send_pixel(24'h00000a, 1'b0, 1'b0);
        end_line();

        // Following line must start with 0x20/0x21, never 0x0a/0x20.
        send_pixel(24'h000020, 1'b0, 1'b0);
        send_pixel(24'h000021, 1'b0, 1'b0);
        send_pixel(24'h000022, 1'b0, 1'b0);
        send_pixel(24'h000023, 1'b0, 1'b1);
        end_line();
        wait_outputs(5);

        // Disable in the middle of a pair.  Re-enable must synchronously
        // flush the orphan so it can never be joined to the next line.
        send_pixel(24'h000030, 1'b0, 1'b0);
        @(negedge clk); camera_enable = 1'b0;
        repeat (3) @(posedge clk);
        @(negedge clk); camera_enable = 1'b1;
        repeat (3) @(posedge clk);
        send_pixel(24'h000040, 1'b0, 1'b0);
        send_pixel(24'h000041, 1'b0, 1'b1);
        end_line();
        wait_outputs(6);

        if (captured[0] != {24'h000002,24'h000001} ||
            captured[1] != {24'h000004,24'h000003} || !captured_last[1] ||
            captured[2] != {24'h000009,24'h000008} || captured_last[2] ||
            captured[3] != {24'h000021,24'h000020} ||
            captured[4] != {24'h000023,24'h000022} || !captured_last[4] ||
            captured[5] != {24'h000041,24'h000040} || !captured_last[5])
            $fatal(1, "line packing/cross-line isolation failed");
        if (line_flush_count != 1)
            $fatal(1, "line_flush_count=%0d expected 1", line_flush_count);
        $display("TB_CAMERA_AXIS_CDC_LINE_BOUNDARY=PASS");
        $finish;
    end
endmodule
