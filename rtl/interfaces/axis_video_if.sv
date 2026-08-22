`timescale 1ns/1ps

interface axis_video_if #(
    parameter integer DATA_WIDTH = 48
);
    logic                  aclk;
    logic                  aresetn;
    logic [DATA_WIDTH-1:0] tdata;
    logic                  tvalid;
    logic                  tready;
    logic                  tuser;
    logic                  tlast;

    modport source (
        output aclk, aresetn, tdata, tvalid, tuser, tlast,
        input  tready
    );

    modport sink (
        input  aclk, aresetn, tdata, tvalid, tuser, tlast,
        output tready
    );
endinterface
