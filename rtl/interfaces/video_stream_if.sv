`timescale 1ns/1ps

// Normalized internal video stream used after physical-input-specific logic.
// One transfer carries two RGB888 pixels in {pixel1, pixel0} order.
interface video_stream_if #(
    parameter integer DATA_WIDTH = 48,
    parameter integer STREAM_ID_WIDTH = 3,
    parameter integer FRAME_ID_WIDTH = 32
);
    logic                       aclk;
    logic                       aresetn;
    logic [DATA_WIDTH-1:0]      data;
    logic                       valid;
    logic                       ready;
    logic                       sof;
    logic                       eol;
    logic                       eof;
    logic [STREAM_ID_WIDTH-1:0] stream_id;
    logic [FRAME_ID_WIDTH-1:0]  frame_id;
    logic                       error;

    modport source (
        output aclk, aresetn, data, valid, sof, eol, eof,
               stream_id, frame_id, error,
        input  ready
    );

    modport sink (
        input  aclk, aresetn, data, valid, sof, eol, eof,
               stream_id, frame_id, error,
        output ready
    );
endinterface

