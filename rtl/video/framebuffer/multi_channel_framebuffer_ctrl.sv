`timescale 1ns/1ps

// CPU register bank for the local-camera frame store.  Channel addresses and
// frame geometry are runtime configuration; channel count and global ID base
// are elaboration parameters shared with the camera subsystem.
module multi_channel_framebuffer_ctrl #(
    parameter integer CHANNELS = 3,
    parameter integer GLOBAL_CHANNEL_BASE = 4,
    parameter [CHANNELS-1:0] CAMERA_PRESENT_MASK = {{(CHANNELS-1){1'b0}}, 1'b1},
    parameter [CHANNELS*32-1:0] DEFAULT_CHANNEL_BASES =
        {CHANNELS{32'h0800_0000}}
) (
    axi_lite_if.slave axil,
    output reg cfg_request_toggle,
    output reg cfg_enable,
    output reg [31:0] cfg_width,
    output reg [31:0] cfg_height,
    output reg [31:0] cfg_stride_bytes,
    output reg [31:0] cfg_buffers_per_channel,
    output reg [CHANNELS*32-1:0] cfg_channel_bases,
    output reg [31:0] cfg_buffer_stride_bytes,
    output reg [2:0] cfg_display_channel,
    output reg cfg_display_mode,
    input wire cfg_ack_toggle,
    input wire [31:0] manager_status,
    input wire [CHANNELS*32-1:0] writer_frame_counts,
    input wire [CHANNELS*32-1:0] drop_counts,
    input wire [CHANNELS*32-1:0] malformed_counts,
    input wire [31:0] reader_frame_count,
    input wire [31:0] underflow_count,
    input wire [31:0] reader_active_base,
    input wire [31:0] reader_debug_status,
    input wire [31:0] writer_perf_outstanding_current,
    input wire [31:0] writer_perf_outstanding_max,
    input wire [31:0] writer_perf_aw_stall_cycles,
    input wire [31:0] writer_perf_w_stall_cycles,
    input wire [31:0] writer_perf_b_stall_cycles,
    input wire [31:0] writer_perf_bursts_issued,
    input wire [31:0] writer_perf_bursts_completed,
    input wire [31:0] writer_perf_response_errors
);
    localparam integer CHANNEL_WIDTH = (CHANNELS <= 1) ? 1 : $clog2(CHANNELS);
    localparam [8:0] REG_CONTROL = 9'h000;
    localparam [8:0] REG_STATUS = 9'h004;
    localparam [8:0] REG_WIDTH = 9'h008;
    localparam [8:0] REG_HEIGHT = 9'h00c;
    localparam [8:0] REG_STRIDE = 9'h010;
    localparam [8:0] REG_SLOT_COUNT = 9'h014;
    localparam [8:0] REG_DISPLAY_CH = 9'h018;
    localparam [8:0] REG_PRESENT_MASK = 9'h01c;
    localparam [8:0] REG_CHANNEL_BASE0 = 9'h020;
    // Reserve 0x20..0x3f for all eight local channels.
    localparam [8:0] REG_BUFFER_STRIDE = 9'h040;
    localparam [8:0] REG_DISPLAY_MODE = 9'h044;
    localparam [8:0] REG_WRITER0 = 9'h080;
    localparam [8:0] REG_DROP0 = 9'h0a0;
    localparam [8:0] REG_MALFORMED0 = 9'h0c0;
    localparam [8:0] REG_READER_COUNT = 9'h0e0;
    localparam [8:0] REG_UNDERFLOW = 9'h0e4;
    localparam [8:0] REG_READER_BASE = 9'h0e8;
    localparam [8:0] REG_READER_DEBUG = 9'h0ec;
    localparam [8:0] REG_WRITER_PERF_CURRENT = 9'h0f0;
    localparam [8:0] REG_WRITER_PERF_MAX = 9'h0f4;
    localparam [8:0] REG_WRITER_PERF_AW_STALL = 9'h0f8;
    localparam [8:0] REG_WRITER_PERF_W_STALL = 9'h0fc;
    localparam [8:0] REG_WRITER_PERF_B_STALL = 9'h100;
    localparam [8:0] REG_WRITER_PERF_ISSUED = 9'h104;
    localparam [8:0] REG_WRITER_PERF_COMPLETED = 9'h108;
    localparam [8:0] REG_WRITER_PERF_ERRORS = 9'h10c;

    reg [8:0] awaddr_hold;
    reg [31:0] wdata_hold;
    reg [3:0] wstrb_hold;
    reg aw_pending;
    reg w_pending;
    reg bvalid;
    reg [31:0] rdata;
    reg rvalid;
    (* ASYNC_REG = "TRUE" *) reg ack_sync_1;
    (* ASYNC_REG = "TRUE" *) reg ack_sync_2;

    wire aw_fire = axil.awvalid && axil.awready;
    wire w_fire = axil.wvalid && axil.wready;
    wire write_complete = !bvalid && (aw_pending || aw_fire) &&
                          (w_pending || w_fire);
    wire [8:0] write_addr = aw_pending ? awaddr_hold : axil.awaddr[8:0];
    wire [31:0] write_data = w_pending ? wdata_hold : axil.wdata;
    wire [3:0] write_strb = w_pending ? wstrb_hold : axil.wstrb;
    wire cfg_busy = (cfg_request_toggle != ack_sync_2);
    wire write_is_channel_base = (write_addr >= REG_CHANNEL_BASE0) &&
        (write_addr < REG_CHANNEL_BASE0 + CHANNELS*4) &&
        (write_addr[1:0] == 2'b00);
    wire read_is_channel_base = (axil.araddr[8:0] >= REG_CHANNEL_BASE0) &&
        (axil.araddr[8:0] < REG_CHANNEL_BASE0 + CHANNELS*4) &&
        (axil.araddr[1:0] == 2'b00);
    wire [CHANNEL_WIDTH-1:0] write_channel =
        (write_addr - REG_CHANNEL_BASE0) >> 2;
    wire [CHANNEL_WIDTH-1:0] read_channel =
        (axil.araddr[8:0] - REG_CHANNEL_BASE0) >> 2;

    function automatic [31:0] apply_wstrb;
        input [31:0] old_value;
        input [31:0] new_value;
        input [3:0] strb;
        integer byte_index;
        begin
            apply_wstrb = old_value;
            for (byte_index = 0; byte_index < 4; byte_index = byte_index + 1)
                if (strb[byte_index])
                    apply_wstrb[byte_index*8 +: 8] =
                        new_value[byte_index*8 +: 8];
        end
    endfunction

    function automatic display_channel_present;
        input [2:0] global_channel;
        integer local_channel;
        begin
            local_channel = global_channel - GLOBAL_CHANNEL_BASE;
            if ((global_channel < GLOBAL_CHANNEL_BASE) ||
                (local_channel >= CHANNELS))
                display_channel_present = 1'b0;
            else
                display_channel_present = CAMERA_PRESENT_MASK[local_channel];
        end
    endfunction

    initial begin
        if ((REG_WRITER0 + CHANNELS*4 > REG_DROP0) ||
            (REG_DROP0 + CHANNELS*4 > REG_MALFORMED0) ||
            (REG_MALFORMED0 + CHANNELS*4 > REG_READER_COUNT))
            $error("multi_channel_framebuffer_ctrl register ranges overlap");
    end

    assign axil.awready = axil.aresetn && !aw_pending && !bvalid;
    assign axil.wready = axil.aresetn && !w_pending && !bvalid;
    assign axil.bresp = 2'b00;
    assign axil.bvalid = bvalid;
    assign axil.arready = axil.aresetn && !rvalid;
    assign axil.rdata = rdata;
    assign axil.rresp = 2'b00;
    assign axil.rvalid = rvalid;

    always @(posedge axil.aclk) begin
        if (!axil.aresetn) begin
            cfg_request_toggle <= 1'b0;
            cfg_enable <= 1'b0;
            cfg_width <= 32'd640;
            cfg_height <= 32'd480;
            cfg_stride_bytes <= 32'd2560;
            cfg_buffers_per_channel <= 32'd3;
            cfg_channel_bases <= DEFAULT_CHANNEL_BASES;
            cfg_buffer_stride_bytes <= 32'h0080_0000;
            cfg_display_channel <= GLOBAL_CHANNEL_BASE;
            // Zero selects the mosaic reader; one retains the full-frame
            // single-channel debug path.
            cfg_display_mode <= 1'b0;
            awaddr_hold <= 9'd0;
            wdata_hold <= 32'd0;
            wstrb_hold <= 4'd0;
            aw_pending <= 1'b0;
            w_pending <= 1'b0;
            bvalid <= 1'b0;
            rdata <= 32'd0;
            rvalid <= 1'b0;
            ack_sync_1 <= 1'b0;
            ack_sync_2 <= 1'b0;
        end else begin
            ack_sync_1 <= cfg_ack_toggle;
            ack_sync_2 <= ack_sync_1;

            if (aw_fire) begin
                awaddr_hold <= axil.awaddr[8:0];
                aw_pending <= 1'b1;
            end
            if (w_fire) begin
                wdata_hold <= axil.wdata;
                wstrb_hold <= axil.wstrb;
                w_pending <= 1'b1;
            end
            if (write_complete) begin
                case (write_addr)
                    REG_CONTROL: if (write_strb[0] && !cfg_busy) begin
                        cfg_enable <= write_data[0];
                        if (write_data[2])
                            cfg_request_toggle <= !cfg_request_toggle;
                    end
                    REG_WIDTH: if (!cfg_busy)
                        cfg_width <= apply_wstrb(cfg_width, write_data, write_strb);
                    REG_HEIGHT: if (!cfg_busy)
                        cfg_height <= apply_wstrb(cfg_height, write_data, write_strb);
                    REG_STRIDE: if (!cfg_busy)
                        cfg_stride_bytes <= apply_wstrb(cfg_stride_bytes, write_data,
                                                       write_strb);
                    REG_SLOT_COUNT: if (!cfg_busy)
                        cfg_buffers_per_channel <= apply_wstrb(
                            cfg_buffers_per_channel, write_data, write_strb);
                    REG_DISPLAY_CH: if (write_strb[0] &&
                                        display_channel_present(write_data[2:0]))
                        cfg_display_channel <= write_data[2:0];
                    REG_DISPLAY_MODE: if (write_strb[0])
                        cfg_display_mode <= write_data[0];
                    REG_BUFFER_STRIDE: if (!cfg_busy)
                        cfg_buffer_stride_bytes <= apply_wstrb(
                            cfg_buffer_stride_bytes, write_data, write_strb);
                    default: if (write_is_channel_base && !cfg_busy)
                        cfg_channel_bases[write_channel*32 +: 32] <=
                            apply_wstrb(
                                cfg_channel_bases[write_channel*32 +: 32],
                                write_data, write_strb);
                endcase
                aw_pending <= 1'b0;
                w_pending <= 1'b0;
                bvalid <= 1'b1;
            end else if (bvalid && axil.bready) begin
                bvalid <= 1'b0;
            end

            if (axil.arready && axil.arvalid) begin
                case (axil.araddr[8:0])
                    REG_CONTROL: rdata <= {29'd0, 1'b0,
                                           cfg_request_toggle, cfg_enable};
                    REG_STATUS: rdata <= {manager_status[31:1], cfg_busy};
                    REG_WIDTH: rdata <= cfg_width;
                    REG_HEIGHT: rdata <= cfg_height;
                    REG_STRIDE: rdata <= cfg_stride_bytes;
                    REG_SLOT_COUNT: rdata <= cfg_buffers_per_channel;
                    REG_DISPLAY_CH: rdata <= {29'd0, cfg_display_channel};
                    REG_DISPLAY_MODE: rdata <= {31'd0, cfg_display_mode};
                    REG_PRESENT_MASK: rdata <= {{(32-CHANNELS){1'b0}},
                                                CAMERA_PRESENT_MASK};
                    REG_BUFFER_STRIDE: rdata <= cfg_buffer_stride_bytes;
                    REG_READER_COUNT: rdata <= reader_frame_count;
                    REG_UNDERFLOW: rdata <= underflow_count;
                    REG_READER_BASE: rdata <= reader_active_base;
                    REG_READER_DEBUG: rdata <= reader_debug_status;
                    REG_WRITER_PERF_CURRENT:
                        rdata <= writer_perf_outstanding_current;
                    REG_WRITER_PERF_MAX:
                        rdata <= writer_perf_outstanding_max;
                    REG_WRITER_PERF_AW_STALL:
                        rdata <= writer_perf_aw_stall_cycles;
                    REG_WRITER_PERF_W_STALL:
                        rdata <= writer_perf_w_stall_cycles;
                    REG_WRITER_PERF_B_STALL:
                        rdata <= writer_perf_b_stall_cycles;
                    REG_WRITER_PERF_ISSUED:
                        rdata <= writer_perf_bursts_issued;
                    REG_WRITER_PERF_COMPLETED:
                        rdata <= writer_perf_bursts_completed;
                    REG_WRITER_PERF_ERRORS:
                        rdata <= writer_perf_response_errors;
                    default: begin
                        if ((axil.araddr[8:0] >= REG_WRITER0) &&
                            (axil.araddr[8:0] < REG_WRITER0 + CHANNELS*4))
                            rdata <= writer_frame_counts[
                                ((axil.araddr[8:0]-REG_WRITER0)>>2)*32 +: 32];
                        else if ((axil.araddr[8:0] >= REG_DROP0) &&
                                 (axil.araddr[8:0] < REG_DROP0 + CHANNELS*4))
                            rdata <= drop_counts[
                                ((axil.araddr[8:0]-REG_DROP0)>>2)*32 +: 32];
                        else if ((axil.araddr[8:0] >= REG_MALFORMED0) &&
                                 (axil.araddr[8:0] <
                                  REG_MALFORMED0 + CHANNELS*4))
                            rdata <= malformed_counts[
                                ((axil.araddr[8:0]-REG_MALFORMED0)>>2)*32 +: 32];
                        else if (read_is_channel_base)
                            rdata <= cfg_channel_bases[read_channel*32 +: 32];
                        else
                            rdata <= 32'd0;
                    end
                endcase
                rvalid <= 1'b1;
            end else if (rvalid && axil.rready) begin
                rvalid <= 1'b0;
            end
        end
    end
endmodule
