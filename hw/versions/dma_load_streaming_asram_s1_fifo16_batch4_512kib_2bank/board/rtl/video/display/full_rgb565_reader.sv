`timescale 1ns/1ps

// Single-channel presentation of a 360x270 RGB565 frame at 1920x1080.
// Each source line is reused four times; each output pair selects
// floor(output_pair*3/16) of the 180 source pairs.
module full_rgb565_reader (
    input  wire          clk,
    input  wire          resetn,
    output wire          buffer_acquire,
    input  wire          buffer_grant,
    input  wire [31:0]   buffer_base,
    output reg           buffer_done,
    axi4_if.master       m_axi,
    axis_video_if.source m_axis,
    output reg           axi_error,
    output reg           fifo_underflow,
    output wire [31:0]   debug_active_base,
    output wire [31:0]   debug_status
);
    localparam [1:0] F_IDLE=0, F_AR=1, F_R=2, F_READY=3;
    localparam [1:0] O_WAIT=0, O_STREAM=1, O_DRAIN=2;
    (* ram_style = "block" *) reg [255:0] line_mem [0:22];
    reg [255:0] read_word_q;
    reg [2:0] lane_q;
    reg [31:0] selected_pair;
    wire [47:0] converted_pair;
    rgb565_to_rgb888 u_expand(
        .rgb565_pair(selected_pair), .rgb888_pair(converted_pair)
    );
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

    reg frame_active, line_ready;
    reg [31:0] frame_base;
    reg [8:0] source_y;
    reg [31:0] line_offset;
    reg [4:0] fill_word;
    reg [5:0] burst_left;
    reg [1:0] fill_state, output_state;
    reg [10:0] output_y;
    reg [9:0] output_x;
    reg [7:0] source_pair;
    reg [3:0] source_phase;
    reg [47:0] output_data_q;
    reg output_user_q, output_last_q;
    reg output_valid_q, output_frame_last_q;
    reg stage_valid_q, stage_user_q, stage_last_q, stage_frame_last_q;
    wire pipeline_advance = !output_valid_q || m_axis.tready;

    wire [31:0] fill_addr = frame_base + line_offset +
                            {22'd0, fill_word, 5'd0};
    wire [5:0] words_left = 6'd23 - {1'b0, fill_word};
    wire [7:0] boundary_left = 8'd128 - {1'b0, fill_addr[11:5]};
    wire [5:0] request_words = boundary_left < {2'b00, words_left} ?
        6'(boundary_left) : words_left;
    wire ar_fire = m_axi.arvalid && m_axi.arready;
    wire r_fire = m_axi.rvalid && m_axi.rready;
    wire output_fire = m_axis.tvalid && m_axis.tready;

    assign buffer_acquire = !frame_active;
    assign debug_active_base = frame_base;
    assign debug_status = {4'd0, output_y[10:0], output_x[9:0],
                           1'b0, fill_state, output_state, 2'b00};
    assign m_axis.aclk = clk;
    assign m_axis.aresetn = resetn;
    assign m_axis.tdata = output_data_q;
    assign m_axis.tvalid = output_valid_q;
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
    assign m_axi.arlen = 8'(request_words-1'b1);
    assign m_axi.arsize = 3'b101;
    assign m_axi.arburst = 2'b01;
    assign m_axi.arlock = 0;
    assign m_axi.arcache = 4'b0010;
    assign m_axi.arprot = 0;
    assign m_axi.arqos = 4'he;
    assign m_axi.arvalid = frame_active && fill_state == F_AR;
    assign m_axi.rready = frame_active && fill_state == F_R;

    always @(posedge clk) begin
        if (!resetn) begin
            frame_active <= 0;
            line_ready <= 0;
            frame_base <= 0;
            source_y <= 0;
            line_offset <= 0;
            fill_word <= 0;
            burst_left <= 0;
            fill_state <= F_IDLE;
            output_state <= O_WAIT;
            output_y <= 0;
            output_x <= 0;
            source_pair <= 0;
            source_phase <= 0;
            read_word_q <= 0;
            lane_q <= 0;
            output_data_q <= 0;
            output_user_q <= 0;
            output_last_q <= 0;
            output_valid_q <= 0;
            output_frame_last_q <= 0;
            stage_valid_q <= 0;
            stage_user_q <= 0;
            stage_last_q <= 0;
            stage_frame_last_q <= 0;
            buffer_done <= 0;
            axi_error <= 0;
            fifo_underflow <= 0;
        end else begin
            buffer_done <= 0;
            if (!frame_active && buffer_grant) begin
                frame_active <= 1;
                frame_base <= buffer_base;
                line_ready <= 0;
                source_y <= 0;
                line_offset <= 0;
                fill_word <= 0;
                fill_state <= F_AR;
                output_y <= 0;
                output_x <= 0;
                source_pair <= 0;
                source_phase <= 0;
                output_state <= O_WAIT;
                output_valid_q <= 0;
                stage_valid_q <= 0;
                axi_error <= 0;
                fifo_underflow <= 0;
            end else if (frame_active) begin
                case (fill_state)
                    F_AR: if (ar_fire) begin
                        burst_left <= request_words;
                        fill_state <= F_R;
                    end
                    F_R: if (r_fire) begin
                        line_mem[fill_word] <=
                            m_axi.rresp == 0 ? m_axi.rdata : 256'd0;
                        if (m_axi.rresp != 0 ||
                            m_axi.rlast != (burst_left == 1))
                            axi_error <= 1;
                        fill_word <= fill_word + 1'b1;
                        burst_left <= burst_left - 1'b1;
                        if (burst_left == 1) begin
                            if (fill_word == 22) begin
                                line_ready <= 1;
                                fill_state <= F_READY;
                            end else
                                fill_state <= F_AR;
                        end
                    end
                    default: ;
                endcase

                if (pipeline_advance) begin
                    output_valid_q <= stage_valid_q;
                    if (stage_valid_q) begin
                        output_data_q <= converted_pair;
                        output_user_q <= stage_user_q;
                        output_last_q <= stage_last_q;
                        output_frame_last_q <= stage_frame_last_q;
                    end
                    stage_valid_q <= 0;
                    case (output_state)
                        O_WAIT: if (line_ready)
                            output_state <= O_STREAM;
                        O_STREAM: begin
                            read_word_q <= line_mem[source_pair[7:3]];
                            lane_q <= source_pair[2:0];
                            stage_valid_q <= 1;
                            stage_user_q <= output_x == 0 && output_y == 0;
                            stage_last_q <= output_x == 959;
                            stage_frame_last_q <= output_y == 1079 &&
                                                  output_x == 959;
                            if (output_x == 959) begin
                                output_x <= 0;
                                source_pair <= 0;
                                source_phase <= 0;
                                output_state <= output_y == 1079 ?
                                                O_DRAIN : O_WAIT;
                                if (output_y != 1079) begin
                                    output_y <= output_y + 1'b1;
                                    if (output_y[1:0] == 2'd3) begin
                                        source_y <= source_y + 1'b1;
                                        line_offset <= line_offset + 32'd736;
                                        fill_word <= 0;
                                        line_ready <= 0;
                                        fill_state <= F_AR;
                                    end
                                end
                            end else begin
                                output_x <= output_x + 1'b1;
                                if ({1'b0, source_phase} + 5'd3 >= 5'd16) begin
                                    source_phase <= 4'({1'b0, source_phase} +
                                                       5'd3 - 5'd16);
                                    source_pair <= source_pair + 1'b1;
                                end else
                                    source_phase <= source_phase + 4'd3;
                            end
                        end
                        default: ;
                    endcase
                end
                if (output_fire && output_frame_last_q) begin
                    frame_active <= 0;
                    buffer_done <= 1;
                    output_state <= O_WAIT;
                end
            end
        end
    end
endmodule
