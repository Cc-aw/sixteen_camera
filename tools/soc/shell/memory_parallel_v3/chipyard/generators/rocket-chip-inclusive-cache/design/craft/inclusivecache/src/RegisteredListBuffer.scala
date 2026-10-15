package sifive.blocks.inclusivecache

import chisel3._
import chisel3.util._

/** Shared secondary-request pool with a synchronous payload read. Popping
  * transfers ownership into a four-entry response pipeline; it never exposes
  * an asynchronous payload mux to the scheduler. Pointers remain narrow.
  */
class RegisteredListBuffer[T <: Data](params: ListBufferParameters[T]) extends Module {
  override def desiredName = s"RegisteredListBuffer_q${params.queues}_e${params.entries}"
  val io = IO(new Bundle {
    val push = Flipped(Decoupled(new ListBufferPush(params)))
    val valid = Output(UInt(params.queues.W))
    val pop = Flipped(Decoupled(UInt(params.queueBits.W)))
    val result = Decoupled(new Bundle {
      val index = UInt(params.queueBits.W)
      val data = params.gen.cloneType
    })
  })
  val valid = RegInit(0.U(params.queues.W))
  val used = RegInit(0.U(params.entries.W))
  val head = Reg(Vec(params.queues, UInt(params.entryBits.W)))
  val tail = Reg(Vec(params.queues, UInt(params.entryBits.W)))
  val next = Reg(Vec(params.entries, UInt(params.entryBits.W)))
  val payload = SyncReadMem(params.entries, params.gen)
  val responses = Module(new Queue(chiselTypeOf(io.result.bits), 4, pipe=false, flow=false))
  io.result <> responses.io.deq
  val pending = RegNext(io.pop.fire, false.B)
  val index = RegEnable(io.pop.bits, io.pop.fire)
  // Count the issued read before granting another response credit. The RAM
  // response is irrevocable; downstream backpressure is absorbed locally.
  io.pop.ready := responses.io.count +& pending.asUInt < 4.U && valid(io.pop.bits)
  val readHead = head(io.pop.bits)
  val readData = payload.read(readHead, io.pop.fire)
  responses.io.enq.valid := pending
  responses.io.enq.bits.index := index
  responses.io.enq.bits.data := readData
  assert(!pending || responses.io.enq.ready, "secondary response credit lost")

  val free = PriorityEncoder(~used)
  io.push.ready := !used.andR
  val pushOH = Mux(io.push.fire, UIntToOH(io.push.bits.index, params.queues), 0.U)
  val last = readHead === tail(io.pop.bits)
  val clearOH = Mux(io.pop.fire && last, UIntToOH(io.pop.bits, params.queues), 0.U)
  valid := (valid & ~clearOH) | pushOH
  used := (used & ~Mux(io.pop.fire, UIntToOH(readHead,params.entries),0.U)) |
    Mux(io.push.fire,UIntToOH(free,params.entries),0.U)
  when(io.push.fire) {
    payload.write(free,io.push.bits.data)
    when(valid(io.push.bits.index) && !(io.pop.fire && last && io.pop.bits===io.push.bits.index)) {
      next(tail(io.push.bits.index)) := free
    }
    tail(io.push.bits.index) := free
  }
  for(i <- 0 until params.queues) {
    val pushes = io.push.fire && io.push.bits.index===i.U
    val pops = io.pop.fire && io.pop.bits===i.U
    when(pops && !last) { head(i) := next(readHead) }
    when(pushes && (!valid(i) || (pops && last))) { head(i) := free }
  }
  io.valid := valid
  assert(!io.pop.fire || valid(io.pop.bits))
}
