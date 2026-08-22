`timescale 1ns/1ps

module tb_ov7670_iic_writer;
    reg clk = 1'b0;
    reg rstn = 1'b0;
    always #1 clk = ~clk;

    wire success_scl;
    wire success_sda_t;
    wire success_done;
    wire success_failed;
    wire success_request;
    wire success_terminal;
    wire [415:0] success_diag;

    // Inject one register-address NACK on table entry 2, then ACK its retry.
    wire success_sda_in =
        (u_success.address == 8'h02 && u_success.retry_count == 2'd0 &&
         u_success.busy_sr[20:19] == 2'b10) ? 1'b1 : 1'b0;

    ov7670_ztachip_ctrl #(
        .STARTUP_COUNTDOWN(7), .POST_RESET_WAIT_CYCLES(5),
        .RETRY_WAIT_CYCLES(3), .MAX_RETRIES(3)
    ) u_success (
        .clk_24m(clk), .sys_rstn(rstn), .sda_in(success_sda_in),
        .reinit_toggle(1'b0), .init_grant(1'b1),
        .xclk_disable(1'b0), .force_reset(1'b0), .force_pwdn(1'b0),
        .xclk_12m(), .reset_n(), .pwdn(), .scl(success_scl), .sda_o(),
        .sda_t(success_sda_t), .done(success_done),
        .failed(success_failed), .init_request(success_request),
        .init_terminal(success_terminal), .capture_enable(),
        .diag(success_diag)
    );

    wire fail_done;
    wire fail_failed;
    wire fail_terminal;
    wire [415:0] fail_diag;
    ov7670_ztachip_ctrl #(
        .STARTUP_COUNTDOWN(7), .POST_RESET_WAIT_CYCLES(5),
        .RETRY_WAIT_CYCLES(3), .MAX_RETRIES(3)
    ) u_fail (
        .clk_24m(clk), .sys_rstn(rstn), .sda_in(1'b1),
        .reinit_toggle(1'b0), .init_grant(1'b1),
        .xclk_disable(1'b0), .force_reset(1'b0), .force_pwdn(1'b0),
        .xclk_12m(), .reset_n(), .pwdn(), .scl(), .sda_o(), .sda_t(),
        .done(fail_done), .failed(fail_failed), .init_request(),
        .init_terminal(fail_terminal), .capture_enable(), .diag(fail_diag)
    );

    initial begin
        repeat (4) @(posedge clk);
        rstn = 1'b1;
        wait (success_terminal && fail_terminal);
        if (!success_done || success_failed ||
            u_success.successful_write_count != 32'd170 ||
            u_success.retry_total_count != 32'd1 ||
            u_success.nack_register_count != 32'd1) begin
            $display("ERROR success path done/fail/write/retry/reg_nack=%0d/%0d/%0d/%0d/%0d",
                     success_done, success_failed,
                     u_success.successful_write_count,
                     u_success.retry_total_count,
                     u_success.nack_register_count);
            $fatal(1);
        end
        if (fail_done || !fail_failed || u_fail.failed_index != 8'h00 ||
            u_fail.retry_total_count != 32'd3 ||
            u_fail.nack_id_count != 32'd4 ||
            u_fail.nack_register_count != 32'd4 ||
            u_fail.nack_data_count != 32'd4) begin
            $display("ERROR failure path done/fail/index/retry/nacks=%0d/%0d/%0d/%0d/%0d/%0d/%0d",
                     fail_done, fail_failed, u_fail.failed_index,
                     u_fail.retry_total_count, u_fail.nack_id_count,
                     u_fail.nack_register_count, u_fail.nack_data_count);
            $fatal(1);
        end
        $display("OV7670_IIC_WRITER_SIM=PASS");
        $finish;
    end

    initial begin
        #10000000;
        $fatal(1, "OV7670_IIC_WRITER_SIM=TIMEOUT");
    end
endmodule
