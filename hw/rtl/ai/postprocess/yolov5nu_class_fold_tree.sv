`timescale 1ns/1ps
// Balanced, stable maxima for the two possible locations in a byte group.
// keep compacts valid bytes exactly as the original serial fold did.
module yolov5nu_class_fold_tree #(
    parameter integer BYTES = 16,
    parameter integer CLASSES = 80
)(
    input wire [BYTES*8-1:0] data,
    input wire [BYTES-1:0] keep,
    input wire [6:0] class_index, best_class,
    input wire signed [7:0] best_score,
    output wire [6:0] next_index, next_class, result_class,
    output wire signed [7:0] next_score, result_score,
    output wire emits
);
    wire [7:0] prefix [0:BYTES];
    wire [15:0] before_tree [1:2*BYTES-1];
    wire [15:0] after_tree [1:2*BYTES-1];
    assign prefix[0] = {1'b0,class_index};
    function automatic [15:0] maximum(input [15:0] a,b);
        if (!a[15]) maximum=b;
        else if (!b[15]) maximum=a;
        else if ($signed(a[14:7]) > $signed(b[14:7]) ||
                 (a[14:7] == b[14:7] && a[6:0] <= b[6:0])) maximum=a;
        else maximum=b;
    endfunction
    for (genvar i=0;i<BYTES;i=i+1) begin : g_leaf
        assign prefix[i+1] = prefix[i] + {7'd0,keep[i]};
        assign before_tree[BYTES+i] =
            {keep[i] && prefix[i] < CLASSES, data[i*8+:8], prefix[i][6:0]};
        wire [6:0] tail_index = 7'(prefix[i]-CLASSES);
        assign after_tree[BYTES+i] =
            {keep[i] && prefix[i] >= CLASSES, data[i*8+:8], tail_index};
    end
    for (genvar i=1;i<BYTES;i=i+1) begin : g_node
        assign before_tree[i] = maximum(before_tree[2*i],before_tree[2*i+1]);
        assign after_tree[i] = maximum(after_tree[2*i],after_tree[2*i+1]);
    end
    wire [15:0] leading = maximum({1'b1,best_score,best_class},before_tree[1]);
    wire [15:0] trailing = maximum({1'b1,8'h80,7'd0},after_tree[1]);
    assign emits = prefix[BYTES] >= CLASSES;
    assign next_index = 7'(emits ? prefix[BYTES]-CLASSES : prefix[BYTES]);
    assign result_score = leading[14:7];
    assign result_class = leading[6:0];
    assign next_score = emits ? trailing[14:7] : leading[14:7];
    assign next_class = emits ? trailing[6:0] : leading[6:0];
endmodule
