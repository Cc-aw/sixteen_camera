`timescale 1ns/1ps

// Cycle-equivalent SystemVerilog translation of demo/ztachip camera.vhd's
// OV7670 clock, reset and SCCB section.  State is initialized by FPGA
// configuration, just as the VHDL declaration initializers are.
module ov7670_ztachip_ctrl #(
    parameter integer XCLK_TO_PWDN_CYCLES = 120000,
    parameter integer PWDN_TO_RESET_CYCLES = 120000,
    parameter integer RESET_TO_SCCB_CYCLES = 240000,
    parameter integer POST_RESET_WAIT_CYCLES = 240000,
    parameter integer RETRY_WAIT_CYCLES = 2400,
    parameter integer MAX_RETRIES = 3
) (
    input  wire        clk_24m,
    input  wire        sys_rstn,
    input  wire        sda_in,
    input  wire        reinit_toggle,
    input  wire        init_grant,
    input  wire        xclk_disable,
    input  wire        force_reset,
    input  wire        force_pwdn,
    output wire        xclk_12m,
    output wire        reset_n,
    output wire        pwdn,
    output wire        scl,
    output wire        sda_o,
    output wire        sda_t,
    output wire        done,
    output wire        failed,
    output wire        init_request,
    output wire        init_terminal,
    output wire        capture_enable,
    output wire [415:0] diag
);
    reg sys_clk = 1'b0;
    reg finished = 1'b0;
    reg taken = 1'b0;
    reg [7:0] divider = 8'h01;
    reg [31:0] busy_sr = 32'd0;
    reg [31:0] data_sr = 32'hffffffff;
    reg [15:0] sreg;
    reg [7:0] address = 8'd0;
    localparam [1:0] START_XCLK_ONLY = 2'd0;
    localparam [1:0] START_PWDN_RELEASED = 2'd1;
    localparam [1:0] START_RESET_RELEASED = 2'd2;
    localparam [1:0] START_SCCB_READY = 2'd3;

    reg [1:0] startup_state = START_XCLK_ONLY;
    reg [17:0] startup_wait = 18'd0;
    reg [17:0] post_reset_wait = 18'd0;
    reg [11:0] retry_wait = 12'd0;
    reg ready = 1'b0;
    reg scl_r = 1'b1;
    reg reinit_seen = 1'b0;
    reg init_request_r = 1'b1;
    reg running = 1'b0;
    reg channel_started = 1'b0;
    reg failed_r = 1'b0;
    reg transaction_nack = 1'b0;
    reg [1:0] transaction_first_nack_phase = 2'd0;
    reg [1:0] retry_count = 2'd0;
    reg [1:0] failed_phase = 2'd0;
    reg [1:0] failed_attempt = 2'd0;
    reg [7:0] failed_index = 8'd0;
    reg [7:0] failed_register = 8'd0;
    reg [7:0] failed_value = 8'd0;
    reg [31:0] successful_write_count = 32'd0;
    reg [31:0] retry_total_count = 32'd0;
    reg [31:0] nack_id_count = 32'd0;
    reg [31:0] nack_register_count = 32'd0;
    reg [31:0] nack_data_count = 32'd0;

    initial begin
        if (XCLK_TO_PWDN_CYCLES < 1 || XCLK_TO_PWDN_CYCLES > 262143 ||
            PWDN_TO_RESET_CYCLES < 1 || PWDN_TO_RESET_CYCLES > 262143 ||
            RESET_TO_SCCB_CYCLES < 1 || RESET_TO_SCCB_CYCLES > 262143 ||
            POST_RESET_WAIT_CYCLES < 1 ||
            POST_RESET_WAIT_CYCLES > 262143)
            $error("OV7670 startup delays must fit the 18-bit counters");
    end

    // Passive diagnostics for the write-only IIC initialization path.
    reg [31:0] ctrl_cycle_count = 32'd0;
    reg [7:0] ack_count = 8'd0;
    reg [7:0] nack_count = 8'd0;
    reg [7:0] ack_sample_count = 8'd0;
    reg first_nack_valid = 1'b0;
    reg [1:0] first_nack_phase = 2'd0;
    reg [7:0] first_nack_write = 8'd0;

    function automatic [15:0] register_value(input [7:0] index);
        begin
            case (index)
                8'h00: register_value = 16'h1280;
                // Full VGA RGB565/AWB/AEC/gamma sequence from
                // doc/OV7670_VGA_RGB565_*.md.  The final entries select the
                // standard RGB565 packing and color matrix.
                // XCLK is 12 MHz; bypass CLKRC prescaling to obtain the same
                // internal clock used by the 24 MHz/CLKRC=1 VGA 30 fps setup.
                8'h01: register_value = 16'h1100;
                8'h02: register_value = 16'h3a04;
                8'h03: register_value = 16'h1200;
                8'h04: register_value = 16'h1713;
                8'h05: register_value = 16'h1801;
                8'h06: register_value = 16'h32b6;
                8'h07: register_value = 16'h1902;
                8'h08: register_value = 16'h1a7a;
                8'h09: register_value = 16'h030a;
                8'h0a: register_value = 16'h0c00;
                8'h0b: register_value = 16'h3e00;
                8'h0c: register_value = 16'h703a;
                8'h0d: register_value = 16'h7135;
                8'h0e: register_value = 16'h7211;
                8'h0f: register_value = 16'h73f0;
                8'h10: register_value = 16'ha202;
                8'h11: register_value = 16'h1500;
                8'h12: register_value = 16'h7a20;
                8'h13: register_value = 16'h7b10;
                8'h14: register_value = 16'h7c1e;
                8'h15: register_value = 16'h7d35;
                8'h16: register_value = 16'h7e5a;
                8'h17: register_value = 16'h7f69;
                8'h18: register_value = 16'h8076;
                8'h19: register_value = 16'h8180;
                8'h1a: register_value = 16'h8288;
                8'h1b: register_value = 16'h838f;
                8'h1c: register_value = 16'h8496;
                8'h1d: register_value = 16'h85a3;
                8'h1e: register_value = 16'h86af;
                8'h1f: register_value = 16'h87c4;
                8'h20: register_value = 16'h88d7;
                8'h21: register_value = 16'h89e8;
                8'h22: register_value = 16'h13e0;
                8'h23: register_value = 16'h0000;
                8'h24: register_value = 16'h1000;
                8'h25: register_value = 16'h0d40;
                8'h26: register_value = 16'h1418;
                8'h27: register_value = 16'ha505;
                8'h28: register_value = 16'hab07;
                8'h29: register_value = 16'h2495;
                8'h2a: register_value = 16'h2533;
                8'h2b: register_value = 16'h26e3;
                8'h2c: register_value = 16'h9f78;
                8'h2d: register_value = 16'ha068;
                8'h2e: register_value = 16'ha103;
                8'h2f: register_value = 16'ha6d8;
                8'h30: register_value = 16'ha7d8;
                8'h31: register_value = 16'ha8f0;
                8'h32: register_value = 16'ha990;
                8'h33: register_value = 16'haa94;
                8'h34: register_value = 16'h13e5;
                8'h35: register_value = 16'h0e61;
                8'h36: register_value = 16'h0f4b;
                8'h37: register_value = 16'h1602;
                8'h38: register_value = 16'h1e07;
                8'h39: register_value = 16'h2102;
                8'h3a: register_value = 16'h2291;
                8'h3b: register_value = 16'h2907;
                8'h3c: register_value = 16'h330b;
                8'h3d: register_value = 16'h350b;
                8'h3e: register_value = 16'h371d;
                8'h3f: register_value = 16'h3871;
                8'h40: register_value = 16'h392a;
                8'h41: register_value = 16'h3c78;
                8'h42: register_value = 16'h4d40;
                8'h43: register_value = 16'h4e20;
                8'h44: register_value = 16'h6900;
                8'h45: register_value = 16'h6b4a;
                8'h46: register_value = 16'h7410;
                8'h47: register_value = 16'h8d4f;
                8'h48: register_value = 16'h8e00;
                8'h49: register_value = 16'h8f00;
                8'h4a: register_value = 16'h9000;
                8'h4b: register_value = 16'h9100;
                8'h4c: register_value = 16'h9600;
                8'h4d: register_value = 16'h9a00;
                8'h4e: register_value = 16'hb084;
                8'h4f: register_value = 16'hb10c;
                8'h50: register_value = 16'hb20e;
                8'h51: register_value = 16'hb382;
                8'h52: register_value = 16'hb80a;
                8'h53: register_value = 16'h430a;
                8'h54: register_value = 16'h44f0;
                8'h55: register_value = 16'h4534;
                8'h56: register_value = 16'h4658;
                8'h57: register_value = 16'h4728;
                8'h58: register_value = 16'h483a;
                8'h59: register_value = 16'h5988;
                8'h5a: register_value = 16'h5a88;
                8'h5b: register_value = 16'h5b44;
                8'h5c: register_value = 16'h5c67;
                8'h5d: register_value = 16'h5d49;
                8'h5e: register_value = 16'h5e0e;
                8'h5f: register_value = 16'h6c0a;
                8'h60: register_value = 16'h6d55;
                8'h61: register_value = 16'h6e11;
                8'h62: register_value = 16'h6f9f;
                8'h63: register_value = 16'h6a40;
                8'h64: register_value = 16'h0140;
                8'h65: register_value = 16'h0260;
                8'h66: register_value = 16'h13e7;
                8'h67: register_value = 16'h4f80;
                8'h68: register_value = 16'h5080;
                8'h69: register_value = 16'h5100;
                8'h6a: register_value = 16'h5222;
                8'h6b: register_value = 16'h535e;
                8'h6c: register_value = 16'h5480;
                8'h6d: register_value = 16'h589e;
                8'h6e: register_value = 16'h4108;
                8'h6f: register_value = 16'h3f00;
                8'h70: register_value = 16'h7505;
                8'h71: register_value = 16'h76e1;
                8'h72: register_value = 16'h4c00;
                8'h73: register_value = 16'h7701;
                8'h74: register_value = 16'h3dc3;
                8'h75: register_value = 16'h4b09;
                8'h76: register_value = 16'hc960;
                8'h77: register_value = 16'h4138;
                8'h78: register_value = 16'h5640;
                8'h79: register_value = 16'h3411;
                8'h7a: register_value = 16'h3b12;
                8'h7b: register_value = 16'ha488;
                8'h7c: register_value = 16'h9600;
                8'h7d: register_value = 16'h9730;
                8'h7e: register_value = 16'h9820;
                8'h7f: register_value = 16'h9930;
                8'h80: register_value = 16'h9a84;
                8'h81: register_value = 16'h9b29;
                8'h82: register_value = 16'h9c03;
                8'h83: register_value = 16'h9d4c;
                8'h84: register_value = 16'h9e3f;
                8'h85: register_value = 16'h7804;
                8'h86: register_value = 16'h7901;
                8'h87: register_value = 16'hc8f0;
                8'h88: register_value = 16'h790f;
                8'h89: register_value = 16'hc800;
                8'h8a: register_value = 16'h7910;
                8'h8b: register_value = 16'hc87e;
                8'h8c: register_value = 16'h790a;
                8'h8d: register_value = 16'hc880;
                8'h8e: register_value = 16'h790b;
                8'h8f: register_value = 16'hc801;
                8'h90: register_value = 16'h790c;
                8'h91: register_value = 16'hc80f;
                8'h92: register_value = 16'h790d;
                8'h93: register_value = 16'hc820;
                8'h94: register_value = 16'h7909;
                8'h95: register_value = 16'hc880;
                8'h96: register_value = 16'h7902;
                8'h97: register_value = 16'hc8c0;
                8'h98: register_value = 16'h7903;
                8'h99: register_value = 16'hc840;
                8'h9a: register_value = 16'h7905;
                8'h9b: register_value = 16'hc830;
                8'h9c: register_value = 16'h7926;
                8'h9d: register_value = 16'h1204;
                8'h9e: register_value = 16'h8c00;
                8'h9f: register_value = 16'h0400;
                8'ha0: register_value = 16'h40d0;
                8'ha1: register_value = 16'h1438;
                8'ha2: register_value = 16'h4fb3;
                8'ha3: register_value = 16'h50b3;
                8'ha4: register_value = 16'h5100;
                8'ha5: register_value = 16'h523d;
                8'ha6: register_value = 16'h53a7;
                8'ha7: register_value = 16'h54e4;
                8'ha8: register_value = 16'h3dc0;
                // Re-apply CLKRC after the RGB565 configuration sequence.
                8'ha9: register_value = 16'h1100;
                default: register_value = 16'hffff;
            endcase
        end
    endfunction

    wire busy = busy_sr[31];
    assign sda_t = (busy_sr[11:10] == 2'b10) ||
                   (busy_sr[20:19] == 2'b10) ||
                   (busy_sr[29:28] == 2'b10);
    assign sda_o = data_sr[31];
    assign xclk_12m = (xclk_disable ||
                       !(channel_started || init_grant)) ? 1'b0 : sys_clk;
    assign reset_n = (force_reset || !channel_started || failed_r) ? 1'b0 :
                     ((startup_state == START_RESET_RELEASED) ||
                      (startup_state == START_SCCB_READY));
    assign pwdn = force_pwdn || !channel_started || failed_r ||
                  (startup_state == START_XCLK_ONLY);
    assign scl = scl_r;
    assign done = finished;
    assign failed = failed_r;
    assign init_request = init_request_r;
    assign init_terminal = finished || failed_r;
    assign capture_enable = finished && !failed_r && !xclk_disable &&
                            !force_reset && !force_pwdn;

    always @(posedge clk_24m) begin
        ctrl_cycle_count <= ctrl_cycle_count + 1'b1;
        sys_clk <= !sys_clk;

        if (!sys_rstn) begin
            sys_clk <= 1'b0;
            init_request_r <= 1'b1;
            running <= 1'b0;
            channel_started <= 1'b0;
            reinit_seen <= reinit_toggle;
            finished <= 1'b0;
            failed_r <= 1'b0;
            taken <= 1'b0;
            divider <= 8'h01;
            busy_sr <= 32'd0;
            data_sr <= 32'hffffffff;
            sreg <= 16'h1280;
            address <= 8'd0;
            startup_state <= START_XCLK_ONLY;
            startup_wait <= 18'd0;
            post_reset_wait <= 18'd0;
            retry_wait <= 12'd0;
            ready <= 1'b0;
            scl_r <= 1'b1;
            ack_count <= 8'd0;
            nack_count <= 8'd0;
            ack_sample_count <= 8'd0;
            first_nack_valid <= 1'b0;
            first_nack_phase <= 2'd0;
            first_nack_write <= 8'd0;
            transaction_nack <= 1'b0;
            transaction_first_nack_phase <= 2'd0;
            retry_count <= 2'd0;
            failed_phase <= 2'd0;
            failed_attempt <= 2'd0;
            failed_index <= 8'd0;
            failed_register <= 8'd0;
            failed_value <= 8'd0;
            successful_write_count <= 32'd0;
            retry_total_count <= 32'd0;
            nack_id_count <= 32'd0;
            nack_register_count <= 32'd0;
            nack_data_count <= 32'd0;
        end else if (reinit_toggle != reinit_seen) begin
            reinit_seen <= reinit_toggle;
            init_request_r <= 1'b1;
            running <= 1'b0;
            finished <= 1'b0;
            failed_r <= 1'b0;
            taken <= 1'b0;
            divider <= 8'h01;
            busy_sr <= 32'd0;
            data_sr <= 32'hffffffff;
            sreg <= 16'h1280;
            address <= 8'd0;
            startup_state <= START_XCLK_ONLY;
            startup_wait <= 18'd0;
            post_reset_wait <= 18'd0;
            retry_wait <= 12'd0;
            ready <= 1'b0;
            scl_r <= 1'b1;
            ack_count <= 8'd0;
            nack_count <= 8'd0;
            ack_sample_count <= 8'd0;
            first_nack_valid <= 1'b0;
            first_nack_phase <= 2'd0;
            first_nack_write <= 8'd0;
            transaction_nack <= 1'b0;
            transaction_first_nack_phase <= 2'd0;
            retry_count <= 2'd0;
            failed_phase <= 2'd0;
            failed_attempt <= 2'd0;
            failed_index <= 8'd0;
            failed_register <= 8'd0;
            failed_value <= 8'd0;
            successful_write_count <= 32'd0;
            retry_total_count <= 32'd0;
            nack_id_count <= 32'd0;
            nack_register_count <= 32'd0;
            nack_data_count <= 32'd0;
        end else begin
            if (init_request_r && init_grant) begin
                init_request_r <= 1'b0;
                running <= 1'b1;
                channel_started <= 1'b1;
                startup_state <= START_XCLK_ONLY;
                startup_wait <= XCLK_TO_PWDN_CYCLES[17:0];
                ready <= 1'b0;
            end

            if (running && !ready) begin
                if (startup_wait != 18'd0) begin
                    startup_wait <= startup_wait - 1'b1;
                end else begin
                    case (startup_state)
                        START_XCLK_ONLY: begin
                            startup_state <= START_PWDN_RELEASED;
                            startup_wait <= PWDN_TO_RESET_CYCLES[17:0];
                        end
                        START_PWDN_RELEASED: begin
                            startup_state <= START_RESET_RELEASED;
                            startup_wait <= RESET_TO_SCCB_CYCLES[17:0];
                        end
                        START_RESET_RELEASED: begin
                            startup_state <= START_SCCB_READY;
                            ready <= 1'b1;
                        end
                        default: ready <= 1'b1;
                    endcase
                end
            end

            sreg <= register_value(address);

            if (post_reset_wait != 18'd0)
                post_reset_wait <= post_reset_wait - 1'b1;
            if (retry_wait != 12'd0)
                retry_wait <= retry_wait - 1'b1;

            taken <= 1'b0;
            if (!busy) begin
                scl_r <= 1'b1;
                if (running && ready && !finished && !failed_r &&
                    post_reset_wait == 18'd0 && retry_wait == 12'd0) begin
                    if (divider == 8'h00) begin
                        data_sr <= {3'b100, 8'h42, 1'b0,
                                    sreg[15:8], 1'b0, sreg[7:0], 1'b0, 2'b01};
                        busy_sr <= {3'b111, 9'h1ff, 9'h1ff, 9'h1ff, 2'b11};
                        taken <= 1'b1;
                        transaction_nack <= 1'b0;
                        transaction_first_nack_phase <= 2'd0;
                    end else begin
                        divider <= divider + 1'b1;
                    end
                end
            end else begin
            case ({busy_sr[31:29], busy_sr[2:0]})
                6'b111111, 6'b111110: scl_r <= 1'b1;
                6'b111100: scl_r <= 1'b0;
                6'b110000: scl_r <= (divider[7:6] != 2'b00);
                6'b100000, 6'b000000: scl_r <= 1'b1;
                default: begin
                    case (divider[7:6])
                        2'b00, 2'b11: scl_r <= 1'b0;
                        default: scl_r <= 1'b1;
                    endcase
                end
            endcase

            if (sda_t && divider == 8'h80) begin
                ack_sample_count <= ack_sample_count + 1'b1;
                if (sda_in === 1'b0) begin
                    ack_count <= ack_count + 1'b1;
                end else begin
                    nack_count <= nack_count + 1'b1;
                    transaction_nack <= 1'b1;
                    if (!first_nack_valid) begin
                        first_nack_valid <= 1'b1;
                        first_nack_write <= address;
                        if (busy_sr[29:28] == 2'b10)
                            first_nack_phase <= 2'd0;
                        else if (busy_sr[20:19] == 2'b10)
                            first_nack_phase <= 2'd1;
                        else
                            first_nack_phase <= 2'd2;
                    end
                    if (!transaction_nack) begin
                        if (busy_sr[29:28] == 2'b10)
                            transaction_first_nack_phase <= 2'd0;
                        else if (busy_sr[20:19] == 2'b10)
                            transaction_first_nack_phase <= 2'd1;
                        else
                            transaction_first_nack_phase <= 2'd2;
                    end
                    if (busy_sr[29:28] == 2'b10)
                        nack_id_count <= nack_id_count + 1'b1;
                    else if (busy_sr[20:19] == 2'b10)
                        nack_register_count <= nack_register_count + 1'b1;
                    else
                        nack_data_count <= nack_data_count + 1'b1;
                end
            end

                if (divider == 8'hff) begin
                    busy_sr <= {busy_sr[30:0], 1'b0};
                    data_sr <= {data_sr[30:0], 1'b1};
                    divider <= 8'd0;
                    if (busy_sr[30:0] == 31'd0) begin
                        if (transaction_nack) begin
                            if (retry_count != MAX_RETRIES[1:0]) begin
                                retry_count <= retry_count + 1'b1;
                                retry_total_count <= retry_total_count + 1'b1;
                                retry_wait <= RETRY_WAIT_CYCLES[11:0];
                            end else begin
                                failed_r <= 1'b1;
                                running <= 1'b0;
                                failed_phase <= transaction_first_nack_phase;
                                failed_attempt <= MAX_RETRIES[1:0];
                                failed_index <= address;
                                failed_register <= sreg[15:8];
                                failed_value <= sreg[7:0];
                            end
                        end else begin
                            retry_count <= 2'd0;
                            successful_write_count <= successful_write_count + 1'b1;
                            if (address == 8'h00) begin
                                address <= 8'h01;
                                // Leave a conservative 10 ms after the COM7
                                // software reset before continuing the table.
                                post_reset_wait <= POST_RESET_WAIT_CYCLES[17:0];
                            end else if (address == 8'ha9) begin
                                address <= 8'haa;
                                finished <= 1'b1;
                                running <= 1'b0;
                            end else begin
                                address <= address + 1'b1;
                            end
                        end
                    end
                end else begin
                    divider <= divider + 1'b1;
                end
            end
        end
    end

    assign diag = {
        {failed_register, failed_value, failed_index, 4'd0,
         failed_phase, failed_attempt},
        nack_data_count,
        nack_register_count,
        nack_id_count,
        retry_total_count,
        successful_write_count,
        ctrl_cycle_count ^ (ctrl_cycle_count >> 1),
        data_sr,
        busy_sr,
        5'd0, first_nack_valid, first_nack_phase, first_nack_write, sreg,
        address, ack_count, nack_count, ack_sample_count,
        4'd0, startup_state, startup_wait, divider,
        8'h76, sys_clk, reset_n, pwdn, ready, finished, busy, sda_in,
        sda_t, scl_r, sda_o, taken, failed_r, running, init_request_r,
        2'd0, address
    };
endmodule

// Register bank shared by each identical OV7670 frontend.
module ov7670_axil_regs #(
    parameter integer WORDS = 1
) (
    axi_lite_if.slave axil,
    input wire [WORDS*32-1:0] read_words,
    output reg write_pulse,
    output reg [15:0] write_word,
    output reg [31:0] write_data,
    output reg [3:0] write_strb
);
    reg aw_seen;
    reg w_seen;
    reg bvalid;
    reg rvalid;
    reg [15:0] aw_word;
    reg [31:0] wdata_hold;
    reg [3:0] wstrb_hold;
    reg [31:0] rdata;

    wire aw_fire = axil.awvalid && axil.awready;
    wire w_fire = axil.wvalid && axil.wready;
    wire write_complete = !bvalid && (aw_seen || aw_fire) &&
                          (w_seen || w_fire);

    assign axil.awready = axil.aresetn && !aw_seen && !bvalid;
    assign axil.wready  = axil.aresetn && !w_seen && !bvalid;
    assign axil.bresp   = 2'b00;
    assign axil.bvalid  = bvalid;
    assign axil.arready = axil.aresetn && !rvalid;
    assign axil.rdata   = rdata;
    assign axil.rresp   = 2'b00;
    assign axil.rvalid  = rvalid;

    always @(posedge axil.aclk) begin
        if (!axil.aresetn) begin
            aw_seen <= 1'b0;
            w_seen <= 1'b0;
            bvalid <= 1'b0;
            rvalid <= 1'b0;
            aw_word <= 16'd0;
            wdata_hold <= 32'd0;
            wstrb_hold <= 4'd0;
            rdata <= 32'd0;
            write_pulse <= 1'b0;
            write_word <= 16'd0;
            write_data <= 32'd0;
            write_strb <= 4'd0;
        end else begin
            write_pulse <= 1'b0;
            if (aw_fire) begin
                aw_seen <= 1'b1;
                aw_word <= axil.awaddr[17:2];
            end
            if (w_fire) begin
                w_seen <= 1'b1;
                wdata_hold <= axil.wdata;
                wstrb_hold <= axil.wstrb;
            end

            if (write_complete) begin
                bvalid <= 1'b1;
                aw_seen <= 1'b0;
                w_seen <= 1'b0;
                write_pulse <= 1'b1;
                write_word <= aw_fire ? axil.awaddr[17:2] : aw_word;
                write_data <= w_fire ? axil.wdata : wdata_hold;
                write_strb <= w_fire ? axil.wstrb : wstrb_hold;
            end else if (bvalid && axil.bready) begin
                bvalid <= 1'b0;
            end

            if (axil.arvalid && axil.arready) begin
                rvalid <= 1'b1;
                if (axil.araddr[17:2] < WORDS[15:0])
                    rdata <= read_words[axil.araddr[17:2]*32 +: 32];
                else
                    rdata <= 32'd0;
            end else if (rvalid && axil.rready) begin
                rvalid <= 1'b0;
            end
        end
    end
endmodule

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
    reg [31:0] pclk_cycle_count = 32'd0;
    reg [31:0] input_frame_count = 32'd0;
    reg [31:0] input_line_count = 32'd0;
    reg [31:0] input_byte_count = 32'd0;
    reg [31:0] input_pixel_count = 32'd0;
    reg        input_byte_phase = 1'b0;
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
    reg [31:0] rejected_vsync_count = 32'd0;
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
            rejected_vsync_count <= 32'd0;
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
                    end else begin
                        rejected_vsync_count <= rejected_vsync_count + 1'b1;
                    end
                end
            end
            if (diag_clear_video)
                rejected_vsync_count <= 32'd0;
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
            pclk_cycle_count <= 32'd0;
            input_frame_count <= 32'd0;
            input_line_count <= 32'd0;
            input_byte_count <= 32'd0;
            input_pixel_count <= 32'd0;
            input_byte_phase <= 1'b0;
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
            if (event_frame_boundary || event_line_end)
                input_byte_phase <= 1'b0;
            else if (event_byte_valid) begin
                if (input_byte_phase)
                    input_pixel_count <= input_pixel_count + 1'b1;
                input_byte_phase <= !input_byte_phase;
            end
            if (pixel_ce) begin
                pclk_cycle_count <= pclk_cycle_count + 1'b1;
                diag_vsync_d <= vsync_qualified;
                diag_href_d <= href_filtered;

                if (vsync_qualified && !diag_vsync_d) begin
                    input_frame_count <= input_frame_count + 1'b1;
                    last_frame_lines <= current_frame_lines;
                    current_frame_lines <= 16'd0;
                end else if (href_filtered && !diag_href_d) begin
                    input_line_count <= input_line_count + 1'b1;
                    current_frame_lines <= current_frame_lines + 1'b1;
                end
                if (!href_filtered && diag_href_d)
                    last_line_bytes <= current_line_bytes;
                if (href_filtered) begin
                    input_byte_count <= input_byte_count + 1'b1;
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
