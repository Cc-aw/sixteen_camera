`timescale 1ns/1ps

module ddr_memory_subsystem #(
    // P4.2 production default: Head payload is backed only by URAM.  Keep
    // this parameter available for a one-line rollback bitstream.
    parameter bit HEAD_SHADOW_DDR = 1'b0
) (
    output wire ppu_overlay_valid,input wire ppu_overlay_ready,
    output wire [3:0] ppu_overlay_stream,ppu_overlay_count,
    output wire [511:0] ppu_overlay_boxes,output wire [1023:0] ppu_overlay_labels,
    input wire [2:0] memory_perf_command,
    input wire memory_perf_request,
    output wire memory_perf_acknowledge, memory_perf_available,
    input wire [8:0] memory_perf_index,
    output wire [63:0] memory_perf_data,
    input  wire        sys_rstn,
    input  wire        c0_sys_clk_p,
    input  wire        c0_sys_clk_n,
    output wire        c0_init_calib_complete,
    output wire        c0_ddr4_act_n,
    output wire [16:0] c0_ddr4_adr,
    output wire [1:0]  c0_ddr4_ba,
    output wire [0:0]  c0_ddr4_bg,
    output wire [0:0]  c0_ddr4_ck_c,
    output wire [0:0]  c0_ddr4_ck_t,
    output wire [0:0]  c0_ddr4_cke,
    output wire [0:0]  c0_ddr4_cs_n,
    inout  wire [7:0]  c0_ddr4_dm_dbi_n,
    inout  wire [63:0] c0_ddr4_dq,
    inout  wire [7:0]  c0_ddr4_dqs_c,
    inout  wire [7:0]  c0_ddr4_dqs_t,
    output wire [0:0]  c0_ddr4_odt,
    output wire        c0_ddr4_reset_n,
    input  wire        soc_clk,
    input  wire        soc_resetn,
    axi4_if.slave      soc_mem_axi,
    axi4_if.master     fbus_axi,
    axi4_if.master     tensor_soc_axi,
    axi_lite_if.slave  postprocess_axil,
    axi4_if.slave      writer_video_axi,
    axi4_if.slave      reader_video_axi,
    axi4_if.slave      tensor_write_video_axi,
    output wire         capture_clk,
    output wire         capture_resetn,
    output wire         video_clk,
    output wire         video_resetn
);
    wire ddr_ui_clk;
    wire ddr_resetn;
    assign capture_clk = ddr_ui_clk;
    assign capture_resetn = ddr_resetn;

    axi4_if #(.ADDR_WIDTH(32), .DATA_WIDTH(256), .ID_WIDTH(3)) writer_ui_axi();
    axi4_if #(.ADDR_WIDTH(32), .DATA_WIDTH(256), .ID_WIDTH(3)) reader_ui_axi();
    axi4_if #(.ADDR_WIDTH(33), .DATA_WIDTH(256), .ID_WIDTH(5))
        fbus_write_soc_axi();
    axi4_if #(.ADDR_WIDTH(33), .DATA_WIDTH(512), .ID_WIDTH(2))
        soc_ddr_axi();
    video_memory_ports u_video_memory_ports (
        .writer_video_axi(writer_video_axi),
        .reader_video_axi(reader_video_axi),
        .ui_clk(ddr_ui_clk), .ui_resetn(ddr_resetn),
        .writer_ui_axi(writer_ui_axi), .reader_ui_axi(reader_ui_axi)
    );

    tensor_coherent_write_cdc u_tensor_memory_bridge (
        .tensor_write_axi(tensor_write_video_axi),
        .soc_clk(soc_clk), .soc_resetn(soc_resetn),
        .tensor_soc_axi(tensor_soc_axi)
    );

    // Tensor writes use their own coherent ingress. Publication writes still
    // use the original FBus path; idle its former video-tensor mux input.
    assign fbus_write_soc_axi.aclk = soc_clk;
    assign fbus_write_soc_axi.aresetn = soc_resetn;
    assign fbus_write_soc_axi.awid = '0;
    assign fbus_write_soc_axi.awaddr = '0;
    assign fbus_write_soc_axi.awlen = '0;
    assign fbus_write_soc_axi.awsize = '0;
    assign fbus_write_soc_axi.awburst = '0;
    assign fbus_write_soc_axi.awlock = '0;
    assign fbus_write_soc_axi.awcache = '0;
    assign fbus_write_soc_axi.awprot = '0;
    assign fbus_write_soc_axi.awqos = '0;
    assign fbus_write_soc_axi.awvalid = 1'b0;
    assign fbus_write_soc_axi.wdata = '0;
    assign fbus_write_soc_axi.wstrb = '0;
    assign fbus_write_soc_axi.wlast = 1'b0;
    assign fbus_write_soc_axi.wvalid = 1'b0;
    assign fbus_write_soc_axi.bready = 1'b1;
    assign fbus_write_soc_axi.arid = '0;
    assign fbus_write_soc_axi.araddr = '0;
    assign fbus_write_soc_axi.arlen = '0;
    assign fbus_write_soc_axi.arsize = '0;
    assign fbus_write_soc_axi.arburst = '0;
    assign fbus_write_soc_axi.arlock = '0;
    assign fbus_write_soc_axi.arcache = '0;
    assign fbus_write_soc_axi.arprot = '0;
    assign fbus_write_soc_axi.arqos = '0;
    assign fbus_write_soc_axi.arvalid = 1'b0;
    assign fbus_write_soc_axi.rready = 1'b0;

    wire [31:0] head_perf_events;
    wire [511:0] mig_perf_events;
    memory_perf_external u_memory_perf (
        .soc_clk(soc_clk), .soc_resetn(soc_resetn), .ddr_clk(ddr_ui_clk), .ddr_resetn(ddr_resetn),
        .command(memory_perf_command), .request(memory_perf_request), .acknowledge(memory_perf_acknowledge),
        .available(memory_perf_available), .index(memory_perf_index), .data(memory_perf_data),
        .soc_axi(soc_mem_axi), .ddr_axi(soc_ddr_axi), .video_write_axi(writer_ui_axi),
        .video_read_axi(reader_ui_axi), .mig_events(mig_perf_events), .head_events(head_perf_events)
    );

    postprocess_memory_bridge #(
        .HEAD_SHADOW_DDR(HEAD_SHADOW_DDR)
    ) u_postprocess_memory_bridge (
        .head_perf_events(head_perf_events),
        .soc_clk(soc_clk), .soc_resetn(soc_resetn),
        .soc_mem_axi(soc_mem_axi),
        .tensor_fbus_write_axi(fbus_write_soc_axi),
        .soc_ddr_axi(soc_ddr_axi), .fbus_axi(fbus_axi),
        .ppu_overlay_valid(ppu_overlay_valid),.ppu_overlay_ready(ppu_overlay_ready),
        .ppu_overlay_stream(ppu_overlay_stream),.ppu_overlay_count(ppu_overlay_count),
        .ppu_overlay_boxes(ppu_overlay_boxes),.ppu_overlay_labels(ppu_overlay_labels),
        .postprocess_axil(postprocess_axil)
    );

    ddr_platform u_ddr_platform (
        .mig_perf_events(mig_perf_events),
        .sys_rstn(sys_rstn),
        .c0_sys_clk_p(c0_sys_clk_p), .c0_sys_clk_n(c0_sys_clk_n),
        .c0_init_calib_complete(c0_init_calib_complete),
        .c0_ddr4_act_n(c0_ddr4_act_n), .c0_ddr4_adr(c0_ddr4_adr),
        .c0_ddr4_ba(c0_ddr4_ba), .c0_ddr4_bg(c0_ddr4_bg),
        .c0_ddr4_ck_c(c0_ddr4_ck_c), .c0_ddr4_ck_t(c0_ddr4_ck_t),
        .c0_ddr4_cke(c0_ddr4_cke), .c0_ddr4_cs_n(c0_ddr4_cs_n),
        .c0_ddr4_dm_dbi_n(c0_ddr4_dm_dbi_n), .c0_ddr4_dq(c0_ddr4_dq),
        .c0_ddr4_dqs_c(c0_ddr4_dqs_c), .c0_ddr4_dqs_t(c0_ddr4_dqs_t),
        .c0_ddr4_odt(c0_ddr4_odt), .c0_ddr4_reset_n(c0_ddr4_reset_n),
        .soc_ddr_axi(soc_ddr_axi), .writer_ui_axi(writer_ui_axi),
        .reader_ui_axi(reader_ui_axi), .ddr_ui_clk(ddr_ui_clk),
        .ddr_resetn(ddr_resetn), .video_clk(video_clk),
        .video_resetn(video_resetn)
    );
endmodule
