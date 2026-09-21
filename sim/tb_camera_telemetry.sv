`timescale 1ns/1ps

module tb_camera_telemetry;
    reg ctrl_clk = 1'b0;
    reg capture_clk = 1'b0;
    reg axil_clk = 1'b0;
    always #21 ctrl_clk = ~ctrl_clk;
    always #2 capture_clk = ~capture_clk;
    always #5 axil_clk = ~axil_clk;

    reg ctrl_resetn = 1'b0;
    reg capture_resetn = 1'b0;
    reg axil_resetn = 1'b0;
    reg [31:0] ctrl_status0_src = 32'd0;
    reg [31:0] ctrl_status1_src = 32'd0;
    reg capture_enable = 1'b0;
    reg pclk_locked = 1'b0;
    reg [1:0] pclk_state = 2'd0;
    reg [23:0] pclk_period = 24'd0;
    reg [31:0] frame_count = 32'd0;
    reg [31:0] overflow_count = 32'd0;
    reg [31:0] lock_loss_count = 32'd0;
    reg [31:0] geometry = 32'd0;
    wire [31:0] ctrl_status0;
    wire [31:0] ctrl_status1;
    wire [31:0] capture_status0;
    wire [31:0] capture_frame_count;
    wire [31:0] capture_overflow_count;
    wire [31:0] capture_lock_loss_count;
    wire [31:0] capture_geometry;

    camera_telemetry dut (
        .ctrl_clk(ctrl_clk), .ctrl_resetn(ctrl_resetn),
        .ctrl_status0_src(ctrl_status0_src),
        .ctrl_status1_src(ctrl_status1_src),
        .capture_clk(capture_clk), .capture_resetn(capture_resetn),
        .capture_enable(capture_enable), .pclk_locked(pclk_locked),
        .pclk_state(pclk_state), .pclk_period(pclk_period),
        .frame_count(frame_count), .overflow_count(overflow_count),
        .lock_loss_count(lock_loss_count), .geometry(geometry),
        .axil_clk(axil_clk), .axil_resetn(axil_resetn),
        .ctrl_status0(ctrl_status0), .ctrl_status1(ctrl_status1),
        .capture_status0(capture_status0),
        .capture_frame_count(capture_frame_count),
        .capture_overflow_count(capture_overflow_count),
        .capture_lock_loss_count(capture_lock_loss_count),
        .capture_geometry(capture_geometry)
    );

    task automatic check_outputs;
        input [31:0] expected_ctrl0;
        input [31:0] expected_ctrl1;
        input [31:0] expected_status;
        input [31:0] expected_frame;
        input [31:0] expected_overflow;
        input [31:0] expected_loss;
        input [31:0] expected_geometry;
        begin
            if (ctrl_status0 !== expected_ctrl0 ||
                ctrl_status1 !== expected_ctrl1 ||
                capture_status0 !== expected_status ||
                capture_frame_count !== expected_frame ||
                capture_overflow_count !== expected_overflow ||
                capture_lock_loss_count !== expected_loss ||
                capture_geometry !== expected_geometry)
                $fatal(1, "telemetry mismatch");
        end
    endtask

    initial begin
        ctrl_status0_src = 32'h1122_3344;
        ctrl_status1_src = 32'h5566_7788;
        capture_enable = 1'b1;
        pclk_locked = 1'b1;
        pclk_state = 2'd2;
        pclk_period = 24'h12_3456;
        frame_count = 32'h0102_0304;
        overflow_count = 32'h1112_1314;
        lock_loss_count = 32'h2122_2324;
        geometry = 32'h01e0_0500;

        repeat (4) @(posedge axil_clk);
        ctrl_resetn = 1'b1;
        capture_resetn = 1'b1;
        axil_resetn = 1'b1;
        repeat (80) @(posedge axil_clk);
        check_outputs(32'h1122_3344, 32'h5566_7788,
                      {4'd0, 24'h12_3456, 2'd2, 1'b1, 1'b1},
                      32'h0102_0304, 32'h1112_1314,
                      32'h2122_2324, 32'h01e0_0500);

        ctrl_status0_src = 32'haaaa_0001;
        ctrl_status1_src = 32'hbbbb_0002;
        pclk_period = 24'hab_cdef;
        pclk_state = 2'd1;
        pclk_locked = 1'b0;
        frame_count = 32'h3132_3334;
        overflow_count = 32'h4142_4344;
        lock_loss_count = 32'h5152_5354;
        geometry = 32'h0258_0500;
        repeat (80) @(posedge axil_clk);
        check_outputs(32'haaaa_0001, 32'hbbbb_0002,
                      {4'd0, 24'hab_cdef, 2'd1, 1'b0, 1'b1},
                      32'h3132_3334, 32'h4142_4344,
                      32'h5152_5354, 32'h0258_0500);
        $display("TB_CAMERA_TELEMETRY_PASS");
        $finish;
    end
endmodule
