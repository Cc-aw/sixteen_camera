# Canonical, hand-written production RTL.  Entries are repository-relative so
# this manifest is usable from both the checked-in Vivado project and clean CI
# workspaces.  Generated SoC collateral and Xilinx IP are registered by their
# dedicated setup phases and deliberately do not appear here.
set RTL_SOURCES {
    hw/rtl/common/pkg/system_cfg_pkg.sv
    hw/rtl/common/pkg/video_types_pkg.sv
    hw/rtl/common/pkg/frame_types_pkg.sv
    hw/rtl/common/pkg/ai_types_pkg.sv
    hw/rtl/common/cdc/cdc_toggle_handshake.sv
    hw/rtl/common/cdc/cdc_mailbox.sv
    hw/rtl/common/cdc/cdc_snapshot.sv

    hw/rtl/interfaces/axi4_if.sv
    hw/rtl/interfaces/axi_lite_if.sv
    hw/rtl/interfaces/axis_video_if.sv
    hw/rtl/interfaces/video_stream_if.sv

    hw/rtl/bus/axi4_channel_join.sv
    hw/rtl/bus/axi4_ui_read_cdc.sv
    hw/rtl/bus/axi4_ui_write_cdc.sv
    hw/rtl/bus/axi4_write_cdc.sv
    hw/rtl/bus/cdc_payload_fifo.sv
    hw/rtl/bus/video_mmio_fabric.sv
    hw/rtl/bus/video_peripheral_fabric.sv

    hw/rtl/control/control_soc_subsystem.sv
    hw/rtl/control/csr/video_csr.sv
    hw/rtl/control/csr/frame_csr.sv
    hw/rtl/control/csr/tensor_csr.sv
    hw/rtl/control/csr/overlay_csr.sv
    hw/rtl/control/csr/telemetry_csr.sv
    hw/rtl/control/telemetry/tensor_telemetry_cdc.sv
    hw/rtl/memory/ddr_platform.sv
    hw/rtl/memory/video_memory_ports.sv
    hw/rtl/memory/tensor_memory_bridge.sv
    hw/rtl/memory/tensor_coherent_write_cdc.sv
    hw/rtl/memory/postprocess_memory_bridge.sv
    hw/rtl/memory/ddr_memory_subsystem.sv

    hw/rtl/si5338/i2c_master.vhd
    hw/rtl/si5338/si5338.vhd
    hw/rtl/si5338/si5338_1.mif
    hw/rtl/si5338/si5338_2.mif
    hw/rtl/si5338/si5338top.v

    hw/rtl/video/camera/camera_axis_cdc.sv
    hw/rtl/video/camera/camera_axis_to_stream.sv
    hw/rtl/video/camera/camera_channel.sv
    hw/rtl/video/camera/camera_clocking.sv
    hw/rtl/video/camera/camera_pixel_assembler.sv
    hw/rtl/video/camera/camera_subsystem.sv
    hw/rtl/video/camera/camera_telemetry.sv
    hw/rtl/video/camera/dvp_event_bridge.sv
    hw/rtl/video/camera/dvp_href_line_guard.sv
    hw/rtl/video/camera/dvp_input_sampler.sv
    hw/rtl/video/camera/dvp_pclk_recovery.sv
    hw/rtl/video/camera/dvp_pclk_telemetry.sv
    hw/rtl/video/camera/control/ov7670_init_ctrl.sv
    hw/rtl/video/camera/control/ov7670_regs.sv
    hw/rtl/video/camera/ov7670_frontend.sv
    hw/rtl/video/camera/ov7670_init_scheduler.sv
    hw/rtl/video/camera/video_stream_cdc.sv
    hw/rtl/video/camera_hdmi_subsystem.sv

    hw/rtl/video/framebuffer/channel_write_fifo.sv
    hw/rtl/video/framebuffer/ddr_frame_reader.sv
    hw/rtl/video/framebuffer/display_reader_subsystem.sv
    hw/rtl/video/framebuffer/mosaic_frame_reader.sv
    hw/rtl/video/framebuffer/multi_channel_ddr_video_pipeline.sv
    hw/rtl/video/framebuffer/multi_channel_frame_manager.sv
    hw/rtl/video/framebuffer/multi_channel_framebuffer_ctrl.sv
    hw/rtl/video/framebuffer/multi_channel_video_dma.sv
    hw/rtl/video/frame_store/frame_store_subsystem.sv
    hw/rtl/video/frame_store/capture_ingress_bridge.sv
    hw/rtl/video/display/rgb888_to_rgb565.sv
    hw/rtl/video/display/rgb565_to_rgb888.sv
    hw/rtl/video/display/display_scaler.sv
    hw/rtl/video/display/display_frame_packer.sv
    hw/rtl/video/display/full_rgb565_reader.sv
    hw/rtl/video/display/mosaic_rgb565_reader.sv
    hw/rtl/video/display/display_subsystem.sv

    hw/rtl/video/hdmi/hdmi_4k_spatial_demux.sv
    hw/rtl/video/hdmi/hdmi_phy_subsystem.sv
    hw/rtl/video/hdmi/hdmi_rx_subsystem.sv
    hw/rtl/video/hdmi/hdmi_subsystem.sv
    hw/rtl/video/hdmi/hdmi_tx_subsystem.sv
    hw/rtl/video/overlay/detection_overlay.sv
    hw/rtl/video/video_control_subsystem.sv
    hw/rtl/video/video_control_bridge.sv

    hw/rtl/ai/preprocess/yolov5nu_multi_channel_tensor_dma.sv
    hw/rtl/ai/preprocess/yolov5nu_tensor_stream_packer.sv
    hw/rtl/ai/tensor/tensor_ingress_subsystem.sv
    hw/rtl/ai/postprocess/axi4_head_uram_router.sv
    hw/rtl/ai/postprocess/fbus_read_engine.sv
    hw/rtl/ai/postprocess/head_local_reader.sv
    hw/rtl/ai/postprocess/head_uram_store.sv
    hw/rtl/ai/postprocess/ppu_descriptor_fifo.sv
    hw/rtl/ai/postprocess/ppu_command_queue.sv
    hw/rtl/ai/postprocess/ppu_result_capture.sv
    hw/rtl/ai/postprocess/ppu_result_fifo.sv
    hw/rtl/ai/postprocess/ppu_overlay_label.sv
    hw/rtl/ai/postprocess/ppu_result_manager.sv
    hw/rtl/ai/postprocess/ppu_result_csr.sv
    hw/rtl/ai/postprocess/ppu_result_path.sv
    hw/rtl/ai/postprocess/ppu_queue_csr.sv
    hw/rtl/ai/postprocess/ppu_publication_csr.sv
    hw/rtl/ai/postprocess/ppu_publication_gate.sv
    hw/rtl/ai/postprocess/head_publication_manager.sv
    hw/rtl/ai/postprocess/ppu_cache_publish_engine.sv
    hw/rtl/ai/postprocess/ppu_publication_write_mux.sv
    hw/rtl/ai/postprocess/postprocess_read_diagnostic.sv
    hw/rtl/ai/postprocess/yolov5nu_bbox_decoder.sv
    hw/rtl/ai/postprocess/yolov5nu_class_fold_tree.sv
    hw/rtl/ai/postprocess/yolov5nu_class_reducer_wide.sv
    hw/rtl/ai/postprocess/yolov5nu_class_reducer.sv
    hw/rtl/ai/postprocess/yolov5nu_probability_pipeline.sv
    hw/rtl/ai/postprocess/yolov5nu_dfl_edge.sv
    hw/rtl/ai/postprocess/yolov5nu_dfl_decoder.sv
    hw/rtl/ai/postprocess/yolov5nu_dfl_lut.sv
    hw/rtl/ai/postprocess/ppu_perf_counters.sv
    hw/rtl/ai/postprocess/yolov5nu_candidate_buckets.sv
    hw/rtl/ai/postprocess/yolov5nu_nms.sv
    hw/rtl/ai/postprocess/yolov5nu_candidate_area.sv
    hw/rtl/ai/postprocess/yolov5nu_iou_pipeline.sv
    hw/rtl/ai/postprocess/yolov5nu_bucket_nms.sv
    hw/rtl/ai/postprocess/yolov5nu_bbox_lut.sv
    hw/rtl/ai/postprocess/yolov5nu_bbox_pipeline.sv
    hw/rtl/ai/postprocess/yolov5nu_postprocessor.sv
    hw/rtl/ai/postprocess/yolov5nu_raw_class_lut.sv
    hw/rtl/ai/postprocess/yolov5nu_topk_nms.sv

    hw/rtl/top_wrapper.sv
}
