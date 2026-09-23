`timescale 1ns/1ps

// Software-written overlay command buffer.
module overlay_csr #(
    parameter integer CHANNELS = 16
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
    output reg  overlay_commit_toggle,
    output reg  [3:0] overlay_stream,
    output reg  [3:0] overlay_count,
    output reg  [8*64-1:0] overlay_boxes,
    output reg  [8*128-1:0] overlay_labels,
    input  wire overlay_commit_ack_toggle
);
    localparam [9:0] REG_CONTROL = 10'h260;
    localparam [9:0] REG_STREAM = 10'h264;
    localparam [9:0] REG_COUNT = 10'h268;
    localparam [9:0] REG_BOX_INDEX = 10'h26c;
    localparam [9:0] REG_BOX_XY0 = 10'h270;
    localparam [9:0] REG_BOX_XY1 = 10'h274;
    localparam [9:0] REG_BOX_CLASS = 10'h278;
    localparam [9:0] REG_LABEL0 = 10'h294;
    localparam [9:0] REG_LABEL1 = 10'h298;
    localparam [9:0] REG_LABEL2 = 10'h29c;
    localparam [9:0] REG_LABEL3 = 10'h2a0;
    localparam [4:0] CHANNEL_COUNT = 5'(CHANNELS);

    reg [2:0] overlay_box_index;
    wire commit_busy = overlay_commit_toggle != overlay_commit_ack_toggle;

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

    always @(posedge clk) begin
        if (!resetn) begin
            overlay_commit_toggle <= 1'b0;
            overlay_stream <= 4'd0;
            overlay_count <= 4'd0;
            overlay_boxes <= 512'd0;
            overlay_labels <= 1024'd0;
            overlay_box_index <= 3'd0;
        end else if (write_valid) begin
            case (write_addr)
                REG_CONTROL: if (write_strb[0] && write_data[0] &&
                                 !commit_busy &&
                                 {1'b0, overlay_stream} < CHANNEL_COUNT &&
                                 overlay_count <= 8)
                    overlay_commit_toggle <= !overlay_commit_toggle;
                REG_STREAM: if (write_strb[0] && !commit_busy &&
                               write_data < CHANNELS)
                    overlay_stream <= write_data[3:0];
                REG_COUNT: if (write_strb[0] && !commit_busy &&
                              write_data <= 8)
                    overlay_count <= write_data[3:0];
                REG_BOX_INDEX: if (write_strb[0] && !commit_busy &&
                                  write_data < 8)
                    overlay_box_index <= write_data[2:0];
                REG_BOX_XY0: if (!commit_busy)
                    overlay_boxes[overlay_box_index*64 +: 32] <= apply_wstrb(
                        overlay_boxes[overlay_box_index*64 +: 32],
                        write_data, write_strb);
                REG_BOX_XY1: if (!commit_busy)
                    overlay_boxes[overlay_box_index*64 + 32 +: 32] <=
                        apply_wstrb(
                            overlay_boxes[overlay_box_index*64 + 32 +: 32],
                            write_data, write_strb);
                REG_BOX_CLASS: if (!commit_busy)
                    overlay_boxes[overlay_box_index*64 + 44 +: 8] <=
                        write_data[7:0];
                REG_LABEL0: if (!commit_busy)
                    overlay_labels[overlay_box_index*128 +: 32] <= apply_wstrb(
                        overlay_labels[overlay_box_index*128 +: 32],
                        write_data, write_strb);
                REG_LABEL1: if (!commit_busy)
                    overlay_labels[overlay_box_index*128 + 32 +: 32] <=
                        apply_wstrb(
                            overlay_labels[overlay_box_index*128 + 32 +: 32],
                            write_data, write_strb);
                REG_LABEL2: if (!commit_busy)
                    overlay_labels[overlay_box_index*128 + 64 +: 32] <=
                        apply_wstrb(
                            overlay_labels[overlay_box_index*128 + 64 +: 32],
                            write_data, write_strb);
                REG_LABEL3: if (!commit_busy)
                    overlay_labels[overlay_box_index*128 + 96 +: 32] <=
                        apply_wstrb(
                            overlay_labels[overlay_box_index*128 + 96 +: 32],
                            write_data, write_strb);
                default: begin end
            endcase
        end
    end

    always @* begin
        read_hit = 1'b1;
        case (read_addr)
            REG_CONTROL:
                read_data = {30'd0, commit_busy, overlay_commit_toggle};
            REG_STREAM: read_data = {28'd0, overlay_stream};
            REG_COUNT: read_data = {28'd0, overlay_count};
            REG_BOX_INDEX: read_data = {29'd0, overlay_box_index};
            REG_BOX_XY0:
                read_data = overlay_boxes[overlay_box_index*64 +: 32];
            REG_BOX_XY1:
                read_data = overlay_boxes[
                    overlay_box_index*64 + 32 +: 32];
            REG_BOX_CLASS:
                read_data = {24'd0, overlay_boxes[
                    overlay_box_index*64 + 44 +: 8]};
            REG_LABEL0:
                read_data = overlay_labels[overlay_box_index*128 +: 32];
            REG_LABEL1:
                read_data = overlay_labels[
                    overlay_box_index*128 + 32 +: 32];
            REG_LABEL2:
                read_data = overlay_labels[
                    overlay_box_index*128 + 64 +: 32];
            REG_LABEL3:
                read_data = overlay_labels[
                    overlay_box_index*128 + 96 +: 32];
            default: begin
                read_hit = 1'b0;
                read_data = 32'd0;
            end
        endcase
    end
endmodule
