`timescale 1ns/1ps

module postprocess_read_diagnostic (
    axi_lite_if.slave axil,
    axi4_if.master    m_axi
);
    localparam logic [31:0] DIAG_ID = 32'h5050_4431; // "PPD1"
    localparam logic [31:0] CAPABILITY = 32'h0020_2102;

    logic aw_pending, w_pending, bvalid_q;
    logic [15:0] awaddr_q;
    logic [31:0] wdata_q;
    logic [3:0] wstrb_q;
    logic rvalid_q;
    logic [31:0] rdata_q;
    logic [32:0] tensor_addr_q;
    logic [31:0] tensor_bytes_q;
    logic start_reader;
    logic done_sticky;
    logic [31:0] result_crc;
    logic [31:0] byte_sum;
    logic [31:0] nonzero_count;
    logic [31:0] completion_count;
    logic [31:0] error_count;
    logic [2:0] result_error_flags;

    wire reader_busy, reader_done, reader_error;
    wire [2:0] reader_error_flags;
    wire [31:0] reader_bytes_read, reader_ar_requests, reader_beats;
    wire [255:0] stream_data;
    wire [31:0] stream_keep;
    wire stream_valid, stream_last;
    logic [31:0] crc_state;
    logic beat_active;
    logic [255:0] beat_data;
    logic [31:0] beat_keep;
    logic [4:0] beat_lane;
    logic reader_complete_pending;

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

    fbus_read_engine u_reader (
        .clk(axil.aclk), .resetn(axil.aresetn), .start(start_reader),
        // MMIO descriptors use device physical addresses. Coherent FBus
        // exposes the same DDR storage through Rocket's bit-31 alias.
        .base_addr({tensor_addr_q[32],
                    tensor_addr_q[31:0] | 32'h8000_0000}),
        .byte_count(tensor_bytes_q),
        .busy(reader_busy), .done(reader_done), .error(reader_error),
        .error_flags(reader_error_flags),
        .bytes_read(reader_bytes_read), .ar_requests(reader_ar_requests),
        .read_beats(reader_beats), .stream_data(stream_data),
        .stream_keep(stream_keep), .stream_valid(stream_valid),
        .stream_ready(!beat_active), .stream_last(stream_last), .m_axi(m_axi)
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
            start_reader <= 1'b0;
            done_sticky <= 1'b0;
            result_crc <= 32'd0;
            crc_state <= 32'hFFFF_FFFF;
            byte_sum <= 32'd0;
            nonzero_count <= 32'd0;
            completion_count <= 32'd0;
            error_count <= 32'd0;
            result_error_flags <= 3'b000;
            beat_active <= 1'b0;
            beat_data <= 256'd0;
            beat_keep <= 32'd0;
            beat_lane <= 5'd0;
            reader_complete_pending <= 1'b0;
        end else begin
            start_reader <= 1'b0;
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
                case (awaddr_q[7:0])
                8'h08: begin
                    if (wstrb_q[0] && wdata_q[1])
                        done_sticky <= 1'b0;
                    if (wstrb_q[0] && wdata_q[0] && !reader_busy) begin
                        start_reader <= 1'b1;
                        done_sticky <= 1'b0;
                        result_crc <= 32'd0;
                        crc_state <= 32'hFFFF_FFFF;
                        byte_sum <= 32'd0;
                        nonzero_count <= 32'd0;
                        result_error_flags <= 3'b000;
                        beat_active <= 1'b0;
                        reader_complete_pending <= 1'b0;
                    end
                end
                8'h10: tensor_addr_q[31:0] <=
                    merge_wstrb(tensor_addr_q[31:0], wdata_q, wstrb_q);
                8'h14: if (wstrb_q[0]) tensor_addr_q[32] <= wdata_q[0];
                8'h18: tensor_bytes_q <=
                    merge_wstrb(tensor_bytes_q, wdata_q, wstrb_q);
                default: begin end
                endcase
                aw_pending <= 1'b0;
                w_pending <= 1'b0;
                bvalid_q <= 1'b1;
            end else if (bvalid_q && axil.bready) begin
                bvalid_q <= 1'b0;
            end

            if (stream_valid && !beat_active) begin
                beat_active <= 1'b1;
                beat_data <= stream_data;
                beat_keep <= stream_keep;
                beat_lane <= 5'd0;
            end

            // Fold one byte per cycle. This keeps the diagnostic CRC away from
            // the critical path and deliberately exercises reader backpressure.
            if (beat_active) begin
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

            if (reader_done) begin
                reader_complete_pending <= 1'b1;
            end
            if (reader_complete_pending && !beat_active) begin
                reader_complete_pending <= 1'b0;
                done_sticky <= 1'b1;
                result_crc <= crc_state ^ 32'hFFFF_FFFF;
                completion_count <= completion_count + 1'b1;
                result_error_flags <= reader_error_flags;
                if (reader_error)
                    error_count <= error_count + 1'b1;
            end

            if (axil.arvalid && axil.arready) begin
                case (axil.araddr[7:0])
                8'h00: rdata_q <= DIAG_ID;
                8'h04: rdata_q <= CAPABILITY;
                8'h08: rdata_q <= 32'd0;
                8'h0c: rdata_q <= {29'd0, reader_error,
                                    done_sticky, reader_busy};
                8'h10: rdata_q <= tensor_addr_q[31:0];
                8'h14: rdata_q <= {31'd0, tensor_addr_q[32]};
                8'h18: rdata_q <= tensor_bytes_q;
                8'h1c: rdata_q <= result_crc;
                8'h20: rdata_q <= byte_sum;
                8'h24: rdata_q <= nonzero_count;
                8'h28: rdata_q <= reader_bytes_read;
                8'h2c: rdata_q <= reader_ar_requests;
                8'h30: rdata_q <= reader_beats;
                8'h34: rdata_q <= completion_count;
                8'h38: rdata_q <= error_count;
                8'h3c: rdata_q <= {29'd0, result_error_flags};
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
