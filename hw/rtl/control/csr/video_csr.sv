`timescale 1ns/1ps

// Display selection and HDMI capture controls.
module video_csr #(
    parameter integer CHANNELS = 16,
    parameter integer GLOBAL_CHANNEL_BASE = 0,
    parameter [CHANNELS-1:0] CAMERA_PRESENT_MASK =
        {{(CHANNELS-1){1'b0}}, 1'b1}
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
    output reg  [((CHANNELS <= 1) ? 1 : $clog2(CHANNELS))-1:0]
                    cfg_display_channel,
    output reg  cfg_display_mode,
    output reg  cfg_hdmi_capture_enable
);
    localparam integer CHANNEL_WIDTH = CHANNELS <= 1 ? 1 : $clog2(CHANNELS);
    localparam [9:0] REG_DISPLAY_CH = 10'h018;
    localparam [9:0] REG_DISPLAY_MODE = 10'h064;
    localparam [9:0] REG_HDMI_CONTROL = 10'h068;

    function automatic display_channel_present;
        input [CHANNEL_WIDTH-1:0] global_channel;
        integer local_channel;
        begin
            local_channel = 32'(global_channel);
            local_channel = local_channel - GLOBAL_CHANNEL_BASE;
            if (local_channel < 0 || local_channel >= CHANNELS)
                display_channel_present = 1'b0;
            else
                display_channel_present = CAMERA_PRESENT_MASK[local_channel];
        end
    endfunction

    always @(posedge clk) begin
        if (!resetn) begin
            cfg_display_channel <= CHANNEL_WIDTH'(GLOBAL_CHANNEL_BASE);
            cfg_display_mode <= 1'b0;
            cfg_hdmi_capture_enable <= 1'b0;
        end else if (write_valid) begin
            case (write_addr)
                REG_DISPLAY_CH: if (write_strb[0] &&
                                    display_channel_present(
                                        write_data[CHANNEL_WIDTH-1:0]))
                    cfg_display_channel <= write_data[CHANNEL_WIDTH-1:0];
                REG_DISPLAY_MODE: if (write_strb[0])
                    cfg_display_mode <= write_data[0];
                REG_HDMI_CONTROL: if (write_strb[0])
                    cfg_hdmi_capture_enable <= write_data[0];
                default: begin end
            endcase
        end
    end

    always @* begin
        read_hit = 1'b1;
        case (read_addr)
            REG_DISPLAY_CH:
                read_data = {{(32-CHANNEL_WIDTH){1'b0}},
                             cfg_display_channel};
            REG_DISPLAY_MODE: read_data = {31'd0, cfg_display_mode};
            REG_HDMI_CONTROL: read_data = {31'd0, cfg_hdmi_capture_enable};
            default: begin
                read_hit = 1'b0;
                read_data = 32'd0;
            end
        endcase
    end
endmodule
