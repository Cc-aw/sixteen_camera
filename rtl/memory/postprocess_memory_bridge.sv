`timescale 1ns/1ps

// Head payload storage and postprocess reads.  The CPU memory port is routed
// through local URAM (with optional DDR shadow), while postprocess reads and
// coherent tensor writes share FBus by independent AXI channel direction.
module postprocess_memory_bridge #(
    parameter bit HEAD_SHADOW_DDR = 1'b0
) (
    output wire ppu_overlay_valid,input wire ppu_overlay_ready,
    output wire [3:0] ppu_overlay_stream,ppu_overlay_count,
    output wire [511:0] ppu_overlay_boxes,output wire [1023:0] ppu_overlay_labels,
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

    axi4_if #(.ADDR_WIDTH(33),.DATA_WIDTH(256),.ID_WIDTH(5)) publication_axi(), combined_write_axi();
    wire pub_enable,pub_allocate,pub_publish,pub_abort,pub_acquire,pub_release;
    wire [1:0] pub_bank,pub_lease_bank;
    wire [31:0] pub_version,pub_lease_version;
    wire [5:0] pub_mask;
    wire [3:0] pub_allocated,pub_reading,pub_fault;
    wire [127:0] pub_versions;
    wire [23:0] pub_ready_heads,pub_producer_heads;
    wire [31:0] pub_rejected,pub_cycles,pub_lines;
    wire pub_active,clean_start,clean_abort,clean_busy,clean_done,clean_error;
    wire [32:0] clean_base;
    wire [31:0] clean_bytes;
    head_publication_manager u_publication(
        .clk(soc_clk),.resetn(soc_resetn),.allocate(pub_allocate),.publish(pub_publish),.abort_slot(pub_abort),
        .release_slot(pub_release),.acquire(pub_acquire),.command_bank(pub_bank),.lease_bank(pub_lease_bank),
        .command_version(pub_version),.lease_version(pub_lease_version),.publish_mask(pub_mask),
        .allocated(pub_allocated),.reading(pub_reading),.fault(pub_fault),.versions(pub_versions),
        .ready_heads(pub_ready_heads),.producer_heads(pub_producer_heads),.rejected_commands(pub_rejected),
        .clean_start(clean_start),.clean_abort(clean_abort),.clean_base(clean_base),.clean_bytes(clean_bytes),
        .clean_busy(clean_busy),.clean_done(clean_done),.clean_error(clean_error),.active(pub_active)
    );
    ppu_cache_publish_engine u_clean(
        .clk(soc_clk),.resetn(soc_resetn),.start(clean_start),.abort(clean_abort),.base(clean_base),.bytes(clean_bytes),
        .busy(clean_busy),.done(clean_done),.error(clean_error),.cycles(pub_cycles),.lines_completed(pub_lines),
        .m_axi(publication_axi)
    );
    ppu_publication_write_mux u_publication_write_mux(
        .clk(soc_clk),.resetn(soc_resetn),.tensor_axi(tensor_fbus_write_axi),.publish_axi(publication_axi),
        .m_axi(combined_write_axi)
    );

    postprocess_read_diagnostic #(
        .HEAD_SHADOW_DDR(HEAD_SHADOW_DDR)
    ) u_postprocess_read_diagnostic (
        .ppu_overlay_valid(ppu_overlay_valid),.ppu_overlay_ready(ppu_overlay_ready),
        .ppu_overlay_stream(ppu_overlay_stream),.ppu_overlay_count(ppu_overlay_count),
        .ppu_overlay_boxes(ppu_overlay_boxes),.ppu_overlay_labels(ppu_overlay_labels),
        .axil(postprocess_axil), .m_axi(postprocess_read_axi),
        .pub_enable(pub_enable),.pub_allocate(pub_allocate),.pub_publish(pub_publish),.pub_abort(pub_abort),
        .pub_acquire(pub_acquire),.pub_release(pub_release),.pub_bank(pub_bank),.pub_lease_bank(pub_lease_bank),
        .pub_version(pub_version),.pub_lease_version(pub_lease_version),.pub_mask(pub_mask),
        .pub_allocated(pub_allocated),.pub_reading(pub_reading),.pub_fault(pub_fault),.pub_versions(pub_versions),
        .pub_ready_heads(pub_ready_heads),.pub_producer_heads(pub_producer_heads),.pub_rejected(pub_rejected),
        .pub_cycles(pub_cycles),.pub_lines(pub_lines),.pub_active(pub_active),
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
        .write_axi(combined_write_axi),
        .read_axi(postprocess_read_axi),
        .clk(soc_clk), .resetn(soc_resetn), .m_axi(fbus_axi)
    );
endmodule
