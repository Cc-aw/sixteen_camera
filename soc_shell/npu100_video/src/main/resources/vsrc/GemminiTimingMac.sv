// Two rising-edge stages. Stage 1 is the DSP P register. Stage 2 is
// either the packed-lane correction/add or an alignment register.
module GemminiTimingMac #(
  parameter integer PACKED = 1,
  parameter integer OUTPUT_WIDTH = 20
) (
  input wire clock,
  input wire signed [7:0] a, b0, b1,
  input wire signed [OUTPUT_WIDTH-1:0] c0, c1,
  output reg signed [OUTPUT_WIDTH-1:0] d0, d1
);
  generate if (PACKED != 0) begin : packed_lanes
    wire signed [26:0] w0 = {{19{b0[7]}}, b0};
    wire signed [26:0] w1 = {{19{b1[7]}}, b1};
    wire signed [26:0] packed_weights = w0 + (w1 <<< 18);
    (* use_dsp = "yes" *) reg signed [34:0] product_p;
    reg signed [OUTPUT_WIDTH-1:0] c0_r, c1_r;
    wire signed [OUTPUT_WIDTH-1:0] lo =
      {{(OUTPUT_WIDTH-16){product_p[15]}}, product_p[15:0]};
    wire signed [OUTPUT_WIDTH-1:0] hi =
      {{(OUTPUT_WIDTH-16){product_p[33]}}, product_p[33:18]};
    (* use_dsp = "no" *) wire [OUTPUT_WIDTH-1:0] sum0 = c0_r + lo;
    // hi + product_p[15] is exactly a*b1 for every signed INT8 input.
    (* use_dsp = "no" *) wire [OUTPUT_WIDTH-1:0] sum1 =
      c1_r + hi + {{(OUTPUT_WIDTH-1){1'b0}}, product_p[15]};
    always @(posedge clock) begin
      product_p <= packed_weights * a;
      c0_r <= c0;
      c1_r <= c1;
      d0 <= sum0;
      d1 <= sum1;
    end
  end else begin : separate_lanes
`ifdef SYNTHESIS
    wire [47:0] native_p0, native_p1;
    genvar lane;
    for(lane=0; lane<2; lane=lane+1) begin : dsp_lane
      wire signed [7:0] weight_in = lane == 0 ? b0 : b1;
      wire signed [OUTPUT_WIDTH-1:0] c_in = lane == 0 ? c0 : c1;
      wire [47:0] p;
      DSP48E2 #(
        .AREG(0), .BREG(0), .ACASCREG(0), .BCASCREG(0),
        .MREG(0), .PREG(1), .CREG(0),
        .ADREG(0), .DREG(0), .INMODEREG(0), .OPMODEREG(0),
        .ALUMODEREG(0), .CARRYINREG(0), .CARRYINSELREG(0),
        .AMULTSEL("A"), .BMULTSEL("B"), .USE_MULT("MULTIPLY"),
        .USE_SIMD("ONE48")
      ) mac (
        .CLK(clock), .A({{22{a[7]}}, a}), .B({{10{weight_in[7]}}, weight_in}),
        .C({{(48-OUTPUT_WIDTH){c_in[OUTPUT_WIDTH-1]}}, c_in}), .D(27'b0),
        .ACIN(30'b0), .BCIN(18'b0), .PCIN(48'b0),
        .ALUMODE(4'b0000), .INMODE(5'b00000), .OPMODE(9'b000110101),
        .CARRYIN(1'b0), .CARRYINSEL(3'b000), .CARRYCASCIN(1'b0), .MULTSIGNIN(1'b0),
        .CEA1(1'b1), .CEA2(1'b1), .CEB1(1'b1), .CEB2(1'b1),
        .CEC(1'b1), .CEM(1'b1), .CEP(1'b1), .CEAD(1'b1), .CED(1'b1),
        .CEALUMODE(1'b1), .CECTRL(1'b1), .CECARRYIN(1'b1), .CEINMODE(1'b1),
        .RSTA(1'b0), .RSTB(1'b0), .RSTC(1'b0), .RSTD(1'b0),
        .RSTM(1'b0), .RSTP(1'b0), .RSTCTRL(1'b0), .RSTINMODE(1'b0),
        .RSTALUMODE(1'b0), .RSTALLCARRYIN(1'b0), .P(p)
      );
      if(lane == 0) assign native_p0 = p;
      else assign native_p1 = p;
    end
    always @(posedge clock) begin
      d0 <= native_p0[OUTPUT_WIDTH-1:0];
      d1 <= native_p1[OUTPUT_WIDTH-1:0];
    end
`else
    reg signed [47:0] p0, p1;
    always @(posedge clock) begin
      p0 <= $signed(a) * $signed(b0) + $signed(c0);
      p1 <= $signed(a) * $signed(b1) + $signed(c1);
      d0 <= p0[OUTPUT_WIDTH-1:0];
      d1 <= p1[OUTPUT_WIDTH-1:0];
    end
`endif
  end endgenerate
endmodule
