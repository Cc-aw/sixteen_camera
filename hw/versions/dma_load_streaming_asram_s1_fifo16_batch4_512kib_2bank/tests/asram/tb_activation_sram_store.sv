`timescale 1ns/1ps
module tb_activation_sram_store;
    reg clock = 0;
    always #5 clock = ~clock;
    reg a_en = 0, a_write = 0, b_en = 0, b_write = 0;
    reg [16:0] a_word = 0, b_word = 0;
    reg [31:0] a_mask = 0, b_mask = 0;
    reg [255:0] a_data = 0, b_data = 0;
    wire [255:0] a_read, b_read;
    activation_sram_store dut(.*);
    reg [255:0] expected [0:35];
    reg [255:0] value;
    integer group_id, edge_id, index, lane;
    task tick;
        begin @(posedge clock); #1; @(negedge clock); end
    endtask
    initial begin
        // Vendor glbl GSR deasserts at 100ns; no RAM data reset is requested.
        repeat (24) tick();
        for (group_id = 0; group_id < 18; group_id = group_id + 1) begin
            for (edge_id = 0; edge_id < 2; edge_id = edge_id + 1) begin
                index = group_id*2 + edge_id;
                for (lane = 0; lane < 32; lane = lane + 1)
                    expected[index][lane*8 +: 8] = (index*37 + lane*13) & 255;
                a_en = 1; a_write = 1; a_mask = '1;
                a_word = group_id*4096 + (edge_id ? 4095 : 0);
                a_data = expected[index]; tick(); a_en = 0;
                b_en = 1; b_write = 0; b_word = a_word;
                tick(); b_en = 0; tick();
                if (b_read !== expected[index]) $fatal(1, "initial cross-port group=%0d edge=%0d", group_id, edge_id);
                // Touch every mask bit individually; each byte's parity
                // boundary must preserve all seven neighboring bytes.
                for (lane = 0; lane < 32; lane = lane + 1) begin
                    value = {8{32'hf1a25bc3}} ^ lane;
                    b_en = 1; b_write = 1; b_mask = 32'b1 << lane; b_data = value;
                    tick(); b_en = 0;
                    expected[index][lane*8 +: 8] = value[lane*8 +: 8];
                    a_en = 1; a_write = 0;
                    tick(); a_en = 0; tick();
                    if (a_read !== expected[index]) $fatal(1, "byte-mask group=%0d edge=%0d byte=%0d", group_id, edge_id, lane);
                end
            end
        end
        // Different-word simultaneous operations use both real ports.
        a_en = 1; a_write = 0; a_word = 0;
        b_en = 1; b_write = 0; b_word = 73727;
        tick(); a_en = 0; b_en = 0; tick();
        if (a_read !== expected[0] || b_read !== expected[35]) $fatal(1, "dual-port read");
        $display("ASRAM_STORE_PASS boundaries=36 single_byte_masks=1152 words=73728 ports=2 latency=2");
        $finish;
    end
    initial begin #1000000; $fatal(1, "timeout"); end
endmodule
