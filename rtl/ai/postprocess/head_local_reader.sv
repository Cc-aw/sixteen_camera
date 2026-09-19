`timescale 1ns/1ps

// Converts a byte-range request into the same ordered stream contract used by
// fbus_read_engine. Bank selection is deliberately external: base_addr keeps
// the existing physical Head ABI, while only its slot-local low bits address
// the selected URAM bank.
module head_local_reader #(
    parameter integer ADDR_WIDTH = 33,
    parameter integer DATA_WIDTH = 256,
    parameter integer SLOT_BYTES = 1024 * 1024
) (
    input  wire                         clk,
    input  wire                         resetn,
    input  wire                         start,
    input  wire [ADDR_WIDTH-1:0]        base_addr,
    input  wire [31:0]                  byte_count,
    output wire                         busy,
    output reg                          done,
    output reg                          error,
    output reg  [2:0]                   error_flags,
    output reg  [31:0]                  bytes_read,

    output wire                         memory_req_valid,
    input  wire                         memory_req_ready,
    output wire [$clog2(SLOT_BYTES/(DATA_WIDTH/8))-1:0]
                                             memory_req_word_addr,
    input  wire [DATA_WIDTH-1:0]        memory_rsp_data,
    input  wire                         memory_rsp_valid,
    output wire                         memory_rsp_ready,

    output wire [DATA_WIDTH-1:0]        stream_data,
    output wire [DATA_WIDTH/8-1:0]      stream_keep,
    output wire                         stream_valid,
    input  wire                         stream_ready,
    output wire                         stream_last
);
    localparam integer BYTE_LANES = DATA_WIDTH / 8;
    localparam integer BYTE_SHIFT = $clog2(BYTE_LANES);
    localparam integer OFFSET_WIDTH = $clog2(SLOT_BYTES);
    localparam integer WORD_ADDR_WIDTH =
        $clog2(SLOT_BYTES / BYTE_LANES);

    reg busy_q;
    reg [WORD_ADDR_WIDTH-1:0] issue_word_addr_q;
    reg [31:0] issue_remaining_q;
    reg [BYTE_SHIFT-1:0] issue_skip_q;
    reg [BYTE_LANES-1:0] response_keep_q;
    reg [BYTE_SHIFT:0] response_bytes_q;
    reg response_last_q;

    reg [BYTE_SHIFT:0] issue_capacity;
    reg [BYTE_SHIFT:0] issue_bytes;
    reg [BYTE_LANES-1:0] issue_keep;
    always @* begin
        issue_capacity = (BYTE_SHIFT+1)'(BYTE_LANES) -
                         {1'b0, issue_skip_q};
        if (issue_remaining_q < issue_capacity)
            issue_bytes = issue_remaining_q[BYTE_SHIFT:0];
        else
            issue_bytes = issue_capacity;
        issue_keep = '0;
        for (integer lane = 0; lane < BYTE_LANES; lane = lane + 1)
            if (lane >= 32'(issue_skip_q) &&
                lane < 32'(issue_skip_q) + 32'(issue_bytes))
                issue_keep[lane] = 1'b1;
    end

    wire request_fire = memory_req_valid && memory_req_ready;
    wire stream_fire = stream_valid && stream_ready;
    wire [OFFSET_WIDTH:0] requested_end =
        {1'b0, base_addr[OFFSET_WIDTH-1:0]} +
        (OFFSET_WIDTH+1)'(byte_count);
    wire request_in_range = requested_end <= (OFFSET_WIDTH+1)'(SLOT_BYTES);

    assign busy = busy_q;
    assign memory_req_valid = busy_q && issue_remaining_q != 0;
    assign memory_req_word_addr = issue_word_addr_q;
    assign memory_rsp_ready = stream_ready;
    assign stream_data = memory_rsp_data;
    assign stream_keep = response_keep_q;
    assign stream_valid = memory_rsp_valid;
    assign stream_last = response_last_q;

    initial begin
        if (ADDR_WIDTH < OFFSET_WIDTH || DATA_WIDTH < 8 ||
            (DATA_WIDTH & (DATA_WIDTH - 1)) != 0 ||
            (DATA_WIDTH % 8) != 0 || SLOT_BYTES < BYTE_LANES ||
            (SLOT_BYTES & (SLOT_BYTES - 1)) != 0 ||
            (SLOT_BYTES % BYTE_LANES) != 0)
            $error("head_local_reader parameters are invalid");
    end

    always @(posedge clk or negedge resetn) begin
        if (!resetn) begin
            busy_q <= 1'b0;
            done <= 1'b0;
            error <= 1'b0;
            error_flags <= 3'b000;
            bytes_read <= 32'd0;
            issue_word_addr_q <= '0;
            issue_remaining_q <= 32'd0;
            issue_skip_q <= '0;
            response_keep_q <= '0;
            response_bytes_q <= '0;
            response_last_q <= 1'b0;
        end else begin
            done <= 1'b0;

            if (start && busy_q) begin
                error <= 1'b1;
                error_flags[1] <= 1'b1;
            end

            if (start && !busy_q) begin
                error <= 1'b0;
                error_flags <= 3'b000;
                bytes_read <= 32'd0;
                issue_word_addr_q <=
                    base_addr[OFFSET_WIDTH-1:BYTE_SHIFT];
                issue_remaining_q <= byte_count;
                issue_skip_q <= base_addr[BYTE_SHIFT-1:0];
                if (byte_count == 0) begin
                    busy_q <= 1'b0;
                    done <= 1'b1;
                end else if (!request_in_range) begin
                    busy_q <= 1'b0;
                    done <= 1'b1;
                    error <= 1'b1;
                    error_flags[0] <= 1'b1;
                end else begin
                    busy_q <= 1'b1;
                end
            end

            if (request_fire) begin
                issue_word_addr_q <= issue_word_addr_q + 1'b1;
                issue_remaining_q <= issue_remaining_q - 32'(issue_bytes);
                issue_skip_q <= '0;
                response_keep_q <= issue_keep;
                response_bytes_q <= issue_bytes;
                response_last_q <= issue_remaining_q == 32'(issue_bytes);
            end

            if (stream_fire) begin
                bytes_read <= bytes_read + 32'(response_bytes_q);
                if (response_last_q) begin
                    busy_q <= 1'b0;
                    done <= 1'b1;
                end
            end
        end
    end
endmodule
