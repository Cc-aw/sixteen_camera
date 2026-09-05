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
    reg [47:0] stage0_data;
    reg [10:0] stage0_x;
    reg [10:0] stage0_y;
    reg [3:0] stage0_stream;
    reg stage0_valid;
    reg stage0_user;
    reg stage0_last;
    reg [47:0] stage1_data;
    reg [BOXES_PER_STREAM-1:0] stage1_hits0;
    reg [BOXES_PER_STREAM-1:0] stage1_hits1;
    reg [7:0] stage1_class [0:BOXES_PER_STREAM-1];
    reg stage1_valid;
    reg stage1_user;
    reg stage1_last;
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
    wire stage1_ready = !stage1_valid || output_ready;
    wire stage0_ready = !stage0_valid || stage1_ready;
    assign s_tready = stage0_ready;
    assign m_tdata = output_data;
    assign m_tvalid = output_valid;
    assign m_tuser = output_user;
    assign m_tlast = output_last;

    reg [47:0] decorated_data;
    reg selected_hit0;
    reg selected_hit1;
    reg [3:0] incoming_stream;
    integer selected_index;

    always @* begin
        if ((s_tuser ? 11'd0 : input_y) >= 11'd810)
            incoming_stream = 4'd12;
        else if ((s_tuser ? 11'd0 : input_y) >= 11'd540)
            incoming_stream = 4'd8;
        else if ((s_tuser ? 11'd0 : input_y) >= 11'd270)
            incoming_stream = 4'd4;
        else
            incoming_stream = 4'd0;
        if ((s_tuser ? 11'd0 : input_x) >= 11'd1440)
            incoming_stream = incoming_stream + 4'd3;
        else if ((s_tuser ? 11'd0 : input_x) >= 11'd960)
            incoming_stream = incoming_stream + 4'd2;
        else if ((s_tuser ? 11'd0 : input_x) >= 11'd480)
            incoming_stream = incoming_stream + 4'd1;
    end

    always @* begin
        decorated_data = stage1_data;
        selected_hit0 = 1'b0;
        selected_hit1 = 1'b0;
        for (box = 0; box < BOXES_PER_STREAM; box = box + 1) begin
            if (!selected_hit0 && stage1_hits0[box]) begin
                selected_hit0 = 1'b1;
                decorated_data[23:0] = class_color(stage1_class[box]);
            end
            if (!selected_hit1 && stage1_hits1[box]) begin
                selected_hit1 = 1'b1;
                decorated_data[47:24] = class_color(stage1_class[box]);
            end
        end
    end

    always @(posedge clk) begin
        if (!resetn) begin
            input_x <= 11'd0;
            input_y <= 11'd0;
            stage0_valid <= 1'b0;
            stage1_valid <= 1'b0;
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
                (s_tuser ? 11'd0 : input_y) == FRAME_HEIGHT-1) begin
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
                output_valid <= stage1_valid;
                if (stage1_valid) begin
                    output_data <= decorated_data;
                    output_user <= stage1_user;
                    output_last <= stage1_last;
                end else begin
                    output_user <= 1'b0;
                    output_last <= 1'b0;
                end
            end

            if (stage1_ready) begin
                stage1_valid <= stage0_valid;
                if (stage0_valid) begin
                    stage1_data <= stage0_data;
                    stage1_user <= stage0_user;
                    stage1_last <= stage0_last;
                    for (box = 0; box < BOXES_PER_STREAM; box = box + 1) begin
                        selected_index = stage0_stream * BOXES_PER_STREAM + box;
                        stage1_hits0[box] <= enable &&
                            box < active_count[stage0_stream] &&
                            pixel_hits_box(stage0_x, stage0_y,
                                active_x_min[selected_index], active_y_min[selected_index],
                                active_x_max[selected_index], active_y_max[selected_index]);
                        stage1_hits1[box] <= enable &&
                            box < active_count[stage0_stream] &&
                            pixel_hits_box(stage0_x + 1'b1, stage0_y,
                                active_x_min[selected_index], active_y_min[selected_index],
                                active_x_max[selected_index], active_y_max[selected_index]);
                        stage1_class[box] <= active_class[selected_index];
                    end
                end else begin
                    stage1_user <= 1'b0;
                    stage1_last <= 1'b0;
                end
            end

            if (stage0_ready) begin
                stage0_valid <= s_tvalid;
                if (s_tvalid) begin
                    stage0_data <= s_tdata;
                    stage0_x <= s_tuser ? 11'd0 : input_x;
                    stage0_y <= s_tuser ? 11'd0 : input_y;
                    stage0_stream <= incoming_stream;
                    stage0_user <= s_tuser;
                    stage0_last <= s_tlast;
                end else begin
                    stage0_user <= 1'b0;
                    stage0_last <= 1'b0;
                end
            end

            if (s_tvalid && s_tready) begin
                if (s_tlast) begin
                    input_x <= 11'd0;
                    input_y <= (s_tuser ? 11'd0 : input_y) == FRAME_HEIGHT-1 ?
                               11'd0 : (s_tuser ? 11'd0 : input_y) + 1'b1;
                end else begin
                    input_x <= (s_tuser ? 11'd0 : input_x) + 2'd2;
                    input_y <= s_tuser ? 11'd0 : input_y;
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
