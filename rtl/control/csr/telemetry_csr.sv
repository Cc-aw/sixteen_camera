`timescale 1ns/1ps

// Read-only frame-store, writer, reader and HDMI telemetry windows.
module telemetry_csr #(
    parameter integer CHANNELS = 16
) (
    input  wire [9:0] read_addr,
    output reg  read_hit,
    output reg  [31:0] read_data,
    input  wire [CHANNELS*32-1:0] writer_frame_counts,
    input  wire [CHANNELS*32-1:0] drop_counts,
    input  wire [CHANNELS*32-1:0] malformed_counts,
    input  wire [31:0] reader_frame_count,
    input  wire [31:0] underflow_count,
    input  wire [31:0] reader_active_base,
    input  wire [31:0] reader_debug_status,
    input  wire [31:0] writer_perf_outstanding_current,
    input  wire [31:0] writer_perf_outstanding_max,
    input  wire [31:0] writer_perf_aw_stall_cycles,
    input  wire [31:0] writer_perf_w_stall_cycles,
    input  wire [31:0] writer_perf_b_stall_cycles,
    input  wire [31:0] writer_perf_bursts_issued,
    input  wire [31:0] writer_perf_bursts_completed,
    input  wire [31:0] writer_perf_response_errors,
    input  wire [31:0] hdmi_transport_frame_count,
    input  wire [31:0] hdmi_transport_malformed_count,
    input  wire [8*32-1:0] hdmi_channel_frame_counts,
    input  wire [8*32-1:0] hdmi_channel_overflow_counts
);
    localparam [9:0] REG_WRITER0 = 10'h080;
    localparam [9:0] REG_DROP0 = 10'h0c0;
    localparam [9:0] REG_MALFORMED0 = 10'h100;
    localparam [9:0] REG_READER_COUNT = 10'h140;
    localparam [9:0] REG_UNDERFLOW = 10'h144;
    localparam [9:0] REG_READER_BASE = 10'h148;
    localparam [9:0] REG_READER_DEBUG = 10'h14c;
    localparam [9:0] REG_WRITER_PERF_CURRENT = 10'h150;
    localparam [9:0] REG_WRITER_PERF_MAX = 10'h154;
    localparam [9:0] REG_WRITER_PERF_AW_STALL = 10'h158;
    localparam [9:0] REG_WRITER_PERF_W_STALL = 10'h15c;
    localparam [9:0] REG_WRITER_PERF_B_STALL = 10'h160;
    localparam [9:0] REG_WRITER_PERF_ISSUED = 10'h164;
    localparam [9:0] REG_WRITER_PERF_COMPLETED = 10'h168;
    localparam [9:0] REG_WRITER_PERF_ERRORS = 10'h16c;
    localparam [9:0] REG_HDMI_TRANSPORT_FRAMES = 10'h170;
    localparam [9:0] REG_HDMI_TRANSPORT_MALFORMED = 10'h174;
    localparam [9:0] REG_HDMI_FRAME0 = 10'h180;
    localparam [9:0] REG_HDMI_OVERFLOW0 = 10'h1a0;
    localparam [9:0] REG_WRITER_END =
        REG_WRITER0 + 10'(CHANNELS*4);
    localparam [9:0] REG_DROP_END = REG_DROP0 + 10'(CHANNELS*4);
    localparam [9:0] REG_MALFORMED_END =
        REG_MALFORMED0 + 10'(CHANNELS*4);
    localparam [9:0] REG_HDMI_FRAME_END = REG_HDMI_FRAME0 + 8*4;
    localparam [9:0] REG_HDMI_OVERFLOW_END = REG_HDMI_OVERFLOW0 + 8*4;

    initial begin
        if (CHANNELS > 16 || REG_WRITER_END > REG_DROP0 ||
            REG_DROP_END > REG_MALFORMED0 ||
            REG_MALFORMED_END > REG_READER_COUNT)
            $error("telemetry_csr channel register ranges overlap");
    end

    always @* begin
        read_hit = 1'b1;
        case (read_addr)
            REG_READER_COUNT: read_data = reader_frame_count;
            REG_UNDERFLOW: read_data = underflow_count;
            REG_READER_BASE: read_data = reader_active_base;
            REG_READER_DEBUG: read_data = reader_debug_status;
            REG_WRITER_PERF_CURRENT:
                read_data = writer_perf_outstanding_current;
            REG_WRITER_PERF_MAX: read_data = writer_perf_outstanding_max;
            REG_WRITER_PERF_AW_STALL:
                read_data = writer_perf_aw_stall_cycles;
            REG_WRITER_PERF_W_STALL:
                read_data = writer_perf_w_stall_cycles;
            REG_WRITER_PERF_B_STALL:
                read_data = writer_perf_b_stall_cycles;
            REG_WRITER_PERF_ISSUED: read_data = writer_perf_bursts_issued;
            REG_WRITER_PERF_COMPLETED:
                read_data = writer_perf_bursts_completed;
            REG_WRITER_PERF_ERRORS: read_data = writer_perf_response_errors;
            REG_HDMI_TRANSPORT_FRAMES:
                read_data = hdmi_transport_frame_count;
            REG_HDMI_TRANSPORT_MALFORMED:
                read_data = hdmi_transport_malformed_count;
            default: begin
                if (read_addr >= REG_WRITER0 &&
                    read_addr < REG_WRITER_END)
                    read_data = writer_frame_counts[
                        ((read_addr-REG_WRITER0)>>2)*32 +: 32];
                else if (read_addr >= REG_DROP0 &&
                         read_addr < REG_DROP_END)
                    read_data = drop_counts[
                        ((read_addr-REG_DROP0)>>2)*32 +: 32];
                else if (read_addr >= REG_MALFORMED0 &&
                         read_addr < REG_MALFORMED_END)
                    read_data = malformed_counts[
                        ((read_addr-REG_MALFORMED0)>>2)*32 +: 32];
                else if (read_addr >= REG_HDMI_FRAME0 &&
                         read_addr < REG_HDMI_FRAME_END)
                    read_data = hdmi_channel_frame_counts[
                        ((read_addr-REG_HDMI_FRAME0)>>2)*32 +: 32];
                else if (read_addr >= REG_HDMI_OVERFLOW0 &&
                         read_addr < REG_HDMI_OVERFLOW_END)
                    read_data = hdmi_channel_overflow_counts[
                        ((read_addr-REG_HDMI_OVERFLOW0)>>2)*32 +: 32];
                else begin
                    read_hit = 1'b0;
                    read_data = 32'd0;
                end
            end
        endcase
    end
endmodule
