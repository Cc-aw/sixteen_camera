`timescale 1ns/1ps

module tb_ov7670_init_scheduler;
    reg clk = 1'b0;
    reg rstn = 1'b0;
    reg [7:0] request = 8'hff;
    reg [7:0] terminal = 8'd0;
    wire [7:0] grant;
    integer channel;

    always #1 clk = ~clk;

    ov7670_init_scheduler dut (
        .clk(clk), .rstn(rstn), .request(request),
        .terminal(terminal), .grant(grant)
    );

    always @(posedge clk) begin
        if (rstn && grant != 8'd0 && (grant & (grant - 1'b1)) != 8'd0)
            $fatal(1, "multiple simultaneous grants: %h", grant);
    end

    initial begin
        repeat (4) @(posedge clk);
        rstn = 1'b1;
        for (channel = 0; channel < 8; channel = channel + 1) begin
            wait (grant == (8'b1 << channel));
            request[channel] = 1'b0;
            repeat (3) @(posedge clk);
            terminal[channel] = 1'b1;
            @(posedge clk);
            terminal[channel] = 1'b0;
        end
        repeat (4) @(posedge clk);
        if (grant != 8'd0)
            $fatal(1, "grant did not return idle: %h", grant);
        $display("OV7670_INIT_SCHEDULER_SIM=PASS");
        $finish;
    end

    initial begin
        #10000;
        $fatal(1, "OV7670_INIT_SCHEDULER_SIM=TIMEOUT");
    end
endmodule
