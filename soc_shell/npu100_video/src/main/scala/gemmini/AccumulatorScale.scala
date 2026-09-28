
package gemmini

import chisel3._
import chisel3.experimental.IntParam
import chisel3.util._
import hardfloat.{INToRecFN, MulRawFN, RecFNToIN, RoundRawFNToRecFN, consts, rawFloatFromRecFN, recFNFromFN}
import Util._

class AccumulatorReadRespWithFullData[T <: Data: Arithmetic, U <: Data](fullDataType: Vec[Vec[T]], scale_t: U)
  extends Bundle {
  val resp = new AccumulatorReadResp(fullDataType, scale_t)
  val full_data = fullDataType.cloneType
}

class AccumulatorScaleResp[T <: Data: Arithmetic](fullDataType: Vec[Vec[T]], rDataType: Vec[Vec[T]]) extends Bundle {
  val full_data = fullDataType.cloneType
  val data = rDataType.cloneType
  val acc_bank_id = UInt(2.W)
  val fromDMA = Bool()
}

class AccumulatorScaleIO[T <: Data: Arithmetic, U <: Data](
  fullDataType: Vec[Vec[T]], scale_t: U,
  rDataType: Vec[Vec[T]]
) extends Bundle {
  val in = Flipped(Decoupled(new NormalizedOutput[T,U](fullDataType, scale_t)))
  val out = Decoupled(new AccumulatorScaleResp[T](fullDataType, rDataType))
  val silu_lut_write = Flipped(Valid(new SiluLutWrite))
  val silu_lut_ready = Output(Bool())
}

/**
  * Synchronous BRAM-backed SiLU lookup table shared by NUM_READ_PORTS
  * activation lanes. Each RAMB36E2 serves two read ports, so the table is
  * replicated NUM_READ_PORTS/2 times. The table initializes to identity on
  * reset and accepts software updates through a single write port that
  * borrows the two read ports for one cycle. The synchronous read latency is
  * matched by the LUT-enabled token stage in AccScalePipe.
  */
