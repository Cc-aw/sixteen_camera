package saturn.exu

import chisel3._
import chisel3.util._
import org.chipsalliance.cde.config._
import freechips.rocketchip.rocket._
import freechips.rocketchip.rocket.ALU._
import freechips.rocketchip.util._
import freechips.rocketchip.tile._
import saturn.common._
import saturn.insns._

case class IntegerDivideFactory(supportsMul: Boolean) extends FunctionalUnitFactory {
  def wideningMulInsns = Seq(
    WMUL.VV, WMUL.VX, WMULU.VV, WMULU.VX,
    WMULSU.VV, WMULSU.VX,
    WMACC.VV, WMACC.VX, WMACCU.VV, WMACCU.VX,
    WMACCSU.VV , WMACCSU.VX, WMACCUS.VV, WMACCUS.VX
  ).map(_.restrictSEW(0, 1, 2)).flatten

  def mulInsns = (wideningMulInsns ++ Seq(
    MUL.VV, MUL.VX, MULH.VV, MULH.VX,
    MULHU.VV, MULHU.VX, MULHSU.VV, MULHSU.VX,
    MACC.VV, MACC.VX, NMSAC.VV, NMSAC.VX,
    MADD.VV, MADD.VX, NMSUB.VV, NMSUB.VX,
    SMUL.VV, SMUL.VX
  )).map(_.elementWise)

  def divInsns = Seq(
    DIVU.VV, DIVU.VX,
    DIV.VV, DIV.VX,
    REMU.VV, REMU.VX,
    REM.VV, REM.VX
  ).map(_.elementWise)

  def insns = (divInsns ++ (if (supportsMul) mulInsns else Nil)).map(_.iterative)

  def generate(implicit p: Parameters) = new IterativeIntegerDivider(supportsMul)(p)
}

class IterativeIntegerDivider(supportsMul: Boolean)(implicit p: Parameters) extends IterativeFunctionalUnit()(p) {
  val div_insns = IntegerDivideFactory(supportsMul).divInsns
  val mul_insns = IntegerDivideFactory(supportsMul).mulInsns

  val div = Module(new MulDiv(MulDivParams(mulUnroll = if (supportsMul) 8 else 0), 64, 1))

  // Isolate MulDiv from the long sequencer/VRF operand path. The surrounding
  // iterative-unit handshake already tolerates variable latency. Capture the
  // decoded request in a separate cycle: requestPending alone delayed valid,
  // but left the sign-extension/decode cone directly on MulDiv's input path.
  val requestCapturePending = RegInit(false.B)
  val requestPending = RegInit(false.B)
  when (io.iss.valid) {
    requestCapturePending := true.B
  } .elsewhen (requestCapturePending) {
    requestCapturePending := false.B
  }
  when (requestCapturePending) {
    requestPending := true.B
  } .elsewhen (div.io.req.fire) {
    requestPending := false.B
  }
  div.io.req.valid := requestPending
  io.stall := requestCapturePending || requestPending || !div.io.req.ready || (valid && !last)

  io.set_vxsat := false.B
  io.set_fflags.valid := false.B
  io.set_fflags.bits := DontCare

  val ctrl_fn = WireInit(VecInit(Seq(FN_DIVU, FN_DIV, FN_REMU, FN_REM))(op.funct6(1,0)))
  val ctrl_sign1 = WireInit(op.funct6(0))
  val ctrl_sign2 = WireInit(op.funct6(0))
  val ctrl_swapvdv2 = WireInit(false.B)

  if (supportsMul) {
    val mul_ctrl = new VectorDecoder(op, mul_insns, Seq(
      MULHi, MULSign1, MULSign2, MULSwapVdV2))
    when (mul_ctrl.matched) {
      ctrl_fn       := Mux(mul_ctrl.bool(MULHi),
        Mux(mul_ctrl.bool(MULSign2) && mul_ctrl.bool(MULSign1), FN_MULH,
          Mux(mul_ctrl.bool(MULSign2), FN_MULHSU, FN_MULHU)),
        FN_MUL)
      when (op.isOpi) { ctrl_fn := FN_MULH }
      ctrl_sign1    := mul_ctrl.bool(MULSign1)
      ctrl_sign2    := mul_ctrl.bool(MULSign2)
      ctrl_swapvdv2 := mul_ctrl.bool(MULSwapVdV2)
    }
  }

