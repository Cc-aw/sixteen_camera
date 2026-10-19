`timescale 1ns/1ps
module tb_hole_port;
    parameter [29:0] BASE = 30'h20000000;
    reg clock = 0, reset = 1, valid = 0, ready = 0, clear = 0;
    reg [2:0] opcode = 4;
    reg [29:0] address = BASE;
    wire a_ready, d_valid, denied, corrupt, operation;
    wire [2:0] d_opcode, d_size;
    wire [5:0] source;
    wire [255:0] data;
    wire [6:0] outstanding;
    wire [63:0] accepted, retired, gets, puts, partials, reads, writes, errors;
    integer cases = 0;
    always #5 clock = ~clock;
    `DUT dut (
        .clock(clock), .reset(reset), .io_clear(clear),
        .io_a_valid(valid), .io_a_ready(a_ready), .io_a_bits_opcode(opcode),
        .io_a_bits_param(3'd0), .io_a_bits_size(3'd3), .io_a_bits_source(6'd31),
        .io_a_bits_address(address), .io_a_bits_mask(32'hff << address[4:0]),
        .io_a_bits_data(256'h1234), .io_a_bits_corrupt(1'b0),
        .io_d_ready(ready), .io_d_valid(d_valid), .io_d_bits_opcode(d_opcode),
        .io_d_bits_size(d_size), .io_d_bits_source(source),
        .io_d_bits_denied(denied), .io_d_bits_corrupt(corrupt), .io_d_bits_data(data),
        .io_operation_ready(1'b1), .io_operation_valid(operation), .io_read(256'h1234),
        .io_counters_0(accepted), .io_counters_1(retired), .io_counters_2(gets),
        .io_counters_3(puts), .io_counters_4(partials), .io_counters_12(reads),
        .io_counters_13(writes), .io_counters_15(errors), .io_outstanding(outstanding)
    );
    task trial(input [29:0] addr, input bit store, input bit reject);
        begin
            @(negedge clock); clear = 1;
            @(negedge clock); clear = 0; address = addr; opcode = store ? 0 : 4; valid = 1;
            do @(posedge clock); while (!a_ready);
            @(negedge clock); valid = 0;
            while (!d_valid) @(negedge clock);
            repeat (3) begin
                if (d_valid !== 1 || denied !== reject || corrupt !== (reject && !store) ||
                    source !== 31 || d_size !== 3 || d_opcode !== (store ? 0 : 1))
                    $fatal(1, "bad D response addr=%h store=%0d reject=%0d", addr, store, reject);
                if (!store && data !== (reject ? 256'h0 : 256'h1234)) $fatal(1, "bad read data");
                @(negedge clock);
            end
            ready = 1;
            @(negedge clock); ready = 0;
            repeat (3) @(negedge clock);
            if (accepted !== 1 || retired !== 1 || gets !== !store || puts !== store ||
                partials !== 0 || outstanding !== 0 || errors !== reject ||
                reads !== (!reject && !store) || writes !== (!reject && store))
                $fatal(1, "bad counters addr=%h accepted=%0d retired=%0d denied=%0d reads=%0d writes=%0d",
                       addr, accepted, retired, errors, reads, writes);
            cases = cases + 1;
        end
    endtask
    initial begin
        repeat (4) @(negedge clock);
        reset = 0;
        // Last valid aligned 8-byte access, then the two board-test holes.
        trial(BASE + 30'h23fff8, 0, 0);
        trial(BASE + 30'h23fff8, 1, 0);
        trial(BASE + 30'h240000, 0, 1);
        trial(BASE + 30'h240000, 1, 1);
        trial(BASE + 30'h3ffff8, 0, 1);
        trial(BASE + 30'h3ffff8, 1, 1);
        $display("FROZEN_HOLE_PORT_PASS base=%h cases=%0d denied=4", BASE, cases);
        $finish;
    end
    initial begin
        #100000;
        $fatal(1, "timeout");
    end
endmodule
