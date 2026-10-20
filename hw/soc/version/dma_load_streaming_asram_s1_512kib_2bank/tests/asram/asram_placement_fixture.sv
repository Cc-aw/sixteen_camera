// Constraint-selection fixture only: real 216 URAM primitives, no TL/SoC model.
module asram_placement_fixture (
    input wire clock,
    input wire [2:0] a_en, a_write, b_en, b_write,
    input wire [50:0] a_word, b_word,
    input wire [95:0] a_mask, b_mask,
    input wire [767:0] a_data, b_data,
    output wire [767:0] a_read, b_read
);
    (* KEEP_HIERARCHY = "yes" *) asram_fixture_tile tile (.*);
endmodule

module asram_fixture_tile (
    input wire clock,
    input wire [2:0] a_en, a_write, b_en, b_write,
    input wire [50:0] a_word, b_word,
    input wire [95:0] a_mask, b_mask,
    input wire [767:0] a_data, b_data,
    output wire [767:0] a_read, b_read
);
    (* KEEP_HIERARCHY = "yes" *) asram_fixture_bank activationSrams (
        .clock(clock),
        .a_en(a_en[0]),
        .a_write(a_write[0]),
        .a_word(a_word[0 +: 17]),
        .a_mask(a_mask[0 +: 32]),
        .a_data(a_data[0 +: 256]),
        .a_read(a_read[0 +: 256]),
        .b_en(b_en[0]),
        .b_write(b_write[0]),
        .b_word(b_word[0 +: 17]),
        .b_mask(b_mask[0 +: 32]),
        .b_data(b_data[0 +: 256]),
        .b_read(b_read[0 +: 256])
    );
    (* KEEP_HIERARCHY = "yes" *) asram_fixture_bank activationSrams_1 (
        .clock(clock),
        .a_en(a_en[1]),
        .a_write(a_write[1]),
        .a_word(a_word[17 +: 17]),
        .a_mask(a_mask[32 +: 32]),
        .a_data(a_data[256 +: 256]),
        .a_read(a_read[256 +: 256]),
        .b_en(b_en[1]),
        .b_write(b_write[1]),
        .b_word(b_word[17 +: 17]),
        .b_mask(b_mask[32 +: 32]),
        .b_data(b_data[256 +: 256]),
        .b_read(b_read[256 +: 256])
    );
    (* KEEP_HIERARCHY = "yes" *) asram_fixture_bank activationSrams_2 (
        .clock(clock),
        .a_en(a_en[2]),
        .a_write(a_write[2]),
        .a_word(a_word[34 +: 17]),
        .a_mask(a_mask[64 +: 32]),
        .a_data(a_data[512 +: 256]),
        .a_read(a_read[512 +: 256]),
        .b_en(b_en[2]),
        .b_write(b_write[2]),
        .b_word(b_word[34 +: 17]),
        .b_mask(b_mask[64 +: 32]),
        .b_data(b_data[512 +: 256]),
        .b_read(b_read[512 +: 256])
    );
endmodule

module asram_fixture_bank (
    input  wire         clock,
    input  wire         a_en,
    input  wire         a_write,
    input  wire [16:0]  a_word,
    input  wire [31:0]  a_mask,
    input  wire [255:0] a_data,
    output wire [255:0] a_read,
    input  wire         b_en,
    input  wire         b_write,
    input  wire [16:0]  b_word,
    input  wire [31:0]  b_mask,
    input  wire [255:0] b_data,
    output wire [255:0] b_read
);
    (* KEEP_HIERARCHY = "yes" *) activation_sram_store backing (.*);
endmodule
