`timescale 1ns/1ps

module detection_overlay #(
    parameter integer STREAMS = 16,
    parameter integer BOXES_PER_STREAM = 8,
    parameter integer FRAME_WIDTH = 1920,
    parameter integer FRAME_HEIGHT = 1080
) (
    input wire clk, input wire resetn, input wire enable,
    input wire cfg_commit, input wire [3:0] cfg_stream,
    input wire [3:0] cfg_count,
    input wire [BOXES_PER_STREAM*64-1:0] cfg_boxes,
    input wire [BOXES_PER_STREAM*128-1:0] cfg_labels,
    input wire [47:0] s_tdata, input wire s_tvalid,
    output wire s_tready, input wire s_tuser, input wire s_tlast,
    output wire [47:0] m_tdata, output wire m_tvalid,
    input wire m_tready, output wire m_tuser, output wire m_tlast
);
    localparam integer META_WIDTH = 180;
    localparam integer META_X_MIN_LSB = 0;
    localparam integer META_Y_MIN_LSB = 11;
    localparam integer META_X_MAX_LSB = 22;
    localparam integer META_Y_MAX_LSB = 33;
    localparam integer META_CLASS_LSB = 44;
    localparam integer META_LABEL_LSB = 52;
    localparam integer ENTRY_COUNT_LSB = BOXES_PER_STREAM * META_WIDTH;
    localparam integer ENTRY_WIDTH = ENTRY_COUNT_LSB + 4;
    localparam [10:0] TILE_WIDTH=11'd480, TILE_HEIGHT=11'd270;
    localparam [10:0] LABEL_WIDTH=11'd128, LABEL_HEIGHT=11'd16;

    // One packed 32-entry memory replaces the former active/shadow register
    // arrays. Address bit 4 selects one of two frame banks and bits 3:0 select
    // the stream. A frame-boundary bank swap is atomic and avoids copying or
    // resetting more than 46k metadata flip-flops.
    (* ram_style = "distributed" *) reg [ENTRY_WIDTH-1:0]
        metadata_mem [0:2*STREAMS-1];
    reg [STREAMS-1:0] active_bank;
    reg [STREAMS-1:0] active_valid;
    reg [STREAMS-1:0] pending_streams;

    reg [3:0] stage0_stream;
    wire [4:0] stage0_metadata_addr =
        {active_bank[stage0_stream], stage0_stream};
    wire [ENTRY_WIDTH-1:0] stage0_metadata_entry =
        metadata_mem[stage0_metadata_addr];
    wire [3:0] stage0_active_count = active_valid[stage0_stream] ?
        stage0_metadata_entry[ENTRY_COUNT_LSB +: 4] : 4'd0;
    wire [META_WIDTH-1:0] active_metadata [0:BOXES_PER_STREAM-1];
    wire [ENTRY_WIDTH-1:0] cfg_metadata_entry;
    assign cfg_metadata_entry[ENTRY_COUNT_LSB +: 4] =
        cfg_count > BOXES_PER_STREAM ? BOXES_PER_STREAM : cfg_count;
    genvar metadata_box;
    generate
        for (metadata_box = 0; metadata_box < BOXES_PER_STREAM;
             metadata_box = metadata_box + 1) begin : g_metadata_read
            assign active_metadata[metadata_box] =
                stage0_metadata_entry[metadata_box*META_WIDTH +: META_WIDTH];
            assign cfg_metadata_entry[metadata_box*META_WIDTH +: META_WIDTH] =
                {cfg_labels[metadata_box*128+:128],
                 cfg_boxes[metadata_box*64+44+:8],
                 cfg_boxes[metadata_box*64+33+:11],
                 cfg_boxes[metadata_box*64+22+:11],
                 cfg_boxes[metadata_box*64+11+:11],
                 cfg_boxes[metadata_box*64+:11]};
        end
    endgenerate

    reg [10:0] input_x, input_y;
    reg [47:0] stage0_data;
    reg [10:0] stage0_x, stage0_y;
    reg stage0_valid, stage0_user, stage0_last;

    reg [47:0] stage1_data;
    reg [BOXES_PER_STREAM-1:0] stage1_hits0, stage1_hits1;
    reg [BOXES_PER_STREAM-1:0] stage1_label_hit0, stage1_label_hit1;
    reg [7:0] stage1_char0[0:BOXES_PER_STREAM-1];
    reg [7:0] stage1_char1[0:BOXES_PER_STREAM-1];
    reg [2:0] stage1_char_x0[0:BOXES_PER_STREAM-1];
    reg [2:0] stage1_char_x1[0:BOXES_PER_STREAM-1];
    reg [3:0] stage1_label_y[0:BOXES_PER_STREAM-1];
    reg [7:0] stage1_class[0:BOXES_PER_STREAM-1];
    reg stage1_valid, stage1_user, stage1_last;

    reg [47:0] stage2_data;
    reg stage2_hit0, stage2_hit1, stage2_label_hit0, stage2_label_hit1;
    reg [2:0] stage2_char_x0, stage2_char_x1;
    reg [3:0] stage2_label_y0, stage2_label_y1;
    reg [34:0] stage2_glyph0, stage2_glyph1;
    reg [23:0] stage2_color0, stage2_color1;
    reg stage2_valid, stage2_user, stage2_last;

    reg [47:0] output_data;
    reg output_valid, output_user, output_last;
    integer index, stream, box;

    function automatic [23:0] class_color(input [7:0] class_id);
        begin
            case (class_id[2:0])
                3'd0: class_color=24'h00ff00; 3'd1: class_color=24'hff3030;
                3'd2: class_color=24'h30a0ff; 3'd3: class_color=24'hffff00;
                3'd4: class_color=24'hff40ff; 3'd5: class_color=24'h00ffff;
                3'd6: class_color=24'hff8000; default: class_color=24'hffffff;
            endcase
        end
    endfunction

    function automatic pixel_hits_box(
        input [10:0] x, input [10:0] y, input [10:0] x_min,
        input [10:0] y_min, input [10:0] x_max, input [10:0] y_max);
        begin
            pixel_hits_box=(x>=x_min)&&(x<x_max)&&(y>=y_min)&&(y<y_max)&&
                ((x<x_min+2)||(x+2>=x_max)||(y<y_min+2)||(y+2>=y_max));
        end
    endfunction

    function automatic [10:0] tile_left(input [3:0] stream_id);
        begin tile_left=stream_id[1:0]*TILE_WIDTH; end
    endfunction
    function automatic [10:0] tile_top(input [3:0] stream_id);
        begin tile_top=stream_id[3:2]*TILE_HEIGHT; end
    endfunction
    function automatic [10:0] label_x_for(
        input [10:0] x_min, input [3:0] stream_id);
        reg [10:0] left;
        begin
            left=tile_left(stream_id);
            if (x_min<left) label_x_for=left;
            else if (x_min>left+TILE_WIDTH-LABEL_WIDTH)
                label_x_for=left+TILE_WIDTH-LABEL_WIDTH;
            else label_x_for=x_min;
        end
    endfunction
    function automatic [10:0] label_y_for(
        input [10:0] y_min, input [3:0] stream_id);
        reg [10:0] top;
        begin
            top=tile_top(stream_id);
            label_y_for=y_min>=top+LABEL_HEIGHT ? y_min-LABEL_HEIGHT : y_min;
        end
    endfunction
    function automatic [7:0] label_char_at(
        input [127:0] label, input [10:0] x, input [10:0] label_x);
        reg [3:0] char_index;
        begin
            char_index=(x-label_x)>>3;
            label_char_at=label[char_index*8 +: 8];
        end
    endfunction
    function automatic pixel_hits_label(
        input [10:0] x, input [10:0] y, input [10:0] x_min,
        input [10:0] y_min, input [3:0] stream_id,
        input [127:0] label);
        reg [10:0] label_x, label_y;
        begin
            label_x=label_x_for(x_min,stream_id);
            label_y=label_y_for(y_min,stream_id);
            pixel_hits_label=(x>=label_x)&&(x<label_x+LABEL_WIDTH)&&
                (y>=label_y)&&(y<label_y+LABEL_HEIGHT)&&
                label_char_at(label,x,label_x)!=8'd0;
        end
    endfunction

    function automatic [34:0] font5x7(input [7:0] c);
        begin
            case(c)
                8'h41,8'h61: font5x7={5'b01110,5'b10001,5'b10001,5'b11111,5'b10001,5'b10001,5'b10001};
                8'h42,8'h62: font5x7={5'b11110,5'b10001,5'b10001,5'b11110,5'b10001,5'b10001,5'b11110};
                8'h43,8'h63: font5x7={5'b01111,5'b10000,5'b10000,5'b10000,5'b10000,5'b10000,5'b01111};
                8'h44,8'h64: font5x7={5'b11110,5'b10001,5'b10001,5'b10001,5'b10001,5'b10001,5'b11110};
                8'h45,8'h65: font5x7={5'b11111,5'b10000,5'b10000,5'b11110,5'b10000,5'b10000,5'b11111};
                8'h46,8'h66: font5x7={5'b11111,5'b10000,5'b10000,5'b11110,5'b10000,5'b10000,5'b10000};
                8'h47,8'h67: font5x7={5'b01111,5'b10000,5'b10000,5'b10111,5'b10001,5'b10001,5'b01110};
                8'h48,8'h68: font5x7={5'b10001,5'b10001,5'b10001,5'b11111,5'b10001,5'b10001,5'b10001};
                8'h49,8'h69: font5x7={5'b11111,5'b00100,5'b00100,5'b00100,5'b00100,5'b00100,5'b11111};
                8'h4a,8'h6a: font5x7={5'b00111,5'b00010,5'b00010,5'b00010,5'b00010,5'b10010,5'b01100};
                8'h4b,8'h6b: font5x7={5'b10001,5'b10010,5'b10100,5'b11000,5'b10100,5'b10010,5'b10001};
                8'h4c,8'h6c: font5x7={5'b10000,5'b10000,5'b10000,5'b10000,5'b10000,5'b10000,5'b11111};
                8'h4d,8'h6d: font5x7={5'b10001,5'b11011,5'b10101,5'b10101,5'b10001,5'b10001,5'b10001};
                8'h4e,8'h6e: font5x7={5'b10001,5'b11001,5'b10101,5'b10011,5'b10001,5'b10001,5'b10001};
                8'h4f,8'h6f: font5x7={5'b01110,5'b10001,5'b10001,5'b10001,5'b10001,5'b10001,5'b01110};
                8'h50,8'h70: font5x7={5'b11110,5'b10001,5'b10001,5'b11110,5'b10000,5'b10000,5'b10000};
                8'h51,8'h71: font5x7={5'b01110,5'b10001,5'b10001,5'b10001,5'b10101,5'b10010,5'b01101};
                8'h52,8'h72: font5x7={5'b11110,5'b10001,5'b10001,5'b11110,5'b10100,5'b10010,5'b10001};
                8'h53,8'h73: font5x7={5'b01111,5'b10000,5'b10000,5'b01110,5'b00001,5'b00001,5'b11110};
                8'h54,8'h74: font5x7={5'b11111,5'b00100,5'b00100,5'b00100,5'b00100,5'b00100,5'b00100};
                8'h55,8'h75: font5x7={5'b10001,5'b10001,5'b10001,5'b10001,5'b10001,5'b10001,5'b01110};
                8'h56,8'h76: font5x7={5'b10001,5'b10001,5'b10001,5'b10001,5'b10001,5'b01010,5'b00100};
                8'h57,8'h77: font5x7={5'b10001,5'b10001,5'b10001,5'b10101,5'b10101,5'b10101,5'b01010};
                8'h58,8'h78: font5x7={5'b10001,5'b10001,5'b01010,5'b00100,5'b01010,5'b10001,5'b10001};
                8'h59,8'h79: font5x7={5'b10001,5'b10001,5'b01010,5'b00100,5'b00100,5'b00100,5'b00100};
                8'h5a,8'h7a: font5x7={5'b11111,5'b00001,5'b00010,5'b00100,5'b01000,5'b10000,5'b11111};
                8'h30: font5x7={5'b01110,5'b10001,5'b10011,5'b10101,5'b11001,5'b10001,5'b01110};
                8'h31: font5x7={5'b00100,5'b01100,5'b00100,5'b00100,5'b00100,5'b00100,5'b01110};
                8'h32: font5x7={5'b01110,5'b10001,5'b00001,5'b00010,5'b00100,5'b01000,5'b11111};
                8'h33: font5x7={5'b11110,5'b00001,5'b00001,5'b01110,5'b00001,5'b00001,5'b11110};
                8'h34: font5x7={5'b00010,5'b00110,5'b01010,5'b10010,5'b11111,5'b00010,5'b00010};
                8'h35: font5x7={5'b11111,5'b10000,5'b10000,5'b11110,5'b00001,5'b00001,5'b11110};
                8'h36: font5x7={5'b01110,5'b10000,5'b10000,5'b11110,5'b10001,5'b10001,5'b01110};
                8'h37: font5x7={5'b11111,5'b00001,5'b00010,5'b00100,5'b01000,5'b01000,5'b01000};
                8'h38: font5x7={5'b01110,5'b10001,5'b10001,5'b01110,5'b10001,5'b10001,5'b01110};
                8'h39: font5x7={5'b01110,5'b10001,5'b10001,5'b01111,5'b00001,5'b00001,5'b01110};
                8'h25: font5x7={5'b11001,5'b11010,5'b00100,5'b01000,5'b10110,5'b00110,5'b00000};
                8'h20: font5x7=35'd0;
                default: font5x7={5'b01110,5'b10001,5'b00001,5'b00010,5'b00100,5'b00000,5'b00100};
            endcase
        end
    endfunction

    function automatic glyph_pixel(input [34:0] glyph,
        input [2:0] char_x, input [3:0] local_y);
        integer row, col;
        begin
            if (char_x>=1 && char_x<=5 && local_y>=1 && local_y<15) begin
                row=(local_y-1)>>1; col=char_x-1;
                glyph_pixel=glyph[34-row*5-col];
            end else glyph_pixel=1'b0;
        end
    endfunction

    wire output_ready=!output_valid||m_tready;
    wire stage2_ready=!stage2_valid||output_ready;
    wire stage1_ready=!stage1_valid||stage2_ready;
    wire stage0_ready=!stage0_valid||stage1_ready;
    assign s_tready=stage0_ready;
    assign m_tdata=output_data; assign m_tvalid=output_valid;
    assign m_tuser=output_user; assign m_tlast=output_last;

    reg [3:0] incoming_stream;
    reg selected_hit0, selected_hit1, selected_label0, selected_label1;
    reg [7:0] selected_char0, selected_char1, selected_class0, selected_class1;
    reg [2:0] selected_char_x0, selected_char_x1;
    reg [3:0] selected_label_y0, selected_label_y1;
    reg [47:0] decorated_data;

    always @* begin
        if ((s_tuser?11'd0:input_y)>=11'd810) incoming_stream=4'd12;
        else if ((s_tuser?11'd0:input_y)>=11'd540) incoming_stream=4'd8;
        else if ((s_tuser?11'd0:input_y)>=11'd270) incoming_stream=4'd4;
        else incoming_stream=4'd0;
        if ((s_tuser?11'd0:input_x)>=11'd1440) incoming_stream=incoming_stream+3;
        else if ((s_tuser?11'd0:input_x)>=11'd960) incoming_stream=incoming_stream+2;
        else if ((s_tuser?11'd0:input_x)>=11'd480) incoming_stream=incoming_stream+1;
    end

    always @* begin
        selected_hit0=0; selected_hit1=0; selected_label0=0; selected_label1=0;
        selected_char0=0; selected_char1=0; selected_char_x0=0; selected_char_x1=0;
        selected_label_y0=0; selected_label_y1=0; selected_class0=0; selected_class1=0;
        for (box=0;box<BOXES_PER_STREAM;box=box+1) begin
            if (!selected_hit0&&stage1_hits0[box]) begin
                selected_hit0=1; selected_label0=stage1_label_hit0[box];
                selected_char0=stage1_char0[box]; selected_char_x0=stage1_char_x0[box];
                selected_label_y0=stage1_label_y[box]; selected_class0=stage1_class[box];
            end
            if (!selected_hit1&&stage1_hits1[box]) begin
                selected_hit1=1; selected_label1=stage1_label_hit1[box];
                selected_char1=stage1_char1[box]; selected_char_x1=stage1_char_x1[box];
                selected_label_y1=stage1_label_y[box]; selected_class1=stage1_class[box];
            end
        end
    end

    always @* begin
        decorated_data=stage2_data;
        if (stage2_hit0) decorated_data[23:0]=stage2_label_hit0&&
            glyph_pixel(stage2_glyph0,stage2_char_x0,stage2_label_y0)?24'hffffff:stage2_color0;
        if (stage2_hit1) decorated_data[47:24]=stage2_label_hit1&&
            glyph_pixel(stage2_glyph1,stage2_char_x1,stage2_label_y1)?24'hffffff:stage2_color1;
    end

    always @(posedge clk) begin
        if (!resetn) begin
            input_x<=0; input_y<=0; stage0_valid<=0; stage1_valid<=0;
            stage2_valid<=0; output_valid<=0; output_data<=0; output_user<=0;
            output_last<=0; pending_streams<=0; active_bank<=0;
            active_valid<=0;
        end else begin
            if (cfg_commit&&cfg_stream<STREAMS) begin
                metadata_mem[{~active_bank[cfg_stream],cfg_stream}]<=
                    cfg_metadata_entry;
                pending_streams[cfg_stream]<=1;
            end
            if(s_tvalid&&s_tready&&s_tlast&&(s_tuser?11'd0:input_y)==FRAME_HEIGHT-1) begin
                for(stream=0;stream<STREAMS;stream=stream+1) if(pending_streams[stream]) begin
                    active_bank[stream]<=~active_bank[stream];
                    active_valid[stream]<=1'b1;
                    pending_streams[stream]<=0;
                end
            end
            if(output_ready) begin
                output_valid<=stage2_valid;
                if(stage2_valid) begin output_data<=decorated_data; output_user<=stage2_user; output_last<=stage2_last; end
                else begin output_user<=0; output_last<=0; end
            end
            if(stage2_ready) begin
                stage2_valid<=stage1_valid;
                if(stage1_valid) begin
                    stage2_data<=stage1_data; stage2_hit0<=selected_hit0; stage2_hit1<=selected_hit1;
                    stage2_label_hit0<=selected_label0; stage2_label_hit1<=selected_label1;
                    stage2_char_x0<=selected_char_x0; stage2_char_x1<=selected_char_x1;
                    stage2_label_y0<=selected_label_y0; stage2_label_y1<=selected_label_y1;
                    stage2_glyph0<=font5x7(selected_char0); stage2_glyph1<=font5x7(selected_char1);
                    stage2_color0<=class_color(selected_class0); stage2_color1<=class_color(selected_class1);
                    stage2_user<=stage1_user; stage2_last<=stage1_last;
                end else begin stage2_user<=0; stage2_last<=0; end
            end
            if(stage1_ready) begin
                stage1_valid<=stage0_valid;
                if(stage0_valid) begin
                    stage1_data<=stage0_data; stage1_user<=stage0_user; stage1_last<=stage0_last;
                    for(box=0;box<BOXES_PER_STREAM;box=box+1) begin
                        stage1_label_hit0[box]<=enable&&box<stage0_active_count&&pixel_hits_label(stage0_x,stage0_y,active_metadata[box][META_X_MIN_LSB+:11],active_metadata[box][META_Y_MIN_LSB+:11],stage0_stream,active_metadata[box][META_LABEL_LSB+:128]);
                        stage1_label_hit1[box]<=enable&&box<stage0_active_count&&pixel_hits_label(stage0_x+1'b1,stage0_y,active_metadata[box][META_X_MIN_LSB+:11],active_metadata[box][META_Y_MIN_LSB+:11],stage0_stream,active_metadata[box][META_LABEL_LSB+:128]);
                        stage1_hits0[box]<=enable&&box<stage0_active_count&&(pixel_hits_box(stage0_x,stage0_y,active_metadata[box][META_X_MIN_LSB+:11],active_metadata[box][META_Y_MIN_LSB+:11],active_metadata[box][META_X_MAX_LSB+:11],active_metadata[box][META_Y_MAX_LSB+:11])||pixel_hits_label(stage0_x,stage0_y,active_metadata[box][META_X_MIN_LSB+:11],active_metadata[box][META_Y_MIN_LSB+:11],stage0_stream,active_metadata[box][META_LABEL_LSB+:128]));
                        stage1_hits1[box]<=enable&&box<stage0_active_count&&(pixel_hits_box(stage0_x+1'b1,stage0_y,active_metadata[box][META_X_MIN_LSB+:11],active_metadata[box][META_Y_MIN_LSB+:11],active_metadata[box][META_X_MAX_LSB+:11],active_metadata[box][META_Y_MAX_LSB+:11])||pixel_hits_label(stage0_x+1'b1,stage0_y,active_metadata[box][META_X_MIN_LSB+:11],active_metadata[box][META_Y_MIN_LSB+:11],stage0_stream,active_metadata[box][META_LABEL_LSB+:128]));
                        stage1_char0[box]<=label_char_at(active_metadata[box][META_LABEL_LSB+:128],stage0_x,label_x_for(active_metadata[box][META_X_MIN_LSB+:11],stage0_stream));
                        stage1_char1[box]<=label_char_at(active_metadata[box][META_LABEL_LSB+:128],stage0_x+1'b1,label_x_for(active_metadata[box][META_X_MIN_LSB+:11],stage0_stream));
                        stage1_char_x0[box]<=stage0_x-label_x_for(active_metadata[box][META_X_MIN_LSB+:11],stage0_stream);
                        stage1_char_x1[box]<=stage0_x+1'b1-label_x_for(active_metadata[box][META_X_MIN_LSB+:11],stage0_stream);
                        stage1_label_y[box]<=stage0_y-label_y_for(active_metadata[box][META_Y_MIN_LSB+:11],stage0_stream);
                        stage1_class[box]<=active_metadata[box][META_CLASS_LSB+:8];
                    end
                end else begin stage1_user<=0; stage1_last<=0; end
            end
            if(stage0_ready) begin
                stage0_valid<=s_tvalid;
                if(s_tvalid) begin stage0_data<=s_tdata; stage0_x<=s_tuser?0:input_x;
                    stage0_y<=s_tuser?0:input_y; stage0_stream<=incoming_stream;
                    stage0_user<=s_tuser; stage0_last<=s_tlast; end
                else begin stage0_user<=0; stage0_last<=0; end
            end
            if(s_tvalid&&s_tready) begin
                if(s_tlast) begin input_x<=0; input_y<=(s_tuser?0:input_y)==FRAME_HEIGHT-1?0:(s_tuser?0:input_y)+1; end
                else begin input_x<=(s_tuser?0:input_x)+2; input_y<=s_tuser?0:input_y; end
            end
        end
    end

    initial if(STREAMS!=16||BOXES_PER_STREAM!=8||FRAME_WIDTH!=1920||FRAME_HEIGHT!=1080)
        $error("detection_overlay currently requires 16 streams, 8 boxes, 1080p");
endmodule
