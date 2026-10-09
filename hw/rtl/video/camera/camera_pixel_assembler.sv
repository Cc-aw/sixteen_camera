`timescale 1ns/1ps

// RGB565 byte assembly in the 150 MHz video domain.  A resync/fault discards
// partial pixels and suppresses output until the next ordered frame boundary.
module camera_pixel_assembler (
    input  wire       video_clk,
    input  wire       video_resetn,
    input  wire       camera_enable,
    input  wire       event_valid,
    output wire       event_ready,
    input  wire [7:0] event_data,
    input  wire       event_byte_valid,
    input  wire       event_line_start,
    input  wire       event_line_last,
    input  wire       event_line_end,
    input  wire       event_frame_boundary,
    input  wire       event_resync,
    input  wire       fault_pulse,
    output wire       pixel_valid,
    input  wire       pixel_ready,
    output wire [23:0] pixel_data,
    output wire       frame_start,
    output wire       line_last,
    output wire       line_end
);
    reg [7:0] first_byte;
    reg byte_phase;
    reg frame_pending;
    reg sof_pending;
    reg discard_until_frame;
    reg output_valid;
    reg [23:0] output_data;
    reg output_sof;
    reg output_eol;
    reg output_line_end;
    wire output_slot = !output_valid || pixel_ready;
    assign event_ready = video_resetn && camera_enable && output_slot;

    function automatic [23:0] rgb565_to_rgb888(input [15:0] value);
        reg [4:0] red;
        reg [5:0] green;
        reg [4:0] blue;
        begin
            red = value[15:11];
            green = value[10:5];
            blue = value[4:0];
            rgb565_to_rgb888 = {red, red[4:2], blue, blue[4:2],
                                green, green[5:4]};
        end
    endfunction

    always @(posedge video_clk) begin
        if (!video_resetn || !camera_enable) begin
            first_byte <= 8'd0;
            byte_phase <= 1'b0;
            frame_pending <= 1'b0;
            sof_pending <= 1'b0;
            discard_until_frame <= 1'b1;
            output_valid <= 1'b0;
            output_data <= 24'd0;
            output_sof <= 1'b0;
            output_eol <= 1'b0;
            output_line_end <= 1'b0;
        end else begin
            if (output_slot) begin
                output_valid <= 1'b0;
                output_line_end <= 1'b0;
            end
            if (fault_pulse) begin
                discard_until_frame <= 1'b1;
                byte_phase <= 1'b0;
                sof_pending <= 1'b0;
                output_valid <= 1'b0;
                output_line_end <= 1'b0;
            end else if (event_valid && event_ready) begin
                if (event_resync) begin
                    discard_until_frame <= 1'b1;
                    byte_phase <= 1'b0;
                    sof_pending <= 1'b0;
                end
                if (event_frame_boundary) begin
                    discard_until_frame <= 1'b0;
                    frame_pending <= 1'b1;
                    byte_phase <= 1'b0;
                    sof_pending <= 1'b0;
                end
                if (event_line_end) begin
                    byte_phase <= 1'b0;
                    output_line_end <= !discard_until_frame;
                end
                if (event_byte_valid &&
                    (!discard_until_frame || event_frame_boundary)) begin
                    if (event_line_start &&
                        (frame_pending || event_frame_boundary)) begin
                        frame_pending <= 1'b0;
                        sof_pending <= 1'b1;
                    end
                    if (!byte_phase) begin
                        first_byte <= event_data;
                        byte_phase <= 1'b1;
                    end else begin
                        output_data <= rgb565_to_rgb888({first_byte, event_data});
                        output_valid <= 1'b1;
                        output_sof <= sof_pending;
                        output_eol <= event_line_last;
                        byte_phase <= 1'b0;
                        sof_pending <= 1'b0;
                    end
                end
            end
        end
    end

    assign pixel_valid = output_valid;
    assign pixel_data = output_data;
    assign frame_start = output_valid && output_sof;
    assign line_last = output_valid && output_eol;
    assign line_end = output_line_end;
endmodule
