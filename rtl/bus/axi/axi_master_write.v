`timescale 1ns/1ps

// Single-outstanding 256-bit AXI4 burst writer. WR_LEN is measured in beats.
module axi_master_write #(
    parameter [3:0] AXI_QOS = 4'he
) (
    input  wire         ARESETN,
    input  wire         ACLK,
    output wire [5:0]   M_AXI_AWID,
    output wire [31:0]  M_AXI_AWADDR,
    output wire [7:0]   M_AXI_AWLEN,
    output wire [2:0]   M_AXI_AWSIZE,
    output wire [1:0]   M_AXI_AWBURST,
    output wire         M_AXI_AWLOCK,
    output wire [3:0]   M_AXI_AWCACHE,
    output wire [2:0]   M_AXI_AWPROT,
    output wire [3:0]   M_AXI_AWQOS,
    output wire [0:0]   M_AXI_AWUSER,
    output wire         M_AXI_AWVALID,
    input  wire         M_AXI_AWREADY,
    output wire [255:0] M_AXI_WDATA,
    output wire [31:0]  M_AXI_WSTRB,
    output wire         M_AXI_WLAST,
    output wire [0:0]   M_AXI_WUSER,
    output wire         M_AXI_WVALID,
    input  wire         M_AXI_WREADY,
    input  wire [5:0]   M_AXI_BID,
    input  wire [1:0]   M_AXI_BRESP,
    input  wire [0:0]   M_AXI_BUSER,
    input  wire         M_AXI_BVALID,
    output wire         M_AXI_BREADY,
    input  wire         WR_START,
    input  wire [31:0]  WR_ADRS,
    input  wire [31:0]  WR_LEN,
    output wire         WR_READY,
    output wire         WR_FIFO_RE,
    input  wire         WR_FIFO_EMPTY,
    input  wire         WR_FIFO_VALID,
    input  wire         WR_FIFO_AEMPTY,
    input  wire [255:0] WR_FIFO_DATA,
    output wire         WR_DONE,
    output wire         WR_ERROR
);
    localparam [2:0] S_IDLE = 3'd0;
    localparam [2:0] S_SEND = 3'd1;
    localparam [2:0] S_RESP = 3'd2;
    localparam [2:0] S_DONE = 3'd3;

    reg [2:0] state;
    reg [31:0] address;
    reg [8:0] beat_count;
    reg [8:0] beats_sent;
    reg awvalid;
    reg fetch_pending;
    reg data_valid;
    reg [255:0] data_reg;
    reg response_error;

    wire w_fire = M_AXI_WVALID && M_AXI_WREADY;
    wire last_beat = beats_sent == beat_count - 1'b1;

    assign WR_READY = state == S_IDLE;
    assign WR_DONE = state == S_DONE;
    assign WR_ERROR = (state == S_DONE) && response_error;
    assign WR_FIFO_RE = (state == S_SEND) && !data_valid &&
                        !fetch_pending && !WR_FIFO_EMPTY;

    always @(posedge ACLK or negedge ARESETN) begin
        if (!ARESETN) begin
            state <= S_IDLE;
            address <= 0;
            beat_count <= 0;
            beats_sent <= 0;
            awvalid <= 1'b0;
            fetch_pending <= 1'b0;
            data_valid <= 1'b0;
            data_reg <= 0;
            response_error <= 1'b0;
        end else begin
            if (WR_FIFO_RE)
                fetch_pending <= 1'b1;

            if (fetch_pending && WR_FIFO_VALID) begin
                data_reg <= WR_FIFO_DATA;
                data_valid <= 1'b1;
                fetch_pending <= 1'b0;
            end

            case (state)
                S_IDLE: begin
                    awvalid <= 1'b0;
                    fetch_pending <= 1'b0;
                    data_valid <= 1'b0;
                    response_error <= 1'b0;
                    beats_sent <= 0;
                    if (WR_START && (WR_LEN != 0)) begin
                        address <= WR_ADRS;
                        beat_count <= WR_LEN[8:0];
                        awvalid <= 1'b1;
                        state <= S_SEND;
                    end
                end

                S_SEND: begin
                    if (awvalid && M_AXI_AWREADY)
                        awvalid <= 1'b0;

                    if (w_fire) begin
                        data_valid <= 1'b0;
                        if (last_beat) begin
                            fetch_pending <= 1'b0;
                            state <= S_RESP;
                        end else begin
                            beats_sent <= beats_sent + 1'b1;
                        end
                    end
                end

                S_RESP: begin
                    if (M_AXI_BVALID) begin
                        response_error <= M_AXI_BRESP != 2'b00;
                        state <= S_DONE;
                    end
                end

                S_DONE: state <= S_IDLE;
                default: state <= S_IDLE;
            endcase
        end
    end

    assign M_AXI_AWID = 0;
    assign M_AXI_AWADDR = address;
    assign M_AXI_AWLEN = beat_count[7:0] - 1'b1;
    assign M_AXI_AWSIZE = 3'b101;
    assign M_AXI_AWBURST = 2'b01;
    assign M_AXI_AWLOCK = 1'b0;
    assign M_AXI_AWCACHE = 4'b0010;
    assign M_AXI_AWPROT = 3'b000;
    assign M_AXI_AWQOS = AXI_QOS;
    assign M_AXI_AWUSER = 1'b0;
    assign M_AXI_AWVALID = awvalid;
    assign M_AXI_WDATA = data_reg;
    assign M_AXI_WSTRB = 32'hffff_ffff;
    assign M_AXI_WLAST = data_valid && last_beat;
    assign M_AXI_WUSER = 1'b0;
    assign M_AXI_WVALID = data_valid && (state == S_SEND) && !awvalid;
    assign M_AXI_BREADY = state == S_RESP;

    wire unused = &{1'b0, M_AXI_BID, M_AXI_BUSER, WR_FIFO_AEMPTY};
endmodule
