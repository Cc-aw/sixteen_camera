`timescale 1ns/1ps

// Complete eight-channel OV7670 ingress subsystem. Physical DVP capture,
// serialized sensor initialization, CDC buffering and stream conversion live
// below this boundary; the parent only connects control and video fabrics.
module camera_subsystem (
    input wire sys_rstn,
    input wire camera_ref_clk,
    input wire capture_clk,
    input wire capture_resetn,
    input wire video_clk,
    input wire video_resetn,
    axi_lite_if.slave camera_axil [8],
    video_stream_if.source capture_channels [8],

    output wire [7:0] cam_rst_n,
    output wire [7:0] cam_pwdn,
    output wire [7:0] cam_scl,
    inout  wire [7:0] cam_sda,
    output wire [7:0] cam_xclk,
    input  wire [7:0] cam_pclk,
    input  wire [7:0] cam_vsync,
    input  wire [7:0] cam_href,
    input  wire [63:0] cam_data,

    output wire camera_pll_locked,
    output wire [255:0] malformed_counts
);
    localparam integer CAMERA_COUNT = 8;

    axis_video_if #(.DATA_WIDTH(48)) camera_axis_from_cdc [CAMERA_COUNT]();
    wire ov7670_ctrl_clk;
    wire [7:0] camera_pixel_valid;
    wire [7:0] camera_pixel_ready;
    wire [7:0][23:0] camera_pixel_data;
    wire [7:0] camera_frame_start;
    wire [7:0] camera_line_last;
    wire [7:0] camera_line_end;
    wire [7:0] camera_scl;
    tri  [7:0] camera_sda;
    wire [7:0] camera_xclk;
    wire [7:0] camera_reset_n;
    wire [7:0] camera_pwdn;
    wire [7:0] camera_enable_video;
    wire [7:0] camera_init_request;
    wire [7:0] camera_init_terminal;
    wire [7:0] camera_init_grant;
    wire [31:0] camera_malformed_count [CAMERA_COUNT];
    wire [31:0] camera_pad_error_count [CAMERA_COUNT];
    wire [31:0] camera_event_overflow_video [CAMERA_COUNT];
    wire [7:0] camera_diag_clear_toggle;

    camera_clocking u_camera_clocking (
        .sys_rstn(sys_rstn), .clk_ref(camera_ref_clk),
        .pll_locked(camera_pll_locked),
        .ov7670_ctrl_clk(ov7670_ctrl_clk)
    );

    ov7670_init_scheduler u_camera_init_scheduler (
        .clk(ov7670_ctrl_clk), .rstn(sys_rstn),
        .request(camera_init_request),
        .terminal(camera_init_terminal), .grant(camera_init_grant)
    );

    genvar camera_index;
    generate
        for (camera_index = 0; camera_index < CAMERA_COUNT;
             camera_index = camera_index + 1) begin : g_camera_frontend
            camera_channel u_channel (
                .sys_rstn(sys_rstn), .ctrl_clk(ov7670_ctrl_clk),
                .init_grant(camera_init_grant[camera_index]),
                .init_request(camera_init_request[camera_index]),
                .init_terminal(camera_init_terminal[camera_index]),
                .capture_clk(capture_clk), .capture_resetn(capture_resetn),
                .video_clk(video_clk), .video_resetn(video_resetn),
                .camera_axil(camera_axil[camera_index]),
                .cam_pclk(cam_pclk[camera_index]),
                .cam_vsync(cam_vsync[camera_index]),
                .cam_href(cam_href[camera_index]),
                .cam_data(cam_data[camera_index*8 +: 8]),
                .cam_scl(camera_scl[camera_index]),
                .cam_sda(camera_sda[camera_index]),
                .cam_xclk(camera_xclk[camera_index]),
                .cam_reset_n(camera_reset_n[camera_index]),
                .cam_pwdn(camera_pwdn[camera_index]),
                .pixel_valid(camera_pixel_valid[camera_index]),
                .pixel_ready(camera_pixel_ready[camera_index]),
                .pixel_data(camera_pixel_data[camera_index]),
                .frame_start(camera_frame_start[camera_index]),
                .line_last(camera_line_last[camera_index]),
                .line_end(camera_line_end[camera_index]),
                .camera_enable_video(camera_enable_video[camera_index]),
                .overflow_count_video(
                    camera_event_overflow_video[camera_index]),
                .diag_clear_toggle(camera_diag_clear_toggle[camera_index])
            );

            camera_axis_cdc #(
                .FRAME_WIDTH(640), .FIFO_DEPTH(16384)
            ) u_camera_cdc (
                .camera_clk(video_clk),
                .camera_resetn(video_resetn),
                .camera_enable(camera_enable_video[camera_index]),
                .pixel_valid(camera_pixel_valid[camera_index]),
                .pixel_ready(camera_pixel_ready[camera_index]),
                .pixel_data(camera_pixel_data[camera_index]),
                .frame_start(camera_frame_start[camera_index]),
                .line_last(camera_line_last[camera_index]),
                .line_end(camera_line_end[camera_index]),
                .ddr_clk(video_clk), .ddr_resetn(video_resetn),
                .m_axis(camera_axis_from_cdc[camera_index])
            );

            camera_axis_to_stream #(
                .FRAME_WIDTH(640), .FRAME_HEIGHT(480),
                .STREAM_ID(camera_index), .STREAM_ID_WIDTH(4)
            ) u_camera_stream (
                .s_axis(camera_axis_from_cdc[camera_index]),
                .m_stream(capture_channels[camera_index]),
                .diag_clear_toggle(camera_diag_clear_toggle[camera_index]),
                .malformed_frame_count(camera_malformed_count[camera_index]),
                .timeout_abort_count()
            );

            assign camera_pad_error_count[camera_index] =
                camera_event_overflow_video[camera_index];
            assign malformed_counts[camera_index*32 +: 32] =
                camera_malformed_count[camera_index] +
                camera_pad_error_count[camera_index];
            tran u_cam_sda(cam_sda[camera_index], camera_sda[camera_index]);
        end
    endgenerate

    assign cam_scl = camera_scl;
    assign cam_xclk = camera_xclk;
    assign cam_rst_n = camera_reset_n;
    assign cam_pwdn = camera_pwdn;

    wire unused = &{1'b0, camera_line_last, capture_channels[0].ready,
                    capture_channels[1].ready, capture_channels[2].ready,
                    capture_channels[3].ready, capture_channels[4].ready,
                    capture_channels[5].ready, capture_channels[6].ready,
                    capture_channels[7].ready};
endmodule
