`timescale 1ns/1ps

// P1A coherent FBus reader. It deliberately permits only one outstanding
// burst. Requests are split at 4 KiB boundaries and at MAX_BURST_BEATS.
module fbus_read_engine #(
    parameter integer ADDR_WIDTH = 33,
    parameter integer DATA_WIDTH = 256,
    parameter integer ID_WIDTH = 4,
    parameter integer MAX_BURST_BEATS = 256
) (
    input  wire                  clk,
    input  wire                  resetn,
    input  wire                  start,
    input  wire [ADDR_WIDTH-1:0] base_addr,
    input  wire [31:0]           byte_count,
    output wire                  busy,
    output reg                   done,
    output wire                  error,
    output wire [2:0]            error_flags,
    output reg  [31:0]           bytes_read,
    output reg  [31:0]           ar_requests,
    output reg  [31:0]           read_beats,
    output wire [DATA_WIDTH-1:0] stream_data,
    output wire [DATA_WIDTH/8-1:0] stream_keep,
    output wire                  stream_valid,
    input  wire                  stream_ready,
    output wire                  stream_last,
    axi4_if.master               m_axi
);
    localparam integer BYTE_LANES = DATA_WIDTH / 8;
    localparam integer BYTE_SHIFT = $clog2(BYTE_LANES);
    localparam [2:0] AXI_SIZE = 3'(BYTE_SHIFT);
    localparam [8:0] MAX_BURST_BEATS_9 = 9'(MAX_BURST_BEATS);
    localparam [2:0] ST_IDLE = 3'd0;
    localparam [2:0] ST_PLAN = 3'd1;
    localparam [2:0] ST_ISSUE = 3'd2;
    localparam [2:0] ST_READ = 3'd3;
    localparam [2:0] ST_FINISH = 3'd4;

    reg [2:0] state;
    reg [ADDR_WIDTH-1:0] burst_addr;
    reg [31:0] remaining_bytes;
    reg [BYTE_SHIFT-1:0] skip_bytes;
    reg [8:0] burst_beats;
    reg [8:0] beats_received;
    reg error_q;
    reg [2:0] error_flags_q;
    reg [DATA_WIDTH-1:0] stream_data_q;
    reg [BYTE_LANES-1:0] stream_keep_q;
    reg stream_valid_q;
    reg stream_last_q;

    wire ar_fire = m_axi.arvalid && m_axi.arready;
    wire r_fire = m_axi.rvalid && m_axi.rready;
    wire stream_fire = stream_valid_q && stream_ready;
    wire output_available = !stream_valid_q || stream_ready;

    reg [32:0] bytes_with_skip;
    reg [32:0] beats_needed;
    reg [12:0] beats_to_4k;
    reg [8:0] planned_beats;
    always @* begin
        bytes_with_skip = {1'b0, remaining_bytes} +
                          {{(33-BYTE_SHIFT){1'b0}}, skip_bytes};
        beats_needed = (bytes_with_skip + BYTE_LANES - 1) >> BYTE_SHIFT;
        beats_to_4k = (13'd4096 - {1'b0, burst_addr[11:0]}) >> BYTE_SHIFT;
        if (beats_needed > {{24{1'b0}}, MAX_BURST_BEATS_9})
            planned_beats = MAX_BURST_BEATS_9;
        else
            planned_beats = beats_needed[8:0];
        if ({4'd0, planned_beats} > beats_to_4k)
            planned_beats = beats_to_4k[8:0];
    end

    reg [BYTE_SHIFT:0] available_bytes;
    reg [BYTE_SHIFT:0] valid_bytes;
    reg [BYTE_LANES-1:0] valid_mask;
    always @* begin
        available_bytes = (BYTE_SHIFT+1)'(BYTE_LANES) -
                          {1'b0, skip_bytes};
        if (remaining_bytes < available_bytes)
            valid_bytes = remaining_bytes[BYTE_SHIFT:0];
        else
            valid_bytes = available_bytes;
        valid_mask = {BYTE_LANES{1'b0}};
        for (integer lane = 0; lane < BYTE_LANES; lane = lane + 1) begin
            if (lane >= 32'(skip_bytes) &&
                lane < 32'(skip_bytes) + 32'(valid_bytes))
                valid_mask[lane] = 1'b1;
        end
    end

    assign busy = state != ST_IDLE;
    assign error = error_q;
    assign error_flags = error_flags_q;
    assign stream_data = stream_data_q;
    assign stream_keep = stream_keep_q;
    assign stream_valid = stream_valid_q;
    assign stream_last = stream_last_q;

    assign m_axi.aclk = clk;
    assign m_axi.aresetn = resetn;
    assign m_axi.awid = '0;
    assign m_axi.awaddr = '0;
    assign m_axi.awlen = '0;
    assign m_axi.awsize = AXI_SIZE;
    assign m_axi.awburst = 2'b01;
    assign m_axi.awlock = 1'b0;
    assign m_axi.awcache = 4'b0010;
    assign m_axi.awprot = 3'b000;
    assign m_axi.awqos = 4'b0000;
    assign m_axi.awvalid = 1'b0;
    assign m_axi.wdata = '0;
    assign m_axi.wstrb = '0;
    assign m_axi.wlast = 1'b0;
    assign m_axi.wvalid = 1'b0;
    assign m_axi.bready = 1'b0;
    assign m_axi.arid = '0;
    assign m_axi.araddr = burst_addr;
    assign m_axi.arlen = burst_beats[7:0] - 1'b1;
    assign m_axi.arsize = AXI_SIZE;
    assign m_axi.arburst = 2'b01;
    assign m_axi.arlock = 1'b0;
    assign m_axi.arcache = 4'b0010;
    assign m_axi.arprot = 3'b000;
    assign m_axi.arqos = 4'hf;
    assign m_axi.arvalid = state == ST_ISSUE;
    assign m_axi.rready = (state == ST_READ) && output_available;

    always @(posedge clk or negedge resetn) begin
        if (!resetn) begin
            state <= ST_IDLE;
            burst_addr <= '0;
            remaining_bytes <= 32'd0;
            skip_bytes <= '0;
            burst_beats <= 9'd0;
            beats_received <= 9'd0;
            error_q <= 1'b0;
            error_flags_q <= 3'b000;
            done <= 1'b0;
            bytes_read <= 32'd0;
            ar_requests <= 32'd0;
            read_beats <= 32'd0;
            stream_data_q <= '0;
            stream_keep_q <= '0;
            stream_valid_q <= 1'b0;
            stream_last_q <= 1'b0;
        end else begin
            done <= 1'b0;
            if (stream_fire)
                stream_valid_q <= 1'b0;

            case (state)
            ST_IDLE: begin
                if (start) begin
                    error_q <= 1'b0;
                    error_flags_q <= 3'b000;
                    bytes_read <= 32'd0;
                    ar_requests <= 32'd0;
                    read_beats <= 32'd0;
                    stream_valid_q <= 1'b0;
                    burst_addr <= {base_addr[ADDR_WIDTH-1:BYTE_SHIFT],
                                   {BYTE_SHIFT{1'b0}}};
                    skip_bytes <= base_addr[BYTE_SHIFT-1:0];
                    remaining_bytes <= byte_count;
                    if (byte_count == 0)
                        done <= 1'b1;
                    else
                        state <= ST_PLAN;
                end
            end
            ST_PLAN: begin
                burst_beats <= planned_beats;
                state <= ST_ISSUE;
            end
            ST_ISSUE: begin
                if (ar_fire) begin
                    ar_requests <= ar_requests + 1'b1;
                    beats_received <= 9'd0;
                    state <= ST_READ;
                end
            end
            ST_READ: begin
                if (r_fire) begin
                    stream_data_q <= m_axi.rdata;
                    stream_keep_q <= valid_mask;
                    stream_last_q <= remaining_bytes <= available_bytes;
                    stream_valid_q <= 1'b1;
                    remaining_bytes <= remaining_bytes - 32'(valid_bytes);
                    bytes_read <= bytes_read + 32'(valid_bytes);
                    read_beats <= read_beats + 1'b1;
                    skip_bytes <= '0;
                    beats_received <= beats_received + 1'b1;
                    if (m_axi.rresp != 2'b00) begin
                        error_q <= 1'b1;
                        error_flags_q[0] <= 1'b1;
                    end
                    if (m_axi.rid != {ID_WIDTH{1'b0}}) begin
                        error_q <= 1'b1;
                        error_flags_q[1] <= 1'b1;
                    end
                    if (m_axi.rlast !=
                        (beats_received + 1'b1 == burst_beats)) begin
                        error_q <= 1'b1;
                        error_flags_q[2] <= 1'b1;
                    end
                    if (beats_received + 1'b1 == burst_beats) begin
                        if (remaining_bytes <= available_bytes) begin
                            state <= ST_FINISH;
                        end else begin
                            burst_addr <= burst_addr +
                                          burst_beats * BYTE_LANES;
                            state <= ST_PLAN;
                        end
                    end
                end
            end
            ST_FINISH: begin
                if (!stream_valid_q) begin
                    done <= 1'b1;
                    state <= ST_IDLE;
                end
            end
            default: state <= ST_IDLE;
            endcase
        end
    end

    wire unused_write_response = &{1'b0, m_axi.awready, m_axi.wready,
                                   m_axi.bid, m_axi.bresp, m_axi.bvalid};
endmodule
