`timescale 1ns/1ps

// One Head payload slot. Port A is reserved for the future SoC AXI write
// router; port B is a local, one-response-deep read port. No storage bit is
// reset. The A/B ownership protocol guarantees that software never writes a
// slot while the postprocessor reads it.
module head_uram_store #(
    parameter integer DATA_WIDTH = 256,
    parameter integer SLOT_BYTES = 1024 * 1024
) (
    input  wire                         clk,
    input  wire                         resetn,

    input  wire                         write_valid,
    output wire                         write_ready,
    input  wire [$clog2(SLOT_BYTES)-1:0] write_addr,
    input  wire [DATA_WIDTH-1:0]        write_data,
    input  wire [DATA_WIDTH/8-1:0]      write_strb,

    input  wire                         read_req_valid,
    output wire                         read_req_ready,
    input  wire [$clog2(SLOT_BYTES/(DATA_WIDTH/8))-1:0] read_req_word_addr,
    output wire [DATA_WIDTH-1:0]        read_rsp_data,
    output wire                         read_rsp_valid,
    input  wire                         read_rsp_ready
);
    localparam integer BYTE_LANES = DATA_WIDTH / 8;
    localparam integer BYTE_SHIFT = $clog2(BYTE_LANES);
    localparam integer DEPTH = SLOT_BYTES / BYTE_LANES;

    // Vivado maps the production 256-bit x 32768 instance to UltraRAM. The
    // byte lanes preserve AXI WSTRB semantics for P2, including partial beats.
    (* ram_style = "ultra" *) reg [DATA_WIDTH-1:0] memory [0:DEPTH-1];
    reg [DATA_WIDTH-1:0] read_data_q;
    reg read_valid_q;

    wire write_fire = write_valid && write_ready;
    wire read_fire = read_req_valid && read_req_ready;
    wire [$clog2(DEPTH)-1:0] write_word_addr =
        write_addr[$clog2(SLOT_BYTES)-1:BYTE_SHIFT];

    assign write_ready = 1'b1;
    assign read_req_ready = !read_valid_q || read_rsp_ready;
    assign read_rsp_data = read_data_q;
    assign read_rsp_valid = read_valid_q;

    initial begin
        if (DATA_WIDTH < 8 || (DATA_WIDTH & (DATA_WIDTH - 1)) != 0 ||
            (DATA_WIDTH % 8) != 0 || SLOT_BYTES < BYTE_LANES ||
            (SLOT_BYTES & (SLOT_BYTES - 1)) != 0 ||
            (SLOT_BYTES % BYTE_LANES) != 0)
            $error("head_uram_store parameters are invalid");
    end

    integer lane;
    always @(posedge clk) begin
        if (write_fire)
            for (lane = 0; lane < BYTE_LANES; lane = lane + 1)
                if (write_strb[lane])
                    memory[write_word_addr][lane*8 +: 8] <=
                        write_data[lane*8 +: 8];
    end

    // Keep the memory data output in a reset-free process. UltraRAM has no
    // reset for its array/output path; mixing this assignment into the valid
    // flag's reset process makes Vivado reject UltraRAM inference.
    always @(posedge clk) begin
        if (read_fire)
            read_data_q <= memory[read_req_word_addr];
    end

    // A consumed response may be replaced in the same cycle, allowing one
    // local 256-bit beat per clock.
    always @(posedge clk or negedge resetn) begin
        if (!resetn)
            read_valid_q <= 1'b0;
        else if (read_fire)
            read_valid_q <= 1'b1;
        else if (read_rsp_ready)
            read_valid_q <= 1'b0;
    end
endmodule