class SiluLutBramMulti(numReadPorts: Int) extends BlackBox(Map(
    "NUM_READ_PORTS" -> IntParam(numReadPorts))) with HasBlackBoxInline {
  require(numReadPorts >= 2 && numReadPorts % 2 == 0,
    "SiluLutBramMulti needs an even number of read ports >= 2")

  val io = IO(new Bundle {
    val clock = Input(Clock())
    val reset = Input(Reset())
    val write_valid = Input(Bool())
    val write_base = Input(UInt(8.W))
    val write_data = Input(UInt(64.W))
    val read_addr = Input(UInt((8 * numReadPorts).W))
    val read_data = Output(UInt((8 * numReadPorts).W))
    val ready = Output(Bool())
  })

  override def desiredName: String = "SiluLutBramMulti"

  setInline("SiluLutBramMulti.sv",
    s"""// Parameterized 256-entry INT8 SiLU table in replicated dual-port BRAMs.
      |// Each RAMB36E2 serves two read ports; NUM_READ_PORTS lanes share
      |// NUM_READ_PORTS/2 primitives. Port A and port B are both read ports
      |// during inference, and double as write ports while the identity table
      |// is initialized or a software table update is accepted. DOA_REG and
      |// DOB_REG are disabled, so the read latency is synchronous and is
      |// matched by the LUT-enabled AccScalePipe token stage.
      |// SILU_LUT_STORAGE=BRAM
      |module SiluLutBramMulti #(
      |  parameter integer NUM_READ_PORTS = $numReadPorts
      |) (
      |  input  wire         clock,
      |  input  wire         reset,
      |  input  wire         write_valid,
      |  input  wire [7:0]   write_base,
      |  input  wire [63:0]  write_data,
      |  input  wire [8*NUM_READ_PORTS-1:0] read_addr,
      |  output wire [8*NUM_READ_PORTS-1:0] read_data,
      |  output wire         ready
      |);
      |  reg [5:0] init_count;
      |  wire init_active = reset || (init_count < 6'd32);
      |  wire [4:0] init_row = init_count[4:0];
      |  wire [7:0] init_base = {init_row, 3'b000};
      |  wire [31:0] init_low = {init_base + 8'd3, init_base + 8'd2,
      |                          init_base + 8'd1, init_base};
      |  wire [31:0] init_high = {init_base + 8'd7, init_base + 8'd6,
      |                           init_base + 8'd5, init_base + 8'd4};
      |  wire [4:0] write_row = init_active ? init_row : write_base[7:3];
      |  wire [31:0] write_low = init_active ? init_low : write_data[31:0];
      |  wire [31:0] write_high = init_active ? init_high : write_data[63:32];
      |  wire write_en = init_active || write_valid;
      |  assign ready = !init_active;
      |
      |  always @(posedge clock) begin
      |    if (reset)
      |      init_count <= 6'd0;
      |    else if (init_count < 6'd32)
      |      init_count <= init_count + 6'd1;
      |  end
      |
      |  wire [31:0] dout_a [0:NUM_READ_PORTS/2-1];
      |  wire [31:0] dout_b [0:NUM_READ_PORTS/2-1];
      |
      |  genvar k;
      |  generate
      |    for (k = 0; k < NUM_READ_PORTS/2; k = k + 1) begin : g_silu_lut_bram
      |      wire [7:0] read_addr_a = read_addr[(2*k)*8 +: 8];
      |      wire [7:0] read_addr_b = read_addr[(2*k+1)*8 +: 8];
      |      reg [1:0] read_byte_a;
      |      reg [1:0] read_byte_b;
      |
      |      // DOA_REG/DOB_REG=0 avoids an extra output register. RAMB36E2
      |      // remains synchronous-read; the AccScalePipe staging accounts for
      |      // that cycle. A software table update uses the same two ports as
      |      // the read path: during that cycle, select the requested row and
      |      // the low/high word; otherwise each port selects its independent
      |      // inference address.
      |      wire [5:0] port_a_word = write_en ? {write_row, 1'b0} :
      |                              {read_addr_a[7:3], read_addr_a[2]};
      |      wire [5:0] port_b_word = write_en ? {write_row, 1'b1} :
      |                              {read_addr_b[7:3], read_addr_b[2]};
      |
      |      RAMB36E2 #(
      |        .DOA_REG(0),
      |        .DOB_REG(0),
      |        .CLOCK_DOMAINS("COMMON"),
      |        .READ_WIDTH_A(36),
      |        .READ_WIDTH_B(36),
      |        .WRITE_WIDTH_A(36),
      |        .WRITE_WIDTH_B(36),
      |        .WRITE_MODE_A("WRITE_FIRST"),
      |        .WRITE_MODE_B("WRITE_FIRST")
      |      ) lut_ram (
      |        .ADDRARDADDR({4'b0, port_a_word, 5'b0}),
      |        .ADDRBWRADDR({4'b0, port_b_word, 5'b0}),
      |        .ADDRENA(1'b1),
      |        .ADDRENB(1'b1),
      |        .CLKARDCLK(clock),
      |        .CLKBWRCLK(clock),
      |        .ENARDEN(1'b1),
      |        .ENBWREN(1'b1),
      |        .WEA({4{write_en}}),
      |        .WEBWE({4'b0, {4{write_en}}}),
      |        .DINADIN(write_low),
      |        .DINPADINP(4'b0),
      |        .DINBDIN(write_high),
      |        .DINPBDINP(4'b0),
      |        .DOUTADOUT(dout_a[k]),
      |        .DOUTPADOUTP(),
      |        .DOUTBDOUT(dout_b[k]),
      |        .DOUTPBDOUTP(),
      |        .CASDIMUXA(1'b0),
      |        .CASDIMUXB(1'b0),
      |        .CASDINA(32'b0),
      |        .CASDINB(32'b0),
      |        .CASDINPA(4'b0),
      |        .CASDINPB(4'b0),
      |        .CASDOMUXA(1'b0),
      |        .CASDOMUXB(1'b0),
      |        .CASDOMUXEN_A(1'b0),
      |        .CASDOMUXEN_B(1'b0),
      |        .CASINDBITERR(1'b0),
      |        .CASINSBITERR(1'b0),
      |        .CASOREGIMUXA(1'b0),
      |        .CASOREGIMUXB(1'b0),
      |        .CASOREGIMUXEN_A(1'b0),
      |        .CASOREGIMUXEN_B(1'b0),
      |        .ECCPIPECE(1'b0),
      |        .INJECTDBITERR(1'b0),
      |        .INJECTSBITERR(1'b0),
      |        .REGCEAREGCE(1'b1),
      |        .REGCEB(1'b1),
      |        .RSTRAMARSTRAM(1'b0),
      |        .RSTRAMB(1'b0),
      |        .RSTREGARSTREG(1'b0),
      |        .RSTREGB(1'b0),
      |        .SLEEP(1'b0)
      |      );

      |      always @(posedge clock) begin
      |        // DOUT is synchronous, so the byte selector must be sampled
      |        // with the same address as the RAM word.
      |        read_byte_a <= read_addr_a[1:0];
      |        read_byte_b <= read_addr_b[1:0];
      |      end
      |
      |      function automatic [7:0] pick_byte(input [31:0] value,
      |                                         input [1:0] index);
      |        case (index)
      |          2'd0: pick_byte = value[7:0];
      |          2'd1: pick_byte = value[15:8];
      |          2'd2: pick_byte = value[23:16];
      |          default: pick_byte = value[31:24];
      |        endcase
      |      endfunction
      |
      |      assign read_data[(2*k)*8 +: 8] =
      |        pick_byte(dout_a[k], read_byte_a);
      |      assign read_data[(2*k+1)*8 +: 8] =
      |        pick_byte(dout_b[k], read_byte_b);
      |    end
      |  endgenerate
      |endmodule
      |""".stripMargin)
}

