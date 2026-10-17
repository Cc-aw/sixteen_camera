// See README.md for license details.
package gemmini

import chisel3._
import chisel3.experimental.IntParam
import chisel3.util._

class SIntDSPMacUnit(inputWidth: Int, weightWidth: Int, cWidth: Int, dWidth: Int)
    extends BlackBox(Map(
      "INPUT_WIDTH" -> IntParam(inputWidth),
      "WEIGHT_WIDTH" -> IntParam(weightWidth),
      "C_WIDTH" -> IntParam(cWidth),
      "D_WIDTH" -> IntParam(dWidth))) with HasBlackBoxInline {
  val io = IO(new Bundle {
    val in_a = Input(SInt(inputWidth.W))
    val in_b = Input(SInt(weightWidth.W))
    val in_c = Input(SInt(cWidth.W))
    val out_d = Output(SInt(dWidth.W))
  })

  override def desiredName: String = "GemminiSIntDSPMac"

  setInline("GemminiSIntDSPMac.sv",
    """(* use_dsp = "yes" *)
      |module GemminiSIntDSPMac #(
      |  parameter integer INPUT_WIDTH = 8,
      |  parameter integer WEIGHT_WIDTH = 8,
      |  parameter integer C_WIDTH = 20,
      |  parameter integer D_WIDTH = 20
      |) (
      |  input signed [INPUT_WIDTH-1:0]  in_a,
      |  input signed [WEIGHT_WIDTH-1:0] in_b,
      |  input signed [C_WIDTH-1:0]      in_c,
      |  output signed [D_WIDTH-1:0]     out_d
      |);
      |  (* use_dsp = "yes" *) wire signed [INPUT_WIDTH+WEIGHT_WIDTH-1:0] product;
      |  (* use_dsp = "yes" *) wire signed [D_WIDTH-1:0] mac_result;
      |  assign product = in_a * in_b;
      |  assign mac_result = in_c + product;
      |  assign out_d = mac_result;
      |endmodule
      |""".stripMargin)
}

class DualSIntDSPMacUnit(inputWidth: Int, weightWidth: Int, cWidth: Int, dWidth: Int)
    extends BlackBox(Map(
      "INPUT_WIDTH" -> IntParam(inputWidth),
      "WEIGHT_WIDTH" -> IntParam(weightWidth),
      "C_WIDTH" -> IntParam(cWidth),
      "D_WIDTH" -> IntParam(dWidth))) with HasBlackBoxInline {
  require(inputWidth == 8 && weightWidth == 8,
    "Dual DSP MAC packing currently requires signed INT8 operands")
  require(cWidth == dWidth && (cWidth == 32 || cWidth == 20 || cWidth == 18),
    "Dual DSP MAC packing currently requires 18-, 20-, or 32-bit partial sums")

  val io = IO(new Bundle {
    val in_a = Input(SInt(inputWidth.W))
    val in_b0 = Input(SInt(weightWidth.W))
    val in_b1 = Input(SInt(weightWidth.W))
    val in_c0 = Input(SInt(cWidth.W))
    val in_c1 = Input(SInt(cWidth.W))
    val out_d0 = Output(SInt(dWidth.W))
    val out_d1 = Output(SInt(dWidth.W))
  })

  override def desiredName: String = "GemminiDualSIntDSPMac"

  setInline("GemminiDualSIntDSPMac.sv",
    """module GemminiDualSIntDSPMac #(
      |  parameter integer INPUT_WIDTH = 8,
      |  parameter integer WEIGHT_WIDTH = 8,
      |  parameter integer C_WIDTH = 20,
      |  parameter integer D_WIDTH = 20
      |) (
      |  input signed [INPUT_WIDTH-1:0]  in_a,
      |  input signed [WEIGHT_WIDTH-1:0] in_b0,
      |  input signed [WEIGHT_WIDTH-1:0] in_b1,
      |  input signed [C_WIDTH-1:0]      in_c0,
      |  input signed [C_WIDTH-1:0]      in_c1,
      |  output signed [D_WIDTH-1:0]     out_d0,
      |  output signed [D_WIDTH-1:0]     out_d1
      |);
      |  wire signed [26:0] b0_extended = {{19{in_b0[7]}}, in_b0};
      |  wire signed [26:0] b1_extended = {{19{in_b1[7]}}, in_b1};
      |  wire signed [26:0] packed_weights =
      |    b0_extended + (b1_extended <<< 18);
      |
      |  (* use_dsp = "yes" *) wire signed [34:0] packed_product =
      |    packed_weights * in_a;
      |  wire signed [15:0] product0 = packed_product[15:0];
      |  wire signed [16:0] product1_uncorrected = packed_product >>> 18;
      |  wire signed [15:0] product1 =
      |    product1_uncorrected[15:0] + product0[15];
      |
      |  (* use_dsp = "no" *) wire signed [D_WIDTH-1:0] sum0 = in_c0 + product0;
      |  (* use_dsp = "no" *) wire signed [D_WIDTH-1:0] sum1 = in_c1 + product1;
      |  assign out_d0 = sum0;
      |  assign out_d1 = sum1;
      |endmodule
      |""".stripMargin)
}

