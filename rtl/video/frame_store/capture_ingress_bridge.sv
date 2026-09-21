`timescale 1ns/1ps

// Normalize camera and HDMI ingress into one 16-channel video-domain array.
// HDMI transport telemetry crosses with the ingress because it belongs to the
// video control plane, not to the DDR platform.
module capture_ingress_bridge (
    input wire capture_clk,
    input wire capture_resetn,
    input wire video_clk,
    input wire video_resetn,
    video_stream_if.sink camera_channels [8],
    video_stream_if.sink hdmi_channels [8],
    video_stream_if.source capture_channels [16],
    input wire [255:0] camera_malformed_counts,
    input wire [31:0] hdmi_transport_frame_count,
    input wire [31:0] hdmi_transport_malformed_count,
    input wire [255:0] hdmi_channel_overflow_counts,
    input wire [255:0] hdmi_channel_frame_counts,
    output wire [511:0] malformed_counts_video,
    output wire [31:0] hdmi_transport_frame_count_video,
    output wire [31:0] hdmi_transport_malformed_count_video,
    output wire [255:0] hdmi_channel_frame_counts_video,
    input wire hdmi_capture_enable_video,
    output wire hdmi_capture_enable
);
    video_stream_if #(.DATA_WIDTH(48), .STREAM_ID_WIDTH(4))
        hdmi_video_channels [8]();
    wire [575:0] hdmi_stats_capture = {
        hdmi_transport_frame_count, hdmi_transport_malformed_count,
        hdmi_channel_frame_counts, hdmi_channel_overflow_counts
    };
    wire [575:0] hdmi_stats_video;
    wire [255:0] hdmi_channel_overflow_counts_video =
        hdmi_stats_video[255:0];
    (* ASYNC_REG = "TRUE", SHREG_EXTRACT = "NO" *)
    reg [1:0] hdmi_capture_enable_sync = 2'b00;

    assign hdmi_transport_frame_count_video = hdmi_stats_video[575:544];
    assign hdmi_transport_malformed_count_video = hdmi_stats_video[543:512];
    assign hdmi_channel_frame_counts_video = hdmi_stats_video[511:256];
    assign malformed_counts_video = {
        hdmi_channel_overflow_counts_video, camera_malformed_counts
    };

    xpm_cdc_array_single #(
        .DEST_SYNC_FF(2), .INIT_SYNC_FF(0), .SIM_ASSERT_CHK(0),
        .SRC_INPUT_REG(1), .WIDTH(576)
    ) u_hdmi_stats_to_video (
        .src_clk(capture_clk), .src_in(hdmi_stats_capture),
        .dest_clk(video_clk), .dest_out(hdmi_stats_video)
    );

    always @(posedge capture_clk) begin
        if (!capture_resetn)
            hdmi_capture_enable_sync <= 2'b00;
        else
            hdmi_capture_enable_sync <= {
                hdmi_capture_enable_sync[0], hdmi_capture_enable_video};
    end
    assign hdmi_capture_enable = hdmi_capture_enable_sync[1];

    genvar channel_index;
    generate
        for (channel_index = 0; channel_index < 8;
             channel_index = channel_index + 1) begin : g_channel
            assign capture_channels[channel_index].aclk =
                camera_channels[channel_index].aclk;
            assign capture_channels[channel_index].aresetn =
                camera_channels[channel_index].aresetn;
            assign capture_channels[channel_index].data =
                camera_channels[channel_index].data;
            assign capture_channels[channel_index].valid =
                camera_channels[channel_index].valid;
            assign capture_channels[channel_index].sof =
                camera_channels[channel_index].sof;
            assign capture_channels[channel_index].eol =
                camera_channels[channel_index].eol;
            assign capture_channels[channel_index].eof =
                camera_channels[channel_index].eof;
            assign capture_channels[channel_index].stream_id =
                camera_channels[channel_index].stream_id;
            assign capture_channels[channel_index].frame_id =
                camera_channels[channel_index].frame_id;
            assign capture_channels[channel_index].error =
                camera_channels[channel_index].error;
            assign camera_channels[channel_index].ready =
                capture_channels[channel_index].ready;

            video_stream_cdc #(.FIFO_DEPTH(1024)) u_hdmi_stream_cdc (
                .s_stream(hdmi_channels[channel_index]),
                .m_clk(video_clk), .m_resetn(video_resetn),
                .m_stream(hdmi_video_channels[channel_index])
            );

            assign capture_channels[channel_index+8].aclk =
                hdmi_video_channels[channel_index].aclk;
            assign capture_channels[channel_index+8].aresetn =
                hdmi_video_channels[channel_index].aresetn;
            assign capture_channels[channel_index+8].data =
                hdmi_video_channels[channel_index].data;
            assign capture_channels[channel_index+8].valid =
                hdmi_video_channels[channel_index].valid;
            assign capture_channels[channel_index+8].sof =
                hdmi_video_channels[channel_index].sof;
            assign capture_channels[channel_index+8].eol =
                hdmi_video_channels[channel_index].eol;
            assign capture_channels[channel_index+8].eof =
                hdmi_video_channels[channel_index].eof;
            assign capture_channels[channel_index+8].stream_id =
                hdmi_video_channels[channel_index].stream_id;
            assign capture_channels[channel_index+8].frame_id =
                hdmi_video_channels[channel_index].frame_id;
            assign capture_channels[channel_index+8].error =
                hdmi_video_channels[channel_index].error;
            assign hdmi_video_channels[channel_index].ready =
                capture_channels[channel_index+8].ready;
        end
    endgenerate
endmodule