class AccScaleDataWithIndex[T <: Data: Arithmetic, U <: Data](t: T, u: U) extends Bundle {
  val scale = u.cloneType
  val act = UInt(Activation.bitwidth.W)
  val igelu_qb = t.cloneType
  val igelu_qc = t.cloneType
  val iexp_qln2 = t.cloneType
  val iexp_qln2_inv = t.cloneType
  val mean = t.cloneType
  val max = t.cloneType
  val inv_stddev = u.cloneType
  val inv_sum_exp = u.cloneType
  val data = t.cloneType
  val full_data = t.cloneType
  val id = UInt(2.W) // TODO hardcoded
  val index = UInt()
}

/**
  * Pipelined scale+activation lane with timing-critical staging.
  *
  * The previous single-cycle implementation chained pre-activation, the
  * FP32 scale multiply (hardfloat INToRecFN + MulAddRecFN + RecFNToIN),
  * the clip to the small output width, and the LEAKY_RELU/SiLU select into
  * one combinational blob whose tail ended at the SiLU table address or at
  * the output register (79 logic levels in the placed XCVU13P design).
  * This version cuts the chain into three register stages:
  *
  *   Stage 1: pre-activation muxes (RELU/LAYERNORM/IGELU/SOFTMAX)
  *   Stage 2: scale multiply via scale_func
  *   Stage 3: clip to small width and launch the SiLU table address.
  *            When the SiLU LUT is enabled, one additional token register
  *            aligns the synchronous BRAM response with the activation data.
  *
  * The LUT-enabled path spends one of the trailing Pipe registers on this
  * alignment stage, so the externally visible latency stays exactly
  * `latency` cycles.
  */
