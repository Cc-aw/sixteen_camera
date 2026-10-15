package gemmini

import chisel3._

object Activation {
  val NONE = 0.U
  val RELU = 1.U
  val LAYERNORM = 2.U
  val IGELU = 3.U
  val SOFTMAX = 4.U
  val LEAKY_RELU = 5.U
  val SILU_LUT = 6.U

  val bitwidth = 3

  /** Quantized LeakyReLU for the INT8 activation path (alpha ~= 0.1). */
  def leakyRelu[T <: Data](x: T): T = {
    if (x.getWidth == 8) {
      val table = VecInit((0 until 256).map { raw =>
        val signed = if (raw < 128) raw else raw - 256
        val activated = if (signed < 0) (signed - 5) / 10 else signed
        activated.S(8.W).asTypeOf(x)
      })
      table(x.asUInt)
    } else {
      val signed = x.asUInt.asSInt
      val activated = Mux(signed < 0.S, (signed - 5.S) / 10.S, signed)
      activated.asTypeOf(x)
    }
  }
}

/** Eight packed INT8 entries written by one CONFIG_SILU_LUT instruction. */
class SiluLutWrite extends Bundle {
  val base = UInt(8.W)
  val data = UInt(64.W)
}
