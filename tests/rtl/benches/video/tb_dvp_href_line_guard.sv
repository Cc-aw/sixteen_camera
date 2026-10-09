`timescale 1ns/1ps

module tb_dvp_href_line_guard;
    reg clk = 1'b0;
    reg resetn = 1'b0;
    reg pixel_ce = 1'b0;
    reg frame_boundary = 1'b0;
    reg href = 1'b0;
    reg diag_clear = 1'b0;
    wire byte_accept;
    wire line_start;
    wire line_last_byte;
    wire line_end;
    wire [31:0] recovered_count;
    wire [31:0] flush_count;
    wire [5:0] gap_last;
    wire [5:0] gap_max;
    wire [10:0] flush_position;

    integer accepted;
    integer starts;
    integer lasts;
    integer ends;

    always #1 clk = ~clk;

    dvp_href_line_guard #(
        .LINE_BYTES(8), .HOLDOVER_CYCLES(4)
    ) dut (
        .clk(clk), .resetn(resetn), .pixel_ce(pixel_ce),
        .frame_boundary(frame_boundary), .href(href),
        .diag_clear(diag_clear), .byte_accept(byte_accept),
        .line_start(line_start), .line_last_byte(line_last_byte),
        .line_end(line_end),
        .diag_gap_recovered_count(recovered_count),
        .diag_flush_count(flush_count), .diag_gap_last(gap_last),
        .diag_gap_max(gap_max), .diag_flush_position(flush_position),
        .active(), .discarding()
    );

    always @(posedge clk) begin
        if (byte_accept) accepted <= accepted + 1;
        if (line_start) starts <= starts + 1;
        if (line_last_byte) lasts <= lasts + 1;
        if (line_end) ends <= ends + 1;
    end

    task automatic sample(input reg href_value);
        begin
            @(negedge clk);
            href = href_value;
            pixel_ce = 1'b1;
            @(negedge clk);
            pixel_ce = 1'b0;
        end
    endtask

    task automatic frame_reset;
        begin
            @(negedge clk);
            frame_boundary = 1'b1;
            @(negedge clk);
            frame_boundary = 1'b0;
            sample(1'b0);
        end
    endtask

    initial begin
        accepted = 0;
        starts = 0;
        lasts = 0;
        ends = 0;
        repeat (3) @(posedge clk);
        resetn = 1'b1;

        // A normal line is accepted exactly once and ends at byte 8.
        repeat (8) sample(1'b1);
        sample(1'b0);
        if (accepted != 8 || starts != 1 || lasts != 1 || ends != 1)
            $fatal(1, "normal line a/s/l/e=%0d/%0d/%0d/%0d",
                   accepted, starts, lasts, ends);

        // A two-cycle low gap remains inside the same protected line.
        repeat (3) sample(1'b1);
        repeat (2) sample(1'b0);
        repeat (3) sample(1'b1);
        sample(1'b0);
        if (accepted != 16 || starts != 2 || lasts != 2 || ends != 2 ||
            recovered_count != 1 || gap_last != 2 || gap_max != 2 ||
            flush_count != 0)
            $fatal(1, "holdover diag rec/gap/max/flush=%0d/%0d/%0d/%0d",
                   recovered_count, gap_last, gap_max, flush_count);

        // The fifth low sample exceeds a four-cycle holdover.  Capture stops
        // at byte position 6 and the rest of the frame is discarded.
        repeat (2) sample(1'b1);
        repeat (5) sample(1'b0);
        @(posedge clk);
        #0.1;
        if (accepted != 22 || flush_count != 1 || gap_last != 4 ||
            gap_max != 4 || flush_position != 6 || ends != 3)
            $fatal(1, "flush a/count/gap/max/pos/end=%0d/%0d/%0d/%0d/%0d/%0d",
                   accepted, flush_count, gap_last, gap_max,
                   flush_position, ends);

        frame_reset();
        repeat (8) sample(1'b1);
        sample(1'b0);
        if (accepted != 30 || lasts != 3 || ends != 4)
            $fatal(1, "frame recovery a/last/end=%0d/%0d/%0d",
                   accepted, lasts, ends);

        $display("DVP_HREF_LINE_GUARD_SIM=PASS");
        $finish;
    end

    initial begin
        #10000;
        $fatal(1, "DVP_HREF_LINE_GUARD_SIM=TIMEOUT");
    end
endmodule
