// SPDX-License-Identifier: Apache-2.0
// custom3: funct[6:5]=channel (3=global), funct[4:0]=operation.
// Three independent readers; control traffic never waits for a running lane.
module GemminiFrontendCluster (
  input wire clock, reset,
  input wire control_valid, output wire control_ready,
  input wire [6:0] control_funct,
  input wire [63:0] control_rs1, control_rs2,
  input wire [4:0] control_rd, input wire control_xd,
  input wire [1:0] control_prv,
  output reg response_valid, input wire response_ready,
  output reg [4:0] response_rd, output reg [63:0] response_data,
  output wire interrupt, transport_busy,
  input wire [2:0] legacy_valid, output wire [2:0] legacy_ready,
  input wire [20:0] legacy_funct,
  input wire [191:0] legacy_rs1, legacy_rs2,
  output wire [2:0] stream_owner,
  output wire [2:0] gemmini_cmd_valid, input wire [2:0] gemmini_cmd_ready,
  output wire [20:0] gemmini_cmd_funct,
  output wire [191:0] gemmini_cmd_rs1, gemmini_cmd_rs2,
  input wire [2:0] gemmini_busy, gemmini_fault,
  output wire [2:0] mem_req_valid, input wire [2:0] mem_req_ready,
  output wire [95:0] mem_req_address,
  input wire [2:0] mem_resp_valid, output wire [2:0] mem_resp_ready,
  input wire [767:0] mem_resp_data, input wire [2:0] mem_resp_error
);
  reg [63:0] cycle;
  reg [2:0] armed, irq_enable;
  wire [2:0] ready, engine_owner, complete, host_wait, fault, fence_busy;
  wire [2:0] launch, arm_pulse, cancel, available;
  wire [2:0] events = complete | host_wait | fault;
  wire [2:0] pending = events & irq_enable;
  wire fire = control_valid && control_ready && control_prv == 3;
  wire [1:0] channel = control_funct[6:5];
  wire [4:0] op = control_funct[4:0];
  wire global_arm = fire && channel == 3 && op == 7 &&
      control_rs1 != 0 && control_rs1[63:3] == 0 && control_rs2[63:3] == 0 &&
      (control_rs1[2:0] & ~available) == 0;
  wire [63:0] read_value [0:2];
  reg [63:0] selected_read;
  assign control_ready = !response_valid || response_ready;
  assign interrupt = |pending;
  assign transport_busy = response_valid;

  always @* begin
    selected_read = 64'hfffffffffffffffe;
    if (channel != 3) selected_read = read_value[channel];
    else case (control_rs1)
      0: selected_read = {32'h00020000, 13'b0, events, 5'b0, irq_enable, 5'b0, pending};
      1: selected_read = {37'b0, armed, 5'b0, available, 5'b0, gemmini_busy, 5'b0, stream_owner};
      2: selected_read = cycle;
      default: ;
    endcase
  end

  always @(posedge clock) begin
    if (reset) begin
      cycle <= 0; response_valid <= 0; response_rd <= 0; response_data <= 0;
    end else begin
      cycle <= cycle + 1'b1;
      if (response_ready) response_valid <= 0;
      if (control_valid && control_ready) begin
        response_valid <= control_xd;
        response_rd <= control_rd;
        response_data <= 64'hffffffffffffffff;
        if (fire) begin
          if (op == 3 && control_rs2 == 0) response_data <= selected_read;
          else if (global_arm) response_data <= 0;
          else if (channel != 3) begin
            case (op)
              0,1: if (available[channel] && control_rs1[63:32] == 0 && control_rs2[63:32] == 0) response_data <= 0;
              2: if (launch[channel] && !armed[channel]) response_data <= 0;
              4: if (host_wait[channel] && control_rs1 == read_value[channel] && control_rs2 == 0) response_data <= 0;
              5: if ((complete[channel] || fault[channel]) && !engine_owner[channel] && control_rs1 == 0 && control_rs2 == 0) response_data <= 0;
              6: if (available[channel] && control_rs2 == 0) response_data <= 0;
              7: if (arm_pulse[channel]) response_data <= 0;
              8: if (cancel[channel]) response_data <= 0;
              default: ;
            endcase
          end
        end
      end
    end
  end

  genvar g;
  generate for (g=0; g<3; g=g+1) begin: lanes
    reg [31:0] base, length, frame, deadline;
    reg [63:0] release_cycle, last_start;
    wire [7:0] error_code;
    wire [31:0] fetched, issued, cursor, completed_cursor, fifo_level;
    wire [63:0] host_tag;
    wire [3:0] state;
    wire feeder_valid, feeder_ready;
    wire [6:0] feeder_funct;
    wire [63:0] feeder_rs1, feeder_rs2;
    wire select_lane = fire && channel == g;
    assign available[g] = ready[g] && !armed[g] && !legacy_valid[g] && !events[g];
    assign cancel[g] = select_lane && op == 8 && armed[g] && control_rs1 == 0 && control_rs2 == 0;
    assign arm_pulse[g] = (global_arm && control_rs1[g]) ||
        (select_lane && op == 7 && available[g] && control_rs1[63:1] == 0 && control_rs2 == 0);
    assign launch[g] = (armed[g] && cycle >= release_cycle && ready[g] && !cancel[g]) ||
        (select_lane && op == 2 && available[g] && control_rs1[63:1] == 0 && control_rs2 == 0);
    assign stream_owner[g] = engine_owner[g] || armed[g];
    assign legacy_ready[g] = !stream_owner[g] && !launch[g] && !arm_pulse[g] && gemmini_cmd_ready[g];
    assign gemmini_cmd_valid[g] = engine_owner[g] ? feeder_valid :
        legacy_valid[g] && !armed[g] && !launch[g] && !arm_pulse[g];
    assign gemmini_cmd_funct[g*7+:7] = engine_owner[g] ? feeder_funct : legacy_funct[g*7+:7];
    assign gemmini_cmd_rs1[g*64+:64] = engine_owner[g] ? feeder_rs1 : legacy_rs1[g*64+:64];
    assign gemmini_cmd_rs2[g*64+:64] = engine_owner[g] ? feeder_rs2 : legacy_rs2[g*64+:64];
    assign feeder_ready = engine_owner[g] && gemmini_cmd_ready[g];
    wire [63:0] status = {32'h00020000, fifo_level[15:0], error_code,
        armed[g],fence_busy[g],gemmini_busy[g],available[g],fault[g],host_wait[g],complete[g],stream_owner[g]};
    // RESUME response validation needs the tag regardless of rs1 query.
    assign read_value[g] = op == 4 ? host_tag :
        control_rs1 == 0 ? status :
        control_rs1 == 1 ? {fetched,issued} :
        control_rs1 == 2 ? {completed_cursor,cursor} :
        control_rs1 == 3 ? host_tag :
        control_rs1 == 4 ? {60'b0,state} :
        control_rs1 == 5 ? release_cycle :
        control_rs1 == 6 ? last_start : 64'hfffffffffffffffe;
    wire acknowledge = select_lane && op == 5 && !armed[g] && control_rs1 == 0 && control_rs2 == 0;
    always @(posedge clock) begin
      if (reset) begin
        base <= 0; length <= 0; frame <= 0; deadline <= 0;
        release_cycle <= 0; last_start <= 0; armed[g] <= 0; irq_enable[g] <= 0;
      end else begin
        if (select_lane && available[g]) begin
          if (control_rs1[63:32] == 0 && control_rs2[63:32] == 0) begin
            if (op == 0) begin base <= control_rs1[31:0]; length <= control_rs2[31:0]; end
            if (op == 1) begin frame <= control_rs1[31:0]; deadline <= control_rs2[31:0]; end
          end
          if (op == 6 && control_rs2 == 0) release_cycle <= control_rs1;
        end
        if (arm_pulse[g]) begin
          armed[g] <= 1;
          irq_enable[g] <= global_arm ? control_rs2[g] : control_rs1[0];
        end
        if (launch[g]) begin
          last_start <= cycle; armed[g] <= 0;
          if (!armed[g]) irq_enable[g] <= control_rs1[0];
        end
        if (cancel[g]) begin armed[g] <= 0; irq_enable[g] <= 0; end
        if (acknowledge && (complete[g] || state == 6)) irq_enable[g] <= 0;
      end
    end
    GemminiCommandFrontend engine (
      .clock(clock), .reset(reset), .start(launch[g]), .start_ready(ready[g]),
      .table_base(base), .table_count(length), .frame_base(frame), .timeout_cycles(deadline),
      .resume(select_lane && op == 4 && control_rs2 == 0), .resume_tag(control_rs1),
      .acknowledge(acknowledge), .owns_gemmini(engine_owner[g]), .fence_busy(fence_busy[g]),
      .done(complete[g]), .host_wait(host_wait[g]), .fault(fault[g]), .error_code(error_code),
      .fetched(fetched), .issued(issued), .cursor(cursor), .completed_cursor(completed_cursor),
      .host_tag(host_tag), .state_out(state), .fifo_level(fifo_level),
      .mem_req_valid(mem_req_valid[g]), .mem_req_ready(mem_req_ready[g]),
      .mem_req_address(mem_req_address[g*32+:32]), .mem_resp_valid(mem_resp_valid[g]),
      .mem_resp_ready(mem_resp_ready[g]), .mem_resp_data(mem_resp_data[g*256+:256]),
      .mem_resp_error(mem_resp_error[g]), .cmd_valid(feeder_valid), .cmd_ready(feeder_ready),
      .cmd_funct(feeder_funct), .cmd_rs1(feeder_rs1), .cmd_rs2(feeder_rs2),
      .gemmini_busy(gemmini_busy[g]), .gemmini_fault(gemmini_fault[g])
    );
  end endgenerate
endmodule
