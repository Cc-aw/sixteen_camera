`timescale 1ns/1ps

module tb_display_scaler;
    reg clk = 0;
    reg resetn = 0;
    always #3 clk = ~clk;

    video_stream_if #(.DATA_WIDTH(48), .STREAM_ID_WIDTH(4)) source();
    video_stream_if #(.DATA_WIDTH(32), .STREAM_ID_WIDTH(4)) scaled();
    display_scaler dut(.s_video(source), .m_video(scaled));
    assign source.aclk = clk;
    assign source.aresetn = resetn;

    integer in_index = 0;
    integer out_index = 0;
    integer cycles = 0;
    integer source_x;
    integer source_y;
    integer output_x;
    integer output_y;
    integer reference_x;
    integer reference_y;
    integer input_frame;
    integer input_local;
    integer output_frame;
    integer output_local;

    function automatic [23:0] pixel(input integer x, input integer y);
        pixel = {8'(x), 8'(y), 8'(x ^ y)};
    endfunction

    function automatic [15:0] rgb565(input [23:0] rgb);
        rgb565 = {rgb[23:19], rgb[15:10], rgb[7:3]};
    endfunction

    initial begin
        source.valid = 0;
        source.data = 0;
        source.sof = 0;
        source.eol = 0;
        source.eof = 0;
        source.error = 0;
        source.stream_id = 4'd5;
        source.frame_id = 32'h1234abcd;
        scaled.ready = 0;
        repeat (5) @(negedge clk);
        resetn = 1;
    end

    always @(negedge clk) if (resetn) begin
        input_frame = in_index / (320*480);
        input_local = in_index % (320*480);
        source_x = (input_local % 320) * 2;
        source_y = input_local / 320;
        source.valid = (in_index < 3*320*480) && ((cycles % 13) != 4);
        source.data = {pixel(source_x+1, source_y), pixel(source_x, source_y)};
        source.sof = (input_local == 0);
        source.eol = (source_x == 638);
        source.eof = (input_local == 320*480-1);
        source.error = (input_frame == 1 && source.eof);
        source.frame_id = 32'h1234abcd + 32'(input_frame);
        scaled.ready = ((cycles % 17) != 3) && ((cycles % 17) != 4);
    end

    always @(posedge clk) if (resetn) begin
        cycles <= cycles + 1;
        if (source.valid && source.ready)
            in_index <= in_index + 1;
        if (scaled.valid && scaled.ready) begin
            output_frame = out_index / (180*270);
            output_local = out_index % (180*270);
            output_x = output_local % 180;
            output_y = output_local / 180;
            reference_x = ((output_x * 16) / 9) * 2;
            reference_y = (output_y * 16) / 9;
            if (scaled.data !== {rgb565(pixel(reference_x+1, reference_y)),
                                 rgb565(pixel(reference_x, reference_y))})
                $fatal(1, "pixel mismatch output=%0d x=%0d y=%0d got=%08x",
                       out_index, output_x, output_y, scaled.data);
            if (scaled.sof !== (output_local == 0) ||
                scaled.eol !== (output_x == 179) ||
                scaled.eof !== (output_local == 180*270-1) ||
                scaled.frame_id !== (32'h1234abcd + 32'(output_frame)) ||
                scaled.stream_id !== 4'd5 ||
                scaled.error !== (output_frame == 1 &&
                                  output_local == 180*270-1))
                $fatal(1, "metadata mismatch output=%0d", out_index);
            out_index <= out_index + 1;
        end
        if (in_index == 3*320*480 && out_index == 3*180*270) begin
            $display("TB_DISPLAY_SCALER=PASS inputs=%0d outputs=%0d", in_index,
                     out_index);
            $finish;
        end
        if (cycles > 1050000)
            $fatal(1, "timeout inputs=%0d outputs=%0d", in_index, out_index);
    end
endmodule
