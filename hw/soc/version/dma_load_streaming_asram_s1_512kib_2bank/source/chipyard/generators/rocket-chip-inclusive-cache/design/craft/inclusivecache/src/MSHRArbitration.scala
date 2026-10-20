package sifive.blocks.inclusivecache

import chisel3._
import freechips.rocketchip.util._

object MSHRArbitration {
  // The low half of Cat(request, request & filter) wins if nonempty.
  // Compute both 34-bit priorities in parallel instead of one 68-bit scan.
  def select(request: UInt, filter: UInt): UInt = {
    val width = request.getWidth
    def first(x: UInt): UInt = (~(leftOR(x) << 1) & x)(width-1, 0)
    val masked = request & filter
    Mux(masked.orR, first(masked), first(request))
  }
}
