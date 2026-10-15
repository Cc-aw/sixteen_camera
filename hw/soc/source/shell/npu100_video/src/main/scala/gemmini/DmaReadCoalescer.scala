package gemmini

import chisel3._
import chisel3.util._
import org.chipsalliance.cde.config.Parameters

/** Look ahead in accepted row descriptors, never speculative memory reads.
  * The output descriptor is registered, and input ready only depends on FIFO
  * occupancy. An unmatched tail drains without waiting for another command.
  * Only complete adjacent scratchpad rows with identical command attributes
  * can share a cache-line transaction. Completion accounts for both rows.
  */
class DmaReadCoalescer(spadRows: Int, accRows: Int, scaleBits: Int,
                       rowElements: Int, rowBytes: Int, lineBytes: Int)
                      (implicit p: Parameters) extends Module {
  require(lineBytes == 2 * rowBytes && isPow2(lineBytes))
  val io = IO(new Bundle {
    val in = Flipped(Decoupled(new StreamReadRequest(spadRows, accRows, scaleBits)))
    val out = Decoupled(new StreamReadRequest(spadRows, accRows, scaleBits))
    val busy = Output(Bool())
  })
  val slots = Reg(Vec(4, chiselTypeOf(io.in.bits)))
  val head = RegInit(0.U(2.W))
  val tail = RegInit(0.U(2.W))
  val count = RegInit(0.U(3.W))
  val headWaited = RegInit(false.B)
  val output = Reg(chiselTypeOf(io.out.bits))
  val outputValid = RegInit(false.B)
  val first = slots(head)
  val second = slots((head + 1.U)(1, 0))
  val merge = count >= 2.U &&
    first.vaddr(log2Ceil(lineBytes)-1, 0) === 0.U &&
    second.vaddr === first.vaddr + rowBytes.U &&
    second.spaddr === first.spaddr +& 1.U &&
    first.len === rowElements.U && second.len === rowElements.U &&
    !first.is_acc && !second.is_acc &&
    !first.has_acc_bitwidth && !second.has_acc_bitwidth &&
    !first.accumulate && !second.accumulate &&
    first.repeats === 0.U && second.repeats === 0.U &&
    first.pixel_repeats === 1.U && second.pixel_repeats === 1.U &&
    first.cmd_id === second.cmd_id && first.scale === second.scale &&
    first.block_stride === second.block_stride &&
    first.status.asUInt === second.status.asUInt
  val prepare = (!outputValid || io.out.ready) &&
    (count >= 2.U || (count =/= 0.U && headWaited))
  io.in.ready := count < 4.U
  io.out.valid := outputValid
  io.out.bits := output
  io.busy := count =/= 0.U || outputValid
  when(io.in.fire) {
    slots(tail) := io.in.bits
    tail := tail + 1.U
  }
  when(io.out.fire) { outputValid := false.B }
  when(prepare) {
    output := first
    when(merge) {
      output.len := (2 * rowElements).U
      output.block_stride := 1.U
    }
    outputValid := true.B
    head := head + Mux(merge, 2.U, 1.U)
  }
  count := count + io.in.fire.asUInt - Mux(prepare, Mux(merge, 2.U, 1.U), 0.U)
  headWaited := !prepare && count =/= 0.U
  assert(count <= 4.U)
}

/** EX retains priority for a bounded burst of contested, successful accesses.
  * The selector depends on registered history, and stalls do not advance it.
  */
class BoundedExPriority(maxBurst: Int) extends Module {
  require(maxBurst > 0)
  val io = IO(new Bundle {
    val exValid = Input(Bool())
    val dmaValid = Input(Bool())
    val fire = Input(Bool())
    val chooseEx = Output(Bool())
  })
  val burst = RegInit(0.U(log2Ceil(maxBurst + 1).W))
  io.chooseEx := io.exValid && (!io.dmaValid || burst < maxBurst.U)
  when(!io.dmaValid) { burst := 0.U }
  when(io.fire) {
    when(io.exValid && io.dmaValid && io.chooseEx) {
      burst := burst + 1.U
    }.otherwise { burst := 0.U }
  }
}
