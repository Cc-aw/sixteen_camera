`timescale 1ns/1ps

// Sample the asynchronous DVP pins as one aligned bus.  PCLK is data here;
// all registers use the high-speed capture clock.  Payload stages deliberately
// have no reset so the IOB flops remain packable and reset routing does not
// become part of the 300 MHz input path.
module dvp_input_sampler (
    input  wire       capture_clk,
    input  wire       dvp_pclk,
    input  wire       dvp_vsync,
    input  wire       dvp_href,
    input  wire [7:0] dvp_data,
    output reg        sampled_pclk = 1'b0,
    output reg        sampled_vsync = 1'b0,
    output reg        sampled_href = 1'b0,
    output reg  [7:0] sampled_data = 8'd0
);
    (* IOB = "TRUE", ASYNC_REG = "TRUE", SHREG_EXTRACT = "NO" *)
    reg       dvp_pclk_iob = 1'b0;
    (* IOB = "TRUE", ASYNC_REG = "TRUE", SHREG_EXTRACT = "NO" *)
    reg       dvp_vsync_iob = 1'b0;
    (* IOB = "TRUE", ASYNC_REG = "TRUE", SHREG_EXTRACT = "NO" *)
    reg       dvp_href_iob = 1'b0;
    (* IOB = "TRUE", ASYNC_REG = "TRUE", SHREG_EXTRACT = "NO" *)
    reg [7:0] dvp_data_iob = 8'd0;

    (* ASYNC_REG = "TRUE", SHREG_EXTRACT = "NO" *)
    reg       dvp_pclk_sync = 1'b0;
    (* ASYNC_REG = "TRUE", SHREG_EXTRACT = "NO" *)
    reg       dvp_vsync_sync = 1'b0;
    (* ASYNC_REG = "TRUE", SHREG_EXTRACT = "NO" *)
    reg       dvp_href_sync = 1'b0;
    (* ASYNC_REG = "TRUE", SHREG_EXTRACT = "NO" *)
    reg [7:0] dvp_data_sync = 8'd0;

    always @(posedge capture_clk) begin
        dvp_pclk_iob <= dvp_pclk;
        dvp_vsync_iob <= dvp_vsync;
        dvp_href_iob <= dvp_href;
        dvp_data_iob <= dvp_data;

        dvp_pclk_sync <= dvp_pclk_iob;
        dvp_vsync_sync <= dvp_vsync_iob;
        dvp_href_sync <= dvp_href_iob;
        dvp_data_sync <= dvp_data_iob;

        sampled_pclk <= dvp_pclk_sync;
        sampled_vsync <= dvp_vsync_sync;
        sampled_href <= dvp_href_sync;
        sampled_data <= dvp_data_sync;
    end
endmodule
