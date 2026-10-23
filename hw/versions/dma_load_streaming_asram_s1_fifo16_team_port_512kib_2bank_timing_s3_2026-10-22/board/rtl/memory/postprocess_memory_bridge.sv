`timescale 1ns/1ps

// Two-entry elastic channel. Both ready and valid terminate on local state,
// so a congested AXI endpoint cannot recreate a long combinational path
// through the register slice. The channel still accepts one beat per cycle.
module rv_elastic_fifo2 #(
    parameter integer WIDTH = 1
) (
    input  wire                 clk,
    input  wire                 resetn,
    input  wire [WIDTH-1:0]     in_data,
    input  wire                 in_valid,
    output wire                 in_ready,
    output wire [WIDTH-1:0]     out_data,
    output wire                 out_valid,
    input  wire                 out_ready
);
    (* ram_style = "registers" *) reg [WIDTH-1:0] storage [0:1];
    reg             read_pointer;
    reg             write_pointer;
    reg [1:0]       occupancy;
    wire            push = in_valid && in_ready;
    wire            pop = out_valid && out_ready;

    assign in_ready = occupancy != 2;
    assign out_valid = occupancy != 0;
    assign out_data = storage[read_pointer];

    always @(posedge clk) begin
        if (!resetn) begin
            read_pointer <= 1'b0;
            write_pointer <= 1'b0;
            occupancy <= 2'd0;
        end else begin
            if (push) begin
                storage[write_pointer] <= in_data;
                write_pointer <= ~write_pointer;
            end
            if (pop)
                read_pointer <= ~read_pointer;
            case ({push, pop})
                2'b10: occupancy <= occupancy + 1'b1;
                2'b01: occupancy <= occupancy - 1'b1;
                default: occupancy <= occupancy;
            endcase
        end
    end
endmodule

// Fully registered AXI boundary: each channel has independent two-beat
// storage, with no combinational ready or valid path across the slice.
module axi4_memory_timing_slice #(
    parameter integer ADDR_WIDTH = 33,
    parameter integer DATA_WIDTH = 512,
    parameter integer ID_WIDTH = 2
) (
    input wire clk,
    input wire resetn,
    axi4_if.slave s_axi,
    axi4_if.master m_axi
);
    localparam integer A_WIDTH = ID_WIDTH + ADDR_WIDTH + 25;
    localparam integer W_WIDTH = DATA_WIDTH + DATA_WIDTH/8 + 1;
    localparam integer B_WIDTH = ID_WIDTH + 2;
    localparam integer R_WIDTH = ID_WIDTH + DATA_WIDTH + 3;
    assign m_axi.aclk = clk;
    assign m_axi.aresetn = resetn;
    // Preserve only these new pipeline boundaries against global retiming.
    (* DONT_TOUCH = "TRUE" *) rv_elastic_fifo2 #(.WIDTH(A_WIDTH)) u_aw (
        .clk(clk), .resetn(resetn),
        .in_data({s_axi.awid,s_axi.awaddr,s_axi.awlen,s_axi.awsize,
                  s_axi.awburst,s_axi.awlock,s_axi.awcache,s_axi.awprot,s_axi.awqos}),
        .in_valid(s_axi.awvalid), .in_ready(s_axi.awready),
        .out_data({m_axi.awid,m_axi.awaddr,m_axi.awlen,m_axi.awsize,
                   m_axi.awburst,m_axi.awlock,m_axi.awcache,m_axi.awprot,m_axi.awqos}),
        .out_valid(m_axi.awvalid), .out_ready(m_axi.awready)
    );
    (* DONT_TOUCH = "TRUE" *) rv_elastic_fifo2 #(.WIDTH(W_WIDTH)) u_w (
        .clk(clk), .resetn(resetn), .in_data({s_axi.wdata,s_axi.wstrb,s_axi.wlast}),
        .in_valid(s_axi.wvalid), .in_ready(s_axi.wready),
        .out_data({m_axi.wdata,m_axi.wstrb,m_axi.wlast}),
        .out_valid(m_axi.wvalid), .out_ready(m_axi.wready)
    );
    (* DONT_TOUCH = "TRUE" *) rv_elastic_fifo2 #(.WIDTH(B_WIDTH)) u_b (
        .clk(clk), .resetn(resetn), .in_data({m_axi.bid,m_axi.bresp}),
        .in_valid(m_axi.bvalid), .in_ready(m_axi.bready),
        .out_data({s_axi.bid,s_axi.bresp}),
        .out_valid(s_axi.bvalid), .out_ready(s_axi.bready)
    );
    (* DONT_TOUCH = "TRUE" *) rv_elastic_fifo2 #(.WIDTH(A_WIDTH)) u_ar (
        .clk(clk), .resetn(resetn),
        .in_data({s_axi.arid,s_axi.araddr,s_axi.arlen,s_axi.arsize,
                  s_axi.arburst,s_axi.arlock,s_axi.arcache,s_axi.arprot,s_axi.arqos}),
        .in_valid(s_axi.arvalid), .in_ready(s_axi.arready),
        .out_data({m_axi.arid,m_axi.araddr,m_axi.arlen,m_axi.arsize,
                   m_axi.arburst,m_axi.arlock,m_axi.arcache,m_axi.arprot,m_axi.arqos}),
        .out_valid(m_axi.arvalid), .out_ready(m_axi.arready)
    );
    (* DONT_TOUCH = "TRUE" *) rv_elastic_fifo2 #(.WIDTH(R_WIDTH)) u_r (
        .clk(clk), .resetn(resetn), .in_data({m_axi.rid,m_axi.rdata,m_axi.rresp,m_axi.rlast}),
        .in_valid(m_axi.rvalid), .in_ready(m_axi.rready),
        .out_data({s_axi.rid,s_axi.rdata,s_axi.rresp,s_axi.rlast}),
        .out_valid(s_axi.rvalid), .out_ready(s_axi.rready)
    );
endmodule

// Head payload storage and postprocess reads.  The CPU memory port is routed
// through local URAM (with optional DDR shadow), while postprocess reads and
// coherent tensor writes share FBus by independent AXI channel direction.
module postprocess_memory_bridge #(
    parameter bit HEAD_SHADOW_DDR = 1'b0,
    parameter integer SOC_DATA_WIDTH = 512,
    parameter integer SOC_ID_WIDTH = 2
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
    output wire [31:0] head_perf_events,
    axi_lite_if.slave  postprocess_axil
);
    axi4_if #(.ADDR_WIDTH(33), .DATA_WIDTH(256), .ID_WIDTH(5))
        postprocess_read_axi(), joined_fbus_axi();
    axi4_if #(.ADDR_WIDTH(33), .DATA_WIDTH(SOC_DATA_WIDTH), .ID_WIDTH(SOC_ID_WIDTH))
        head_input_axi();
    localparam integer FBUS_A_WIDTH = 63;
    localparam integer FBUS_W_WIDTH = 289;
    localparam integer FBUS_B_WIDTH = 7;
    localparam integer FBUS_R_WIDTH = 264;
    wire [FBUS_A_WIDTH-1:0] fbus_aw_input, fbus_aw_output;
    wire [FBUS_W_WIDTH-1:0] fbus_w_input, fbus_w_output;
    wire [FBUS_B_WIDTH-1:0] fbus_b_input, fbus_b_output;
    wire [FBUS_A_WIDTH-1:0] fbus_ar_input, fbus_ar_output;
    wire [FBUS_R_WIDTH-1:0] fbus_r_input, fbus_r_output;
    wire [2:0] head_local_read_bank;
    wire head_local_read_req_valid;
    wire head_local_read_req_ready;
    wire [14:0] head_local_read_req_word_addr;
    wire [255:0] head_local_read_rsp_data;
    wire head_local_read_rsp_valid;
    wire head_local_read_rsp_ready;

    axi4_if #(.ADDR_WIDTH(33),.DATA_WIDTH(256),.ID_WIDTH(5)) publication_axi(), combined_write_axi();
    wire pub_enable,pub_allocate,pub_publish,pub_abort,pub_acquire,pub_release;
    wire [2:0] pub_bank,pub_lease_bank;
    wire [31:0] pub_version,pub_lease_version;
    wire [5:0] pub_mask;
    wire [5:0] pub_allocated,pub_reading,pub_fault;
    wire [191:0] pub_versions;
    wire [35:0] pub_ready_heads,pub_producer_heads;
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

    axi4_memory_timing_slice #(
        .ADDR_WIDTH(33), .DATA_WIDTH(SOC_DATA_WIDTH), .ID_WIDTH(SOC_ID_WIDTH)
    ) u_soc_memory_slice (
        .clk(soc_clk), .resetn(soc_resetn),
        .s_axi(soc_mem_axi), .m_axi(head_input_axi)
    );

    axi4_head_uram_router #(
        .DATA_WIDTH(SOC_DATA_WIDTH), .ID_WIDTH(SOC_ID_WIDTH), .LOCAL_DATA_WIDTH(256),
        .SHADOW_DDR(HEAD_SHADOW_DDR)
    ) u_head_uram_router (
        .perf_events(head_perf_events),
        .clk(soc_clk), .resetn(soc_resetn),
        .s_axi(head_input_axi), .m_ddr_axi(soc_ddr_axi),
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
        .clk(soc_clk), .resetn(soc_resetn), .m_axi(joined_fbus_axi)
    );

    assign fbus_axi.aclk = soc_clk;
    assign fbus_axi.aresetn = soc_resetn;

    assign fbus_aw_input = {joined_fbus_axi.awid, joined_fbus_axi.awaddr,
        joined_fbus_axi.awlen, joined_fbus_axi.awsize,
        joined_fbus_axi.awburst, joined_fbus_axi.awlock,
        joined_fbus_axi.awcache, joined_fbus_axi.awprot,
        joined_fbus_axi.awqos};
    assign {fbus_axi.awid, fbus_axi.awaddr, fbus_axi.awlen,
        fbus_axi.awsize, fbus_axi.awburst, fbus_axi.awlock,
        fbus_axi.awcache, fbus_axi.awprot, fbus_axi.awqos} = fbus_aw_output;
    rv_elastic_fifo2 #(.WIDTH(FBUS_A_WIDTH)) u_fbus_aw_fifo (
        .clk(soc_clk), .resetn(soc_resetn), .in_data(fbus_aw_input),
        .in_valid(joined_fbus_axi.awvalid),
        .in_ready(joined_fbus_axi.awready), .out_data(fbus_aw_output),
        .out_valid(fbus_axi.awvalid), .out_ready(fbus_axi.awready)
    );

    assign fbus_w_input = {joined_fbus_axi.wdata, joined_fbus_axi.wstrb,
        joined_fbus_axi.wlast};
    assign {fbus_axi.wdata, fbus_axi.wstrb, fbus_axi.wlast} = fbus_w_output;
    rv_elastic_fifo2 #(.WIDTH(FBUS_W_WIDTH)) u_fbus_w_fifo (
        .clk(soc_clk), .resetn(soc_resetn), .in_data(fbus_w_input),
        .in_valid(joined_fbus_axi.wvalid),
        .in_ready(joined_fbus_axi.wready), .out_data(fbus_w_output),
        .out_valid(fbus_axi.wvalid), .out_ready(fbus_axi.wready)
    );

    assign fbus_b_input = {fbus_axi.bid, fbus_axi.bresp};
    assign {joined_fbus_axi.bid, joined_fbus_axi.bresp} = fbus_b_output;
    rv_elastic_fifo2 #(.WIDTH(FBUS_B_WIDTH)) u_fbus_b_fifo (
        .clk(soc_clk), .resetn(soc_resetn), .in_data(fbus_b_input),
        .in_valid(fbus_axi.bvalid), .in_ready(fbus_axi.bready),
        .out_data(fbus_b_output), .out_valid(joined_fbus_axi.bvalid),
        .out_ready(joined_fbus_axi.bready)
    );

    assign fbus_ar_input = {joined_fbus_axi.arid, joined_fbus_axi.araddr,
        joined_fbus_axi.arlen, joined_fbus_axi.arsize,
        joined_fbus_axi.arburst, joined_fbus_axi.arlock,
        joined_fbus_axi.arcache, joined_fbus_axi.arprot,
        joined_fbus_axi.arqos};
    assign {fbus_axi.arid, fbus_axi.araddr, fbus_axi.arlen,
        fbus_axi.arsize, fbus_axi.arburst, fbus_axi.arlock,
        fbus_axi.arcache, fbus_axi.arprot, fbus_axi.arqos} = fbus_ar_output;
    rv_elastic_fifo2 #(.WIDTH(FBUS_A_WIDTH)) u_fbus_ar_fifo (
        .clk(soc_clk), .resetn(soc_resetn), .in_data(fbus_ar_input),
        .in_valid(joined_fbus_axi.arvalid),
        .in_ready(joined_fbus_axi.arready), .out_data(fbus_ar_output),
        .out_valid(fbus_axi.arvalid), .out_ready(fbus_axi.arready)
    );

    assign fbus_r_input = {fbus_axi.rid, fbus_axi.rdata,
        fbus_axi.rresp, fbus_axi.rlast};
    assign {joined_fbus_axi.rid, joined_fbus_axi.rdata,
        joined_fbus_axi.rresp, joined_fbus_axi.rlast} = fbus_r_output;
    rv_elastic_fifo2 #(.WIDTH(FBUS_R_WIDTH)) u_fbus_r_fifo (
        .clk(soc_clk), .resetn(soc_resetn), .in_data(fbus_r_input),
        .in_valid(fbus_axi.rvalid), .in_ready(fbus_axi.rready),
        .out_data(fbus_r_output), .out_valid(joined_fbus_axi.rvalid),
        .out_ready(joined_fbus_axi.rready)
    );
endmodule
