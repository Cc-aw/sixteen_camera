// Single-outstanding AXI4 error responder used before video MMIO exists.
// It accepts one write transaction or one read transaction and returns DECERR.
module axi4_mmio_error_slave (
    input  wire        aclk,
    input  wire        aresetn,

    input  wire [3:0]  s_awid,
    input  wire        s_awvalid,
    output wire        s_awready,
    input  wire        s_wvalid,
    input  wire        s_wlast,
    output wire        s_wready,
    output wire [3:0]  s_bid,
    output wire [1:0]  s_bresp,
    output wire        s_bvalid,
    input  wire        s_bready,

    input  wire [3:0]  s_arid,
    input  wire        s_arvalid,
    output wire        s_arready,
    output wire [3:0]  s_rid,
    output wire [63:0] s_rdata,
    output wire [1:0]  s_rresp,
    output wire        s_rlast,
    output wire        s_rvalid,
    input  wire        s_rready
);
    reg       aw_seen;
    reg       w_seen;
    reg       bvalid;
    reg [3:0] write_id;
    reg       rvalid;
    reg [3:0] read_id;

    assign s_awready = aresetn && !aw_seen && !bvalid;
    assign s_wready  = aresetn && !w_seen  && !bvalid;
    assign s_bid     = write_id;
    assign s_bresp   = 2'b11;
    assign s_bvalid  = bvalid;

    assign s_arready = aresetn && !rvalid;
    assign s_rid     = read_id;
    assign s_rdata   = 64'b0;
    assign s_rresp   = 2'b11;
    assign s_rlast   = 1'b1;
    assign s_rvalid  = rvalid;

    always @(posedge aclk) begin
        if (!aresetn) begin
            aw_seen  <= 1'b0;
            w_seen   <= 1'b0;
            bvalid   <= 1'b0;
            write_id <= 4'b0;
            rvalid   <= 1'b0;
            read_id  <= 4'b0;
        end else begin
            if (s_awready && s_awvalid) begin
                aw_seen  <= 1'b1;
                write_id <= s_awid;
            end
            if (s_wready && s_wvalid && s_wlast)
                w_seen <= 1'b1;

            if (!bvalid && (aw_seen || (s_awready && s_awvalid)) &&
                (w_seen || (s_wready && s_wvalid && s_wlast))) begin
                bvalid <= 1'b1;
                aw_seen <= 1'b0;
                w_seen <= 1'b0;
            end else if (bvalid && s_bready) begin
                bvalid <= 1'b0;
            end

            if (s_arready && s_arvalid) begin
                rvalid  <= 1'b1;
                read_id <= s_arid;
            end else if (rvalid && s_rready) begin
                rvalid <= 1'b0;
            end
        end
    end
endmodule
