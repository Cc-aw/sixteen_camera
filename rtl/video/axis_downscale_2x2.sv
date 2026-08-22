`timescale 1ns/1ps

// Nearest-neighbor 2:1 downscaler for RGB888 AXI4-Stream video.
// Both interfaces use two pixels per beat: {pixel[1], pixel[0]}.
// For each 2x2 input block, pixel (0,0) is retained.
module axis_downscale_2x2 #(
    parameter integer INPUT_WIDTH  = 3840,
    parameter integer INPUT_HEIGHT = 2160
) (
    axis_video_if.sink   s_axis,
    axis_video_if.source m_axis
);
    localparam integer OUTPUT_WIDTH  = INPUT_WIDTH / 2;
    localparam integer OUTPUT_HEIGHT = INPUT_HEIGHT / 2;
    localparam integer INPUT_BEATS_PER_LINE = INPUT_WIDTH / 2;

    reg        input_even_line;
    reg        have_first_pixel;
    reg [23:0] first_pixel;
    reg        first_user;
    reg [47:0] output_data;
    reg        output_valid;
    reg        output_user;
    reg        output_last;

    wire input_fire;
    wire output_fire;
    wire input_makes_output;

    assign m_axis.aclk = s_axis.aclk;
    assign m_axis.aresetn = s_axis.aresetn;
    assign m_axis.tdata = output_data;
    assign m_axis.tvalid = output_valid;
    assign m_axis.tuser = output_user;
    assign m_axis.tlast = output_last;

    // Only every second beat of an even input line produces an output beat.
    // Such a beat can replace an output consumed in the same cycle.
    assign input_makes_output = input_even_line && have_first_pixel;
    assign s_axis.tready = !input_makes_output || !output_valid || m_axis.tready;
    assign input_fire = s_axis.tvalid && s_axis.tready;
    assign output_fire = output_valid && m_axis.tready;

    initial begin
        if ((INPUT_WIDTH % 4) != 0 || (INPUT_HEIGHT % 2) != 0) begin
            $error("axis_downscale_2x2 requires INPUT_WIDTH divisible by 4 and INPUT_HEIGHT divisible by 2");
        end
    end

    always @(posedge s_axis.aclk) begin
        if (!s_axis.aresetn) begin
            input_even_line <= 1'b1;
            have_first_pixel <= 1'b0;
            first_pixel <= 24'd0;
            first_user <= 1'b0;
            output_data <= 48'd0;
            output_valid <= 1'b0;
            output_user <= 1'b0;
            output_last <= 1'b0;
        end else begin
            if (output_fire) begin
                output_valid <= 1'b0;
                output_user <= 1'b0;
                output_last <= 1'b0;
            end

            if (input_fire) begin
                // SOF realigns the decimation phase after any upstream reset.
                if (s_axis.tuser) begin
                    input_even_line <= 1'b1;
                    have_first_pixel <= 1'b1;
                    first_pixel <= s_axis.tdata[23:0];
                    first_user <= 1'b1;
                end else if (input_even_line) begin
                    if (!have_first_pixel) begin
                        have_first_pixel <= 1'b1;
                        first_pixel <= s_axis.tdata[23:0];
                        first_user <= 1'b0;
                    end else begin
                        output_data <= {s_axis.tdata[23:0], first_pixel};
                        output_valid <= 1'b1;
                        output_user <= first_user;
                        output_last <= s_axis.tlast;
                        have_first_pixel <= 1'b0;
                        first_user <= 1'b0;
                    end
                end

                if (s_axis.tlast) begin
                    input_even_line <= !input_even_line;
                    have_first_pixel <= 1'b0;
                    first_user <= 1'b0;
                end
            end
        end
    end

    wire unused_dimensions = &{1'b0, OUTPUT_WIDTH[0], OUTPUT_HEIGHT[0],
                               INPUT_BEATS_PER_LINE[0]};
endmodule
