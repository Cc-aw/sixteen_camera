`timescale 1ns/1ps

module tb_dvp_pclk_recovery;
    reg clk = 1'b0, resetn = 1'b0, diag_clear = 1'b0;
    reg pclk = 1'b0, href = 1'b1, vsync = 1'b0;
    reg frame_boundary = 1'b0;
    reg scramble_data = 1'b0;
    reg [7:0] data = 8'd0;
    reg [2:0] sample_offset = 3'd2;
    wire pixel_ce, pixel_href, pixel_vsync, locked;
    wire [7:0] pixel_data;
    wire [1:0] state;
    wire [23:0] period_est_fp, phase_error_fp, phase_error_max_fp;
    wire [15:0] last_interval, interval_min, interval_max;
    wire [31:0] candidate_count, valid_count, glitch_count, missing_count;
    wire [31:0] holdover_count, holdover_recovered_count;
    wire [31:0] harmonic_reject_count, lock_loss_count;
    wire [31:0] data_unstable_count;
    wire [15:0] short_high_count, short_low_count;

    always #1.666 clk = ~clk;
    always @(posedge clk)
        if (scramble_data)
            data <= data + 8'h3d;

    dvp_pclk_recovery #(
        .SEARCH_VALID_EDGES(4), .ACQUIRE_EDGES(4),
        .DEFAULT_DATA_SAMPLE_OFFSET(2)
    ) dut (
        .clk_300m(clk), .resetn(resetn), .diag_clear(diag_clear),
        .pclk_sample(pclk), .data_sample(data),
        .href_sample(href), .vsync_sample(vsync),
        .frame_boundary(frame_boundary),
        .data_sample_offset(sample_offset),
        .pixel_ce(pixel_ce), .pixel_data(pixel_data),
        .pixel_href(pixel_href), .pixel_vsync(pixel_vsync),
        .pclk_locked(locked), .recovery_state(state),
        .period_est_fp(period_est_fp), .last_interval(last_interval),
        .interval_min(interval_min), .interval_max(interval_max),
        .phase_error_fp(phase_error_fp),
        .phase_error_max_fp(phase_error_max_fp),
        .candidate_count(candidate_count), .valid_count(valid_count),
        .glitch_count(glitch_count), .missing_count(missing_count),
        .holdover_count(holdover_count),
        .holdover_recovered_count(holdover_recovered_count),
        .harmonic_reject_count(harmonic_reject_count),
        .lock_loss_count(lock_loss_count),
        .data_unstable_count(data_unstable_count),
        .short_high_count(short_high_count),
        .short_low_count(short_low_count)
    );

    task automatic wait_clks(input integer count);
        integer i;
        begin
            for (i = 0; i < count; i = i + 1) @(posedge clk);
        end
    endtask

    task automatic reset_dut;
        begin
            resetn = 1'b0; pclk = 1'b0; href = 1'b1; vsync = 1'b0;
            wait_clks(8); resetn = 1'b1; wait_clks(2);
        end
    endtask

    task automatic send_cycle(input integer high_samples,
                              input integer low_samples);
        begin
            data = data + 1'b1;
            pclk = 1'b1; wait_clks(high_samples);
            pclk = 1'b0; wait_clks(low_samples);
        end
    endtask

    // A stable false pulse starts eight samples after the true edge. It passes
    // the two-sample deglitcher but lies outside the predicted LOCK window.
    task automatic send_early_wide_glitch;
        begin
            data = data + 1'b1;
            pclk = 1'b1; wait_clks(2);
            pclk = 1'b0; wait_clks(6);
            pclk = 1'b1; wait_clks(2);
            pclk = 1'b0; wait_clks(2);
        end
    endtask

    integer i;
    integer ce_count = 0;
    integer saved_ce;
    reg [31:0] saved_candidate, saved_valid, saved_glitch, saved_missing;
    reg [31:0] saved_holdover, saved_recovered, saved_lock_loss;
`ifdef DEBUG_REC
    reg [1:0] previous_state = 2'd0;
    always @(posedge clk) begin
        if (state != previous_state) begin
            $display("REC t=%0t state %0d->%0d lock=%0d period=%0d raw=%0d miss=%0d hold=%0d score=%0d confirm=%0d phase=%0d",
                     $time, previous_state, state, locked, period_est_fp,
                     dut.candidate_period_est_fp, missing_count,
                     holdover_count, dut.lock_score,
                     dut.recovery_confirm_count, phase_error_fp);
            previous_state <= state;
        end
    end
