`timescale 1ns/1ps

module tb_yolov5nu_tensor_stream_packer;
    reg clk = 0;
    always #5 clk = ~clk;
    reg resetn = 0;
    reg [47:0] s_pair = 0;
    reg s_sof = 0, s_eol = 0, s_eof = 0, s_error = 0;
    reg [31:0] s_frame_id = 7;
    reg s_valid = 0;
    wire s_ready;
    wire [255:0] m_data;
    wire m_sof, m_eol, m_eof, m_error, m_valid;
    wire [31:0] m_frame_id;
    reg m_ready = 0;
    integer cycle = 0, seen = 0;
    reg bad_case, continuous_case;

    yolov5nu_tensor_stream_packer #(.FRAME_WIDTH(32), .FRAME_HEIGHT(2)) dut (
        .clk(clk), .resetn(resetn), .s_pair(s_pair), .s_sof(s_sof),
        .s_eol(s_eol), .s_eof(s_eof), .s_frame_id(s_frame_id),
        .s_error(s_error), .s_valid(s_valid), .s_ready(s_ready),
        .m_data(m_data), .m_sof(m_sof), .m_eol(m_eol),
        .m_eof(m_eof), .m_frame_id(m_frame_id), .m_error(m_error),
        .m_valid(m_valid), .m_ready(m_ready)
    );

    function automatic [23:0] pixel(input integer index);
        reg [7:0] r, b, g;
        begin
            r = 8'(index * 3 + 1);
            b = 8'(index * 3 + 2);
            g = 8'(index * 3 + 3);
            pixel = {r, b, g};
        end
    endfunction

    always @(negedge clk) begin
        cycle = cycle + 1;
        m_ready = continuous_case || cycle % 4 != 1;
    end

    always @(posedge clk) if (resetn && m_valid && m_ready) begin
        integer byte_offset, pixel_index, channel, expected;
        if (m_sof != (seen == 0) ||
            m_eol != (seen % 3 == 2) ||
            m_eof != (seen == 5) ||
            m_frame_id != 7 || m_error != (bad_case && seen < 3))
            $fatal(1, "tensor beat metadata mismatch beat=%0d", seen);
        for (int lane=0; lane<32; lane++) begin
            byte_offset = (seen % 3) * 32 + lane;
            pixel_index = (seen / 3) * 32 + byte_offset / 3;
            channel = byte_offset % 3;
            case (channel)
                0: expected = (pixel_index * 3 + 1) & 8'hff;
                1: expected = (pixel_index * 3 + 3) & 8'hff;
                default: expected = (pixel_index * 3 + 2) & 8'hff;
            endcase
            if (m_data[lane*8 +: 8] !== 8'(expected >> 1))
                $fatal(1, "tensor byte mismatch beat=%0d lane=%0d got=%0h want=%0h",
                       seen, lane, m_data[lane*8 +: 8], expected >> 1);
        end
        seen = seen + 1;
    end

    initial begin
        bad_case = $test$plusargs("bad");
        continuous_case = $test$plusargs("continuous");
        repeat (5) @(negedge clk);
        resetn = 1;
        if (continuous_case) begin
            for (int pair_index=0; pair_index<32; pair_index++) begin
                @(negedge clk);
                if (!s_ready)
                    $fatal(1, "packer stalled continuous input pair=%0d",
                           pair_index);
                s_pair = {pixel(pair_index*2+1), pixel(pair_index*2)};
                s_sof = pair_index == 0;
                s_eol = pair_index % 16 == 15;
                s_eof = pair_index == 31;
                s_error = bad_case && pair_index == 15;
                s_valid = 1;
            end
            @(negedge clk);
            s_valid = 0;
        end else begin
            for (int pair_index=0; pair_index<32; pair_index++) begin
                @(negedge clk);
                s_pair = {pixel(pair_index*2+1), pixel(pair_index*2)};
                s_sof = pair_index == 0;
                s_eol = pair_index % 16 == 15;
                s_eof = pair_index == 31;
                s_error = bad_case && pair_index == 15;
                s_valid = 1;
                @(posedge clk);
                while (!s_ready) @(posedge clk);
                @(negedge clk);
                s_valid = 0;
            end
        end
        wait(seen == 6);
        $display("YOLOV5NU_TENSOR_STREAM_PACKER=PASS bad=%0d continuous=%0d beats=%0d",
                 bad_case, continuous_case, seen);
        $finish;
    end

    initial begin
        repeat (500) @(posedge clk);
        $fatal(1, "tensor stream packer timeout beats=%0d", seen);
    end
endmodule
