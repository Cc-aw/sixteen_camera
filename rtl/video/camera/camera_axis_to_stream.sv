`timescale 1ns/1ps

// Converts the camera AXIS stream into fixed-geometry frames for the DDR
// writer. A malformed input frame is completed with error-marked black beats
// before the next SOF is accepted, so a partial frame cannot hold a writer
// context forever.
module camera_axis_to_stream #(
    parameter integer FRAME_WIDTH = 1920,
    parameter integer FRAME_HEIGHT = 1080,
    parameter integer STREAM_ID = 4,
    parameter integer STREAM_ID_WIDTH = 3,
    parameter integer FRAME_ID_WIDTH = 32,
    // capture_clk is the 300 MHz DDR UI clock.  Five million idle cycles are
    // approximately half of a 30 Hz frame (16.67 ms).
    parameter integer NO_DATA_TIMEOUT_CYCLES = 5000000
) (
    axis_video_if.sink s_axis,
    video_stream_if.source m_stream,
    input wire diag_clear_toggle,
    output reg [31:0] malformed_frame_count,
    output wire [255:0] diag_counts,
    output reg [31:0] timeout_abort_count
);
    localparam integer BEATS_PER_LINE = FRAME_WIDTH / 2;
    localparam integer X_WIDTH = (BEATS_PER_LINE <= 1) ? 1 : $clog2(BEATS_PER_LINE);
    localparam integer Y_WIDTH = (FRAME_HEIGHT <= 1) ? 1 : $clog2(FRAME_HEIGHT);
    localparam [X_WIDTH-1:0] LAST_BEAT = X_WIDTH'(BEATS_PER_LINE - 1);
    localparam [Y_WIDTH-1:0] LAST_LINE = Y_WIDTH'(FRAME_HEIGHT - 1);
    localparam [1:0] WAIT_SOF = 2'd0;
    localparam [1:0] FRAME = 2'd1;
    localparam [1:0] PAD = 2'd2;
    localparam integer WATCHDOG_WIDTH = (NO_DATA_TIMEOUT_CYCLES <= 2) ? 1 :
                                        $clog2(NO_DATA_TIMEOUT_CYCLES);
    localparam [WATCHDOG_WIDTH-1:0] WATCHDOG_LAST =
        WATCHDOG_WIDTH'(NO_DATA_TIMEOUT_CYCLES - 1);

    reg [1:0] state;
    reg [X_WIDTH-1:0] x_beat;
    reg [Y_WIDTH-1:0] y_line;
    reg [FRAME_ID_WIDTH-1:0] frame_id;
    reg recovery_pending;
    reg [WATCHDOG_WIDTH-1:0] no_data_count;

    reg out_valid;
    reg [47:0] out_data;
    reg out_sof;
    reg out_eol;
    reg out_eof;
    reg out_error;
    reg [FRAME_ID_WIDTH-1:0] out_frame_id;

    reg [31:0] unexpected_sof_count;
    reg [31:0] early_eol_count;
    reg [31:0] missing_eol_count;
    reg [31:0] aborted_frame_count;
    reg [31:0] discarded_beat_count;
    reg [31:0] padded_beat_count;
    reg [31:0] good_frame_count;
    reg [31:0] resync_frame_count;

    (* ASYNC_REG = "TRUE", SHREG_EXTRACT = "NO" *) reg diag_clear_sync1;
    (* ASYNC_REG = "TRUE", SHREG_EXTRACT = "NO" *) reg diag_clear_sync2;
    reg diag_clear_seen;

    wire output_slot = !out_valid || m_stream.ready;
    wire expected_eol = (x_beat == LAST_BEAT);
    wire expected_eof = expected_eol && (y_line == LAST_LINE);
    wire held_unexpected_sof = (state == FRAME) && s_axis.tvalid && s_axis.tuser;
    wire accept = s_axis.tvalid && s_axis.tready;
    wire line_fault = (s_axis.tlast != expected_eol);
    wire diag_clear = (diag_clear_sync2 != diag_clear_seen);
    wire no_data_timeout = (state == FRAME) && !s_axis.tvalid &&
                           (no_data_count == WATCHDOG_LAST);

    initial begin
        if ((FRAME_WIDTH & 1) != 0 || FRAME_WIDTH <= 0 || FRAME_HEIGHT <= 0 ||
            NO_DATA_TIMEOUT_CYCLES < 2)
            $error("camera_axis_to_stream requires a positive even frame width");
    end

    // Hold an unexpected SOF at the CDC FIFO head while padding the previous
    // frame. It is then accepted as the first beat of the recovered frame.
    assign s_axis.tready = s_axis.aresetn && output_slot &&
                           (state != PAD) && !held_unexpected_sof;
    assign m_stream.aclk = s_axis.aclk;
    assign m_stream.aresetn = s_axis.aresetn;
    assign m_stream.data = out_data;
    assign m_stream.valid = out_valid;
    assign m_stream.sof = out_sof;
    assign m_stream.eol = out_eol;
    assign m_stream.eof = out_eof;
    assign m_stream.stream_id = STREAM_ID[STREAM_ID_WIDTH-1:0];
    assign m_stream.frame_id = out_frame_id;
    assign m_stream.error = out_error;

    // Word order is the camera MMIO ABI at offsets 0xe4 through 0x100.
    assign diag_counts = {resync_frame_count, good_frame_count,
                          padded_beat_count, discarded_beat_count,
                          aborted_frame_count, missing_eol_count,
                          early_eol_count, unexpected_sof_count};

    always @(posedge s_axis.aclk) begin
        if (!s_axis.aresetn) begin
            state <= WAIT_SOF;
            x_beat <= {X_WIDTH{1'b0}};
            y_line <= {Y_WIDTH{1'b0}};
            frame_id <= {FRAME_ID_WIDTH{1'b1}};
            recovery_pending <= 1'b0;
            no_data_count <= {WATCHDOG_WIDTH{1'b0}};
            out_valid <= 1'b0;
            out_data <= 48'd0;
            out_sof <= 1'b0;
            out_eol <= 1'b0;
            out_eof <= 1'b0;
            out_error <= 1'b0;
            out_frame_id <= {FRAME_ID_WIDTH{1'b0}};
            malformed_frame_count <= 32'd0;
            unexpected_sof_count <= 32'd0;
            early_eol_count <= 32'd0;
            missing_eol_count <= 32'd0;
            aborted_frame_count <= 32'd0;
            discarded_beat_count <= 32'd0;
            padded_beat_count <= 32'd0;
            good_frame_count <= 32'd0;
            resync_frame_count <= 32'd0;
            timeout_abort_count <= 32'd0;
            diag_clear_sync1 <= 1'b0;
            diag_clear_sync2 <= 1'b0;
            diag_clear_seen <= 1'b0;
        end else begin
            diag_clear_sync1 <= diag_clear_toggle;
            diag_clear_sync2 <= diag_clear_sync1;
            if ((state == FRAME) && !s_axis.tvalid) begin
                if (no_data_count != WATCHDOG_LAST)
                    no_data_count <= no_data_count + 1'b1;
            end else begin
                no_data_count <= {WATCHDOG_WIDTH{1'b0}};
            end
            if (output_slot)
                out_valid <= 1'b0;

            // Do not consume this SOF. Emit the first missing beat of the old
            // frame now; PAD completes it while the SOF remains held.
            if (held_unexpected_sof && output_slot) begin
                state <= expected_eof ? WAIT_SOF : PAD;
                out_valid <= 1'b1;
                out_data <= 48'd0;
                out_sof <= 1'b0;
                out_eol <= expected_eol;
                out_eof <= expected_eof;
                out_error <= 1'b1;
                out_frame_id <= frame_id;
                unexpected_sof_count <= unexpected_sof_count + 1'b1;
                aborted_frame_count <= aborted_frame_count + 1'b1;
                malformed_frame_count <= malformed_frame_count + 1'b1;
                padded_beat_count <= padded_beat_count + 1'b1;
                recovery_pending <= 1'b1;
                if (expected_eof) begin
                    x_beat <= {X_WIDTH{1'b0}};
                    y_line <= {Y_WIDTH{1'b0}};
                end else if (expected_eol) begin
                    x_beat <= {X_WIDTH{1'b0}};
                    y_line <= y_line + 1'b1;
                end else begin
                    x_beat <= x_beat + 1'b1;
                end
            end else if (no_data_timeout && output_slot) begin
                // A camera can stop PCLK/HREF in the middle of a frame. Finish
                // that writer transaction instead of waiting indefinitely.
                state <= expected_eof ? WAIT_SOF : PAD;
                out_valid <= 1'b1;
                out_data <= 48'd0;
                out_sof <= 1'b0;
                out_eol <= expected_eol;
                out_eof <= expected_eof;
                out_error <= 1'b1;
                out_frame_id <= frame_id;
                aborted_frame_count <= aborted_frame_count + 1'b1;
                malformed_frame_count <= malformed_frame_count + 1'b1;
                padded_beat_count <= padded_beat_count + 1'b1;
                timeout_abort_count <= timeout_abort_count + 1'b1;
                recovery_pending <= 1'b1;
                no_data_count <= {WATCHDOG_WIDTH{1'b0}};
                if (expected_eof) begin
                    x_beat <= {X_WIDTH{1'b0}};
                    y_line <= {Y_WIDTH{1'b0}};
                end else if (expected_eol) begin
                    x_beat <= {X_WIDTH{1'b0}};
                    y_line <= y_line + 1'b1;
                end else begin
                    x_beat <= x_beat + 1'b1;
                end
            end else if ((state == PAD) && output_slot) begin
                out_valid <= 1'b1;
                out_data <= 48'd0;
                out_sof <= 1'b0;
                out_eol <= expected_eol;
                out_eof <= expected_eof;
                out_error <= 1'b1;
                out_frame_id <= frame_id;
                padded_beat_count <= padded_beat_count + 1'b1;
                if (expected_eof) begin
                    state <= WAIT_SOF;
                    x_beat <= {X_WIDTH{1'b0}};
                    y_line <= {Y_WIDTH{1'b0}};
                end else if (expected_eol) begin
                    x_beat <= {X_WIDTH{1'b0}};
                    y_line <= y_line + 1'b1;
                end else begin
                    x_beat <= x_beat + 1'b1;
                end
            end else if (accept) begin
                if ((state == WAIT_SOF) && !s_axis.tuser) begin
                    discarded_beat_count <= discarded_beat_count + 1'b1;
                    recovery_pending <= 1'b1;
                    x_beat <= {X_WIDTH{1'b0}};
                    y_line <= {Y_WIDTH{1'b0}};
                end else begin
                    out_valid <= 1'b1;
                    out_data <= s_axis.tdata;
                    out_sof <= (state == WAIT_SOF);
                    out_eol <= expected_eol;
                    out_eof <= expected_eof;
                    out_error <= line_fault;
                    if (state == WAIT_SOF) begin
                        frame_id <= frame_id + 1'b1;
                        out_frame_id <= frame_id + 1'b1;
                        if (recovery_pending) begin
                            resync_frame_count <= resync_frame_count + 1'b1;
                            recovery_pending <= 1'b0;
                        end
                    end else begin
                        out_frame_id <= frame_id;
                    end

                    if (line_fault) begin
                        if (s_axis.tlast)
                            early_eol_count <= early_eol_count + 1'b1;
                        else
                            missing_eol_count <= missing_eol_count + 1'b1;
                        aborted_frame_count <= aborted_frame_count + 1'b1;
                        malformed_frame_count <= malformed_frame_count + 1'b1;
                        recovery_pending <= 1'b1;
                        state <= expected_eof ? WAIT_SOF : PAD;
                    end else if (expected_eof) begin
                        state <= WAIT_SOF;
                        good_frame_count <= good_frame_count + 1'b1;
                    end else begin
                        state <= FRAME;
                    end

                    if (expected_eof) begin
                        x_beat <= {X_WIDTH{1'b0}};
                        y_line <= {Y_WIDTH{1'b0}};
                    end else if (expected_eol) begin
                        x_beat <= {X_WIDTH{1'b0}};
                        y_line <= y_line + 1'b1;
                    end else begin
                        x_beat <= x_beat + 1'b1;
                    end
                end
            end

            // Telemetry clear is independent of the functional recovery FSM.
            if (diag_clear) begin
                diag_clear_seen <= diag_clear_sync2;
                malformed_frame_count <= 32'd0;
                unexpected_sof_count <= 32'd0;
                early_eol_count <= 32'd0;
                missing_eol_count <= 32'd0;
                aborted_frame_count <= 32'd0;
                discarded_beat_count <= 32'd0;
                padded_beat_count <= 32'd0;
                good_frame_count <= 32'd0;
                resync_frame_count <= 32'd0;
                timeout_abort_count <= 32'd0;
            end
        end
    end
endmodule
