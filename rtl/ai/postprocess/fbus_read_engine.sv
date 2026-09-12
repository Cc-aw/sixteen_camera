`timescale 1ns/1ps

// Coherent FBus reader with independent request, response and ordered-output
// pipelines. Each live slot owns one AXI ID. Responses may complete in any ID
// order; the slot RAMs restore descriptor byte order before producing stream.
module fbus_read_engine #(
    parameter integer ADDR_WIDTH = 33,
    parameter integer DATA_WIDTH = 256,
    parameter integer ID_WIDTH = 4,
    parameter integer MAX_BURST_BEATS = 256,
    parameter integer MAX_OUTSTANDING = 8
) (
    input  wire                    clk,
    input  wire                    resetn,
    input  wire                    start,
    input  wire [ADDR_WIDTH-1:0]   base_addr,
    input  wire [31:0]             byte_count,
    input  wire [8:0]              burst_beats_limit,
    output wire                    busy,
    output reg                     done,
    output wire                    error,
    output wire [2:0]              error_flags,
    output reg  [31:0]             bytes_read,
    output reg  [31:0]             ar_requests,
    output reg  [31:0]             read_beats,
    output reg  [31:0]             active_cycles,
    output reg  [31:0]             ar_stall_cycles,
    output reg  [31:0]             r_wait_cycles,
    output reg  [31:0]             r_backpressure_cycles,
    output reg  [31:0]             max_outstanding_observed,
    output reg  [31:0]             max_reorder_occupancy,
    output reg  [31:0]             active_id_mask_observed,
    output wire [DATA_WIDTH-1:0]   stream_data,
    output wire [DATA_WIDTH/8-1:0] stream_keep,
    output wire                    stream_valid,
    input  wire                    stream_ready,
    output wire                    stream_last,
    axi4_if.master                 m_axi
);
    localparam integer BYTE_LANES = DATA_WIDTH / 8;
    localparam integer BYTE_SHIFT = $clog2(BYTE_LANES);
    localparam integer PTR_WIDTH = $clog2(MAX_OUTSTANDING);
    localparam integer SLOT_BEATS = 4096 / BYTE_LANES;
    localparam integer SLOT_INDEX_WIDTH = $clog2(SLOT_BEATS);
    localparam [2:0] AXI_SIZE = 3'(BYTE_SHIFT);
    localparam [8:0] MAX_BURST_BEATS_9 = 9'(MAX_BURST_BEATS);
    localparam [8:0] SLOT_BEATS_9 = 9'(SLOT_BEATS);

    reg busy_q;
    reg error_q;
    reg [2:0] error_flags_q;
    reg [ADDR_WIDTH-1:0] issue_addr;
    reg [31:0] issue_beats_remaining;
    reg [PTR_WIDTH-1:0] issue_ptr;
    reg [PTR_WIDTH-1:0] drain_ptr;
    reg [PTR_WIDTH:0] allocated_count;
    reg [PTR_WIDTH:0] response_outstanding_count;

    reg slot_active [0:MAX_OUTSTANDING-1];
    reg slot_complete [0:MAX_OUTSTANDING-1];
    reg [8:0] slot_expected_beats [0:MAX_OUTSTANDING-1];
    reg [8:0] slot_received_beats [0:MAX_OUTSTANDING-1];
    reg [8:0] slot_drained_beats [0:MAX_OUTSTANDING-1];
    (* ram_style = "block" *) reg [DATA_WIDTH-1:0] slot_data
        [0:MAX_OUTSTANDING-1][0:SLOT_BEATS-1];

    reg [31:0] output_remaining_bytes;
    reg [BYTE_SHIFT-1:0] output_skip_bytes;
    reg all_data_queued;
    reg [DATA_WIDTH-1:0] stream_data_q;
    reg [BYTE_LANES-1:0] stream_keep_q;
    reg stream_valid_q;
    reg stream_last_q;

    wire [12:0] issue_bytes_to_4k =
        13'd4096 - {1'b0, issue_addr[11:0]};
    wire [8:0] issue_beats_to_4k =
        {1'b0, issue_bytes_to_4k[12:BYTE_SHIFT]};
    wire [32:0] initial_bytes_with_skip =
        {1'b0, byte_count} +
        {{(33-BYTE_SHIFT){1'b0}}, base_addr[BYTE_SHIFT-1:0]};
    wire [32:0] initial_beats =
        (initial_bytes_with_skip + 33'(BYTE_LANES - 1)) >> BYTE_SHIFT;

    reg [8:0] planned_beats;
    reg [8:0] effective_burst_beats;
    always @* begin
        if (burst_beats_limit == 0 ||
            burst_beats_limit > MAX_BURST_BEATS_9)
            effective_burst_beats = MAX_BURST_BEATS_9;
        else
            effective_burst_beats = burst_beats_limit;
        if (issue_beats_remaining > effective_burst_beats)
            planned_beats = effective_burst_beats;
        else
            planned_beats = issue_beats_remaining[8:0];
        if (planned_beats > SLOT_BEATS_9)
            planned_beats = SLOT_BEATS_9;
        if (planned_beats > issue_beats_to_4k)
            planned_beats = issue_beats_to_4k;
    end

    reg [BYTE_SHIFT:0] output_available_bytes;
    reg [BYTE_SHIFT:0] output_valid_bytes;
    reg [BYTE_LANES-1:0] output_valid_mask;
    always @* begin
        output_available_bytes = (BYTE_SHIFT+1)'(BYTE_LANES) -
                                 {1'b0, output_skip_bytes};
        if (output_remaining_bytes < output_available_bytes)
            output_valid_bytes = output_remaining_bytes[BYTE_SHIFT:0];
        else
            output_valid_bytes = output_available_bytes;
        output_valid_mask = {BYTE_LANES{1'b0}};
        for (integer lane = 0; lane < BYTE_LANES; lane = lane + 1)
            if (lane >= 32'(output_skip_bytes) &&
                lane < 32'(output_skip_bytes) + 32'(output_valid_bytes))
                output_valid_mask[lane] = 1'b1;
    end

    wire output_register_available = !stream_valid_q || stream_ready;
    wire ar_fire = m_axi.arvalid && m_axi.arready;
    wire r_fire = m_axi.rvalid && m_axi.rready;
    wire stream_fire = stream_valid_q && stream_ready;
    wire [PTR_WIDTH-1:0] response_slot = m_axi.rid[PTR_WIDTH-1:0];
    wire response_id_in_range = m_axi.rid < ID_WIDTH'(MAX_OUTSTANDING);
    wire response_id_valid = response_id_in_range &&
                             slot_active[response_slot];
    wire expected_response_last = response_id_valid &&
        slot_received_beats[response_slot] + 1'b1 ==
        slot_expected_beats[response_slot];
    wire response_burst_done = r_fire && expected_response_last;
    wire drain_data_available = slot_complete[drain_ptr] &&
        slot_drained_beats[drain_ptr] < slot_expected_beats[drain_ptr];
    wire drain_fire = busy_q && output_register_available &&
                      drain_data_available;
    wire drain_burst_done = drain_fire &&
        slot_drained_beats[drain_ptr] + 1'b1 ==
        slot_expected_beats[drain_ptr];

    assign busy = busy_q;
    assign error = error_q;
    assign error_flags = error_flags_q;
    assign stream_data = stream_data_q;
    assign stream_keep = stream_keep_q;
    assign stream_valid = stream_valid_q;
    assign stream_last = stream_last_q;

    assign m_axi.aclk = clk;
    assign m_axi.aresetn = resetn;
    assign m_axi.awid = '0;
    assign m_axi.awaddr = '0;
    assign m_axi.awlen = '0;
    assign m_axi.awsize = AXI_SIZE;
    assign m_axi.awburst = 2'b01;
    assign m_axi.awlock = 1'b0;
    assign m_axi.awcache = 4'b0010;
    assign m_axi.awprot = 3'b000;
    assign m_axi.awqos = 4'b0000;
    assign m_axi.awvalid = 1'b0;
    assign m_axi.wdata = '0;
    assign m_axi.wstrb = '0;
    assign m_axi.wlast = 1'b0;
    assign m_axi.wvalid = 1'b0;
    assign m_axi.bready = 1'b0;
    assign m_axi.arid = {{(ID_WIDTH-PTR_WIDTH){1'b0}}, issue_ptr};
    assign m_axi.araddr = issue_addr;
    assign m_axi.arlen = planned_beats[7:0] - 1'b1;
    assign m_axi.arsize = AXI_SIZE;
    assign m_axi.arburst = 2'b01;
    assign m_axi.arlock = 1'b0;
    assign m_axi.arcache = 4'b0010;
    assign m_axi.arprot = 3'b000;
    assign m_axi.arqos = 4'hf;
    assign m_axi.arvalid = busy_q && issue_beats_remaining != 0 &&
                           allocated_count <
                           (PTR_WIDTH+1)'(MAX_OUTSTANDING);
    assign m_axi.rready = busy_q && response_outstanding_count != 0 &&
        (!response_id_valid ||
         slot_received_beats[response_slot] < SLOT_BEATS_9);

    initial begin
        if (DATA_WIDTH < 8 || (DATA_WIDTH & (DATA_WIDTH - 1)) != 0 ||
            (DATA_WIDTH % 8) != 0 || MAX_BURST_BEATS < 1 ||
            MAX_BURST_BEATS > 256 || MAX_OUTSTANDING < 2 ||
            MAX_OUTSTANDING > 32 || ID_WIDTH < PTR_WIDTH ||
            (MAX_OUTSTANDING & (MAX_OUTSTANDING - 1)) != 0 ||
            SLOT_BEATS > 256)
            $error("fbus_read_engine parameters are invalid");
    end

    integer slot;
    always @(posedge clk or negedge resetn) begin
        if (!resetn) begin
            busy_q <= 1'b0;
            done <= 1'b0;
            error_q <= 1'b0;
            error_flags_q <= 3'b000;
            issue_addr <= '0;
            issue_beats_remaining <= 32'd0;
            issue_ptr <= '0;
            drain_ptr <= '0;
            allocated_count <= '0;
            response_outstanding_count <= '0;
            output_remaining_bytes <= 32'd0;
            output_skip_bytes <= '0;
            all_data_queued <= 1'b0;
            bytes_read <= 32'd0;
            ar_requests <= 32'd0;
            read_beats <= 32'd0;
            active_cycles <= 32'd0;
            ar_stall_cycles <= 32'd0;
            r_wait_cycles <= 32'd0;
            r_backpressure_cycles <= 32'd0;
            max_outstanding_observed <= 32'd0;
            max_reorder_occupancy <= 32'd0;
            active_id_mask_observed <= 32'd0;
            stream_data_q <= '0;
            stream_keep_q <= '0;
            stream_valid_q <= 1'b0;
            stream_last_q <= 1'b0;
            for (slot = 0; slot < MAX_OUTSTANDING; slot = slot + 1) begin
                slot_active[slot] <= 1'b0;
                slot_complete[slot] <= 1'b0;
                slot_expected_beats[slot] <= 9'd0;
                slot_received_beats[slot] <= 9'd0;
                slot_drained_beats[slot] <= 9'd0;
            end
        end else begin
            done <= 1'b0;
            if (busy_q)
                active_cycles <= active_cycles + 1'b1;
            if (m_axi.arvalid && !m_axi.arready)
                ar_stall_cycles <= ar_stall_cycles + 1'b1;
            if (busy_q && response_outstanding_count != 0 && !m_axi.rvalid)
                r_wait_cycles <= r_wait_cycles + 1'b1;
            if (busy_q && m_axi.rvalid && !m_axi.rready)
                r_backpressure_cycles <= r_backpressure_cycles + 1'b1;
            if (stream_fire)
                stream_valid_q <= 1'b0;

            if (start && !busy_q) begin
                error_q <= 1'b0;
                error_flags_q <= 3'b000;
                bytes_read <= 32'd0;
                ar_requests <= 32'd0;
                read_beats <= 32'd0;
                active_cycles <= 32'd0;
                ar_stall_cycles <= 32'd0;
                r_wait_cycles <= 32'd0;
                r_backpressure_cycles <= 32'd0;
                max_outstanding_observed <= 32'd0;
                max_reorder_occupancy <= 32'd0;
                active_id_mask_observed <= 32'd0;
                stream_valid_q <= 1'b0;
                issue_addr <= {base_addr[ADDR_WIDTH-1:BYTE_SHIFT],
                               {BYTE_SHIFT{1'b0}}};
                issue_beats_remaining <= initial_beats[31:0];
                issue_ptr <= '0;
                drain_ptr <= '0;
                allocated_count <= '0;
                response_outstanding_count <= '0;
                output_remaining_bytes <= byte_count;
                output_skip_bytes <= base_addr[BYTE_SHIFT-1:0];
                all_data_queued <= 1'b0;
                for (slot = 0; slot < MAX_OUTSTANDING; slot = slot + 1) begin
                    slot_active[slot] <= 1'b0;
                    slot_complete[slot] <= 1'b0;
                    slot_expected_beats[slot] <= 9'd0;
                    slot_received_beats[slot] <= 9'd0;
                    slot_drained_beats[slot] <= 9'd0;
                end
                if (byte_count == 0)
                    done <= 1'b1;
                else
                    busy_q <= 1'b1;
            end else if (busy_q) begin
                if (ar_fire) begin
                    slot_active[issue_ptr] <= 1'b1;
                    slot_complete[issue_ptr] <= 1'b0;
                    slot_expected_beats[issue_ptr] <= planned_beats;
                    slot_received_beats[issue_ptr] <= 9'd0;
                    slot_drained_beats[issue_ptr] <= 9'd0;
                    active_id_mask_observed <= active_id_mask_observed |
                                               (32'd1 << issue_ptr);
                    issue_ptr <= issue_ptr + 1'b1;
                    issue_addr <= issue_addr + planned_beats * BYTE_LANES;
                    issue_beats_remaining <= issue_beats_remaining -
                                             32'(planned_beats);
                    ar_requests <= ar_requests + 1'b1;
                    if (!response_burst_done && max_outstanding_observed <
                        32'(response_outstanding_count) + 1'b1)
                        max_outstanding_observed <=
                            32'(response_outstanding_count) + 1'b1;
                    if (!drain_burst_done && max_reorder_occupancy <
                        32'(allocated_count) + 1'b1)
                        max_reorder_occupancy <=
                            32'(allocated_count) + 1'b1;
                end

                if (r_fire) begin
                    read_beats <= read_beats + 1'b1;
                    if (!response_id_valid) begin
                        error_q <= 1'b1;
                        error_flags_q[1] <= 1'b1;
                    end else begin
                        slot_data[response_slot]
                                 [slot_received_beats[response_slot]
                                                      [SLOT_INDEX_WIDTH-1:0]] <=
                            m_axi.rdata;
                        slot_received_beats[response_slot] <=
                            slot_received_beats[response_slot] + 1'b1;
                        if (m_axi.rresp != 2'b00) begin
                            error_q <= 1'b1;
                            error_flags_q[0] <= 1'b1;
                        end
                        if (m_axi.rlast != expected_response_last) begin
                            error_q <= 1'b1;
                            error_flags_q[2] <= 1'b1;
                        end
                        if (expected_response_last)
                            slot_complete[response_slot] <= 1'b1;
                    end
                end

                if (drain_fire) begin
                    stream_data_q <=
                        slot_data[drain_ptr]
                                 [slot_drained_beats[drain_ptr]
                                                     [SLOT_INDEX_WIDTH-1:0]];
                    stream_keep_q <= output_valid_mask;
                    stream_last_q <=
                        output_remaining_bytes <= output_available_bytes;
                    stream_valid_q <= 1'b1;
                    output_remaining_bytes <= output_remaining_bytes -
                                              32'(output_valid_bytes);
                    output_skip_bytes <= '0;
                    bytes_read <= bytes_read + 32'(output_valid_bytes);
                    slot_drained_beats[drain_ptr] <=
                        slot_drained_beats[drain_ptr] + 1'b1;
                    if (output_remaining_bytes <= output_available_bytes)
                        all_data_queued <= 1'b1;
                    if (drain_burst_done) begin
                        slot_active[drain_ptr] <= 1'b0;
                        slot_complete[drain_ptr] <= 1'b0;
                        drain_ptr <= drain_ptr + 1'b1;
                    end
                end

                case ({ar_fire, response_burst_done})
                2'b10: response_outstanding_count <=
                           response_outstanding_count + 1'b1;
                2'b01: response_outstanding_count <=
                           response_outstanding_count - 1'b1;
                default: response_outstanding_count <=
                             response_outstanding_count;
                endcase
                case ({ar_fire, drain_burst_done})
                2'b10: allocated_count <= allocated_count + 1'b1;
                2'b01: allocated_count <= allocated_count - 1'b1;
                default: allocated_count <= allocated_count;
                endcase

                if (all_data_queued && !stream_valid_q) begin
                    busy_q <= 1'b0;
                    done <= 1'b1;
                end
            end
        end
    end

    wire unused_write_response = &{1'b0, m_axi.awready, m_axi.wready,
                                   m_axi.bid, m_axi.bresp, m_axi.bvalid};
endmodule
