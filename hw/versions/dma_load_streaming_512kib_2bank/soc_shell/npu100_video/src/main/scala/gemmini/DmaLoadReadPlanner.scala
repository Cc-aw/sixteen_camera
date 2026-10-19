package gemmini

import chisel3._
import chisel3.util._

/** One physical fragment, never a synthetic multi-row SPAD request. The
  * caller maintains logical offsets independently of physical overfetch. */
class DmaLoadReadPlanner(addressBits: Int, maxBytes: Int = 64, beatBytes: Int = 32) extends Module {
  require(maxBytes == 64 && beatBytes == 32)
  val io = IO(new Bundle {
    val address = Input(UInt(addressBits.W))
    val remaining = Input(UInt(11.W))
    val bytes = Output(UInt(7.W))
    val size = Output(UInt(3.W))
    val legal = Output(Bool())
  })
  val in32 = 32.U(7.W) - io.address(4, 0)
  val in64 = 64.U(7.W) - io.address(5, 0)
  val take32 = Mux(io.remaining < in32, io.remaining, in32)
  val take64 = Mux(io.remaining < in64, io.remaining, in64)
  io.bytes := Mux(take64 > take32, take64, take32)
  io.size := Mux(take64 > take32, 6.U, 5.U)
  // This target's ordinary physical DDR aperture. An aligned 32/64B Get
  // cannot cross a page or aperture edge. Translation/MMIO use legacy.
  val end = io.address +& io.bytes
  io.legal := io.remaining =/= 0.U && io.address >= "h80000000".U &&
    end <= "h100000000".U
}
