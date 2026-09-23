`timescale 1ns/1ps

// The canonical two-pixel stream remains RGB888.  Only the display branch
// quantizes each pixel before its compact frame store.
module rgb888_to_rgb565 (
    input  wire [47:0] rgb888_pair,
    output wire [31:0] rgb565_pair
);
    assign rgb565_pair[15:0] = {
        rgb888_pair[23:19], rgb888_pair[15:10], rgb888_pair[7:3]
    };
    assign rgb565_pair[31:16] = {
        rgb888_pair[47:43], rgb888_pair[39:34], rgb888_pair[31:27]
    };
endmodule
