`timescale 1ns/1ps

// Transfers tensor telemetry as indexed records instead of continuously
// synchronizing every slot and channel bit across the clock boundary.  The
// destination reconstructs the legacy packed arrays, so the CSR map remains
// unchanged while only one slot and one channel record cross at a time.
module tensor_telemetry_cdc #(
    parameter integer CHANNELS = 16,
    parameter integer SLOTS = 32
) (
    input  wire                   src_clk,
    input  wire                   src_resetn,
    input  wire [SLOTS*32-1:0]    src_frame_ids,
    input  wire [SLOTS-1:0]       src_ready_mask,
    input  wire [SLOTS-1:0]       src_writing_mask,
    input  wire [SLOTS-1:0]       src_error_mask,
    input  wire [SLOTS*64-1:0]    src_timestamps,
    input  wire [SLOTS*32-1:0]    src_versions,
    input  wire [SLOTS*8-1:0]     src_error_codes,
    input  wire [SLOTS*32-1:0]    src_byte_counts,
    input  wire [CHANNELS*32-1:0] src_no_slot_counts,
    input  wire [CHANNELS*32-1:0] src_missed_counts,
    input  wire [CHANNELS*32-1:0] src_admission_skip_counts,
    input  wire [CHANNELS*32-1:0] src_overflow_counts,
    input  wire                   dst_clk,
    input  wire                   dst_resetn,
    output reg  [SLOTS*32-1:0]    dst_frame_ids = 0,
    output reg  [SLOTS-1:0]       dst_ready_mask = 0,
    output reg  [SLOTS-1:0]       dst_writing_mask = 0,
    output reg  [SLOTS-1:0]       dst_error_mask = 0,
    output reg  [SLOTS*64-1:0]    dst_timestamps = 0,
    output reg  [SLOTS*32-1:0]    dst_versions = 0,
    output reg  [SLOTS*8-1:0]     dst_error_codes = 0,
    output reg  [SLOTS*32-1:0]    dst_byte_counts = 0,
    output reg  [CHANNELS*32-1:0] dst_no_slot_counts = 0,
    output reg  [CHANNELS*32-1:0] dst_missed_counts = 0,
    output reg  [CHANNELS*32-1:0] dst_admission_skip_counts = 0,
    output reg  [CHANNELS*32-1:0] dst_overflow_counts = 0
);
    localparam integer SLOT_INDEX_WIDTH = SLOTS <= 1 ? 1 : $clog2(SLOTS);
    localparam integer CHANNEL_INDEX_WIDTH = CHANNELS <= 1 ? 1 :
                                               $clog2(CHANNELS);
    localparam integer SLOT_RECORD_WIDTH = SLOT_INDEX_WIDTH + 171;
    localparam integer CHANNEL_RECORD_WIDTH = CHANNEL_INDEX_WIDTH + 128;

    reg [SLOT_INDEX_WIDTH-1:0] slot_index;
    reg [CHANNEL_INDEX_WIDTH-1:0] channel_index;
    wire slot_ready;
    wire channel_ready;
    wire [SLOT_RECORD_WIDTH-1:0] slot_record_src = {
        slot_index,
        src_error_mask[slot_index],
        src_writing_mask[slot_index],
        src_ready_mask[slot_index],
        src_byte_counts[slot_index*32 +: 32],
        src_error_codes[slot_index*8 +: 8],
        src_versions[slot_index*32 +: 32],
        src_timestamps[slot_index*64 +: 64],
        src_frame_ids[slot_index*32 +: 32]
    };
    wire [CHANNEL_RECORD_WIDTH-1:0] channel_record_src = {
        channel_index,
        src_overflow_counts[channel_index*32 +: 32],
        src_admission_skip_counts[channel_index*32 +: 32],
        src_missed_counts[channel_index*32 +: 32],
        src_no_slot_counts[channel_index*32 +: 32]
    };
    wire [SLOT_RECORD_WIDTH-1:0] slot_record_dst;
    wire [CHANNEL_RECORD_WIDTH-1:0] channel_record_dst;
    wire slot_record_valid;
    wire channel_record_valid;
    wire [SLOT_INDEX_WIDTH-1:0] slot_index_dst =
        slot_record_dst[SLOT_RECORD_WIDTH-1 -: SLOT_INDEX_WIDTH];
    wire [CHANNEL_INDEX_WIDTH-1:0] channel_index_dst =
        channel_record_dst[CHANNEL_RECORD_WIDTH-1 -: CHANNEL_INDEX_WIDTH];

    always @(posedge src_clk) begin
        if (!src_resetn) begin
            slot_index <= 0;
            channel_index <= 0;
        end else begin
            if (slot_ready)
                slot_index <= slot_index == SLOTS-1 ? 0 : slot_index + 1'b1;
            if (channel_ready)
                channel_index <= channel_index == CHANNELS-1 ?
                                 0 : channel_index + 1'b1;
        end
    end

    cdc_mailbox #(.WIDTH(SLOT_RECORD_WIDTH)) u_slot_mailbox (
        .src_clk(src_clk), .src_resetn(src_resetn),
        .src_data(slot_record_src), .src_valid(1'b1),
        .src_ready(slot_ready), .src_done(),
        .dst_clk(dst_clk), .dst_resetn(dst_resetn),
        .dst_data(slot_record_dst), .dst_valid(slot_record_valid)
    );

    cdc_mailbox #(.WIDTH(CHANNEL_RECORD_WIDTH)) u_channel_mailbox (
        .src_clk(src_clk), .src_resetn(src_resetn),
        .src_data(channel_record_src), .src_valid(1'b1),
        .src_ready(channel_ready), .src_done(),
        .dst_clk(dst_clk), .dst_resetn(dst_resetn),
        .dst_data(channel_record_dst), .dst_valid(channel_record_valid)
    );

    always @(posedge dst_clk) begin
        if (slot_record_valid) begin
            dst_frame_ids[slot_index_dst*32 +: 32] <=
                slot_record_dst[0 +: 32];
            dst_timestamps[slot_index_dst*64 +: 64] <=
                slot_record_dst[32 +: 64];
            dst_versions[slot_index_dst*32 +: 32] <=
                slot_record_dst[96 +: 32];
            dst_error_codes[slot_index_dst*8 +: 8] <=
                slot_record_dst[128 +: 8];
            dst_byte_counts[slot_index_dst*32 +: 32] <=
                slot_record_dst[136 +: 32];
            dst_ready_mask[slot_index_dst] <= slot_record_dst[168];
            dst_writing_mask[slot_index_dst] <= slot_record_dst[169];
            dst_error_mask[slot_index_dst] <= slot_record_dst[170];
        end
        if (channel_record_valid) begin
            dst_no_slot_counts[channel_index_dst*32 +: 32] <=
                channel_record_dst[0 +: 32];
            dst_missed_counts[channel_index_dst*32 +: 32] <=
                channel_record_dst[32 +: 32];
            dst_admission_skip_counts[channel_index_dst*32 +: 32] <=
                channel_record_dst[64 +: 32];
            dst_overflow_counts[channel_index_dst*32 +: 32] <=
                channel_record_dst[96 +: 32];
        end
    end

    initial begin
        if (SLOTS < 1 || SLOTS > (1 << SLOT_INDEX_WIDTH))
            $error("invalid tensor telemetry slot count");
        if (CHANNELS < 1 || CHANNELS > (1 << CHANNEL_INDEX_WIDTH))
            $error("invalid tensor telemetry channel count");
    end
endmodule
