`timescale 1ns/1ps

// Streaming Top-256 followed by deterministic heap sort and class-aware NMS.
// Candidate order: score descending, then original location ascending,
// matching the board CPU implementation's stable scan on equal scores.
module yolov5nu_topk_nms #(
    parameter integer CAPACITY = 256,
    parameter integer RESULT_LIMIT = 32
) (
    input  wire         clk,
    input  wire         resetn,
    input  wire         start,
    input  wire [127:0] candidate_data,
    input  wire         candidate_valid,
    output wire         candidate_ready,
    input  wire         candidates_finished,
    output reg  [127:0] result_data,
    output reg          result_valid,
    input  wire         result_ready,
    output reg          result_last,
    output wire         sort_active, nms_active,
    output reg          busy,
    output reg          done,
    output reg  [15:0]  candidates_seen,
    output reg  [8:0]   retained_count,
    output reg  [5:0]   result_count
);
    localparam [3:0] ST_IDLE = 4'd0;
    localparam [3:0] ST_COLLECT = 4'd1;
    localparam [3:0] ST_UP = 4'd2;
    localparam [3:0] ST_DOWN = 4'd3;
    localparam [3:0] ST_SORT_SWAP = 4'd4;
    localparam [3:0] ST_SORT_DOWN = 4'd5;
    localparam [3:0] ST_NMS_PICK = 4'd6;
    localparam [3:0] ST_NMS_OUTPUT = 4'd7;
    localparam [3:0] ST_NMS_SCAN = 4'd8;
    localparam [3:0] ST_DONE = 4'd9;
    localparam [3:0] ST_NMS_EVAL = 4'd10;
    localparam [3:0] ST_UP_READ = 4'd11;
    localparam [3:0] ST_DOWN_READ = 4'd12;
    localparam [3:0] ST_SORT_DOWN_READ = 4'd13;

    reg [3:0] state;
    reg [127:0] heap [0:CAPACITY-1];
    reg [CAPACITY-1:0] suppressed;
    reg [127:0] work;
    reg [8:0] hole;
    reg [8:0] heap_size;
    reg [8:0] sort_size;
    reg [8:0] nms_pick;
    reg [8:0] nms_scan;
    reg [127:0] selected;
    reg [127:0] scan_entry;
    reg [127:0] parent_entry;
    reg [127:0] left_entry;
    reg [127:0] right_entry;
    reg finish_pending;

    wire [8:0] left_child = hole * 2 + 1'b1;
    wire [8:0] right_child = left_child + 1'b1;
    reg [8:0] worse_child;

    function automatic better(input [127:0] left, input [127:0] right);
        begin
            if (left[79:64] != right[79:64])
                better = left[79:64] > right[79:64];
            else
                // CPU NMS scans locations in ascending order on equal score.
                better = left[99:87] < right[99:87];
        end
    endfunction

    function automatic suppresses(input [127:0] a, input [127:0] b);
        reg [15:0] left, top, right, bottom;
        reg [31:0] intersection, area_a, area_b, union_area;
        begin
            left = a[15:0] > b[15:0] ? a[15:0] : b[15:0];
            top = a[31:16] > b[31:16] ? a[31:16] : b[31:16];
            right = a[47:32] < b[47:32] ? a[47:32] : b[47:32];
            bottom = a[63:48] < b[63:48] ? a[63:48] : b[63:48];
            intersection = right > left && bottom > top ?
                (right - left) * (bottom - top) : 0;
            area_a = a[47:32] > a[15:0] && a[63:48] > a[31:16] ?
                (a[47:32] - a[15:0]) * (a[63:48] - a[31:16]) : 0;
            area_b = b[47:32] > b[15:0] && b[63:48] > b[31:16] ?
                (b[47:32] - b[15:0]) * (b[63:48] - b[31:16]) : 0;
            union_area = area_a + area_b - intersection;
            // Existing runtime suppresses strictly above IoU 0.45.
            suppresses = a[86:80] == b[86:80] && union_area != 0 &&
                         intersection * 100 > union_area * 45;
        end
    endfunction

    always @* begin
        if (right_child < heap_size &&
            better(left_entry, right_entry))
            worse_child = right_child;
        else
            worse_child = left_child;
    end

    assign sort_active = state == ST_SORT_SWAP || state == ST_SORT_DOWN ||
                         state == ST_SORT_DOWN_READ;
    assign nms_active = state == ST_NMS_PICK || state == ST_NMS_OUTPUT ||
                        state == ST_NMS_SCAN || state == ST_NMS_EVAL;
    assign candidate_ready = state == ST_COLLECT && !finish_pending;

    always @(posedge clk) begin
        if (!resetn) begin
            state <= ST_IDLE;
            result_valid <= 1'b0;
            result_last <= 1'b0;
            busy <= 1'b0;
            done <= 1'b0;
            candidates_seen <= 16'd0;
            retained_count <= 9'd0;
            result_count <= 6'd0;
            suppressed <= '0;
            finish_pending <= 1'b0;
        end else begin
            done <= 1'b0;
            if (start && state == ST_IDLE) begin
                state <= ST_COLLECT;
                busy <= 1'b1;
                result_valid <= 1'b0;
                candidates_seen <= 16'd0;
                retained_count <= 9'd0;
                heap_size <= 9'd0;
                result_count <= 6'd0;
                suppressed <= '0;
                finish_pending <= 1'b0;
            end

            if (candidates_finished && state == ST_COLLECT)
                finish_pending <= 1'b1;

            case (state)
            ST_IDLE: begin end
            ST_COLLECT: begin
                if (candidate_valid && candidate_ready) begin
                    candidates_seen <= candidates_seen + 1'b1;
                    if (heap_size < CAPACITY) begin
                        work <= candidate_data;
                        hole <= heap_size;
                        heap_size <= heap_size + 1'b1;
                        retained_count <= heap_size + 1'b1;
                        state <= ST_UP_READ;
                    end else if (better(candidate_data, heap[0])) begin
                        work <= candidate_data;
                        hole <= 9'd0;
                        state <= ST_DOWN_READ;
                    end
                end else if (finish_pending || candidates_finished) begin
                    sort_size <= heap_size;
                    if (heap_size <= 1) begin
                        nms_pick <= 9'd0;
                        state <= ST_NMS_PICK;
                    end else begin
                        state <= ST_SORT_SWAP;
                    end
                end
            end
            ST_UP_READ: begin
                parent_entry <= heap[hole != 0 ? (hole-1'b1)>>1 : 9'd0];
                state <= ST_UP;
            end
            ST_UP: begin
                if (hole != 0 && better(parent_entry, work)) begin
                    heap[hole] <= parent_entry;
                    hole <= (hole-1'b1)>>1;
                    state <= ST_UP_READ;
                end else begin
                    heap[hole] <= work;
                    state <= ST_COLLECT;
                end
            end
            ST_DOWN_READ, ST_SORT_DOWN_READ: begin
                left_entry <= heap[left_child < heap_size ? left_child : 9'd0];
                right_entry <= heap[right_child < heap_size ? right_child : 9'd0];
                state <= state == ST_SORT_DOWN_READ ? ST_SORT_DOWN : ST_DOWN;
            end
            ST_DOWN, ST_SORT_DOWN: begin
                if (left_child < heap_size &&
                    better(work, worse_child == right_child ? right_entry : left_entry)) begin
                    heap[hole] <= worse_child == right_child ? right_entry : left_entry;
                    hole <= worse_child;
                    state <= state == ST_SORT_DOWN ? ST_SORT_DOWN_READ : ST_DOWN_READ;
                end else begin
                    heap[hole] <= work;
                    if (state == ST_SORT_DOWN) begin
                        if (sort_size <= 1) begin
                            heap_size <= retained_count;
                            nms_pick <= 9'd0;
                            state <= ST_NMS_PICK;
                        end else begin
                            state <= ST_SORT_SWAP;
                        end
                    end else begin
                        state <= ST_COLLECT;
                    end
                end
            end
            ST_SORT_SWAP: begin
                work <= heap[sort_size-1'b1];
                heap[sort_size-1'b1] <= heap[0];
                hole <= 9'd0;
                heap_size <= sort_size - 1'b1;
                sort_size <= sort_size - 1'b1;
                state <= ST_SORT_DOWN_READ;
            end
            ST_NMS_PICK: begin
                if (nms_pick >= retained_count ||
                    result_count >= RESULT_LIMIT) begin
                    state <= ST_DONE;
                end else if (suppressed[nms_pick]) begin
                    nms_pick <= nms_pick + 1'b1;
                end else begin
                    selected <= heap[nms_pick];
                    result_data <= heap[nms_pick];
                    result_valid <= 1'b1;
                    result_last <= result_count == RESULT_LIMIT-1 ||
                                   nms_pick == retained_count-1;
                    state <= ST_NMS_OUTPUT;
                end
            end
            ST_NMS_OUTPUT: begin
                if (result_valid && result_ready) begin
                    result_valid <= 1'b0;
                    result_count <= result_count + 1'b1;
                    nms_scan <= nms_pick + 1'b1;
                    if (result_count + 1'b1 >= RESULT_LIMIT ||
                        nms_pick + 1'b1 >= retained_count) begin
                        state <= ST_DONE;
                    end else begin
                        state <= ST_NMS_SCAN;
                    end
                end
            end
            ST_NMS_SCAN: begin
                if (nms_scan >= retained_count) begin
                    nms_pick <= nms_pick + 1'b1;
                    state <= ST_NMS_PICK;
                end else begin
                    scan_entry <= heap[nms_scan];
                    state <= ST_NMS_EVAL;
                end
            end
            ST_NMS_EVAL: begin
                if (suppresses(selected, scan_entry))
                    suppressed[nms_scan] <= 1'b1;
                nms_scan <= nms_scan + 1'b1;
                state <= ST_NMS_SCAN;
            end
            ST_DONE: begin
                busy <= 1'b0;
                done <= 1'b1;
                state <= ST_IDLE;
            end
            default: state <= ST_IDLE;
            endcase
        end
    end
endmodule
