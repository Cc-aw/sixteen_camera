`timescale 1ns/1ps

module ov7670_frontend #(
    parameter integer SENSOR_WIDTH = 640,
    parameter integer SENSOR_HEIGHT = 480,
    parameter integer FRAME_WIDTH = 1920,
    parameter integer FRAME_HEIGHT = 1080,
    parameter integer LEFT_MARGIN = 640,
    parameter integer TOP_MARGIN = 300,
    parameter integer VSYNC_FILTER_CYCLES = 256,
    parameter integer HREF_FILTER_CYCLES = 16,
    parameter integer MIN_FRAME_LINES = 470,
    parameter integer MIN_FRAME_INTERVAL_CYCLES = 200000,
    parameter integer FRAME_RESYNC_TIMEOUT_CYCLES = 2000000
) (
    input wire sys_rstn,
    input wire ov7670_ctrl_clk,
    input wire init_grant,
    output wire init_request,
    output wire init_terminal,
    input wire video_clk,
    input wire video_resetn,
    axi_lite_if.slave camera_axil,

    input wire ov7670_pclk,
    input wire ov7670_vsync,
    input wire ov7670_href,
    input wire [7:0] ov7670_data,
    output wire cam_scl,
    inout wire cam_sda,
    output wire cam_xclk,
    output wire cam_reset_n,
    output wire cam_pwdn,
    output wire event_valid,
    input wire event_ready,
    output reg diag_clear_toggle,
    output wire [7:0] event_data,
    output wire event_byte_valid,
    output wire event_line_start,
    output wire event_line_last,
    output wire event_line_end,
    output wire event_frame_boundary,
    output wire event_fault,
    output wire pixel_resetn,
    output wire pixel_enable
);
    reg [31:0] input_frame_count = 32'd0;
    reg [31:0] input_overflow_count = 32'd0;
    reg [15:0] current_line_bytes = 16'd0;
    reg [15:0] last_line_bytes = 16'd0;
    reg [15:0] current_frame_lines = 16'd0;
    reg [15:0] last_frame_lines = 16'd0;
    reg [31:0] geometry_snapshot_pclk = 32'd0;
    reg diag_vsync_d = 1'b0;
    reg diag_href_d = 1'b0;
    reg [HREF_FILTER_CYCLES*8-1:0] href_data_pipe =
        {HREF_FILTER_CYCLES*8{1'b0}};
    wire [7:0] dvp_data_pipe;
    wire       dvp_href_pipe;
    wire       dvp_vsync_pipe;
    wire       dvp_pclk_pipe;

    wire pixel_ce;
    wire [7:0] recovered_data;
    wire recovered_href;
    wire recovered_vsync;
    wire pclk_recovery_locked;
    wire [1:0] pclk_recovery_state;
    wire [23:0] pclk_period_est_fp;
    wire [31:0] pclk_lock_loss_count;
    wire pclk_loss_event;
    // Board-qualified sampling tap. Keep this fixed at tap 2; runtime tap
    // switching is intentionally disabled to remove a high-fanout 300 MHz
    // control path from the PCLK recovery datapath.
    localparam logic [2:0] FIXED_SAMPLE_OFFSET = 3'd2;
    // VSYNC is a frame-rate signal, so a valid level persists for many PCLK
    // cycles. Counter-based hysteresis allows a substantially stronger filter
    // without building a wide reduction tree in every camera channel.
    localparam integer VSYNC_RUN_WIDTH =
        (VSYNC_FILTER_CYCLES <= 2) ? 1 : $clog2(VSYNC_FILTER_CYCLES);
    reg [VSYNC_RUN_WIDTH-1:0] vsync_high_run = {VSYNC_RUN_WIDTH{1'b0}};
    reg [VSYNC_RUN_WIDTH-1:0] vsync_low_run = {VSYNC_RUN_WIDTH{1'b0}};
    reg vsync_filtered = 1'b0;
    reg vsync_filter_d = 1'b0;
    reg vsync_qualified = 1'b0;
    reg frame_sync_seen = 1'b0;
    reg [15:0] qualified_lines_since_frame = 16'd0;
    reg [31:0] frame_interval_cycles = 32'd0;
    (* ASYNC_REG = "TRUE", SHREG_EXTRACT = "NO" *)
    reg diag_clear_video_sync1 = 1'b0;
    (* ASYNC_REG = "TRUE", SHREG_EXTRACT = "NO" *)
    reg diag_clear_video_sync2 = 1'b0;
    reg diag_clear_video_seen = 1'b0;
    localparam integer HREF_RUN_WIDTH =
        (HREF_FILTER_CYCLES <= 2) ? 1 : $clog2(HREF_FILTER_CYCLES);
    reg [HREF_RUN_WIDTH-1:0] href_high_run = {HREF_RUN_WIDTH{1'b0}};
    reg [HREF_RUN_WIDTH-1:0] href_low_run = {HREF_RUN_WIDTH{1'b0}};
    reg href_filtered = 1'b0;
    wire href_guard_byte_accept;
    wire href_guard_line_start;
    wire href_guard_last_byte;
    wire href_guard_line_end;

    initial begin
        if (SENSOR_WIDTH != 640 || SENSOR_HEIGHT != 480 ||
            FRAME_WIDTH != 1920 || FRAME_HEIGHT != 1080 ||
            LEFT_MARGIN != 640 || TOP_MARGIN != 300 ||
            VSYNC_FILTER_CYCLES < 2 || VSYNC_FILTER_CYCLES > 1024 ||
            HREF_FILTER_CYCLES < 2 || HREF_FILTER_CYCLES > 32 ||
            MIN_FRAME_LINES < 1 || MIN_FRAME_LINES > SENSOR_HEIGHT ||
            MIN_FRAME_INTERVAL_CYCLES < 1 ||
            FRAME_RESYNC_TIMEOUT_CYCLES <= MIN_FRAME_INTERVAL_CYCLES)
            $error("ov7670_frontend parameters must describe 640x480 in 1920x1080");
    end

    wire hw_scl;
    wire hw_xclk;
    wire hw_reset_n;
    wire hw_pwdn;
    wire hw_sda_o;
    wire hw_sda_t;
    wire hw_sda_in;
    wire hw_init_done;
    wire hw_init_failed;
    wire hw_capture_enable;
    wire [415:0] ctrl_diag_24m;
    reg [6:1] control_bits;
    reg reinit_toggle;
    wire [3:0] control_24m;
    wire control_write_pulse;
    wire [15:0] control_write_word;
    wire [31:0] control_write_data;
    wire [3:0] control_write_strb;
    (* ASYNC_REG = "TRUE", SHREG_EXTRACT = "NO" *)
    reg capture_enable_sync1 = 1'b0;
    (* ASYNC_REG = "TRUE", SHREG_EXTRACT = "NO" *)
    reg capture_enable_sync2 = 1'b0;

    xpm_cdc_array_single #(
        .DEST_SYNC_FF(2), .INIT_SYNC_FF(0), .SIM_ASSERT_CHK(0),
        .SRC_INPUT_REG(1), .WIDTH(4)
    ) u_control_cdc (
        .src_clk(camera_axil.aclk),
        .src_in({reinit_toggle, control_bits[3:1]}),
        .dest_clk(ov7670_ctrl_clk), .dest_out(control_24m)
    );

    ov7670_ztachip_ctrl u_ov7670_ctrl (
        .clk_24m(ov7670_ctrl_clk), .sys_rstn(sys_rstn),
        .sda_in(hw_sda_in),
        .reinit_toggle(control_24m[3]),
        .init_grant(init_grant),
        .xclk_disable(control_24m[0]),
        .force_reset(control_24m[1]), .force_pwdn(control_24m[2]),
        .xclk_12m(hw_xclk), .reset_n(hw_reset_n), .pwdn(hw_pwdn),
        .scl(hw_scl), .sda_o(hw_sda_o), .sda_t(hw_sda_t),
        .done(hw_init_done), .failed(hw_init_failed),
        .init_request(init_request), .init_terminal(init_terminal),
        .capture_enable(hw_capture_enable),
        .diag(ctrl_diag_24m)
    );
    wire normal_scl = control_bits[4] ? control_bits[5] : hw_scl;
    assign cam_xclk = hw_xclk;
    assign cam_reset_n = hw_reset_n;
    assign cam_pwdn = hw_pwdn;
    assign cam_scl = normal_scl;
    IOBUF u_ov7670_sda_iobuf (
        .I(control_bits[4] ? 1'b0 : hw_sda_o), .O(hw_sda_in),
        .T(control_bits[4] ? control_bits[6] : hw_sda_t),
        .IO(cam_sda)
    );

    always @(posedge camera_axil.aclk) begin
        if (!camera_axil.aresetn) begin
            control_bits <= 6'd0;
            reinit_toggle <= 1'b0;
            diag_clear_toggle <= 1'b0;
        end else begin
            if (control_write_pulse && control_write_word == 16'd1 &&
                control_write_strb[0]) begin
                control_bits <= control_write_data[6:1];
                if (control_write_data[0])
                    reinit_toggle <= !reinit_toggle;
                if (control_write_data[7])
                    diag_clear_toggle <= !diag_clear_toggle;
            end
        end
    end

    wire [31:0] ctrl_status0_axil;
    wire [31:0] ctrl_status1_axil;
    wire [31:0] capture_status0_axil;
    wire [31:0] capture_frame_count_axil;
    wire [31:0] capture_overflow_count_axil;
    wire [31:0] capture_lock_loss_count_axil;
    wire [31:0] capture_geometry_axil;

    camera_telemetry u_camera_telemetry (
        .ctrl_clk(ov7670_ctrl_clk), .ctrl_resetn(sys_rstn),
        .ctrl_status0_src(ctrl_diag_24m[31:0]),
        .ctrl_status1_src(ctrl_diag_24m[415:384]),
        .capture_clk(video_clk), .capture_resetn(video_resetn),
        .capture_enable(capture_enable_sync2),
        .pclk_locked(pclk_recovery_locked),
        .pclk_state(pclk_recovery_state),
        .pclk_period(pclk_period_est_fp),
        .frame_count(input_frame_count),
        .overflow_count(input_overflow_count),
        .lock_loss_count(pclk_lock_loss_count),
        .geometry(geometry_snapshot_pclk),
        .axil_clk(camera_axil.aclk), .axil_resetn(camera_axil.aresetn),
        .ctrl_status0(ctrl_status0_axil),
        .ctrl_status1(ctrl_status1_axil),
        .capture_status0(capture_status0_axil),
        .capture_frame_count(capture_frame_count_axil),
        .capture_overflow_count(capture_overflow_count_axil),
        .capture_lock_loss_count(capture_lock_loss_count_axil),
        .capture_geometry(capture_geometry_axil)
    );

    wire [8*32-1:0] diagnostic_words;
    assign diagnostic_words[0*32 +: 32] = ctrl_status0_axil;
    assign diagnostic_words[1*32 +: 32] = {25'd0, control_bits, 1'b0};
    assign diagnostic_words[2*32 +: 32] = capture_status0_axil;
    assign diagnostic_words[3*32 +: 32] = capture_frame_count_axil;
    assign diagnostic_words[4*32 +: 32] = capture_overflow_count_axil;
    assign diagnostic_words[5*32 +: 32] = capture_geometry_axil;
    assign diagnostic_words[6*32 +: 32] = capture_lock_loss_count_axil;
    assign diagnostic_words[7*32 +: 32] = ctrl_status1_axil;
    ov7670_axil_regs #(.WORDS(8)) u_diagnostics (
        .axil(camera_axil), .read_words(diagnostic_words),
        .write_pulse(control_write_pulse),
        .write_word(control_write_word), .write_data(control_write_data),
        .write_strb(control_write_strb)
    );
    // Synchronize the controller's enable into the 300 MHz capture domain.
    // The IOB input flops intentionally have no reset so reset routing cannot
    // prevent packing at the pins.
    // video_resetn is already asserted until DDR calibration completes and
    // is synchronously released in video_clk before it reaches this channel.
    // Do not re-combine the raw system/calibration status here: doing so
    // creates a high-fanout 300 MHz data/CE path across SLRs.  Camera capture
    // remains disabled until the SCCB controller reports initialization OK.
    wire capture_resetn = video_resetn && capture_enable_sync2;

    dvp_input_sampler u_input_sampler (
        .capture_clk(video_clk),
        .dvp_pclk(ov7670_pclk), .dvp_vsync(ov7670_vsync),
        .dvp_href(ov7670_href), .dvp_data(ov7670_data),
        .sampled_pclk(dvp_pclk_pipe),
        .sampled_vsync(dvp_vsync_pipe),
        .sampled_href(dvp_href_pipe),
        .sampled_data(dvp_data_pipe)
    );

    always @(posedge video_clk) begin
        if (!video_resetn) begin
            capture_enable_sync1 <= 1'b0;
            capture_enable_sync2 <= 1'b0;
        end else begin
            capture_enable_sync1 <= hw_capture_enable;
            capture_enable_sync2 <= capture_enable_sync1;
        end
    end

    wire diag_clear_video =
        (diag_clear_video_sync2 != diag_clear_video_seen);

    // Diagnostic clear is the only control crossing into the recovery clock
    // domain.  Camera enable is already synchronized above.
    always @(posedge video_clk) begin
        if (!video_resetn) begin
            diag_clear_video_sync1 <= 1'b0;
            diag_clear_video_sync2 <= 1'b0;
            diag_clear_video_seen <= 1'b0;
        end else begin
            diag_clear_video_sync1 <= diag_clear_toggle;
            diag_clear_video_sync2 <= diag_clear_video_sync1;
            if (diag_clear_video) begin
                diag_clear_video_seen <= diag_clear_video_sync2;
            end
        end
    end

    dvp_pclk_recovery #(
        .PERIOD_FRAC_BITS(8),
        .NOMINAL_PERIOD_FP(3200),
        .HIGH_CONFIRM(2), .LOW_CONFIRM(2),
        .DEAD_TIME_SAMPLES(8),
        // All configured cameras are 24 MHz.  Excluding 25 samples prevents
        // a distorted input from locking to the divide-by-two harmonic.
        .SEARCH_MIN_PERIOD(8), .SEARCH_MAX_PERIOD(18),
        .SEARCH_VALID_EDGES(8), .ACQUIRE_EDGES(8),
        .ACQUIRE_WINDOW(4), .LOCK_WINDOW(2), .RECOVERY_WINDOW(4),
        .MAX_HOLDOVER(1),
        .PERIOD_IIR_SHIFT(3),
        .DATA_HISTORY_DEPTH(6), .DEFAULT_DATA_SAMPLE_OFFSET(2)
    ) u_pclk_recovery (
        .clk_300m(video_clk), .resetn(capture_resetn),
        .diag_clear(diag_clear_video),
        .frame_boundary(pixel_ce && vsync_qualified && !diag_vsync_d),
        .pclk_sample(dvp_pclk_pipe), .data_sample(dvp_data_pipe),
        .href_sample(dvp_href_pipe), .vsync_sample(dvp_vsync_pipe),
        .data_sample_offset(FIXED_SAMPLE_OFFSET),
        .pixel_ce(pixel_ce), .pixel_data(recovered_data),
        .pixel_href(recovered_href), .pixel_vsync(recovered_vsync),
        .pclk_locked(pclk_recovery_locked),
        .recovery_state(pclk_recovery_state),
        .period_est_fp(pclk_period_est_fp),
        .last_interval(), .interval_min(), .interval_max(),
        .phase_error_fp(), .phase_error_max_fp(),
        .candidate_count(), .valid_count(), .glitch_count(),
        .missing_count(), .holdover_count(), .holdover_recovered_count(),
        .harmonic_reject_count(),
        .lock_loss_count(pclk_lock_loss_count),
        .data_unstable_count(), .short_high_count(), .short_low_count(),
        .candidate_period_est_fp(), .raw_candidate_interval(),
        .period_range_fault_count(), .half_period_candidate_count(),
        .too_early_count(), .too_late_count(), .invalid_interval_count(),
        .lock_score(), .recovery_confirm_count(), .last_loss_reason(),
        .data_stable_count(), .candidate_count64(), .valid_count64(),
        .pixel_ce_count64(),
        .loss_event(pclk_loss_event),
        .period_at_loss(), .candidate_period_at_loss(),
        .phase_error_at_loss(), .interval_at_loss()
    );

    always @(posedge video_clk) begin
        if (!capture_resetn) begin
            vsync_high_run <= {VSYNC_RUN_WIDTH{1'b0}};
            vsync_low_run <= {VSYNC_RUN_WIDTH{1'b0}};
            vsync_filtered <= 1'b0;
        end else if (pixel_ce) begin
            if (recovered_vsync) begin
                vsync_low_run <= {VSYNC_RUN_WIDTH{1'b0}};
                if (!vsync_filtered) begin
                    if (vsync_high_run ==
                        VSYNC_RUN_WIDTH'(VSYNC_FILTER_CYCLES-1)) begin
                        vsync_filtered <= 1'b1;
                        vsync_high_run <= {VSYNC_RUN_WIDTH{1'b0}};
                    end else begin
                        vsync_high_run <= vsync_high_run + 1'b1;
                    end
                end
            end else begin
                vsync_high_run <= {VSYNC_RUN_WIDTH{1'b0}};
                if (vsync_filtered) begin
                    if (vsync_low_run ==
                        VSYNC_RUN_WIDTH'(VSYNC_FILTER_CYCLES-1)) begin
                        vsync_filtered <= 1'b0;
                        vsync_low_run <= {VSYNC_RUN_WIDTH{1'b0}};
                    end else begin
                        vsync_low_run <= vsync_low_run + 1'b1;
                    end
                end
            end
        end
    end

    // A long VSYNC glitch can pass the level filter.  Do not let it reset an
    // active frame unless enough real lines and time have elapsed.  The long
    // timeout is an escape hatch for a camera that lost HREF completely.
    wire href_qualified_rise = href_filtered && !diag_href_d;
    wire vsync_filtered_rise = vsync_filtered && !vsync_filter_d;
    wire frame_sync_eligible = !frame_sync_seen ||
        ((qualified_lines_since_frame >= MIN_FRAME_LINES) &&
         (frame_interval_cycles >= MIN_FRAME_INTERVAL_CYCLES)) ||
        (frame_interval_cycles >= FRAME_RESYNC_TIMEOUT_CYCLES);
    wire force_frame_resync = frame_sync_seen && vsync_filtered &&
        !vsync_qualified &&
        (frame_interval_cycles >= FRAME_RESYNC_TIMEOUT_CYCLES);
    always @(posedge video_clk) begin
        if (!capture_resetn) begin
            vsync_filter_d <= 1'b0;
            vsync_qualified <= 1'b0;
            frame_sync_seen <= 1'b0;
            qualified_lines_since_frame <= 16'd0;
            frame_interval_cycles <= 32'd0;
        end else begin
            if (pixel_ce) begin
                vsync_filter_d <= vsync_filtered;
                if (!vsync_filtered)
                    vsync_qualified <= 1'b0;
                if (frame_interval_cycles != 32'hffffffff)
                    frame_interval_cycles <= frame_interval_cycles + 1'b1;
                if (href_qualified_rise &&
                    qualified_lines_since_frame != 16'hffff)
                    qualified_lines_since_frame <=
                        qualified_lines_since_frame + 1'b1;
                if (vsync_filtered_rise || force_frame_resync) begin
                    if (frame_sync_eligible) begin
                        vsync_qualified <= 1'b1;
                        frame_sync_seen <= 1'b1;
                        qualified_lines_since_frame <= 16'd0;
                        frame_interval_cycles <= 32'd0;
                    end
                end
            end
        end
    end

    // Qualify HREF symmetrically.  The parameterized decision latency is
    // matched by the data pipeline below, so the first and last
    // pixels of a qualified line remain aligned with their HREF level.
    always @(posedge video_clk) begin
        if (!capture_resetn) begin
            href_high_run <= {HREF_RUN_WIDTH{1'b0}};
            href_low_run <= {HREF_RUN_WIDTH{1'b0}};
            href_filtered <= 1'b0;
            href_data_pipe <= {HREF_FILTER_CYCLES*8{1'b0}};
        end else if (pixel_ce) begin
            href_data_pipe <= {
                href_data_pipe[HREF_FILTER_CYCLES*8-9:0], recovered_data};
            if (recovered_href) begin
                href_low_run <= {HREF_RUN_WIDTH{1'b0}};
                if (!href_filtered) begin
                    if (href_high_run ==
                        HREF_RUN_WIDTH'(HREF_FILTER_CYCLES-1)) begin
                        href_filtered <= 1'b1;
                        href_high_run <= {HREF_RUN_WIDTH{1'b0}};
                    end else begin
                        href_high_run <= href_high_run + 1'b1;
                    end
                end
            end else begin
                href_high_run <= {HREF_RUN_WIDTH{1'b0}};
                if (href_filtered) begin
                    if (href_low_run ==
                        HREF_RUN_WIDTH'(HREF_FILTER_CYCLES-1)) begin
                        href_filtered <= 1'b0;
                        href_low_run <= {HREF_RUN_WIDTH{1'b0}};
                    end else begin
                        href_low_run <= href_low_run + 1'b1;
                    end
                end
            end
        end
    end

    wire [7:0] href_aligned_data =
        href_data_pipe[HREF_FILTER_CYCLES*8-1 -: 8];

    dvp_href_line_guard #(
        .LINE_BYTES(SENSOR_WIDTH * 2),
        .HOLDOVER_CYCLES(32)
    ) u_href_line_guard (
        .clk(video_clk), .resetn(capture_resetn), .pixel_ce(pixel_ce),
        .frame_boundary(vsync_qualified), .href(href_filtered),
        .diag_clear(diag_clear_video),
        .byte_accept(href_guard_byte_accept),
        .line_start(href_guard_line_start),
        .line_last_byte(href_guard_last_byte),
        .line_end(href_guard_line_end),
        .diag_gap_recovered_count(), .diag_flush_count(),
        .diag_gap_last(), .diag_gap_max(), .diag_flush_position(),
        .active(), .discarding()
    );

    // Ordered recovery events are the only payload leaving the 300 MHz
    // capture domain. RGB565 assembly is intentionally deferred until after
    // the P3 event CDC. The source is physical and cannot be backpressured;
    // event_ready is telemetry for an explicit overflow/resync decision.
    assign pixel_resetn = video_resetn;
    assign pixel_enable = capture_enable_sync2;
    assign event_data = href_aligned_data;
    assign event_byte_valid = href_guard_byte_accept;
    assign event_line_start = href_guard_line_start;
    assign event_line_last = href_guard_last_byte;
    assign event_line_end = href_guard_line_end;
    assign event_frame_boundary = pixel_ce && vsync_qualified &&
                                  !diag_vsync_d;
    assign event_fault = pclk_loss_event;
    assign event_valid = capture_enable_sync2 &&
                         (event_byte_valid || event_line_end ||
                          event_frame_boundary || event_fault);

    always @(posedge video_clk) begin
        if (!capture_resetn) begin
            input_frame_count <= 32'd0;
            input_overflow_count <= 32'd0;
            current_line_bytes <= 16'd0;
            last_line_bytes <= 16'd0;
            current_frame_lines <= 16'd0;
            last_frame_lines <= 16'd0;
            diag_vsync_d <= 1'b0;
            diag_href_d <= 1'b0;
        end else begin
            if (event_valid && !event_ready)
                input_overflow_count <= input_overflow_count + 1'b1;
            if (pixel_ce) begin
                diag_vsync_d <= vsync_qualified;
                diag_href_d <= href_filtered;

                if (vsync_qualified && !diag_vsync_d) begin
                    input_frame_count <= input_frame_count + 1'b1;
                    last_frame_lines <= current_frame_lines;
                    current_frame_lines <= 16'd0;
                end else if (href_filtered && !diag_href_d) begin
                    current_frame_lines <= current_frame_lines + 1'b1;
                end
                if (!href_filtered && diag_href_d)
                    last_line_bytes <= current_line_bytes;
                if (href_filtered) begin
                    if (!diag_href_d)
                        current_line_bytes <= 16'd1;
                    else
                        current_line_bytes <= current_line_bytes + 1'b1;
                end
            end
        end
    end

    // Publish one atomic geometry value per frame. Both fields below are
    // complete values from the just-finished frame and remain unchanged until
    // the next filtered VSYNC boundary.
    always @(posedge video_clk) begin
        if (!capture_resetn) begin
            geometry_snapshot_pclk <= 32'd0;
        end else if (pixel_ce && vsync_qualified && !diag_vsync_d) begin
            geometry_snapshot_pclk <= {current_frame_lines, last_line_bytes};
        end
    end

    wire unused = &{1'b0, FRAME_WIDTH, FRAME_HEIGHT, LEFT_MARGIN,
                    TOP_MARGIN, video_clk};
endmodule
