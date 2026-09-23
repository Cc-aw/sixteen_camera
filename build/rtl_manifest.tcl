# Canonical, hand-written production RTL.  Entries are repository-relative so
# this manifest is usable from both the checked-in Vivado project and clean CI
# workspaces.  Generated SoC collateral and Xilinx IP are registered by their
# dedicated setup phases and deliberately do not appear here.
set RTL_SOURCES {
    rtl/common/pkg/system_cfg_pkg.sv
    rtl/common/pkg/video_types_pkg.sv
    rtl/common/pkg/frame_types_pkg.sv
    rtl/common/pkg/ai_types_pkg.sv
    rtl/common/cdc/cdc_toggle_handshake.sv
    rtl/common/cdc/cdc_mailbox.sv
    rtl/common/cdc/cdc_snapshot.sv

    rtl/interfaces/axi4_if.sv
    rtl/interfaces/axi_lite_if.sv
    rtl/interfaces/axis_video_if.sv
    rtl/interfaces/video_stream_if.sv

    rtl/bus/axi4_channel_join.sv
    rtl/bus/axi4_ui_read_cdc.sv
    rtl/bus/axi4_ui_write_cdc.sv
    rtl/bus/axi4_write_cdc.sv
    rtl/bus/cdc_payload_fifo.sv
    rtl/bus/video_mmio_fabric.sv
    rtl/bus/video_peripheral_fabric.sv

    rtl/control/control_soc_subsystem.sv
    rtl/control/csr/video_csr.sv
    rtl/control/csr/frame_csr.sv
    rtl/control/csr/tensor_csr.sv
    rtl/control/csr/overlay_csr.sv
    rtl/control/csr/telemetry_csr.sv
    rtl/control/telemetry/tensor_telemetry_cdc.sv
    rtl/memory/ddr_platform.sv
    rtl/memory/video_memory_ports.sv
    rtl/memory/tensor_memory_bridge.sv
    rtl/memory/postprocess_memory_bridge.sv
    rtl/memory/ddr_memory_subsystem.sv

    rtl/si5338/i2c_master.vhd
    rtl/si5338/si5338.vhd
    rtl/si5338/si5338_1.mif
    rtl/si5338/si5338_2.mif
    rtl/si5338/si5338top.v

    rtl/video/camera/camera_axis_cdc.sv
    rtl/video/camera/camera_axis_to_stream.sv
    rtl/video/camera/camera_channel.sv
    rtl/video/camera/camera_clocking.sv
    rtl/video/camera/camera_pixel_assembler.sv
    rtl/video/camera/camera_subsystem.sv
    rtl/video/camera/camera_telemetry.sv
    rtl/video/camera/dvp_event_bridge.sv
    rtl/video/camera/dvp_href_line_guard.sv
    rtl/video/camera/dvp_input_sampler.sv
    rtl/video/camera/dvp_pclk_recovery.sv
    rtl/video/camera/control/ov7670_init_ctrl.sv
    rtl/video/camera/control/ov7670_regs.sv
    rtl/video/camera/ov7670_frontend.sv
    rtl/video/camera/ov7670_init_scheduler.sv
    rtl/video/camera/video_stream_cdc.sv
    rtl/video/camera_hdmi_subsystem.sv

    rtl/video/framebuffer/channel_write_fifo.sv
    rtl/video/framebuffer/ddr_frame_reader.sv
    rtl/video/framebuffer/display_reader_subsystem.sv
    rtl/video/framebuffer/mosaic_frame_reader.sv
    rtl/video/framebuffer/multi_channel_ddr_video_pipeline.sv
    rtl/video/framebuffer/multi_channel_frame_manager.sv
    rtl/video/framebuffer/multi_channel_framebuffer_ctrl.sv
    rtl/video/framebuffer/multi_channel_video_dma.sv
    rtl/video/frame_store/frame_store_subsystem.sv
    rtl/video/frame_store/capture_ingress_bridge.sv
    rtl/video/display/display_subsystem.sv

    rtl/video/hdmi/hdmi_4k_spatial_demux.sv
    rtl/video/hdmi/hdmi_phy_subsystem.sv
    rtl/video/hdmi/hdmi_rx_subsystem.sv
    rtl/video/hdmi/hdmi_subsystem.sv
    rtl/video/hdmi/hdmi_tx_subsystem.sv
    rtl/video/overlay/detection_overlay.sv
    rtl/video/video_control_subsystem.sv
    rtl/video/video_control_bridge.sv

    rtl/ai/preprocess/yolov5nu_multi_channel_tensor_dma.sv
    rtl/ai/preprocess/yolov5nu_tensor_stream_packer.sv
    rtl/ai/tensor/tensor_ingress_subsystem.sv
    rtl/ai/postprocess/axi4_head_uram_router.sv
    rtl/ai/postprocess/fbus_read_engine.sv
    rtl/ai/postprocess/head_local_reader.sv
    rtl/ai/postprocess/head_uram_store.sv
    rtl/ai/postprocess/postprocess_read_diagnostic.sv
    rtl/ai/postprocess/yolov5nu_bbox_decoder.sv
    rtl/ai/postprocess/yolov5nu_class_reducer.sv
    rtl/ai/postprocess/yolov5nu_dfl_decoder.sv
    rtl/ai/postprocess/yolov5nu_dfl_lut.sv
    rtl/ai/postprocess/yolov5nu_postprocessor.sv
    rtl/ai/postprocess/yolov5nu_raw_class_lut.sv
    rtl/ai/postprocess/yolov5nu_topk_nms.sv

    rtl/top_wrapper.sv
}
