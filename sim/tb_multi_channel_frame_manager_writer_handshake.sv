`timescale 1ns/1ps

module tb_multi_channel_frame_manager_writer_handshake;
    localparam integer CHANNELS = 1;

    reg ui_clk = 1'b0;
    reg ui_resetn = 1'b0;
    always #5 ui_clk = ~ui_clk;

    reg cfg_request_toggle = 1'b0;
    wire cfg_ack_toggle;
    reg cfg_enable = 1'b1;
    reg [31:0] cfg_width = 32'd640;
    reg [31:0] cfg_height = 32'd480;
    reg [31:0] cfg_stride_bytes = 32'd2560;
    reg [31:0] cfg_buffers_per_channel = 32'd4;
    reg [31:0] cfg_channel_bases = 32'h1000_0000;
    reg [31:0] cfg_buffer_stride_bytes = 32'h0020_0000;
    reg cfg_display_channel = 1'b0;
    reg cfg_display_mode = 1'b1;

    reg writer_acquire = 1'b0;
    wire writer_grant;
    wire writer_drop;
    wire [31:0] writer_base;
    reg writer_done = 1'b0;
    reg writer_error = 1'b0;

    reg reader_acquire = 1'b0;
    wire reader_grant;
    wire [31:0] reader_base;
    wire [31:0] reader_bases;
    wire reader_valid_mask;
    wire reader_mode;
    reg reader_done = 1'b0;
    reg reader_underflow = 1'b0;

    wire [31:0] active_width;
    wire [31:0] active_height;
    wire [31:0] active_stride_bytes;
    wire [31:0] writer_frame_counts;
    wire [31:0] reader_frame_count;
    wire [31:0] drop_counts;
    wire [31:0] underflow_count;
    wire [31:0] status;

    multi_channel_frame_manager #(
        .CHANNELS(CHANNELS),
        .MAX_BUFFERS_PER_CHANNEL(4)
    ) dut (
        .ui_clk(ui_clk),
        .ui_resetn(ui_resetn),
        .cfg_request_toggle(cfg_request_toggle),
        .cfg_ack_toggle(cfg_ack_toggle),
        .cfg_enable(cfg_enable),
        .cfg_width(cfg_width),
        .cfg_height(cfg_height),
        .cfg_stride_bytes(cfg_stride_bytes),
        .cfg_buffers_per_channel(cfg_buffers_per_channel),
        .cfg_channel_bases(cfg_channel_bases),
        .cfg_buffer_stride_bytes(cfg_buffer_stride_bytes),
        .cfg_display_channel(cfg_display_channel),
        .cfg_display_mode(cfg_display_mode),
        .writer_acquire(writer_acquire),
        .writer_grant(writer_grant),
        .writer_drop(writer_drop),
        .writer_base(writer_base),
        .writer_done(writer_done),
        .writer_error(writer_error),
        .reader_acquire(reader_acquire),
        .reader_grant(reader_grant),
        .reader_base(reader_base),
        .reader_bases(reader_bases),
        .reader_valid_mask(reader_valid_mask),
        .reader_mode(reader_mode),
        .reader_done(reader_done),
        .reader_underflow(reader_underflow),
        .active_width(active_width),
        .active_height(active_height),
        .active_stride_bytes(active_stride_bytes),
        .writer_frame_counts(writer_frame_counts),
        .reader_frame_count(reader_frame_count),
        .drop_counts(drop_counts),
        .underflow_count(underflow_count),
        .status(status)
    );

    always @(posedge ui_clk)
        if (ui_resetn && writer_grant && writer_drop)
            $fatal(1, "grant and drop asserted together");

    task automatic accept_grant;
        integer timeout;
        begin
            writer_acquire = 1'b1;
            timeout = 0;
            while (!writer_grant) begin
                @(posedge ui_clk);
                #1;
                timeout = timeout + 1;
                if (writer_drop)
                    $fatal(1, "unexpected drop while waiting for grant");
                if (timeout > 20)
                    $fatal(1, "timeout waiting for grant");
            end
            @(posedge ui_clk);
            #1;
            writer_acquire = 1'b0;
            @(posedge ui_clk);
            #1;
            if (!status[7])
                $fatal(1, "manager did not commit accepted grant");
        end
    endtask

    initial begin
        repeat (4) @(posedge ui_clk);
        ui_resetn = 1'b1;
        repeat (2) @(posedge ui_clk);
        cfg_request_toggle = ~cfg_request_toggle;
        wait (cfg_ack_toggle == cfg_request_toggle);
        @(posedge ui_clk);
        #1;

        // Establish an active writer normally.
        accept_grant();

        // Reproduce the hardware race: completion and the next frame request
        // are visible to the manager in exactly the same cycle.  The old RTL
        // emitted drop here and then committed a grant that the DMA missed.
        writer_done = 1'b1;
        writer_acquire = 1'b1;
        @(posedge ui_clk);
        #1;
        writer_done = 1'b0;
        if (writer_drop)
            $fatal(1, "done + acquire generated a destructive drop");

        // The held request must be granted on a later cycle and accepted.
        wait (writer_grant);
        @(posedge ui_clk);
        #1;
        writer_acquire = 1'b0;
        @(posedge ui_clk);
        #1;
        if (!status[7])
            $fatal(1, "writer did not restart after completion boundary");
        if (writer_frame_counts != 1)
            $fatal(1, "completed frame count=%0d expected 1",
                   writer_frame_counts);
        if (drop_counts != 0)
            $fatal(1, "drop count=%0d expected 0", drop_counts);

        // Repeat with an error completion.  It must free the old slot and
        // still grant the next SOF without counting a resource drop.
        writer_error = 1'b1;
        writer_acquire = 1'b1;
        @(posedge ui_clk);
        #1;
        writer_error = 1'b0;
        if (writer_drop)
            $fatal(1, "error + acquire generated a destructive drop");
        wait (writer_grant);
        @(posedge ui_clk);
        #1;
        writer_acquire = 1'b0;
        @(posedge ui_clk);
        #1;
        if (!status[7] || drop_counts != 0)
            $fatal(1, "error recovery failed active=%0d drops=%0d",
                   status[7], drop_counts);

        $display("TB_MULTI_CHANNEL_FRAME_MANAGER_WRITER_HANDSHAKE=PASS");
        $finish;
    end
endmodule