class AccScalePipe[T <: Data, U <: Data](t: T, rDataType: Vec[Vec[T]], scale_func: (T, U) => T, scale_t: U,
                                         latency: Int, has_nonlinear_activations: Boolean, has_normalizations: Boolean,
                                         has_silu_lut: Boolean = false, silu_only: Boolean = false)
                                        (implicit ev: Arithmetic[T]) extends Module {
  val u = scale_t
  require(latency >= 3,
    "AccScalePipe needs at least 3 latency slots for its internal stages")
  val io = IO(new Bundle {
    val in = Input(Valid(new AccScaleDataWithIndex(t, u)(ev)))
    val out = Output(Valid(new AccScaleDataWithIndex(t, u)(ev)))
    val silu_addr = Output(UInt(8.W))
    val silu_data = Input(UInt(8.W))
  })
  import ev._

  // ------------------------------------------------------------------
  // Stage 1: pre-activation (cheap muxes and adds only).
  // ------------------------------------------------------------------
  val s1_valid = RegNext(io.in.valid, false.B)
  val s1_bits = RegEnable(io.in.bits, io.in.valid)

  val e_act: T = if (silu_only) io.in.bits.data else MuxCase(io.in.bits.data, if (has_normalizations) Seq(
    (has_nonlinear_activations.B && io.in.bits.act === Activation.RELU) -> io.in.bits.data.relu,
    (has_nonlinear_activations.B && has_normalizations.B && io.in.bits.act === Activation.LAYERNORM) ->
      (io.in.bits.data - io.in.bits.mean),
    (has_nonlinear_activations.B && has_normalizations.B && io.in.bits.act === Activation.IGELU) ->
      AccumulatorScale.igelu(io.in.bits.data, io.in.bits.igelu_qb, io.in.bits.igelu_qc),
    (has_nonlinear_activations.B && has_normalizations.B && io.in.bits.act === Activation.SOFTMAX) ->
      AccumulatorScale.iexp(io.in.bits.data - io.in.bits.max, io.in.bits.iexp_qln2, io.in.bits.iexp_qln2_inv, io.in.bits.igelu_qb, io.in.bits.igelu_qc),
  ) else Seq(
    (has_nonlinear_activations.B && io.in.bits.act === Activation.RELU) -> io.in.bits.data.relu
  ))

  // make sure no normalizations gets passed in if no functional units present
  assert(has_normalizations.B || (!io.in.valid) ||
    (io.in.bits.act =/= Activation.LAYERNORM && io.in.bits.act =/= Activation.SOFTMAX && io.in.bits.act =/= Activation.IGELU))

  val s1_e_act = RegEnable(e_act, io.in.valid)

  val stagedFp16 = silu_only && t.isInstanceOf[SInt] && t.getWidth == 32 &&
    scale_t.isInstanceOf[Float] &&
    scale_t.asInstanceOf[Float].expWidth == 5 &&
    scale_t.asInstanceOf[Float].sigWidth == 11

  if (stagedFp16) {
    // The V2 path put INToRecFN + MulAddRecFN + RecFNToIN in one cycle
    // (39-45 levels, 10.5ns placed). V3 assigns one registered stage to
    // each operation and retains the configured eight-cycle interface.
    require(latency >= 6)
    val fp = scale_t.asInstanceOf[Float]

    val intToRec = Module(new INToRecFN(t.getWidth, fp.expWidth, fp.sigWidth))
    intToRec.io.signedIn := true.B
    intToRec.io.in := s1_e_act.asUInt
    intToRec.io.roundingMode := consts.round_near_even
    intToRec.io.detectTininess := consts.tininess_afterRounding
    val s2_valid = RegNext(s1_valid, false.B)
    val s2_int_rec = RegEnable(intToRec.io.out, s1_valid)
    val s2_scale_rec = RegEnable(
      recFNFromFN(fp.expWidth, fp.sigWidth, s1_bits.scale.asTypeOf(fp).bits),
      s1_valid)
    val s2_bits = RegEnable(s1_bits, s1_valid)

    // Split HardFloat's MulRecFN exactly at its MulRawFN/RoundRawFNToRecFN
    // boundary. This preserves its arithmetic bit-for-bit while allowing the
    // inferred 11x11 DSP multiply to end at a register.
    val mulRaw = Module(new MulRawFN(fp.expWidth, fp.sigWidth))
    mulRaw.io.a := rawFloatFromRecFN(fp.expWidth, fp.sigWidth, s2_int_rec)
    mulRaw.io.b := rawFloatFromRecFN(fp.expWidth, fp.sigWidth, s2_scale_rec)
    val s3_valid = RegNext(s2_valid, false.B)
    val s3_raw = RegEnable(mulRaw.io.rawOut, s2_valid)
    val s3_invalid = RegEnable(mulRaw.io.invalidExc, s2_valid)
    val s3_bits = RegEnable(s2_bits, s2_valid)

    val round = Module(new RoundRawFNToRecFN(fp.expWidth, fp.sigWidth, 0))
    round.io.invalidExc := s3_invalid
    round.io.infiniteExc := false.B
    round.io.in := s3_raw
    round.io.roundingMode := consts.round_near_even
    round.io.detectTininess := consts.tininess_afterRounding
    val s4_valid = RegNext(s3_valid, false.B)
    val s4_product = RegEnable(round.io.out, s3_valid)
    val s4_bits = RegEnable(s3_bits, s3_valid)

    val recToInt = Module(new RecFNToIN(fp.expWidth, fp.sigWidth, t.getWidth))
    recToInt.io.in := s4_product
    recToInt.io.roundingMode := consts.round_near_even
    recToInt.io.signedOut := true.B
    val overflow = recToInt.io.intExceptionFlags(1)
    val productSign = rawFloatFromRecFN(fp.expWidth, fp.sigWidth, s4_product).sign
    val maxsat = ((BigInt(1) << (t.getWidth - 1)) - 1).U(t.getWidth.W)
    val minsat = (BigInt(1) << (t.getWidth - 1)).U(t.getWidth.W)
    val scaledWire = Mux(overflow, Mux(productSign, minsat, maxsat), recToInt.io.out)
    val s5_valid = RegNext(s4_valid, false.B)
    val s5_data = RegEnable(scaledWire.asTypeOf(t), s4_valid)
    val s5_bits = RegEnable(s4_bits, s4_valid)

    val clippedPre = s5_data.clippedToWidthOf(rDataType.head.head)
    val s6_valid = RegNext(s5_valid, false.B)
    val s6_clip = RegEnable(clippedPre, s5_valid)
    val s6_bits = RegEnable(s5_bits, s5_valid)

    val silu_addr_hold = if (has_silu_lut) {
      RegNext(clippedPre.asUInt, 0.U(8.W))
    } else 0.U(8.W)
    io.silu_addr := silu_addr_hold

    // The FPGA RAM primitive returns the value for the address presented in
    // the previous cycle. Delay the token metadata once more so it stays
    // aligned with io.silu_data. The trailing Pipe below is shortened by one
    // register to preserve the configured external latency. Keep the old
    // pipeline when the LUT is disabled.
    val activation_valid = if (has_silu_lut) {
      require(latency >= 7,
        "SiLU BRAM alignment requires at least seven scale-pipeline stages")
      RegNext(s6_valid, false.B)
    } else s6_valid
    val activation_clip = if (has_silu_lut) RegEnable(s6_clip, s6_valid) else s6_clip
    val activation_bits = if (has_silu_lut) RegEnable(s6_bits, s6_valid) else s6_bits

    val activated: T = if (has_silu_lut) {
      Mux(activation_bits.act === Activation.SILU_LUT,
        io.silu_data.asTypeOf(activation_clip), activation_clip)
    } else {
      activation_clip
    }
    val out = Wire(Valid(new AccScaleDataWithIndex(t, u)(ev)))
    out.valid := activation_valid
    out.bits := activation_bits
    out.bits.data := activated
    io.out := Pipe(out, latency - (if (has_silu_lut) 7 else 6))
  } else {
      // ------------------------------------------------------------------
      // Stage 2: FP32 scale multiply (the hardfloat-heavy block).
      // ------------------------------------------------------------------
      val s2_valid = RegNext(s1_valid, false.B)
      val s2_bits = RegEnable(s1_bits, s1_valid)
      val s2_data = RegEnable(scale_func(s1_e_act, if (has_normalizations) MuxCase(s1_bits.scale, Seq(
        (has_nonlinear_activations.B && has_normalizations.B && s1_bits.act === Activation.LAYERNORM) ->
          s1_bits.inv_stddev,
        (has_nonlinear_activations.B && has_normalizations.B && s1_bits.act === Activation.SOFTMAX) ->
          s1_bits.inv_sum_exp.asTypeOf(scale_t)
      )).asTypeOf(scale_t) else s1_bits.scale.asTypeOf(scale_t)), s1_valid)

      // ------------------------------------------------------------------
      // Stage 3: clip and launch the SiLU address. The synchronous BRAM
      // response is consumed in the following register stage.
      // ------------------------------------------------------------------
      val s3_valid = RegNext(s2_valid, false.B)
      val s3_bits = RegEnable(s2_bits, s2_valid)
      val e_clipped_pre_act = s2_data.clippedToWidthOf(rDataType.head.head)
      val s3_clip = RegEnable(e_clipped_pre_act, s2_valid)

      val silu_addr_hold = if (has_silu_lut) {
        RegNext(e_clipped_pre_act.asUInt, 0.U(8.W))
      } else 0.U(8.W)
      io.silu_addr := silu_addr_hold

      val activation_valid = if (has_silu_lut) {
        require(latency >= 4,
          "SiLU BRAM alignment requires at least four scale-pipeline stages")
        RegNext(s3_valid, false.B)
      } else s3_valid
      val activation_clip = if (has_silu_lut) RegEnable(s3_clip, s3_valid) else s3_clip
      val activation_bits = if (has_silu_lut) RegEnable(s3_bits, s3_valid) else s3_bits

      val e_clipped: T = if (has_nonlinear_activations) {
        val siluCases = if (has_silu_lut) {
          Seq((activation_bits.act === Activation.SILU_LUT) ->
            io.silu_data.asTypeOf(activation_clip))
        } else Seq.empty
        if (silu_only) {
          // Keep NONE/SiLU selection semantics, but do not elaborate the ReLU,
          // leaky-ReLU, IGELU, SoftMax, or LayerNorm activation datapaths.
          MuxCase(activation_clip, siluCases)
        } else {
          val leakyCases = Seq(
            (activation_bits.act === Activation.LEAKY_RELU) -> Activation.leakyRelu(activation_clip)
          )
          MuxCase(activation_clip, leakyCases ++ siluCases)
        }
      } else {
        activation_clip
      }

      val out = Wire(Valid(new AccScaleDataWithIndex(t, u)(ev)))
      out.valid := activation_valid
      out.bits := activation_bits
      out.bits.data := e_clipped

      io.out := Pipe(out, latency - (if (has_silu_lut) 4 else 3))
  }
}


