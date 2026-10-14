// Bind the production camera register interface at its real 18-bit width.
module camera_frontend_synthesis_top(
    input wire sys_rstn,
    input wire ov7670_ctrl_clk,
    input wire init_grant,
    output wire init_request,
    output wire init_terminal,
    input wire video_clk,
    input wire video_resetn,
    input wire ov7670_pclk,
    input wire ov7670_vsync,
    input wire ov7670_href,
    input wire [7:0] ov7670_data,
    output wire cam_scl,
    inout wire cam_sda,
    output wire cam_xclk,
    output wire cam_reset_n,
    output wire cam_pwdn,
    output wire event_valid,
    input wire event_ready,
    output wire diag_clear_toggle,
    output wire [7:0] event_data,
    output wire event_byte_valid,
    output wire event_line_start,
    output wire event_line_last,
    output wire event_line_end,
    output wire event_frame_boundary,
    output wire event_fault,
    output wire pixel_resetn,
    output wire pixel_enable,
    input wire [17:0] cfg_awaddr,
    input wire [2:0] cfg_awprot,
    input wire cfg_awvalid,
    output wire cfg_awready,
    input wire [31:0] cfg_wdata,
    input wire [3:0] cfg_wstrb,
    input wire cfg_wvalid,
    output wire cfg_wready,
    output wire [1:0] cfg_bresp,
    output wire cfg_bvalid,
    input wire cfg_bready,
    input wire [17:0] cfg_araddr,
    input wire [2:0] cfg_arprot,
    input wire cfg_arvalid,
    output wire cfg_arready,
    output wire [31:0] cfg_rdata,
    output wire [1:0] cfg_rresp,
    output wire cfg_rvalid,
    input wire cfg_rready
);
    axi_lite_if #(.ADDR_WIDTH(18)) camera_axil();
    assign camera_axil.aclk = ov7670_ctrl_clk;
    assign camera_axil.aresetn = sys_rstn;
    assign camera_axil.awaddr = cfg_awaddr;
    assign camera_axil.awprot = cfg_awprot;
    assign camera_axil.awvalid = cfg_awvalid;
    assign cfg_awready = camera_axil.awready;
    assign camera_axil.wdata = cfg_wdata;
    assign camera_axil.wstrb = cfg_wstrb;
    assign camera_axil.wvalid = cfg_wvalid;
    assign cfg_wready = camera_axil.wready;
    assign cfg_bresp = camera_axil.bresp;
    assign cfg_bvalid = camera_axil.bvalid;
    assign camera_axil.bready = cfg_bready;
    assign camera_axil.araddr = cfg_araddr;
    assign camera_axil.arprot = cfg_arprot;
    assign camera_axil.arvalid = cfg_arvalid;
    assign cfg_arready = camera_axil.arready;
    assign cfg_rdata = camera_axil.rdata;
    assign cfg_rresp = camera_axil.rresp;
    assign cfg_rvalid = camera_axil.rvalid;
    assign camera_axil.rready = cfg_rready;
    ov7670_frontend dut(
        .sys_rstn(sys_rstn),
        .ov7670_ctrl_clk(ov7670_ctrl_clk),
        .init_grant(init_grant),
        .init_request(init_request),
        .init_terminal(init_terminal),
        .video_clk(video_clk),
        .video_resetn(video_resetn),
        .ov7670_pclk(ov7670_pclk),
        .ov7670_vsync(ov7670_vsync),
        .ov7670_href(ov7670_href),
        .ov7670_data(ov7670_data),
        .cam_scl(cam_scl),
        .cam_sda(cam_sda),
        .cam_xclk(cam_xclk),
        .cam_reset_n(cam_reset_n),
        .cam_pwdn(cam_pwdn),
        .event_valid(event_valid),
        .event_ready(event_ready),
        .diag_clear_toggle(diag_clear_toggle),
        .event_data(event_data),
        .event_byte_valid(event_byte_valid),
        .event_line_start(event_line_start),
        .event_line_last(event_line_last),
        .event_line_end(event_line_end),
        .event_frame_boundary(event_frame_boundary),
        .event_fault(event_fault),
        .pixel_resetn(pixel_resetn),
        .pixel_enable(pixel_enable),
        .camera_axil(camera_axil)
    );
endmodule
