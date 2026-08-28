`timescale 1ns/1ps

// Single-frame nearest-neighbour preprocessor.  The source is the framebuffer
// XRGB8888 layout used by channel_write_fifo.  The destination is tightly
// packed signed INT8 NHWC with byte order R, G, B.  Input values are mapped
// from unsigned 8-bit to the model's [0,127] range by dropping bit zero.
module frame_preprocess_accel #(
    parameter integer SRC_WIDTH = 640,
    parameter integer SRC_HEIGHT = 480,
    parameter integer SRC_STRIDE_BYTES = SRC_WIDTH * 4,
    // The fixed YOLOv5nu contract is 640x480 (6300 anchors).
    parameter integer DST_WIDTH = 640,
    parameter integer DST_HEIGHT = 480,
    parameter integer MAX_BURST_BEATS = 64
) (
    input  wire        clk,
    input  wire        resetn,
    input  wire        start,
    input  wire        source_valid,
    input  wire [31:0] source_addr,
    input  wire [31:0] dest_addr,
    output reg         busy,
    output reg         done,
    output reg         error,
    output reg  [31:0] cycles,
    output reg  [31:0] read_beats,
    output reg  [31:0] write_beats,
    axi4_if.master     m_axi
);
    localparam integer SRC_ROW_BEATS = SRC_WIDTH / 8;
    localparam integer DST_ROW_BYTES = DST_WIDTH * 3;
    localparam integer DST_ROW_BEATS = DST_ROW_BYTES / 32;
    localparam integer X_BASE_STEP = SRC_WIDTH / DST_WIDTH;
    localparam integer X_STEP_REMAINDER = SRC_WIDTH % DST_WIDTH;
    localparam integer Y_BASE_STEP = SRC_HEIGHT / DST_HEIGHT;
    localparam integer Y_STEP_REMAINDER = SRC_HEIGHT % DST_HEIGHT;

    localparam [3:0] ST_IDLE     = 4'd0;
    localparam [3:0] ST_ROW_PREP = 4'd1;
    localparam [3:0] ST_RD_PREP  = 4'd2;
    localparam [3:0] ST_RD_AR    = 4'd3;
    localparam [3:0] ST_RD_DATA  = 4'd4;
    localparam [3:0] ST_WR_PREP  = 4'd5;
    localparam [3:0] ST_WR_AW    = 4'd6;
    localparam [3:0] ST_WR_LOAD  = 4'd7;
    localparam [3:0] ST_WR_DATA  = 4'd8;
    localparam [3:0] ST_WR_RESP  = 4'd9;
    localparam [3:0] ST_WR_FETCH = 4'd10;

    reg [3:0] state;
    reg source_valid_q;
    reg [31:0] source_base;
    reg [31:0] dest_base;
    reg [15:0] output_y;
    reg [15:0] source_y;
    reg [15:0] y_remainder;

    reg [31:0] read_addr;
    reg [15:0] row_read_remaining;
    reg [8:0] read_burst_beats;
    reg [8:0] read_burst_received;
    reg [15:0] row_beat_received;
    reg read_arvalid;
    reg [255:0] input_word;
    reg input_word_valid;
    reg input_word_burst_last;
    reg [15:0] input_beat_x;

    reg [15:0] output_x;
    reg [15:0] target_x;
    reg [15:0] x_remainder;
    reg [255:0] pack_data;
    reg [5:0] pack_bytes;
    reg [5:0] row_word_count;
    (* ram_style = "block" *) reg [255:0] row_buffer [0:DST_ROW_BEATS-1];

    reg [31:0] write_addr;
    reg [6:0] row_write_remaining;
    reg [8:0] write_burst_beats;
    reg [8:0] write_burst_sent;
    reg [5:0] row_write_index;
    reg [5:0] row_buffer_rd_addr;
    reg [255:0] row_buffer_rd_data;
    reg [255:0] write_data;
    reg write_awvalid;

    wire [12:0] read_bytes_to_4k =
        13'h1000 - {1'b0, read_addr[11:0]};
    wire [8:0] read_beats_to_4k = read_bytes_to_4k[12:5];
    wire [15:0] read_address_limited =
        row_read_remaining < read_beats_to_4k ? row_read_remaining :
        read_beats_to_4k;
    wire [15:0] read_planned_wide =
        read_address_limited < MAX_BURST_BEATS ? read_address_limited :
        MAX_BURST_BEATS;

    wire [12:0] write_bytes_to_4k =
        13'h1000 - {1'b0, write_addr[11:0]};
    wire [8:0] write_beats_to_4k = write_bytes_to_4k[12:5];
    wire [8:0] write_address_limited =
        row_write_remaining < write_beats_to_4k ? row_write_remaining :
        write_beats_to_4k;
    wire [8:0] write_planned =
        write_address_limited < MAX_BURST_BEATS ? write_address_limited :
        MAX_BURST_BEATS;

    function automatic [31:0] select_lane;
        input [255:0] word;
        input [2:0] lane;
        begin
            case (lane)
                3'd0: select_lane = word[31:0];
                3'd1: select_lane = word[63:32];
                3'd2: select_lane = word[95:64];
                3'd3: select_lane = word[127:96];
                3'd4: select_lane = word[159:128];
                3'd5: select_lane = word[191:160];
                3'd6: select_lane = word[223:192];
                default: select_lane = word[255:224];
            endcase
        end
    endfunction

    wire [31:0] selected_source_pixel = select_lane(input_word, target_x[2:0]);
    // Existing video words use bit lanes {R,B,G}; pack little-endian RGB.
    wire [23:0] quantized_pixel = {
        1'b0, selected_source_pixel[15:9],
        1'b0, selected_source_pixel[7:1],
        1'b0, selected_source_pixel[23:17]
    };
    wire x_step_long = x_remainder + X_STEP_REMAINDER >= DST_WIDTH;
    wire [15:0] next_target_x = target_x + X_BASE_STEP + x_step_long;
    wire [15:0] next_x_remainder = x_step_long ?
        x_remainder + X_STEP_REMAINDER - DST_WIDTH :
        x_remainder + X_STEP_REMAINDER;
    wire [279:0] shifted_pixel =
        {256'd0, quantized_pixel} << (pack_bytes * 8);
    wire [279:0] combined_pack = {24'd0, pack_data} | shifted_pixel;
    wire pack_emits_word = pack_bytes + 6'd3 >= 6'd32;
    wire row_buffer_write = state == ST_RD_DATA && input_word_valid &&
                            (target_x[15:3] == input_beat_x) &&
                            pack_emits_word;

    wire y_step_long = y_remainder + Y_STEP_REMAINDER >= DST_HEIGHT;
    wire ar_fire = m_axi.arvalid && m_axi.arready;
    wire r_fire = m_axi.rvalid && m_axi.rready;
    wire aw_fire = m_axi.awvalid && m_axi.awready;
    wire w_fire = m_axi.wvalid && m_axi.wready;
    wire b_fire = m_axi.bvalid && m_axi.bready;

    assign m_axi.aclk = clk;
    assign m_axi.aresetn = resetn;
    assign m_axi.arid = 3'd0;
    assign m_axi.araddr = read_addr;
    assign m_axi.arlen = read_burst_beats[7:0] - 1'b1;
    assign m_axi.arsize = 3'b101;
    assign m_axi.arburst = 2'b01;
    assign m_axi.arlock = 1'b0;
    assign m_axi.arcache = 4'b0010;
    assign m_axi.arprot = 3'b000;
    assign m_axi.arqos = 4'h6;
    assign m_axi.arvalid = read_arvalid;
    assign m_axi.rready = (state == ST_RD_DATA) && !input_word_valid;

    assign m_axi.awid = 3'd0;
    assign m_axi.awaddr = write_addr;
    assign m_axi.awlen = write_burst_beats[7:0] - 1'b1;
    assign m_axi.awsize = 3'b101;
    assign m_axi.awburst = 2'b01;
    assign m_axi.awlock = 1'b0;
    assign m_axi.awcache = 4'b0010;
    assign m_axi.awprot = 3'b000;
    assign m_axi.awqos = 4'h6;
    assign m_axi.awvalid = write_awvalid;
    assign m_axi.wdata = source_valid_q ? write_data : 256'd0;
    assign m_axi.wstrb = 32'hffff_ffff;
    assign m_axi.wlast = write_burst_sent + 1'b1 == write_burst_beats;
    assign m_axi.wvalid = state == ST_WR_DATA;
    assign m_axi.bready = state == ST_WR_RESP;

    initial begin
        if (SRC_WIDTH <= 0 || SRC_HEIGHT <= 0 || DST_WIDTH <= 0 ||
            DST_HEIGHT <= 0 || SRC_WIDTH < DST_WIDTH ||
            SRC_HEIGHT < DST_HEIGHT || (SRC_WIDTH % 8) != 0 ||
            (SRC_STRIDE_BYTES % 32) != 0 || (DST_ROW_BYTES % 32) != 0 ||
            DST_ROW_BEATS > 64 || MAX_BURST_BEATS < 1 ||
            MAX_BURST_BEATS > 128)
            $error("frame_preprocess_accel parameters are invalid");
    end

    always @(posedge clk) begin
        if (!resetn) begin
            state <= ST_IDLE;
            source_valid_q <= 1'b0;
            source_base <= 32'd0;
            dest_base <= 32'd0;
            output_y <= 16'd0;
            source_y <= 16'd0;
            y_remainder <= 16'd0;
            read_addr <= 32'd0;
            row_read_remaining <= 16'd0;
            read_burst_beats <= 9'd0;
            read_burst_received <= 9'd0;
            row_beat_received <= 16'd0;
            read_arvalid <= 1'b0;
            input_word <= 256'd0;
            input_word_valid <= 1'b0;
            input_word_burst_last <= 1'b0;
            input_beat_x <= 16'd0;
            output_x <= 16'd0;
            target_x <= 16'd0;
            x_remainder <= 16'd0;
            pack_data <= 256'd0;
            pack_bytes <= 6'd0;
            row_word_count <= 6'd0;
            write_addr <= 32'd0;
            row_write_remaining <= 7'd0;
            write_burst_beats <= 9'd0;
            write_burst_sent <= 9'd0;
            row_write_index <= 6'd0;
            row_buffer_rd_addr <= 6'd0;
            write_data <= 256'd0;
            write_awvalid <= 1'b0;
            busy <= 1'b0;
            done <= 1'b0;
            error <= 1'b0;
            cycles <= 32'd0;
            read_beats <= 32'd0;
            write_beats <= 32'd0;
        end else begin
            done <= 1'b0;
            if (busy)
                cycles <= cycles + 1'b1;

            case (state)
                ST_IDLE: begin
                    read_arvalid <= 1'b0;
                    write_awvalid <= 1'b0;
                    if (start) begin
                        source_valid_q <= source_valid;
                        source_base <= source_addr;
                        dest_base <= dest_addr;
                        output_y <= 16'd0;
                        source_y <= 16'd0;
                        y_remainder <= 16'd0;
                        error <= 1'b0;
                        cycles <= 32'd0;
                        read_beats <= 32'd0;
                        write_beats <= 32'd0;
                        if (source_addr[4:0] != 0 || dest_addr[4:0] != 0) begin
                            done <= 1'b1;
                            error <= 1'b1;
                        end else begin
                            busy <= 1'b1;
                            state <= ST_ROW_PREP;
                        end
                    end
                end

                ST_ROW_PREP: begin
                    write_addr <= dest_base + output_y * DST_ROW_BYTES;
                    row_write_remaining <= DST_ROW_BEATS;
                    row_write_index <= 6'd0;
                    row_buffer_rd_addr <= 6'd0;
                    if (!source_valid_q) begin
                        state <= ST_WR_PREP;
                    end else begin
                        read_addr <= source_base + source_y * SRC_STRIDE_BYTES;
                        row_read_remaining <= SRC_ROW_BEATS;
                        row_beat_received <= 16'd0;
                        output_x <= 16'd0;
                        target_x <= 16'd0;
                        x_remainder <= 16'd0;
                        pack_data <= 256'd0;
                        pack_bytes <= 6'd0;
                        row_word_count <= 6'd0;
                        input_word_valid <= 1'b0;
                        state <= ST_RD_PREP;
                    end
                end

                ST_RD_PREP: begin
                    read_burst_beats <= read_planned_wide[8:0];
                    read_burst_received <= 9'd0;
                    read_arvalid <= 1'b1;
                    state <= ST_RD_AR;
                end

                ST_RD_AR: begin
                    if (ar_fire) begin
                        read_arvalid <= 1'b0;
                        state <= ST_RD_DATA;
                    end
                end

                ST_RD_DATA: begin
                    if (r_fire) begin
                        input_word <= m_axi.rdata;
                        input_word_valid <= 1'b1;
                        input_word_burst_last <=
                            read_burst_received + 1'b1 == read_burst_beats;
                        input_beat_x <= row_beat_received;
                        row_beat_received <= row_beat_received + 1'b1;
                        read_burst_received <= read_burst_received + 1'b1;
                        read_beats <= read_beats + 1'b1;
                        if (m_axi.rid != 0 || m_axi.rresp != 2'b00 ||
                            m_axi.rlast != (read_burst_received + 1'b1 ==
                                            read_burst_beats))
                            error <= 1'b1;
                        if (read_burst_received + 1'b1 == read_burst_beats) begin
                            read_addr <= read_addr + read_burst_beats * 32;
                            row_read_remaining <= row_read_remaining -
                                                  read_burst_beats;
                        end
                    end

                    if (input_word_valid &&
                        (target_x[15:3] == input_beat_x)) begin
                        output_x <= output_x + 1'b1;
                        target_x <= next_target_x;
                        x_remainder <= next_x_remainder;
                        if (pack_emits_word) begin
                            row_word_count <= row_word_count + 1'b1;
                            pack_data <= {232'd0, combined_pack[279:256]};
                            pack_bytes <= pack_bytes + 6'd3 - 6'd32;
                        end else begin
                            pack_data <= combined_pack[255:0];
                            pack_bytes <= pack_bytes + 6'd3;
                        end

                        if (output_x + 1'b1 == DST_WIDTH) begin
                            input_word_valid <= 1'b0;
                            if (!pack_emits_word ||
                                row_word_count + 1'b1 != DST_ROW_BEATS)
                                error <= 1'b1;
                            state <= ST_WR_PREP;
                        end else if (next_target_x[15:3] != input_beat_x) begin
                            input_word_valid <= 1'b0;
                            if (input_word_burst_last)
                                state <= ST_RD_PREP;
                        end
                    end
                end

                ST_WR_PREP: begin
                    write_burst_beats <= write_planned;
                    write_burst_sent <= 9'd0;
                    row_buffer_rd_addr <= row_write_index;
                    write_awvalid <= 1'b1;
                    state <= ST_WR_AW;
                end

                ST_WR_AW: begin
                    if (aw_fire) begin
                        write_awvalid <= 1'b0;
                        if (source_valid_q) begin
                            row_buffer_rd_addr <= row_write_index + 1'b1;
                            state <= ST_WR_LOAD;
                        end else begin
                            state <= ST_WR_DATA;
                        end
                    end
                end

                ST_WR_LOAD: begin
                    write_data <= row_buffer_rd_data;
                    state <= ST_WR_DATA;
                end

                ST_WR_DATA: begin
                    if (w_fire) begin
                        write_beats <= write_beats + 1'b1;
                        row_write_index <= row_write_index + 1'b1;
                        write_burst_sent <= write_burst_sent + 1'b1;
                        if (write_burst_sent + 1'b1 == write_burst_beats) begin
                            state <= ST_WR_RESP;
                        end else if (source_valid_q) begin
                            row_buffer_rd_addr <= row_write_index + 1'b1;
                            // row_buffer is synchronous.  Allow one complete
                            // clock after changing the address before loading
                            // the next AXI beat.
                            state <= ST_WR_FETCH;
                        end
                    end
                end

                ST_WR_FETCH: begin
                    state <= ST_WR_LOAD;
                end

                ST_WR_RESP: begin
                    if (b_fire) begin
                        if (m_axi.bid != 0 || m_axi.bresp != 2'b00)
                            error <= 1'b1;
                        write_addr <= write_addr + write_burst_beats * 32;
                        row_write_remaining <= row_write_remaining -
                                               write_burst_beats;
                        if (row_write_remaining == write_burst_beats) begin
                            if (output_y + 1'b1 == DST_HEIGHT) begin
                                busy <= 1'b0;
                                done <= 1'b1;
                                state <= ST_IDLE;
                            end else begin
                                output_y <= output_y + 1'b1;
                                source_y <= source_y + Y_BASE_STEP +
                                            y_step_long;
                                y_remainder <= y_step_long ?
                                    y_remainder + Y_STEP_REMAINDER -
                                    DST_HEIGHT :
                                    y_remainder + Y_STEP_REMAINDER;
                                state <= ST_ROW_PREP;
                            end
                        end else begin
                            state <= ST_WR_PREP;
                        end
                    end
                end

                default: begin
                    busy <= 1'b0;
                    done <= 1'b1;
                    error <= 1'b1;
                    state <= ST_IDLE;
                end
            endcase
        end
    end

    always @(posedge clk) begin
        if (row_buffer_write)
            row_buffer[row_word_count] <= combined_pack[255:0];
        row_buffer_rd_data <= row_buffer[row_buffer_rd_addr];
    end
endmodule