class AccumulatorScale[T <: Data, U <: Data](
  fullDataType: Vec[Vec[T]], rDataType: Vec[Vec[T]],
  scale_t: U,
  read_small_data: Boolean, read_full_data: Boolean,
  scale_func: (T, U) => T,
  num_scale_units: Int,
  latency: Int,
  has_nonlinear_activations: Boolean, has_normalizations: Boolean,
  has_silu_lut: Boolean = false, silu_only: Boolean = false)(implicit ev: Arithmetic[T]) extends Module {

  import ev._

  // The BRAM-backed SiLU table has one read port per shared scale unit; the
  // fully parallel path would need one port per lane, which no longer exists.
  require(!has_silu_lut || num_scale_units > 0,
    "has_silu_lut requires shared accumulator scale units (num_scale_units > 0)")

  val io = IO(new AccumulatorScaleIO[T,U](
    fullDataType, scale_t, rDataType
  )(ev))
  val t = io.in.bits.acc_read_resp.data(0)(0).cloneType
  val acc_read_data = io.in.bits.acc_read_resp.data

  // Synchronous SiLU LUT storage for the shared-unit datapath. The identity
  // initialization and the software write port live inside SiluLutBramMulti;
  // its read latency is part of AccScalePipe's staging.
  val silu_bram = if (has_silu_lut && num_scale_units > 0) {
    val m = Module(new SiluLutBramMulti(num_scale_units))
    m.io.clock := clock
    m.io.reset := reset
    m.io.write_valid := io.silu_lut_write.valid
    m.io.write_base := io.silu_lut_write.bits.base
    m.io.write_data := io.silu_lut_write.bits.data
    Some(m)
  } else None
  io.silu_lut_ready := silu_bram.map(_.io.ready).getOrElse(true.B)

  def apply_output_activation(e: T, act: UInt): T = {
    if (!has_nonlinear_activations) {
      e
    } else {
      val siluCases = if (has_silu_lut && num_scale_units == -1) {
        // Unreachable with the require above; kept so this method compiles
        // without the shared-unit table.
        Seq.empty
      } else Seq.empty
      if (silu_only) {
        MuxCase(e, siluCases)
      } else {
        val leakyCases = Seq(
          (act === Activation.LEAKY_RELU) -> Activation.leakyRelu(e)
        )
        MuxCase(e, leakyCases ++ siluCases)
      }
    }
  }
  val out = Wire(Decoupled(new AccumulatorScaleResp[T](
    fullDataType, rDataType)(ev)))

  if (num_scale_units == -1) {
    val data = io.in.bits.acc_read_resp.data
    val act = io.in.bits.acc_read_resp.act
    val igelu_qb = io.in.bits.acc_read_resp.igelu_qb
    val igelu_qc = io.in.bits.acc_read_resp.igelu_qc
    val iexp_qln2 = io.in.bits.acc_read_resp.iexp_qln2
    val iexp_qln2_inv = io.in.bits.acc_read_resp.iexp_qln2_inv
    val scale = io.in.bits.acc_read_resp.scale

    val activated_data = VecInit(data.map(v => VecInit(v.map { e =>
      val e_act = if (silu_only) e else MuxCase(e, if (has_normalizations) Seq(
        (has_nonlinear_activations.B && act === Activation.RELU) -> e.relu,
        (has_nonlinear_activations.B && has_normalizations.B && act === Activation.LAYERNORM) ->
          (e - io.in.bits.mean),
        (has_nonlinear_activations.B && has_normalizations.B && act === Activation.IGELU) ->
          AccumulatorScale.igelu(e, igelu_qb, igelu_qc),
        (has_nonlinear_activations.B && has_normalizations.B && act === Activation.SOFTMAX) ->
          AccumulatorScale.iexp(e - io.in.bits.max, iexp_qln2, iexp_qln2_inv, igelu_qb, igelu_qc),
      ) else Seq(
        (has_nonlinear_activations.B && act === Activation.RELU) -> e.relu
      ))

      val e_scaled: T = scale_func(e_act, if (has_normalizations) MuxCase(scale, Seq(
        (has_nonlinear_activations.B && has_normalizations.B && act === Activation.LAYERNORM) ->
          io.in.bits.inv_stddev,
        (has_nonlinear_activations.B && has_normalizations.B && act === Activation.SOFTMAX) ->
          io.in.bits.inv_sum_exp.asTypeOf(scale_t)
      )).asTypeOf(scale_t) else scale.asTypeOf(scale_t))

      val e_clipped_pre_act = e_scaled.clippedToWidthOf(rDataType.head.head)
      apply_output_activation(e_clipped_pre_act, act)
    })))

    val in = Wire(Decoupled(new AccumulatorReadRespWithFullData(fullDataType, scale_t)(ev)))
    in.valid := io.in.valid
    io.in.ready := in.ready
    in.bits.resp := io.in.bits.acc_read_resp
    in.bits.full_data := acc_read_data
    in.bits.resp.data := activated_data

    val pipe_out = Pipeline(in, latency)

    out.valid := pipe_out.valid
    pipe_out.ready := out.ready
    out.bits.full_data := pipe_out.bits.full_data
    out.bits.data      := pipe_out.bits.resp.data
    out.bits.fromDMA   := pipe_out.bits.resp.fromDMA
    out.bits.acc_bank_id := pipe_out.bits.resp.acc_bank_id
  } else {
    val width = acc_read_data.size * acc_read_data(0).size
    val nEntries = 3
    val regs = Reg(Vec(nEntries, Valid(new NormalizedOutput[T,U](
      fullDataType, scale_t)(ev))))
    val out_regs = Reg(Vec(nEntries, new AccumulatorScaleResp[T](
      fullDataType, rDataType)(ev)))

    val fired_masks = Reg(Vec(nEntries, Vec(width, Bool())))
    val completed_masks = Reg(Vec(nEntries, Vec(width, Bool())))
    val head_oh = RegInit(1.U(nEntries.W))
    val tail_oh = RegInit(1.U(nEntries.W))
    out.valid := Mux1H(head_oh.asBools, (regs zip completed_masks).map({case (r, c) => r.valid && c.reduce(_&&_)}))
    out.bits  := Mux1H(head_oh.asBools, out_regs)
    when (out.fire) {
      for (i <- 0 until nEntries) {
        when (head_oh(i)) {
          regs(i).valid := false.B
        }
      }
      head_oh := (head_oh << 1).asUInt | head_oh(nEntries-1)
    }

    io.in.ready := !Mux1H(tail_oh.asBools, regs.map(_.valid)) || (tail_oh === head_oh && out.fire)
    when (io.in.fire) {
      for (i <- 0 until nEntries) {
        when (tail_oh(i)) {
          regs(i).valid := true.B
          regs(i).bits  := io.in.bits
          out_regs(i).fromDMA := io.in.bits.acc_read_resp.fromDMA
          out_regs(i).acc_bank_id := io.in.bits.acc_read_resp.acc_bank_id
          fired_masks(i).foreach(_ := false.B)
          completed_masks(i).foreach(_ := false.B)
        }
      }
      tail_oh := (tail_oh << 1).asUInt | tail_oh(nEntries-1)
    }

    // When normalization is disabled there are no norm-dedicated units, so the
    // norm/non-norm split collapses to num_scale_units uniform non-norm units.
    // A non-zero hardcoded value here would leave units 0..3 with an empty
    // arbiter input set (RRArbiter of size 0) and fail elaboration.
    val num_units_with_norm = if (has_normalizations) 4 else 0 // TODO: move to configs

    // One SiLU BRAM read address slot per shared scale unit. The aggregate is
    // a Vec of per-unit wires so each pipe below can drive its own 8-bit slot:
    // a Vec element assignment is writable, whereas a bit-slice of a wide UInt
    // (w(8*i+7, 8*i) := ...) is a read-only OpResult in Chisel and fails
    // elaboration. Vec.asUInt puts element 0 in the least-significant 8 bits,
    // matching SiluLutBramMulti's per-lane read_addr/read_data byte mapping.
    val pipe_silu_addr_cat: Option[Vec[UInt]] =
      if (has_silu_lut) {
        val v = Wire(Vec(num_scale_units, UInt(8.W)))
        v.foreach(_ := 0.U)
        silu_bram.get.io.read_addr := v.asUInt
        Some(v)
      } else {
        None
      }

    val inputs_norm = Seq.fill(width*nEntries) { Wire(Decoupled(new AccScaleDataWithIndex(t, scale_t)(ev))) }
    val inputs_non_norm = Seq.fill(width*nEntries) { Wire(Decoupled(new AccScaleDataWithIndex(t, scale_t)(ev))) }

    val norm_mask = regs.map(r => r.valid && (
      (r.bits.acc_read_resp.act === Activation.SOFTMAX) ||
      (r.bits.acc_read_resp.act === Activation.LAYERNORM) ||
      (r.bits.acc_read_resp.act === Activation.IGELU)
    ))

    // input: norm_mask
    // output: {b2, b1, b0} <-> b_i = whether entry i should use functional units with norm (1 = should)
    val static_assignment_policy = Wire(Vec(1 << nEntries, UInt(nEntries.W)))
    for (i <- 0 until (1 << nEntries)) {
      val binaryString = String.format("%" + nEntries + "s", i.toBinaryString)
        .replace(' ', '0').toCharArray.toList
      val num_norm : Int = binaryString.count(_ == '1')
      val ratio_of_norm_entries = num_norm.toFloat / nEntries.toFloat
      val ratio_of_norm_units = num_units_with_norm.toFloat / num_scale_units.toFloat
      if (ratio_of_norm_entries >= ratio_of_norm_units) {
        // use norm units for all norm entries
        static_assignment_policy(i.U) := i.U
      } else {
        def flip_n_zeros (s: List[Char], n: Int): List[Char] = {
          if (s.nonEmpty) {
            if ((s.head == '0') && (n > 0))
              '1' :: flip_n_zeros(s.tail, n - 1)
            else
              s.head :: flip_n_zeros(s.tail, n)
          } else {
            assert(n == 0, "cannot flip " + n + " zeros in an empty string")
            List.empty
          }
        }
        val flippedString = flip_n_zeros(
          binaryString, Math.round(ratio_of_norm_units * nEntries) - num_norm)
        val flipped = Integer.parseInt(flippedString.mkString(""), 2)
        static_assignment_policy(i.U) := flipped.U
      }
    }

    val current_policy = Wire(UInt(nEntries.W))
    val norm_mask_int = Wire(UInt(nEntries.W))
    norm_mask_int := VecInit(norm_mask).asUInt
    dontTouch(norm_mask_int)
    current_policy := static_assignment_policy(norm_mask_int)

    for (i <- 0 until nEntries) {
      for (w <- 0 until width) {
        val input = inputs_norm(i*width+w)

        val acc_read_resp = regs(i).bits.acc_read_resp

        input.valid       := regs(i).valid && !fired_masks(i)(w) && current_policy(i)
        input.bits.data   := acc_read_resp.data(w / acc_read_data(0).size)(w % acc_read_data(0).size)
        input.bits.full_data := acc_read_resp.data(w / acc_read_data(0).size)(w % acc_read_data(0).size)
        input.bits.scale  := acc_read_resp.scale
        input.bits.act    := acc_read_resp.act
        input.bits.igelu_qb := acc_read_resp.igelu_qb
        input.bits.igelu_qc := acc_read_resp.igelu_qc
        input.bits.iexp_qln2 := acc_read_resp.iexp_qln2
        input.bits.iexp_qln2_inv := acc_read_resp.iexp_qln2_inv
        input.bits.mean := regs(i).bits.mean
        input.bits.max := regs(i).bits.max
        input.bits.inv_stddev := regs(i).bits.inv_stddev
        input.bits.inv_sum_exp := regs(i).bits.inv_sum_exp
        input.bits.id := i.U
        input.bits.index := w.U
        if (num_units_with_norm == 0) {
          input.ready := false.B
        }
        when (input.fire) {
          fired_masks(i)(w) := true.B
        }
      }
    }

    for (i <- 0 until nEntries) {
      for (w <- 0 until width) {
        val input = inputs_non_norm(i*width+w)

        val acc_read_resp = regs(i).bits.acc_read_resp

        input.valid       := regs(i).valid && !fired_masks(i)(w) && (!current_policy(i))
        input.bits.data   := acc_read_resp.data(w / acc_read_data(0).size)(w % acc_read_data(0).size)
        input.bits.full_data := acc_read_resp.data(w / acc_read_data(0).size)(w % acc_read_data(0).size)
        input.bits.scale  := acc_read_resp.scale
        input.bits.act    := acc_read_resp.act
        input.bits.igelu_qb := DontCare
        input.bits.igelu_qc := DontCare
        input.bits.iexp_qln2 := DontCare
        input.bits.iexp_qln2_inv := DontCare
        input.bits.mean := DontCare
        input.bits.max := DontCare
        input.bits.inv_stddev := DontCare
        input.bits.inv_sum_exp := DontCare
        input.bits.id := i.U
        input.bits.index := w.U
        if (num_scale_units == num_units_with_norm) {
          input.ready := false.B
        }
        when (input.fire) {
          fired_masks(i)(w) := true.B
        }
      }
    }

    for (i <- 0 until num_scale_units) {
      val norm_supported = (i < num_units_with_norm) && has_normalizations

      val arbIn =
        if (norm_supported)
          // for norm units, prioritize norm operations
          inputs_norm.zipWithIndex.filter({ case (_, w) => w % num_units_with_norm == i }).map(_._1)
        else
          inputs_non_norm.zipWithIndex.filter({ case (_, w) => w % (num_scale_units - num_units_with_norm) == (i - num_units_with_norm) }).map(_._1)

      val arb = Module(new RRArbiter(new AccScaleDataWithIndex(t, scale_t)(ev), arbIn.length))
      arb.io.in <> arbIn
      arb.io.out.ready := true.B
      val arbOut = Reg(Valid(new AccScaleDataWithIndex(t, scale_t)(ev)))
      arbOut.valid := arb.io.out.valid
      arbOut.bits  := arb.io.out.bits
      when (reset.asBool) {
        arbOut.valid := false.B
      }
      val pipe = Module(new AccScalePipe(t, rDataType, scale_func, scale_t, latency,
            has_nonlinear_activations, norm_supported, has_silu_lut, silu_only))

      pipe.io.in := arbOut
      if (has_silu_lut) {
        pipe_silu_addr_cat.get(i) := pipe.io.silu_addr
        pipe.io.silu_data := silu_bram.get.io.read_data(8 * i + 7, 8 * i)
      } else {
        pipe.io.silu_data := 0.U
      }
      val pipe_out = pipe.io.out

      for (j <- 0 until nEntries) {
        for (w <- 0 until width) {
          val id0 = w % acc_read_data(0).size
          val id1 = w / acc_read_data(0).size
            if (norm_supported && (j*width+w) % num_units_with_norm == i) {
              when (pipe_out.fire && pipe_out.bits.id === j.U && pipe_out.bits.index === w.U) {
                out_regs(j).data     (id1)(id0) := pipe_out.bits.data
                out_regs(j).full_data(id1)(id0) := pipe_out.bits.full_data
                completed_masks(j)(w) := true.B
              }
            }
            if (num_scale_units > num_units_with_norm) {
              if ((j*width+w) % (num_scale_units - num_units_with_norm) == (i - num_units_with_norm)) {
                val id0 = w % acc_read_data(0).size
                val id1 = w / acc_read_data(0).size
                when (pipe_out.fire && pipe_out.bits.id === j.U && pipe_out.bits.index === w.U) {
                  out_regs(j).data     (id1)(id0) := pipe_out.bits.data
                  out_regs(j).full_data(id1)(id0) := pipe_out.bits.full_data
                  completed_masks(j)(w) := true.B
                }
              }
            }
        }
      }
    }

    when (reset.asBool) {
      regs.foreach(_.valid := false.B)
    }
  }

  io.out <> out

  if (read_small_data)
    io.out.bits.data := out.bits.data
  else
    io.out.bits.data := DontCare

  if (read_full_data)
    io.out.bits.full_data := out.bits.full_data
  else
    io.out.bits.full_data := DontCare
}

