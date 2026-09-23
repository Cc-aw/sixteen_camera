`timescale 1ns/1ps

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
