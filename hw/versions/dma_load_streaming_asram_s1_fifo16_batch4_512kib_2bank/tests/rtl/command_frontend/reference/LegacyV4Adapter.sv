// SPDX-License-Identifier: Apache-2.0
// Board adapter: custom2 control/status, a TL-UL 256-bit physical read master,
// and exclusive arbitration between a legacy custom1 CPU port and the feeder.
module GemminiFrontendRoCC (
  input wire clock, reset,
  input wire control_valid,
  output wire control_ready,
  input wire [6:0] control_funct,
  input wire [63:0] control_rs1, control_rs2,
  input wire [4:0] control_rd,
  input wire control_xd,
  input wire [1:0] control_prv,
  output reg response_valid,
  input wire response_ready,
  output reg [4:0] response_rd,
  output reg [63:0] response_data,
  output wire interrupt, busy,
  input wire legacy_valid,
  output wire legacy_ready,
  input wire [6:0] legacy_funct,
  input wire [63:0] legacy_rs1, legacy_rs2,
  output wire stream_owner,
  output wire gemmini_cmd_valid,
  input wire gemmini_cmd_ready,
  output wire [6:0] gemmini_cmd_funct,
  output wire [63:0] gemmini_cmd_rs1, gemmini_cmd_rs2,
  input wire gemmini_busy, gemmini_fault,
  output wire tl_a_valid,
  input wire tl_a_ready,
  output wire [31:0] tl_a_address,
  input wire tl_d_valid,
  output wire tl_d_ready,
  input wire [2:0] tl_d_opcode,
  input wire [3:0] tl_d_size,
  input wire [4:0] tl_d_source,
  input wire [255:0] tl_d_data,
  input wire tl_d_denied, tl_d_corrupt
);
  reg [31:0] base, length, frame, deadline;
  reg irq_enable;
  wire start_ready, complete, host_wait, fault, feeder_valid, feeder_ready;
  wire [7:0] error_code;
  wire [31:0] fetched, issued, cursor, completed_cursor, fifo_level;
  wire [63:0] host_tag;
  wire [3:0] state;
  wire [6:0] feeder_funct;
  wire [63:0] feeder_rs1, feeder_rs2;
  wire ctrl_fire = control_valid && control_ready;
  wire launch = ctrl_fire && control_funct == 2 && control_prv == 3 &&
                start_ready && !legacy_valid && control_rs1[63:1] == 0 && control_rs2 == 0;
  wire [63:0] status = {32'h00010000, fifo_level[15:0], error_code,
                        1'b0,busy,gemmini_busy,start_ready,fault,host_wait,complete,stream_owner};
  reg [63:0] read_value;
  always @* begin
    case (control_rs1)
      0: read_value = status;
      1: read_value = {fetched,issued};
      2: read_value = {completed_cursor,cursor};
      3: read_value = host_tag;
      4: read_value = {60'b0,state};
      default: read_value = 64'hfffffffffffffffe;
    endcase
  end
  assign control_ready = !response_valid || response_ready;
  assign interrupt = irq_enable && (complete || host_wait || fault);
  assign legacy_ready = !stream_owner && !launch && gemmini_cmd_ready;
  assign gemmini_cmd_valid = stream_owner ? feeder_valid : legacy_valid && !launch;
  assign gemmini_cmd_funct = stream_owner ? feeder_funct : legacy_funct;
  assign gemmini_cmd_rs1 = stream_owner ? feeder_rs1 : legacy_rs1;
  assign gemmini_cmd_rs2 = stream_owner ? feeder_rs2 : legacy_rs2;
  assign feeder_ready = stream_owner && gemmini_cmd_ready;
  always @(posedge clock) begin
    if (reset) begin
      base <= 0; length <= 0; frame <= 0; deadline <= 0;
      irq_enable <= 0; response_valid <= 0; response_rd <= 0; response_data <= 0;
    end else begin
      if (response_ready) response_valid <= 0;
      if (ctrl_fire) begin
        response_valid <= control_xd;
        response_rd <= control_rd;
        response_data <= 64'hffffffffffffffff;
        if (control_prv == 3) begin
          case (control_funct)
            0: if (start_ready && control_rs1[63:32] == 0 && control_rs2[63:32] == 0) begin
              base <= control_rs1[31:0]; length <= control_rs2[31:0]; response_data <= 0;
            end
            1: if (start_ready && control_rs1[63:32] == 0 && control_rs2[63:32] == 0) begin
              frame <= control_rs1[31:0]; deadline <= control_rs2[31:0]; response_data <= 0;
            end
            2: if (launch) begin irq_enable <= control_rs1[0]; response_data <= 0; end
            3: response_data <= read_value;
            4: if (host_wait && control_rs1 == host_tag && control_rs2 == 0) response_data <= 0;
            5: if ((complete || state == 6) && control_rs1 == 0 && control_rs2 == 0) begin
              irq_enable <= 0; response_data <= 0;
            end
            default: ;
          endcase
        end
      end
    end
  end
  GemminiCommandFrontend engine (
    .clock(clock), .reset(reset), .start(launch), .start_ready(start_ready),
    .table_base(base), .table_count(length), .frame_base(frame), .timeout_cycles(deadline),
    .resume(ctrl_fire && control_prv == 3 && control_funct == 4 && control_rs2 == 0),
    .resume_tag(control_rs1),
    .acknowledge(ctrl_fire && control_prv == 3 && control_funct == 5 && control_rs1 == 0 && control_rs2 == 0),
    .owns_gemmini(stream_owner), .fence_busy(busy), .done(complete), .host_wait(host_wait),
    .fault(fault), .error_code(error_code), .fetched(fetched), .issued(issued),
    .cursor(cursor), .completed_cursor(completed_cursor), .host_tag(host_tag),
    .state_out(state), .fifo_level(fifo_level),
    .mem_req_valid(tl_a_valid), .mem_req_ready(tl_a_ready), .mem_req_address(tl_a_address),
    .mem_resp_valid(tl_d_valid), .mem_resp_ready(tl_d_ready), .mem_resp_data(tl_d_data),
    .mem_resp_error(tl_d_denied || tl_d_corrupt || tl_d_opcode != 1 || tl_d_size != 5 || tl_d_source != 0),
    .cmd_valid(feeder_valid), .cmd_ready(feeder_ready), .cmd_funct(feeder_funct),
    .cmd_rs1(feeder_rs1), .cmd_rs2(feeder_rs2), .gemmini_busy(gemmini_busy), .gemmini_fault(gemmini_fault)
  );
endmodule
