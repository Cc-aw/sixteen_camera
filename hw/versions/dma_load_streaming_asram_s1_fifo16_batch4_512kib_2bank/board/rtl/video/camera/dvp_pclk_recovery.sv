`timescale 1ns/1ps

// PCLK is asynchronous data; every state element uses clk_300m.  SEARCH and
// ACQUIRE use real edges. LOCK maintains a wrapping fixed-point predicted phase and permits
// exactly one missing-edge HOLDOVER, never long-term free running.
module dvp_pclk_recovery #(
    parameter integer PERIOD_FRAC_BITS   = 8,
    parameter integer NOMINAL_PERIOD_FP  = 3200,
    parameter integer HIGH_CONFIRM       = 2,
    parameter integer LOW_CONFIRM        = 2,
    parameter integer DEAD_TIME_SAMPLES  = 8,
    parameter integer SEARCH_MIN_PERIOD  = 8,
    parameter integer SEARCH_MAX_PERIOD  = 18,
    parameter integer SEARCH_VALID_EDGES = 8,
    parameter integer ACQUIRE_EDGES      = 8,
    parameter integer ACQUIRE_WINDOW     = 4,
    parameter integer LOCK_WINDOW        = 2,
    parameter integer RECOVERY_WINDOW    = 4,
    parameter integer MAX_HOLDOVER       = 1,
    parameter integer PERIOD_IIR_SHIFT   = 3,
    parameter integer PERIOD_MIN         = 8,
    parameter integer PERIOD_MAX         = 18,
    parameter integer LOCK_THRESHOLD     = 24,
    parameter integer HOLDOVER_SCORE_MIN = 20,
    parameter integer RECOVERY_CONFIRM_EDGES = 3,
    parameter integer HARMONIC_CONFIRM_COUNT = 4,
    parameter integer RAW_ACCEPT_WINDOW = 3,
    parameter integer DATA_HISTORY_DEPTH = 8,
    parameter integer DEFAULT_DATA_SAMPLE_OFFSET = 2,
    parameter integer FIRST_EDGE_IS_PIXEL = 1
) (
    input  wire clk_300m, input wire resetn, input wire diag_clear,
    input  wire pclk_sample, input wire [7:0] data_sample,
    input  wire href_sample, input wire vsync_sample,
    input  wire frame_boundary,
    input  wire [2:0] data_sample_offset,
    output wire pixel_ce, output wire [7:0] pixel_data,
    output wire pixel_href, output wire pixel_vsync,
    output reg pclk_locked, output reg [1:0] recovery_state,
    output reg [23:0] period_est_fp, output reg [15:0] last_interval,
    output wire [15:0] interval_min, output wire [15:0] interval_max,
    output wire [23:0] phase_error_fp,
    output wire [23:0] phase_error_max_fp,
    output wire [31:0] candidate_count, output wire [31:0] valid_count,
    output wire [31:0] glitch_count, output wire [31:0] missing_count,
    output wire [31:0] holdover_count,
    output wire [31:0] holdover_recovered_count,
    output wire [31:0] harmonic_reject_count,
    output wire [31:0] lock_loss_count,
    output wire [31:0] data_unstable_count,
    output wire [15:0] short_high_count,
    output wire [15:0] short_low_count,
    output reg [23:0] candidate_period_est_fp,
    output reg [15:0] raw_candidate_interval,
    output wire [31:0] period_range_fault_count,
    output wire [31:0] half_period_candidate_count,
    output wire [31:0] too_early_count,
    output wire [31:0] too_late_count,
    output wire [31:0] invalid_interval_count,
    output reg [5:0] lock_score,
    output reg [3:0] recovery_confirm_count,
    output wire [3:0] last_loss_reason,
    output wire [31:0] data_stable_count,
    output wire [63:0] candidate_count64,
    output wire [63:0] valid_count64,
    output wire [63:0] pixel_ce_count64,
    output reg loss_event,
    output wire [23:0] period_at_loss,
    output wire [23:0] candidate_period_at_loss,
    output wire [23:0] phase_error_at_loss,
    output wire [15:0] interval_at_loss
);
    localparam [1:0] STATE_SEARCH = 2'd0, STATE_ACQUIRE = 2'd1,
                     STATE_LOCK = 2'd2, STATE_HOLDOVER = 2'd3;
    // The longest measured interval is 127 clocks. One extra integer bit
    // makes the signed phase difference unambiguous across a 128-clock span,
    // while avoiding 24-bit add/subtract logic in the 300 MHz core. External
    // diagnostic and estimator ports retain their existing 24-bit format.
    localparam integer FP_WIDTH = PERIOD_FRAC_BITS + 8;
    localparam integer FAST_INTERVAL_WIDTH = 7;
    localparam integer SEARCH_COUNT_WIDTH = $clog2(SEARCH_VALID_EDGES);
    localparam integer ACQUIRE_COUNT_WIDTH = $clog2(ACQUIRE_EDGES + 1);
    localparam [FAST_INTERVAL_WIDTH-1:0] FAST_INTERVAL_MAX = 7'h7f;
    localparam [3:0] HIGH_CONFIRM_COUNT = 4'(HIGH_CONFIRM);
    localparam [3:0] LOW_CONFIRM_COUNT = 4'(LOW_CONFIRM);
    localparam [15:0] DEAD_TIME_COUNT = 16'(DEAD_TIME_SAMPLES);
    localparam [15:0] SEARCH_MIN_COUNT = 16'(SEARCH_MIN_PERIOD);
    localparam [15:0] SEARCH_MAX_COUNT = 16'(SEARCH_MAX_PERIOD);
    localparam [7:0] SEARCH_EDGE_COUNT = 8'(SEARCH_VALID_EDGES);
    localparam [7:0] ACQUIRE_EDGE_COUNT = 8'(ACQUIRE_EDGES);
    localparam [7:0] MAX_HOLDOVER_COUNT = 8'(MAX_HOLDOVER);
    localparam [5:0] LOCK_SCORE_LIMIT = 6'd31;
    localparam [5:0] LOCK_SCORE_THRESHOLD = 6'(LOCK_THRESHOLD);
    localparam [5:0] HOLDOVER_SCORE_THRESHOLD = 6'(HOLDOVER_SCORE_MIN);
    localparam [3:0] RECOVERY_CONFIRM_COUNT = 4'(RECOVERY_CONFIRM_EDGES);
    localparam [3:0] HARMONIC_CONFIRM_LIMIT = 4'(HARMONIC_CONFIRM_COUNT);
    localparam [FP_WIDTH-1:0] NOMINAL_PERIOD =
        FP_WIDTH'(NOMINAL_PERIOD_FP);
    localparam [FP_WIDTH-1:0] ACQUIRE_WINDOW_FP =
        FP_WIDTH'(ACQUIRE_WINDOW << PERIOD_FRAC_BITS);
    localparam [FP_WIDTH-1:0] LOCK_WINDOW_FP =
        FP_WIDTH'(LOCK_WINDOW << PERIOD_FRAC_BITS);
    localparam [FP_WIDTH-1:0] RECOVERY_WINDOW_FP =
        FP_WIDTH'(RECOVERY_WINDOW << PERIOD_FRAC_BITS);
    localparam [15:0] HARMONIC_MIN_COUNT = 16'(
        (NOMINAL_PERIOD_FP >> PERIOD_FRAC_BITS) * 2 - 4);
    localparam [15:0] HARMONIC_MAX_COUNT = 16'(
        (NOMINAL_PERIOD_FP >> PERIOD_FRAC_BITS) * 2 + 6);

    initial begin
        if (HIGH_CONFIRM < 2 || HIGH_CONFIRM > 15 ||
            LOW_CONFIRM < 2 || LOW_CONFIRM > 15 ||
            DEAD_TIME_SAMPLES < HIGH_CONFIRM ||
            SEARCH_MIN_PERIOD < DEAD_TIME_SAMPLES ||
            SEARCH_MAX_PERIOD <= SEARCH_MIN_PERIOD ||
            SEARCH_MAX_PERIOD > FAST_INTERVAL_MAX ||
            HARMONIC_MAX_COUNT > FAST_INTERVAL_MAX ||
            NOMINAL_PERIOD_FP < (PERIOD_MIN << PERIOD_FRAC_BITS) ||
            NOMINAL_PERIOD_FP > (PERIOD_MAX << PERIOD_FRAC_BITS) ||
            PERIOD_MIN < SEARCH_MIN_PERIOD || PERIOD_MAX > SEARCH_MAX_PERIOD ||
            SEARCH_VALID_EDGES < 2 || SEARCH_VALID_EDGES > 255 ||
            ACQUIRE_EDGES < 2 || ACQUIRE_EDGES > 255 ||
            ACQUIRE_WINDOW < LOCK_WINDOW ||
            RECOVERY_WINDOW < LOCK_WINDOW || LOCK_WINDOW < 1 ||
            MAX_HOLDOVER != 1 || LOCK_THRESHOLD < 4 || LOCK_THRESHOLD > 31 ||
            HOLDOVER_SCORE_MIN < 4 || HOLDOVER_SCORE_MIN > LOCK_THRESHOLD ||
            RECOVERY_CONFIRM_EDGES < 2 || RECOVERY_CONFIRM_EDGES > 8 ||
            HARMONIC_CONFIRM_COUNT < 2 || HARMONIC_CONFIRM_COUNT > 8 ||
            RAW_ACCEPT_WINDOW < 1 || RAW_ACCEPT_WINDOW > 4 ||
            PERIOD_FRAC_BITS < 1 ||
            PERIOD_FRAC_BITS > 12 || DATA_HISTORY_DEPTH < 2 ||
            DATA_HISTORY_DEPTH > 8 || DEFAULT_DATA_SAMPLE_OFFSET < 0 ||
            DEFAULT_DATA_SAMPLE_OFFSET >= DATA_HISTORY_DEPTH ||
            (FIRST_EDGE_IS_PIXEL != 0 && FIRST_EDGE_IS_PIXEL != 1))
            $error("invalid dvp_pclk_recovery parameters");
    end

    // Symmetric deglitcher. Two samples retain margin for distorted 24 MHz
    // duty cycles; dead-time and the predicted window reject wider pulses.
    reg filtered_pclk;
    reg [3:0] high_run, low_run;
    reg candidate_edge;
    reg diag_short_high_event, diag_short_low_event;
    always @(posedge clk_300m) begin
        if (!resetn) begin
            filtered_pclk <= 1'b0;
            high_run <= 4'd0;
            low_run <= 4'd0;
            candidate_edge <= 1'b0;
            diag_short_high_event <= 1'b0;
            diag_short_low_event <= 1'b0;
        end else begin
            candidate_edge <= 1'b0;
            diag_short_high_event <= 1'b0;
            diag_short_low_event <= 1'b0;
            if (pclk_sample) begin
                if (low_run != 0 && filtered_pclk &&
                    low_run < LOW_CONFIRM_COUNT)
                    diag_short_low_event <= 1'b1;
                low_run <= 4'd0;
                if (!filtered_pclk) begin
                    if (high_run == HIGH_CONFIRM_COUNT - 1'b1) begin
                        filtered_pclk <= 1'b1;
                        high_run <= 4'd0;
                        candidate_edge <= 1'b1;
                    end else high_run <= high_run + 1'b1;
                end else high_run <= 4'd0;
            end else begin
                if (high_run != 0 && !filtered_pclk &&
                    high_run < HIGH_CONFIRM_COUNT)
                    diag_short_high_event <= 1'b1;
                high_run <= 4'd0;
                if (filtered_pclk) begin
                    if (low_run == LOW_CONFIRM_COUNT - 1'b1) begin
                        filtered_pclk <= 1'b0;
                        low_run <= 4'd0;
                    end else low_run <= low_run + 1'b1;
                end else low_run <= 4'd0;
            end
        end
    end

    reg accepted_edge_seen;
    reg [FAST_INTERVAL_WIDTH-1:0] accepted_edge_elapsed;
    reg [SEARCH_COUNT_WIDTH-1:0] search_good_count;
    reg [ACQUIRE_COUNT_WIDTH-1:0] acquire_good_count;
    reg consecutive_missing;
    reg recovered_edge;
    reg recovered_deadline_edge, recovered_deadline_edge_q;
    reg [FP_WIDTH-1:0] phase_now_fp, expected_phase_fp;
    reg href_sample_d, blanking_gap_seen, acquire_anchor_pending;
    reg raw_edge_seen;
    reg [FAST_INTERVAL_WIDTH-1:0] raw_edge_elapsed;
    reg [3:0] period_stable_count;
    reg [3:0] harmonic_confirm;
    reg half_period_candidate_d, harmonic_ratio_match_d;
    reg candidate_early_d;
    reg [FP_WIDTH-1:0] candidate_phase_abs_d;
    // Diagnostic events are registered at the functional decision boundary.
    // Wide counters consume these one cycle later, preventing their carry and
    // saturation logic from feeding back into the 300 MHz recovery FSM.
    reg diag_candidate_event, diag_valid_event, diag_glitch_event;
    reg diag_missing_event, diag_holdover_event;
    reg diag_holdover_recovered_event, diag_harmonic_reject_event;
    reg diag_lock_loss_event, diag_period_range_fault_event;
    reg diag_half_period_event, diag_too_early_event;
    reg diag_too_late_event, diag_invalid_interval_event;
    reg diag_phase_event;
    reg [FP_WIDTH-1:0] diag_phase_value;
    reg diag_interval_event;
    reg [15:0] diag_interval_value;
    reg loss_snapshot_event;
    reg [3:0] loss_snapshot_reason;
    reg [23:0] loss_snapshot_period;
    reg [23:0] loss_snapshot_candidate_period;
    reg [23:0] loss_snapshot_phase_error;
    reg [15:0] loss_snapshot_interval;
    // Stage A snapshots the physical edge. Stage B classifies that snapshot;
    // Stage C consumes only registered flags. Even the shortest accepted PCLK
    // interval leaves enough clocks for both pipeline registers.
    reg edge_event;
    reg class_event;
    reg edge_raw_seen;
    reg [FAST_INTERVAL_WIDTH-1:0] edge_candidate_interval,
        edge_raw_interval;
    reg [FP_WIDTH-1:0] edge_phase_now_q, edge_expected_phase_q;
    reg [FP_WIDTH-1:0] edge_candidate_period_q;
    reg [1:0] edge_recovery_state_q;
    reg [FP_WIDTH-1:0] edge_raw_estimator_next;
    reg edge_raw_interval_valid;
    reg edge_raw_near_candidate, edge_raw_near_double;
    reg edge_search_interval_valid, edge_harmonic_interval;
    reg edge_dead_interval, edge_short_interval;
    reg edge_phase_negative, edge_in_phase_window;
    reg [FP_WIDTH-1:0] edge_phase_abs;
    // Keep the established physical phase anchor even though FSM dispatch
    // moves one clock later; processing latency must not move PCLK sampling.
    reg [FP_WIDTH-1:0] edge_phase_anchor_q;
    wire signed [FP_WIDTH-1:0] class_phase_error =
        $signed(edge_phase_now_q - edge_expected_phase_q);
    wire [FP_WIDTH-1:0] class_phase_abs =
        class_phase_error[FP_WIDTH-1] ?
        (~class_phase_error + 1'b1) : class_phase_error;
    wire [FP_WIDTH-1:0] class_window_fp =
        (edge_recovery_state_q == STATE_ACQUIRE) ? ACQUIRE_WINDOW_FP :
        (edge_recovery_state_q == STATE_HOLDOVER) ? RECOVERY_WINDOW_FP :
        LOCK_WINDOW_FP;
    wire [FP_WIDTH-1:0] class_candidate_period_rounded =
        edge_candidate_period_q + FP_WIDTH'(1 << (PERIOD_FRAC_BITS - 1));
    wire [15:0] class_candidate_cycles =
        class_candidate_period_rounded >> PERIOD_FRAC_BITS;
    wire [15:0] class_double_cycles = class_candidate_cycles << 1;
    wire class_raw_valid = edge_raw_interval >= 16'(PERIOD_MIN) &&
                           edge_raw_interval <= 16'(PERIOD_MAX);
    wire class_raw_near_candidate = class_raw_valid &&
        edge_raw_interval >= class_candidate_cycles - 16'(RAW_ACCEPT_WINDOW) &&
        edge_raw_interval <= class_candidate_cycles + 16'(RAW_ACCEPT_WINDOW);
    wire class_raw_near_double =
        edge_raw_interval >= class_double_cycles - 16'(RAW_ACCEPT_WINDOW + 1) &&
        edge_raw_interval <= class_double_cycles + 16'(RAW_ACCEPT_WINDOW + 1);

    wire [FAST_INTERVAL_WIDTH-1:0] candidate_interval =
        (accepted_edge_elapsed == FAST_INTERVAL_MAX) ? FAST_INTERVAL_MAX :
        accepted_edge_elapsed + 1'b1;
    wire [FAST_INTERVAL_WIDTH-1:0] raw_interval =
        (raw_edge_elapsed == FAST_INTERVAL_MAX) ? FAST_INTERVAL_MAX :
        raw_edge_elapsed + 1'b1;
    // The IIR now belongs to Stage B as well: Stage A only captures the raw
    // interval and the independent period estimate.
    wire [FP_WIDTH-1:0] class_raw_interval_fp =
        FP_WIDTH'(edge_raw_interval) << PERIOD_FRAC_BITS;
    wire signed [FP_WIDTH:0] class_raw_estimator_error =
        $signed({1'b0, class_raw_interval_fp}) -
        $signed({1'b0, edge_candidate_period_q});
    wire signed [FP_WIDTH:0] class_raw_estimator_next_signed =
        $signed({1'b0, edge_candidate_period_q}) +
        (class_raw_estimator_error >>> PERIOD_IIR_SHIFT);
    wire period_current_valid = period_est_fp >=
                                FP_WIDTH'(PERIOD_MIN << PERIOD_FRAC_BITS) &&
                                period_est_fp <=
                                FP_WIDTH'(PERIOD_MAX << PERIOD_FRAC_BITS);
    wire signed [FP_WIDTH-1:0] candidate_phase_error =
        $signed(phase_now_fp - expected_phase_fp);
    wire [FP_WIDTH-1:0] candidate_phase_abs =
        candidate_phase_error[FP_WIDTH-1] ?
        (~candidate_phase_error + 1'b1) : candidate_phase_error;
    // A real physical edge is identified primarily by its interval relative
    // to the independent raw estimator.  The phase predictor is deliberately
    // not allowed to delete such an edge: doing so makes the accepted-edge
    // estimator drift toward 2T and can collapse every following video line.
    wire physical_edge_valid = class_event && edge_raw_seen &&
        (edge_raw_near_candidate || edge_in_phase_window ||
         ((edge_recovery_state_q == STATE_HOLDOVER) &&
          edge_raw_near_double));
    wire signed [FP_WIDTH-1:0] deadline_next_error =
        $signed((phase_now_fp + FP_WIDTH'(1 << PERIOD_FRAC_BITS)) -
                expected_phase_fp);
    reg deadline_closed_q;
    // Classification may use the narrow LOCK window, but absence must not be
    // declared until the wider recovery window has fully elapsed. Otherwise
    // a legitimate +3-sample edge is preceded by a synthetic HOLDOVER CE and
    // the line gains a duplicate byte.
    // Predict the next cycle's deadline at a register boundary. A pending
    // physical edge suppresses the deadline until classification completes.
    wire phase_window_closed = deadline_closed_q && !candidate_edge &&
                               !edge_event && !physical_edge_valid;
    wire [FP_WIDTH-1:0] twice_candidate_period =
        candidate_period_est_fp << 1;
    wire [FP_WIDTH-1:0] harmonic_ratio_error =
        (period_est_fp >= twice_candidate_period) ?
        period_est_fp - twice_candidate_period :
        twice_candidate_period - period_est_fp;
    wire harmonic_ratio_match = harmonic_ratio_error <=
        FP_WIDTH'(2 << PERIOD_FRAC_BITS);
    wire [FP_WIDTH-1:0] half_period_fp = period_est_fp >> 1;
    wire [FP_WIDTH-1:0] half_phase_error =
        (candidate_phase_abs_d >= half_period_fp) ?
        candidate_phase_abs_d - half_period_fp :
        half_period_fp - candidate_phase_abs_d;
    wire half_period_candidate_now = candidate_early_d &&
        (half_phase_error <= FP_WIDTH'(2 << PERIOD_FRAC_BITS));
    wire holdover_eligible = pclk_locked && href_sample &&
        (lock_score >= HOLDOVER_SCORE_THRESHOLD) &&
        (period_stable_count >= 8) &&
        (harmonic_confirm == 0);

    always @(posedge clk_300m) begin
        if (!resetn) begin
            accepted_edge_seen <= 1'b0;
            accepted_edge_elapsed <= '0;
            search_good_count <= '0;
            acquire_good_count <= '0;
            consecutive_missing <= '0;
            recovered_edge <= 1'b0;
            recovered_deadline_edge <= 1'b0;
            recovered_deadline_edge_q <= 1'b0;
            phase_now_fp <= 24'd0;
            expected_phase_fp <= NOMINAL_PERIOD;
            href_sample_d <= 1'b0;
            blanking_gap_seen <= 1'b0;
            acquire_anchor_pending <= 1'b0;
            raw_edge_seen <= 1'b0;
            raw_edge_elapsed <= '0;
            period_stable_count <= '0;
            harmonic_confirm <= 4'd0;
            half_period_candidate_d <= 1'b0;
            harmonic_ratio_match_d <= 1'b0;
            candidate_early_d <= 1'b0;
            candidate_phase_abs_d <= {FP_WIDTH{1'b0}};
            pclk_locked <= 1'b0;
            recovery_state <= STATE_SEARCH;
            period_est_fp <= NOMINAL_PERIOD;
            last_interval <= 16'd0;
            candidate_period_est_fp <= NOMINAL_PERIOD;
            raw_candidate_interval <= 16'd0;
            lock_score <= 6'd0;
            recovery_confirm_count <= 4'd0;
            loss_event <= 1'b0;
            loss_snapshot_event <= 1'b0;
            loss_snapshot_reason <= 4'd0;
            loss_snapshot_period <= 24'd0;
            loss_snapshot_candidate_period <= 24'd0;
            loss_snapshot_phase_error <= 24'd0;
            loss_snapshot_interval <= 16'd0;
            diag_candidate_event <= 1'b0;
            diag_valid_event <= 1'b0;
            diag_glitch_event <= 1'b0;
            diag_missing_event <= 1'b0;
            diag_holdover_event <= 1'b0;
            diag_holdover_recovered_event <= 1'b0;
            diag_harmonic_reject_event <= 1'b0;
            diag_lock_loss_event <= 1'b0;
            diag_period_range_fault_event <= 1'b0;
            diag_half_period_event <= 1'b0;
            diag_too_early_event <= 1'b0;
            diag_too_late_event <= 1'b0;
            diag_invalid_interval_event <= 1'b0;
            diag_phase_event <= 1'b0;
            diag_phase_value <= {FP_WIDTH{1'b0}};
            diag_interval_event <= 1'b0;
            diag_interval_value <= 16'd0;
            edge_event <= 1'b0;
            class_event <= 1'b0;
            edge_raw_seen <= 1'b0;
            edge_candidate_interval <= '0;
            edge_raw_interval <= '0;
            edge_phase_now_q <= '0;
            edge_expected_phase_q <= '0;
            edge_candidate_period_q <= '0;
            edge_recovery_state_q <= STATE_SEARCH;
            edge_raw_estimator_next <= NOMINAL_PERIOD;
            edge_raw_interval_valid <= 1'b0;
            edge_raw_near_candidate <= 1'b0;
            edge_raw_near_double <= 1'b0;
            edge_search_interval_valid <= 1'b0;
            edge_harmonic_interval <= 1'b0;
            edge_dead_interval <= 1'b0;
            edge_short_interval <= 1'b0;
            edge_phase_negative <= 1'b0;
            edge_in_phase_window <= 1'b0;
            edge_phase_abs <= {FP_WIDTH{1'b0}};
            edge_phase_anchor_q <= {FP_WIDTH{1'b0}};
            deadline_closed_q <= 1'b0;
        end else begin
            recovered_edge <= 1'b0;
            recovered_deadline_edge <= 1'b0;
            recovered_deadline_edge_q <= recovered_deadline_edge;
            loss_event <= 1'b0;
            loss_snapshot_event <= 1'b0;
            diag_candidate_event <= 1'b0;
            diag_valid_event <= 1'b0;
            diag_glitch_event <= 1'b0;
            diag_missing_event <= 1'b0;
            diag_holdover_event <= 1'b0;
            diag_holdover_recovered_event <= 1'b0;
            diag_harmonic_reject_event <= 1'b0;
            diag_lock_loss_event <= 1'b0;
            diag_period_range_fault_event <= 1'b0;
            diag_half_period_event <= 1'b0;
            diag_too_early_event <= 1'b0;
            diag_too_late_event <= 1'b0;
            diag_invalid_interval_event <= 1'b0;
            diag_phase_event <= 1'b0;
            diag_interval_event <= 1'b0;
            edge_event <= candidate_edge;
            class_event <= edge_event;
            if ((class_event && (physical_edge_valid || acquire_anchor_pending)) ||
                phase_window_closed || frame_boundary)
                deadline_closed_q <= 1'b0;
            else
                deadline_closed_q <=
                    !deadline_next_error[FP_WIDTH-1] &&
                    deadline_next_error > $signed(RECOVERY_WINDOW_FP);
            if (candidate_edge) begin
                edge_raw_seen <= raw_edge_seen;
                edge_candidate_interval <= candidate_interval;
                edge_raw_interval <= raw_interval;
                edge_phase_now_q <= phase_now_fp;
                edge_expected_phase_q <= expected_phase_fp;
                edge_candidate_period_q <= candidate_period_est_fp[FP_WIDTH-1:0];
                edge_recovery_state_q <= recovery_state;
                edge_phase_anchor_q <=
                    phase_now_fp + FP_WIDTH'(1 << PERIOD_FRAC_BITS);
            end
            if (edge_event) begin
                edge_raw_estimator_next <=
                    class_raw_estimator_next_signed[FP_WIDTH-1:0];
                edge_raw_interval_valid <= class_raw_valid;
                edge_raw_near_candidate <= class_raw_near_candidate;
                edge_raw_near_double <= class_raw_near_double;
                edge_search_interval_valid <=
                    edge_candidate_interval >= SEARCH_MIN_COUNT &&
                    edge_candidate_interval <= SEARCH_MAX_COUNT;
                edge_harmonic_interval <=
                    edge_candidate_interval >= HARMONIC_MIN_COUNT &&
                    edge_candidate_interval <= HARMONIC_MAX_COUNT;
                edge_dead_interval <= edge_candidate_interval < DEAD_TIME_COUNT;
                edge_short_interval <= edge_candidate_interval < SEARCH_MIN_COUNT;
                edge_phase_negative <= class_phase_error[FP_WIDTH-1];
                edge_in_phase_window <= class_phase_abs <= class_window_fp;
                edge_phase_abs <= class_phase_abs;
            end
            // Payloads are sampled every cycle. Registered event flags qualify
            // them in the following diagnostic stage, avoiding a complex CE
            // path from the recovery decision into these payload registers.
            diag_phase_value <= edge_phase_abs;
            diag_interval_value <=
                (recovery_state == STATE_SEARCH) ?
                edge_candidate_interval : edge_raw_interval;
            // Diagnostic/harmonic classification is intentionally split over
            // two pipeline boundaries. It is not part of the pixel_ce
            // decision and must not lengthen the 300 MHz recovery path.
            candidate_early_d <= candidate_edge &&
                                 candidate_phase_error[FP_WIDTH-1];
            candidate_phase_abs_d <= candidate_phase_abs;
            half_period_candidate_d <= half_period_candidate_now;
            harmonic_ratio_match_d <= harmonic_ratio_match;
            href_sample_d <= href_sample;
            phase_now_fp <= phase_now_fp + FP_WIDTH'(1 << PERIOD_FRAC_BITS);
            if (accepted_edge_seen &&
                accepted_edge_elapsed != FAST_INTERVAL_MAX)
                accepted_edge_elapsed <= accepted_edge_elapsed + 1'b1;
            if (raw_edge_seen && raw_edge_elapsed != FAST_INTERVAL_MAX)
                raw_edge_elapsed <= raw_edge_elapsed + 1'b1;
            if (class_event && edge_raw_near_candidate)
                candidate_period_est_fp <= edge_raw_estimator_next;
            else if (class_event && !edge_raw_interval_valid)
                diag_invalid_interval_event <= 1'b1;
            if (candidate_edge)
                diag_candidate_event <= 1'b1;
            if (candidate_edge) begin
                if (!raw_edge_seen) begin
                    raw_edge_seen <= 1'b1;
                    raw_edge_elapsed <= '0;
                end else begin
                    raw_candidate_interval <= raw_interval;
                    raw_edge_elapsed <= '0;
                end
            end
            if (half_period_candidate_d) begin
                diag_half_period_event <= 1'b1;
                if (harmonic_ratio_match_d) begin
                    if (harmonic_confirm < HARMONIC_CONFIRM_LIMIT)
                        harmonic_confirm <= harmonic_confirm + 1'b1;
                end else begin
                    harmonic_confirm <= 4'd0;
                end
            end else if (class_event &&
                         recovery_state == STATE_LOCK &&
                         edge_in_phase_window) begin
                harmonic_confirm <= 4'd0;
            end

            case (recovery_state)
                STATE_SEARCH: begin
                    pclk_locked <= 1'b0;
                    consecutive_missing <= '0;
                    lock_score <= 6'd0;
                    recovery_confirm_count <= 4'd0;
                    harmonic_confirm <= 4'd0;
                    if (class_event) begin
                        if (!accepted_edge_seen) begin
                            accepted_edge_seen <= 1'b1;
                            accepted_edge_elapsed <= '0;
                            search_good_count <= '0;
                        end else begin
                            last_interval <= edge_candidate_interval;
                            if (edge_dead_interval) begin
                                diag_glitch_event <= 1'b1;
                            end else if (edge_search_interval_valid) begin
                                recovered_edge <= 1'b1;
                                accepted_edge_elapsed <= '0;
                                diag_valid_event <= 1'b1;
                                diag_interval_event <= 1'b1;
                                period_est_fp <= edge_raw_estimator_next;
                                if (search_good_count ==
                                    SEARCH_EDGE_COUNT - 1'b1) begin
                                    recovery_state <= STATE_ACQUIRE;
                                    acquire_good_count <= '0;
                                    acquire_anchor_pending <= 1'b0;
                                    expected_phase_fp <=
                                        edge_phase_anchor_q + edge_raw_estimator_next;
                                end else search_good_count <=
                                    search_good_count + 1'b1;
                            end else if (edge_short_interval) begin
                                diag_glitch_event <= 1'b1;
                            end else begin
                                // Late edges can re-anchor measurement but
                                // never seed a 2x-period estimate.
                                accepted_edge_elapsed <= '0;
                                search_good_count <= '0;
                                if (edge_harmonic_interval)
                                    diag_harmonic_reject_event <= 1'b1;
                            end
                        end
                    end
                end

                STATE_ACQUIRE: begin
                    pclk_locked <= 1'b0;
                    if (class_event && acquire_anchor_pending) begin
                        // PCLK was gated in blanking: the first real edge of
                        // the new line is a phase anchor, not a timing error.
                        if (FIRST_EDGE_IS_PIXEL != 0)
                            recovered_edge <= 1'b1;
                        accepted_edge_seen <= 1'b1;
                        accepted_edge_elapsed <= '0;
                        expected_phase_fp <= edge_phase_anchor_q + period_est_fp;
                        acquire_anchor_pending <= 1'b0;
                        acquire_good_count <= '0;
                        lock_score <= 6'd0;
                        if (FIRST_EDGE_IS_PIXEL != 0) begin
                            diag_valid_event <= 1'b1;
                        end
                    end else if (physical_edge_valid) begin
                        diag_phase_event <= 1'b1;
                        recovered_edge <= 1'b1;
                        accepted_edge_elapsed <= '0;
                        diag_valid_event <= 1'b1;
                        if (edge_raw_near_candidate) begin
                            diag_interval_event <= 1'b1;
                            period_est_fp <= edge_raw_estimator_next;
                            expected_phase_fp <=
                                edge_phase_anchor_q + edge_raw_estimator_next;
                        end else begin
                            // A phase-consistent real edge may follow a false
                            // candidate that split its raw interval. Keep the
                            // independent period estimate and only re-anchor.
                            expected_phase_fp <=
                                edge_phase_anchor_q + candidate_period_est_fp;
                        end
                        if (edge_in_phase_window) begin
                            if (lock_score <= LOCK_SCORE_LIMIT - 3)
                                lock_score <= lock_score + 3'd3;
                            else
                                lock_score <= LOCK_SCORE_LIMIT;
                        end else begin
                            // A plausible physical edge is a phase re-anchor,
                            // never a dropped byte.
                            if (lock_score != 0)
                                lock_score <= lock_score - 1'b1;
                            if (edge_phase_negative) begin
                                diag_too_early_event <= 1'b1;
                            end else
                                diag_too_late_event <= 1'b1;
                        end
                        if ((acquire_good_count >=
                             ACQUIRE_EDGE_COUNT - 1'b1) &&
                            (lock_score >= LOCK_SCORE_THRESHOLD - 3)) begin
                            recovery_state <= STATE_LOCK;
                            pclk_locked <= 1'b1;
                            period_stable_count <= '0;
                        end else if (acquire_good_count < ACQUIRE_EDGE_COUNT)
                            acquire_good_count <= acquire_good_count + 1'b1;
                    end else if (phase_window_closed) begin
                        if (class_event)
                            diag_glitch_event <= 1'b1;
                        recovery_state <= STATE_SEARCH;
                        search_good_count <= '0;
                        accepted_edge_seen <= 1'b0;
                        diag_missing_event <= 1'b1;
                    end else if (class_event) begin
                        diag_glitch_event <= 1'b1;
                        if (edge_phase_negative)
                            diag_too_early_event <= 1'b1;
                    end
                end

                STATE_LOCK, STATE_HOLDOVER: begin
                    if (physical_edge_valid) begin
                        diag_phase_event <= 1'b1;
                        recovered_edge <= 1'b1;
                        if (!href_sample)
                            blanking_gap_seen <= 1'b0;
                        accepted_edge_seen <= 1'b1;
                        accepted_edge_elapsed <= '0;
                        consecutive_missing <= '0;
                        diag_valid_event <= 1'b1;
                        if (edge_raw_near_candidate) begin
                            period_est_fp <= edge_raw_estimator_next;
                            expected_phase_fp <=
                                edge_phase_anchor_q + edge_raw_estimator_next;
                            diag_interval_event <= 1'b1;
                        end else begin
                            // The first real edge after one missing cycle is
                            // roughly 2T. Keep the learned T and re-anchor.
                            expected_phase_fp <=
                                edge_phase_anchor_q + candidate_period_est_fp;
                        end
                        if (edge_in_phase_window) begin
                            if (lock_score < LOCK_SCORE_LIMIT)
                                lock_score <= lock_score + 1'b1;
                        end else begin
                            if (lock_score != 0)
                                lock_score <= lock_score - 1'b1;
                            if (edge_phase_negative) begin
                                diag_too_early_event <= 1'b1;
                            end else
                                diag_too_late_event <= 1'b1;
                        end
                        if (period_stable_count < 4'd8)
                            period_stable_count <= period_stable_count + 1'b1;
                        if (recovery_state == STATE_HOLDOVER) begin
                            if (recovery_confirm_count >=
                                RECOVERY_CONFIRM_COUNT - 1'b1) begin
                                recovery_state <= STATE_LOCK;
                                recovery_confirm_count <= 4'd0;
                                diag_holdover_recovered_event <= 1'b1;
                            end else begin
                                recovery_confirm_count <=
                                    recovery_confirm_count + 1'b1;
                            end
                        end else begin
                            recovery_state <= STATE_LOCK;
                            recovery_confirm_count <= 4'd0;
                        end
                    end else if (phase_window_closed) begin
                        if (class_event)
                            diag_glitch_event <= 1'b1;
                        expected_phase_fp <=
                            expected_phase_fp + period_est_fp;
                        if (!href_sample) begin
                            // A gated PCLK during horizontal blanking is not
                            // a missing video pixel and consumes no holdover.
                            consecutive_missing <= '0;
                            recovery_state <= STATE_LOCK;
                            pclk_locked <= 1'b1;
                            recovery_confirm_count <= 4'd0;
                            blanking_gap_seen <= 1'b1;
                        end else begin
                            diag_missing_event <= 1'b1;
                            if ((recovery_state == STATE_LOCK) &&
                                (consecutive_missing < MAX_HOLDOVER_COUNT) &&
                                holdover_eligible) begin
                                // Only synthesize after the complete real-edge
                                // acceptance window has expired. Re-anchor the
                                // next deadline from this decision point; an
                                // old predicted deadline may already be in the
                                // past after a late rejected glitch.
                                recovered_deadline_edge <= 1'b1;
                                expected_phase_fp <=
                                    phase_now_fp + candidate_period_est_fp;
                                consecutive_missing <=
                                    consecutive_missing + 1'b1;
                                recovery_state <= STATE_HOLDOVER;
                                pclk_locked <= 1'b1;
                                recovery_confirm_count <= 4'd0;
                                if (lock_score >= 4)
                                    lock_score <= lock_score - 3'd4;
                                else
                                    lock_score <= 6'd0;
                                diag_holdover_event <= 1'b1;
                            end else begin
                                recovery_state <= STATE_SEARCH;
                                pclk_locked <= 1'b0;
                                search_good_count <= '0;
                                accepted_edge_seen <= 1'b0;
                                lock_score <= 6'd0;
                                recovery_confirm_count <= 4'd0;
                                loss_snapshot_reason <=
                                    (recovery_state == STATE_HOLDOVER) ?
                                    4'd9 : 4'd2;
                                loss_event <= 1'b1;
                                loss_snapshot_event <= 1'b1;
                                loss_snapshot_period <= period_est_fp;
                                loss_snapshot_candidate_period <=
                                    candidate_period_est_fp;
                                loss_snapshot_phase_error <= phase_error_fp;
                                loss_snapshot_interval <= last_interval;
                                diag_lock_loss_event <= 1'b1;
                            end
                        end
                    end else if (class_event) begin
                        // A candidate inconsistent with the raw period is a
                        // real glitch. It must not move phase or emit CE.
                        diag_glitch_event <= 1'b1;
                    end
                end
                default: recovery_state <= STATE_SEARCH;
            endcase

            if (href_sample && !href_sample_d && blanking_gap_seen) begin
                recovery_state <= STATE_ACQUIRE;
                pclk_locked <= 1'b0;
                acquire_good_count <= '0;
                acquire_anchor_pending <= 1'b1;
                blanking_gap_seen <= 1'b0;
                consecutive_missing <= '0;
                recovery_confirm_count <= 4'd0;
            end

            if (frame_boundary) begin
                consecutive_missing <= '0;
                recovery_confirm_count <= 4'd0;
                harmonic_confirm <= 4'd0;
                if (recovery_state == STATE_HOLDOVER) begin
                    recovery_state <= STATE_LOCK;
                    pclk_locked <= period_current_valid;
                end
            end

            // A corrupt estimator is never silently clamped.  The learned
            // raw period remains available to seed the following SEARCH.
            if ((recovery_state != STATE_SEARCH) && !period_current_valid) begin
                recovery_state <= STATE_SEARCH;
                pclk_locked <= 1'b0;
                period_est_fp <= candidate_period_est_fp;
                search_good_count <= '0;
                accepted_edge_seen <= 1'b0;
                lock_score <= 6'd0;
                recovery_confirm_count <= 4'd0;
                loss_event <= 1'b1;
                loss_snapshot_event <= 1'b1;
                loss_snapshot_reason <= 4'd1;
                loss_snapshot_period <= period_est_fp;
                loss_snapshot_candidate_period <= candidate_period_est_fp;
                loss_snapshot_phase_error <= phase_error_fp;
                loss_snapshot_interval <= last_interval;
                diag_period_range_fault_event <= 1'b1;
                if (pclk_locked || recovery_state == STATE_HOLDOVER)
                    diag_lock_loss_event <= 1'b1;
            end else if ((recovery_state == STATE_LOCK) &&
                         (harmonic_confirm >=
                          HARMONIC_CONFIRM_LIMIT - 1'b1)) begin
                recovery_state <= STATE_ACQUIRE;
                pclk_locked <= 1'b0;
                period_est_fp <= candidate_period_est_fp;
                expected_phase_fp <= phase_now_fp + candidate_period_est_fp;
                acquire_good_count <= '0;
                lock_score <= 6'd0;
                harmonic_confirm <= 4'd0;
                loss_event <= 1'b1;
                loss_snapshot_event <= 1'b1;
                loss_snapshot_reason <= 4'd4;
                loss_snapshot_period <= period_est_fp;
                loss_snapshot_candidate_period <= candidate_period_est_fp;
                loss_snapshot_phase_error <= phase_error_fp;
                loss_snapshot_interval <= last_interval;
                diag_harmonic_reject_event <= 1'b1;
                diag_lock_loss_event <= 1'b1;
            end

        end
    end

    // Continuous IOB-aligned bus history. Tap 2 is the current board default
    // and samples approximately 6.67 ns after the recovered phase.
    reg [7:0] data_history [0:DATA_HISTORY_DEPTH-1];
    reg href_history [0:DATA_HISTORY_DEPTH-1];
    reg vsync_history [0:DATA_HISTORY_DEPTH-1];
    // Stage B adds one clock before recovered_edge. Shorten only the CE delay
    // by one; payload history and tap selection retain their board phase.
    reg [DATA_HISTORY_DEPTH-2:0] recovered_history;
    integer history_index;
    wire [2:0] bounded_sample_offset =
        ({1'b0, data_sample_offset} < 4'(DATA_HISTORY_DEPTH)) ?
        data_sample_offset :
        3'(DEFAULT_DATA_SAMPLE_OFFSET);
    // The registered classification and final tap add latency to the CE.
    // Delay the DATA history by the same amount so the software-visible tap
    // retains its established board-level sampling phase (tap 2).
    wire [2:0] sample_index =
        (bounded_sample_offset == 0) ? 3'(DATA_HISTORY_DEPTH - 1) :
        3'(DATA_HISTORY_DEPTH) - bounded_sample_offset;
    wire [2:0] sample_neighbor_early =
        (sample_index == 0) ? sample_index : sample_index - 1'b1;
    wire [2:0] sample_neighbor_late =
        (sample_index == 3'(DATA_HISTORY_DEPTH-1)) ? sample_index :
        sample_index + 1'b1;
    wire selected_data_stable =
        (data_history[sample_index] == data_history[sample_neighbor_early]) &&
        (data_history[sample_index] == data_history[sample_neighbor_late]);
    reg tap_ce_q;
    reg [7:0] tap_data_q;
    reg tap_href_q, tap_vsync_q, tap_stable_q;
    assign pixel_ce = tap_ce_q;
    assign pixel_data = tap_data_q;
    assign pixel_href = tap_href_q;
    assign pixel_vsync = tap_vsync_q;

    // History and selected payload do not need reset. The reset tap valid
    // keeps them invisible until a recovered sample has reached the tap.
    always @(posedge clk_300m) begin
        data_history[0] <= data_sample;
        href_history[0] <= href_sample;
        vsync_history[0] <= vsync_sample;
        for (history_index = 1; history_index < DATA_HISTORY_DEPTH;
             history_index = history_index + 1) begin
            data_history[history_index] <= data_history[history_index-1];
            href_history[history_index] <= href_history[history_index-1];
            vsync_history[history_index] <= vsync_history[history_index-1];
        end
        tap_data_q <= data_history[sample_index];
        tap_href_q <= href_history[sample_index];
        tap_vsync_q <= vsync_history[sample_index];
        tap_stable_q <= selected_data_stable;
    end

    always @(posedge clk_300m) begin
        if (!resetn) begin
            recovered_history <= {(DATA_HISTORY_DEPTH-1){1'b0}};
            tap_ce_q <= 1'b0;
        end else begin
            recovered_history <= {recovered_history,
                                  recovered_edge | recovered_deadline_edge_q};
            tap_ce_q <= recovered_history[DATA_HISTORY_DEPTH-2];
        end
    end

    dvp_pclk_telemetry u_telemetry (
        .clk(clk_300m), .resetn(resetn), .diag_clear(diag_clear),
        .candidate_event(diag_candidate_event),
        .valid_event(diag_valid_event),
        .glitch_event(diag_glitch_event),
        .missing_event(diag_missing_event),
        .holdover_event(diag_holdover_event),
        .holdover_recovered_event(diag_holdover_recovered_event),
        .harmonic_reject_event(diag_harmonic_reject_event),
        .lock_loss_event(diag_lock_loss_event),
        .period_range_fault_event(diag_period_range_fault_event),
        .half_period_event(diag_half_period_event),
        .too_early_event(diag_too_early_event),
        .too_late_event(diag_too_late_event),
        .invalid_interval_event(diag_invalid_interval_event),
        .short_high_event(diag_short_high_event),
        .short_low_event(diag_short_low_event),
        .phase_event(diag_phase_event),
        .phase_value({{(24-FP_WIDTH){1'b0}}, diag_phase_value}),
        .interval_event(diag_interval_event),
        .interval_value(diag_interval_value),
        .loss_snapshot_event(loss_snapshot_event),
        .loss_snapshot_reason(loss_snapshot_reason),
        .loss_snapshot_period(loss_snapshot_period),
        .loss_snapshot_candidate_period(loss_snapshot_candidate_period),
        .loss_snapshot_phase_error(loss_snapshot_phase_error),
        .loss_snapshot_interval(loss_snapshot_interval),
        .pixel_ce(pixel_ce), .selected_data_stable(tap_stable_q),
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
        .short_low_count(short_low_count),
        .period_range_fault_count(period_range_fault_count),
        .half_period_candidate_count(half_period_candidate_count),
        .too_early_count(too_early_count),
        .too_late_count(too_late_count),
        .invalid_interval_count(invalid_interval_count),
        .data_stable_count(data_stable_count),
        .candidate_count64(candidate_count64),
        .valid_count64(valid_count64),
        .pixel_ce_count64(pixel_ce_count64),
        .last_loss_reason(last_loss_reason),
        .period_at_loss(period_at_loss),
        .candidate_period_at_loss(candidate_period_at_loss),
        .phase_error_at_loss(phase_error_at_loss),
        .interval_at_loss(interval_at_loss)
    );
endmodule