/** Two independent DSP MACs behind the same dual-lane interface as the packed
  * implementation. Keeping them in one BlackBox avoids thousands of generic
  * PE/MacUnit elaboration wrappers in a large hybrid mesh. */
class DualSIntDSPMacUnpackedUnit(inputWidth: Int, weightWidth: Int,
                                cWidth: Int, dWidth: Int)
    extends BlackBox(Map(
      "INPUT_WIDTH" -> IntParam(inputWidth),
      "WEIGHT_WIDTH" -> IntParam(weightWidth),
      "C_WIDTH" -> IntParam(cWidth),
      "D_WIDTH" -> IntParam(dWidth))) with HasBlackBoxInline {
  val io = IO(new Bundle {
    val in_a = Input(SInt(inputWidth.W))
    val in_b0 = Input(SInt(weightWidth.W))
    val in_b1 = Input(SInt(weightWidth.W))
    val in_c0 = Input(SInt(cWidth.W))
    val in_c1 = Input(SInt(cWidth.W))
    val out_d0 = Output(SInt(dWidth.W))
    val out_d1 = Output(SInt(dWidth.W))
  })

  override def desiredName: String = "GemminiDualSIntDSPMacUnpacked"

  setInline("GemminiDualSIntDSPMacUnpacked.sv",
    """module GemminiDualSIntDSPMacUnpacked #(
      |  parameter integer INPUT_WIDTH = 8,
      |  parameter integer WEIGHT_WIDTH = 8,
      |  parameter integer C_WIDTH = 20,
      |  parameter integer D_WIDTH = 20
      |) (
      |  input signed [INPUT_WIDTH-1:0]  in_a,
      |  input signed [WEIGHT_WIDTH-1:0] in_b0,
      |  input signed [WEIGHT_WIDTH-1:0] in_b1,
      |  input signed [C_WIDTH-1:0]      in_c0,
      |  input signed [C_WIDTH-1:0]      in_c1,
      |  output signed [D_WIDTH-1:0]     out_d0,
      |  output signed [D_WIDTH-1:0]     out_d1
      |);
      |  (* use_dsp = "yes" *) wire signed [INPUT_WIDTH+WEIGHT_WIDTH-1:0] product0;
      |  (* use_dsp = "yes" *) wire signed [INPUT_WIDTH+WEIGHT_WIDTH-1:0] product1;
      |  (* use_dsp = "yes" *) wire signed [D_WIDTH-1:0] mac_result0;
      |  (* use_dsp = "yes" *) wire signed [D_WIDTH-1:0] mac_result1;
      |  assign product0 = in_a * in_b0;
      |  assign product1 = in_a * in_b1;
      |  assign mac_result0 = in_c0 + product0;
      |  assign mac_result1 = in_c1 + product1;
      |  assign out_d0 = mac_result0;
      |  assign out_d1 = mac_result1;
      |endmodule
      |""".stripMargin)
}

class PEControl[T <: Data : Arithmetic](accType: T) extends Bundle {
  val dataflow = UInt(1.W) // TODO make this an Enum
  val propagate = UInt(1.W) // Which register should be propagated (and which should be accumulated)?
  val shift = UInt(log2Up(accType.getWidth).W) // TODO this isn't correct for Floats

}

