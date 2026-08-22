`timescale 1ns/1ps

// DDR UI-domain capture/display pipeline.  HDMI-specific IP remains outside
// this module; only AXIS video, AXI DDR ports and the CPU register bank cross
// its boundary.
module ddr_video_framebuffer_pipeline (
    input  wire          init_done,
    input  wire          ddr_ui_clk,
    input  wire          ddr_resetn,
    axi_lite_if.slave    control_axil,
    axis_video_if.sink   capture_axis,
    input wire [479:0]   camera_axis_diag,
    axi4_if.master       writer_axi,
    axi4_if.master       reader_axi,
    axis_video_if.source display_axis,
    output wire          writer_error,
    output wire          reader_error,
    output wire          reader_underflow
);
    wire cfg_request_toggle;
    wire cfg_ack_toggle;
    wire cfg_enable;
    wire [31:0] cfg_width;
    wire [31:0] cfg_height;
    wire [31:0] cfg_stride_bytes;
    wire [31:0] cfg_buffer_count;
    wire [127:0] cfg_buffer_bases;
    wire [31:0] active_width;
    wire [31:0] active_height;
    wire [31:0] active_stride_bytes;
    wire [31:0] writer_frame_count;
    wire [31:0] reader_frame_count;
    wire [31:0] drop_count;
    wire [31:0] underflow_count;
    wire [31:0] manager_status;
    wire [31:0] writer_frame_count_cpu;
    wire [31:0] reader_frame_count_cpu;
    wire [31:0] drop_count_cpu;
    wire [31:0] underflow_count_cpu;
    wire [31:0] manager_status_cpu;
    wire [31:0] reader_active_base;
    wire [31:0] reader_debug_status;
    wire [31:0] reader_active_base_cpu;
    wire [31:0] reader_debug_status_cpu;
    wire [31:0] malformed_frame_count_cpu;
    wire writer_acquire;
    wire writer_grant;
    wire writer_drop;
    wire [31:0] writer_base;
    wire writer_done;
    wire reader_acquire;
    wire reader_grant;
    wire [31:0] reader_base;
    wire reader_done;
    wire [31:0] malformed_frame_count;
    wire [479:0] camera_axis_diag_cpu;

    framebuffer_ctrl u_control (
        .axil(control_axil), .cfg_request_toggle(cfg_request_toggle),
        .cfg_enable(cfg_enable), .cfg_width(cfg_width),
        .cfg_height(cfg_height), .cfg_stride_bytes(cfg_stride_bytes),
        .cfg_buffer_count(cfg_buffer_count),
        .cfg_buffer_bases(cfg_buffer_bases),
        .cfg_ack_toggle(cfg_ack_toggle), .manager_status(manager_status_cpu),
        .writer_frame_count(writer_frame_count_cpu),
        .reader_frame_count(reader_frame_count_cpu), .drop_count(drop_count_cpu),
        .underflow_count(underflow_count_cpu),
        .reader_active_base(reader_active_base_cpu),
        .reader_debug_status(reader_debug_status_cpu),
        .malformed_frame_count(malformed_frame_count_cpu),
        .camera_axis_diag(camera_axis_diag_cpu)
    );

    xpm_cdc_array_single #(
        .DEST_SYNC_FF(2), .INIT_SYNC_FF(0), .SIM_ASSERT_CHK(0),
        .SRC_INPUT_REG(1), .WIDTH(480)
    ) u_camera_diag_cpu_cdc (
        .src_clk(ddr_ui_clk), .src_in(camera_axis_diag),
        .dest_clk(control_axil.aclk), .dest_out(camera_axis_diag_cpu)
    );

    // These values are CPU diagnostics. Bitwise synchronization is sufficient:
    // software may observe either adjacent counter value while it is changing.
    xpm_cdc_array_single #(
        .DEST_SYNC_FF(2), .INIT_SYNC_FF(0), .SIM_ASSERT_CHK(0),
        .SRC_INPUT_REG(1), .WIDTH(256)
    ) u_status_cdc (
        .src_clk(ddr_ui_clk),
        .src_in({manager_status, writer_frame_count, reader_frame_count,
                 drop_count, underflow_count, reader_active_base,
                 reader_debug_status, malformed_frame_count}),
        .dest_clk(control_axil.aclk),
        .dest_out({manager_status_cpu, writer_frame_count_cpu,
                   reader_frame_count_cpu, drop_count_cpu,
                   underflow_count_cpu, reader_active_base_cpu,
                   reader_debug_status_cpu, malformed_frame_count_cpu})
    );

    frame_buffer_manager u_manager (
        .ui_clk(ddr_ui_clk), .ui_resetn(ddr_resetn && init_done),
        .cfg_request_toggle(cfg_request_toggle),
        .cfg_ack_toggle(cfg_ack_toggle), .cfg_enable(cfg_enable),
        .cfg_width(cfg_width), .cfg_height(cfg_height),
        .cfg_stride_bytes(cfg_stride_bytes),
        .cfg_buffer_count(cfg_buffer_count),
        .cfg_buffer_bases(cfg_buffer_bases),
        .writer_acquire(writer_acquire), .writer_grant(writer_grant),
        .writer_drop(writer_drop), .writer_base(writer_base),
        .writer_done(writer_done), .writer_error(writer_error),
        .reader_acquire(reader_acquire), .reader_grant(reader_grant),
        .reader_base(reader_base), .reader_done(reader_done),
        .reader_underflow(reader_underflow), .active_width(active_width),
        .active_height(active_height),
        .active_stride_bytes(active_stride_bytes),
        .writer_frame_count(writer_frame_count),
        .reader_frame_count(reader_frame_count), .drop_count(drop_count),
        .underflow_count(underflow_count), .status(manager_status)
    );

    axis_frame_writer u_writer (
        .s_axis(capture_axis), .m_axi(writer_axi),
        .buffer_acquire(writer_acquire), .buffer_grant(writer_grant),
        .buffer_drop(writer_drop), .buffer_base(writer_base),
        .buffer_done(writer_done), .buffer_error(writer_error),
        .frame_width(active_width), .frame_height(active_height),
        .frame_stride_bytes(active_stride_bytes),
        .malformed_frame_count(malformed_frame_count)
    );

    ddr_frame_reader u_reader (
        .clk(ddr_ui_clk), .resetn(ddr_resetn && init_done),
        .buffer_acquire(reader_acquire), .buffer_grant(reader_grant),
        .buffer_base(reader_base), .buffer_done(reader_done),
        .frame_width(active_width), .frame_height(active_height),
        .frame_stride_bytes(active_stride_bytes), .m_axi(reader_axi),
        .m_axis(display_axis), .axi_error(reader_error),
        .fifo_underflow(reader_underflow),
        .debug_active_base(reader_active_base),
        .debug_status(reader_debug_status)
    );

    wire unused = &{1'b0, malformed_frame_count};
endmodule
