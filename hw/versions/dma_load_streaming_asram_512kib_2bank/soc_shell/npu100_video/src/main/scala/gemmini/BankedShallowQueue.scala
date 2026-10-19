package gemmini

import chisel3._
import chisel3.util._

/** A small FIFO with a fixed output register and local control for each word.
  *
  * Chisel Queue uses an asynchronously read Mem even for two entries. On this
  * FPGA that produces thousands of LUTRAM read/write address loads on one
  * pointer for an accumulator row. Here dequeue shifts the remaining entries
  * toward the head, so the output never passes through a pointer-driven mux.
  * Payload registers have no reset. Only the occupancy state is reset.
  */
class ShallowQueueSlice(width: Int, entries: Int, pipe: Boolean, flow: Boolean)
    extends Module {
  require(width > 0 && entries > 0 && entries <= 8)
  val io = IO(new QueueIO(UInt(width.W), entries))

  // Identical slices must retain separate occupancy flops and local decode.
  // Preserving only their tiny controller lets unused payload bits disappear.
  VivadoAttributes(this.toTarget, "keep_hierarchy = \"yes\"")
  val occupancy = RegInit(0.U(log2Ceil(entries + 1).W))
  VivadoAttributes(occupancy.toTarget, "dont_touch = \"yes\"")
  val data = Reg(Vec(entries, UInt(width.W)))
  val empty = occupancy === 0.U
  val full = occupancy === entries.U

  io.count := occupancy
  io.enq.ready := !full || (pipe.B && io.deq.ready)
  io.deq.valid := !empty || (flow.B && io.enq.valid)
  io.deq.bits := (if (flow) Mux(empty, io.enq.bits, data.head) else data.head)

  // An empty flowing queue can transfer a token without storing it.
  val bypass = flow.B && empty && io.deq.ready
  val push = io.enq.fire && !bypass
  val pop = !empty && io.deq.ready
  when (push =/= pop) {
    occupancy := Mux(push, occupancy + 1.U, occupancy - 1.U)
  }

  for (i <- 0 until entries) {
    val insert = push && Mux(pop, occupancy === (i + 1).U, occupancy === i.U)
    if (i + 1 < entries) {
      val shift = pop && occupancy > (i + 1).U
      val writeEnable = insert || shift
      when (writeEnable) {
        data(i) := Mux(insert, io.enq.bits, data(i + 1))
      }
    } else {
      when (insert) { data(i) := io.enq.bits }
    }
  }
  assert(occupancy <= entries.U)
}

/** Distributed storage with independent, bounded-fanout address registers.
  * This variant keeps the area advantage of LUTRAM for wide data, while the
  * register variant is useful for metadata that feeds another ready chain.
  */
class ShallowQueueRamSlice(width: Int, depth: Int, pipelined: Boolean, flowing: Boolean)
    extends Queue(UInt(width.W), depth, pipe = pipelined, flow = flowing) {
  require(width > 0 && depth > 1 && depth <= 8)
  override def desiredName: String = s"ShallowQueueRamSlice_${width}_${depth}"
  VivadoAttributes(this.toTarget, "keep_hierarchy = \"yes\"")
  for (state <- Seq(enq_ptr.value, deq_ptr.value, maybe_full)) {
    VivadoAttributes(state.toTarget, "dont_touch = \"yes\"")
  }
}

/** Cycle-equivalent to Queue, including its pipe/flow options and capacity.
  * Chunk controls observe the same handshakes but are preserved independently;
  * no one pointer or clock-enable must drive the entire wide payload.
  */
class BankedShallowQueue[T <: Data](gen: T, val entries: Int,
    pipe: Boolean = false, flow: Boolean = false, bankBits: Int = 64,
    registerPayload: Boolean = false) extends Module {
  require(entries > 0 && entries <= 8 && bankBits > 0)
  private val width = gen.getWidth
  require(width > 0)
  val io = IO(new Bundle {
    val enq = Flipped(Decoupled(gen.cloneType))
    val deq = Decoupled(gen.cloneType)
    val count = Output(UInt(log2Ceil(entries + 1).W))
  })

  val slices = (0 until width by bankBits).map { low =>
    val high = math.min(low + bankBits, width) - 1
    val slice = if (registerPayload || entries == 1) {
      Module(new ShallowQueueSlice(high - low + 1, entries, pipe, flow)).io
    } else {
      Module(new ShallowQueueRamSlice(high - low + 1, entries, pipe, flow)).io
    }
    slice.enq.valid := io.enq.valid
    slice.enq.bits := io.enq.bits.asUInt(high, low)
    slice.deq.ready := io.deq.ready
    slice
  }
  io.enq.ready := slices.head.enq.ready
  io.deq.valid := slices.head.deq.valid
  io.count := slices.head.count
  io.deq.bits := Cat(slices.reverse.map(_.deq.bits)).asTypeOf(gen)
  for (slice <- slices.tail) {
    assert(slice.count === slices.head.count)
  }
}
