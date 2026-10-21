// SPDX-License-Identifier: Apache-2.0
// Autonomous command-table reader. See ../README.md for the versioned ABI.
// Memory interface: one physical, aligned, 32-byte read, one response in order.
// The transport must provide coherent reads (or software must clean caches).
module GemminiCommandFrontend #(
  parameter integer FIFO_DEPTH = 8,
  parameter integer QUIET_CYCLES = 4
) (
  input wire clock, reset,
  input wire start,
  output wire start_ready,
  input wire [31:0] table_base, table_count, frame_base, timeout_cycles,
  input wire resume, acknowledge,
  input wire [63:0] resume_tag,
  output wire owns_gemmini, fence_busy, done, host_wait, fault,
  output reg [7:0] error_code,
  output reg [31:0] fetched, issued, cursor, completed_cursor,
  output reg [63:0] host_tag,
  output wire [3:0] state_out,
  output wire [31:0] fifo_level,
  output reg mem_req_valid,
  input wire mem_req_ready,
  output reg [31:0] mem_req_address,
  input wire mem_resp_valid,
  output wire mem_resp_ready,
  input wire [255:0] mem_resp_data,
  input wire mem_resp_error,
  output reg cmd_valid,
  input wire cmd_ready,
  output reg [6:0] cmd_funct,
  output reg [63:0] cmd_rs1, cmd_rs2,
  input wire gemmini_busy, gemmini_fault
);
  localparam [3:0] IDLE=0, RUN=1, DRAIN=2, HOST=3, DONE=4,
                   FAULT_DRAIN=5, FAULT=6;
  localparam [1:0] BARRIER=0, TO_HOST=1, FINISH=2;
  localparam integer PTR_W = (FIFO_DEPTH <= 2) ? 1 : $clog2(FIFO_DEPTH);
  localparam integer CNT_W = $clog2(FIFO_DEPTH+1);
  localparam integer QUIET_W = (QUIET_CYCLES <= 2) ? 1 : $clog2(QUIET_CYCLES+1);
  reg [3:0] state;
  reg [1:0] drain_reason;
  reg [31:0] base, count, frame, timeout_limit, elapsed, fetch_index;
  reg [PTR_W-1:0] read_ptr, write_ptr;
  reg [CNT_W-1:0] used;
  reg [QUIET_W-1:0] quiet;
  reg awaiting_response;
  reg [255:0] fifo [0:FIFO_DEPTH-1];

  wire [255:0] head = fifo[read_ptr];
  wire [7:0] kind = head[7:0];
  wire [6:0] funct = head[14:8];
  wire [64:0] relocated_rs1 = {1'b0,head[127:64]} + {33'b0,frame};
  wire [64:0] relocated_rs2 = {1'b0,head[191:128]} + {33'b0,frame};
  wire rs1_bad = head[16] && (|relocated_rs1[64:32] || !relocated_rs1[31]);
  wire rs2_bad = head[17] && (|relocated_rs2[64:32] || !relocated_rs2[31]);
  // Raw commands never request a CPU register response. Counter reads (126)
  // and unknown command encodings are excluded from a streamed table.
  wire bad_head = head[255:192] != 0 || head[63:18] != 0 || head[15] ||
                 kind > 2 || (kind == 0 && (funct > 21 || rs1_bad || rs2_bad)) ||
                 (kind != 0 && (head[17:8] != 0 || head[191:128] != 0)) ||
                 (kind == 1 && head[127:64] != 0);
  wire take_head = state == RUN && used != 0 && !cmd_valid && !bad_head;
  wire request_fire = mem_req_valid && mem_req_ready;
  wire response_fire = mem_resp_valid && mem_resp_ready;
  wire push = response_fire && !mem_resp_error && state != FAULT_DRAIN;
  wire command_fire = cmd_valid && cmd_ready;
  wire timeout_hit = (state == RUN || state == DRAIN) && timeout_limit != 0 &&
                     elapsed >= timeout_limit;
  wire format_error = state == RUN && used != 0 && !cmd_valid && bad_head;
  wire transport_error = response_fire && mem_resp_error;
  wire active_error = (state == RUN || state == DRAIN || state == HOST) &&
                     (transport_error || format_error || timeout_hit || gemmini_fault);
  wire drained = !gemmini_busy && !cmd_valid && quiet == QUIET_CYCLES;
  // Up to 65535 entries; widened end arithmetic rejects 32-bit wraparound.
  wire [32:0] table_end = {1'b0,table_base} + {12'b0,table_count[15:0],5'b0};
  wire descriptor_bad = table_base[4:0] != 0 || !table_base[31] ||
                        table_count == 0 || table_count[31:16] != 0 ||
                        table_end > 33'h100000000;

  assign start_ready = (state == IDLE || state == DONE || state == FAULT) &&
                       !gemmini_busy && !gemmini_fault && !mem_req_valid &&
                       !awaiting_response && !cmd_valid;
  assign owns_gemmini = state == RUN || state == DRAIN || state == HOST || state == FAULT_DRAIN;
  // HOST is a fully drained handoff, so CPU fences/RVV can run there. FAULT_DRAIN
  // stays busy until real transactions drain; a timeout never fabricates idle.
  assign fence_busy = state == RUN || state == DRAIN || state == FAULT_DRAIN;
  assign done = state == DONE;
  assign host_wait = state == HOST;
  assign fault = error_code != 0;
  assign state_out = state;
  assign fifo_level = {{(32-CNT_W){1'b0}},used};
  assign mem_resp_ready = awaiting_response || request_fire;

  always @(posedge clock) begin
    if (reset) begin
      state <= IDLE;
      drain_reason <= BARRIER;
      base <= 0; count <= 0; frame <= 0; timeout_limit <= 0; elapsed <= 0;
      fetch_index <= 0; fetched <= 0; issued <= 0; cursor <= 0; completed_cursor <= 0;
      read_ptr <= 0; write_ptr <= 0; used <= 0; quiet <= 0;
      awaiting_response <= 0; mem_req_valid <= 0; mem_req_address <= 0;
      cmd_valid <= 0; cmd_funct <= 0; cmd_rs1 <= 0; cmd_rs2 <= 0;
      error_code <= 0; host_tag <= 0;
    end else begin
      // A valid request/command is held stable through backpressure, including
      // timeout/error. Already offered transfers cannot be withdrawn.
      if (request_fire) begin
        mem_req_valid <= 0;
        awaiting_response <= 1;
        fetch_index <= fetch_index + 1;
      end
      if (response_fire) begin
        awaiting_response <= 0;
        if (!mem_resp_error) fetched <= fetched + 1;
      end
      if (command_fire) begin
        cmd_valid <= 0;
        issued <= issued + 1;
      end
      if (gemmini_busy || cmd_valid) quiet <= 0;
      else if (quiet < QUIET_CYCLES) quiet <= quiet + 1'b1;
      if ((state == RUN || state == DRAIN) && elapsed != 32'hffffffff)
        elapsed <= elapsed + 1;

      // There is at most one reserved read outside the FIFO. Allocation occurs
      // only with a free FIFO slot; consumption can only increase that space.
      if (state == RUN && !active_error && !mem_req_valid && !awaiting_response &&
          fetch_index < count && used < FIFO_DEPTH) begin
        mem_req_address <= base + (fetch_index << 5);
        mem_req_valid <= 1;
      end
      if (push) begin
        fifo[write_ptr] <= mem_resp_data;
        write_ptr <= (write_ptr == FIFO_DEPTH-1) ? 0 : write_ptr + 1'b1;
      end
      if (take_head && !active_error) begin
        read_ptr <= (read_ptr == FIFO_DEPTH-1) ? 0 : read_ptr + 1'b1;
        cursor <= cursor + 1;
        if (kind == 0) begin
          cmd_valid <= 1;
          cmd_funct <= funct;
          cmd_rs1 <= head[16] ? relocated_rs1[63:0] : head[127:64];
          cmd_rs2 <= head[17] ? relocated_rs2[63:0] : head[191:128];
        end else begin
          state <= DRAIN;
          quiet <= 0;
          drain_reason <= kind == 1 ? BARRIER : TO_HOST;
          if (kind == 2) host_tag <= head[127:64];
        end
      end
      case ({push, take_head && !active_error})
        2'b10: used <= used + 1'b1;
        2'b01: used <= used - 1'b1;
        default: ;
      endcase
      if (state == RUN && cursor == count && !cmd_valid) begin
        state <= DRAIN;
        drain_reason <= FINISH;
        quiet <= 0;
      end
      if (state == DRAIN && drained) begin
        if (drain_reason == BARRIER) begin
          completed_cursor <= cursor;
          state <= RUN;
        end else if (drain_reason == TO_HOST && !mem_req_valid && !awaiting_response) begin
          completed_cursor <= cursor;
          state <= HOST;
        end else if (drain_reason == FINISH && !mem_req_valid && !awaiting_response) begin
          completed_cursor <= cursor;
          state <= DONE;
        end
      end
      if (state == HOST && resume && resume_tag == host_tag) begin
        state <= RUN;
        elapsed <= 0;
        quiet <= 0;
      end
      if ((state == DONE || state == FAULT) && acknowledge) begin
        state <= IDLE;
        error_code <= 0;
      end
      if (state == FAULT_DRAIN && drained && !mem_req_valid && !awaiting_response) begin
        state <= FAULT;
        used <= 0;
      end
      if (active_error) begin
        state <= FAULT_DRAIN;
        error_code <= transport_error ? 8'd2 : format_error ? 8'd3 :
                      gemmini_fault ? 8'd5 : 8'd4;
      end
      if (start && start_ready) begin
        state <= descriptor_bad ? FAULT : RUN;
        error_code <= descriptor_bad ? 8'd1 : 8'd0;
        base <= table_base; count <= table_count; frame <= frame_base;
        timeout_limit <= timeout_cycles; elapsed <= 0; fetch_index <= 0;
        fetched <= 0; issued <= 0; cursor <= 0; completed_cursor <= 0;
        read_ptr <= 0; write_ptr <= 0; used <= 0; quiet <= 0; host_tag <= 0;
      end
    end
  end

`ifndef SYNTHESIS
  initial begin
    if (FIFO_DEPTH < 2 || QUIET_CYCLES < 2) $fatal(1,"invalid frontend parameters");
  end
  always @(posedge clock) if (!reset) begin
    if (used > FIFO_DEPTH) $fatal(1,"command FIFO overflow");
    if (mem_req_valid && awaiting_response) $fatal(1,"multiple reads outstanding");
    if (done && (gemmini_busy || cmd_valid || mem_req_valid || awaiting_response))
      $fatal(1,"premature completion");
  end
`endif
endmodule
