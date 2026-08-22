`timescale 1ns/1ps

// Expands a native two-pixel AXIS frame into a larger, centered frame.  The
// adapter runs after camera_axis_cdc, matching the CH5/CH6 DDR-clocked path;
// only image-region beats consume the source stream.
module camera_axis_center_pad #(
    parameter integer INPUT_WIDTH = 640,
    parameter integer INPUT_HEIGHT = 480,
    parameter integer OUTPUT_WIDTH = 1920,
    parameter integer OUTPUT_HEIGHT = 1080,
    parameter integer LEFT_MARGIN = 640,
    parameter integer TOP_MARGIN = 300
) (
    axis_video_if.sink s_axis,
    axis_video_if.source m_axis,
    output reg [31:0] input_error_count
);
    localparam integer INPUT_BEATS = INPUT_WIDTH / 2;
    localparam integer OUTPUT_BEATS = OUTPUT_WIDTH / 2;
    localparam integer LEFT_BEATS = LEFT_MARGIN / 2;
    localparam integer RIGHT_START = LEFT_BEATS + INPUT_BEATS;
    localparam integer BOTTOM_START = TOP_MARGIN + INPUT_HEIGHT;
    localparam integer X_WIDTH = $clog2(OUTPUT_BEATS);
    localparam integer Y_WIDTH = $clog2(OUTPUT_HEIGHT);
    localparam integer INPUT_X_WIDTH = $clog2(INPUT_BEATS);
    localparam integer INPUT_Y_WIDTH = $clog2(INPUT_HEIGHT);
    localparam [X_WIDTH-1:0] LEFT_BEAT = X_WIDTH'(LEFT_BEATS);
    localparam [X_WIDTH-1:0] RIGHT_BEAT = X_WIDTH'(RIGHT_START);
    localparam [X_WIDTH-1:0] LAST_OUTPUT_BEAT =
        X_WIDTH'(OUTPUT_BEATS - 1);
    localparam [Y_WIDTH-1:0] TOP_LINE = Y_WIDTH'(TOP_MARGIN);
    localparam [Y_WIDTH-1:0] BOTTOM_LINE = Y_WIDTH'(BOTTOM_START);
    localparam [Y_WIDTH-1:0] LAST_OUTPUT_LINE =
        Y_WIDTH'(OUTPUT_HEIGHT - 1);
    localparam [INPUT_X_WIDTH-1:0] LAST_INPUT_BEAT =
        INPUT_X_WIDTH'(INPUT_BEATS - 1);
    localparam [INPUT_Y_WIDTH-1:0] LAST_INPUT_LINE =
        INPUT_Y_WIDTH'(INPUT_HEIGHT - 1);

    reg active;
    reg [X_WIDTH-1:0] output_beat;
    reg [Y_WIDTH-1:0] output_line;
    reg [INPUT_X_WIDTH-1:0] input_beat;
    reg [INPUT_Y_WIDTH-1:0] input_line;

    wire in_image_line = (output_line >= TOP_LINE) &&
                         (output_line < BOTTOM_LINE);
    wire in_image = active && in_image_line &&
                    (output_beat >= LEFT_BEAT) &&
                    (output_beat < RIGHT_BEAT);
    wire output_valid = active && (in_image ? s_axis.tvalid : 1'b1);
    wire output_fire = output_valid && m_axis.tready;
    wire input_fire = in_image && s_axis.tvalid && m_axis.tready;
    wire expected_input_sof = (input_beat == 0) && (input_line == 0);
    wire expected_input_eol = (input_beat == LAST_INPUT_BEAT);

    initial begin
        if ((INPUT_WIDTH & 1) != 0 || (OUTPUT_WIDTH & 1) != 0 ||
            INPUT_WIDTH <= 0 || INPUT_HEIGHT <= 0 ||
            OUTPUT_WIDTH <= 0 || OUTPUT_HEIGHT <= 0 ||
            LEFT_MARGIN < 0 || TOP_MARGIN < 0 ||
            LEFT_MARGIN + INPUT_WIDTH > OUTPUT_WIDTH ||
            TOP_MARGIN + INPUT_HEIGHT > OUTPUT_HEIGHT)
            $error("camera_axis_center_pad has invalid geometry");
    end

    assign s_axis.tready = s_axis.aresetn &&
                           (active ? (in_image && m_axis.tready) :
                                     (s_axis.tvalid && !s_axis.tuser));
    assign m_axis.aclk = s_axis.aclk;
    assign m_axis.aresetn = s_axis.aresetn;
    assign m_axis.tdata = in_image ? s_axis.tdata : 48'd0;
    assign m_axis.tvalid = output_valid;
    assign m_axis.tuser = output_valid && (output_beat == 0) &&
                          (output_line == 0);
    assign m_axis.tlast = output_valid &&
                          (output_beat == LAST_OUTPUT_BEAT);

    always @(posedge s_axis.aclk) begin
        if (!s_axis.aresetn) begin
            active <= 1'b0;
            output_beat <= {X_WIDTH{1'b0}};
            output_line <= {Y_WIDTH{1'b0}};
            input_beat <= 0;
            input_line <= 0;
            input_error_count <= 32'd0;
        end else begin
            if (!active) begin
                output_beat <= {X_WIDTH{1'b0}};
                output_line <= {Y_WIDTH{1'b0}};
                input_beat <= 0;
                input_line <= 0;
                if (s_axis.tvalid && s_axis.tuser)
                    active <= 1'b1;
            end else if (output_fire) begin
                if (output_beat == LAST_OUTPUT_BEAT) begin
                    output_beat <= {X_WIDTH{1'b0}};
                    if (output_line == LAST_OUTPUT_LINE) begin
                        output_line <= {Y_WIDTH{1'b0}};
                        active <= 1'b0;
                    end else begin
                        output_line <= output_line + 1'b1;
                    end
                end else begin
                    output_beat <= output_beat + 1'b1;
                end
            end

            if (input_fire) begin
                if ((s_axis.tuser != expected_input_sof) ||
                    (s_axis.tlast != expected_input_eol))
                    input_error_count <= input_error_count + 1'b1;

                if (input_beat == LAST_INPUT_BEAT) begin
                    input_beat <= 0;
                    if (input_line == LAST_INPUT_LINE)
                        input_line <= 0;
                    else
                        input_line <= input_line + 1'b1;
                end else begin
                    input_beat <= input_beat + 1'b1;
                end
            end
        end
    end
endmodule
