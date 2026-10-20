// ASRAM-1: one physical backing store, two synchronous read/write ports.
// 18 depth groups x 4 URAM288_BASE, PARITY_INDEPENDENT: bits [63:0]
// carry eight ordinary bytes; parity [71:64] is unused and never counted.
// Data arrays have NO reset. The controller serializes cross-port hazards.
module activation_sram_store (
    input  wire         clock,
    input  wire         a_en,
    input  wire         a_write,
    input  wire [16:0]  a_word,
    input  wire [31:0]  a_mask,
    input  wire [255:0] a_data,
    output reg  [255:0] a_read,
    input  wire         b_en,
    input  wire         b_write,
    input  wire [16:0]  b_word,
    input  wire [31:0]  b_mask,
    input  wire [255:0] b_data,
    output reg  [255:0] b_read
);
    wire [255:0] group_a [0:17];
    wire [255:0] group_b [0:17];
    reg [4:0] select_a, select_b;
    // First edge: physical synchronous read. Second edge: selected output
    // register. Metadata in the TL controller traverses exactly two stages.
    always @(posedge clock) begin
        if (a_en) select_a <= a_word[16:12];
        if (b_en) select_b <= b_word[16:12];
        a_read <= group_a[select_a];
        b_read <= group_b[select_b];
    end

    genvar depth, slice;
    generate for (depth = 0; depth < 18; depth = depth + 1) begin : groups
        for (slice = 0; slice < 4; slice = slice + 1) begin : slices
            wire ena = a_en && a_word[16:12] == depth;
            wire enb = b_en && b_word[16:12] == depth;
`ifdef ASRAM_BEHAVIORAL
            // Protocol/reference simulation only; production always uses
            // the primitive below, never infers a second CPU data copy.
            reg [63:0] bytes_mem [0:4095];
            reg [63:0] qa, qb;
            integer lane;
            always @(posedge clock) begin
                if (ena) begin
                    if (a_write) begin
                        for (lane = 0; lane < 8; lane = lane + 1)
                            if (a_mask[slice*8+lane])
                                bytes_mem[a_word[11:0]][lane*8 +: 8] <= a_data[slice*64+lane*8 +: 8];
                    end else qa <= bytes_mem[a_word[11:0]];
                end
                if (enb) begin
                    if (b_write) begin
                        for (lane = 0; lane < 8; lane = lane + 1)
                            if (b_mask[slice*8+lane])
                                bytes_mem[b_word[11:0]][lane*8 +: 8] <= b_data[slice*64+lane*8 +: 8];
                    end else qb <= bytes_mem[b_word[11:0]];
                end
            end
            assign group_a[depth][slice*64 +: 64] = qa;
            assign group_b[depth][slice*64 +: 64] = qb;
`else
            wire [71:0] qa, qb;
            URAM288_BASE #(
                .BWE_MODE_A("PARITY_INDEPENDENT"),
                .BWE_MODE_B("PARITY_INDEPENDENT"),
                .EN_ECC_RD_A("FALSE"), .EN_ECC_WR_A("FALSE"),
                .EN_ECC_RD_B("FALSE"), .EN_ECC_WR_B("FALSE"),
                .OREG_A("FALSE"), .OREG_B("FALSE"),
                .IREG_PRE_A("FALSE"), .IREG_PRE_B("FALSE")
            ) uram (
                .CLK(clock),
                .ADDR_A({11'b0, a_word[11:0]}),
                .ADDR_B({11'b0, b_word[11:0]}),
                .DIN_A({8'b0, a_data[slice*64 +: 64]}),
                .DIN_B({8'b0, b_data[slice*64 +: 64]}),
                .DOUT_A(qa), .DOUT_B(qb),
                .BWE_A({1'b0, a_mask[slice*8 +: 8]}),
                .BWE_B({1'b0, b_mask[slice*8 +: 8]}),
                .EN_A(ena), .EN_B(enb), .RDB_WR_A(a_write), .RDB_WR_B(b_write),
                .RST_A(1'b0), .RST_B(1'b0), .SLEEP(1'b0),
                .OREG_CE_A(1'b1), .OREG_CE_B(1'b1),
                .OREG_ECC_CE_A(1'b1), .OREG_ECC_CE_B(1'b1),
                .INJECT_SBITERR_A(1'b0), .INJECT_DBITERR_A(1'b0),
                .INJECT_SBITERR_B(1'b0), .INJECT_DBITERR_B(1'b0),
                .SBITERR_A(), .DBITERR_A(), .SBITERR_B(), .DBITERR_B()
            );
            assign group_a[depth][slice*64 +: 64] = qa[63:0];
            assign group_b[depth][slice*64 +: 64] = qb[63:0];
`endif
        end
    end endgenerate
endmodule
