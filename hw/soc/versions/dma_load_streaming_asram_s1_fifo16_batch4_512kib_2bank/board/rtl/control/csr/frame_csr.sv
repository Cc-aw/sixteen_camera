`timescale 1ns/1ps

// Frame-store geometry and buffer layout registers.  Configuration is held
// stable while the video-domain mailbox transaction is outstanding.
module frame_csr #(
    parameter integer CHANNELS = 16,
    parameter integer GLOBAL_CHANNEL_BASE = 0,
    parameter [CHANNELS-1:0] CAMERA_PRESENT_MASK =
        {{(CHANNELS-1){1'b0}}, 1'b1},
    parameter [CHANNELS*32-1:0] DEFAULT_CHANNEL_BASES =
        {CHANNELS{32'h0800_0000}}
) (
    input  wire clk,
    input  wire resetn,
    input  wire write_valid,
    input  wire [9:0] write_addr,
    input  wire [31:0] write_data,
    input  wire [3:0] write_strb,
    input  wire [9:0] read_addr,
    output reg  read_hit,
    output reg  [31:0] read_data,
    output reg  cfg_request_toggle,
    output reg  cfg_enable,
    output reg  [31:0] cfg_width,
    output reg  [31:0] cfg_height,
    output reg  [31:0] cfg_stride_bytes,
    output reg  [31:0] cfg_buffers_per_channel,
    output reg  [CHANNELS*32-1:0] cfg_channel_bases,
    output reg  [31:0] cfg_buffer_stride_bytes,
    input  wire cfg_ack_toggle,
    input  wire [31:0] manager_status
);
    localparam integer CHANNEL_WIDTH = CHANNELS <= 1 ? 1 : $clog2(CHANNELS);
    localparam [9:0] REG_CONTROL = 10'h000;
    localparam [9:0] REG_STATUS = 10'h004;
    localparam [9:0] REG_WIDTH = 10'h008;
    localparam [9:0] REG_HEIGHT = 10'h00c;
    localparam [9:0] REG_STRIDE = 10'h010;
    localparam [9:0] REG_SLOT_COUNT = 10'h014;
    localparam [9:0] REG_PRESENT_MASK = 10'h01c;
    localparam [9:0] REG_CHANNEL_BASE0 = 10'h020;
    localparam [9:0] REG_BUFFER_STRIDE = 10'h060;
    localparam [9:0] REG_CHANNEL_BASE_END =
        REG_CHANNEL_BASE0 + 10'(CHANNELS*4);

    (* ASYNC_REG = "TRUE" *) reg ack_sync_1;
    (* ASYNC_REG = "TRUE" *) reg ack_sync_2;
    wire cfg_busy = cfg_request_toggle != ack_sync_2;
    wire write_is_channel_base = write_addr >= REG_CHANNEL_BASE0 &&
        write_addr < REG_CHANNEL_BASE_END &&
        write_addr[1:0] == 2'b00;
    wire read_is_channel_base = read_addr >= REG_CHANNEL_BASE0 &&
        read_addr < REG_CHANNEL_BASE_END &&
        read_addr[1:0] == 2'b00;
    wire [9:0] write_channel_offset = write_addr - REG_CHANNEL_BASE0;
    wire [9:0] read_channel_offset = read_addr - REG_CHANNEL_BASE0;
    wire [CHANNEL_WIDTH-1:0] write_channel =
        write_channel_offset[CHANNEL_WIDTH+1:2];
    wire [CHANNEL_WIDTH-1:0] read_channel =
        read_channel_offset[CHANNEL_WIDTH+1:2];

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

    initial begin
        if (CHANNELS > 16 || REG_CHANNEL_BASE_END > REG_BUFFER_STRIDE)
            $error("frame_csr channel register range overlaps");
    end

    always @(posedge clk) begin
        if (!resetn) begin
            cfg_request_toggle <= 1'b0;
            cfg_enable <= 1'b0;
            cfg_width <= 32'd640;
            cfg_height <= 32'd480;
            cfg_stride_bytes <= 32'd2560;
            cfg_buffers_per_channel <= 32'd5;
            cfg_channel_bases <= DEFAULT_CHANNEL_BASES;
            cfg_buffer_stride_bytes <= 32'h0040_0000;
            ack_sync_1 <= 1'b0;
            ack_sync_2 <= 1'b0;
        end else begin
            ack_sync_1 <= cfg_ack_toggle;
            ack_sync_2 <= ack_sync_1;
            if (write_valid) begin
                case (write_addr)
                    REG_CONTROL: if (write_strb[0] && !cfg_busy) begin
                        cfg_enable <= write_data[0];
                        if (write_data[2])
                            cfg_request_toggle <= !cfg_request_toggle;
                    end
                    REG_WIDTH: if (!cfg_busy)
                        cfg_width <= apply_wstrb(cfg_width, write_data,
                                                write_strb);
                    REG_HEIGHT: if (!cfg_busy)
                        cfg_height <= apply_wstrb(cfg_height, write_data,
                                                 write_strb);
                    REG_STRIDE: if (!cfg_busy)
                        cfg_stride_bytes <= apply_wstrb(cfg_stride_bytes,
                                                       write_data, write_strb);
                    REG_SLOT_COUNT: if (!cfg_busy)
                        cfg_buffers_per_channel <= apply_wstrb(
                            cfg_buffers_per_channel, write_data, write_strb);
                    REG_BUFFER_STRIDE: if (!cfg_busy)
                        cfg_buffer_stride_bytes <= apply_wstrb(
                            cfg_buffer_stride_bytes, write_data, write_strb);
                    default: if (write_is_channel_base && !cfg_busy)
                        cfg_channel_bases[write_channel*32 +: 32] <=
                            apply_wstrb(
                                cfg_channel_bases[write_channel*32 +: 32],
                                write_data, write_strb);
                endcase
            end
        end
    end

    always @* begin
        read_hit = 1'b1;
        case (read_addr)
            REG_CONTROL: read_data = {29'd0, 1'b0,
                                      cfg_request_toggle, cfg_enable};
            REG_STATUS: read_data = {manager_status[31:1], cfg_busy};
            REG_WIDTH: read_data = cfg_width;
            REG_HEIGHT: read_data = cfg_height;
            REG_STRIDE: read_data = cfg_stride_bytes;
            REG_SLOT_COUNT: read_data = cfg_buffers_per_channel;
            REG_PRESENT_MASK:
                read_data = {{(32-CHANNELS){1'b0}}, CAMERA_PRESENT_MASK};
            REG_BUFFER_STRIDE: read_data = cfg_buffer_stride_bytes;
            default: begin
                if (read_is_channel_base)
                    read_data = cfg_channel_bases[read_channel*32 +: 32];
                else begin
                    read_hit = 1'b0;
                    read_data = 32'd0;
                end
            end
        endcase
    end
endmodule
