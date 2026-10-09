`timescale 1ns/1ps

// Owns independent frame-buffer pools for a configurable set of capture
// channels and lends
// exactly one complete buffer to the display reader. Channel changes are
// committed only between output frames; an unavailable target never blanks
// the current display.
module multi_channel_frame_manager #(
    parameter integer CHANNELS = 3,
    parameter integer PIXEL_BYTES = 4,
    parameter integer MAX_BUFFERS_PER_CHANNEL = 5
) (
    input  wire                              ui_clk,
    input  wire                              ui_resetn,
    input  wire                              cfg_request_toggle,
    output reg                               cfg_ack_toggle,
    input  wire                              cfg_enable,
    input  wire [31:0]                       cfg_width,
    input  wire [31:0]                       cfg_height,
    input  wire [31:0]                       cfg_stride_bytes,
    input  wire [31:0]                       cfg_buffers_per_channel,
    input  wire [CHANNELS*32-1:0]            cfg_channel_bases,
    input  wire [31:0]                       cfg_buffer_stride_bytes,
    input  wire [((CHANNELS <= 1) ? 1 : $clog2(CHANNELS))-1:0]
                                               cfg_display_channel,
    input  wire                              cfg_display_mode,

    input  wire [CHANNELS-1:0]               writer_acquire,
    output reg  [CHANNELS-1:0]               writer_grant,
    output reg  [CHANNELS-1:0]               writer_drop,
    output reg  [CHANNELS*32-1:0]            writer_base,
    input  wire [CHANNELS-1:0]               writer_done,
    input  wire [CHANNELS-1:0]               writer_error,

    input  wire                              reader_acquire,
    output reg                               reader_grant,
    output reg  [31:0]                       reader_base,
    output reg  [CHANNELS*32-1:0]            reader_bases,
    output reg  [CHANNELS-1:0]               reader_valid_mask,
    output reg                               reader_mode,
    input  wire                              reader_done,
    input  wire                              reader_underflow,

    output reg  [31:0]                       active_width,
    output reg  [31:0]                       active_height,
    output reg  [31:0]                       active_stride_bytes,
    output reg  [CHANNELS*32-1:0]            writer_frame_counts,
    output reg  [31:0]                       reader_frame_count,
    output reg  [CHANNELS*32-1:0]            drop_counts,
    output reg  [31:0]                       underflow_count,
    output reg  [31:0]                       status
);
    localparam integer SLOT_WIDTH = (MAX_BUFFERS_PER_CHANNEL <= 1) ?
                                     1 : $clog2(MAX_BUFFERS_PER_CHANNEL);
    localparam integer CHANNEL_WIDTH = (CHANNELS <= 1) ?
                                        1 : $clog2(CHANNELS);
    localparam [1:0] BUFFER_FREE    = 2'd0;
    localparam [1:0] BUFFER_WRITING = 2'd1;
    localparam [1:0] BUFFER_READY   = 2'd2;
    localparam [1:0] BUFFER_READING = 2'd3;

    (* ASYNC_REG = "TRUE" *) reg cfg_sync_1;
    (* ASYNC_REG = "TRUE" *) reg cfg_sync_2;
    (* ASYNC_REG = "TRUE" *) reg [CHANNEL_WIDTH-1:0] select_sync_1;
    (* ASYNC_REG = "TRUE" *) reg [CHANNEL_WIDTH-1:0] select_sync_2;
    (* ASYNC_REG = "TRUE" *) reg mode_sync_1;
    (* ASYNC_REG = "TRUE" *) reg mode_sync_2;

    // Slot addresses are calculated only when a new configuration is
    // committed.  The frame-rate path can then select a registered address
    // instead of implementing base + slot * stride at 300 MHz.
    reg [31:0] active_slot_bases [0:CHANNELS-1]
                                  [0:MAX_BUFFERS_PER_CHANNEL-1];
    reg [MAX_BUFFERS_PER_CHANNEL-1:0] active_slot_mask;
    reg [2:0] active_buffer_count;
    reg [1:0] buffer_state [0:CHANNELS-1][0:MAX_BUFFERS_PER_CHANNEL-1];
    reg writer_active [0:CHANNELS-1];
    reg [SLOT_WIDTH-1:0] writer_index [0:CHANNELS-1];
    reg drop_reported [0:CHANNELS-1];
    reg latest_ready_valid [0:CHANNELS-1];
    reg [SLOT_WIDTH-1:0] latest_ready_index [0:CHANNELS-1];
    reg reader_active;
    reg [CHANNEL_WIDTH-1:0] reader_channel;
    reg [SLOT_WIDTH-1:0] display_index [0:CHANNELS-1];

    integer ch;
    integer slot;
    integer free_slot;

    function automatic [31:0] slot_address;
        input integer channel_number;
        input integer slot_number;
        begin
            slot_address = active_slot_bases[channel_number][slot_number];
        end
    endfunction

    function automatic integer find_free_slot;
        input integer channel_number;
        integer search_slot;
        begin
            find_free_slot = -1;
            for (search_slot = 0; search_slot < MAX_BUFFERS_PER_CHANNEL;
                 search_slot = search_slot + 1)
                if (active_slot_mask[search_slot] &&
                    (buffer_state[channel_number][search_slot] == BUFFER_FREE) &&
                    (find_free_slot < 0))
                    find_free_slot = search_slot;
        end
    endfunction

    wire [CHANNEL_WIDTH-1:0] requested_channel = select_sync_2;
    wire requested_channel_valid = (requested_channel < CHANNELS);
    wire requested_ready = requested_channel_valid &&
        latest_ready_valid[requested_channel] &&
        (buffer_state[requested_channel]
                     [latest_ready_index[requested_channel]] == BUFFER_READY);
    wire requested_writer_completes = requested_channel_valid &&
        writer_done[requested_channel] && writer_active[requested_channel] &&
        !writer_error[requested_channel];
    wire [CHANNELS-1:0] writer_active_vector;
    wire [CHANNELS-1:0] latest_ready_vector;
    generate
        genvar active_ch;
        for (active_ch = 0; active_ch < CHANNELS;
             active_ch = active_ch + 1) begin : g_writer_active_vector
            assign writer_active_vector[active_ch] = writer_active[active_ch];
            assign latest_ready_vector[active_ch] =
                latest_ready_valid[active_ch];
        end
    endgenerate
    wire any_writer_active = |writer_active_vector;
    wire any_writer_response_pending = |writer_grant || |writer_drop;

    always @* begin
        status = 32'd0;
        status[3:0] = requested_channel;
        status[7:4] = reader_channel;
        status[8] = reader_active;
        status[9] = (cfg_sync_2 != cfg_ack_toggle);
        status[12:10] = active_buffer_count;
        status[13] = any_writer_active;
        for (ch = 0; ch < CHANNELS; ch = ch + 1)
            status[14+ch] = writer_active[ch];
        status[30] = |latest_ready_vector;
        status[31] = any_writer_response_pending;
    end

    initial begin
        if (CHANNELS < 1 || CHANNELS > 16 || MAX_BUFFERS_PER_CHANNEL < 2 ||
            MAX_BUFFERS_PER_CHANNEL > 5)
            $error("multi_channel_frame_manager supports 1-16 channels and 2-5 slots");
    end

    always @(posedge ui_clk) begin
        if (!ui_resetn) begin
            cfg_sync_1 <= 1'b0;
            cfg_sync_2 <= 1'b0;
            select_sync_1 <= {CHANNEL_WIDTH{1'b0}};
            select_sync_2 <= {CHANNEL_WIDTH{1'b0}};
            mode_sync_1 <= 1'b0;
            mode_sync_2 <= 1'b0;
            cfg_ack_toggle <= 1'b0;
            active_width <= 32'd640;
            active_height <= 32'd480;
            active_stride_bytes <= 32'd2560;
            active_buffer_count <= 3'd0;
            active_slot_mask <= {MAX_BUFFERS_PER_CHANNEL{1'b0}};
            writer_grant <= {CHANNELS{1'b0}};
            writer_drop <= {CHANNELS{1'b0}};
            writer_base <= {CHANNELS*32{1'b0}};
            writer_frame_counts <= {CHANNELS*32{1'b0}};
            drop_counts <= {CHANNELS*32{1'b0}};
            reader_grant <= 1'b0;
            reader_base <= 32'd0;
            reader_bases <= {CHANNELS*32{1'b0}};
            reader_valid_mask <= {CHANNELS{1'b0}};
            reader_mode <= 1'b0;
            reader_frame_count <= 32'd0;
            underflow_count <= 32'd0;
            reader_active <= 1'b0;
            reader_channel <= {CHANNEL_WIDTH{1'b0}};
            for (ch = 0; ch < CHANNELS; ch = ch + 1) begin
                writer_active[ch] <= 1'b0;
                writer_index[ch] <= {SLOT_WIDTH{1'b0}};
                drop_reported[ch] <= 1'b0;
                latest_ready_valid[ch] <= 1'b0;
                latest_ready_index[ch] <= {SLOT_WIDTH{1'b0}};
                display_index[ch] <= {SLOT_WIDTH{1'b0}};
                for (slot = 0; slot < MAX_BUFFERS_PER_CHANNEL;
                     slot = slot + 1)
                    begin
                        buffer_state[ch][slot] <= BUFFER_FREE;
                        active_slot_bases[ch][slot] <= 32'd0;
                    end
            end
        end else begin
            cfg_sync_1 <= cfg_request_toggle;
            cfg_sync_2 <= cfg_sync_1;
            select_sync_1 <= cfg_display_channel;
            select_sync_2 <= select_sync_1;
            mode_sync_1 <= cfg_display_mode;
            mode_sync_2 <= mode_sync_1;
            reader_grant <= 1'b0;

            // Configuration buses remain stable until this acknowledgement.
            if ((cfg_sync_2 != cfg_ack_toggle) && !any_writer_active &&
                !any_writer_response_pending && !reader_active) begin
                active_width <= cfg_width;
                active_height <= cfg_height;
                active_stride_bytes <= cfg_stride_bytes;
                if (cfg_enable && (cfg_buffers_per_channel >= 2) &&
                    (cfg_buffers_per_channel <= MAX_BUFFERS_PER_CHANNEL) &&
                    (cfg_width != 0) && (cfg_height != 0) &&
                    (cfg_width[2:0] == 0) &&
                    (cfg_stride_bytes >= cfg_width*PIXEL_BYTES) &&
                    (cfg_stride_bytes[4:0] == 0) &&
                    (cfg_buffer_stride_bytes >= cfg_stride_bytes*cfg_height) &&
                    (cfg_buffer_stride_bytes[4:0] == 0))
                begin
                    active_buffer_count <= cfg_buffers_per_channel[2:0];
                    case (cfg_buffers_per_channel[2:0])
                        3'd2: active_slot_mask <= 5'b0_0011;
                        3'd3: active_slot_mask <= 5'b0_0111;
                        3'd4: active_slot_mask <= 5'b0_1111;
                        3'd5: active_slot_mask <= 5'b1_1111;
                        default: active_slot_mask <=
                            {MAX_BUFFERS_PER_CHANNEL{1'b0}};
                    endcase
                end else begin
                    active_buffer_count <= 3'd0;
                    active_slot_mask <= {MAX_BUFFERS_PER_CHANNEL{1'b0}};
                end
                for (ch = 0; ch < CHANNELS; ch = ch + 1) begin
                    writer_grant[ch] <= 1'b0;
                    writer_drop[ch] <= 1'b0;
                    writer_active[ch] <= 1'b0;
                    drop_reported[ch] <= 1'b0;
                    latest_ready_valid[ch] <= 1'b0;
                    display_index[ch] <= {SLOT_WIDTH{1'b0}};
                    reader_valid_mask[ch] <= 1'b0;
                    reader_bases[ch*32 +: 32] <= 32'd0;
                    for (slot = 0; slot < MAX_BUFFERS_PER_CHANNEL;
                         slot = slot + 1)
                        begin
                            buffer_state[ch][slot] <= BUFFER_FREE;
                            case (slot)
                                0: active_slot_bases[ch][slot] <=
                                    cfg_channel_bases[ch*32 +: 32];
                                1: active_slot_bases[ch][slot] <=
                                    cfg_channel_bases[ch*32 +: 32] +
                                    cfg_buffer_stride_bytes;
                                2: active_slot_bases[ch][slot] <=
                                    cfg_channel_bases[ch*32 +: 32] +
                                    {cfg_buffer_stride_bytes[30:0], 1'b0};
                                3: active_slot_bases[ch][slot] <=
                                    cfg_channel_bases[ch*32 +: 32] +
                                    cfg_buffer_stride_bytes +
                                    {cfg_buffer_stride_bytes[30:0], 1'b0};
                                4: active_slot_bases[ch][slot] <=
                                    cfg_channel_bases[ch*32 +: 32] +
                                    {cfg_buffer_stride_bytes[29:0], 2'b00};
                                default: active_slot_bases[ch][slot] <=
                                    32'd0;
                            endcase
                        end
                end
                cfg_ack_toggle <= cfg_sync_2;
            end else begin
                for (ch = 0; ch < CHANNELS; ch = ch + 1) begin
                    // Reclaim an old READY slot after both Latest and all
                    // consumers have moved away from it.
                    for (slot = 0; slot < MAX_BUFFERS_PER_CHANNEL;
                         slot = slot + 1)
                        if ((buffer_state[ch][slot] == BUFFER_READY) &&
                            !(latest_ready_valid[ch] &&
                              (latest_ready_index[ch] ==
                               slot[SLOT_WIDTH-1:0])) &&
                            !(reader_valid_mask[ch] &&
                              (display_index[ch] == slot[SLOT_WIDTH-1:0])))
                            buffer_state[ch][slot] <= BUFFER_FREE;

                    if ((writer_done[ch] || writer_error[ch]) &&
                        writer_active[ch]) begin
                        writer_active[ch] <= 1'b0;
                        if (writer_error[ch]) begin
                            buffer_state[ch][writer_index[ch]] <= BUFFER_FREE;
                        end else begin
                            // Only the newest completed non-displayed frame is
                            // useful; reclaim its predecessor immediately.
                            if (latest_ready_valid[ch] &&
                                (buffer_state[ch][latest_ready_index[ch]] ==
                                 BUFFER_READY))
                                buffer_state[ch][latest_ready_index[ch]] <=
                                    BUFFER_FREE;
                            buffer_state[ch][writer_index[ch]] <= BUFFER_READY;
                            latest_ready_valid[ch] <= 1'b1;
                            latest_ready_index[ch] <= writer_index[ch];
                            writer_frame_counts[ch*32 +: 32] <=
                                writer_frame_counts[ch*32 +: 32] + 1'b1;
                        end
                    end

                    if (!writer_acquire[ch])
                        drop_reported[ch] <= 1'b0;

                    // writer_grant/writer_drop are registered responses.  Do
                    // not claim the slot, set writer_active, or count a drop
                    // until the DMA still presents acquire on the response
                    // cycle.  Advancing manager state when merely scheduling
                    // a response can permanently desynchronize the manager
                    // and DMA around a done + next-SOF boundary.
                    if (writer_grant[ch]) begin
                        writer_grant[ch] <= 1'b0;
                        if (writer_acquire[ch]) begin
                            writer_active[ch] <= 1'b1;
                            buffer_state[ch][writer_index[ch]] <= BUFFER_WRITING;
                            drop_reported[ch] <= 1'b1;
                        end
                    end else if (writer_drop[ch]) begin
                        writer_drop[ch] <= 1'b0;
                        if (writer_acquire[ch]) begin
                            drop_reported[ch] <= 1'b1;
                            drop_counts[ch*32 +: 32] <=
                                drop_counts[ch*32 +: 32] + 1'b1;
                        end
                    end else if (writer_acquire[ch] &&
                                 (active_buffer_count != 0) &&
                                 !((writer_done[ch] || writer_error[ch]) &&
                                   writer_active[ch])) begin
                        free_slot = find_free_slot(ch);
                        if (writer_active[ch]) begin
                            // The DMA cannot legitimately request a new frame
                            // while its previous context is active.  Hold the
                            // request instead of turning a transient state
                            // skew into a destructive whole-frame drop.
                        end else if (free_slot >= 0) begin
                            writer_index[ch] <= free_slot[SLOT_WIDTH-1:0];
                            writer_base[ch*32 +: 32] <=
                                slot_address(ch, free_slot);
                            writer_grant[ch] <= 1'b1;
                        end else if (!drop_reported[ch]) begin
                            writer_drop[ch] <= 1'b1;
                        end
                    end
                end

                if (reader_underflow)
                    underflow_count <= underflow_count + 1'b1;

                // At EOF, refresh every channel's stable display snapshot.
                // Channels without a newer frame retain the current buffer so
                // a 30 fps source can be displayed twice at 60 fps.
                if (reader_done && reader_active) begin
                    reader_frame_count <= reader_frame_count + 1'b1;
                    reader_active <= 1'b0;
                    for (ch = 0; ch < CHANNELS; ch = ch + 1) begin
                        if (latest_ready_valid[ch] && !writer_done[ch]) begin
                            if (reader_valid_mask[ch])
                                buffer_state[ch][display_index[ch]] <=
                                    BUFFER_FREE;
                            display_index[ch] <= latest_ready_index[ch];
                            reader_bases[ch*32 +: 32] <=
                                slot_address(ch, latest_ready_index[ch]);
                            reader_valid_mask[ch] <= 1'b1;
                            buffer_state[ch][latest_ready_index[ch]] <=
                                BUFFER_READING;
                            latest_ready_valid[ch] <= 1'b0;
                        end
                    end
                end

                if (reader_acquire && !reader_done && !reader_active) begin
                    if (!mode_sync_2 || reader_valid_mask[requested_channel] ||
                        (requested_ready && !requested_writer_completes)) begin
                        reader_active <= 1'b1;
                        reader_channel <= requested_channel;
                        reader_mode <= mode_sync_2;
                        for (ch = 0; ch < CHANNELS; ch = ch + 1) begin
                            if (latest_ready_valid[ch] && !writer_done[ch]) begin
                                if (reader_valid_mask[ch])
                                    buffer_state[ch][display_index[ch]] <=
                                        BUFFER_FREE;
                                display_index[ch] <= latest_ready_index[ch];
                                reader_bases[ch*32 +: 32] <=
                                    slot_address(ch, latest_ready_index[ch]);
                                reader_valid_mask[ch] <= 1'b1;
                                buffer_state[ch][latest_ready_index[ch]] <=
                                    BUFFER_READING;
                                latest_ready_valid[ch] <= 1'b0;
                            end
                        end
                        if (requested_ready && !requested_writer_completes)
                            reader_base <= slot_address(
                                requested_channel,
                                latest_ready_index[requested_channel]);
                        else if (reader_valid_mask[requested_channel])
                            reader_base <= reader_bases[
                                requested_channel*32 +: 32];
                        else
                            reader_base <= 32'd0;
                        reader_grant <= 1'b1;
                    end
                end

            end
        end
    end
endmodule
