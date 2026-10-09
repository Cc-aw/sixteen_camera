`timescale 1ns/1ps

module tb_common_cdc;
    reg src_clk = 1'b0;
    reg dst_clk = 1'b0;
    always #5 src_clk = ~src_clk;
    always #7 dst_clk = ~dst_clk;

    reg src_resetn = 1'b0;
    reg dst_resetn = 1'b0;

    reg toggle_request = 1'b0;
    wire toggle_busy;
    wire toggle_done;
    wire toggle_pulse;
    cdc_toggle_handshake u_toggle (
        .src_clk(src_clk), .src_resetn(src_resetn),
        .src_request(toggle_request), .src_busy(toggle_busy),
        .src_done(toggle_done), .dst_clk(dst_clk),
        .dst_resetn(dst_resetn), .dst_pulse(toggle_pulse)
    );

    reg [31:0] mailbox_input = 32'd0;
    reg mailbox_valid = 1'b0;
    wire mailbox_ready;
    wire mailbox_done;
    wire [31:0] mailbox_output;
    wire mailbox_output_valid;
    cdc_mailbox #(.WIDTH(32)) u_mailbox (
        .src_clk(src_clk), .src_resetn(src_resetn),
        .src_data(mailbox_input), .src_valid(mailbox_valid),
        .src_ready(mailbox_ready), .src_done(mailbox_done),
        .dst_clk(dst_clk), .dst_resetn(dst_resetn),
        .dst_data(mailbox_output), .dst_valid(mailbox_output_valid)
    );

    reg snapshot_request = 1'b0;
    reg [31:0] live_data = 32'd0;
    wire snapshot_busy;
    wire [31:0] snapshot_data;
    wire snapshot_valid;
    cdc_snapshot #(.WIDTH(32)) u_snapshot (
        .request_clk(src_clk), .request_resetn(src_resetn),
        .request(snapshot_request), .busy(snapshot_busy),
        .snapshot(snapshot_data), .snapshot_valid(snapshot_valid),
        .data_clk(dst_clk), .data_resetn(dst_resetn), .data(live_data)
    );

    integer toggle_pulses = 0;
    integer mailbox_receives = 0;
    integer timeout;
    always @(posedge dst_clk) begin
        if (toggle_pulse)
            toggle_pulses <= toggle_pulses + 1;
        if (mailbox_output_valid) begin
            mailbox_receives <= mailbox_receives + 1;
            if (mailbox_output !== 32'h5a17_c0de)
                $fatal(1, "mailbox payload corrupted: %08x", mailbox_output);
        end
    end

    initial begin
        repeat (5) @(posedge src_clk);
        src_resetn = 1'b1;
        repeat (3) @(posedge dst_clk);
        dst_resetn = 1'b1;

        @(negedge src_clk);
        toggle_request = 1'b1;
        @(negedge src_clk);
        toggle_request = 1'b0;
        timeout = 0;
        while (!toggle_done && timeout < 30) begin
            @(posedge src_clk);
            timeout = timeout + 1;
        end
        if (!toggle_done || toggle_pulses != 1)
            $fatal(1, "toggle handshake failed: done=%0d pulses=%0d",
                   toggle_done, toggle_pulses);

        @(negedge src_clk);
        mailbox_input = 32'h5a17_c0de;
        mailbox_valid = 1'b1;
        @(negedge src_clk);
        mailbox_valid = 1'b0;
        mailbox_input = 32'hdead_beef;
        timeout = 0;
        while (!mailbox_done && timeout < 40) begin
            @(posedge src_clk);
            timeout = timeout + 1;
        end
        if (!mailbox_done || mailbox_receives != 1)
            $fatal(1, "mailbox handshake failed: done=%0d receives=%0d",
                   mailbox_done, mailbox_receives);

        @(negedge dst_clk);
        live_data = 32'h1234_5678;
        @(negedge src_clk);
        snapshot_request = 1'b1;
        @(negedge src_clk);
        snapshot_request = 1'b0;
        wait (u_snapshot.acknowledge_pending);
        @(negedge dst_clk);
        live_data = 32'h8765_4321;
        timeout = 0;
        while (!snapshot_valid && timeout < 50) begin
            @(posedge src_clk);
            timeout = timeout + 1;
        end
        if (!snapshot_valid || snapshot_data !== 32'h1234_5678)
            $fatal(1, "snapshot was not atomic: valid=%0d data=%08x",
                   snapshot_valid, snapshot_data);

        $display("TB_COMMON_CDC=PASS");
        $finish;
    end
endmodule
