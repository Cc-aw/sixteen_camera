`timescale 1ns/1ps

// Video-domain DDR access ports.  Frame-store write/read protocol remains in
// the video data plane; this module owns only the crossings into the MIG UI
// clock and the unused halves of the split S01 AXI port.
module video_memory_ports (
    axi4_if.slave  writer_video_axi,
    axi4_if.slave  reader_video_axi,
    input wire     ui_clk,
    input wire     ui_resetn,
    axi4_if.master writer_ui_axi,
    axi4_if.master reader_ui_axi
);
    axi4_ui_write_cdc u_writer_ui_cdc (
        .s_axi(writer_video_axi), .ui_clk(ui_clk),
        .ui_resetn(ui_resetn), .m_axi(writer_ui_axi)
    );

    axi4_ui_read_cdc u_reader_ui_cdc (
        .s_axi(reader_video_axi), .ui_clk(ui_clk),
        .ui_resetn(ui_resetn), .m_axi(reader_ui_axi)
    );

    // S01 is deliberately split by AXI channel: capture is write-only and
    // display is read-only.  Terminate the unused return/request channels so
    // each interface keeps exactly one driver.
    assign writer_ui_axi.arready = 1'b0;
    assign writer_ui_axi.rid = 3'd0;
    assign writer_ui_axi.rdata = 256'd0;
    assign writer_ui_axi.rresp = 2'b00;
    assign writer_ui_axi.rlast = 1'b0;
    assign writer_ui_axi.rvalid = 1'b0;

    assign reader_ui_axi.awready = 1'b0;
    assign reader_ui_axi.wready = 1'b0;
    assign reader_ui_axi.bid = 3'd0;
    assign reader_ui_axi.bresp = 2'b00;
    assign reader_ui_axi.bvalid = 1'b0;
endmodule
