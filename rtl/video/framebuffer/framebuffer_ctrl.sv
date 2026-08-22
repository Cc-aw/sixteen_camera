`timescale 1ns/1ps

// CPU clock-domain register bank for the video frame-buffer manager.
// Configuration registers are locked from commit until the UI domain
// acknowledges it, allowing the manager to safely sample the multi-bit bus.
module framebuffer_ctrl #(
    parameter integer MAX_BUFFERS = 4
) (
    axi_lite_if.slave axil,
    output reg                         cfg_request_toggle,
    output reg                         cfg_enable,
    output reg [31:0]                  cfg_width,
    output reg [31:0]                  cfg_height,
    output reg [31:0]                  cfg_stride_bytes,
    output reg [31:0]                  cfg_buffer_count,
    output reg [MAX_BUFFERS*32-1:0]    cfg_buffer_bases,
    input  wire                        cfg_ack_toggle,
    input  wire [31:0]                 manager_status,
    input  wire [31:0]                 writer_frame_count,
    input  wire [31:0]                 reader_frame_count,
    input  wire [31:0]                 drop_count,
    input  wire [31:0]                 underflow_count,
    input  wire [31:0]                 reader_active_base,
    input  wire [31:0]                 reader_debug_status,
    input  wire [31:0]                 malformed_frame_count,
    input  wire [479:0]                camera_axis_diag
);
    localparam [7:0] REG_CONTROL       = 8'h00;
    localparam [7:0] REG_STATUS        = 8'h04;
    localparam [7:0] REG_FRAME_WIDTH   = 8'h08;
    localparam [7:0] REG_FRAME_HEIGHT  = 8'h0c;
    localparam [7:0] REG_STRIDE_BYTES  = 8'h10;
    localparam [7:0] REG_BUFFER_COUNT  = 8'h14;
    localparam [7:0] REG_BUFFER_BASE0  = 8'h20;
    localparam [7:0] REG_BUFFER_BASE_END = 8'(8'h20 + (MAX_BUFFERS * 4));
    localparam [7:0] REG_WRITER_COUNT  = 8'h80;
    localparam [7:0] REG_READER_COUNT  = 8'h84;
    localparam [7:0] REG_DROP_COUNT    = 8'h88;
    localparam [7:0] REG_UNDERFLOW     = 8'h8c;
    localparam [7:0] REG_READER_BASE   = 8'h90;
    localparam [7:0] REG_READER_DEBUG  = 8'h94;
    localparam [7:0] REG_MALFORMED     = 8'h98;
    localparam [7:0] REG_CAMERA_DIAG0  = 8'ha0;

    reg [7:0] awaddr_hold;
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
    wire write_complete = !bvalid &&
                          (aw_pending || aw_fire) &&
                          (w_pending || w_fire);
    wire [7:0] write_addr = aw_pending ? awaddr_hold : axil.awaddr[7:0];
    wire [31:0] write_data = w_pending ? wdata_hold : axil.wdata;
    wire [3:0] write_strb = w_pending ? wstrb_hold : axil.wstrb;
    wire cfg_busy = (cfg_request_toggle != ack_sync_2);
    wire write_is_buffer_base = (write_addr >= REG_BUFFER_BASE0) &&
                                (write_addr < REG_BUFFER_BASE_END) &&
                                (write_addr[1:0] == 2'b00);
    wire [7:0] write_buffer_index = (write_addr - REG_BUFFER_BASE0) >> 2;
    wire [7:0] read_buffer_index = (axil.araddr[7:0] - REG_BUFFER_BASE0) >> 2;
    wire read_is_buffer_base = (axil.araddr[7:0] >= REG_BUFFER_BASE0) &&
                               (axil.araddr[7:0] < REG_BUFFER_BASE_END) &&
                               (axil.araddr[1:0] == 2'b00);

    function automatic [31:0] apply_wstrb;
        input [31:0] old_value;
        input [31:0] new_value;
        input [3:0] strb;
        integer byte_index;
        begin
            apply_wstrb = old_value;
            for (byte_index = 0; byte_index < 4; byte_index = byte_index + 1)
                if (strb[byte_index])
                    apply_wstrb[byte_index*8 +: 8] = new_value[byte_index*8 +: 8];
        end
    endfunction

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
            cfg_width <= 32'd1920;
            cfg_height <= 32'd1080;
            cfg_stride_bytes <= 32'd7680;
            cfg_buffer_count <= 32'd3;
            cfg_buffer_bases <= {MAX_BUFFERS*32{1'b0}};
            awaddr_hold <= 8'd0;
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
                awaddr_hold <= axil.awaddr[7:0];
                aw_pending <= 1'b1;
            end
            if (w_fire) begin
                wdata_hold <= axil.wdata;
                wstrb_hold <= axil.wstrb;
                w_pending <= 1'b1;
            end

            if (write_complete) begin
                case (write_addr)
                    REG_CONTROL: begin
                        if (write_strb[0] && !cfg_busy) begin
                            cfg_enable <= write_data[0];
                            if (write_data[2])
                                cfg_request_toggle <= !cfg_request_toggle;
                        end
                    end
                    REG_FRAME_WIDTH:
                        if (!cfg_busy)
                            cfg_width <= apply_wstrb(cfg_width, write_data, write_strb);
                    REG_FRAME_HEIGHT:
                        if (!cfg_busy)
                            cfg_height <= apply_wstrb(cfg_height, write_data, write_strb);
                    REG_STRIDE_BYTES:
                        if (!cfg_busy)
                            cfg_stride_bytes <= apply_wstrb(cfg_stride_bytes, write_data, write_strb);
                    REG_BUFFER_COUNT:
                        if (!cfg_busy)
                            cfg_buffer_count <= apply_wstrb(cfg_buffer_count, write_data, write_strb);
                    default: begin
                        if (write_is_buffer_base && !cfg_busy)
                            cfg_buffer_bases[write_buffer_index * 32 +: 32] <=
                                apply_wstrb(cfg_buffer_bases[write_buffer_index * 32 +: 32],
                                            write_data, write_strb);
                    end
                endcase
                aw_pending <= 1'b0;
                w_pending <= 1'b0;
                bvalid <= 1'b1;
            end else if (bvalid && axil.bready) begin
                bvalid <= 1'b0;
            end

            if (axil.arready && axil.arvalid) begin
                case (axil.araddr[7:0])
                    REG_CONTROL:      rdata <= {29'd0, 1'b0, cfg_request_toggle, cfg_enable};
                    REG_STATUS:       rdata <= {manager_status[31:1], cfg_busy};
                    REG_FRAME_WIDTH:  rdata <= cfg_width;
                    REG_FRAME_HEIGHT: rdata <= cfg_height;
                    REG_STRIDE_BYTES: rdata <= cfg_stride_bytes;
                    REG_BUFFER_COUNT: rdata <= cfg_buffer_count;
                    REG_WRITER_COUNT: rdata <= writer_frame_count;
                    REG_READER_COUNT: rdata <= reader_frame_count;
                    REG_DROP_COUNT:   rdata <= drop_count;
                    REG_UNDERFLOW:    rdata <= underflow_count;
                    REG_READER_BASE:  rdata <= reader_active_base;
                    REG_READER_DEBUG: rdata <= reader_debug_status;
                    REG_MALFORMED:    rdata <= malformed_frame_count;
                    default: begin
                        if ((axil.araddr[7:0] >= REG_CAMERA_DIAG0) &&
                            (axil.araddr[7:0] <= 8'hd8) &&
                            (axil.araddr[1:0] == 2'b00))
                            rdata <= camera_axis_diag[
                                ((axil.araddr[7:0] - REG_CAMERA_DIAG0) >> 2) * 32 +: 32];
                        else if (read_is_buffer_base)
                            rdata <= cfg_buffer_bases[read_buffer_index * 32 +: 32];
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
