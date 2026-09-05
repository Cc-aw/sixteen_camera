`timescale 1ns/1ps

// Small dual-clock FIFO used by the FBus write bridge.  The producer and
// consumer each own their binary/Gray pointers; only Gray pointers cross the
// clock boundary.
module async_fifo #(
    parameter integer DATA_WIDTH = 8,
    parameter integer ADDR_WIDTH = 4
) (
    input  wire                  wclk,
    input  wire                  wresetn,
    input  wire [DATA_WIDTH-1:0] wdata,
    input  wire                  w_en,
    output wire                  w_full,

    input  wire                  rclk,
    input  wire                  rresetn,
    output wire [DATA_WIDTH-1:0] rdata,
    input  wire                  r_en,
    output wire                  r_empty
);
    localparam integer PTR_WIDTH = ADDR_WIDTH + 1;

    (* ram_style = "block" *) reg [DATA_WIDTH-1:0] mem [0:(1 << ADDR_WIDTH)-1];
    reg [PTR_WIDTH-1:0] wbin;
    reg [PTR_WIDTH-1:0] wgray;
    reg [PTR_WIDTH-1:0] rbin;
    reg [PTR_WIDTH-1:0] rgray;
    (* ASYNC_REG = "TRUE", SHREG_EXTRACT = "NO" *)
        reg [PTR_WIDTH-1:0] rgray_wsync1, rgray_wsync2;
    (* ASYNC_REG = "TRUE", SHREG_EXTRACT = "NO" *)
        reg [PTR_WIDTH-1:0] wgray_rsync1, wgray_rsync2;

    wire w_fire = w_en && !w_full;
    wire r_fire = r_en && !r_empty;
    wire [PTR_WIDTH-1:0] wbin_next =
        wbin + {{(PTR_WIDTH-1){1'b0}}, w_fire};
    wire [PTR_WIDTH-1:0] rbin_next =
        rbin + {{(PTR_WIDTH-1){1'b0}}, r_fire};
    wire [PTR_WIDTH-1:0] wgray_next = (wbin_next >> 1) ^ wbin_next;
    wire [PTR_WIDTH-1:0] rgray_next = (rbin_next >> 1) ^ rbin_next;
    wire [PTR_WIDTH-1:0] wfull_compare = {
        ~rgray_wsync2[PTR_WIDTH-1:PTR_WIDTH-2],
         rgray_wsync2[PTR_WIDTH-3:0]
    };

    reg wfull_q;
    reg rempty_q;

    assign w_full = wfull_q;
    assign r_empty = rempty_q;
    assign rdata = mem[rbin[ADDR_WIDTH-1:0]];

    always @(posedge wclk or negedge wresetn) begin
        if (!wresetn) begin
            wbin <= {PTR_WIDTH{1'b0}};
            wgray <= {PTR_WIDTH{1'b0}};
            rgray_wsync1 <= {PTR_WIDTH{1'b0}};
            rgray_wsync2 <= {PTR_WIDTH{1'b0}};
            wfull_q <= 1'b0;
        end else begin
            rgray_wsync1 <= rgray;
            rgray_wsync2 <= rgray_wsync1;
            if (w_fire)
                mem[wbin[ADDR_WIDTH-1:0]] <= wdata;
            wbin <= wbin_next;
            wgray <= wgray_next;
            wfull_q <= (wgray_next == wfull_compare);
        end
    end

    always @(posedge rclk or negedge rresetn) begin
        if (!rresetn) begin
            rbin <= {PTR_WIDTH{1'b0}};
            rgray <= {PTR_WIDTH{1'b0}};
            wgray_rsync1 <= {PTR_WIDTH{1'b0}};
            wgray_rsync2 <= {PTR_WIDTH{1'b0}};
            rempty_q <= 1'b1;
        end else begin
            wgray_rsync1 <= wgray;
            wgray_rsync2 <= wgray_rsync1;
            rbin <= rbin_next;
            rgray <= rgray_next;
            rempty_q <= (rgray_next == wgray_rsync2);
        end
    end
endmodule
