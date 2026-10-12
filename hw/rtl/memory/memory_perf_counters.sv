`timescale 1ns/1ps

// Read-only observations. Event/control staging is aligned, and no counter
// influences the monitored channel's ready/valid handshake.
module memory_perf_counter_bank #(
    parameter [31:0] PEAK_MASK = 0
) (
    input wire clk, resetn,
    input wire command_valid,
    input wire [2:0] command,
    input wire [511:0] events,
    input wire [4:0] index,
    output wire [63:0] data,
    output wire [2047:0] frozen_flat
);
    reg enabled;
    reg [63:0] timestamp;
    reg command_valid_q;
    reg [2:0] command_q;
    reg [511:0] events_q;
    reg [63:0] live [0:31];
    reg [63:0] frozen [0:31];
    assign data = frozen[index];
    always @(posedge clk) begin
        if(!resetn) timestamp <= 0;
        else timestamp <= timestamp + 1'b1;
    end
    for (genvar n=0; n<32; n=n+1) begin: g_counter
        assign frozen_flat[n*64 +: 64] = frozen[n];
        always @(posedge clk) begin
            if (!resetn) begin live[n] <= 0; frozen[n] <= 0; end
            else begin
                if (enabled) begin
                    if (PEAK_MASK[n]) begin
                        if ({48'd0, events_q[n*16 +: 16]} > live[n])
                            live[n] <= {48'd0, events_q[n*16 +: 16]};
                    end else live[n] <= live[n] + {48'd0, events_q[n*16 +: 16]};
                end
                if (command_valid_q && command_q == 4) frozen[n] <= (n == 31) ? timestamp : live[n];
                if (command_valid_q && command_q == 3) begin live[n] <= 0; frozen[n] <= 0; end
            end
        end
    end
    always @(posedge clk) begin
        if (!resetn) begin
            enabled <= 0; command_valid_q <= 0; command_q <= 0; events_q <= 0;
        end else begin
            command_valid_q <= command_valid;
            command_q <= command;
            events_q <= events;
            if (command_valid_q && command_q == 1) enabled <= 1;
            if (command_valid_q && (command_q == 2 || command_q == 3)) enabled <= 0;
        end
    end
endmodule

// Transaction credit tracking is independent of measurement control. Clearing
// statistics never discards outstanding AR/AW obligations. Read bytes count
// AR-requested bytes; R occupied bytes separately count bus lanes transferred.
module memory_perf_axi_events #(
    parameter integer DATA_BYTES = 64
) (
    input wire clk, resetn,
    input wire arvalid, arready, awvalid, awready,
    input wire rvalid, rready, rlast, wvalid, wready, bvalid, bready,
    input wire [7:0] arlen,
    input wire [2:0] arsize,
    input wire [DATA_BYTES-1:0] wstrb,
    output reg [511:0] events
);
    reg [15:0] reads, writes;
    wire ar = arvalid && arready;
    wire aw = awvalid && awready;
    wire rd = rvalid && rready;
    wire wd = wvalid && wready;
    wire b = bvalid && bready;
    wire done = rd && rlast;
    reg [15:0] strobes;
    always @* begin
        strobes = 0;
        for (integer n=0; n<DATA_BYTES; n=n+1) strobes = strobes + {15'd0, wstrb[n]};
        events = 0;
        events[0*16 +:16] = 1;
        events[1*16 +:16] = {15'd0, ar};
        events[2*16 +:16] = {15'd0, aw};
        events[3*16 +:16] = {15'd0, rd};
        events[4*16 +:16] = {15'd0, wd};
        events[5*16 +:16] = {15'd0, b};
        events[6*16 +:16] = ar ? (({8'd0, arlen} + 16'd1) << arsize) : 0;
        events[7*16 +:16] = wd ? strobes : 0;
        events[8*16 +:16] = {15'd0, arvalid && !arready};
        events[9*16 +:16] = {15'd0, awvalid && !awready};
        events[10*16+:16] = {15'd0, rvalid && !rready};
        events[11*16+:16] = {15'd0, wvalid && !wready};
        events[12*16+:16] = {15'd0, bvalid && !bready};
        events[13*16+:16] = reads;
        events[14*16+:16] = writes;
        events[15*16+:16] = reads;
        events[16*16+:16] = writes;
        events[17*16+:16] = {15'd0, done};
        events[18*16+:16] = rd ? 16'(DATA_BYTES) : 0;
    end
    always @(posedge clk) begin
        if (!resetn) begin reads <= 0; writes <= 0; end
        else begin
            case ({ar, done})
                2'b10: reads <= reads + 1'b1;
                2'b01: reads <= reads - 1'b1;
                default: ;
            endcase
            case ({aw, b})
                2'b10: writes <= writes + 1'b1;
                2'b01: writes <= writes - 1'b1;
                default: ;
            endcase
        end
    end
endmodule

// Bundled-data mailbox. Source snapshots are held until the next command.
// The acknowledgement traverses two flops AFTER the snapshot is frozen; the
// destination then captures the entire stable payload before returning ack.
// The reset input is common assertion, independently synchronous deassertion.
module memory_perf_async_group #(
    parameter integer BANKS = 3
) (
    input wire dst_clk, src_clk, resetn,
    input wire request,
    input wire [2:0] command,
    input wire [BANKS*512-1:0] events,
    output reg acknowledge,
    output wire available,
    output reg [BANKS*2048-1:0] snapshots
);
    (* ASYNC_REG="TRUE", SHREG_EXTRACT="NO" *) reg [2:0] src_reset, dst_reset;
    (* ASYNC_REG="TRUE", SHREG_EXTRACT="NO" *) reg [1:0] req_sync, ack_sync, up_sync;
    reg source_ack, source_up;
    reg [2:0] delay_q;
    wire [BANKS*2048-1:0] source_frozen;
    wire source_command = (req_sync[1] != source_ack) && delay_q == 0;
    assign available = up_sync[1] && dst_reset[2];
    always @(posedge src_clk or negedge resetn)
        if (!resetn) src_reset <= 0; else src_reset <= {src_reset[1:0], 1'b1};
    always @(posedge dst_clk or negedge resetn)
        if (!resetn) dst_reset <= 0; else dst_reset <= {dst_reset[1:0], 1'b1};
    always @(posedge src_clk) begin
        if (!src_reset[2]) begin req_sync <= 0; source_ack <= 0; delay_q <= 0; source_up <= 0; end
        else begin
            source_up <= 1;
            req_sync <= {req_sync[0], request};
            if (source_command) delay_q <= 3;
            else if (delay_q != 0) begin
                delay_q <= delay_q - 1'b1;
                if (delay_q == 1) source_ack <= req_sync[1];
            end
        end
    end
    for(genvar n=0; n<BANKS; n=n+1) begin: g_bank
        memory_perf_counter_bank #(.PEAK_MASK(32'h00018000)) u_counter (
            .clk(src_clk), .resetn(src_reset[2]), .command_valid(source_command), .command(command),
            .events(events[n*512 +:512]), .index(5'd0), .data(),
            .frozen_flat(source_frozen[n*2048 +:2048])
        );
    end
    always @(posedge dst_clk) begin
        if (!dst_reset[2]) begin ack_sync <= 0; up_sync <= 0; acknowledge <= 0; snapshots <= 0; end
        else begin
            ack_sync <= {ack_sync[0], source_ack};
            up_sync <= {up_sync[0], source_up};
            if (ack_sync[1] != acknowledge) begin
                snapshots <= source_frozen;
                acknowledge <= ack_sync[1];
            end
        end
    end
endmodule
