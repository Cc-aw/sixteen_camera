`timescale 1ns/1ps

module postprocess_read_diagnostic #(
    parameter bit HEAD_SHADOW_DDR = 1'b1
) (
    axi_lite_if.slave axil,
    axi4_if.master    m_axi,
    output wire [1:0] local_read_bank,
    output wire       local_read_req_valid,
    input  wire       local_read_req_ready,
    output wire [14:0] local_read_req_word_addr,
    input  wire [255:0] local_read_rsp_data,
    input  wire       local_read_rsp_valid,
    output wire       local_read_rsp_ready
);
    localparam logic [31:0] DIAG_ID = 32'h5050_4431; // "PPD1"
    localparam logic [31:0] CAPABILITY = 32'h0020_2305;

    logic aw_pending, w_pending, bvalid_q;
    logic [15:0] awaddr_q;
    logic [31:0] wdata_q;
    logic [3:0] wstrb_q;
    logic rvalid_q;
    logic [31:0] rdata_q;
    logic [32:0] tensor_addr_q;
    logic [31:0] tensor_bytes_q;
    logic [8:0] burst_beats_q;
    logic start_reader;
    logic done_sticky;
    logic [31:0] result_crc;
    logic [31:0] byte_sum;
    logic [31:0] nonzero_count;
    logic [31:0] completion_count;
    logic [31:0] error_count;
    logic [2:0] result_error_flags;
    logic fast_mode_q;
    // Capture shared-reader counters before PPU reuse; publish only after CRC drain.
    typedef struct packed {
        logic [31:0] bytes_read;
        logic [31:0] ar_requests;
        logic [31:0] beats;
        logic [31:0] active_cycles;
        logic [31:0] ar_stall_cycles;
        logic [31:0] r_wait_cycles;
        logic [31:0] r_backpressure_cycles;
        logic [31:0] max_outstanding;
        logic [31:0] max_reorder_occupancy;
        logic [31:0] active_id_mask;
        logic error;
        logic [2:0] error_flags;
    } reader_snapshot_t;
    reader_snapshot_t pending_snapshot, result_snapshot;
    logic [31:0] result_byte_sum, result_nonzero_count;

    wire reader_busy, reader_done, reader_error;
    wire [2:0] reader_error_flags;
    wire [31:0] reader_bytes_read, reader_ar_requests, reader_beats;
    wire [31:0] reader_active_cycles, reader_ar_stall_cycles;
    wire [31:0] reader_r_wait_cycles, reader_r_backpressure_cycles;
    wire [31:0] reader_max_outstanding;
    wire [31:0] reader_max_reorder_occupancy;
    wire [31:0] reader_active_id_mask;
    wire [255:0] stream_data;
    wire [31:0] stream_keep;
    wire stream_valid, stream_last;
    logic [31:0] crc_state;
    logic beat_active;
    logic [255:0] beat_data;
    logic [31:0] beat_keep;
    logic [4:0] beat_lane;
    logic reader_complete_pending;
    // The production descriptor shares the proven FBus reader.  Arbitration
    // happens only between complete read commands, never between AXI beats.
    logic production_owner;
    logic local_enable_q;
    logic local_active_q;
    logic production_start;
    logic [32:0] production_class0, production_class1, production_class2;
    logic [32:0] production_dfl0, production_dfl1, production_dfl2;
    logic [4:0] production_result_index;
    wire [127:0] production_result;
    wire [5:0] production_count;
    wire production_busy, production_done, production_error;
    wire [12:0] production_positions, production_candidates;
    wire [15:0] production_nms_candidates;
    wire [31:0] production_cycles;
    wire production_read_start, production_stream_ready;
    wire [32:0] production_read_base;
    wire [31:0] production_read_bytes;

    wire fbus_reader_busy, fbus_reader_done, fbus_reader_error;
    wire [2:0] fbus_reader_error_flags;
    wire [31:0] fbus_reader_bytes_read;
    wire [255:0] fbus_stream_data;
    wire [31:0] fbus_stream_keep;
    wire fbus_stream_valid, fbus_stream_last;
    wire local_reader_busy, local_reader_done, local_reader_error;
    wire [2:0] local_reader_error_flags;
    wire [31:0] local_reader_bytes_read;
    wire [255:0] local_stream_data;
    wire [31:0] local_stream_keep;
    wire local_stream_valid, local_stream_last;
    wire production_uses_local = production_owner && local_active_q;

    function automatic [1:0] decode_local_bank(input [32:0] address);
        reg [31:0] canonical;
        begin
            canonical = address[31:0];
            canonical[31] = 1'b0;
            case (canonical[31:20])
            12'h320: decode_local_bank = 2'd0;
            12'h321: decode_local_bank = 2'd1;
            12'h324: decode_local_bank = 2'd2;
            12'h325: decode_local_bank = 2'd3;
            default: decode_local_bank = 2'd0;
            endcase
        end
    endfunction

    assign local_read_bank = decode_local_bank(production_read_base);
    assign reader_busy = production_uses_local ? local_reader_busy :
                         fbus_reader_busy;
    assign reader_done = production_uses_local ? local_reader_done :
                         fbus_reader_done;
    assign reader_error = production_uses_local ? local_reader_error :
                          fbus_reader_error;
    assign reader_error_flags = production_uses_local ?
                                local_reader_error_flags :
                                fbus_reader_error_flags;
    assign reader_bytes_read = production_uses_local ?
                               local_reader_bytes_read :
                               fbus_reader_bytes_read;
    assign stream_data = production_uses_local ? local_stream_data :
                         fbus_stream_data;
    assign stream_keep = production_uses_local ? local_stream_keep :
                         fbus_stream_keep;
    assign stream_valid = production_uses_local ? local_stream_valid :
                          fbus_stream_valid;
    assign stream_last = production_uses_local ? local_stream_last :
                         fbus_stream_last;

    yolov5nu_postprocessor u_production (
        .clk(axil.aclk), .resetn(axil.aresetn),
        .start(production_start),
        .class0(production_class0), .class1(production_class1),
        .class2(production_class2), .dfl0(production_dfl0),
        .dfl1(production_dfl1), .dfl2(production_dfl2),
        .read_start(production_read_start),
        .read_base(production_read_base),
        .read_bytes(production_read_bytes),
        .read_busy(reader_busy),
        .read_done(reader_done && production_owner),
        .read_error(reader_error && production_owner),
        .stream_data(stream_data), .stream_keep(stream_keep),
        .stream_valid(stream_valid && production_owner),
        .stream_last(stream_last),
        .stream_ready(production_stream_ready),
        .result_index(production_result_index),
        .result_word(production_result),
        .result_count(production_count), .busy(production_busy),
        .done(production_done), .error(production_error),
        .positions_seen(production_positions),
        .candidates_seen(production_candidates),
        .nms_candidates_seen(production_nms_candidates),
        .cycles(production_cycles)
    );

    function automatic [31:0] merge_wstrb(
        input [31:0] previous,
        input [31:0] value,
        input [3:0] strobes
    );
        begin
            merge_wstrb = previous;
            for (integer byte_index = 0; byte_index < 4;
                 byte_index = byte_index + 1)
                if (strobes[byte_index])
                    merge_wstrb[byte_index*8 +: 8] =
                        value[byte_index*8 +: 8];
        end
    endfunction

    function automatic [31:0] crc32_byte(
        input [31:0] current,
        input [7:0] value
    );
        logic [31:0] next;
        begin
            next = current ^ {24'd0, value};
            for (integer bit_index = 0; bit_index < 8;
                 bit_index = bit_index + 1)
                next = next[0] ? (next >> 1) ^ 32'hEDB8_8320 : next >> 1;
            crc32_byte = next;
        end
    endfunction

    function automatic [31:0] crc32_chunk64(
        input [31:0] current,
        input [63:0] data,
        input [7:0] keep
    );
        logic [31:0] next;
        begin
            next = current;
            for (integer lane = 0; lane < 8; lane = lane + 1)
                if (keep[lane])
                    next = crc32_byte(next, data[lane*8 +: 8]);
            crc32_chunk64 = next;
        end
    endfunction

    function automatic [31:0] chunk64_byte_sum(
        input [63:0] data,
        input [7:0] keep
    );
        logic [31:0] total;
        begin
            total = 32'd0;
            for (integer lane = 0; lane < 8; lane = lane + 1)
                if (keep[lane])
                    total = total + {24'd0, data[lane*8 +: 8]};
            chunk64_byte_sum = total;
        end
    endfunction

    function automatic [31:0] chunk64_nonzero_count(
        input [63:0] data,
        input [7:0] keep
    );
        logic [31:0] total;
        begin
            total = 32'd0;
            for (integer lane = 0; lane < 8; lane = lane + 1)
                if (keep[lane] && data[lane*8 +: 8] != 8'd0)
                    total = total + 1'b1;
            chunk64_nonzero_count = total;
        end
    endfunction

    // ID 31 belongs to preprocess writes, avoiding cross-direction FIFO stalls.
    fbus_read_engine #(.READ_ID_COUNT(31)) u_reader (
        .clk(axil.aclk), .resetn(axil.aresetn),
        .start(start_reader ||
               (production_read_start && !local_active_q)),
        // MMIO descriptors use device physical addresses. Coherent FBus
        // exposes the same DDR storage through Rocket's bit-31 alias.
        .base_addr(production_read_start ?
                   {production_read_base[32],
                    production_read_base[31:0] | 32'h8000_0000} :
                   {tensor_addr_q[32],
                    tensor_addr_q[31:0] | 32'h8000_0000}),
        .byte_count(production_read_start ? production_read_bytes :
                    tensor_bytes_q),
        // Keep production reads at one cache line even during a diagnostic sweep.
        .burst_beats_limit((production_read_start || production_owner) ?
                           9'd2 : burst_beats_q),
        .busy(fbus_reader_busy), .done(fbus_reader_done),
        .error(fbus_reader_error),
        .error_flags(fbus_reader_error_flags),
        .bytes_read(fbus_reader_bytes_read),
        .ar_requests(reader_ar_requests),
        .read_beats(reader_beats), .active_cycles(reader_active_cycles),
        .ar_stall_cycles(reader_ar_stall_cycles),
        .r_wait_cycles(reader_r_wait_cycles),
        .r_backpressure_cycles(reader_r_backpressure_cycles),
        .max_outstanding_observed(reader_max_outstanding),
        .max_reorder_occupancy(reader_max_reorder_occupancy),
        .active_id_mask_observed(reader_active_id_mask),
        .stream_data(fbus_stream_data),
        .stream_keep(fbus_stream_keep), .stream_valid(fbus_stream_valid),
        .stream_ready(production_owner && !local_active_q ?
                      production_stream_ready :
                      !beat_active),
        .stream_last(fbus_stream_last), .m_axi(m_axi)
    );

    head_local_reader u_local_reader (
        .clk(axil.aclk), .resetn(axil.aresetn),
        .start(production_read_start && local_active_q),
        .base_addr(production_read_base),
        .byte_count(production_read_bytes),
        .busy(local_reader_busy), .done(local_reader_done),
        .error(local_reader_error),
        .error_flags(local_reader_error_flags),
        .bytes_read(local_reader_bytes_read),
        .memory_req_valid(local_read_req_valid),
        .memory_req_ready(local_read_req_ready),
        .memory_req_word_addr(local_read_req_word_addr),
        .memory_rsp_data(local_read_rsp_data),
        .memory_rsp_valid(local_read_rsp_valid),
        .memory_rsp_ready(local_read_rsp_ready),
        .stream_data(local_stream_data), .stream_keep(local_stream_keep),
        .stream_valid(local_stream_valid),
        .stream_ready(production_stream_ready),
        .stream_last(local_stream_last)
    );

    assign axil.awready = axil.aresetn && !aw_pending && !bvalid_q;
    assign axil.wready = axil.aresetn && !w_pending && !bvalid_q;
    assign axil.bvalid = bvalid_q;
    assign axil.bresp = 2'b00;
    assign axil.arready = axil.aresetn && !rvalid_q;
    assign axil.rvalid = rvalid_q;
    assign axil.rdata = rdata_q;
    assign axil.rresp = 2'b00;

    always_ff @(posedge axil.aclk) begin
        if (!axil.aresetn) begin
            aw_pending <= 1'b0;
            w_pending <= 1'b0;
            bvalid_q <= 1'b0;
            rvalid_q <= 1'b0;
            tensor_addr_q <= 33'd0;
            tensor_bytes_q <= 32'd0;
            burst_beats_q <= 9'd128;
            start_reader <= 1'b0;
            done_sticky <= 1'b0;
            result_crc <= 32'd0;
            pending_snapshot <= '0;
            result_snapshot <= '0;
            result_byte_sum <= 0;
            result_nonzero_count <= 0;
            crc_state <= 32'hFFFF_FFFF;
            byte_sum <= 32'd0;
            nonzero_count <= 32'd0;
            completion_count <= 32'd0;
            error_count <= 32'd0;
            result_error_flags <= 3'b000;
            fast_mode_q <= 1'b0;
            beat_active <= 1'b0;
            beat_data <= 256'd0;
            beat_keep <= 32'd0;
            beat_lane <= 5'd0;
            reader_complete_pending <= 1'b0;
            production_owner <= 1'b0;
            local_enable_q <= 1'b1;
            local_active_q <= 1'b1;
            production_start <= 1'b0;
            production_class0 <= 0;
            production_class1 <= 0;
            production_class2 <= 0;
            production_dfl0 <= 0;
            production_dfl1 <= 0;
            production_dfl2 <= 0;
            production_result_index <= 0;
        end else begin
            start_reader <= 1'b0;
            production_start <= 1'b0;
            if (production_start) local_active_q <= local_enable_q;
            if (production_read_start) production_owner <= 1'b1;
            else if (reader_done) production_owner <= 1'b0;
            if (axil.awvalid && axil.awready) begin
                aw_pending <= 1'b1;
                awaddr_q <= axil.awaddr[15:0];
            end
            if (axil.wvalid && axil.wready) begin
                w_pending <= 1'b1;
                wdata_q <= axil.wdata;
                wstrb_q <= axil.wstrb;
            end
            if (!bvalid_q && aw_pending && w_pending) begin
                case (awaddr_q[9:0])
                8'h08: begin
                    if (wstrb_q[0] && wdata_q[1])
                        done_sticky <= 1'b0;
                    if (wstrb_q[0] && wdata_q[0] && !reader_busy &&
                        !production_busy) begin
                        start_reader <= 1'b1;
                        done_sticky <= 1'b0;
                        crc_state <= 32'hFFFF_FFFF;
                        byte_sum <= 32'd0;
                        nonzero_count <= 32'd0;
                        fast_mode_q <= wdata_q[2];
                        beat_active <= 1'b0;
                        reader_complete_pending <= 1'b0;
                    end
                end
                8'h10: tensor_addr_q[31:0] <=
                    merge_wstrb(tensor_addr_q[31:0], wdata_q, wstrb_q);
                8'h14: if (wstrb_q[0]) tensor_addr_q[32] <= wdata_q[0];
                8'h18: tensor_bytes_q <=
                    merge_wstrb(tensor_bytes_q, wdata_q, wstrb_q);
                8'h5c: if (!reader_busy && wstrb_q[0])
                    burst_beats_q <= wdata_q[8:0];
                // Queue the production command even if a diagnostic burst
                // owns the reader; CLASS_LAUNCH waits for the whole read.
                10'h100: if (wstrb_q[0] && wdata_q[0] &&
                            !production_busy) production_start <= 1'b1;
                10'h104: production_class0[31:0] <= merge_wstrb(
                    production_class0[31:0], wdata_q, wstrb_q);
                10'h108: production_class1[31:0] <= merge_wstrb(
                    production_class1[31:0], wdata_q, wstrb_q);
                10'h10c: production_class2[31:0] <= merge_wstrb(
                    production_class2[31:0], wdata_q, wstrb_q);
                10'h110: production_dfl0[31:0] <= merge_wstrb(
                    production_dfl0[31:0], wdata_q, wstrb_q);
                10'h114: production_dfl1[31:0] <= merge_wstrb(
                    production_dfl1[31:0], wdata_q, wstrb_q);
                10'h118: production_dfl2[31:0] <= merge_wstrb(
                    production_dfl2[31:0], wdata_q, wstrb_q);
                10'h120: if (wstrb_q[0])
                    production_result_index <= wdata_q[4:0];
                // Change the source only while the complete PPU command is
                // idle. The selection is latched once per command.
                10'h148: if (wstrb_q[0] && !production_busy &&
                            !fbus_reader_busy && !local_reader_busy)
                    local_enable_q <= wdata_q[0];
                default: begin end
                endcase
                aw_pending <= 1'b0;
                w_pending <= 1'b0;
                bvalid_q <= 1'b1;
            end else if (bvalid_q && axil.bready) begin
                bvalid_q <= 1'b0;
            end

            if (stream_valid && !production_owner &&
                !beat_active && !fast_mode_q) begin
                beat_active <= 1'b1;
                beat_data <= stream_data;
                beat_keep <= stream_keep;
                beat_lane <= 5'd0;
            end

            // The physical FBus behind the 256-bit AXI adapter is 64-bit.
            // Consume the first 64-bit chunk as the beat is accepted, then
            // fold the remaining three chunks while the next beat assembles.
            if (stream_valid && !production_owner &&
                !beat_active && fast_mode_q) begin
                crc_state <= crc32_chunk64(
                    crc_state, stream_data[63:0], stream_keep[7:0]);
                byte_sum <= byte_sum +
                            chunk64_byte_sum(stream_data[63:0],
                                             stream_keep[7:0]);
                nonzero_count <= nonzero_count +
                    chunk64_nonzero_count(stream_data[63:0],
                                          stream_keep[7:0]);
                beat_active <= 1'b1;
                beat_data <= stream_data;
                beat_keep <= stream_keep;
                beat_lane <= 5'd8;
            end

            // Fold one byte per cycle. This keeps the diagnostic CRC away from
            // the critical path and deliberately exercises reader backpressure.
            if (beat_active && !fast_mode_q) begin
                if (beat_keep[beat_lane]) begin
                    crc_state <= crc32_byte(
                        crc_state, beat_data[beat_lane*8 +: 8]);
                    byte_sum <= byte_sum +
                                {24'd0, beat_data[beat_lane*8 +: 8]};
                    if (beat_data[beat_lane*8 +: 8] != 8'd0)
                        nonzero_count <= nonzero_count + 1'b1;
                end
                if (beat_lane == 5'd31)
                    beat_active <= 1'b0;
                else
                    beat_lane <= beat_lane + 1'b1;
            end

            if (beat_active && fast_mode_q) begin
                crc_state <= crc32_chunk64(
                    crc_state, beat_data[beat_lane*8 +: 64],
                    beat_keep[beat_lane +: 8]);
                byte_sum <= byte_sum + chunk64_byte_sum(
                    beat_data[beat_lane*8 +: 64],
                    beat_keep[beat_lane +: 8]);
                nonzero_count <= nonzero_count + chunk64_nonzero_count(
                    beat_data[beat_lane*8 +: 64],
                    beat_keep[beat_lane +: 8]);
                if (beat_lane == 5'd24)
                    beat_active <= 1'b0;
                else
                    beat_lane <= beat_lane + 5'd8;
            end

            if (reader_done && !production_owner) begin
                reader_complete_pending <= 1'b1;
                pending_snapshot.bytes_read <= reader_bytes_read;
                pending_snapshot.ar_requests <= reader_ar_requests;
                pending_snapshot.beats <= reader_beats;
                pending_snapshot.active_cycles <= reader_active_cycles;
                pending_snapshot.ar_stall_cycles <= reader_ar_stall_cycles;
                pending_snapshot.r_wait_cycles <= reader_r_wait_cycles;
                pending_snapshot.r_backpressure_cycles <= reader_r_backpressure_cycles;
                pending_snapshot.max_outstanding <= reader_max_outstanding;
                pending_snapshot.max_reorder_occupancy <= reader_max_reorder_occupancy;
                pending_snapshot.active_id_mask <= reader_active_id_mask;
                pending_snapshot.error <= reader_error;
                pending_snapshot.error_flags <= reader_error_flags;
            end
            if (reader_complete_pending && !beat_active) begin
                reader_complete_pending <= 1'b0;
                done_sticky <= 1'b1;
                result_crc <= crc_state ^ 32'hFFFF_FFFF;
                completion_count <= completion_count + 1'b1;
                result_snapshot <= pending_snapshot;
                result_byte_sum <= byte_sum;
                result_nonzero_count <= nonzero_count;
                result_error_flags <= pending_snapshot.error_flags;
                if (pending_snapshot.error)
                    error_count <= error_count + 1'b1;
            end

            if (axil.arvalid && axil.arready) begin
                case (axil.araddr[9:0])
                8'h00: rdata_q <= DIAG_ID;
                8'h04: rdata_q <= CAPABILITY;
                8'h08: rdata_q <= 32'd0;
                8'h0c: rdata_q <= {29'd0, result_snapshot.error,
                                    done_sticky, reader_busy};
                8'h10: rdata_q <= tensor_addr_q[31:0];
                8'h14: rdata_q <= {31'd0, tensor_addr_q[32]};
                8'h18: rdata_q <= tensor_bytes_q;
                8'h1c: rdata_q <= result_crc;
                8'h20: rdata_q <= result_byte_sum;
                8'h24: rdata_q <= result_nonzero_count;
                8'h28: rdata_q <= result_snapshot.bytes_read;
                8'h2c: rdata_q <= result_snapshot.ar_requests;
                8'h30: rdata_q <= result_snapshot.beats;
                8'h34: rdata_q <= completion_count;
                8'h38: rdata_q <= error_count;
                8'h3c: rdata_q <= {29'd0, result_error_flags};
                8'h40: rdata_q <= result_snapshot.active_cycles;
                8'h44: rdata_q <= result_snapshot.ar_stall_cycles;
                8'h48: rdata_q <= result_snapshot.r_wait_cycles;
                8'h4c: rdata_q <= result_snapshot.r_backpressure_cycles;
                8'h50: rdata_q <= result_snapshot.max_outstanding;
                8'h54: rdata_q <= result_snapshot.max_reorder_occupancy;
                8'h58: rdata_q <= result_snapshot.active_id_mask;
                8'h5c: rdata_q <= {23'd0, burst_beats_q};
                10'h100: rdata_q <= 32'h5050_5531; // "PPU1"
                10'h104: rdata_q <= production_class0[31:0];
                10'h108: rdata_q <= production_class1[31:0];
                10'h10c: rdata_q <= production_class2[31:0];
                10'h110: rdata_q <= production_dfl0[31:0];
                10'h114: rdata_q <= production_dfl1[31:0];
                10'h118: rdata_q <= production_dfl2[31:0];
                10'h11c: rdata_q <= {28'd0, reader_busy, production_error,
                                     production_done, production_busy};
                10'h120: rdata_q <= {27'd0, production_result_index};
                10'h124: rdata_q <= {26'd0, production_count};
                10'h128: rdata_q <= production_result[31:0];
                10'h12c: rdata_q <= production_result[63:32];
                10'h130: rdata_q <= production_result[95:64];
                10'h134: rdata_q <= production_result[127:96];
                10'h138: rdata_q <= {19'd0, production_positions};
                10'h13c: rdata_q <= {19'd0, production_candidates};
                10'h140: rdata_q <= {16'd0, production_nms_candidates};
                10'h144: rdata_q <= production_cycles;
                10'h148: rdata_q <= {28'd0, local_reader_error,
                                     local_reader_busy, local_active_q,
                                     local_enable_q};
                // bit 1 identifies the URAM Head store; bit 0 reports
                // whether the build also mirrors Head writes into DDR.
                10'h14c: rdata_q <= {30'd0, 1'b1, HEAD_SHADOW_DDR};
                default: rdata_q <= 32'd0;
                endcase
                rvalid_q <= 1'b1;
            end else if (rvalid_q && axil.rready) begin
                rvalid_q <= 1'b0;
            end
        end
    end

    wire unused_stream_last = &{1'b0, stream_last};
endmodule
