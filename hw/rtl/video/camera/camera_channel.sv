`timescale 1ns/1ps

// One complete camera ingress channel.  The subsystem above this boundary
// deals only in initialized sensor pins and video-domain pixels; capture
// recovery, event CDC and RGB565 assembly remain local to the channel.
module camera_channel #(
    parameter integer EVENT_FIFO_DEPTH = 1024
) (
    input  wire        sys_rstn,
    input  wire        ctrl_clk,
    input  wire        init_grant,
    output wire        init_request,
    output wire        init_terminal,
    input  wire        capture_clk,
    input  wire        capture_resetn,
    input  wire        video_clk,
    input  wire        video_resetn,
    axi_lite_if.slave  camera_axil,

    input  wire        cam_pclk,
    input  wire        cam_vsync,
    input  wire        cam_href,
    input  wire [7:0]  cam_data,
    output wire        cam_scl,
    inout  wire        cam_sda,
    output wire        cam_xclk,
    output wire        cam_reset_n,
    output wire        cam_pwdn,

    output wire        pixel_valid,
    input  wire        pixel_ready,
    output wire [23:0] pixel_data,
    output wire        frame_start,
    output wire        line_last,
    output wire        line_end,
    output wire        camera_enable_video,
    output wire [31:0] overflow_count_video,
    output wire        diag_clear_toggle
);
    (* ASYNC_REG = "TRUE", SHREG_EXTRACT = "NO" *)
    reg [1:0] capture_resetn_sync = 2'b00;
    (* ASYNC_REG = "TRUE", SHREG_EXTRACT = "NO" *)
    reg [1:0] camera_enable_sync = 2'b00;
    wire capture_resetn_local = capture_resetn_sync[1];
    wire camera_enable_capture;
    wire pixel_resetn_unused;

    wire capture_event_valid;
    wire capture_event_ready;
    wire [7:0] capture_event_data;
    wire capture_event_byte_valid;
    wire capture_event_line_start;
    wire capture_event_line_last;
    wire capture_event_line_end;
    wire capture_event_frame_boundary;
    wire capture_event_fault;
    wire video_event_valid;
    wire video_event_ready;
    wire [7:0] video_event_data;
    wire video_event_byte_valid;
    wire video_event_line_start;
    wire video_event_line_last;
    wire video_event_line_end;
    wire video_event_frame_boundary;
    wire video_event_resync;
    wire video_event_fault_pulse;
    wire [31:0] overflow_count_capture;

    always @(posedge capture_clk or negedge capture_resetn) begin
        if (!capture_resetn)
            capture_resetn_sync <= 2'b00;
        else
            capture_resetn_sync <= {capture_resetn_sync[0], 1'b1};
    end

    always @(posedge video_clk) begin
        if (!video_resetn)
            camera_enable_sync <= 2'b00;
        else
            camera_enable_sync <= {camera_enable_sync[0],
                                   camera_enable_capture};
    end
    assign camera_enable_video = camera_enable_sync[1];

    ov7670_frontend #(
        .VSYNC_FILTER_CYCLES(256),
        .HREF_FILTER_CYCLES(16),
        .MIN_FRAME_LINES(470),
        .MIN_FRAME_INTERVAL_CYCLES(200000),
        .FRAME_RESYNC_TIMEOUT_CYCLES(2000000)
    ) u_frontend (
        .sys_rstn(sys_rstn), .ov7670_ctrl_clk(ctrl_clk),
        .init_grant(init_grant), .init_request(init_request),
        .init_terminal(init_terminal),
        .video_clk(capture_clk), .video_resetn(capture_resetn_local),
        .camera_axil(camera_axil),
        .ov7670_pclk(cam_pclk), .ov7670_vsync(cam_vsync),
        .ov7670_href(cam_href), .ov7670_data(cam_data),
        .cam_scl(cam_scl), .cam_sda(cam_sda), .cam_xclk(cam_xclk),
        .cam_reset_n(cam_reset_n), .cam_pwdn(cam_pwdn),
        .event_valid(capture_event_valid),
        .event_ready(capture_event_ready),
        .diag_clear_toggle(diag_clear_toggle),
        .event_data(capture_event_data),
        .event_byte_valid(capture_event_byte_valid),
        .event_line_start(capture_event_line_start),
        .event_line_last(capture_event_line_last),
        .event_line_end(capture_event_line_end),
        .event_frame_boundary(capture_event_frame_boundary),
        .event_fault(capture_event_fault),
        .pixel_resetn(pixel_resetn_unused),
        .pixel_enable(camera_enable_capture)
    );

    dvp_event_bridge #(.FIFO_DEPTH(EVENT_FIFO_DEPTH)) u_event_bridge (
        .capture_clk(capture_clk), .capture_resetn(capture_resetn_local),
        .capture_enable(camera_enable_capture),
        .event_valid(capture_event_valid), .event_ready(capture_event_ready),
        .event_data(capture_event_data),
        .event_byte_valid(capture_event_byte_valid),
        .event_line_start(capture_event_line_start),
        .event_line_last(capture_event_line_last),
        .event_line_end(capture_event_line_end),
        .event_frame_boundary(capture_event_frame_boundary),
        .event_fault(capture_event_fault),
        .video_clk(video_clk), .video_resetn(video_resetn),
        .video_event_valid(video_event_valid),
        .video_event_ready(video_event_ready),
        .video_event_data(video_event_data),
        .video_byte_valid(video_event_byte_valid),
        .video_line_start(video_event_line_start),
        .video_line_last(video_event_line_last),
        .video_line_end(video_event_line_end),
        .video_frame_boundary(video_event_frame_boundary),
        .video_resync(video_event_resync),
        .video_fault_pulse(video_event_fault_pulse),
        .overflow_count(overflow_count_capture)
    );

    camera_pixel_assembler u_pixel_assembler (
        .video_clk(video_clk), .video_resetn(video_resetn),
        .camera_enable(camera_enable_video),
        .event_valid(video_event_valid), .event_ready(video_event_ready),
        .event_data(video_event_data),
        .event_byte_valid(video_event_byte_valid),
        .event_line_start(video_event_line_start),
        .event_line_last(video_event_line_last),
        .event_line_end(video_event_line_end),
        .event_frame_boundary(video_event_frame_boundary),
        .event_resync(video_event_resync),
        .fault_pulse(video_event_fault_pulse),
        .pixel_valid(pixel_valid), .pixel_ready(pixel_ready),
        .pixel_data(pixel_data), .frame_start(frame_start),
        .line_last(line_last), .line_end(line_end)
    );

    // This compatibility counter will move into the indexed subsystem
    // telemetry stream with the CSR stage.  Keeping it here prevents a wide
    // capture-domain diagnostic bus from leaking through camera_subsystem.
    xpm_cdc_array_single #(
        .DEST_SYNC_FF(2), .INIT_SYNC_FF(0), .SIM_ASSERT_CHK(0),
        .SRC_INPUT_REG(1), .WIDTH(32)
    ) u_overflow_count_cdc (
        .src_clk(capture_clk), .src_in(overflow_count_capture),
        .dest_clk(video_clk), .dest_out(overflow_count_video)
    );
endmodule
