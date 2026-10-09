`timescale 1ns/1ps

// 4x4 compositor for the compact 368x270 RGB565 display frame layout.
// Two 4-tile line banks let DDR fill the next output row during presentation.
module mosaic_rgb565_reader #(
    parameter integer CHANNELS = 16
) (
    input  wire                    clk,
    input  wire                    resetn,
    output wire                    buffer_acquire,
    input  wire                    buffer_grant,
    input  wire [CHANNELS*32-1:0]  buffer_bases,
    input  wire [CHANNELS-1:0]     buffer_valid_mask,
    output reg                     buffer_done,
    axi4_if.master                 m_axi,
    axis_video_if.source           m_axis,
    output reg                     axi_error,
    output reg                     fifo_underflow,
    output wire [31:0]             debug_status
);
    localparam integer WORDS_PER_LINE = 23;
    localparam integer WORDS_PER_BANK = 4*WORDS_PER_LINE;
    localparam [2:0] F_IDLE=0, F_TILE=1, F_AR=2, F_R=3,
                     F_ZERO=4, F_NEXT=5;
    localparam [1:0] O_WAIT=0, O_STREAM=1, O_DRAIN=2;

    (* ram_style = "block" *) reg [255:0] line_mem [0:2*WORDS_PER_BANK-1];
    reg [255:0] read_word_q;
    reg [2:0] lane_q;
    reg [31:0] selected_pair;
    always @* begin
        case (lane_q)
            3'd0: selected_pair = read_word_q[31:0];
            3'd1: selected_pair = read_word_q[63:32];
            3'd2: selected_pair = read_word_q[95:64];
            3'd3: selected_pair = read_word_q[127:96];
            3'd4: selected_pair = read_word_q[159:128];
            3'd5: selected_pair = read_word_q[191:160];
            3'd6: selected_pair = read_word_q[223:192];
            default: selected_pair = read_word_q[255:224];
        endcase
    end
    wire [47:0] converted_pair;
    rgb565_to_rgb888 u_expand(
        .rgb565_pair(selected_pair), .rgb888_pair(converted_pair)
    );

    reg frame_active;
    reg [CHANNELS*32-1:0] frame_bases;
    reg [CHANNELS-1:0] frame_valid_mask;
    reg bank_ready [0:1];
    reg [10:0] bank_line [0:1];
    reg [10:0] fill_y, output_y;
    reg [8:0] fill_source_y;
    reg [31:0] fill_line_offset;
    reg [1:0] fill_tile_row, fill_tile;
    reg [4:0] fill_word;
    reg [5:0] burst_left;
    reg [2:0] fill_state;
    reg [1:0] output_state;
    reg [9:0] output_x;
    reg [47:0] output_data_q;
    reg output_user_q, output_last_q;
    reg output_valid_q, output_frame_last_q;
    reg stage_valid_q, stage_black_q;
    reg stage_user_q, stage_last_q, stage_frame_last_q;
    wire pipeline_advance = !output_valid_q || m_axis.tready;

    wire fill_bank = fill_y[0];
    wire [3:0] fill_channel = {fill_tile_row, 2'b00} + {2'b00, fill_tile};
    wire [31:0] fill_base = frame_bases[fill_channel*32 +: 32];
    wire [31:0] fill_addr = fill_base + fill_line_offset +
                            {22'd0, fill_word, 5'd0};
    wire [5:0] words_left = 6'(WORDS_PER_LINE) - {1'b0, fill_word};
    wire [7:0] boundary_left = 8'd128 - {1'b0, fill_addr[11:5]};
    wire [5:0] request_words = (boundary_left < {2'b00, words_left}) ?
        6'(boundary_left) : words_left;
    wire ar_fire = m_axi.arvalid && m_axi.arready;
    wire r_fire = m_axi.rvalid && m_axi.rready;

    wire [1:0] output_tile = output_x < 240 ? 2'd0 :
        output_x < 480 ? 2'd1 : output_x < 720 ? 2'd2 : 2'd3;
    wire [7:0] tile_pair = 8'(output_x - 10'(output_tile)*10'd240);
    wire image_pair_valid = tile_pair >= 30 && tile_pair < 210;
    wire [7:0] image_pair = tile_pair - 8'd30;
    wire [3:0] output_channel =
        (output_y < 270 ? 4'd0 : output_y < 540 ? 4'd4 :
         output_y < 810 ? 4'd8 : 4'd12) + {2'b00, output_tile};
    wire output_black = !image_pair_valid ||
        !frame_valid_mask[output_channel];
    wire [7:0] memory_address =
        8'(output_y[0])*8'(WORDS_PER_BANK) +
        8'(output_tile)*8'(WORDS_PER_LINE) +
        {3'd0, image_pair[7:3]};

    assign buffer_acquire = !frame_active;
    assign debug_status = {4'd0, output_y[10:0], output_x[9:0],
                           fill_state, output_state, 2'b00};
    assign m_axis.aclk = clk;
    assign m_axis.aresetn = resetn;
    assign m_axis.tvalid = output_valid_q;
    assign m_axis.tdata = output_data_q;
    assign m_axis.tuser = output_user_q;
    assign m_axis.tlast = output_last_q;

    assign m_axi.aclk = clk;
    assign m_axi.aresetn = resetn;
    assign m_axi.awid = 0;
    assign m_axi.awaddr = 0;
    assign m_axi.awlen = 0;
    assign m_axi.awsize = 3'b101;
    assign m_axi.awburst = 2'b01;
    assign m_axi.awlock = 0;
    assign m_axi.awcache = 0;
    assign m_axi.awprot = 0;
    assign m_axi.awqos = 0;
    assign m_axi.awvalid = 0;
    assign m_axi.wdata = 0;
    assign m_axi.wstrb = 0;
    assign m_axi.wlast = 0;
    assign m_axi.wvalid = 0;
    assign m_axi.bready = 0;
    assign m_axi.arid = 0;
    assign m_axi.araddr = fill_addr;
    assign m_axi.arlen = 8'(request_words - 1'b1);
    assign m_axi.arsize = 3'b101;
    assign m_axi.arburst = 2'b01;
    assign m_axi.arlock = 0;
    assign m_axi.arcache = 4'b0010;
    assign m_axi.arprot = 0;
    assign m_axi.arqos = 4'he;
    assign m_axi.arvalid = fill_state == F_AR;
    assign m_axi.rready = fill_state == F_R;

    initial if (CHANNELS != 16)
        $error("mosaic_rgb565_reader requires sixteen channels");

    always @(posedge clk) begin
        if (!resetn) begin
            frame_active <= 0;
            frame_bases <= 0;
            frame_valid_mask <= 0;
            bank_ready[0] <= 0;
            bank_ready[1] <= 0;
            bank_line[0] <= 0;
            bank_line[1] <= 0;
            fill_y <= 0;
            fill_source_y <= 0;
            fill_line_offset <= 0;
            fill_tile_row <= 0;
            fill_tile <= 0;
            fill_word <= 0;
            burst_left <= 0;
            fill_state <= F_IDLE;
            output_y <= 0;
            output_x <= 0;
            output_state <= O_WAIT;
            read_word_q <= 0;
            lane_q <= 0;
            output_data_q <= 0;
            output_user_q <= 0;
            output_last_q <= 0;
            output_valid_q <= 0;
            output_frame_last_q <= 0;
            stage_valid_q <= 0;
            stage_black_q <= 0;
            stage_user_q <= 0;
            stage_last_q <= 0;
            stage_frame_last_q <= 0;
            buffer_done <= 0;
            axi_error <= 0;
            fifo_underflow <= 0;
        end else begin
            buffer_done <= 0;
            fifo_underflow <= 0;
            if (!frame_active && buffer_grant) begin
                frame_active <= 1;
                frame_bases <= buffer_bases;
                frame_valid_mask <= buffer_valid_mask;
                bank_ready[0] <= 0;
                bank_ready[1] <= 0;
                fill_y <= 0;
                fill_source_y <= 0;
                fill_line_offset <= 0;
                fill_tile_row <= 0;
                fill_state <= F_IDLE;
                output_y <= 0;
                output_x <= 0;
                output_state <= O_WAIT;
                output_valid_q <= 0;
                stage_valid_q <= 0;
                axi_error <= 0;
                fifo_underflow <= 0;
            end else if (frame_active) begin
                case (fill_state)
                    F_IDLE: if (fill_y < 1080 && !bank_ready[fill_bank]) begin
                        fill_tile <= 0;
                        fill_word <= 0;
                        fill_state <= F_TILE;
                    end
                    F_TILE: fill_state <= frame_valid_mask[fill_channel] ?
                        F_AR : F_ZERO;
                    F_AR: if (ar_fire) begin
                        burst_left <= request_words;
                        fill_state <= F_R;
                    end
                    F_R: if (r_fire) begin
                        line_mem[8'(fill_bank)*8'(WORDS_PER_BANK) +
                                 8'(fill_tile)*8'(WORDS_PER_LINE) +
                                 {3'd0, fill_word}] <=
                            m_axi.rresp == 0 ? m_axi.rdata : 256'd0;
                        if (m_axi.rresp != 0 ||
                            m_axi.rlast != (burst_left == 1))
                            axi_error <= 1;
                        fill_word <= fill_word + 1'b1;
                        burst_left <= burst_left - 1'b1;
                        if (burst_left == 1)
                            fill_state <= fill_word == WORDS_PER_LINE-1 ?
                                F_NEXT : F_AR;
                    end
                    F_ZERO: begin
                        line_mem[8'(fill_bank)*8'(WORDS_PER_BANK) +
                                 8'(fill_tile)*8'(WORDS_PER_LINE) +
                                 {3'd0, fill_word}] <= 0;
                        fill_word <= fill_word + 1'b1;
                        if (fill_word == WORDS_PER_LINE-1)
                            fill_state <= F_NEXT;
                    end
                    F_NEXT: if (fill_tile == 3) begin
                        bank_ready[fill_bank] <= 1;
                        bank_line[fill_bank] <= fill_y;
                        fill_y <= fill_y + 1'b1;
                        if (fill_source_y == 269) begin
                            fill_source_y <= 0;
                            fill_line_offset <= 0;
                            fill_tile_row <= fill_tile_row + 1'b1;
                        end else begin
                            fill_source_y <= fill_source_y + 1'b1;
                            fill_line_offset <= fill_line_offset + 32'd736;
                        end
                        fill_state <= F_IDLE;
                    end else begin
                        fill_tile <= fill_tile + 1'b1;
                        fill_word <= 0;
                        fill_state <= F_TILE;
                    end
                    default: fill_state <= F_IDLE;
                endcase

                // One synchronous BRAM read and one RGB expansion stage are
                // elastic as a unit.  Once a line is ready, a new pixel pair
                // can be issued every 300 MHz cycle, including under stalls.
                if (pipeline_advance) begin
                    output_valid_q <= stage_valid_q;
                    if (stage_valid_q) begin
                        output_data_q <= stage_black_q ? 48'd0 : converted_pair;
                        output_user_q <= stage_user_q;
                        output_last_q <= stage_last_q;
                        output_frame_last_q <= stage_frame_last_q;
                    end
                    stage_valid_q <= 0;
                    case (output_state)
                        O_WAIT: if (bank_ready[output_y[0]] &&
                                   bank_line[output_y[0]] == output_y)
                            output_state <= O_STREAM;
                        O_STREAM: begin
                            stage_valid_q <= 1;
                            stage_black_q <= output_black;
                            stage_user_q <= output_y == 0 && output_x == 0;
                            stage_last_q <= output_x == 959;
                            stage_frame_last_q <= output_y == 1079 &&
                                                  output_x == 959;
                            if (!output_black) begin
                                read_word_q <= line_mem[memory_address];
                                lane_q <= image_pair[2:0];
                            end
                            if (output_x == 959) begin
                                output_x <= 0;
                                bank_ready[output_y[0]] <= 0;
                                if (output_y == 1079)
                                    output_state <= O_DRAIN;
                                else begin
                                    if (!bank_ready[!output_y[0]])
                                        fifo_underflow <= 1;
                                    output_y <= output_y + 1'b1;
                                    output_state <= O_WAIT;
                                end
                            end else
                                output_x <= output_x + 1'b1;
                        end
                        default: ;
                    endcase
                end
                if (output_valid_q && m_axis.tready &&
                    output_frame_last_q) begin
                    frame_active <= 0;
                    buffer_done <= 1;
                    output_state <= O_WAIT;
                end
            end
        end
    end
endmodule
