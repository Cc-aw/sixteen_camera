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
