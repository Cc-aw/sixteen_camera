`timescale 1ns/1ps

module tb_hdmi_4k_spatial_demux;
    reg clk = 1'b0;
    reg resetn = 1'b0;
    reg capture_enable = 1'b0;
    axis_video_if #(.DATA_WIDTH(48)) input_axis();
    video_stream_if #(.DATA_WIDTH(48), .STREAM_ID_WIDTH(4)) outputs [8]();
    wire [31:0] transport_frames;
    wire [31:0] transport_malformed;
    wire [255:0] overflow_counts;
    wire [255:0] frame_counts;
    integer beat_count [0:7];
    integer channel;
    integer x;
    integer y;

    always #1 clk = ~clk;

    assign input_axis.aclk = clk;
    assign input_axis.aresetn = resetn;

    generate
        genvar output_index;
        for (output_index = 0; output_index < 8;
             output_index = output_index + 1) begin : g_ready
            assign outputs[output_index].ready = 1'b1;
        end
    endgenerate

    hdmi_4k_spatial_demux dut (
        .s_axis(input_axis), .channels(outputs),
        .capture_enable(capture_enable),
        .transport_frame_count(transport_frames),
        .transport_malformed_count(transport_malformed),
        .channel_overflow_counts(overflow_counts),
        .channel_frame_counts(frame_counts)
    );

    function automatic [23:0] pixel_code(input integer beat_x,
                                          input integer line_y);
        pixel_code = {1'b0, line_y[11:0], beat_x[10:0]};
    endfunction

    generate
        genvar monitor_index;
        for (monitor_index = 0; monitor_index < 8;
             monitor_index = monitor_index + 1) begin : g_monitor
            always @(posedge clk) begin
                integer source_x;
                integer source_y;
                integer slot_col;
                integer slot_row;
                reg [23:0] expected;
                if (resetn && outputs[monitor_index].valid &&
                    outputs[monitor_index].ready) begin
                    source_x = beat_count[monitor_index] % 320;
                    source_y = beat_count[monitor_index] / 320;
                    slot_col = monitor_index % 4;
                    slot_row = monitor_index / 4;
                    expected = pixel_code(slot_col*480 + 80 + source_x,
                                          slot_row*1080 + 300 + source_y);
                    if (outputs[monitor_index].data != {expected, expected})
                        $fatal(1, "CH%0d data mismatch at %0d,%0d",
                               monitor_index + 8, source_x, source_y);
                    if (outputs[monitor_index].stream_id != monitor_index + 8)
                        $fatal(1, "CH%0d stream id=%0d", monitor_index + 8,
                               outputs[monitor_index].stream_id);
                    if (outputs[monitor_index].sof !=
                        (beat_count[monitor_index] == 0))
                        $fatal(1, "CH%0d bad SOF at beat %0d",
                               monitor_index + 8, beat_count[monitor_index]);
                    if (outputs[monitor_index].eol != (source_x == 319))
                        $fatal(1, "CH%0d bad EOL at %0d,%0d",
                               monitor_index + 8, source_x, source_y);
                    if (outputs[monitor_index].eof !=
                        ((source_x == 319) && (source_y == 479)))
                        $fatal(1, "CH%0d bad EOF at %0d,%0d",
                               monitor_index + 8, source_x, source_y);
                    if (outputs[monitor_index].error)
                        $fatal(1, "CH%0d unexpected error", monitor_index + 8);
                    beat_count[monitor_index] =
                        beat_count[monitor_index] + 1;
                end
            end
        end
    endgenerate

    initial begin
        input_axis.tdata = 48'd0;
        input_axis.tvalid = 1'b0;
        input_axis.tuser = 1'b0;
        input_axis.tlast = 1'b0;
        for (channel = 0; channel < 8; channel = channel + 1)
            beat_count[channel] = 0;
        repeat (4) @(posedge clk);
        resetn = 1'b1;
        capture_enable = 1'b1;

        for (y = 0; y < 2160; y = y + 1) begin
            for (x = 0; x < 1920; x = x + 1) begin
                @(negedge clk);
                input_axis.tvalid = 1'b1;
                input_axis.tuser = (x == 0) && (y == 0);
                input_axis.tlast = (x == 1919);
                input_axis.tdata = {pixel_code(x, y), pixel_code(x, y)};
            end
        end
        @(negedge clk);
        input_axis.tvalid = 1'b0;
        input_axis.tuser = 1'b0;
        input_axis.tlast = 1'b0;
        repeat (3) @(posedge clk);

        for (channel = 0; channel < 8; channel = channel + 1) begin
            if (beat_count[channel] != 320*480)
                $fatal(1, "CH%0d beats=%0d", channel + 8,
                       beat_count[channel]);
            if (frame_counts[channel*32 +: 32] != 1)
                $fatal(1, "CH%0d frame count=%0d", channel + 8,
                       frame_counts[channel*32 +: 32]);
        end
        if (transport_frames != 1 || transport_malformed != 0 ||
            overflow_counts != 0)
            $fatal(1, "transport f/m/overflow=%0d/%0d/%h",
                   transport_frames, transport_malformed, overflow_counts);
        $display("HDMI_4K_SPATIAL_DEMUX_SIM=PASS");
        $finish;
    end

    initial begin
        #20000000;
        $fatal(1, "HDMI_4K_SPATIAL_DEMUX_SIM=TIMEOUT");
    end
endmodule
