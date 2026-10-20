// Generated from the same ASRAM manifest as the TL managers.
package gemmini
import chisel3._
object ActivationSramDmaAddress {
  def localRange(start: UInt, endExclusive: UInt): Bool =
    freechips.rocketchip.tile.commandfrontend.ActivationSramMap.containsRange(start, endExclusive)
}
