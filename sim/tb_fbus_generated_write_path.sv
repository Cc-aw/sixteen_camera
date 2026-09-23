`timescale 1ns/1ps

// Write-throughput model for the actual generated FBus AXI4Fragmenter and
// AXI4ToTL path.  The responder models one delayed PutAck per 64-byte TL
// request, which exposes how AXI burst length interacts with the two TL
// write-source tags available under each AXI ID.
module tb_fbus_generated_write_path #(
    parameter integer BYTES = 262144,
    parameter integer MEMORY_LATENCY = 160,
    parameter integer AXI_ID_WIDTH = 5,
    parameter integer FIRST_WRITE_ID = 24,
    parameter integer WRITE_ID_COUNT = 8,
    parameter integer MEMORY_DATA_WIDTH = 256
);
    reg clk = 0;
    reg resetn = 0;
    always #5 clk = ~clk;

    axi4_if #(.ADDR_WIDTH(33), .DATA_WIDTH(256),
              .ID_WIDTH(AXI_ID_WIDTH)) axi();
    axi4_if #(.ADDR_WIDTH(32), .DATA_WIDTH(256), .ID_WIDTH(3)) source_axi();
    wire [31:0] bridge_w_stall;

    axi4_write_cdc #(
        .FIFO_ADDR_WIDTH(5), .FBUS_WRITE_ID(FIRST_WRITE_ID),
        .FBUS_WRITE_ID_COUNT(WRITE_ID_COUNT)
    ) write_cdc (
        .s_axi(source_axi), .m_clk(clk), .m_resetn(resetn), .m_axi(axi),
        .perf_aw_count(), .perf_w_count(), .perf_b_count(),
        .perf_aw_stall_cycles(), .perf_w_stall_cycles(bridge_w_stall),
        .perf_b_stall_cycles(), .perf_outstanding_current(),
        .perf_outstanding_max(), .perf_write_id_mask(),
        .perf_protocol_errors()
    );

    reg [8:0] burst_beats;
    reg [31:0] bytes_issued;
    reg [31:0] bytes_completed;
    reg [8:0] w_index;
    reg [7:0] outstanding;
    reg aw_active;
    reg w_active;
    integer active_cycles;
    integer w_stall_cycles;
    integer b_count;

    wire [8:0] this_burst_beats =
        BYTES-bytes_issued < burst_beats*32 ?
        9'((BYTES-bytes_issued)/32) : burst_beats;
    wire aw_fire = source_axi.awvalid && source_axi.awready;
    wire w_fire = source_axi.wvalid && source_axi.wready;
    wire b_fire = source_axi.bvalid && source_axi.bready;
    wire done = bytes_completed == BYTES;

    assign source_axi.aclk = clk;
    assign source_axi.aresetn = resetn;
    assign source_axi.awid = 3'd0;
    assign source_axi.awaddr = 32'h3000_0000 + bytes_issued;
    assign source_axi.awlen = this_burst_beats[7:0] - 1'b1;
    assign source_axi.awsize = 3'd5;
    assign source_axi.awburst = 2'b01;
    assign source_axi.awlock = 1'b0;
    assign source_axi.awcache = 4'b0010;
    assign source_axi.awprot = 3'b000;
    assign source_axi.awqos = 4'h6;
    assign source_axi.awvalid = aw_active && bytes_issued < BYTES &&
                                outstanding < 8'(WRITE_ID_COUNT);
    assign source_axi.wdata =
        {8{bytes_issued + {18'd0, w_index, 5'd0}}};
    assign source_axi.wstrb = 32'hffff_ffff;
    assign source_axi.wlast = w_index + 1'b1 == this_burst_beats;
    assign source_axi.wvalid = w_active;
    assign source_axi.bready = 1'b1;
    assign source_axi.arid = '0;
    assign source_axi.araddr = '0;
    assign source_axi.arlen = '0;
    assign source_axi.arsize = '0;
    assign source_axi.arburst = '0;
    assign source_axi.arlock = '0;
    assign source_axi.arcache = '0;
    assign source_axi.arprot = '0;
    assign source_axi.arqos = '0;
    assign source_axi.arvalid = 1'b0;
    assign source_axi.rready = 1'b0;

    always @(posedge clk) begin
        if (!resetn) begin
            bytes_issued <= 0;
            bytes_completed <= 0;
            w_index <= 0;
            outstanding <= 0;
            aw_active <= 1'b1;
            w_active <= 1'b0;
            active_cycles <= 0;
            w_stall_cycles <= 0;
            b_count <= 0;
        end else begin
            if (!done)
                active_cycles <= active_cycles + 1;
            if (source_axi.wvalid && !source_axi.wready)
                w_stall_cycles <= w_stall_cycles + 1;
            if (aw_fire) begin
                aw_active <= 1'b0;
                w_active <= 1'b1;
            end
            if (w_fire) begin
                if (source_axi.wlast) begin
                    bytes_issued <= bytes_issued + this_burst_beats*32;
                    w_index <= 0;
                    w_active <= 1'b0;
                    aw_active <= 1'b1;
                end else begin
                    w_index <= w_index + 1'b1;
                end
            end
            if (b_fire) begin
                if (source_axi.bresp != 0 || source_axi.bid != 0)
                    $fatal(1, "bad source write response id=%0d resp=%0d",
                           source_axi.bid, source_axi.bresp);
                bytes_completed <= bytes_completed + burst_beats*32;
                b_count <= b_count + 1;
            end
            case ({aw_fire, b_fire})
                2'b10: outstanding <= outstanding + 1'b1;
                2'b01: outstanding <= outstanding - 1'b1;
                default: ;
            endcase
        end
    end

    wire a_valid;
    wire a_ready;
    wire [2:0] a_opcode;
    wire [3:0] a_size;
    wire [6:0] a_source;
    wire [32:0] a_address;
    wire d_ready;
    reg d_valid;
    reg [6:0] d_source;
    reg [127:0] pending;
    integer due [0:127];
    integer tick;
    integer put_beat;
    integer selected;
    integer peak_pending;

    assign a_ready = !pending[a_source];
    fbus_generated_wrapper coupling (
        .clk(clk), .resetn(resetn), .axi(axi),
        .a_valid(a_valid), .a_ready(a_ready), .a_opcode(a_opcode),
        .a_size(a_size), .a_source(a_source), .a_address(a_address),
        .d_ready(d_ready), .d_valid(d_valid), .d_opcode(3'd0),
        .d_source(d_source), .d_data('0)
    );

    integer candidate;
    always @* begin
        candidate = -1;
        for (integer source = 0; source < 128; source++) begin
            if (pending[source] && due[source] <= tick && candidate < 0)
                candidate = source;
        end
    end

    always @(posedge clk) begin
        if (!resetn) begin
            pending <= 0;
            tick <= 0;
            put_beat <= 0;
            selected <= -1;
            d_valid <= 0;
            d_source <= 0;
            peak_pending <= 0;
        end else begin
            tick <= tick + 1;
            if ($countones(pending) > peak_pending)
                peak_pending <= $countones(pending);
            if (a_valid && a_ready) begin
                if ((a_opcode != 0 && a_opcode != 1) || a_size != 6)
                    $fatal(1, "expected 64-byte Put opcode=%0d size=%0d",
                           a_opcode, a_size);
                if (put_beat == 64/(MEMORY_DATA_WIDTH/8)-1) begin
                    put_beat <= 0;
                    pending[a_source] <= 1'b1;
                    due[a_source] <= tick + MEMORY_LATENCY;
                end else begin
                    put_beat <= put_beat + 1;
                end
            end
            if (!d_valid && candidate >= 0) begin
                selected <= candidate;
                d_source <= 7'(candidate);
                d_valid <= 1'b1;
            end else if (d_valid && d_ready) begin
                pending[selected] <= 1'b0;
                selected <= -1;
                d_valid <= 1'b0;
            end
        end
    end

    integer cycles64, cycles16, cycles4, cycles2;
    integer stall64, stall16, stall4, stall2;
    integer peak64, peak16, peak4, peak2;
    integer bridge_stall64, bridge_stall16, bridge_stall4, bridge_stall2;
    task automatic run_case(input integer beats);
        begin
            resetn = 0;
            burst_beats = 9'(beats);
            repeat (8) @(negedge clk);
            resetn = 1;
            wait(done);
            repeat (4) @(negedge clk);
            $display("FBUS_WRITE burst_beats=%0d cycles=%0d source_wstall=%0d bridge_wstall=%0d peak_TL=%0d MBps_at_100MHz=%0d",
                     beats, active_cycles, w_stall_cycles, bridge_w_stall,
                     peak_pending, BYTES*100/active_cycles);
            case (beats)
                64: begin cycles64 = active_cycles; stall64 = w_stall_cycles;
                          bridge_stall64 = bridge_w_stall;
                          peak64 = peak_pending; end
                16: begin cycles16 = active_cycles; stall16 = w_stall_cycles;
                          bridge_stall16 = bridge_w_stall;
                          peak16 = peak_pending; end
                4:  begin cycles4 = active_cycles; stall4 = w_stall_cycles;
                          bridge_stall4 = bridge_w_stall;
                          peak4 = peak_pending; end
                default: begin cycles2 = active_cycles; stall2 = w_stall_cycles;
                               bridge_stall2 = bridge_w_stall;
                               peak2 = peak_pending; end
            endcase
        end
    endtask

    initial begin
        run_case(64);
        run_case(16);
        run_case(4);
        run_case(2);
        if (cycles2 >= cycles4 || cycles2 >= cycles16 ||
            cycles2 >= cycles64 || bridge_stall2 >= bridge_stall4 ||
            peak2 < WRITE_ID_COUNT)
            $fatal(1, "short-burst FBus concurrency was not demonstrated");
        $display("TB_FBUS_GENERATED_WRITE_PATH=PASS");
        $finish;
    end

    initial begin
        #200000000;
        $fatal(1, "timeout");
    end
endmodule