class MacUnit[T <: Data](inputType: T, weightType: T, cType: T, dType: T,
                         useDspMacBlackBox: Boolean = false)
                        (implicit ev: Arithmetic[T]) extends Module {
  import ev._
  val io = IO(new Bundle {
    val in_a  = Input(inputType)
    val in_b  = Input(weightType)
    val in_c  = Input(cType)
    val out_d = Output(dType)
  })

  if (useDspMacBlackBox && inputType.isInstanceOf[SInt] &&
      weightType.isInstanceOf[SInt] && cType.isInstanceOf[SInt] &&
      dType.isInstanceOf[SInt]) {
    val dspMac = Module(new SIntDSPMacUnit(
      inputType.getWidth, weightType.getWidth, cType.getWidth, dType.getWidth))
    dspMac.io.in_a := io.in_a.asTypeOf(SInt(inputType.getWidth.W))
    dspMac.io.in_b := io.in_b.asTypeOf(SInt(weightType.getWidth.W))
    dspMac.io.in_c := io.in_c.asTypeOf(SInt(cType.getWidth.W))
    io.out_d := dspMac.io.out_d.asTypeOf(dType)
  } else {
    io.out_d := io.in_c.mac(io.in_a, io.in_b)
  }
}

/**
  * Implements a signed rounding right shift with a power-of-two multiplier.
  * The multiplier result encodes both the arithmetic quotient and discarded
  * bits, allowing the original round-to-nearest-even behavior to be retained.
  */
class DspRoundingShift(width: Int) extends Module {
  require(width > 1 && (width & (width - 1)) == 0,
    "DspRoundingShift requires a power-of-two width")

  val io = IO(new Bundle {
    val in = Input(SInt(width.W))
    val shamt = Input(UInt(log2Ceil(width).W))
    val out = Output(SInt(width.W))
  })

  val factors = VecInit((0 until width).map { amount =>
    val factor = if (amount == 0) BigInt(0) else BigInt(1) << (width - amount)
    factor.S((width + 1).W)
  })
  val product = io.in * factors(io.shamt)
  val quotient = product(2 * width - 1, width).asSInt

  val half = product(width - 1)
  val belowHalf = product(width - 2, 0).orR
  val roundUp = io.shamt.orR && half && (belowHalf || quotient(0))
  val rounded = quotient + Mux(roundUp, 1.S(width.W), 0.S(width.W))

  io.out := Mux(io.shamt === 0.U, io.in, rounded)
}

// TODO update documentation
/**
  * A PE implementing a MAC operation. Configured as fully combinational when integrated into a Mesh.
  * @param width Data width of operands
  */
