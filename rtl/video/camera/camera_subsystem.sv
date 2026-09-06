`timescale 1ns/1ps

// Complete eight-channel OV7670 ingress subsystem. Physical DVP capture,
// serialized sensor initialization, CDC buffering and stream conversion live
// below this boundary; the parent only connects control and video fabrics.
module camera_subsystem (
    input wire sys_rstn,
    input wire sys_init_done,
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
    input  wire [7:0] cam_xclk_pad,
    input  wire [7:0] cam_rst_n_pad,
    input  wire [7:0] cam_pwdn_pad,
    input  wire [7:0] cam_scl_pad,
    input  wire [7:0] cam_pclk,
    input  wire [7:0] cam_vsync,
    input  wire [7:0] cam_href,
    input  wire [63:0] cam_data,

    output wire camera_pll_locked,
    output wire [479:0] camera_axis_diag,
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
    wire [7:0] capture_event_valid;
    wire [7:0] capture_event_ready;
    wire [7:0][7:0] capture_event_data;
    wire [7:0] capture_event_byte_valid;
    wire [7:0] capture_event_line_start;
    wire [7:0] capture_event_line_last;
    wire [7:0] capture_event_line_end;
    wire [7:0] capture_event_frame_boundary;
    wire [7:0] capture_event_fault;
    wire [7:0] video_event_valid;
    wire [7:0] video_event_ready;
    wire [7:0][7:0] video_event_data;
    wire [7:0] video_event_byte_valid;
    wire [7:0] video_event_line_start;
    wire [7:0] video_event_line_last;
    wire [7:0] video_event_line_end;
    wire [7:0] video_event_frame_boundary;
    wire [7:0] video_event_resync;
    wire [7:0] video_event_fault_pulse;
    wire [7:0] camera_scl;
    tri  [7:0] camera_sda;
    wire [7:0] camera_xclk;
    wire [7:0] camera_reset_n;
    wire [7:0] camera_pwdn;
    wire [7:0] ov7670_pixel_resetn;
    wire [7:0] ov7670_pixel_enable;
    wire [7:0] camera_init_request;
    wire [7:0] camera_init_terminal;
    wire [7:0] camera_init_grant;
    wire [7:0][383:0] camera_axis_diag_cam;
    wire [383:0] camera_axis_diag_ddr;
    wire [31:0] camera_cdc_fire_count [CAMERA_COUNT];
    wire [31:0] camera_cdc_sof_count [CAMERA_COUNT];
    wire [31:0] camera_cdc_eol_count [CAMERA_COUNT];
    wire [31:0] camera_cdc_fifo_full_stall_count [CAMERA_COUNT];
    wire [31:0] camera_cdc_ready_low_count [CAMERA_COUNT];
    wire [31:0] camera_cdc_fifo_max_level [CAMERA_COUNT];
    wire [31:0] camera_cdc_line_flush_count [CAMERA_COUNT];
    wire [31:0] camera_malformed_count [CAMERA_COUNT];
    wire [31:0] camera_timeout_abort_count [CAMERA_COUNT];
    wire [31:0] camera_pad_error_count [CAMERA_COUNT];
    wire [31:0] camera_event_overflow_count [CAMERA_COUNT];
    wire [31:0] camera_event_overflow_video [CAMERA_COUNT];
    wire [255:0] camera_stream_diag [CAMERA_COUNT];
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
            (* ASYNC_REG = "TRUE", SHREG_EXTRACT = "NO" *)
            reg [1:0] capture_resetn_local_sync = 2'b00;
            wire capture_resetn_local = capture_resetn_local_sync[1];
            (* ASYNC_REG = "TRUE", SHREG_EXTRACT = "NO" *)
            reg [1:0] pixel_enable_video_sync = 2'b00;

            always @(posedge capture_clk) begin
                capture_resetn_local_sync[0] <= capture_resetn;
                capture_resetn_local_sync[1] <= capture_resetn_local_sync[0];
            end

            always @(posedge video_clk) begin
                if (!video_resetn)
                    pixel_enable_video_sync <= 2'b00;
                else
                    pixel_enable_video_sync <=
                        {pixel_enable_video_sync[0],
                         ov7670_pixel_enable[camera_index]};
            end

            ov7670_frontend #(
                .VSYNC_FILTER_CYCLES(256),
                .HREF_FILTER_CYCLES(16),
                .MIN_FRAME_LINES(470),
                .MIN_FRAME_INTERVAL_CYCLES(200000),
                .FRAME_RESYNC_TIMEOUT_CYCLES(2000000)
            ) u_camera (
                .sys_rstn(sys_rstn), .sys_init_done(sys_init_done),
                .ov7670_ctrl_clk(ov7670_ctrl_clk),
                .init_grant(camera_init_grant[camera_index]),
                .init_request(camera_init_request[camera_index]),
                .init_terminal(camera_init_terminal[camera_index]),
                .video_clk(capture_clk), .video_resetn(capture_resetn_local),
                .pixel_clk(video_clk),
                .camera_axil(camera_axil[camera_index]),
                .ov7670_pclk(cam_pclk[camera_index]),
                .ov7670_vsync(cam_vsync[camera_index]),
                .ov7670_href(cam_href[camera_index]),
                .ov7670_data(cam_data[camera_index*8 +: 8]),
                .cam_scl(camera_scl[camera_index]),
                .cam_sda(camera_sda[camera_index]),
                .cam_xclk(camera_xclk[camera_index]),
                .cam_reset_n(camera_reset_n[camera_index]),
                .cam_pwdn(camera_pwdn[camera_index]),
                .cam_xclk_pad(cam_xclk_pad[camera_index]),
                .cam_reset_n_pad(cam_rst_n_pad[camera_index]),
                .cam_pwdn_pad(cam_pwdn_pad[camera_index]),
                .cam_scl_pad(cam_scl_pad[camera_index]),
                .event_valid(capture_event_valid[camera_index]),
                .event_ready(capture_event_ready[camera_index]),
                .diag_fifo_full_stall_count(
                    camera_cdc_fifo_full_stall_count[camera_index]),
                .diag_ready_low_count(camera_cdc_ready_low_count[camera_index]),
                .diag_fifo_max_level(camera_cdc_fifo_max_level[camera_index]),
                .diag_line_flush_count(camera_cdc_line_flush_count[camera_index]),
                .stream_diag_counts(camera_stream_diag[camera_index]),
                .stream_timeout_abort_count(
                    camera_timeout_abort_count[camera_index]),
                .diag_clear_toggle(camera_diag_clear_toggle[camera_index]),
                .event_data(capture_event_data[camera_index]),
                .event_byte_valid(capture_event_byte_valid[camera_index]),
                .event_line_start(capture_event_line_start[camera_index]),
                .event_line_last(capture_event_line_last[camera_index]),
                .event_line_end(capture_event_line_end[camera_index]),
                .event_frame_boundary(
                    capture_event_frame_boundary[camera_index]),
                .event_fault(capture_event_fault[camera_index]),
                .pixel_resetn(ov7670_pixel_resetn[camera_index]),
                .pixel_enable(ov7670_pixel_enable[camera_index]),
                .axis_diag(camera_axis_diag_cam[camera_index])
            );

            dvp_event_bridge #(.FIFO_DEPTH(1024)) u_event_bridge (
                .capture_clk(capture_clk),
                .capture_resetn(capture_resetn_local),
                .capture_enable(ov7670_pixel_enable[camera_index]),
                .event_valid(capture_event_valid[camera_index]),
                .event_ready(capture_event_ready[camera_index]),
                .event_data(capture_event_data[camera_index]),
                .event_byte_valid(capture_event_byte_valid[camera_index]),
                .event_line_start(capture_event_line_start[camera_index]),
                .event_line_last(capture_event_line_last[camera_index]),
                .event_line_end(capture_event_line_end[camera_index]),
                .event_frame_boundary(
                    capture_event_frame_boundary[camera_index]),
                .event_fault(capture_event_fault[camera_index]),
                .video_clk(video_clk), .video_resetn(video_resetn),
                .video_event_valid(video_event_valid[camera_index]),
                .video_event_ready(video_event_ready[camera_index]),
                .video_event_data(video_event_data[camera_index]),
                .video_byte_valid(video_event_byte_valid[camera_index]),
                .video_line_start(video_event_line_start[camera_index]),
                .video_line_last(video_event_line_last[camera_index]),
                .video_line_end(video_event_line_end[camera_index]),
                .video_frame_boundary(
                    video_event_frame_boundary[camera_index]),
                .video_resync(video_event_resync[camera_index]),
                .video_fault_pulse(video_event_fault_pulse[camera_index]),
                .overflow_count(camera_event_overflow_count[camera_index])
            );

            camera_pixel_assembler u_pixel_assembler (
                .video_clk(video_clk), .video_resetn(video_resetn),
                .camera_enable(pixel_enable_video_sync[1]),
                .event_valid(video_event_valid[camera_index]),
                .event_ready(video_event_ready[camera_index]),
                .event_data(video_event_data[camera_index]),
                .event_byte_valid(video_event_byte_valid[camera_index]),
                .event_line_start(video_event_line_start[camera_index]),
                .event_line_last(video_event_line_last[camera_index]),
                .event_line_end(video_event_line_end[camera_index]),
                .event_frame_boundary(
                    video_event_frame_boundary[camera_index]),
                .event_resync(video_event_resync[camera_index]),
                .fault_pulse(video_event_fault_pulse[camera_index]),
                .pixel_valid(camera_pixel_valid[camera_index]),
                .pixel_ready(camera_pixel_ready[camera_index]),
                .pixel_data(camera_pixel_data[camera_index]),
                .frame_start(camera_frame_start[camera_index]),
                .line_last(camera_line_last[camera_index]),
                .line_end(camera_line_end[camera_index])
            );

            xpm_cdc_array_single #(
                .DEST_SYNC_FF(2), .INIT_SYNC_FF(0), .SIM_ASSERT_CHK(0),
                .SRC_INPUT_REG(1), .WIDTH(32)
            ) u_event_overflow_diag_cdc (
                .src_clk(capture_clk),
                .src_in(camera_event_overflow_count[camera_index]),
                .dest_clk(video_clk),
                .dest_out(camera_event_overflow_video[camera_index])
            );

            camera_axis_cdc #(
                .FRAME_WIDTH(640), .FIFO_DEPTH(16384)
            ) u_camera_cdc (
                .camera_clk(video_clk),
                .camera_resetn(video_resetn),
                .camera_enable(pixel_enable_video_sync[1]),
                .pixel_valid(camera_pixel_valid[camera_index]),
                .pixel_ready(camera_pixel_ready[camera_index]),
                .pixel_data(camera_pixel_data[camera_index]),
                .frame_start(camera_frame_start[camera_index]),
                .line_last(camera_line_last[camera_index]),
                .line_end(camera_line_end[camera_index]),
                .diag_clear_toggle(camera_diag_clear_toggle[camera_index]),
                .diag_fifo_full_stall_count(
                    camera_cdc_fifo_full_stall_count[camera_index]),
                .diag_ready_low_count(camera_cdc_ready_low_count[camera_index]),
                .diag_fifo_max_level(camera_cdc_fifo_max_level[camera_index]),
                .diag_line_flush_count(camera_cdc_line_flush_count[camera_index]),
                .ddr_clk(video_clk), .ddr_resetn(video_resetn),
                .diag_fire_count(camera_cdc_fire_count[camera_index]),
                .diag_sof_count(camera_cdc_sof_count[camera_index]),
                .diag_eol_count(camera_cdc_eol_count[camera_index]),
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
                .diag_counts(camera_stream_diag[camera_index]),
                .timeout_abort_count(camera_timeout_abort_count[camera_index])
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

    assign camera_axis_diag_ddr = camera_axis_diag_cam[0];
    assign camera_axis_diag = {camera_cdc_eol_count[0],
                               camera_cdc_sof_count[0],
                               camera_cdc_fire_count[0],
                               camera_axis_diag_ddr};

    wire unused = &{1'b0, camera_line_last, capture_channels[0].ready,
                    capture_channels[1].ready, capture_channels[2].ready,
                    capture_channels[3].ready, capture_channels[4].ready,
                    capture_channels[5].ready, capture_channels[6].ready,
                    capture_channels[7].ready};
endmodule