  val requestFn = Reg(chiselTypeOf(div.io.req.bits.fn))
  val requestIn1 = Reg(chiselTypeOf(div.io.req.bits.in1))
  val requestIn2 = Reg(chiselTypeOf(div.io.req.bits.in2))
  when (requestCapturePending) {
    requestFn := ctrl_fn
    requestIn1 := Mux(ctrl_swapvdv2, op.rvd_elem, Mux(ctrl_sign2,
      sextElem(op.rvs2_elem, op.rvs2_eew),
      op.rvs2_elem))
    requestIn2 := Mux(ctrl_sign1,
      sextElem(op.rvs1_elem, op.rvs1_eew),
      op.rvs1_elem)
  }

  div.io.req.bits.fn := requestFn
  div.io.req.bits.in1 := requestIn1
  div.io.req.bits.in2 := requestIn2
  div.io.req.bits.dw  := DW_64
  div.io.req.bits.tag := DontCare

  div.io.kill := false.B

  io.hazard.valid   := valid
  io.hazard.bits.eg := op.wvd_eg
  io.hazard.bits.vat := op.vat

  val write_elem = WireInit(div.io.resp.bits.data)
  val wdata = VecInit.tabulate(4)({ eew => Fill(dLenB >> eew, write_elem((8<<eew)-1,0)) })(op.rvd_eew)

  if (supportsMul) {
    val mul_ctrl = new VectorDecoder(op, mul_insns, Seq(
      MULHi, MULSign1, MULSign2, MULSwapVdV2, MULAccumulate, MULSub))
    val is_smul = op.isOpi
    val prod = div.io.resp.bits.full_data.asSInt
    val hi = VecInit.tabulate(4)({ eew => prod >> (8 << eew) })(op.vd_eew)(63,0)
    val lo = VecInit.tabulate(4)({ eew => prod((8 << eew)-1,0)})(op.vd_eew)(63,0)
    val madd = Mux(mul_ctrl.bool(MULSub), ~lo, lo) + mul_ctrl.bool(MULSub) + Mux(mul_ctrl.bool(MULSwapVdV2),
      op.rvs2_elem, op.rvd_elem)
    val rounding_incr = VecInit.tabulate(4)({ eew => RoundingIncrement(op.vxrm, prod((8 << eew)-1,0)) })(op.vd_eew)
    val smul = VecInit.tabulate(4)({ eew => prod >> ((8 << eew) - 1) })(op.vd_eew) + Cat(0.U(1.W), rounding_incr).asSInt
    val smul_clip_neg = VecInit.tabulate(4)({ eew => (-1 << ((8 << eew)-1)).S })(op.vd_eew)
    val smul_clip_pos = VecInit.tabulate(4)({ eew => ((1 << ((8 << eew)-1)) - 1).S })(op.vd_eew)
    val smul_clip_hi = smul > smul_clip_pos
    val smul_clip_lo = smul < smul_clip_neg
    val smul_clipped = Mux(smul_clip_hi, smul_clip_pos, 0.S) | Mux(smul_clip_lo, smul_clip_neg, 0.S) | Mux(!smul_clip_hi && !smul_clip_lo, smul, 0.S)
    val smul_sat = smul_clip_hi || smul_clip_lo
    val mul_wdata = WireInit(Mux(mul_ctrl.bool(MULHi), hi, lo))
    when (mul_ctrl.bool(MULAccumulate) || is_smul) {
      mul_wdata := Mux(mul_ctrl.bool(MULAccumulate), madd, 0.U) | Mux(is_smul, smul_clipped.asUInt, 0.U)
    }
    when (mul_ctrl.matched) {
      write_elem := mul_wdata
      io.set_vxsat := is_smul && smul_sat && io.write.fire && op.wmask =/= 0.U
    }
  }

  div.io.resp.ready  := io.write.ready
  io.write.valid     := div.io.resp.valid
  io.write.bits.eg   := op.wvd_eg
  io.write.bits.mask := FillInterleaved(8, op.wmask)
  io.write.bits.data := wdata

  io.scalar_write.valid := false.B
  io.scalar_write.bits := DontCare

  last := io.write.fire

  io.acc := false.B
  io.tail := op.tail
}
