`timescale 1ns/1ps

// Converts the filtered HREF level into a protected, fixed-size byte line.
// A short low interval inside a line is treated as a control-signal glitch:
// data capture continues for up to HOLDOVER_CYCLES recovered PCLK events.
// Longer gaps flush the partial line and suppress the remainder of that frame.
module dvp_href_line_guard #(
    parameter integer LINE_BYTES = 1280,
    parameter integer HOLDOVER_CYCLES = 32
) (
    input  wire        clk,
    input  wire        resetn,
    input  wire        pixel_ce,
    input  wire        frame_boundary,
    input  wire        href,
    input  wire        diag_clear,
    output wire        byte_accept,
    output wire        line_start,
    output wire        line_last_byte,
    output reg         line_end,
    output reg  [31:0] diag_gap_recovered_count,
    output reg  [31:0] diag_flush_count,
    output reg  [5:0]  diag_gap_last,
    output reg  [5:0]  diag_gap_max,
    output reg  [10:0] diag_flush_position,
    output wire        active,
    output wire        discarding
);
    localparam integer BYTE_COUNT_WIDTH =
        (LINE_BYTES <= 2) ? 1 : $clog2(LINE_BYTES);
    localparam integer GAP_COUNT_WIDTH =
        (HOLDOVER_CYCLES <= 1) ? 1 : $clog2(HOLDOVER_CYCLES + 1);

    reg href_d;
    reg line_active;
    reg wait_for_low;
    reg discard_frame;
    reg [BYTE_COUNT_WIDTH-1:0] byte_count;
    reg [GAP_COUNT_WIDTH-1:0] gap_count;

    wire href_rise = href && !href_d;
    assign line_start = resetn && pixel_ce && !frame_boundary &&
                        !line_active && !wait_for_low && !discard_frame &&
                        href_rise;
    assign byte_accept = resetn && pixel_ce && !frame_boundary &&
                         (line_start ||
                          (line_active &&
                           (href || gap_count < HOLDOVER_CYCLES)));
    assign line_last_byte = byte_accept &&
                            (byte_count == BYTE_COUNT_WIDTH'(LINE_BYTES-1));
    assign active = line_active;
    assign discarding = discard_frame;

    initial begin
        if (LINE_BYTES < 2 || LINE_BYTES > 2048 ||
            HOLDOVER_CYCLES < 1 || HOLDOVER_CYCLES > 32)
            $error("dvp_href_line_guard parameter range error");
    end

    always @(posedge clk) begin
        if (!resetn) begin
            href_d <= 1'b0;
            line_active <= 1'b0;
            wait_for_low <= 1'b0;
            discard_frame <= 1'b0;
            byte_count <= {BYTE_COUNT_WIDTH{1'b0}};
            gap_count <= {GAP_COUNT_WIDTH{1'b0}};
            line_end <= 1'b0;
            diag_gap_recovered_count <= 32'd0;
            diag_flush_count <= 32'd0;
            diag_gap_last <= 6'd0;
            diag_gap_max <= 6'd0;
            diag_flush_position <= 11'd0;
        end else begin
            line_end <= 1'b0;
            if (pixel_ce)
                href_d <= href;

            if (frame_boundary) begin
                line_active <= 1'b0;
                wait_for_low <= 1'b0;
                discard_frame <= 1'b0;
                byte_count <= {BYTE_COUNT_WIDTH{1'b0}};
                gap_count <= {GAP_COUNT_WIDTH{1'b0}};
            end else if (pixel_ce) begin
                if (wait_for_low && !href)
                    wait_for_low <= 1'b0;

                if (line_start) begin
                    line_active <= 1'b1;
                    byte_count <= BYTE_COUNT_WIDTH'(1);
                    gap_count <= {GAP_COUNT_WIDTH{1'b0}};
                end else if (line_active) begin
                    if (!href && gap_count == HOLDOVER_CYCLES) begin
                        // The 32 protected samples are exhausted.  The byte
                        // position is the number already accepted (0..1279).
                        line_active <= 1'b0;
                        discard_frame <= 1'b1;
                        byte_count <= {BYTE_COUNT_WIDTH{1'b0}};
                        gap_count <= {GAP_COUNT_WIDTH{1'b0}};
                        line_end <= 1'b1;
                        diag_flush_count <= diag_flush_count + 1'b1;
                        diag_gap_last <= 6'(HOLDOVER_CYCLES);
                        if (diag_gap_max < HOLDOVER_CYCLES)
                            diag_gap_max <= 6'(HOLDOVER_CYCLES);
                        diag_flush_position <= 11'(byte_count);
                    end else if (byte_accept) begin
                        if (!href)
                            gap_count <= gap_count + 1'b1;
                        else if (gap_count != 0) begin
                            diag_gap_recovered_count <=
                                diag_gap_recovered_count + 1'b1;
                            diag_gap_last <= 6'(gap_count);
                            if (diag_gap_max < gap_count)
                                diag_gap_max <= 6'(gap_count);
                            gap_count <= {GAP_COUNT_WIDTH{1'b0}};
                        end

                        if (line_last_byte) begin
                            line_active <= 1'b0;
                            wait_for_low <= href;
                            byte_count <= {BYTE_COUNT_WIDTH{1'b0}};
                            line_end <= 1'b1;
                            if (!href) begin
                                diag_gap_recovered_count <=
                                    diag_gap_recovered_count + 1'b1;
                                diag_gap_last <= 6'(gap_count + 1'b1);
                                if (diag_gap_max < (gap_count + 1'b1))
                                    diag_gap_max <= 6'(gap_count + 1'b1);
                            end
                            gap_count <= {GAP_COUNT_WIDTH{1'b0}};
                        end else begin
                            byte_count <= byte_count + 1'b1;
                        end
                    end
                end
            end

            if (diag_clear) begin
                diag_gap_recovered_count <= 32'd0;
                diag_flush_count <= 32'd0;
                diag_gap_last <= 6'd0;
                diag_gap_max <= 6'd0;
                diag_flush_position <= 11'd0;
            end
        end
    end
endmodule
