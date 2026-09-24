`timescale 1ns/1ps

// Diagnostic state is a sink of registered recovery events. It never controls
// edge acceptance or the recovered byte stream.
module dvp_pclk_telemetry (
    input wire clk, resetn, diag_clear,
    input wire candidate_event, valid_event, glitch_event, missing_event,
    input wire holdover_event, holdover_recovered_event,
    input wire harmonic_reject_event, lock_loss_event,
    input wire period_range_fault_event, half_period_event,
    input wire too_early_event, too_late_event, invalid_interval_event,
    input wire short_high_event, short_low_event,
    input wire phase_event, input wire [23:0] phase_value,
    input wire interval_event, input wire [15:0] interval_value,
    input wire loss_snapshot_event,
    input wire [3:0] loss_snapshot_reason,
    input wire [23:0] loss_snapshot_period,
    input wire [23:0] loss_snapshot_candidate_period,
    input wire [23:0] loss_snapshot_phase_error,
    input wire [15:0] loss_snapshot_interval,
    input wire pixel_ce, selected_data_stable,
    output reg [15:0] interval_min, interval_max,
    output reg [23:0] phase_error_fp, phase_error_max_fp,
    output reg [31:0] candidate_count, valid_count, glitch_count,
    output reg [31:0] missing_count, holdover_count,
    output reg [31:0] holdover_recovered_count, harmonic_reject_count,
    output reg [31:0] lock_loss_count, data_unstable_count,
    output reg [15:0] short_high_count, short_low_count,
    output reg [31:0] period_range_fault_count,
    output reg [31:0] half_period_candidate_count,
    output reg [31:0] too_early_count, too_late_count,
    output reg [31:0] invalid_interval_count, data_stable_count,
    output reg [63:0] candidate_count64, valid_count64, pixel_ce_count64,
    output reg [3:0] last_loss_reason,
    output reg [23:0] period_at_loss, candidate_period_at_loss,
    output reg [23:0] phase_error_at_loss,
    output reg [15:0] interval_at_loss
);
    always @(posedge clk) begin
        if (!resetn || diag_clear) begin
            last_loss_reason <= 4'd0;
            period_at_loss <= 24'd0;
            candidate_period_at_loss <= 24'd0;
            phase_error_at_loss <= 24'd0;
            interval_at_loss <= 16'd0;
            candidate_count <= 32'd0;
            valid_count <= 32'd0;
            candidate_count64 <= 64'd0;
            valid_count64 <= 64'd0;
            glitch_count <= 32'd0;
            missing_count <= 32'd0;
            holdover_count <= 32'd0;
            holdover_recovered_count <= 32'd0;
            harmonic_reject_count <= 32'd0;
            lock_loss_count <= 32'd0;
            period_range_fault_count <= 32'd0;
            half_period_candidate_count <= 32'd0;
            too_early_count <= 32'd0;
            too_late_count <= 32'd0;
            invalid_interval_count <= 32'd0;
            phase_error_fp <= 24'd0;
            phase_error_max_fp <= 24'd0;
            interval_min <= 16'hffff;
            interval_max <= 16'd0;
            short_high_count <= 16'd0;
            short_low_count <= 16'd0;
        end else begin
            if (loss_snapshot_event) begin
                last_loss_reason <= loss_snapshot_reason;
                period_at_loss <= loss_snapshot_period;
                candidate_period_at_loss <= loss_snapshot_candidate_period;
                phase_error_at_loss <= loss_snapshot_phase_error;
                interval_at_loss <= loss_snapshot_interval;
            end
            if (candidate_event) begin
                if (candidate_count != 32'hffff_ffff)
                    candidate_count <= candidate_count + 1'b1;
                candidate_count64 <= candidate_count64 + 1'b1;
            end
            if (valid_event) begin
                if (valid_count != 32'hffff_ffff)
                    valid_count <= valid_count + 1'b1;
                valid_count64 <= valid_count64 + 1'b1;
            end
            if (glitch_event && glitch_count != 32'hffff_ffff)
                glitch_count <= glitch_count + 1'b1;
            if (missing_event && missing_count != 32'hffff_ffff)
                missing_count <= missing_count + 1'b1;
            if (holdover_event && holdover_count != 32'hffff_ffff)
                holdover_count <= holdover_count + 1'b1;
            if (holdover_recovered_event &&
                holdover_recovered_count != 32'hffff_ffff)
                holdover_recovered_count <= holdover_recovered_count + 1'b1;
            if (harmonic_reject_event &&
                harmonic_reject_count != 32'hffff_ffff)
                harmonic_reject_count <= harmonic_reject_count + 1'b1;
            if (lock_loss_event && lock_loss_count != 32'hffff_ffff)
                lock_loss_count <= lock_loss_count + 1'b1;
            if (period_range_fault_event &&
                period_range_fault_count != 32'hffff_ffff)
                period_range_fault_count <= period_range_fault_count + 1'b1;
            if (half_period_event &&
                half_period_candidate_count != 32'hffff_ffff)
                half_period_candidate_count <= half_period_candidate_count + 1'b1;
            if (too_early_event && too_early_count != 32'hffff_ffff)
                too_early_count <= too_early_count + 1'b1;
            if (too_late_event && too_late_count != 32'hffff_ffff)
                too_late_count <= too_late_count + 1'b1;
            if (invalid_interval_event &&
                invalid_interval_count != 32'hffff_ffff)
                invalid_interval_count <= invalid_interval_count + 1'b1;
            if (short_high_event && short_high_count != 16'hffff)
                short_high_count <= short_high_count + 1'b1;
            if (short_low_event && short_low_count != 16'hffff)
                short_low_count <= short_low_count + 1'b1;
            if (phase_event) begin
                phase_error_fp <= phase_value;
                if (phase_value > phase_error_max_fp)
                    phase_error_max_fp <= phase_value;
            end
            if (interval_event) begin
                if (interval_value < interval_min)
                    interval_min <= interval_value;
                if (interval_value > interval_max)
                    interval_max <= interval_value;
            end
        end
    end

    always @(posedge clk) begin
        if (!resetn || diag_clear) begin
            data_unstable_count <= 32'd0;
            data_stable_count <= 32'd0;
            pixel_ce_count64 <= 64'd0;
        end else if (pixel_ce) begin
            pixel_ce_count64 <= pixel_ce_count64 + 1'b1;
            if (selected_data_stable) begin
                if (data_stable_count != 32'hffff_ffff)
                    data_stable_count <= data_stable_count + 1'b1;
            end else if (data_unstable_count != 32'hffff_ffff) begin
                data_unstable_count <= data_unstable_count + 1'b1;
            end
        end
    end
endmodule
