`timescale 1ns/1ps

module rgb565_to_rgb888 (
    input  wire [31:0] rgb565_pair,
    output wire [47:0] rgb888_pair
);
    function automatic [23:0] expand(input [15:0] pixel);
        expand = {
            pixel[15:11], pixel[15:13],
            pixel[10:5], pixel[10:9],
            pixel[4:0], pixel[4:2]
        };
    endfunction
    assign rgb888_pair = {expand(rgb565_pair[31:16]),
                          expand(rgb565_pair[15:0])};
endmodule