`endif

    always @(posedge clk) begin
        if (pixel_ce) begin
            ce_count <= ce_count + 1;
            if (!pixel_href || pixel_vsync)
                $fatal(1, "sampled control bus lost tap-4 alignment");
        end
    end

    initial begin
        reset_dut();

        // Ideal 24 MHz represented by alternating 12/13 sample intervals.
        for (i = 0; i < 40; i = i + 1)
            send_cycle(6, ((i & 1) != 0) ? 7 : 6);
        if (!locked || state != 2'd2)
            $fatal(1, "failed clean lock state=%0d period=%0d", state,
                   period_est_fp);
        if (period_est_fp < (24'd12 << 8) ||
            period_est_fp > (24'd13 << 8))
            $fatal(1, "clean period outside 12..13: %0d", period_est_fp);
        if (glitch_count != 0 || missing_count != 0)
            $fatal(1, "clean input errors g=%0d m=%0d", glitch_count,
                   missing_count);
        if (dut.candidate_period_est_fp < (24'd12 << 8) ||
            dut.candidate_period_est_fp > (24'd13 << 8))
            $fatal(1, "raw candidate period outside 12..13: %0d",
                   dut.candidate_period_est_fp);
        if (dut.data_stable_count == 0)
            $fatal(1, "stable DATA history was not counted");

        // A complete active line with realistic 300 MHz quantisation and
        // bounded phase jitter must preserve every physical byte. The phase
        // model may score/re-anchor these edges, but it must neither delete a
        // real edge nor insert a premature HOLDOVER edge.
        saved_ce = ce_count;
        saved_valid = valid_count;
        saved_glitch = glitch_count;
        saved_missing = missing_count;
        saved_holdover = holdover_count;
        for (i = 0; i < 1280; i = i + 1) begin
            case (i % 6)
                0: send_cycle(4, 6);  // 10 samples
                1: send_cycle(4, 9);  // 13 samples
                2: send_cycle(4, 11); // 15 samples
                3: send_cycle(4, 8);  // 12 samples
                4: send_cycle(4, 7);  // 11 samples
                default: send_cycle(4, 10); // 14 samples
            endcase
        end
        if (ce_count != saved_ce + 1280)
            $fatal(1, "jittered line changed byte count got=%0d expected=%0d",
                   ce_count - saved_ce, 1280);
        if (valid_count != saved_valid + 1280 ||
            glitch_count != saved_glitch ||
            missing_count != saved_missing ||
            holdover_count != saved_holdover)
            $fatal(1, "jittered line was not entirely physical valid=%0d glitch=%0d missing=%0d hold=%0d",
                   valid_count - saved_valid, glitch_count - saved_glitch,
                   missing_count - saved_missing,
                   holdover_count - saved_holdover);
        if (!locked)
            $fatal(1, "jittered line lost lock state=%0d", state);

        // Run through the 24-bit Q16.8 phase accumulator wrap. Modular signed
        // subtraction must keep all clean edges valid across 0xffffff->0.
        saved_ce = ce_count;
        saved_valid = valid_count;
        saved_glitch = glitch_count;
        saved_missing = missing_count;
        for (i = 0; i < 4500; i = i + 1)
            send_cycle(6, 6);
        if (ce_count != saved_ce + 4500 ||
            valid_count != saved_valid + 4500 ||
            glitch_count != saved_glitch ||
            missing_count != saved_missing || !locked)
            $fatal(1, "Q16.8 wrap lost physical edges ce/valid/glitch/missing=%0d/%0d/%0d/%0d",
                   ce_count - saved_ce, valid_count - saved_valid,
                   glitch_count - saved_glitch,
                   missing_count - saved_missing);

        // A one-sample high pulse must not reach candidate_edge.
        saved_candidate = candidate_count;
        pclk = 1'b1; wait_clks(1); pclk = 1'b0; wait_clks(5);
        if (candidate_count != saved_candidate || short_high_count == 0)
            $fatal(1, "one-sample high glitch not rejected/diagnosed");

        // A wider early pulse reaches candidate_edge but not recovered CE.
        for (i = 0; i < 12; i = i + 1) send_cycle(6, 6);
        saved_glitch = glitch_count;
        send_early_wide_glitch();
        for (i = 0; i < 12; i = i + 1) send_cycle(6, 6);
        if (glitch_count == saved_glitch || !locked)
            $fatal(1, "predicted window failed early-wide-glitch test");

        // A single absent PCLK is bridged exactly once and the following real
        // edge returns HOLDOVER to LOCK.
        for (i = 0; i < 32; i = i + 1) send_cycle(6, 6);
        saved_missing = missing_count;
        saved_holdover = holdover_count;
        saved_recovered = holdover_recovered_count;
        pclk = 1'b0; wait_clks(12);
        for (i = 0; i < 12; i = i + 1) send_cycle(6, 6);
        if (missing_count != saved_missing + 1 ||
            holdover_count != saved_holdover + 1 ||
            holdover_recovered_count != saved_recovered + 1 || !locked)
            $fatal(1, "single holdover failed m/h/r=%0d/%0d/%0d state=%0d",
                   missing_count, holdover_count,
                   holdover_recovered_count, state);

        // Gated PCLK during HREF low neither emits video CE nor consumes
        // missing-edge/holdover budget.
        saved_missing = missing_count;
        saved_holdover = holdover_count;
        href = 1'b0; pclk = 1'b0; wait_clks(60);
        href = 1'b1;
        if (missing_count != saved_missing ||
            holdover_count != saved_holdover)
            $fatal(1, "HREF-gated blanking consumed holdover");
        for (i = 0; i < 24; i = i + 1) send_cycle(6, 6);
        if (!locked) $fatal(1, "failed after HREF gate state=%0d g=%0d m=%0d period=%0d last=%0d",
                            state, glitch_count, missing_count,
                            period_est_fp, last_interval);

        // Two consecutive missing edges exceed MAX_HOLDOVER=1.
        saved_lock_loss = lock_loss_count;
        pclk = 1'b0; wait_clks(32);
        if (locked || state != 2'd0 || lock_loss_count != saved_lock_loss + 1)
            $fatal(1, "continuous missing edges did not force SEARCH");
        if (dut.last_loss_reason != 4'd9 || dut.period_at_loss == 0)
            $fatal(1, "recovery-confirm loss scene not preserved");

        // Exact board failure signature: stable 25-sample candidates must be
        // rejected as a 2x harmonic and can never establish LOCK.
        reset_dut();
        for (i = 0; i < 24; i = i + 1) send_cycle(6, 19);
        if (locked || state != 2'd0 || harmonic_reject_count == 0)
            $fatal(1, "divide-by-two harmonic acquired unexpectedly");
        if (period_est_fp < (24'd12 << 8) ||
            period_est_fp > (24'd13 << 8))
            $fatal(1, "harmonic corrupted nominal estimator: %0d",
                   period_est_fp);

        // Distorted duty cycle with only two high samples remains recoverable.
        reset_dut();
        for (i = 0; i < 40; i = i + 1) send_cycle(2, 10);
        if (!locked || state != 2'd2)
            $fatal(1, "two-sample high duty cycle failed to lock");
        if (period_est_fp < (24'd11 << 8) ||
            period_est_fp > (24'd13 << 8))
            $fatal(1, "narrow-duty estimate invalid: %0d", period_est_fp);

        // A corrupt recovered estimator must never self-prove a divide-by-two
        // lock.  The hard guard drops lock and the independent raw estimator
        // remains near the real 12-sample candidate period for reseeding.
        saved_lock_loss = lock_loss_count;
        force dut.period_est_fp = (24'd25 << 8);
        wait_clks(2);
        release dut.period_est_fp;
        wait_clks(2);
        if (dut.period_range_fault_count == 0 ||
            lock_loss_count != saved_lock_loss + 1 || state != 2'd0)
            $fatal(1, "period hard guard failed fault/loss/state=%0d/%0d/%0d",
                   dut.period_range_fault_count, lock_loss_count, state);
        if (dut.last_loss_reason != 4'd1 ||
            dut.period_at_loss != (24'd25 << 8))
            $fatal(1, "period-range loss scene incorrect reason/period=%0d/%0d",
                   dut.last_loss_reason, dut.period_at_loss);
        if (dut.candidate_period_est_fp < (24'd11 << 8) ||
            dut.candidate_period_est_fp > (24'd13 << 8))
            $fatal(1, "raw candidate estimator corrupted: %0d",
                   dut.candidate_period_est_fp);
        for (i = 0; i < 40; i = i + 1) send_cycle(2, 10);
        if (!locked || period_est_fp < (24'd11 << 8) ||
            period_est_fp > (24'd13 << 8))
            $fatal(1, "failed to reacquire after period fault");

        // Runtime history selection remains synthesizable for every tap; tap2
        // is restored as the operational default after the sweep.
        for (i = 0; i < 5; i = i + 1) begin
            sample_offset = i[2:0];
            send_cycle(2, 10);
            send_cycle(2, 10);
        end
        sample_offset = 3'd2;

        // Toggle DATA every 300 MHz sample to force disagreement between the
        // selected tap and both neighbours. This is diagnostic only.
        saved_glitch = dut.data_unstable_count;
        scramble_data = 1'b1;
        for (i = 0; i < 12; i = i + 1) begin
            pclk = 1'b1; wait_clks(6);
            pclk = 1'b0; wait_clks(6);
        end
        scramble_data = 1'b0;
        if (dut.data_unstable_count == saved_glitch)
            $fatal(1, "unstable DATA history was not counted");
        if (dut.candidate_count64 < candidate_count ||
            dut.valid_count64 < valid_count || dut.pixel_ce_count64 == 0)
            $fatal(1, "64-bit high-rate counters are inconsistent");

        $display("TB_DVP_PCLK_RECOVERY=PASS period_fp=%0d ce=%0d hold=%0d harmonic=%0d",
                 period_est_fp, ce_count, holdover_count,
                 harmonic_reject_count);
        $finish;
    end
endmodule
