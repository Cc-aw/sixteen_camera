`timescale 1ns/1ps

// Decoder for the 256 KiB peripheral window at 0x4010_0000. The framebuffer
// owns the first 64 KiB. Each OV7670 keeps a 16 KiB channel slot and exposes
// its control/diagnostic bank at offset 0x1000.
module video_peripheral_fabric (
    axi_lite_if.slave  s_axil,
    axi_lite_if.master framebuffer_axil,
    axi_lite_if.master camera_axil [8],
    axi_lite_if.master postprocess_axil
);
    localparam logic [3:0] SEL_FB = 4'd0;
    localparam logic [3:0] SEL_POSTPROCESS = 4'd9;
    localparam logic [3:0] SEL_ERROR = 4'd15;

    logic [3:0] aw_sel, ar_sel;
    logic [17:0] awaddr_hold, araddr_hold;
    logic [2:0] awprot_hold, arprot_hold;
    logic [31:0] wdata_hold;
    logic [3:0] wstrb_hold;
    logic aw_hold, w_hold, write_active, write_aw_done, write_w_done;
    logic ar_hold, read_active, read_ar_done;

    wire [9:0] m_awready;
    wire [9:0] m_wready;
    wire [9:0][1:0] m_bresp;
    wire [9:0] m_bvalid;
    wire [9:0] m_arready;
    wire [9:0][31:0] m_rdata;
    wire [9:0][1:0] m_rresp;
    wire [9:0] m_rvalid;

    assign m_awready[0] = framebuffer_axil.awready;
    assign m_wready[0] = framebuffer_axil.wready;
    assign m_bresp[0] = framebuffer_axil.bresp;
    assign m_bvalid[0] = framebuffer_axil.bvalid;
    assign m_arready[0] = framebuffer_axil.arready;
    assign m_rdata[0] = framebuffer_axil.rdata;
    assign m_rresp[0] = framebuffer_axil.rresp;
    assign m_rvalid[0] = framebuffer_axil.rvalid;

    assign m_awready[SEL_POSTPROCESS] = postprocess_axil.awready;
    assign m_wready[SEL_POSTPROCESS] = postprocess_axil.wready;
    assign m_bresp[SEL_POSTPROCESS] = postprocess_axil.bresp;
    assign m_bvalid[SEL_POSTPROCESS] = postprocess_axil.bvalid;
    assign m_arready[SEL_POSTPROCESS] = postprocess_axil.arready;
    assign m_rdata[SEL_POSTPROCESS] = postprocess_axil.rdata;
    assign m_rresp[SEL_POSTPROCESS] = postprocess_axil.rresp;
    assign m_rvalid[SEL_POSTPROCESS] = postprocess_axil.rvalid;

    generate
        genvar camera_index;
        for (camera_index = 0; camera_index < 8;
             camera_index = camera_index + 1) begin : g_camera_targets
            localparam integer TARGET = camera_index + 1;
            assign m_awready[TARGET] = camera_axil[camera_index].awready;
            assign m_wready[TARGET] = camera_axil[camera_index].wready;
            assign m_bresp[TARGET] = camera_axil[camera_index].bresp;
            assign m_bvalid[TARGET] = camera_axil[camera_index].bvalid;
            assign m_arready[TARGET] = camera_axil[camera_index].arready;
            assign m_rdata[TARGET] = camera_axil[camera_index].rdata;
            assign m_rresp[TARGET] = camera_axil[camera_index].rresp;
            assign m_rvalid[TARGET] = camera_axil[camera_index].rvalid;

            assign camera_axil[camera_index].aclk = s_axil.aclk;
            assign camera_axil[camera_index].aresetn = s_axil.aresetn;
            assign camera_axil[camera_index].awaddr =
                {6'd0, awaddr_hold[11:0]};
            assign camera_axil[camera_index].araddr =
                {6'd0, araddr_hold[11:0]};
            assign camera_axil[camera_index].awprot = awprot_hold;
            assign camera_axil[camera_index].arprot = arprot_hold;
            assign camera_axil[camera_index].wdata = wdata_hold;
            assign camera_axil[camera_index].wstrb = wstrb_hold;
            assign camera_axil[camera_index].awvalid =
                write_active && (aw_sel == TARGET) && !write_aw_done;
            assign camera_axil[camera_index].wvalid =
                write_active && (aw_sel == TARGET) && !write_w_done;
            assign camera_axil[camera_index].bready =
                write_active && (aw_sel == TARGET) && s_axil.bready;
            assign camera_axil[camera_index].arvalid =
                read_active && (ar_sel == TARGET) && !read_ar_done;
            assign camera_axil[camera_index].rready =
                read_active && (ar_sel == TARGET) && s_axil.rready;
        end
    endgenerate

    function automatic logic [3:0] decode(input logic [17:0] address);
        begin
            decode = SEL_ERROR;
            if (address < 18'h10000) begin
                decode = SEL_FB;
            end else if ((address[17:14] >= 4'd4) &&
                         (address[17:14] <= 4'd11) &&
                         (address[13:12] == 2'd1)) begin
                decode = 4'd1 + (address[17:14] - 4'd4);
            end else if (address[17:16] == 2'b11) begin
                decode = SEL_POSTPROCESS;
            end
        end
    endfunction

    assign s_axil.awready = !aw_hold && !write_active;
    assign s_axil.wready = !w_hold && !write_active;
    assign s_axil.arready = !ar_hold && !read_active;

    always_ff @(posedge s_axil.aclk) begin
        if (!s_axil.aresetn) begin
            aw_hold <= 1'b0;
            w_hold <= 1'b0;
            write_active <= 1'b0;
            write_aw_done <= 1'b0;
            write_w_done <= 1'b0;
            ar_hold <= 1'b0;
            read_active <= 1'b0;
            read_ar_done <= 1'b0;
        end else begin
            if (s_axil.awvalid && s_axil.awready) begin
                aw_hold <= 1'b1;
                awaddr_hold <= s_axil.awaddr;
                awprot_hold <= s_axil.awprot;
                aw_sel <= decode(s_axil.awaddr);
            end
            if (s_axil.wvalid && s_axil.wready) begin
                w_hold <= 1'b1;
                wdata_hold <= s_axil.wdata;
                wstrb_hold <= s_axil.wstrb;
            end
            if (!write_active && aw_hold && w_hold) begin
                write_active <= 1'b1;
                write_aw_done <= 1'b0;
                write_w_done <= 1'b0;
            end
            if (write_active && (aw_sel != SEL_ERROR) &&
                !write_aw_done && m_awready[aw_sel])
                write_aw_done <= 1'b1;
            if (write_active && (aw_sel != SEL_ERROR) &&
                !write_w_done && m_wready[aw_sel])
                write_w_done <= 1'b1;
            if (s_axil.bvalid && s_axil.bready) begin
                aw_hold <= 1'b0;
                w_hold <= 1'b0;
                write_active <= 1'b0;
            end

            if (s_axil.arvalid && s_axil.arready) begin
                ar_hold <= 1'b1;
                araddr_hold <= s_axil.araddr;
                arprot_hold <= s_axil.arprot;
                ar_sel <= decode(s_axil.araddr);
            end
            if (!read_active && ar_hold) begin
                read_active <= 1'b1;
                read_ar_done <= 1'b0;
            end
            if (read_active && (ar_sel != SEL_ERROR) &&
                !read_ar_done && m_arready[ar_sel])
                read_ar_done <= 1'b1;
            if (s_axil.rvalid && s_axil.rready) begin
                ar_hold <= 1'b0;
                read_active <= 1'b0;
            end
        end
    end

    always_comb begin
        framebuffer_axil.aclk = s_axil.aclk;
        framebuffer_axil.aresetn = s_axil.aresetn;
        framebuffer_axil.awaddr = awaddr_hold;
        framebuffer_axil.araddr = araddr_hold;
        framebuffer_axil.awprot = awprot_hold;
        framebuffer_axil.arprot = arprot_hold;
        framebuffer_axil.wdata = wdata_hold;
        framebuffer_axil.wstrb = wstrb_hold;
        framebuffer_axil.awvalid = write_active && (aw_sel == SEL_FB) &&
                                   !write_aw_done;
        framebuffer_axil.wvalid = write_active && (aw_sel == SEL_FB) &&
                                  !write_w_done;
        framebuffer_axil.bready = write_active && (aw_sel == SEL_FB) &&
                                  s_axil.bready;
        framebuffer_axil.arvalid = read_active && (ar_sel == SEL_FB) &&
                                   !read_ar_done;
        framebuffer_axil.rready = read_active && (ar_sel == SEL_FB) &&
                                  s_axil.rready;

        postprocess_axil.aclk = s_axil.aclk;
        postprocess_axil.aresetn = s_axil.aresetn;
        postprocess_axil.awaddr = {2'd0, awaddr_hold[15:0]};
        postprocess_axil.araddr = {2'd0, araddr_hold[15:0]};
        postprocess_axil.awprot = awprot_hold;
        postprocess_axil.arprot = arprot_hold;
        postprocess_axil.wdata = wdata_hold;
        postprocess_axil.wstrb = wstrb_hold;
        postprocess_axil.awvalid = write_active &&
                                   (aw_sel == SEL_POSTPROCESS) &&
                                   !write_aw_done;
        postprocess_axil.wvalid = write_active &&
                                  (aw_sel == SEL_POSTPROCESS) &&
                                  !write_w_done;
        postprocess_axil.bready = write_active &&
                                  (aw_sel == SEL_POSTPROCESS) &&
                                  s_axil.bready;
        postprocess_axil.arvalid = read_active &&
                                   (ar_sel == SEL_POSTPROCESS) &&
                                   !read_ar_done;
        postprocess_axil.rready = read_active &&
                                  (ar_sel == SEL_POSTPROCESS) &&
                                  s_axil.rready;
    end

    assign s_axil.bvalid = write_active &&
                           ((aw_sel == SEL_ERROR) ||
                            (write_aw_done && write_w_done && m_bvalid[aw_sel]));
    assign s_axil.bresp = (aw_sel == SEL_ERROR) ? 2'b11 : m_bresp[aw_sel];
    assign s_axil.rvalid = read_active &&
                           ((ar_sel == SEL_ERROR) ||
                            (read_ar_done && m_rvalid[ar_sel]));
    assign s_axil.rdata = (ar_sel == SEL_ERROR) ? 32'b0 : m_rdata[ar_sel];
    assign s_axil.rresp = (ar_sel == SEL_ERROR) ? 2'b11 : m_rresp[ar_sel];
endmodule