class PE[T <: Data](inputType: T, weightType: T, outputType: T, accType: T,
                   df: Dataflow.Value, max_simultaneous_matmuls: Int,
                   useDspOutputShift: Boolean = false,
                   useDspMacBlackBox: Boolean = false)
                   (implicit ev: Arithmetic[T]) extends Module { // Debugging variables
  import ev._

  val io = IO(new Bundle {
    val in_a = Input(inputType)
    val in_b = Input(outputType)
    val in_d = Input(outputType)
    val out_a = Output(inputType)
    val out_b = Output(outputType)
    val out_c = Output(outputType)

    val in_control = Input(new PEControl(accType))
    val out_control = Output(new PEControl(accType))

    val in_id = Input(UInt(log2Up(max_simultaneous_matmuls).W))
    val out_id = Output(UInt(log2Up(max_simultaneous_matmuls).W))

    val in_last = Input(Bool())
    val out_last = Output(Bool())

    val in_valid = Input(Bool())
    val out_valid = Output(Bool())

    val bad_dataflow = Output(Bool())
  })

  val cType = if (df == Dataflow.WS) inputType else accType

  // When creating PEs that support multiple dataflows, the
  // elaboration/synthesis tools often fail to consolidate and de-duplicate
  // MAC units. To force mac circuitry to be re-used, we create a "mac_unit"
  // module here which just performs a single MAC operation
  val mac_unit = Module(new MacUnit(inputType, weightType,
    if (df == Dataflow.WS) outputType else accType, outputType,
    useDspMacBlackBox))

  val a  = io.in_a
  val b  = io.in_b
  val d  = io.in_d
  val c1 = Reg(cType)
  val c2 = Reg(cType)
  val dataflow = io.in_control.dataflow
  val prop  = io.in_control.propagate
  val shift = io.in_control.shift
  val id = io.in_id
  val last = io.in_last
  val valid = io.in_valid

  io.out_a := a
  io.out_control.dataflow := dataflow
  io.out_control.propagate := prop
  io.out_control.shift := shift
  io.out_id := id
  io.out_last := last
  io.out_valid := valid

  mac_unit.io.in_a := a

  val last_s = RegEnable(prop, valid)
  val flip = last_s =/= prop
  val shift_offset = Mux(flip, shift, 0.U)

  // Which dataflow are we using?
  val OUTPUT_STATIONARY = Dataflow.OS.id.U(1.W)
  val WEIGHT_STATIONARY = Dataflow.WS.id.U(1.W)

  // Is c1 being computed on, or propagated forward (in the output-stationary dataflow)?
  val COMPUTE = 0.U(1.W)
  val PROPAGATE = 1.U(1.W)

  val dspOsShifted = if (useDspOutputShift) {
    require(cType.isInstanceOf[SInt],
      "DSP output shifting currently supports signed integer Gemmini arrays")
    val osShiftInput = Mux(prop === PROPAGATE, c1, c2)
    val dspShift = Module(new DspRoundingShift(cType.getWidth))
    dspShift.io.in := osShiftInput.asUInt.asSInt
    dspShift.io.shamt := shift_offset
    Some(dspShift.io.out.asTypeOf(cType))
  } else {
    None
  }

  io.bad_dataflow := false.B
  when ((df == Dataflow.OS).B || ((df == Dataflow.BOTH).B && dataflow === OUTPUT_STATIONARY)) {
    when(prop === PROPAGATE) {
      io.out_c := dspOsShifted.getOrElse(c1 >> shift_offset).clippedToWidthOf(outputType)
      io.out_b := b
      mac_unit.io.in_b := b.asTypeOf(weightType)
      mac_unit.io.in_c := c2
      c2 := mac_unit.io.out_d
      c1 := d.withWidthOf(cType)
    }.otherwise {
      io.out_c := dspOsShifted.getOrElse(c2 >> shift_offset).clippedToWidthOf(outputType)
      io.out_b := b
      mac_unit.io.in_b := b.asTypeOf(weightType)
      mac_unit.io.in_c := c1
      c1 := mac_unit.io.out_d
      c2 := d.withWidthOf(cType)
    }
  }.elsewhen ((df == Dataflow.WS).B || ((df == Dataflow.BOTH).B && dataflow === WEIGHT_STATIONARY)) {
    when(prop === PROPAGATE) {
      io.out_c := c1
      mac_unit.io.in_b := c2.asTypeOf(weightType)
      mac_unit.io.in_c := b
      io.out_b := mac_unit.io.out_d
      c1 := d
    }.otherwise {
      io.out_c := c2
      mac_unit.io.in_b := c1.asTypeOf(weightType)
      mac_unit.io.in_c := b
      io.out_b := mac_unit.io.out_d
      c2 := d
    }
  }.otherwise {
    io.bad_dataflow := true.B
    //assert(false.B, "unknown dataflow")
    io.out_c := DontCare
    io.out_b := DontCare
    mac_unit.io.in_b := b.asTypeOf(weightType)
    mac_unit.io.in_c := c2
  }

  when (!valid) {
    c1 := c1
    c2 := c2
    mac_unit.io.in_b := DontCare
    mac_unit.io.in_c := DontCare
  }
}

