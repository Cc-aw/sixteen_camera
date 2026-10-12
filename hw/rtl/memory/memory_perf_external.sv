`timescale 1ns/1ps
module memory_perf_external (
    input wire soc_clk, soc_resetn, ddr_clk, ddr_resetn,
    input wire [2:0] command,
    input wire request,
    output reg acknowledge,
    output wire available,
    input wire [8:0] index,
    output reg [63:0] data,
    // Match the parent SoC slave modport when forwarding its interface.
    // This module only reads the interface; it never drives AXI signals.
    axi4_if.slave soc_axi,
    axi4_if ddr_axi, video_write_axi, video_read_axi,
    input wire [511:0] mig_events,
    input wire [31:0] head_events
);
    wire resetn = soc_resetn && ddr_resetn;
    wire [511:0] soc_events, ddr_events, video_events;
    reg [511:0] head_counter_events;
    wire [63:0] soc_data, ddr_data, head_data;
    wire [6143:0] async_snapshots;
    wire async_ack;
    reg seen;
    reg [2:0] delay_q;
    wire local_command = (request != seen) && delay_q == 0;
    wire [511:0] idle_events = 512'd1;
    memory_perf_async_group u_async (
        .dst_clk(soc_clk), .src_clk(ddr_clk), .resetn(resetn), .request(request), .command(command),
        .events({idle_events, video_events, mig_events}), .acknowledge(async_ack),
        .available(available), .snapshots(async_snapshots)
    );
    always @* begin
        head_counter_events = 0;
        head_counter_events[15:0] = 1;
        for (integer n=0; n<8; n=n+1) head_counter_events[(n+1)*16 +:16] = {15'd0,head_events[n]};
        data = 0;
        case(index[8:5])
            7: data = soc_data;
            8: data = ddr_data;
            9,10,11: data = async_snapshots[(int'(index[8:5])-9)*2048 + int'(index[4:0])*64 +:64];
            12: data = head_data;
            default: ;
        endcase
    end
    always @(posedge soc_clk) begin
        if (!resetn || !available) begin seen <= 0; acknowledge <= 0; delay_q <= 0; end
        else begin
            if(local_command) begin delay_q <= 3; seen <= request; end
            else if(delay_q != 0) delay_q <= delay_q - 1'b1;
            if(delay_q == 0 && seen == request && async_ack == request) acknowledge <= request;
        end
    end
    memory_perf_axi_events #(.DATA_BYTES(64)) u_soc_events (
        .clk(soc_clk), .resetn(soc_resetn),
        .arvalid(soc_axi.arvalid), .arready(soc_axi.arready), .awvalid(soc_axi.awvalid), .awready(soc_axi.awready), .rvalid(soc_axi.rvalid), .rready(soc_axi.rready), .rlast(soc_axi.rlast), .wvalid(soc_axi.wvalid), .wready(soc_axi.wready), .bvalid(soc_axi.bvalid), .bready(soc_axi.bready), .arlen(soc_axi.arlen), .arsize(soc_axi.arsize), .wstrb(soc_axi.wstrb),
        .events(soc_events)
    );
    memory_perf_axi_events #(.DATA_BYTES(64)) u_ddr_events (
        .clk(soc_clk), .resetn(soc_resetn),
        .arvalid(ddr_axi.arvalid), .arready(ddr_axi.arready), .awvalid(ddr_axi.awvalid), .awready(ddr_axi.awready), .rvalid(ddr_axi.rvalid), .rready(ddr_axi.rready), .rlast(ddr_axi.rlast), .wvalid(ddr_axi.wvalid), .wready(ddr_axi.wready), .bvalid(ddr_axi.bvalid), .bready(ddr_axi.bready), .arlen(ddr_axi.arlen), .arsize(ddr_axi.arsize), .wstrb(ddr_axi.wstrb),
        .events(ddr_events)
    );
    memory_perf_axi_events #(.DATA_BYTES(32)) u_video_events (
        .clk(ddr_clk), .resetn(ddr_resetn),
        .arvalid(video_read_axi.arvalid), .arready(video_read_axi.arready), .awvalid(video_write_axi.awvalid), .awready(video_write_axi.awready), .rvalid(video_read_axi.rvalid), .rready(video_read_axi.rready), .rlast(video_read_axi.rlast), .wvalid(video_write_axi.wvalid), .wready(video_write_axi.wready), .bvalid(video_write_axi.bvalid), .bready(video_write_axi.bready), .arlen(video_read_axi.arlen), .arsize(video_read_axi.arsize), .wstrb(video_write_axi.wstrb),
        .events(video_events)
    );
    memory_perf_counter_bank #(.PEAK_MASK(32'h00018000)) u_soc_counter (
        .clk(soc_clk), .resetn(resetn), .command_valid(local_command && available), .command(command),
        .events(soc_events), .index(index[4:0]), .data(soc_data), .frozen_flat()
    );
    memory_perf_counter_bank #(.PEAK_MASK(32'h00018000)) u_ddr_counter (
        .clk(soc_clk), .resetn(resetn), .command_valid(local_command && available), .command(command),
        .events(ddr_events), .index(index[4:0]), .data(ddr_data), .frozen_flat()
    );
    memory_perf_counter_bank #(.PEAK_MASK(32'h00000000)) u_head_counter (
        .clk(soc_clk), .resetn(resetn), .command_valid(local_command && available), .command(command),
        .events(head_counter_events), .index(index[4:0]), .data(head_data), .frozen_flat()
    );
endmodule
