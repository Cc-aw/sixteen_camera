`timescale 1ns/1ps

module tb_yolov5nu_class_reducer;
    localparam integer SCORE_BYTES = 80 * 6300;
    localparam integer BEATS = SCORE_BYTES / 32;

    reg clk;
    reg resetn;
    reg start;
    reg [255:0] s_data;
    reg [31:0] s_keep;
    reg s_valid;
    wire s_ready;
    reg s_last;
    wire result_valid;
    reg result_ready;
    wire [12:0] result_position;
    wire [6:0] result_class;
    wire signed [7:0] result_score;
    wire result_candidate, result_last;
    wire busy, done, error;
    wire [2:0] error_flags;
    wire [12:0] positions_seen, candidates_seen;

    reg [7:0] scores [0:SCORE_BYTES-1];
    reg [15:0] expected [0:6299];
    integer send_beat;
    integer received;
    integer expected_candidates;
    integer cycle_count;

    always #5 clk = ~clk;

    always @* begin
        s_data = '0;
        s_keep = 32'hffff_ffff;
        s_valid = busy && send_beat < BEATS && cycle_count[3:0] != 4'd5;
        s_last = send_beat == BEATS - 1;
        for (integer lane = 0; lane < 32; lane = lane + 1)
            if (send_beat < BEATS)
                s_data[lane*8 +: 8] = scores[send_beat*32 + lane];
    end

    yolov5nu_class_reducer dut (
        .clk(clk), .resetn(resetn), .start(start),
        .score_threshold(8'sd34),
        .s_data(s_data), .s_keep(s_keep), .s_valid(s_valid),
        .s_ready(s_ready), .s_last(s_last),
        .result_valid(result_valid), .result_ready(result_ready),
        .result_position(result_position), .result_class(result_class),
        .result_score(result_score), .result_candidate(result_candidate),
        .result_last(result_last), .busy(busy), .done(done),
        .error(error), .error_flags(error_flags),
        .positions_seen(positions_seen), .candidates_seen(candidates_seen)
    );

    always @(posedge clk) begin
        cycle_count <= cycle_count + 1;
        // Deterministic bubbles and output backpressure exercise state across
        // beats that split an 80-byte location.
        result_ready <= cycle_count[2:0] != 3'd3;
        if (s_valid && s_ready)
            send_beat <= send_beat + 1;

        if (result_valid && result_ready) begin
            if (result_position !== received[12:0])
                $fatal(1, "position got=%0d expected=%0d",
                       result_position, received);
            if (result_score !== $signed(expected[received][7:0]) ||
                result_class !== expected[received][14:8] ||
                result_candidate !== expected[received][15])
                $fatal(1,
                    "result %0d got score/class/pass=%0d/%0d/%0d expected=%0d/%0d/%0d",
                    received, result_score, result_class, result_candidate,
                    $signed(expected[received][7:0]),
                    expected[received][14:8], expected[received][15]);
            if (result_last !== (received == 6299))
                $fatal(1, "last mismatch at %0d", received);
            if (result_candidate)
                expected_candidates <= expected_candidates + 1;
            received <= received + 1;
        end
    end

    initial begin
        clk = 1'b0;
        resetn = 1'b0;
        start = 1'b0;
        result_ready = 1'b0;
        send_beat = 0;
        received = 0;
        expected_candidates = 0;
        cycle_count = 0;
        $readmemh("scores.mem", scores);
        $readmemh("expected.mem", expected);
        repeat (5) @(posedge clk);
        resetn = 1'b1;
        @(posedge clk);
        start = 1'b1;
        @(posedge clk);
        start = 1'b0;
        wait (done);
        @(posedge clk);
        if (error || error_flags != 0)
            $fatal(1, "protocol error flags=%b", error_flags);
        if (received != 6300 || positions_seen != 6300 ||
            candidates_seen != 10 || expected_candidates != 10)
            $fatal(1,
                "counts result/positions/candidates/observed=%0d/%0d/%0d/%0d",
                received, positions_seen, candidates_seen,
                expected_candidates);
        $display("PASS yolov5nu class reducer positions=%0d candidates=%0d cycles=%0d",
                 received, candidates_seen, cycle_count);
        $finish;
    end

    initial begin
        repeat (200000) @(posedge clk);
        $fatal(1, "timeout");
    end
endmodule