class WSDualPackedPE[T <: Data](inputType: T, weightType: T, outputType: T,
                                accType: T, max_simultaneous_matmuls: Int,
                                packMultipliers: Boolean = true,
                                pipelineCycles: Int = 0)
                               (implicit ev: Arithmetic[T]) extends Module {
  val io = IO(new Bundle {
    val in_a = Input(inputType)
    val in_b = Input(Vec(2, outputType))
    val in_d = Input(Vec(2, outputType))
    val out_a = Output(inputType)
    val out_b = Output(Vec(2, outputType))
    val out_c = Output(Vec(2, outputType))

    val in_control = Input(Vec(2, new PEControl(accType)))
    val out_control = Output(Vec(2, new PEControl(accType)))
    val in_id = Input(Vec(2, UInt(log2Up(max_simultaneous_matmuls).W)))
    val out_id = Output(Vec(2, UInt(log2Up(max_simultaneous_matmuls).W)))
    val in_last = Input(Vec(2, Bool()))
    val out_last = Output(Vec(2, Bool()))
    val in_valid = Input(Vec(2, Bool()))
    val out_valid = Output(Vec(2, Bool()))
    val bad_dataflow = Output(Bool())
  })

  require(inputType.isInstanceOf[SInt] && weightType.isInstanceOf[SInt] &&
    outputType.isInstanceOf[SInt],
    "WS dual DSP packing requires signed integer Gemmini types")

  val c1 = Seq.fill(2)(Reg(inputType))
  val c2 = Seq.fill(2)(Reg(inputType))
  val selectedWeight = Wire(Vec(2, weightType))
  val partialSum = Wire(Vec(2, outputType))

  require(pipelineCycles == 0 || pipelineCycles == 2)
  if (pipelineCycles == 2) {
    require(inputType.getWidth == 8 && weightType.getWidth == 8 &&
      outputType.getWidth >= 20 && outputType.getWidth <= 48)
    val mac = Module(new TimingDualMac(packMultipliers, outputType.getWidth))
    mac.io.clock := clock
    mac.io.a := io.in_a.asUInt.asSInt
    mac.io.b0 := selectedWeight(0).asUInt.asSInt
    mac.io.b1 := selectedWeight(1).asUInt.asSInt
    mac.io.c0 := partialSum(0).asUInt.asSInt
    mac.io.c1 := partialSum(1).asUInt.asSInt
    io.out_b(0) := mac.io.d0.asTypeOf(outputType)
    io.out_b(1) := mac.io.d1.asTypeOf(outputType)
  } else if (packMultipliers) {
    val packedMac = Module(new DualSIntDSPMacUnit(
      inputType.getWidth, weightType.getWidth, outputType.getWidth,
      outputType.getWidth))
    packedMac.io.in_a := io.in_a.asTypeOf(SInt(inputType.getWidth.W))
    packedMac.io.in_b0 := selectedWeight(0).asTypeOf(SInt(weightType.getWidth.W))
    packedMac.io.in_b1 := selectedWeight(1).asTypeOf(SInt(weightType.getWidth.W))
    packedMac.io.in_c0 := partialSum(0).asTypeOf(SInt(outputType.getWidth.W))
    packedMac.io.in_c1 := partialSum(1).asTypeOf(SInt(outputType.getWidth.W))
    io.out_b(0) := packedMac.io.out_d0.asTypeOf(outputType)
    io.out_b(1) := packedMac.io.out_d1.asTypeOf(outputType)
  } else {
    // Keep the same dual-lane state/control shell, but map each exact MAC to
    // its own DSP48E2. A single dual-output BlackBox keeps Chisel elaboration
    // and netlist hierarchy small in large hybrid meshes.
    val unpackedMacs = Module(new DualSIntDSPMacUnpackedUnit(
      inputType.getWidth, weightType.getWidth, outputType.getWidth,
      outputType.getWidth))
    unpackedMacs.io.in_a := io.in_a.asTypeOf(SInt(inputType.getWidth.W))
    unpackedMacs.io.in_b0 := selectedWeight(0).asTypeOf(SInt(weightType.getWidth.W))
    unpackedMacs.io.in_b1 := selectedWeight(1).asTypeOf(SInt(weightType.getWidth.W))
    unpackedMacs.io.in_c0 := partialSum(0).asTypeOf(SInt(outputType.getWidth.W))
    unpackedMacs.io.in_c1 := partialSum(1).asTypeOf(SInt(outputType.getWidth.W))
    io.out_b(0) := unpackedMacs.io.out_d0.asTypeOf(outputType)
    io.out_b(1) := unpackedMacs.io.out_d1.asTypeOf(outputType)
  }

  io.out_a := ShiftRegister(io.in_a, pipelineCycles)
  io.bad_dataflow := false.B

  for (lane <- 0 until 2) {
    val prop = io.in_control(lane).propagate
    val valid = io.in_valid(lane)
    val PROPAGATE = 1.U(1.W)

    io.out_control(lane) := ShiftRegister(io.in_control(lane), pipelineCycles)
    io.out_id(lane) := ShiftRegister(io.in_id(lane), pipelineCycles)
    io.out_last(lane) := ShiftRegister(io.in_last(lane), pipelineCycles)
    io.out_valid(lane) := ShiftRegister(valid, pipelineCycles, false.B, true.B)
    partialSum(lane) := io.in_b(lane)

    val forwardedWeight = Wire(inputType.cloneType)
    io.out_c(lane) := ShiftRegister(forwardedWeight, pipelineCycles)

    when (prop === PROPAGATE) {
      forwardedWeight := c1(lane)
      selectedWeight(lane) := c2(lane).asTypeOf(weightType)
      c1(lane) := io.in_d(lane)
    }.otherwise {
      forwardedWeight := c2(lane)
      selectedWeight(lane) := c1(lane).asTypeOf(weightType)
      c2(lane) := io.in_d(lane)
    }

    when (!valid) {
      c1(lane) := c1(lane)
      c2(lane) := c2(lane)
      // A packed multiplier is shared by both lanes. Zero an inactive lane so
      // its don't-care values cannot contaminate the active lane's product.
      selectedWeight(lane) := 0.U.asTypeOf(weightType)
      partialSum(lane) := 0.U.asTypeOf(outputType)
    }
  }
}
