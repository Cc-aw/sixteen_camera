`timescale 1ns/1ps

module detection_overlay #(
    parameter integer STREAMS = 16,
    parameter integer BOXES_PER_STREAM = 8,
    parameter integer FRAME_WIDTH = 1920,
    parameter integer FRAME_HEIGHT = 1080
) (
    input  wire clk,
    input  wire resetn,
    input  wire enable,
    input  wire cfg_commit,
    input  wire [3:0] cfg_stream,
    input  wire [3:0] cfg_count,
    input  wire [BOXES_PER_STREAM*64-1:0] cfg_boxes,
    input  wire [47:0] s_tdata,
    input  wire s_tvalid,
    output wire s_tready,
    input  wire s_tuser,
    input  wire s_tlast,
    output wire [47:0] m_tdata,
    output wire m_tvalid,
    input  wire m_tready,
    output wire m_tuser,
    output wire m_tlast
);
    localparam integer TOTAL_BOXES = STREAMS * BOXES_PER_STREAM;

    reg [10:0] shadow_x_min [0:TOTAL_BOXES-1];
    reg [10:0] shadow_y_min [0:TOTAL_BOXES-1];
    reg [10:0] shadow_x_max [0:TOTAL_BOXES-1];
    reg [10:0] shadow_y_max [0:TOTAL_BOXES-1];
    reg [7:0] shadow_class [0:TOTAL_BOXES-1];
    reg [3:0] shadow_count [0:STREAMS-1];
    reg [10:0] active_x_min [0:TOTAL_BOXES-1];
    reg [10:0] active_y_min [0:TOTAL_BOXES-1];
    reg [10:0] active_x_max [0:TOTAL_BOXES-1];
    reg [10:0] active_y_max [0:TOTAL_BOXES-1];
    reg [7:0] active_class [0:TOTAL_BOXES-1];
    reg [3:0] active_count [0:STREAMS-1];
    reg [STREAMS-1:0] pending_streams;

    reg [10:0] input_x;
    reg [10:0] input_y;
    reg [47:0] output_data;
    reg output_valid;
    reg output_user;
    reg output_last;

    integer index;
    integer stream;
    integer box;

    function automatic [23:0] class_color;
        input [7:0] class_id;
        begin
            case (class_id[2:0])
                3'd0: class_color = 24'h00ff00;
                3'd1: class_color = 24'hff3030;
                3'd2: class_color = 24'h30a0ff;
                3'd3: class_color = 24'hffff00;
                3'd4: class_color = 24'hff40ff;
                3'd5: class_color = 24'h00ffff;
                3'd6: class_color = 24'hff8000;
                default: class_color = 24'hffffff;
            endcase
        end
    endfunction

    function automatic pixel_hits_box;
        input [10:0] x;
        input [10:0] y;
        input [10:0] x_min;
        input [10:0] y_min;
        input [10:0] x_max;
        input [10:0] y_max;
        begin
            pixel_hits_box = (x >= x_min) && (x < x_max) &&
                (y >= y_min) && (y < y_max) &&
                ((x < x_min + 2) || (x + 2 >= x_max) ||
                 (y < y_min + 2) || (y + 2 >= y_max));
        end
    endfunction

    wire output_ready = !output_valid || m_tready;
    assign s_tready = output_ready;
    assign m_tdata = output_data;
    assign m_tvalid = output_valid;
    assign m_tuser = output_user;
    assign m_tlast = output_last;

    reg [47:0] decorated_data;
    reg hit0;
    reg hit1;
    reg [23:0] color0;
    reg [23:0] color1;
    reg [10:0] effective_x;
    reg [10:0] effective_y;
    reg [3:0] effective_stream;
    integer selected_index;

    always @* begin
        effective_x = s_tuser ? 11'd0 : input_x;
        effective_y = s_tuser ? 11'd0 : input_y;
        effective_stream = (effective_y / 270) * 4 +
                           (effective_x / 480);
        decorated_data = s_tdata;
        hit0 = 1'b0;
        hit1 = 1'b0;
        color0 = 24'd0;
        color1 = 24'd0;
        for (box = 0; box < BOXES_PER_STREAM; box = box + 1) begin
            selected_index = effective_stream * BOXES_PER_STREAM + box;
            if (enable && box < active_count[effective_stream]) begin
                if (!hit0 && pixel_hits_box(effective_x, effective_y,
                    active_x_min[selected_index], active_y_min[selected_index],
                    active_x_max[selected_index], active_y_max[selected_index])) begin
                    hit0 = 1'b1;
                    color0 = class_color(active_class[selected_index]);
                end
                if (!hit1 && pixel_hits_box(effective_x + 1'b1, effective_y,
                    active_x_min[selected_index], active_y_min[selected_index],
                    active_x_max[selected_index], active_y_max[selected_index])) begin
                    hit1 = 1'b1;
                    color1 = class_color(active_class[selected_index]);
                end
            end
        end
        if (hit0)
            decorated_data[23:0] = color0;
        if (hit1)
            decorated_data[47:24] = color1;
    end

    always @(posedge clk) begin
        if (!resetn) begin
            input_x <= 11'd0;
            input_y <= 11'd0;
            output_data <= 48'd0;
            output_valid <= 1'b0;
            output_user <= 1'b0;
            output_last <= 1'b0;
            pending_streams <= {STREAMS{1'b0}};
            for (stream = 0; stream < STREAMS; stream = stream + 1) begin
                shadow_count[stream] <= 4'd0;
                active_count[stream] <= 4'd0;
            end
            for (index = 0; index < TOTAL_BOXES; index = index + 1) begin
                shadow_x_min[index] <= 11'd0;
                shadow_y_min[index] <= 11'd0;
                shadow_x_max[index] <= 11'd0;
                shadow_y_max[index] <= 11'd0;
                shadow_class[index] <= 8'd0;
                active_x_min[index] <= 11'd0;
                active_y_min[index] <= 11'd0;
                active_x_max[index] <= 11'd0;
                active_y_max[index] <= 11'd0;
                active_class[index] <= 8'd0;
            end
        end else begin
            if (cfg_commit && cfg_stream < STREAMS) begin
                shadow_count[cfg_stream] <=
                    cfg_count > BOXES_PER_STREAM ? BOXES_PER_STREAM : cfg_count;
                pending_streams[cfg_stream] <= 1'b1;
                for (index = 0; index < BOXES_PER_STREAM; index = index + 1) begin
                    shadow_x_min[cfg_stream*BOXES_PER_STREAM + index] <=
                        cfg_boxes[index*64 +: 11];
                    shadow_y_min[cfg_stream*BOXES_PER_STREAM + index] <=
                        cfg_boxes[index*64 + 11 +: 11];
                    shadow_x_max[cfg_stream*BOXES_PER_STREAM + index] <=
                        cfg_boxes[index*64 + 22 +: 11];
                    shadow_y_max[cfg_stream*BOXES_PER_STREAM + index] <=
                        cfg_boxes[index*64 + 33 +: 11];
                    shadow_class[cfg_stream*BOXES_PER_STREAM + index] <=
                        cfg_boxes[index*64 + 44 +: 8];
                end
            end

            if (s_tvalid && s_tready && s_tlast &&
                effective_y == FRAME_HEIGHT-1) begin
                for (stream = 0; stream < STREAMS; stream = stream + 1) begin
                    if (pending_streams[stream]) begin
                        active_count[stream] <= shadow_count[stream];
                        pending_streams[stream] <= 1'b0;
                        for (index = 0; index < BOXES_PER_STREAM;
                             index = index + 1) begin
                            active_x_min[stream*BOXES_PER_STREAM + index] <=
                                shadow_x_min[stream*BOXES_PER_STREAM + index];
                            active_y_min[stream*BOXES_PER_STREAM + index] <=
                                shadow_y_min[stream*BOXES_PER_STREAM + index];
                            active_x_max[stream*BOXES_PER_STREAM + index] <=
                                shadow_x_max[stream*BOXES_PER_STREAM + index];
                            active_y_max[stream*BOXES_PER_STREAM + index] <=
                                shadow_y_max[stream*BOXES_PER_STREAM + index];
                            active_class[stream*BOXES_PER_STREAM + index] <=
                                shadow_class[stream*BOXES_PER_STREAM + index];
                        end
                    end
                end
            end

            if (output_ready) begin
                output_valid <= s_tvalid;
                if (s_tvalid) begin
                    output_data <= decorated_data;
                    output_user <= s_tuser;
                    output_last <= s_tlast;
                end else begin
                    output_user <= 1'b0;
                    output_last <= 1'b0;
                end
            end

            if (s_tvalid && s_tready) begin
                if (s_tlast) begin
                    input_x <= 11'd0;
                    input_y <= effective_y == FRAME_HEIGHT-1 ?
                               11'd0 : effective_y + 1'b1;
                end else begin
        input_x <= effective_x + 2'd2;
                    input_y <= effective_y;
                end
            end
        end
    end

    initial begin
        if (STREAMS != 16 || BOXES_PER_STREAM != 8 ||
            FRAME_WIDTH != 1920 || FRAME_HEIGHT != 1080)
            $error("detection_overlay currently requires 16 streams, 8 boxes, 1080p");
    end
endmodule
