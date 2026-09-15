`timescale 1ns/1ps

module tb_multi_channel_frame_manager_ai_snapshot;
    localparam integer CHANNELS = 16;
    localparam integer SLOT_STRIDE = 32'h0020_0000;

    reg ui_clk = 1'b0;
    reg ui_resetn = 1'b0;
    always #5 ui_clk = ~ui_clk;

    reg cfg_request_toggle = 1'b0;
    wire cfg_ack_toggle;
    reg cfg_enable = 1'b1;
    reg [31:0] cfg_width = 32'd640;
    reg [31:0] cfg_height = 32'd480;
    reg [31:0] cfg_stride_bytes = 32'd2560;
    reg [31:0] cfg_buffers_per_channel = 32'd5;
    reg [CHANNELS*32-1:0] cfg_channel_bases;
    reg [31:0] cfg_buffer_stride_bytes = SLOT_STRIDE;
    reg [3:0] cfg_display_channel = 4'd0;
    reg cfg_display_mode = 1'b0;

    reg [CHANNELS-1:0] writer_acquire = 0;
    wire [CHANNELS-1:0] writer_grant;
    wire [CHANNELS-1:0] writer_drop;
    wire [CHANNELS*32-1:0] writer_base;
    reg [CHANNELS-1:0] writer_done = 0;
    reg [CHANNELS-1:0] writer_error = 0;
    reg [CHANNELS*32-1:0] writer_source_frame_ids = 0;

    reg reader_acquire = 1'b0;
    wire reader_grant;
    wire [31:0] reader_base;
    wire [CHANNELS*32-1:0] reader_bases;
    wire [CHANNELS-1:0] reader_valid_mask;
    wire reader_mode;
    reg reader_done = 1'b0;
    reg reader_underflow = 1'b0;

    reg ai_snapshot_req_toggle = 1'b0;
    wire ai_snapshot_ack_toggle;
    reg ai_release_req_toggle = 1'b0;
    wire ai_release_ack_toggle;
    reg [CHANNELS-1:0] ai_release_mask = 0;
    wire ai_snapshot_active;
    wire [CHANNELS-1:0] ai_snapshot_valid_mask;
    wire [CHANNELS-1:0] ai_snapshot_fresh_mask;
    wire [CHANNELS-1:0] ai_held_mask;
    wire [CHANNELS*32-1:0] ai_snapshot_addrs;
    wire [CHANNELS*64-1:0] ai_snapshot_frame_ids;
    wire [CHANNELS*32-1:0] ai_snapshot_source_frame_ids;
    wire [CHANNELS*64-1:0] ai_snapshot_timestamps;
    wire [CHANNELS*32-1:0] ai_snapshot_versions;
    wire [63:0] ai_snapshot_batch_id;
    wire [31:0] ai_snapshot_count;
    wire [31:0] ai_release_count;
    wire [31:0] ai_error_count;

    wire [31:0] active_width;
    wire [31:0] active_height;
    wire [31:0] active_stride_bytes;
    wire [CHANNELS*32-1:0] writer_frame_counts;
    wire [31:0] reader_frame_count;
    wire [CHANNELS*32-1:0] drop_counts;
    wire [31:0] underflow_count;
    wire [31:0] status;

    reg [CHANNELS*32-1:0] first_frame_addrs;
    integer ch;
    integer slot;
    integer timeout;

    multi_channel_frame_manager #(
        .CHANNELS(CHANNELS),
        .MAX_BUFFERS_PER_CHANNEL(5)
    ) dut (
        .ui_clk(ui_clk), .ui_resetn(ui_resetn),
        .cfg_request_toggle(cfg_request_toggle),
        .cfg_ack_toggle(cfg_ack_toggle), .cfg_enable(cfg_enable),
        .cfg_width(cfg_width), .cfg_height(cfg_height),
        .cfg_stride_bytes(cfg_stride_bytes),
        .cfg_buffers_per_channel(cfg_buffers_per_channel),
        .cfg_channel_bases(cfg_channel_bases),
        .cfg_buffer_stride_bytes(cfg_buffer_stride_bytes),
        .cfg_display_channel(cfg_display_channel),
        .cfg_display_mode(cfg_display_mode),
        .writer_acquire(writer_acquire), .writer_grant(writer_grant),
        .writer_drop(writer_drop), .writer_base(writer_base),
        .writer_done(writer_done), .writer_error(writer_error),
        .writer_source_frame_ids(writer_source_frame_ids),
        .reader_acquire(reader_acquire), .reader_grant(reader_grant),
        .reader_base(reader_base), .reader_bases(reader_bases),
        .reader_valid_mask(reader_valid_mask), .reader_mode(reader_mode),
        .reader_done(reader_done), .reader_underflow(reader_underflow),
        .ai_snapshot_req_toggle(ai_snapshot_req_toggle),
        .ai_snapshot_ack_toggle(ai_snapshot_ack_toggle),
        .ai_release_req_toggle(ai_release_req_toggle),
        .ai_release_ack_toggle(ai_release_ack_toggle),
        .ai_release_mask(ai_release_mask),
        .ai_snapshot_active(ai_snapshot_active),
        .ai_snapshot_valid_mask(ai_snapshot_valid_mask),
        .ai_snapshot_fresh_mask(ai_snapshot_fresh_mask),
        .ai_held_mask(ai_held_mask),
        .ai_snapshot_addrs(ai_snapshot_addrs),
        .ai_snapshot_frame_ids(ai_snapshot_frame_ids),
        .ai_snapshot_source_frame_ids(ai_snapshot_source_frame_ids),
        .ai_snapshot_timestamps(ai_snapshot_timestamps),
        .ai_snapshot_versions(ai_snapshot_versions),
        .ai_snapshot_batch_id(ai_snapshot_batch_id),
        .ai_snapshot_count(ai_snapshot_count),
        .ai_release_count(ai_release_count),
        .ai_error_count(ai_error_count),
        .active_width(active_width), .active_height(active_height),
        .active_stride_bytes(active_stride_bytes),
        .writer_frame_counts(writer_frame_counts),
        .reader_frame_count(reader_frame_count), .drop_counts(drop_counts),
        .underflow_count(underflow_count), .status(status)
    );

    task automatic capture_all;
        input integer expected_frame_id;
        begin
            for (int source_ch = 0; source_ch < CHANNELS; source_ch++)
                writer_source_frame_ids[source_ch*32 +: 32] =
                    32'(1000*expected_frame_id + source_ch);
            writer_acquire = {CHANNELS{1'b1}};
            timeout = 0;
            while (writer_grant != {CHANNELS{1'b1}}) begin
                @(posedge ui_clk); #1;
                if (|writer_drop)
                    $fatal(1, "unexpected writer drop on frame %0d mask=%h",
                           expected_frame_id, writer_drop);
                timeout = timeout + 1;
                if (timeout > 30)
                    $fatal(1, "writer grant timeout on frame %0d grants=%h",
                           expected_frame_id, writer_grant);
            end
            @(posedge ui_clk); #1;
            writer_acquire = 0;
            @(posedge ui_clk); #1;
            writer_done = {CHANNELS{1'b1}};
            @(posedge ui_clk); #1;
            writer_done = 0;
            @(posedge ui_clk); #1;
            for (ch = 0; ch < CHANNELS; ch = ch + 1)
                if (writer_frame_counts[ch*32 +: 32] != expected_frame_id)
                    $fatal(1, "CH%0d frame count=%0d expected=%0d", ch,
                           writer_frame_counts[ch*32 +: 32],
                           expected_frame_id);
        end
    endtask

    task automatic request_snapshot;
        begin
            ai_snapshot_req_toggle = ~ai_snapshot_req_toggle;
            timeout = 0;
            while (ai_snapshot_ack_toggle != ai_snapshot_req_toggle) begin
                @(posedge ui_clk); #1;
                timeout = timeout + 1;
                if (timeout > 20)
                    $fatal(1, "snapshot ack timeout");
            end
            @(posedge ui_clk); #1;
        end
    endtask

    task automatic release_channels;
        input [CHANNELS-1:0] mask;
        begin
            ai_release_mask = mask;
            ai_release_req_toggle = ~ai_release_req_toggle;
            timeout = 0;
            while (ai_release_ack_toggle != ai_release_req_toggle) begin
                @(posedge ui_clk); #1;
                timeout = timeout + 1;
                if (timeout > 20)
                    $fatal(1, "release ack timeout");
            end
            @(posedge ui_clk); #1;
        end
    endtask

    task automatic check_writer_does_not_use_snapshot;
        begin
            for (ch = 0; ch < CHANNELS; ch = ch + 1)
                if (writer_base[ch*32 +: 32] ==
                    first_frame_addrs[ch*32 +: 32])
                    $fatal(1, "CH%0d writer reused AI-held address %08x", ch,
                           writer_base[ch*32 +: 32]);
        end
    endtask

    initial begin
        for (ch = 0; ch < CHANNELS; ch = ch + 1)
            cfg_channel_bases[ch*32 +: 32] =
                32'h1000_0000 + ch * 32'h0100_0000;

        repeat (4) @(posedge ui_clk);
        ui_resetn = 1'b1;
        repeat (2) @(posedge ui_clk);
        cfg_request_toggle = ~cfg_request_toggle;
        wait (cfg_ack_toggle == cfg_request_toggle);
        @(posedge ui_clk); #1;

        if (status[12:10] != 3'd5)
            $fatal(1, "five-buffer configuration inactive status=%08x",
                   status);
        for (ch = 0; ch < CHANNELS; ch = ch + 1)
            for (slot = 0; slot < 5; slot = slot + 1)
                if (dut.active_slot_bases[ch][slot] !=
                    cfg_channel_bases[ch*32 +: 32] + slot * SLOT_STRIDE)
                    $fatal(1, "CH%0d slot%0d address=%08x expected=%08x",
                           ch, slot, dut.active_slot_bases[ch][slot],
                           cfg_channel_bases[ch*32 +: 32] +
                           slot * SLOT_STRIDE);

        capture_all(1);
        request_snapshot();
        first_frame_addrs = ai_snapshot_addrs;
        if (!ai_snapshot_active || ai_snapshot_valid_mask != 16'hffff ||
            ai_snapshot_fresh_mask != 16'hffff || ai_held_mask != 16'hffff)
            $fatal(1, "first snapshot state invalid active=%0d v/f/h=%h/%h/%h",
                   ai_snapshot_active, ai_snapshot_valid_mask,
                   ai_snapshot_fresh_mask, ai_held_mask);
        if (ai_snapshot_batch_id != 1 || ai_snapshot_count != 1)
            $fatal(1, "first snapshot counters invalid batch=%0d count=%0d",
                   ai_snapshot_batch_id, ai_snapshot_count);
        for (ch = 0; ch < CHANNELS; ch = ch + 1) begin
            if (ai_snapshot_frame_ids[ch*64 +: 64] != 1 ||
                ai_snapshot_source_frame_ids[ch*32 +: 32] != 1000+ch ||
                ai_snapshot_versions[ch*32 +: 32] != 1 ||
                ai_snapshot_addrs[ch*32 +: 32] !=
                    cfg_channel_bases[ch*32 +: 32])
                $fatal(1, "CH%0d first metadata addr/frame/version=%08x/%0d/%0d",
                       ch, ai_snapshot_addrs[ch*32 +: 32],
                       ai_snapshot_frame_ids[ch*64 +: 64],
                       ai_snapshot_versions[ch*32 +: 32]);
        end

        // A duplicate request must be acknowledged but must not replace the
        // immutable in-flight snapshot.
        request_snapshot();
        if (ai_error_count != 1 || ai_snapshot_count != 1 ||
            ai_snapshot_addrs != first_frame_addrs)
            $fatal(1, "duplicate snapshot was not rejected cleanly");

        // Display and AI now share frame 1.  Later captures must use other
        // slots while the Snapshot metadata itself remains unchanged.
        reader_acquire = 1'b1;
        wait (reader_grant); @(posedge ui_clk); #1;
        reader_acquire = 1'b0;
        capture_all(2); check_writer_does_not_use_snapshot();
        capture_all(3); check_writer_does_not_use_snapshot();
        capture_all(4); check_writer_does_not_use_snapshot();
        if (ai_snapshot_addrs != first_frame_addrs)
            $fatal(1, "snapshot changed while held");
        for (ch = 0; ch < CHANNELS; ch = ch + 1)
            if (ai_snapshot_frame_ids[ch*64 +: 64] != 1)
                $fatal(1, "CH%0d held frame id changed", ch);

        release_channels(16'h00ff);
        if (ai_held_mask != 16'hff00 || !ai_snapshot_active)
            $fatal(1, "partial release failed held=%h active=%0d",
                   ai_held_mask, ai_snapshot_active);
        release_channels(16'hff00);
        if (ai_held_mask != 0 || ai_snapshot_active)
            $fatal(1, "final release failed held=%h active=%0d",
                   ai_held_mask, ai_snapshot_active);

        // The next snapshot sees frame 4 as fresh; another snapshot without
        // capture is valid but not fresh.
        request_snapshot();
        if (ai_snapshot_fresh_mask != 16'hffff)
            $fatal(1, "new frames not marked fresh: %h",
                   ai_snapshot_fresh_mask);
        for (ch = 0; ch < CHANNELS; ch = ch + 1)
            if (ai_snapshot_frame_ids[ch*64 +: 64] != 4)
                $fatal(1, "CH%0d latest frame=%0d expected=4", ch,
                       ai_snapshot_frame_ids[ch*64 +: 64]);
        release_channels(16'hffff);
        request_snapshot();
        if (ai_snapshot_fresh_mask != 0)
            $fatal(1, "unchanged Latest entries marked fresh: %h",
                   ai_snapshot_fresh_mask);
        release_channels(16'hffff);

        // Once AI releases frame 1 and display advances, slot 0 becomes
        // reusable.  This proves the reference prevents overwrite but does not
        // leak the buffer permanently.
        reader_done = 1'b1;
        @(posedge ui_clk); #1;
        reader_done = 1'b0;
        repeat (2) @(posedge ui_clk);
        writer_acquire = {CHANNELS{1'b1}};
        wait (writer_grant == {CHANNELS{1'b1}});
        #1;
        for (ch = 0; ch < CHANNELS; ch = ch + 1)
            if (writer_base[ch*32 +: 32] !=
                first_frame_addrs[ch*32 +: 32])
                $fatal(1, "CH%0d released slot was not reclaimed", ch);

        if (ai_snapshot_count != 3 || ai_release_count != 4 ||
            ai_error_count != 1)
            $fatal(1, "diagnostics count snap/release/error=%0d/%0d/%0d",
                   ai_snapshot_count, ai_release_count, ai_error_count);
        if (|drop_counts)
            $fatal(1, "unexpected frame drops %h", drop_counts);

        $display("TB_MULTI_CHANNEL_FRAME_MANAGER_AI_SNAPSHOT=PASS");
        $finish;
    end
endmodule
