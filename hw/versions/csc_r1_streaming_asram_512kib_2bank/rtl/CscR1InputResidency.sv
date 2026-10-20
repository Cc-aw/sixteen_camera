// Experimental C1a: two physical-half descriptors, no data SRAM or remapping.
// The integration supplies an exact, unhashed input-generator key. A miss
// executes the original generator. A hit executes its existing null-operand
// completion lifecycle, without creating a DMA tag or synthetic DMA credit.
// Its original load configuration command still follows the normal RS path.
module CscR1InputResidency #(
    parameter integer KEY_WIDTH = 232
)(
    input wire clock, reset, enabled, clear, fault, core_idle, quiescent,
    input wire passthrough,
    input wire req_valid, engine_ready, req_supported, req_preserves, req_half,
    input wire [KEY_WIDTH-1:0] req_key,
    input wire [14:0] req_rows,
    input wire [39:0] req_source,
    input wire [40:0] req_source_end,
    input wire generator_idle, generator_half,
    input wire [7:0] write_valid, write_input,
    input wire [111:0] write_rows,
    input wire source_write,
    input wire [39:0] source_write_address,
    input wire [6:0] source_write_bytes,
    output wire req_ready, hit, wait_for_commit,
    output wire accepted, skipped,
    output wire completion,
    output wire [1:0] resident_valid,
    output wire [1:0] resident_building,
    output wire [63:0] resident_owner,
    output reg [31:0] engine_owner
);
    reg [1:0] valid, building, generated;
    reg [KEY_WIDTH-1:0] keys [0:1];
    reg [14:0] rows [0:1];
    reg [39:0] sources [0:1];
    reg [40:0] source_ends [0:1];
    reg [31:0] owners [0:1];
    reg [31:0] next_owner;
    reg quarantined, faulted, previous_enabled;
    reg skip_pending, skip_half;
    wire [40:0] write_end = {1'b0, source_write_address} + {34'd0, source_write_bytes};
    reg [1:0] invalidated;
    always @* begin
        invalidated = 0;
        for (integer s = 0; s < 2; s = s + 1) begin
            if (source_write && {1'b0, source_write_address} < source_ends[s] &&
                    write_end > {1'b0, sources[s]}) invalidated[s] = 1;
            for (integer w = 0; w < 8; w = w + 1) begin
                if (write_valid[w] && write_rows[w*14+13] == (s != 0) &&
                        {2'b0, write_rows[w*14+:13]} < rows[s] &&
                        (valid[s] || !write_input[w])) invalidated[s] = 1;
            end
        end
    end
    wire usable = enabled && previous_enabled && !clear && !fault && !faulted &&
                  !passthrough && !quarantined;
    wire matching = usable && req_supported && (valid[req_half] || building[req_half]) &&
                    keys[req_half] == req_key && rows[req_half] == req_rows &&
                    sources[req_half] == req_source && source_ends[req_half] == req_source_end &&
                    !invalidated[req_half];
    assign wait_for_commit = matching && (!valid[req_half] || !quiescent);
    assign req_ready = engine_ready && !wait_for_commit;
    assign hit = matching && valid[req_half] && quiescent;
    assign accepted = req_valid && req_ready;
    assign skipped = accepted && hit;
    assign completion = skip_pending && generator_idle && generator_half == skip_half;
    assign resident_valid = valid;
    assign resident_building = building;
    assign resident_owner = {owners[1], owners[0]};
    always @(posedge clock) begin
        if (reset) begin
            valid <= 0;
            building <= 0;
            generated <= 0;
            quarantined <= 0;
            faulted <= 0;
            previous_enabled <= 0;
            skip_pending <= 0;
            skip_half <= 0;
            next_owner <= 1;
            engine_owner <= 0;
            owners[0] <= 0;
            owners[1] <= 0;
        end else begin
            previous_enabled <= enabled;
            if (core_idle && quiescent) quarantined <= 0;
            if (completion) skip_pending <= 0;
            if (skipped) begin
                skip_pending <= 1;
                skip_half <= req_half;
            end
            if (accepted) begin
                engine_owner <= next_owner;
                if (next_owner != 32'hffffffff) next_owner <= next_owner + 1;
                else faulted <= 1; // Never reuse an in-flight writer generation.
            end
            for (integer s = 0; s < 2; s = s + 1) begin
                if (building[s] && generator_idle && generator_half == (s != 0))
                    generated[s] <= 1;
                if (building[s] && generated[s] && quiescent) begin
                    valid[s] <= 1;
                    building[s] <= 0;
                end
                // A real new tile replaces this half even if unsupported.
                // Native null operands preserve the original resident bytes.
                if (accepted && !hit && !req_preserves && req_half == (s != 0)) begin
                    valid[s] <= 0;
                    building[s] <= usable && req_supported;
                    generated[s] <= 0;
                    keys[s] <= req_key;
                    rows[s] <= req_rows;
                    sources[s] <= req_source;
                    source_ends[s] <= req_source_end;
                    owners[s] <= next_owner;
                end
                // Wins over promotion and request acceptance in this cycle.
                if (invalidated[s]) begin
                    valid[s] <= 0;
                    building[s] <= 0;
                    generated[s] <= 0;
                end
            end
            if (passthrough || clear || !enabled || enabled != previous_enabled || fault || faulted) begin
                valid <= 0;
                building <= 0;
                generated <= 0;
                quarantined <= passthrough || fault || faulted || !(core_idle && quiescent);
                // Clear boundaries are issued only at a drain. Do not cancel
                // the generator's real completion: this is an observation token.
            end
            if (fault) faulted <= 1;
        end
    end
`ifndef SYNTHESIS
    always @(posedge clock) if (!reset) begin
        assert (!(skipped && (!quiescent || !req_supported || invalidated[req_half])))
            else $fatal(1, "CSC skip before physical completion or during invalidation");
        assert (!(skipped && skip_pending && !completion))
            else $fatal(1, "CSC replacement completion overwritten");
    end
`endif
endmodule
