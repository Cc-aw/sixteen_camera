// Flat ports for independent synthesis/timing checks of the production reader.
module fbus_reader_synthesis_top (
    input wire clk, resetn, start,
    input wire [32:0] base_addr,
    input wire [31:0] byte_count,
    input wire [8:0] burst_limit,
    output wire busy, done, error,
    output wire [2:0] error_flags,
    output wire [319:0] statistics,
    output wire [255:0] stream_data,
    output wire [31:0] stream_keep,
    output wire stream_valid, stream_last,
    input wire stream_ready,
    output wire [4:0] arid,
    output wire [32:0] araddr,
    output wire [7:0] arlen,
    output wire [2:0] arsize,
    output wire arvalid,
    input wire arready,
    input wire [4:0] rid,
    input wire [255:0] rdata,
    input wire [1:0] rresp,
    input wire rlast, rvalid,
    output wire rready
);
    axi4_if #(.ADDR_WIDTH(33), .DATA_WIDTH(256), .ID_WIDTH(5)) axi();
    assign arid = axi.arid;
    assign araddr = axi.araddr;
    assign arlen = axi.arlen;
    assign arsize = axi.arsize;
    assign arvalid = axi.arvalid;
    assign axi.arready = arready;
    assign axi.rid = rid;
    assign axi.rdata = rdata;
    assign axi.rresp = rresp;
    assign axi.rlast = rlast;
    assign axi.rvalid = rvalid;
    assign rready = axi.rready;
    assign axi.awready = 0;
    assign axi.wready = 0;
    assign axi.bid = 0;
    assign axi.bresp = 0;
    assign axi.bvalid = 0;
    fbus_read_engine #(.READ_ID_COUNT(31)) reader (
        .clk(clk), .resetn(resetn), .start(start), .base_addr(base_addr),
        .byte_count(byte_count), .burst_beats_limit(burst_limit),
        .busy(busy), .done(done), .error(error), .error_flags(error_flags),
        .bytes_read(statistics[31:0]), .ar_requests(statistics[63:32]),
        .read_beats(statistics[95:64]), .active_cycles(statistics[127:96]),
        .ar_stall_cycles(statistics[159:128]), .r_wait_cycles(statistics[191:160]),
        .r_backpressure_cycles(statistics[223:192]),
        .max_outstanding_observed(statistics[255:224]),
        .max_reorder_occupancy(statistics[287:256]),
        .active_id_mask_observed(statistics[319:288]),
        .stream_data(stream_data), .stream_keep(stream_keep),
        .stream_valid(stream_valid), .stream_last(stream_last),
        .stream_ready(stream_ready), .m_axi(axi)
    );
endmodule
