`timescale 1ns/1ps

// AXI4-Lite error responder used to reserve address windows for IP that is
// intentionally absent from the current build.  AW and W may arrive in either
// order; every completed access receives DECERR instead of stalling the bus.
module axi_lite_decerr_slave (
    input  wire        aclk,
    input  wire        aresetn,
    input  wire        s_awvalid,
    output wire        s_awready,
    input  wire        s_wvalid,
    output wire        s_wready,
    output wire [1:0]  s_bresp,
    output wire        s_bvalid,
    input  wire        s_bready,
    input  wire        s_arvalid,
    output wire        s_arready,
    output wire [31:0] s_rdata,
    output wire [1:0]  s_rresp,
    output wire        s_rvalid,
    input  wire        s_rready
);
    reg aw_seen;
    reg w_seen;
    reg bvalid;
    reg rvalid;

    assign s_awready = aresetn && !aw_seen && !bvalid;
    assign s_wready  = aresetn && !w_seen  && !bvalid;
    assign s_bresp   = 2'b11;
    assign s_bvalid  = bvalid;
    assign s_arready = aresetn && !rvalid;
    assign s_rdata   = 32'b0;
    assign s_rresp   = 2'b11;
    assign s_rvalid  = rvalid;

    always @(posedge aclk) begin
        if (!aresetn) begin
            aw_seen <= 1'b0;
            w_seen  <= 1'b0;
            bvalid  <= 1'b0;
            rvalid  <= 1'b0;
        end else begin
            if (s_awready && s_awvalid)
                aw_seen <= 1'b1;
            if (s_wready && s_wvalid)
                w_seen <= 1'b1;

            if (!bvalid && (aw_seen || (s_awready && s_awvalid)) &&
                           (w_seen  || (s_wready  && s_wvalid))) begin
                bvalid <= 1'b1;
                aw_seen <= 1'b0;
                w_seen <= 1'b0;
            end else if (bvalid && s_bready) begin
                bvalid <= 1'b0;
            end

            if (s_arready && s_arvalid)
                rvalid <= 1'b1;
            else if (rvalid && s_rready)
                rvalid <= 1'b0;
        end
    end
endmodule
