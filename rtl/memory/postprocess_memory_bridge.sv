`timescale 1ns/1ps

// Head payload storage and postprocess reads.  The CPU memory port is routed
// through local URAM (with optional DDR shadow), while postprocess reads and
// coherent tensor writes share FBus by independent AXI channel direction.
module postprocess_memory_bridge #(
    parameter bit HEAD_SHADOW_DDR = 1'b0
) (
    input  wire        soc_clk,
    input  wire        soc_resetn,
    axi4_if.slave      soc_mem_axi,
    axi4_if.slave      tensor_fbus_write_axi,
    axi4_if.master     soc_ddr_axi,
    axi4_if.master     fbus_axi,
    axi_lite_if.slave  postprocess_axil
);
    axi4_if #(.ADDR_WIDTH(33), .DATA_WIDTH(256), .ID_WIDTH(5))
        postprocess_read_axi();
    wire [1:0] head_local_read_bank;
    wire head_local_read_req_valid;
    wire head_local_read_req_ready;
    wire [14:0] head_local_read_req_word_addr;
    wire [255:0] head_local_read_rsp_data;
    wire head_local_read_rsp_valid;
    wire head_local_read_rsp_ready;

    postprocess_read_diagnostic #(
        .HEAD_SHADOW_DDR(HEAD_SHADOW_DDR)
    ) u_postprocess_read_diagnostic (
        .axil(postprocess_axil), .m_axi(postprocess_read_axi),
        .local_read_bank(head_local_read_bank),
        .local_read_req_valid(head_local_read_req_valid),
        .local_read_req_ready(head_local_read_req_ready),
        .local_read_req_word_addr(head_local_read_req_word_addr),
        .local_read_rsp_data(head_local_read_rsp_data),
        .local_read_rsp_valid(head_local_read_rsp_valid),
        .local_read_rsp_ready(head_local_read_rsp_ready)
    );

    axi4_head_uram_router #(
        .SHADOW_DDR(HEAD_SHADOW_DDR)
    ) u_head_uram_router (
        .clk(soc_clk), .resetn(soc_resetn),
        .s_axi(soc_mem_axi), .m_ddr_axi(soc_ddr_axi),
        .local_read_bank(head_local_read_bank),
        .local_read_req_valid(head_local_read_req_valid),
        .local_read_req_ready(head_local_read_req_ready),
        .local_read_req_word_addr(head_local_read_req_word_addr),
        .local_read_rsp_data(head_local_read_rsp_data),
        .local_read_rsp_valid(head_local_read_rsp_valid),
        .local_read_rsp_ready(head_local_read_rsp_ready)
    );

    axi4_channel_join u_fbus_channel_join (
        .write_axi(tensor_fbus_write_axi),
        .read_axi(postprocess_read_axi),
        .clk(soc_clk), .resetn(soc_resetn), .m_axi(fbus_axi)
    );
endmodule
