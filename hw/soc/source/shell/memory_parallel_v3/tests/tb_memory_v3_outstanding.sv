`timescale 1ns/1ps

// Fill the DDR credits without any responses, send AW ahead of W, return
// responses out of order across IDs, and fence local Head traffic behind them.
module tb_memory_v3_outstanding #(
    parameter integer DEPTH = 32
);
    reg clk = 0, resetn = 0;
    always #5 clk = ~clk;
    axi4_if #(.ADDR_WIDTH(33), .DATA_WIDTH(512), .ID_WIDTH(2)) s();
    axi4_if #(.ADDR_WIDTH(33), .DATA_WIDTH(512), .ID_WIDTH(2)) d();
    wire local_ready, local_valid;
    wire [255:0] local_data;
    axi4_head_uram_router #(.DATA_WIDTH(512), .ID_WIDTH(2), .DDR_OUTSTANDING(DEPTH), .SLOT_BYTES(4096)) dut (
        .clk(clk), .resetn(resetn), .s_axi(s), .m_ddr_axi(d),
        .local_read_bank(3'd0), .local_read_req_valid(1'b0),
        .local_read_req_ready(local_ready), .local_read_req_word_addr(7'd0),
        .local_read_rsp_data(local_data), .local_read_rsp_valid(local_valid),
        .local_read_rsp_ready(1'b1)
    );

    integer aw_count = 0, ar_count = 0, w_count = 0, b_count = 0, r_count = 0;
    integer cycles = 0, first_ar = -1, last_ar = -1;
    reg [31:0] random_state = 32'h537ab9de;
    reg [511:0] stalled_rdata;
    reg [1:0] stalled_rid, stalled_bid;
    reg [1:0] stalled_rresp, stalled_bresp;
    reg stalled_rlast, was_r_stalled = 0, was_b_stalled = 0;
    // Independent W backpressure, including when many AWs are outstanding.
    assign d.wready = random_state[0] || random_state[5];

    function automatic [511:0] payload(input integer index, input integer beat);
        payload = {64{8'(index * 3 + beat + 1)}};
    endfunction

    always @(posedge clk) begin
        cycles <= cycles + 1;
        random_state <= {random_state[30:0], random_state[31] ^ random_state[21] ^ random_state[1] ^ random_state[0]};
        if (cycles > 20000) $fatal(1, "outstanding test timeout");
        if (resetn) begin
            if (d.awvalid && d.awready) begin
                if (d.awid !== 2'(aw_count) || d.awaddr !== 33'h10000000 + 33'(aw_count * 128) ||
                    d.awlen !== 1 || d.awsize !== 6 || d.awburst !== 1 ||
                    d.awcache !== 4'ha || d.awprot !== 3'h5 || d.awqos !== 4'h7)
                    $fatal(1, "DDR AW metadata/order changed index=%0d", aw_count);
                aw_count <= aw_count + 1;
            end
            if (d.arvalid && d.arready) begin
                if (d.arid !== 2'(ar_count) || d.araddr !== 33'h10010000 + 33'(ar_count * 128) ||
                    d.arlen !== 1 || d.arsize !== 6 || d.arburst !== 1 ||
                    d.arcache !== 4'hb || d.arprot !== 3'h3 || d.arqos !== 4'h9)
                    $fatal(1, "DDR AR metadata/order changed index=%0d", ar_count);
                if (ar_count == 0) first_ar <= cycles;
                if (ar_count == DEPTH - 1) last_ar <= cycles;
                ar_count <= ar_count + 1;
            end
            if (d.wvalid && d.wready) begin
                if (d.wdata !== payload(w_count / 2, w_count % 2) ||
                    d.wstrb !== (w_count % 2 ? 64'h5555555555555555 : 64'hffffffffffffffff) ||
                    d.wlast !== 1'(w_count % 2))
                    $fatal(1, "DDR W data/order changed beat=%0d", w_count);
                w_count <= w_count + 1;
            end
            if (d.bvalid && d.bready) begin
                if (!s.bvalid || s.bid !== d.bid || s.bresp !== d.bresp)
                    $fatal(1, "DDR B response lost or changed");
                b_count <= b_count + 1;
            end
            if (d.rvalid && d.rready) begin
                if (!s.rvalid || s.rid !== d.rid || s.rdata !== d.rdata ||
                    s.rresp !== d.rresp || s.rlast !== d.rlast)
                    $fatal(1, "DDR R response lost or changed");
                r_count <= r_count + 1;
            end
            if (was_r_stalled && (!s.rvalid || s.rdata !== stalled_rdata ||
                s.rid !== stalled_rid || s.rresp !== stalled_rresp || s.rlast !== stalled_rlast))
                $fatal(1, "R payload changed under backpressure");
            if (was_b_stalled && (!s.bvalid || s.bid !== stalled_bid || s.bresp !== stalled_bresp))
                $fatal(1, "B payload changed under backpressure");
            was_r_stalled <= s.rvalid && !s.rready;
            stalled_rdata <= s.rdata; stalled_rid <= s.rid;
            stalled_rresp <= s.rresp; stalled_rlast <= s.rlast;
            was_b_stalled <= s.bvalid && !s.bready;
            stalled_bid <= s.bid; stalled_bresp <= s.bresp;
        end else begin
            was_r_stalled <= 0; was_b_stalled <= 0;
        end
    end

    task automatic address_write(input integer index, input bit head = 0);
        @(negedge clk);
        s.awid = head ? 2'h0 : 2'(index);
        s.awaddr = head ? 33'h32000000 : 33'h10000000 + 33'(index * 128);
        s.awlen = head ? 0 : 1;
        s.awvalid = 1;
        do @(posedge clk); while (!s.awready);
        if (head && b_count != DEPTH + 1) $fatal(1, "Head AW overtook DDR B");
        @(negedge clk); s.awvalid = 0;
    endtask
    task automatic address_read(input integer index, input bit head = 0);
        @(negedge clk);
        s.arid = head ? 2'h0 : 2'(index);
        s.araddr = head ? 33'h32000000 : 33'h10010000 + 33'(index * 128);
        s.arlen = head ? 0 : 1;
        s.arvalid = 1;
        do @(posedge clk); while (!s.arready);
        if (head && r_count != 2 * (DEPTH + 1)) $fatal(1, "Head AR overtook DDR R");
        @(negedge clk); s.arvalid = 0;
    endtask
    task automatic write_data(input integer index);
        for (integer beat = 0; beat < 2; beat++) begin
            @(negedge clk);
            s.wvalid = 1; s.wdata = payload(index, beat);
            s.wstrb = beat ? 64'h5555555555555555 : 64'hffffffffffffffff; s.wlast = 1'(beat);
            do @(posedge clk); while (!s.wready);
        end
        @(negedge clk); s.wvalid = 0;
    endtask
    task automatic response_write(input integer index, input bit stall = 0);
        @(negedge clk);
        d.bid = 2'(index); d.bresp = 2'(index % 4); d.bvalid = 1;
        if (stall) begin
            repeat (4) @(negedge clk);
            if (!s.bvalid || d.bready) $fatal(1, "B backpressure ignored");
            s.bready = 1;
        end
        do @(posedge clk); while (!d.bready);
        @(negedge clk); d.bvalid = 0;
    endtask
    task automatic response_read(input integer index, input bit stall = 0);
        for (integer beat = 0; beat < 2; beat++) begin
            @(negedge clk);
            d.rid = 2'(index); d.rdata = payload(index, beat);
            d.rresp = 2'(index % 4); d.rlast = 1'(beat); d.rvalid = 1;
            if (stall && beat == 0) begin
                repeat (4) @(negedge clk);
                if (!s.rvalid || d.rready) $fatal(1, "R backpressure ignored");
                s.rready = 1;
            end
            do @(posedge clk); while (!d.rready);
        end
        @(negedge clk); d.rvalid = 0;
    endtask

    initial begin
        s.awvalid = 0; s.wvalid = 0; s.arvalid = 0; s.bready = 0; s.rready = 0;
        s.awid = 0; s.awaddr = 0; s.awlen = 0; s.awsize = 6; s.awburst = 1;
        s.awlock = 0; s.awcache = 4'ha; s.awprot = 5; s.awqos = 7;
        s.arid = 0; s.araddr = 0; s.arlen = 0; s.arsize = 6; s.arburst = 1;
        s.arlock = 0; s.arcache = 4'hb; s.arprot = 3; s.arqos = 9;
        s.wdata = 0; s.wstrb = 0; s.wlast = 0;
        d.awready = 1; d.arready = 1; d.bvalid = 0; d.bid = 0; d.bresp = 0;
        d.rvalid = 0; d.rid = 0; d.rdata = 0; d.rresp = 0; d.rlast = 0;
        repeat (5) @(negedge clk); resetn = 1;

        fork
            begin for (integer i = 0; i < DEPTH; i++) address_write(i); end
            begin for (integer i = 0; i < DEPTH; i++) address_read(i); end
        join
        if (aw_count != DEPTH || ar_count != DEPTH || b_count || r_count || w_count)
            $fatal(1, "Could not fill credits before W/R/B");
        for (integer i = 0; i < DEPTH; i++) write_data(i);

        // The next DDR request must wait for credit, even when W has drained.
        fork
            address_write(DEPTH);
            address_read(DEPTH);
            begin
                repeat (8) @(negedge clk);
                if (s.awready || s.arready || aw_count != DEPTH || ar_count != DEPTH)
                    $fatal(1, "Outstanding credit overflow");
                fork response_write(0, 1); response_read(0, 1); join
            end
        join
        write_data(DEPTH);

        // Reverse response order within each set of distinct IDs, preserving
        // AXI same-ID ordering when DEPTH=32 reuses all 4 IDs.
        fork
            address_write(0, 1);
            address_read(0, 1);
            begin
                repeat (5) @(negedge clk);
                if (s.awready || s.arready) $fatal(1, "Head did not drain DDR");
                for (integer group_base = 0; group_base < DEPTH; group_base += 4)
                    for (integer i = ((group_base + 4 < DEPTH) ? group_base + 3 : DEPTH - 1);
                         i >= group_base; i--)
                        if (i != 0) begin
                            fork response_write(i); response_read(i); join
                        end
                fork response_write(DEPTH); response_read(DEPTH); join
            end
        join
        // Read and write local Head directions can complete independently.
        @(negedge clk); s.wvalid = 1; s.wdata = '1; s.wstrb = '1; s.wlast = 1;
        do @(posedge clk); while (!s.wready);
        @(negedge clk); s.wvalid = 0;
        do @(posedge clk); while (!s.bvalid);
        if (s.bid != 0 || s.bresp != 0) $fatal(1, "Local Head B changed");
        // Head AR was accepted before the write: payload is intentionally not
        // checked here; the original test covers URAM data, strobes and errors.
        if (aw_count != DEPTH + 1 || ar_count != DEPTH + 1 ||
            w_count != 2 * (DEPTH + 1) || b_count != DEPTH + 1 || r_count != 2 * (DEPTH + 1))
            $fatal(1, "DDR counts mismatch or Head leaked to DDR");
        // Reset with an unanswered DDR read and an AW whose W has not begun.
        fork address_write(DEPTH + 1); address_read(DEPTH + 1); join
        @(negedge clk); resetn = 0;
        repeat (3) @(negedge clk); resetn = 1;
        repeat (2) @(negedge clk);
        if (!s.awready || !s.arready || s.bvalid || s.rvalid)
            $fatal(1, "Reset did not clear router credits/state");
        fork
            begin for (integer i = 0; i < DEPTH; i++) address_write(DEPTH + 2 + i); end
            begin for (integer i = 0; i < DEPTH; i++) address_read(DEPTH + 2 + i); end
        join
        if (aw_count != 2 * DEPTH + 2 || ar_count != 2 * DEPTH + 2 || s.awready || s.arready)
            $fatal(1, "Reset did not restore all DDR credits");
        $display("HEAD_ROUTER_OUTSTANDING=PASS depth=%0d DDR_requests=%0d AW_ahead_of_W=yes response_reordering=yes Head_drain=yes reset_inflight=yes", DEPTH, DEPTH + 1);
        $finish;
    end
endmodule
