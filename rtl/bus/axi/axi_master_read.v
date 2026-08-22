`timescale 1ns/1ps

// Single-outstanding 256-bit AXI4 burst reader. RD_LEN is measured in beats.
module axi_master_read #(
    parameter [3:0] AXI_QOS = 4'hf
) (
    input  wire         ARESETN,
    input  wire         ACLK,
    output wire [5:0]   M_AXI_ARID,
    output wire [31:0]  M_AXI_ARADDR,
    output wire [7:0]   M_AXI_ARLEN,
    output wire [2:0]   M_AXI_ARSIZE,
    output wire [1:0]   M_AXI_ARBURST,
    output wire [1:0]   M_AXI_ARLOCK,
    output wire [3:0]   M_AXI_ARCACHE,
    output wire [2:0]   M_AXI_ARPROT,
    output wire [3:0]   M_AXI_ARQOS,
    output wire [0:0]   M_AXI_ARUSER,
    output wire         M_AXI_ARVALID,
    input  wire         M_AXI_ARREADY,
    input  wire [5:0]   M_AXI_RID,
    input  wire [255:0] M_AXI_RDATA,
    input  wire [1:0]   M_AXI_RRESP,
    input  wire         M_AXI_RLAST,
    input  wire [0:0]   M_AXI_RUSER,
    input  wire         M_AXI_RVALID,
    output wire         M_AXI_RREADY,
    input  wire         RD_START,
    input  wire [31:0]  RD_ADRS,
    input  wire [31:0]  RD_LEN,
    output wire         RD_READY,
    output wire         RD_FIFO_WE,
    output wire [255:0] RD_FIFO_DATA,
    output wire         RD_DONE
);
    localparam [1:0] S_IDLE = 2'd0;
    localparam [1:0] S_ADDR = 2'd1;
    localparam [1:0] S_DATA = 2'd2;
    localparam [1:0] S_DONE = 2'd3;

    reg [1:0] state;
    reg [31:0] address;
    reg [8:0] beat_count;

    always @(posedge ACLK or negedge ARESETN) begin
        if (!ARESETN) begin
            state <= S_IDLE;
            address <= 0;
            beat_count <= 0;
        end else begin
            case (state)
                S_IDLE: begin
                    if (RD_START && (RD_LEN != 0)) begin
                        address <= RD_ADRS;
                        beat_count <= RD_LEN[8:0];
                        state <= S_ADDR;
                    end
                end
                S_ADDR: begin
                    if (M_AXI_ARREADY)
                        state <= S_DATA;
                end
                S_DATA: begin
                    if (M_AXI_RVALID && M_AXI_RLAST)
                        state <= S_DONE;
                end
                S_DONE: state <= S_IDLE;
                default: state <= S_IDLE;
            endcase
        end
    end

    assign RD_READY = state == S_IDLE;
    assign RD_DONE = state == S_DONE;
    assign RD_FIFO_WE = (state == S_DATA) && M_AXI_RVALID;
    assign RD_FIFO_DATA = M_AXI_RDATA;
    assign M_AXI_ARID = 0;
    assign M_AXI_ARADDR = address;
    assign M_AXI_ARLEN = beat_count[7:0] - 1'b1;
    assign M_AXI_ARSIZE = 3'b101;
    assign M_AXI_ARBURST = 2'b01;
    assign M_AXI_ARLOCK = 2'b00;
    assign M_AXI_ARCACHE = 4'b0010;
    assign M_AXI_ARPROT = 3'b000;
    assign M_AXI_ARQOS = AXI_QOS;
    assign M_AXI_ARUSER = 1'b0;
    assign M_AXI_ARVALID = state == S_ADDR;
    assign M_AXI_RREADY = state == S_DATA;

    wire unused = &{1'b0, M_AXI_RID, M_AXI_RRESP, M_AXI_RUSER};
endmodule
