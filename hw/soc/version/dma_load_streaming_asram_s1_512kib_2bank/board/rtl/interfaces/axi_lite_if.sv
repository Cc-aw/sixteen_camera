`timescale 1ns/1ps

interface axi_lite_if #(
    parameter integer ADDR_WIDTH = 16
);
    logic                  aclk;
    logic                  aresetn;
    logic [ADDR_WIDTH-1:0] awaddr;
    logic [2:0]            awprot;
    logic                  awvalid;
    logic                  awready;
    logic [31:0]           wdata;
    logic [3:0]            wstrb;
    logic                  wvalid;
    logic                  wready;
    logic [1:0]            bresp;
    logic                  bvalid;
    logic                  bready;
    logic [ADDR_WIDTH-1:0] araddr;
    logic [2:0]            arprot;
    logic                  arvalid;
    logic                  arready;
    logic [31:0]           rdata;
    logic [1:0]            rresp;
    logic                  rvalid;
    logic                  rready;

    modport master (
        output aclk, aresetn, awaddr, awprot, awvalid,
        input  awready,
        output wdata, wstrb, wvalid,
        input  wready, bresp, bvalid,
        output bready, araddr, arprot, arvalid,
        input  arready, rdata, rresp, rvalid,
        output rready
    );

    modport slave (
        input  aclk, aresetn, awaddr, awprot, awvalid,
        output awready,
        input  wdata, wstrb, wvalid,
        output wready, bresp, bvalid,
        input  bready, araddr, arprot, arvalid,
        output arready, rdata, rresp, rvalid,
        input  rready
    );
endinterface
