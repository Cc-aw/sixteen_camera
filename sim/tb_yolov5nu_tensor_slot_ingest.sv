`timescale 1ns/1ps

module tb_yolov5nu_tensor_slot_ingest;
    reg clk = 0;
    always #5 clk = ~clk;
    reg resetn = 0, enable = 0, release_pulse = 0;
    reg [31:0] release_mask = 0;
    reg [16*48-1:0] tap_data = 0;
    reg [15:0] tap_accept = 0, tap_sof = 0, tap_eol = 0;
    reg [15:0] tap_eof = 0, tap_error = 0;
    reg inject_error_ch0 = 0;
    reg [16*32-1:0] tap_frame_id = 0;
    wire [31:0] ready_mask, writing_mask, error_mask;
    wire [32*32-1:0] slot_frame_ids, slot_byte_counts;
    wire [16*32-1:0] no_slot_counts, missed_frame_counts;
    wire [16*32-1:0] overflow_counts;
    axi4_if #(.ADDR_WIDTH(32), .DATA_WIDTH(256), .ID_WIDTH(3)) axi();
    reg bvalid = 0;
    reg [3:0] bus_cycle = 0;
    integer active_channel = -1, active_bank = -1;
    integer beat_in_burst = 0;
    integer total_beats = 0;
    integer frame_number = 0;
    localparam integer FRAME_PAIRS = 256;
    localparam integer FRAME_BEATS = 48;

    yolov5nu_tensor_slot_ingest #(
        .FRAME_WIDTH(32), .FRAME_HEIGHT(16),
        .FIFO_DEPTH(32), .SLOT_STRIDE(32'd4096)
    ) dut (
        .clk(clk), .resetn(resetn), .enable(enable),
        .release_pulse(release_pulse), .release_mask(release_mask),
        .tap_data(tap_data), .tap_accept(tap_accept),
        .tap_sof(tap_sof), .tap_eol(tap_eol), .tap_eof(tap_eof),
        .tap_frame_id(tap_frame_id), .tap_error(tap_error),
        .ready_mask(ready_mask), .writing_mask(writing_mask),
        .error_mask(error_mask), .slot_frame_ids(slot_frame_ids),
        .slot_byte_counts(slot_byte_counts),
        .no_slot_counts(no_slot_counts),
        .missed_frame_counts(missed_frame_counts),
        .overflow_counts(overflow_counts),
        .m_axi(axi)
    );

    assign axi.awready = !bvalid;
    // Model a shared write path that accepts data on only half the cycles.
    assign axi.wready = bus_cycle[0];
    assign axi.bid = 3'd0;
    assign axi.bresp = 2'd0;
    assign axi.bvalid = bvalid;
    assign axi.arready = 1'b0;
    assign axi.rid = 3'd0;
    assign axi.rdata = 256'd0;
    assign axi.rresp = 2'd0;
    assign axi.rlast = 1'b0;
    assign axi.rvalid = 1'b0;

    always @(posedge clk) if (resetn) begin
        bus_cycle <= bus_cycle + 1'b1;
        if (axi.awvalid && axi.awready) begin
            if (axi.awaddr >= 32'h3100_0000) begin
                active_bank <= 1;
                active_channel <= int'((axi.awaddr - 32'h3100_0000) / 4096);
            end else begin
                active_bank <= 0;
                active_channel <= int'((axi.awaddr - 32'h3000_0000) / 4096);
            end
            if (axi.awlen != 8'(FRAME_BEATS-1) ||
                axi.awaddr[11:0] != 0)
                $fatal(1, "invalid production AW addr/len");
            beat_in_burst <= 0;
        end
        if (axi.wvalid && axi.wready) begin
            if (active_channel < 0 || active_channel >= 16 ||
                axi.wlast !== (beat_in_burst == FRAME_BEATS-1))
                $fatal(1, "invalid production W channel/last");
            beat_in_burst <= beat_in_burst + 1;
            total_beats <= total_beats + 1;
            if (axi.wlast) bvalid <= 1;
        end
        if (axi.bvalid && axi.bready) bvalid <= 0;
    end

    task automatic send_frame(input integer frame_number);
        for (int pair_index = 0; pair_index < FRAME_PAIRS;
             pair_index++) begin
            @(negedge clk);
            for (int ch = 0; ch < 16; ch++) begin
                tap_data[ch*48 +: 48] = {
                    8'(ch+1), 8'(pair_index*2+2), 8'(frame_number),
                    8'(ch+1), 8'(pair_index*2+1), 8'(frame_number)
                };
                tap_frame_id[ch*32 +: 32] = 32'(frame_number*100+ch);
            end
            tap_accept = 16'hffff;
            tap_sof = pair_index == 0 ? 16'hffff : 0;
            tap_eol = pair_index % 16 == 15 ? 16'hffff : 0;
            tap_eof = pair_index == FRAME_PAIRS-1 ? 16'hffff : 0;
            tap_error = inject_error_ch0 && pair_index == 0 ? 16'h0001 : 0;
        end
        @(negedge clk);
        tap_accept = 0;
        tap_sof = 0;
        tap_eol = 0;
        tap_eof = 0;
        tap_error = 0;
    endtask

    initial begin
        repeat (5) @(negedge clk);
        resetn = 1;
        enable = 1;
        repeat (8) @(negedge clk);
        for (int attempt = 0; attempt < 64 &&
             ready_mask[15:0] != 16'hffff; attempt++) begin
            frame_number++;
            send_frame(frame_number);
            repeat (80) @(negedge clk);
        end
        if (ready_mask[15:0] != 16'hffff)
            $fatal(1, "not every first slot became ready");
        if (error_mask != 0 || total_beats != 16*FRAME_BEATS)
            $fatal(1, "first production frame failed");
        for (int slot = 0; slot < 16; slot++)
            if (slot_frame_ids[slot*32 +: 32] == 0 ||
                slot_byte_counts[slot*32 +: 32] != 1536 ||
                overflow_counts[slot*32 +: 32] != 0)
                $fatal(1, "first slot metadata mismatch slot=%0d", slot);
        for (int attempt = 0; attempt < 64 &&
             ready_mask != 32'hffff_ffff; attempt++) begin
            frame_number++;
            send_frame(frame_number);
            repeat (80) @(negedge clk);
        end
        if (ready_mask != 32'hffff_ffff)
            $fatal(1, "not every second slot became ready");
        if (error_mask != 0 || total_beats != 32*FRAME_BEATS)
            $fatal(1, "second production frame failed");
        repeat (8) @(negedge clk);
        frame_number++;
        send_frame(frame_number);
        if (ready_mask != 32'hffff_ffff ||
            total_beats != 32*FRAME_BEATS)
            $fatal(1, "full slots were overwritten");
        for (int ch = 0; ch < 16; ch++)
            if (no_slot_counts[ch*32 +: 32] == 0 ||
                missed_frame_counts[ch*32 +: 32] == 0)
                $fatal(1, "missing full-slot drop count ch=%0d", ch);
        @(negedge clk);
        release_mask = 32'h0000_ffff;
        release_pulse = 1;
        @(negedge clk);
        release_pulse = 0;
        wait(ready_mask[15:0] == 0);
        for (int attempt = 0; attempt < 64 &&
             ready_mask != 32'hffff_ffff; attempt++) begin
            frame_number++;
            send_frame(frame_number);
            repeat (80) @(negedge clk);
        end
        if (ready_mask != 32'hffff_ffff)
            $fatal(1, "released slots were not refilled");
        if (error_mask != 0 || total_beats != 48*FRAME_BEATS)
            $fatal(1, "released slots were not reused");
        for (int slot = 0; slot < 16; slot++)
            if (slot_frame_ids[slot*32 +: 32] <=
                slot_frame_ids[(slot+16)*32 +: 32] ||
                overflow_counts[slot*32 +: 32] != 0)
                $fatal(1, "slot ownership mismatch ch=%0d", slot);
        @(negedge clk);
        release_mask = 32'h0000_0001;
        release_pulse = 1;
        @(negedge clk);
        release_pulse = 0;
        wait(!ready_mask[0]);
        wait(writing_mask[0]);
        repeat (3) @(negedge clk);
        inject_error_ch0 = 1;
        frame_number++;
        send_frame(frame_number);
        wait(error_mask[0]);
        if (ready_mask[0] || !ready_mask[16])
            $fatal(1, "errored slot was published or other slot lost");
        inject_error_ch0 = 0;
        wait(writing_mask[0]);
        repeat (3) @(negedge clk);
        frame_number++;
        send_frame(frame_number);
        wait(ready_mask[0]);
        if (error_mask[0] ||
            slot_frame_ids[0 +: 32] != 32'(frame_number*100))
            $fatal(1, "errored slot did not recover");
        @(negedge clk);
        release_mask = 32'h0000_0001;
        release_pulse = 1;
        @(negedge clk);
        release_pulse = 0;
        wait(writing_mask[0]);
        enable = 0;
        repeat (20) @(negedge clk);
        if (writing_mask[0] || ready_mask[0] || error_mask[0])
            $fatal(1, "disabling did not cancel an armed capture");
        $display("YOLOV5NU_TENSOR_SLOT_INGEST=PASS beats=%0d", total_beats);
        $finish;
    end
    initial begin
        repeat (100000) @(posedge clk);
        $fatal(1, "tensor slot ingest timeout ready=%h writing=%h beats=%0d ch0_state=%0d writer=%0d pending=%0d err=%0d",
               ready_mask, writing_mask, total_beats,
               dut.g_channel[0].u_capture.state,
               dut.g_channel[0].u_capture.u_writer.state,
               dut.g_channel[0].pending, error_mask[0]);
    end
endmodule
