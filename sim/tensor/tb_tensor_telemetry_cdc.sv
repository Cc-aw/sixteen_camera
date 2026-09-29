`timescale 1ns/1ps

module tb_tensor_telemetry_cdc;
    localparam integer CHANNELS = 2;
    localparam integer SLOTS = 4;
    reg src_clk = 1'b0;
    reg dst_clk = 1'b0;
    always #3 src_clk = ~src_clk;
    always #5 dst_clk = ~dst_clk;
    reg src_resetn = 1'b0;
    reg dst_resetn = 1'b0;
    reg [SLOTS*32-1:0] frame_ids = 0;
    reg [SLOTS-1:0] ready_mask = 0;
    reg [SLOTS-1:0] writing_mask = 0;
    reg [SLOTS-1:0] error_mask = 0;
    reg [SLOTS*64-1:0] timestamps = 0;
    reg [SLOTS*32-1:0] versions = 0;
    reg [SLOTS*8-1:0] error_codes = 0;
    reg [SLOTS*32-1:0] byte_counts = 0;
    reg [CHANNELS*32-1:0] no_slot_counts = 0;
    reg [CHANNELS*32-1:0] missed_counts = 0;
    reg [CHANNELS*32-1:0] admission_skip_counts = 0;
    reg [CHANNELS*32-1:0] overflow_counts = 0;
    wire [SLOTS*32-1:0] frame_ids_out;
    wire [SLOTS-1:0] ready_mask_out;
    wire [SLOTS-1:0] writing_mask_out;
    wire [SLOTS-1:0] error_mask_out;
    wire [SLOTS*64-1:0] timestamps_out;
    wire [SLOTS*32-1:0] versions_out;
    wire [SLOTS*8-1:0] error_codes_out;
    wire [SLOTS*32-1:0] byte_counts_out;
    wire [CHANNELS*32-1:0] no_slot_counts_out;
    wire [CHANNELS*32-1:0] missed_counts_out;
    wire [CHANNELS*32-1:0] admission_skip_counts_out;
    wire [CHANNELS*32-1:0] overflow_counts_out;

    tensor_telemetry_cdc #(.CHANNELS(CHANNELS), .SLOTS(SLOTS)) dut (
        .src_clk(src_clk), .src_resetn(src_resetn),
        .src_ready_mask(ready_mask), .src_writing_mask(writing_mask),
        .src_error_mask(error_mask),
        .src_frame_ids(frame_ids), .src_timestamps(timestamps),
        .src_versions(versions), .src_error_codes(error_codes),
        .src_byte_counts(byte_counts), .src_no_slot_counts(no_slot_counts),
        .src_missed_counts(missed_counts),
        .src_admission_skip_counts(admission_skip_counts),
        .src_overflow_counts(overflow_counts),
        .dst_clk(dst_clk), .dst_resetn(dst_resetn),
        .dst_ready_mask(ready_mask_out),
        .dst_writing_mask(writing_mask_out),
        .dst_error_mask(error_mask_out),
        .dst_frame_ids(frame_ids_out), .dst_timestamps(timestamps_out),
        .dst_versions(versions_out), .dst_error_codes(error_codes_out),
        .dst_byte_counts(byte_counts_out),
        .dst_no_slot_counts(no_slot_counts_out),
        .dst_missed_counts(missed_counts_out),
        .dst_admission_skip_counts(admission_skip_counts_out),
        .dst_overflow_counts(overflow_counts_out)
    );

    integer index;
    integer timeout;
    initial begin
        for (index = 0; index < SLOTS; index = index + 1) begin
            frame_ids[index*32 +: 32] = 32'h1000 + index;
            timestamps[index*64 +: 64] = 64'h2000_0000_0000_0000 + index;
            versions[index*32 +: 32] = 32'h3000 + index;
            error_codes[index*8 +: 8] = 8'h40 + index;
            byte_counts[index*32 +: 32] = 32'h5000 + index;
        end
        ready_mask = 4'b0101;
        writing_mask = 4'b0010;
        error_mask = 4'b1000;
        for (index = 0; index < CHANNELS; index = index + 1) begin
            no_slot_counts[index*32 +: 32] = 32'h6000 + index;
            missed_counts[index*32 +: 32] = 32'h7000 + index;
            admission_skip_counts[index*32 +: 32] = 32'h8000 + index;
            overflow_counts[index*32 +: 32] = 32'h9000 + index;
        end
        repeat (4) @(posedge src_clk);
        src_resetn = 1'b1;
        repeat (3) @(posedge dst_clk);
        dst_resetn = 1'b1;

        timeout = 0;
        while ((ready_mask_out !== ready_mask ||
                writing_mask_out !== writing_mask ||
                error_mask_out !== error_mask ||
                frame_ids_out !== frame_ids || timestamps_out !== timestamps ||
                versions_out !== versions || error_codes_out !== error_codes ||
                byte_counts_out !== byte_counts ||
                no_slot_counts_out !== no_slot_counts ||
                missed_counts_out !== missed_counts ||
                admission_skip_counts_out !== admission_skip_counts ||
                overflow_counts_out !== overflow_counts) && timeout < 500) begin
            @(posedge dst_clk);
            timeout = timeout + 1;
        end
        if (timeout == 500)
            $fatal(1, "telemetry reconstruction timed out");

        frame_ids[2*32 +: 32] = 32'hfeed_beef;
        timeout = 0;
        while (frame_ids_out[2*32 +: 32] !== 32'hfeed_beef && timeout < 300) begin
            @(posedge dst_clk);
            timeout = timeout + 1;
        end
        if (timeout == 300)
            $fatal(1, "updated slot did not propagate");

        $display("TB_TENSOR_TELEMETRY_CDC=PASS");
        $finish;
    end
endmodule
