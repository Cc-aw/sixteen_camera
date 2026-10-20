// Conservative envelope of a future native Conv Store. Issued stores still
// drain through the original RS/controller/physical-DMA checks. Unknown layouts
// disable reuse; they must never force a producer to wait for its own consumer.
module CscR1StoreDisjoint(
    input wire active, known, no_pool, transpose,
    input wire [15:0] batches, rows, cols, outer_cols, stride, channels,
    input wire [39:0] base, source,
    input wire [40:0] source_end,
    output wire disjoint
);
    wire [63:0] span = (({48'd0, rows} - 1) * {48'd0, outer_cols} +
                        {48'd0, cols} - 1) * {48'd0, stride} + {48'd0, channels};
    wire [63:0] end_full = {24'd0, base} + span;
    // Include the entire aligned TL beat, even bytes masked out by the Store.
    wire [63:0] first_beat = {24'd0, base[39:6], 6'd0};
    wire [63:0] end_beat = (end_full + 63) & 64'hffffffffffffffc0;
    wire supported = known && no_pool && !transpose && batches == 1 &&
        rows != 0 && cols != 0 && cols <= outer_cols && channels != 0 &&
        channels <= stride && span < 64'h100000000 && end_full <= 64'h200000000;
    assign disjoint = !active || base == 0 || (supported &&
        (end_beat <= {24'd0, source} || first_beat >= {23'd0, source_end}));
endmodule
