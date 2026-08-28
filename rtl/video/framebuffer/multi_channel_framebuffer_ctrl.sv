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
    output reg [31:0] preprocess_arena0_base,
    output reg [31:0] preprocess_arena1_base,
    output reg [31:0] preprocess_member_stride,
    output reg [31:0] preprocess_member_bytes,
    output reg [((CHANNELS <= 1) ? 1 : $clog2(CHANNELS))-1:0]
        cfg_display_channel,
    output reg cfg_display_mode,
    output reg cfg_hdmi_capture_enable,
    output reg ai_snapshot_req_toggle,
    output reg ai_release_req_toggle,
    output reg [CHANNELS-1:0] ai_release_mask,
    output reg ai_meta_req_toggle,
    output reg [((CHANNELS <= 1) ? 1 : $clog2(CHANNELS))-1:0]
        ai_meta_index,
    input wire ai_snapshot_ack_toggle,
    input wire ai_release_ack_toggle,
    input wire ai_meta_ack_toggle,
    input wire ai_snapshot_active,
    input wire [CHANNELS-1:0] ai_snapshot_valid_mask,
    input wire [CHANNELS-1:0] ai_snapshot_fresh_mask,
    input wire [CHANNELS-1:0] ai_held_mask,
    input wire [31:0] ai_meta_addr,
    input wire [63:0] ai_meta_frame_id,
    input wire [63:0] ai_meta_timestamp,
    input wire [31:0] ai_meta_version,
    input wire [63:0] ai_snapshot_batch_id,
    input wire [31:0] ai_snapshot_count,
    input wire [31:0] ai_release_count,
    input wire [31:0] ai_error_count,
    output reg preprocess_start_req_toggle,
    output reg preprocess_recycle_req_toggle,
    output reg [1:0] preprocess_recycle_mask,
    input wire preprocess_start_ack_toggle,
    input wire preprocess_recycle_ack_toggle,
    input wire preprocess_busy,
    input wire [1:0] preprocess_ready_mask,
    input wire preprocess_active_arena,
    input wire [4:0] preprocess_active_channel,
    input wire [4:0] preprocess_completed_channels,
    input wire [31:0] preprocess_active_tensor_base,
    input wire [63:0] preprocess_arena0_batch_id,
    input wire [63:0] preprocess_arena1_batch_id,
    input wire [CHANNELS-1:0] preprocess_arena0_valid_mask,
    input wire [CHANNELS-1:0] preprocess_arena1_valid_mask,
    input wire [CHANNELS-1:0] preprocess_arena0_fresh_mask,
    input wire [CHANNELS-1:0] preprocess_arena1_fresh_mask,
    input wire [31:0] preprocess_last_batch_cycles,
    input wire [31:0] preprocess_last_read_beats,
    input wire [31:0] preprocess_last_write_beats,
    input wire [31:0] preprocess_start_count,
    input wire [31:0] preprocess_complete_count,
    input wire [31:0] preprocess_error_count,
    output reg overlay_commit_toggle,
    output reg [3:0] overlay_stream,
    output reg [3:0] overlay_count,
    output reg [8*64-1:0] overlay_boxes,
    input wire overlay_commit_ack_toggle,
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
    input wire [31:0] writer_perf_response_errors,
    input wire [31:0] hdmi_transport_frame_count,
    input wire [31:0] hdmi_transport_malformed_count,
    input wire [8*32-1:0] hdmi_channel_frame_counts,
    input wire [8*32-1:0] hdmi_channel_overflow_counts
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
    // Reserve 0x20..0x5f for all sixteen channels.
    localparam [8:0] REG_BUFFER_STRIDE = 9'h060;
    localparam [8:0] REG_DISPLAY_MODE = 9'h064;
    localparam [8:0] REG_HDMI_CONTROL = 9'h068;
    localparam [8:0] REG_WRITER0 = 9'h080;
    localparam [8:0] REG_DROP0 = 9'h0c0;
    localparam [8:0] REG_MALFORMED0 = 9'h100;
    localparam [8:0] REG_READER_COUNT = 9'h140;
    localparam [8:0] REG_UNDERFLOW = 9'h144;
    localparam [8:0] REG_READER_BASE = 9'h148;
    localparam [8:0] REG_READER_DEBUG = 9'h14c;
    localparam [8:0] REG_WRITER_PERF_CURRENT = 9'h150;
    localparam [8:0] REG_WRITER_PERF_MAX = 9'h154;
    localparam [8:0] REG_WRITER_PERF_AW_STALL = 9'h158;
    localparam [8:0] REG_WRITER_PERF_W_STALL = 9'h15c;
    localparam [8:0] REG_WRITER_PERF_B_STALL = 9'h160;
    localparam [8:0] REG_WRITER_PERF_ISSUED = 9'h164;
    localparam [8:0] REG_WRITER_PERF_COMPLETED = 9'h168;
    localparam [8:0] REG_WRITER_PERF_ERRORS = 9'h16c;
    localparam [8:0] REG_HDMI_TRANSPORT_FRAMES = 9'h170;
    localparam [8:0] REG_HDMI_TRANSPORT_MALFORMED = 9'h174;
    localparam [8:0] REG_HDMI_FRAME0 = 9'h180;
    localparam [8:0] REG_HDMI_OVERFLOW0 = 9'h1a0;
    localparam [8:0] REG_AI_CONTROL = 9'h1c0;
    localparam [8:0] REG_AI_STATUS = 9'h1c4;
    localparam [8:0] REG_AI_RELEASE_MASK = 9'h1c8;
    localparam [8:0] REG_AI_VALID_MASK = 9'h1cc;
    localparam [8:0] REG_AI_FRESH_MASK = 9'h1d0;
    localparam [8:0] REG_AI_HELD_MASK = 9'h1d4;
    localparam [8:0] REG_AI_META_INDEX = 9'h1d8;
    localparam [8:0] REG_AI_META_ADDR = 9'h1dc;
    localparam [8:0] REG_AI_META_FRAME_LO = 9'h1e0;
    localparam [8:0] REG_AI_META_FRAME_HI = 9'h1e4;
    localparam [8:0] REG_AI_META_TIME_LO = 9'h1e8;
    localparam [8:0] REG_AI_META_TIME_HI = 9'h1ec;
    localparam [8:0] REG_AI_META_VERSION = 9'h1f0;
    localparam [8:0] REG_AI_BATCH_LO = 9'h1f4;
    localparam [8:0] REG_AI_BATCH_HI = 9'h1f8;
    localparam [9:0] REG_AI_DIAG = 10'h1fc;
    localparam [9:0] REG_PRE_CONTROL = 10'h200;
    localparam [9:0] REG_PRE_STATUS = 10'h204;
    localparam [9:0] REG_PRE_RECYCLE_MASK = 10'h208;
    localparam [9:0] REG_PRE_PROGRESS = 10'h20c;
    localparam [9:0] REG_PRE_ACTIVE_BASE = 10'h210;
    localparam [9:0] REG_PRE_ARENA0_BATCH_LO = 10'h220;
    localparam [9:0] REG_PRE_ARENA0_BATCH_HI = 10'h224;
    localparam [9:0] REG_PRE_ARENA1_BATCH_LO = 10'h228;
    localparam [9:0] REG_PRE_ARENA1_BATCH_HI = 10'h22c;
    localparam [9:0] REG_PRE_ARENA0_VALID = 10'h230;
    localparam [9:0] REG_PRE_ARENA1_VALID = 10'h234;
    localparam [9:0] REG_PRE_ARENA0_FRESH = 10'h238;
    localparam [9:0] REG_PRE_ARENA1_FRESH = 10'h23c;
    localparam [9:0] REG_PRE_LAST_CYCLES = 10'h240;
    localparam [9:0] REG_PRE_LAST_READ = 10'h244;
    localparam [9:0] REG_PRE_LAST_WRITE = 10'h248;
    localparam [9:0] REG_PRE_START_COUNT = 10'h24c;
    localparam [9:0] REG_PRE_COMPLETE_COUNT = 10'h250;
    localparam [9:0] REG_PRE_ERROR_COUNT = 10'h254;
    localparam [9:0] REG_PRE_ARENA0_BASE = 10'h280;
    localparam [9:0] REG_PRE_ARENA1_BASE = 10'h284;
    localparam [9:0] REG_PRE_MEMBER_STRIDE = 10'h288;
    localparam [9:0] REG_PRE_MEMBER_BYTES = 10'h28c;
    localparam [9:0] REG_OVERLAY_CONTROL = 10'h260;
    localparam [9:0] REG_OVERLAY_STREAM = 10'h264;
    localparam [9:0] REG_OVERLAY_COUNT = 10'h268;
    localparam [9:0] REG_OVERLAY_BOX_INDEX = 10'h26c;
    localparam [9:0] REG_OVERLAY_BOX_XY0 = 10'h270;
    localparam [9:0] REG_OVERLAY_BOX_XY1 = 10'h274;
    localparam [9:0] REG_OVERLAY_BOX_CLASS = 10'h278;

    reg [9:0] awaddr_hold;
    reg [31:0] wdata_hold;
    reg [3:0] wstrb_hold;
    reg aw_pending;
    reg w_pending;
    reg bvalid;
    reg [31:0] rdata;
    reg rvalid;
    reg [2:0] overlay_box_index;
    (* ASYNC_REG = "TRUE" *) reg ack_sync_1;
    (* ASYNC_REG = "TRUE" *) reg ack_sync_2;

    wire aw_fire = axil.awvalid && axil.awready;
    wire w_fire = axil.wvalid && axil.wready;
    wire write_complete = !bvalid && (aw_pending || aw_fire) &&
                          (w_pending || w_fire);
    wire [9:0] write_addr = aw_pending ? awaddr_hold : axil.awaddr[9:0];
    wire [31:0] write_data = w_pending ? wdata_hold : axil.wdata;
    wire [3:0] write_strb = w_pending ? wstrb_hold : axil.wstrb;
    wire cfg_busy = (cfg_request_toggle != ack_sync_2);
    wire ai_snapshot_busy =
        (ai_snapshot_req_toggle != ai_snapshot_ack_toggle);
    wire ai_release_busy =
        (ai_release_req_toggle != ai_release_ack_toggle);
    wire ai_meta_busy = (ai_meta_req_toggle != ai_meta_ack_toggle);
    wire preprocess_start_busy =
        preprocess_start_req_toggle != preprocess_start_ack_toggle;
    wire preprocess_recycle_busy =
        preprocess_recycle_req_toggle != preprocess_recycle_ack_toggle;
    wire overlay_commit_busy =
        overlay_commit_toggle != overlay_commit_ack_toggle;
    wire write_is_channel_base = (write_addr >= REG_CHANNEL_BASE0) &&
        (write_addr < REG_CHANNEL_BASE0 + CHANNELS*4) &&
        (write_addr[1:0] == 2'b00);
    wire read_is_channel_base = (axil.araddr[9:0] >= REG_CHANNEL_BASE0) &&
        (axil.araddr[9:0] < REG_CHANNEL_BASE0 + CHANNELS*4) &&
        (axil.araddr[1:0] == 2'b00);
    wire [CHANNEL_WIDTH-1:0] write_channel =
        (write_addr - REG_CHANNEL_BASE0) >> 2;
    wire [CHANNEL_WIDTH-1:0] read_channel =
        (axil.araddr[9:0] - REG_CHANNEL_BASE0) >> 2;

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
        input [CHANNEL_WIDTH-1:0] global_channel;
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
        if (CHANNELS > 16 ||
            (REG_CHANNEL_BASE0 + CHANNELS*4 > REG_BUFFER_STRIDE) ||
            (REG_WRITER0 + CHANNELS*4 > REG_DROP0) ||
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
            cfg_buffers_per_channel <= 32'd5;
            cfg_channel_bases <= DEFAULT_CHANNEL_BASES;
            cfg_buffer_stride_bytes <= 32'h0040_0000;
            preprocess_arena0_base <= 32'h3000_0000;
            preprocess_arena1_base <= 32'h3100_0000;
            preprocess_member_stride <= 32'h000e_1000;
            preprocess_member_bytes <= 32'h000e_1000;
            cfg_display_channel <= CHANNEL_WIDTH'(GLOBAL_CHANNEL_BASE);
            // Zero selects the mosaic reader; one retains the full-frame
            // single-channel debug path.
            cfg_display_mode <= 1'b0;
            cfg_hdmi_capture_enable <= 1'b0;
            ai_snapshot_req_toggle <= 1'b0;
            ai_release_req_toggle <= 1'b0;
            ai_release_mask <= {CHANNELS{1'b0}};
            ai_meta_req_toggle <= 1'b0;
            ai_meta_index <= {CHANNEL_WIDTH{1'b0}};
            preprocess_start_req_toggle <= 1'b0;
            preprocess_recycle_req_toggle <= 1'b0;
            preprocess_recycle_mask <= 2'b00;
            overlay_commit_toggle <= 1'b0;
            overlay_stream <= 4'd0;
            overlay_count <= 4'd0;
            overlay_boxes <= 512'd0;
            overlay_box_index <= 3'd0;
            awaddr_hold <= 10'd0;
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
                awaddr_hold <= axil.awaddr[9:0];
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
                                        display_channel_present(
                                            write_data[CHANNEL_WIDTH-1:0]))
                        cfg_display_channel <= write_data[CHANNEL_WIDTH-1:0];
                    REG_DISPLAY_MODE: if (write_strb[0])
                        cfg_display_mode <= write_data[0];
                    REG_HDMI_CONTROL: if (write_strb[0])
                        cfg_hdmi_capture_enable <= write_data[0];
                    REG_AI_CONTROL: if (write_strb[0]) begin
                        if (write_data[0] && !write_data[1] &&
                            !ai_snapshot_busy)
                            ai_snapshot_req_toggle <=
                                !ai_snapshot_req_toggle;
                        if (write_data[1] && !write_data[0] &&
                            !ai_release_busy)
                            ai_release_req_toggle <=
                                !ai_release_req_toggle;
                    end
                    REG_AI_RELEASE_MASK: if (!ai_release_busy)
                        ai_release_mask <= write_data[CHANNELS-1:0];
                    REG_AI_META_INDEX: if (write_strb[0] && !ai_meta_busy &&
                                           (write_data < CHANNELS)) begin
                        ai_meta_index <= write_data[CHANNEL_WIDTH-1:0];
                        ai_meta_req_toggle <= !ai_meta_req_toggle;
                    end
                    REG_PRE_CONTROL: if (write_strb[0]) begin
                        if (write_data[0] && !write_data[1] &&
                            !preprocess_start_busy)
                            preprocess_start_req_toggle <=
                                !preprocess_start_req_toggle;
                        if (write_data[1] && !write_data[0] &&
                            !preprocess_recycle_busy)
                            preprocess_recycle_req_toggle <=
                                !preprocess_recycle_req_toggle;
                    end
                    REG_PRE_RECYCLE_MASK: if (!preprocess_recycle_busy)
                        preprocess_recycle_mask <= write_data[1:0];
                    REG_PRE_ARENA0_BASE: if (!preprocess_busy &&
                                              !preprocess_start_busy)
                        preprocess_arena0_base <= apply_wstrb(
                            preprocess_arena0_base, write_data, write_strb);
                    REG_PRE_ARENA1_BASE: if (!preprocess_busy &&
                                              !preprocess_start_busy)
                        preprocess_arena1_base <= apply_wstrb(
                            preprocess_arena1_base, write_data, write_strb);
                    REG_PRE_MEMBER_STRIDE: if (!preprocess_busy &&
                                                !preprocess_start_busy)
                        preprocess_member_stride <= apply_wstrb(
                            preprocess_member_stride, write_data, write_strb);
                    REG_PRE_MEMBER_BYTES: if (!preprocess_busy &&
                                               !preprocess_start_busy)
                        preprocess_member_bytes <= apply_wstrb(
                            preprocess_member_bytes, write_data, write_strb);
                    REG_OVERLAY_CONTROL: if (write_strb[0] &&
                                                write_data[0] &&
                                                !overlay_commit_busy &&
                                                overlay_stream < CHANNELS &&
                                                overlay_count <= 8)
                        overlay_commit_toggle <= !overlay_commit_toggle;
                    REG_OVERLAY_STREAM: if (write_strb[0] &&
                                               !overlay_commit_busy &&
                                               write_data < CHANNELS)
                        overlay_stream <= write_data[3:0];
                    REG_OVERLAY_COUNT: if (write_strb[0] &&
                                              !overlay_commit_busy &&
                                              write_data <= 8)
                        overlay_count <= write_data[3:0];
                    REG_OVERLAY_BOX_INDEX: if (write_strb[0] &&
                                                  !overlay_commit_busy &&
                                                  write_data < 8)
                        overlay_box_index <= write_data[2:0];
                    REG_OVERLAY_BOX_XY0: if (!overlay_commit_busy)
                        overlay_boxes[overlay_box_index*64 +: 32] <=
                            apply_wstrb(
                                overlay_boxes[overlay_box_index*64 +: 32],
                                write_data, write_strb);
                    REG_OVERLAY_BOX_XY1: if (!overlay_commit_busy)
                        overlay_boxes[overlay_box_index*64 + 32 +: 32] <=
                            apply_wstrb(
                                overlay_boxes[overlay_box_index*64 + 32 +: 32],
                                write_data, write_strb);
                    REG_OVERLAY_BOX_CLASS: if (!overlay_commit_busy)
                        overlay_boxes[overlay_box_index*64 + 44 +: 8] <=
                            write_data[7:0];
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
                case (axil.araddr[9:0])
                    REG_CONTROL: rdata <= {29'd0, 1'b0,
                                           cfg_request_toggle, cfg_enable};
                    REG_STATUS: rdata <= {manager_status[31:1], cfg_busy};
                    REG_WIDTH: rdata <= cfg_width;
                    REG_HEIGHT: rdata <= cfg_height;
                    REG_STRIDE: rdata <= cfg_stride_bytes;
                    REG_SLOT_COUNT: rdata <= cfg_buffers_per_channel;
                    REG_DISPLAY_CH: rdata <=
                        {{(32-CHANNEL_WIDTH){1'b0}}, cfg_display_channel};
                    REG_DISPLAY_MODE: rdata <= {31'd0, cfg_display_mode};
                    REG_HDMI_CONTROL:
                        rdata <= {31'd0, cfg_hdmi_capture_enable};
                    REG_AI_CONTROL:
                        rdata <= {28'd0, ai_release_busy, ai_snapshot_busy,
                                  ai_release_req_toggle,
                                  ai_snapshot_req_toggle};
                    REG_AI_STATUS:
                        rdata <= {ai_error_count[15:0], 11'd0, ai_meta_busy,
                                  (ai_error_count != 0), ai_snapshot_active,
                                  ai_release_busy, ai_snapshot_busy};
                    REG_AI_RELEASE_MASK:
                        rdata <= {{(32-CHANNELS){1'b0}}, ai_release_mask};
                    REG_AI_VALID_MASK:
                        rdata <= {{(32-CHANNELS){1'b0}},
                                  ai_snapshot_valid_mask};
                    REG_AI_FRESH_MASK:
                        rdata <= {{(32-CHANNELS){1'b0}},
                                  ai_snapshot_fresh_mask};
                    REG_AI_HELD_MASK:
                        rdata <= {{(32-CHANNELS){1'b0}}, ai_held_mask};
                    REG_AI_META_INDEX:
                        rdata <= {{(32-CHANNEL_WIDTH){1'b0}}, ai_meta_index};
                    REG_AI_META_ADDR:
                        rdata <= ai_meta_addr;
                    REG_AI_META_FRAME_LO:
                        rdata <= ai_meta_frame_id[31:0];
                    REG_AI_META_FRAME_HI:
                        rdata <= ai_meta_frame_id[63:32];
                    REG_AI_META_TIME_LO:
                        rdata <= ai_meta_timestamp[31:0];
                    REG_AI_META_TIME_HI:
                        rdata <= ai_meta_timestamp[63:32];
                    REG_AI_META_VERSION:
                        rdata <= ai_meta_version;
                    REG_AI_BATCH_LO: rdata <= ai_snapshot_batch_id[31:0];
                    REG_AI_BATCH_HI: rdata <= ai_snapshot_batch_id[63:32];
                    REG_AI_DIAG:
                        rdata <= {ai_error_count[7:0],
                                  ai_release_count[11:0],
                                  ai_snapshot_count[11:0]};
                    REG_PRE_CONTROL:
                        rdata <= {28'd0, preprocess_recycle_busy,
                                  preprocess_start_busy,
                                  preprocess_recycle_req_toggle,
                                  preprocess_start_req_toggle};
                    REG_PRE_STATUS:
                        rdata <= {preprocess_error_count[15:0], 10'd0,
                                  preprocess_active_arena,
                                  preprocess_ready_mask,
                                  preprocess_busy,
                                  preprocess_recycle_busy,
                                  preprocess_start_busy};
                    REG_PRE_RECYCLE_MASK:
                        rdata <= {30'd0, preprocess_recycle_mask};
                    REG_PRE_PROGRESS:
                        rdata <= {21'd0, preprocess_completed_channels,
                                  preprocess_active_channel,
                                  preprocess_active_arena};
                    REG_PRE_ACTIVE_BASE:
                        rdata <= preprocess_active_tensor_base;
                    REG_PRE_ARENA0_BATCH_LO:
                        rdata <= preprocess_arena0_batch_id[31:0];
                    REG_PRE_ARENA0_BATCH_HI:
                        rdata <= preprocess_arena0_batch_id[63:32];
                    REG_PRE_ARENA1_BATCH_LO:
                        rdata <= preprocess_arena1_batch_id[31:0];
                    REG_PRE_ARENA1_BATCH_HI:
                        rdata <= preprocess_arena1_batch_id[63:32];
                    REG_PRE_ARENA0_VALID:
                        rdata <= {{(32-CHANNELS){1'b0}},
                                  preprocess_arena0_valid_mask};
                    REG_PRE_ARENA1_VALID:
                        rdata <= {{(32-CHANNELS){1'b0}},
                                  preprocess_arena1_valid_mask};
                    REG_PRE_ARENA0_FRESH:
                        rdata <= {{(32-CHANNELS){1'b0}},
                                  preprocess_arena0_fresh_mask};
                    REG_PRE_ARENA1_FRESH:
                        rdata <= {{(32-CHANNELS){1'b0}},
                                  preprocess_arena1_fresh_mask};
                    REG_PRE_LAST_CYCLES:
                        rdata <= preprocess_last_batch_cycles;
                    REG_PRE_LAST_READ:
                        rdata <= preprocess_last_read_beats;
                    REG_PRE_LAST_WRITE:
                        rdata <= preprocess_last_write_beats;
                    REG_PRE_START_COUNT:
                        rdata <= preprocess_start_count;
                    REG_PRE_COMPLETE_COUNT:
                        rdata <= preprocess_complete_count;
                    REG_PRE_ERROR_COUNT:
                        rdata <= preprocess_error_count;
                    REG_PRE_ARENA0_BASE: rdata <= preprocess_arena0_base;
                    REG_PRE_ARENA1_BASE: rdata <= preprocess_arena1_base;
                    REG_PRE_MEMBER_STRIDE: rdata <= preprocess_member_stride;
                    REG_PRE_MEMBER_BYTES: rdata <= preprocess_member_bytes;
                    REG_OVERLAY_CONTROL:
                        rdata <= {30'd0, overlay_commit_busy,
                                  overlay_commit_toggle};
                    REG_OVERLAY_STREAM: rdata <= {28'd0, overlay_stream};
                    REG_OVERLAY_COUNT: rdata <= {28'd0, overlay_count};
                    REG_OVERLAY_BOX_INDEX:
                        rdata <= {29'd0, overlay_box_index};
                    REG_OVERLAY_BOX_XY0:
                        rdata <= overlay_boxes[overlay_box_index*64 +: 32];
                    REG_OVERLAY_BOX_XY1:
                        rdata <= overlay_boxes[
                            overlay_box_index*64 + 32 +: 32];
                    REG_OVERLAY_BOX_CLASS:
                        rdata <= {24'd0, overlay_boxes[
                            overlay_box_index*64 + 44 +: 8]};
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
                    REG_HDMI_TRANSPORT_FRAMES:
                        rdata <= hdmi_transport_frame_count;
                    REG_HDMI_TRANSPORT_MALFORMED:
                        rdata <= hdmi_transport_malformed_count;
                    default: begin
                        if ((axil.araddr[9:0] >= REG_WRITER0) &&
                            (axil.araddr[9:0] < REG_WRITER0 + CHANNELS*4))
                            rdata <= writer_frame_counts[
                                ((axil.araddr[9:0]-REG_WRITER0)>>2)*32 +: 32];
                        else if ((axil.araddr[9:0] >= REG_DROP0) &&
                                 (axil.araddr[9:0] < REG_DROP0 + CHANNELS*4))
                            rdata <= drop_counts[
                                ((axil.araddr[9:0]-REG_DROP0)>>2)*32 +: 32];
                        else if ((axil.araddr[9:0] >= REG_MALFORMED0) &&
                                 (axil.araddr[9:0] <
                                  REG_MALFORMED0 + CHANNELS*4))
                            rdata <= malformed_counts[
                                ((axil.araddr[9:0]-REG_MALFORMED0)>>2)*32 +: 32];
                        else if ((axil.araddr[9:0] >= REG_HDMI_FRAME0) &&
                                 (axil.araddr[9:0] < REG_HDMI_FRAME0 + 8*4))
                            rdata <= hdmi_channel_frame_counts[
                                ((axil.araddr[9:0]-REG_HDMI_FRAME0)>>2)*32
                                +: 32];
                        else if ((axil.araddr[9:0] >= REG_HDMI_OVERFLOW0) &&
                                 (axil.araddr[9:0] <
                                  REG_HDMI_OVERFLOW0 + 8*4))
                            rdata <= hdmi_channel_overflow_counts[
                                ((axil.araddr[9:0]-REG_HDMI_OVERFLOW0)>>2)*32
                                +: 32];
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
