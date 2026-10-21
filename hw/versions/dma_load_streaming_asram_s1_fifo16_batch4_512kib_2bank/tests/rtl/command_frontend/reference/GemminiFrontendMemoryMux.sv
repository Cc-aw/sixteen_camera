// SPDX-License-Identifier: Apache-2.0
// Share one existing TL-UL port without changing the generated fabric's IDs.
// Source 31 is dynamically leased, never assumed unused by Gemmini.
module GemminiFrontendMemoryMux (
  input wire clock, reset,
  input wire f_req_valid, output wire f_req_ready, input wire [31:0] f_req_address,
  output wire f_resp_valid, input wire f_resp_ready,
  output wire [255:0] f_resp_data, output wire f_resp_error,
  input wire g_a_valid, output wire g_a_ready,
  input wire [2:0] g_a_opcode, g_a_param, input wire [3:0] g_a_size,
  input wire [4:0] g_a_source, input wire [31:0] g_a_address, g_a_mask,
  input wire [255:0] g_a_data, input wire g_a_corrupt,
  output wire g_d_valid, input wire g_d_ready,
  output wire [2:0] g_d_opcode, output wire [1:0] g_d_param,
  output wire [3:0] g_d_size, output wire [4:0] g_d_source,
  output wire [4:0] g_d_sink, output wire g_d_denied, output wire [255:0] g_d_data, output wire g_d_corrupt,
  output wire a_valid, input wire a_ready,
  output wire [2:0] a_opcode, a_param, output wire [3:0] a_size,
  output wire [4:0] a_source, output wire [31:0] a_address, a_mask,
  output wire [255:0] a_data, output wire a_corrupt,
  input wire d_valid, output wire d_ready,
  input wire [2:0] d_opcode, input wire [1:0] d_param,
  input wire [3:0] d_size, input wire [4:0] d_source,
  input wire [4:0] d_sink, input wire d_denied, input wire [255:0] d_data, input wire d_corrupt
);
  reg locked, selected_f, prefer_f;
  reg [10:0] a_left, d31_left;
  reg id31_busy, id31_frontend;
  wire eligible_f = f_req_valid && !id31_busy;
  wire eligible_g = g_a_valid && (g_a_source != 31 || !id31_busy || a_left != 0);
  wire choose_f = locked ? selected_f : eligible_f && (!eligible_g || prefer_f);
  assign a_valid = locked ? (choose_f ? f_req_valid : g_a_valid) : eligible_f || eligible_g;
  assign a_opcode = choose_f ? 3'd4 : g_a_opcode;
  assign a_param = choose_f ? 3'd0 : g_a_param;
  assign a_size = choose_f ? 4'd5 : g_a_size;
  assign a_source = choose_f ? 5'd31 : g_a_source;
  assign a_address = choose_f ? f_req_address : g_a_address;
  assign a_mask = choose_f ? 32'hffffffff : g_a_mask;
  assign a_data = choose_f ? 256'b0 : g_a_data;
  assign a_corrupt = !choose_f && g_a_corrupt;
  assign f_req_ready = a_ready && a_valid && choose_f;
  assign g_a_ready = a_ready && a_valid && !choose_f;
  wire a_fire = a_valid && a_ready;
  wire first_a = a_left == 0;
  wire allocate31 = a_fire && first_a && a_source == 31;
  // A same-cycle response is legal. Use the just-accepted A's owner if needed.
  wire response_f = d_source == 31 && (id31_busy ? id31_frontend : allocate31 && choose_f);
  assign f_resp_valid = d_valid && response_f;
  assign f_resp_data = d_data;
  assign f_resp_error = d_denied || d_corrupt || d_opcode != 1 || d_size != 5;
  assign g_d_valid = d_valid && !response_f;
  assign g_d_opcode = d_opcode;
  assign g_d_param = d_param;
  assign g_d_size = d_size;
  assign g_d_source = d_source;
  assign g_d_sink = d_sink;
  assign g_d_denied = d_denied;
  assign g_d_data = d_data;
  assign g_d_corrupt = d_corrupt;
  assign d_ready = response_f ? f_resp_ready : g_d_ready;
  wire d31_fire = d_valid && d_ready && d_source == 31;
  function automatic [10:0] extra_beats(input [3:0] size);
    extra_beats = size > 5 ? (11'd1 << (size - 5)) - 1'b1 : 0;
  endfunction
  wire [10:0] initial_a_left = a_opcode <= 1 ? extra_beats(a_size) : 0;
  wire [10:0] initial_d_left = d_opcode == 1 ? extra_beats(d_size) : 0;
  always @(posedge clock) begin
    if (reset) begin
      locked <= 0; selected_f <= 0; prefer_f <= 1;
      a_left <= 0; d31_left <= 0; id31_busy <= 0; id31_frontend <= 0;
    end else begin
      if (a_valid && !a_ready) begin locked <= 1; selected_f <= choose_f; end
      if (a_fire) begin
        a_left <= first_a ? initial_a_left : a_left - 1'b1;
        locked <= first_a ? initial_a_left != 0 : a_left != 1;
        selected_f <= choose_f;
        prefer_f <= !choose_f;
      end
      if (allocate31) begin id31_busy <= 1; id31_frontend <= choose_f; end
      if (d31_fire) begin
        d31_left <= d31_left == 0 ? initial_d_left : d31_left - 1'b1;
        if ((d31_left == 0 && initial_d_left == 0) || d31_left == 1) id31_busy <= 0;
      end
    end
  end
`ifndef SYNTHESIS
  always @(posedge clock) if (!reset) begin
    if (allocate31 && id31_busy) $fatal(1,"TL source31 reused before response");
    if (d31_fire && !id31_busy && !allocate31) $fatal(1,"TL response without source31 owner");
  end
`endif
endmodule
