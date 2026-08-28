`timescale 1ns/1ps

// One-worker, fixed-layout batch preprocessor.  A start operation consumes an
// already atomic frame snapshot.  Every channel owns one fixed tensor member;
// invalid snapshot members are zero-filled so the resulting Batch16 layout is
// deterministic even while only part of the sixteen inputs is installed.
module batch_preprocess_engine #(
    parameter integer CHANNELS = 16,
    parameter integer SRC_WIDTH = 640,
    parameter integer SRC_HEIGHT = 480,
    parameter integer SRC_STRIDE_BYTES = SRC_WIDTH * 4,
    // Keep this equal to the fixed model input contract (640x480x3 INT8).
    parameter integer DST_WIDTH = 640,
    parameter integer DST_HEIGHT = 480,
    parameter integer MEMBER_BYTES = DST_WIDTH * DST_HEIGHT * 3,
    parameter [31:0] ARENA0_BASE = 32'h3000_0000,
    parameter [31:0] ARENA1_BASE = 32'h3100_0000
) (
    input  wire                     clk,
    input  wire                     resetn,
    input  wire                     start,
    input  wire                     snapshot_active,
    input  wire [CHANNELS-1:0]      snapshot_valid_mask,
    input  wire [CHANNELS-1:0]      snapshot_fresh_mask,
    input  wire [CHANNELS*32-1:0]   snapshot_addrs,
    input  wire [63:0]              snapshot_batch_id,
    input  wire                     recycle,
    input  wire [1:0]               recycle_mask,
    input  wire [31:0]              arena0_base_cfg,
    input  wire [31:0]              arena1_base_cfg,
    input  wire [31:0]              member_stride_cfg,
    output reg                      command_done,
    output reg                      command_error,
    output reg                      busy,
    output reg  [1:0]               ready_mask,
    output reg                      active_arena,
    output reg  [4:0]               active_channel,
    output reg  [4:0]               completed_channels,
    output reg  [31:0]              active_tensor_base,
    output reg  [63:0]              arena0_batch_id,
    output reg  [63:0]              arena1_batch_id,
    output reg  [CHANNELS-1:0]      arena0_valid_mask,
    output reg  [CHANNELS-1:0]      arena1_valid_mask,
    output reg  [CHANNELS-1:0]      arena0_fresh_mask,
    output reg  [CHANNELS-1:0]      arena1_fresh_mask,
    output reg  [31:0]              batch_cycles,
    output reg  [31:0]              last_batch_cycles,
    output reg  [31:0]              last_read_beats,
    output reg  [31:0]              last_write_beats,
    output reg  [31:0]              start_count,
    output reg  [31:0]              complete_count,
    output reg  [31:0]              error_count,
    axi4_if.master                 m_axi
);
    localparam integer CHANNEL_WIDTH =
        (CHANNELS <= 1) ? 1 : $clog2(CHANNELS);

    reg [CHANNELS*32-1:0] snapshot_addrs_q;
    reg [CHANNELS-1:0] snapshot_valid_q;
    reg [CHANNELS-1:0] snapshot_fresh_q;
    reg [63:0] snapshot_batch_id_q;
    reg [31:0] member_stride_q;
    reg arena_preference;
    reg accel_start;
    wire accel_busy;
    wire accel_done;
    wire accel_error;
    wire [31:0] accel_cycles;
    wire [31:0] accel_read_beats;
    wire [31:0] accel_write_beats;

    wire free_arena0 = !ready_mask[0] && !(busy && !active_arena);
    wire free_arena1 = !ready_mask[1] && !(busy && active_arena);
    wire selected_arena =
        (arena_preference && free_arena1) ? 1'b1 :
        ((!arena_preference && free_arena0) ? 1'b0 : free_arena1);
    wire [31:0] selected_arena_base =
        selected_arena ? arena1_base_cfg : arena0_base_cfg;
    wire [CHANNEL_WIDTH-1:0] active_channel_index =
        active_channel[CHANNEL_WIDTH-1:0];
    wire active_source_valid = snapshot_valid_q[active_channel_index];
    wire [31:0] active_source_addr = snapshot_addrs_q[
        active_channel_index*32 +: 32];
    wire [31:0] active_dest_addr = active_tensor_base +
        active_channel * member_stride_q;

    initial begin
        if (CHANNELS < 1 || CHANNELS > 16 ||
            MEMBER_BYTES[4:0] != 0 || ARENA0_BASE[4:0] != 0 ||
            ARENA1_BASE[4:0] != 0)
            $error("batch_preprocess_engine parameters are invalid");
    end

    frame_preprocess_accel #(
        .SRC_WIDTH(SRC_WIDTH), .SRC_HEIGHT(SRC_HEIGHT),
        .SRC_STRIDE_BYTES(SRC_STRIDE_BYTES),
        .DST_WIDTH(DST_WIDTH), .DST_HEIGHT(DST_HEIGHT)
    ) u_frame_preprocess (
        .clk(clk), .resetn(resetn), .start(accel_start),
        .source_valid(active_source_valid),
        .source_addr(active_source_addr), .dest_addr(active_dest_addr),
        .busy(accel_busy), .done(accel_done), .error(accel_error),
        .cycles(accel_cycles), .read_beats(accel_read_beats),
        .write_beats(accel_write_beats), .m_axi(m_axi)
    );

    always @(posedge clk) begin
        if (!resetn) begin
            snapshot_addrs_q <= {CHANNELS*32{1'b0}};
            snapshot_valid_q <= {CHANNELS{1'b0}};
            snapshot_fresh_q <= {CHANNELS{1'b0}};
            snapshot_batch_id_q <= 64'd0;
            member_stride_q <= MEMBER_BYTES;
            arena_preference <= 1'b0;
            accel_start <= 1'b0;
            command_done <= 1'b0;
            command_error <= 1'b0;
            busy <= 1'b0;
            ready_mask <= 2'b00;
            active_arena <= 1'b0;
            active_channel <= 5'd0;
            completed_channels <= 5'd0;
            active_tensor_base <= 32'd0;
            arena0_batch_id <= 64'd0;
            arena1_batch_id <= 64'd0;
            arena0_valid_mask <= {CHANNELS{1'b0}};
            arena1_valid_mask <= {CHANNELS{1'b0}};
            arena0_fresh_mask <= {CHANNELS{1'b0}};
            arena1_fresh_mask <= {CHANNELS{1'b0}};
            batch_cycles <= 32'd0;
            last_batch_cycles <= 32'd0;
            last_read_beats <= 32'd0;
            last_write_beats <= 32'd0;
            start_count <= 32'd0;
            complete_count <= 32'd0;
            error_count <= 32'd0;
        end else begin
            accel_start <= 1'b0;
            command_done <= 1'b0;
            command_error <= 1'b0;

            if (busy)
                batch_cycles <= batch_cycles + 1'b1;

            if (recycle) begin
                if ((recycle_mask == 0) ||
                    (recycle_mask[active_arena] && busy)) begin
                    command_error <= 1'b1;
                    error_count <= error_count + 1'b1;
                end else begin
                    ready_mask <= ready_mask & ~recycle_mask;
                    command_done <= 1'b1;
                end
            end

            if (start) begin
                start_count <= start_count + 1'b1;
                if (busy || !snapshot_active ||
                    (!free_arena0 && !free_arena1)) begin
                    command_done <= 1'b1;
                    command_error <= 1'b1;
                    error_count <= error_count + 1'b1;
                end else begin
                    snapshot_addrs_q <= snapshot_addrs;
                    snapshot_valid_q <= snapshot_valid_mask;
                    snapshot_fresh_q <= snapshot_fresh_mask;
                    snapshot_batch_id_q <= snapshot_batch_id;
                    member_stride_q <= member_stride_cfg;
                    active_arena <= selected_arena;
                    active_tensor_base <= selected_arena_base;
                    arena_preference <= !selected_arena;
                    active_channel <= 5'd0;
                    completed_channels <= 5'd0;
                    batch_cycles <= 32'd0;
                    last_read_beats <= 32'd0;
                    last_write_beats <= 32'd0;
                    busy <= 1'b1;
                    accel_start <= 1'b1;
                    command_done <= 1'b1;
                end
            end

            if (busy && accel_done) begin
                last_read_beats <= last_read_beats + accel_read_beats;
                last_write_beats <= last_write_beats + accel_write_beats;
                if (accel_error) begin
                    busy <= 1'b0;
                    command_error <= 1'b1;
                    error_count <= error_count + 1'b1;
                    last_batch_cycles <= batch_cycles;
                end else if (active_channel + 1'b1 == CHANNELS) begin
                    busy <= 1'b0;
                    completed_channels <= CHANNELS[4:0];
                    ready_mask[active_arena] <= 1'b1;
                    last_batch_cycles <= batch_cycles;
                    complete_count <= complete_count + 1'b1;
                    if (!active_arena) begin
                        arena0_batch_id <= snapshot_batch_id_q;
                        arena0_valid_mask <= snapshot_valid_q;
                        arena0_fresh_mask <= snapshot_fresh_q;
                    end else begin
                        arena1_batch_id <= snapshot_batch_id_q;
                        arena1_valid_mask <= snapshot_valid_q;
                        arena1_fresh_mask <= snapshot_fresh_q;
                    end
                end else begin
                    active_channel <= active_channel + 1'b1;
                    completed_channels <= completed_channels + 1'b1;
                    accel_start <= 1'b1;
                end
            end
        end
    end
endmodule