object AccumulatorScale {
  def igelu[T <: Data](q: T, qb: T, qc: T)(implicit ev: Arithmetic[T]): T = {
    import ev._

    val zero = q.zero
    val one = q.identity
    def neg(x: T) = zero-x

    val q_sign = Mux(q.zero > q, neg(one), one)
    val q_abs = Mux(q.zero > q, neg(q), q)
    val q_clipped = Mux(q_abs > neg(qb), neg(qb), q_abs)
    val q_poly = qc.mac(q_clipped + qb, q_clipped + qb).withWidthOf(q)
    val q_erf = (q_sign * q_poly).withWidthOf(q)
    (q * (q_erf + qc)).withWidthOf(q)
  }

  def iexp[T <: Data](q: T, qln2: T, qln2_inv: T, qb: T, qc: T)(implicit ev: Arithmetic[T]): T = {
    import ev._

    val zero = q.zero
    val one = q.identity
    def neg(x: T) = zero-x

    val q_sign = Mux(q.zero > q, neg(one), one)
    val q_abs = Mux(q.zero > q, neg(q), q)
    val q_clipped = Mux(q_abs > neg(qb), neg(qb), q_abs)
    val q_poly = qc.mac(q_clipped + qb, q_clipped + qb).withWidthOf(q)
    val q_erf = (q_sign * q_poly).withWidthOf(q)
    (q * (q_erf + qc)).withWidthOf(q)
  }}
