`timescale 1ns/1ps

module tb_dvp_event_bridge_assembler;
    reg capture_clk = 0;
    reg video_clk = 0;
    always #5 capture_clk = ~capture_clk;
    always #10 video_clk = ~video_clk;

    reg capture_resetn = 0;
    reg video_resetn = 0;
    reg capture_enable = 0;
    reg event_valid = 0;
    wire event_ready;
    reg [7:0] event_data = 0;
    reg event_byte_valid = 0;
    reg event_line_start = 0;
    reg event_line_last = 0;
    reg event_line_end = 0;
    reg event_frame_boundary = 0;
    reg event_fault = 0;
    wire video_event_valid;
    wire video_event_ready;
    wire [7:0] video_event_data;
    wire video_byte_valid, video_line_start, video_line_last;
    wire video_line_end, video_frame_boundary, video_resync;
    wire video_fault_pulse;
    wire [31:0] overflow_count;
    wire pixel_valid;
    reg pixel_ready = 1;
    wire [23:0] pixel_data;
    wire frame_start, line_last, line_end;
    reg [23:0] expected [0:31];
    integer expected_count = 0;
    integer read_count = 0;
    integer sof_count = 0;
    integer eol_count = 0;
    reg [31:0] lfsr = 32'h1ace_beef;
    reg check_outputs = 1;
    reg stalled;
    reg [25:0] stalled_payload;

    dvp_event_bridge #(.FIFO_DEPTH(8)) u_bridge (.*);
    camera_pixel_assembler u_assembler (
        .video_clk(video_clk), .video_resetn(video_resetn),
        .camera_enable(capture_enable),
        .event_valid(video_event_valid), .event_ready(video_event_ready),
        .event_data(video_event_data), .event_byte_valid(video_byte_valid),
        .event_line_start(video_line_start),
        .event_line_last(video_line_last), .event_line_end(video_line_end),
        .event_frame_boundary(video_frame_boundary),
        .event_resync(video_resync), .fault_pulse(video_fault_pulse),
        .pixel_valid(pixel_valid), .pixel_ready(pixel_ready),
        .pixel_data(pixel_data), .frame_start(frame_start),
        .line_last(line_last), .line_end(line_end)
    );

    function automatic [23:0] expand565(input [15:0] value);
        expand565 = {value[15:11], value[15:13],
                     value[4:0], value[4:2],
                     value[10:5], value[10:9]};
    endfunction

    task automatic push_event(
        input bit byte_valid, input [7:0] data,
        input bit line_start_i, input bit line_last_i,
        input bit line_end_i, input bit frame_i, input bit fault_i
    );
        begin
            @(negedge capture_clk);
            event_valid = 1;
            event_byte_valid = byte_valid;
            event_data = data;
            event_line_start = line_start_i;
            event_line_last = line_last_i;
            event_line_end = line_end_i;
            event_frame_boundary = frame_i;
            event_fault = fault_i;
            @(negedge capture_clk);
            event_valid = 0;
            event_byte_valid = 0;
            event_line_start = 0;
            event_line_last = 0;
            event_line_end = 0;
            event_frame_boundary = 0;
            event_fault = 0;
        end
    endtask

    task automatic push_line(input [15:0] base, input integer pixels);
        integer i;
        reg [15:0] word;
        begin
            for (i = 0; i < pixels; i = i + 1) begin
                word = base + 16'(i);
                expected[expected_count] = expand565(word);
                expected_count = expected_count + 1;
                push_event(1, word[15:8], i == 0, 0, 0, 0, 0);
                push_event(1, word[7:0], 0, i == pixels-1, 0, 0, 0);
            end
            push_event(0, 0, 0, 0, 1, 0, 0);
        end
    endtask

    always @(posedge video_clk) begin
        lfsr <= {lfsr[30:0], lfsr[31] ^ lfsr[21] ^ lfsr[1] ^ lfsr[0]};
        if (video_resetn && check_outputs)
            pixel_ready <= lfsr[0] | lfsr[3];
        if (pixel_valid && !pixel_ready) begin
            if (stalled && stalled_payload != {frame_start, line_last, pixel_data})
                $fatal(1, "pixel payload changed while stalled");
            stalled <= 1;
            stalled_payload <= {frame_start, line_last, pixel_data};
        end else begin
            stalled <= 0;
        end
        if (pixel_valid && pixel_ready && check_outputs) begin
            if (read_count >= expected_count)
                $fatal(1, "unexpected pixel %h", pixel_data);
            if (pixel_data !== expected[read_count])
                $fatal(1, "pixel %0d mismatch got=%h expected=%h",
                       read_count, pixel_data, expected[read_count]);
            read_count <= read_count + 1;
            if (frame_start) sof_count <= sof_count + 1;
            if (line_last) eol_count <= eol_count + 1;
        end
    end

    initial begin
        stalled = 0;
        repeat (5) @(posedge capture_clk);
        capture_resetn = 1;
        video_resetn = 1;
        capture_enable = 1;
        repeat (12) @(posedge capture_clk);

        // Ordered blanking boundary followed by a normal RGB565 line.
        push_event(0, 0, 0, 0, 0, 1, 0);
        push_line(16'h1230, 6);
        wait (read_count == expected_count);
        if (sof_count != 1 || eol_count != 1)
            $fatal(1, "normal boundary counts sof=%0d eol=%0d",
                   sof_count, eol_count);

        // Block the video consumer until the source-side event FIFO overflows.
        check_outputs = 0;
        pixel_ready = 0;
        push_event(0, 0, 0, 0, 0, 1, 0);
        repeat (20) push_event(1, 8'($random), 0, 0, 0, 0, 0);
        if (overflow_count == 0)
            $fatal(1, "event FIFO overflow was not recorded");
        pixel_ready = 1;
        repeat (30) @(posedge video_clk);

        // A later complete frame boundary is the only point allowed to resume.
        expected_count = 0;
        read_count = 0;
        sof_count = 0;
        eol_count = 0;
        check_outputs = 1;
        push_event(0, 0, 0, 0, 0, 1, 0);
        push_line(16'h7a40, 4);
        wait (read_count == expected_count);
        if (sof_count != 1 || eol_count != 1)
            $fatal(1, "resync boundary counts sof=%0d eol=%0d",
                   sof_count, eol_count);
        $display("TB_DVP_EVENT_BRIDGE_ASSEMBLER=PASS overflow=%0d",
                 overflow_count);
        $finish;
    end
endmodule
