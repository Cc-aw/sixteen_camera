`timescale 1ns/1ps

// Split the fixed 3840x2160p30, RGB888, 2-PPC transport described in
// doc/接口规范/8路640x480视频在4K30_HDMI中的空间封装规范.md into eight native
// 640x480 streams.  The HDMI input is never backpressured: if one downstream
// channel cannot accept a cropped beat, only that channel/frame is marked
// bad and the transport coordinate tracker continues to run.
module hdmi_4k_spatial_demux #(
    parameter integer OUTPUT_CHANNELS = 8,
    parameter integer GLOBAL_CHANNEL_BASE = 8
) (
    axis_video_if.sink s_axis,
    video_stream_if.source channels [OUTPUT_CHANNELS],
    input  wire capture_enable,
    output reg  [31:0] transport_frame_count,
    output reg  [31:0] transport_malformed_count,
    output reg  [OUTPUT_CHANNELS*32-1:0] channel_overflow_counts,
    output reg  [OUTPUT_CHANNELS*32-1:0] channel_frame_counts
);
    localparam [10:0] TRANSPORT_LAST_X = 11'd1919;
    localparam [11:0] TRANSPORT_LAST_Y = 12'd2159;
    localparam [8:0] IMAGE_LAST_X = 9'd319;
    localparam [8:0] IMAGE_LAST_Y = 9'd479;

    reg [10:0] transport_x;
    reg [11:0] transport_y;
    reg [31:0] transport_epoch;
    reg transport_active;
    reg transport_bad;
    reg [OUTPUT_CHANNELS-1:0] channel_bad;

    wire input_fire = s_axis.tvalid && s_axis.tready;
    wire start_beat = input_fire && s_axis.tuser;
    wire [10:0] beat_x = start_beat ? 11'd0 : transport_x;
    wire [11:0] beat_y = start_beat ? 12'd0 : transport_y;
    wire in_image_y = ((beat_y >= 12'd300) && (beat_y < 12'd780)) ||
                      ((beat_y >= 12'd1380) && (beat_y < 12'd1860));
    wire slot_row = beat_y >= 12'd1080;
    wire [1:0] slot_col = (beat_x < 11'd480) ? 2'd0 :
                          (beat_x < 11'd960) ? 2'd1 :
                          (beat_x < 11'd1440) ? 2'd2 : 2'd3;
    wire [10:0] slot_x = (slot_col == 2'd0) ? beat_x :
                         (slot_col == 2'd1) ? beat_x - 11'd480 :
                         (slot_col == 2'd2) ? beat_x - 11'd960 :
                                              beat_x - 11'd1440;
    wire in_image_x = (slot_x >= 11'd80) && (slot_x < 11'd400);
    wire crop_valid = input_fire && capture_enable &&
                      (transport_active || start_beat) &&
                      in_image_x && in_image_y;
    wire [2:0] crop_channel = {slot_row, slot_col};
    wire [8:0] source_x = slot_x[8:0] - 9'd80;
    wire [8:0] source_y = slot_row ?
        (beat_y - 12'd1380) : (beat_y - 12'd300);
    wire geometry_error = input_fire &&
        ((s_axis.tlast && (beat_x != TRANSPORT_LAST_X)) ||
         (!s_axis.tlast && (beat_x == TRANSPORT_LAST_X)));

    // The protocol RX and coordinate tracker must never be stopped by a
    // congested crop output.
    assign s_axis.tready = 1'b1;

    genvar channel_index;
    generate
        for (channel_index = 0; channel_index < OUTPUT_CHANNELS;
             channel_index = channel_index + 1) begin : g_outputs
            wire selected = crop_valid &&
                            (crop_channel == channel_index[2:0]);
            reg stage_valid;
            reg [47:0] stage_data;
            reg stage_sof;
            reg stage_eol;
            reg stage_eof;
            reg [31:0] stage_frame_id;
            reg stage_error;
            wire stage_ready = !stage_valid ||
                               channels[channel_index].ready;
            wire stage_load = selected && stage_ready;
            wire stage_overflow = selected && !stage_ready;

            assign channels[channel_index].aclk = s_axis.aclk;
            assign channels[channel_index].aresetn = s_axis.aresetn;
            // One elastic beat breaks the HDMI RX/demux path before the
            // channel packer and BRAM write enable.  It can retire the old
            // beat and accept its replacement on the same clock, preserving
            // full-rate operation.  HDMI itself remains unbackpressured.
            assign channels[channel_index].valid = stage_valid;
            assign channels[channel_index].data = stage_data;
            assign channels[channel_index].sof = stage_sof;
            assign channels[channel_index].eol = stage_eol;
            assign channels[channel_index].eof = stage_eof;
            assign channels[channel_index].stream_id =
                4'(GLOBAL_CHANNEL_BASE + channel_index);
            assign channels[channel_index].frame_id = stage_frame_id;
            assign channels[channel_index].error =
                stage_error || channel_bad[channel_index];

            always @(posedge s_axis.aclk) begin
                if (!s_axis.aresetn) begin
                    stage_valid <= 1'b0;
                    stage_data <= 48'd0;
                    stage_sof <= 1'b0;
                    stage_eol <= 1'b0;
                    stage_eof <= 1'b0;
                    stage_frame_id <= 32'd0;
                    stage_error <= 1'b0;
                    channel_bad[channel_index] <= 1'b0;
                    channel_overflow_counts[channel_index*32 +: 32] <= 32'd0;
                    channel_frame_counts[channel_index*32 +: 32] <= 32'd0;
                end else begin
                    if (stage_ready) begin
                        stage_valid <= selected;
                        if (selected) begin
                            stage_data <= s_axis.tdata;
                            stage_sof <= (source_x == 0) && (source_y == 0);
                            stage_eol <= (source_x == IMAGE_LAST_X);
                            stage_eof <= (source_x == IMAGE_LAST_X) &&
                                         (source_y == IMAGE_LAST_Y);
                            stage_frame_id <= transport_epoch;
                            stage_error <= geometry_error ||
                                (!start_beat &&
                                 (transport_bad ||
                                  channel_bad[channel_index]));
                        end
                    end

                    if (input_fire && (s_axis.tuser || !capture_enable))
                        channel_bad[channel_index] <= 1'b0;
                    if (stage_overflow) begin
                        channel_bad[channel_index] <= 1'b1;
                        channel_overflow_counts[channel_index*32 +: 32] <=
                            channel_overflow_counts[
                                channel_index*32 +: 32] + 1'b1;
                    end
                    if (stage_load &&
                        (source_x == IMAGE_LAST_X) &&
                        (source_y == IMAGE_LAST_Y))
                        channel_frame_counts[channel_index*32 +: 32] <=
                            channel_frame_counts[
                                channel_index*32 +: 32] + 1'b1;
                end
            end
        end
    endgenerate

    always @(posedge s_axis.aclk) begin
        if (!s_axis.aresetn) begin
            transport_x <= 11'd0;
            transport_y <= 12'd0;
            transport_epoch <= 32'd0;
            transport_active <= 1'b0;
            transport_bad <= 1'b0;
            transport_frame_count <= 32'd0;
            transport_malformed_count <= 32'd0;
        end else if (input_fire) begin
            if (s_axis.tuser) begin
                if (transport_active &&
                    ((transport_x != 0) || (transport_y != 0)))
                    transport_malformed_count <=
                        transport_malformed_count + 1'b1;
                transport_x <= 11'd0;
                transport_y <= 12'd0;
                transport_epoch <= transport_epoch + 1'b1;
                transport_active <= capture_enable;
                transport_bad <= 1'b0;
            end

            if (geometry_error)
                transport_bad <= 1'b1;

            if (s_axis.tlast) begin
                transport_x <= 11'd0;
                if (beat_y == TRANSPORT_LAST_Y) begin
                    transport_y <= 12'd0;
                    transport_active <= 1'b0;
                    transport_frame_count <= transport_frame_count + 1'b1;
                    if (transport_bad || geometry_error)
                        transport_malformed_count <=
                            transport_malformed_count + 1'b1;
                end else begin
                    transport_y <= beat_y + 1'b1;
                end
            end else begin
                transport_x <= beat_x + 1'b1;
            end

            if (!capture_enable) begin
                transport_active <= 1'b0;
            end
        end
    end

    initial begin
        if (OUTPUT_CHANNELS != 8 || GLOBAL_CHANNEL_BASE != 8)
            $error("hdmi_4k_spatial_demux implements fixed CH8-CH15 mapping");
    end
endmodule
