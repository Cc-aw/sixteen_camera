// SPDX-License-Identifier: Apache-2.0
package freechips.rocketchip.tile.commandfrontend

import chisel3._
import chisel3.util._
import chisel3.util.HasBlackBoxResource
import org.chipsalliance.cde.config.Parameters
import org.chipsalliance.diplomacy.lazymodule._
import freechips.rocketchip.diplomacy.{RegionType, TransferSizes}
import freechips.rocketchip.tilelink._

class ActivationSramOperation extends Bundle {
  val write = Bool()
  val word = UInt(17.W)
  val mask = UInt(32.W)
  val data = UInt(256.W)
}

class ActivationSramStore extends BlackBox with HasBlackBoxResource {
  override def desiredName = "activation_sram_store"
  val io = IO(new Bundle {
    val clock = Input(Clock())
    val a_en = Input(Bool()); val a_write = Input(Bool()); val a_word = Input(UInt(17.W))
    val a_mask = Input(UInt(32.W)); val a_data = Input(UInt(256.W)); val a_read = Output(UInt(256.W))
    val b_en = Input(Bool()); val b_write = Input(Bool()); val b_word = Input(UInt(17.W))
    val b_mask = Input(UInt(32.W)); val b_data = Input(UInt(256.W)); val b_read = Output(UInt(256.W))
  })
  addResource("/vsrc/activation_sram_store.sv")
}

/** Ordered 1..64B non-coherent endpoint. Each physical operation reserves its
  * eventual D beat BEFORE launching an irrevocable synchronous read. Write
  * responses traverse the same two stages and are never acknowledged on A.
  */
class ActivationSramPort(params: TLBundleParameters, base: BigInt) extends Module {
  require(params.dataBits == 256 && params.addressBits >= 30)
  val io = IO(new Bundle {
    val a = Flipped(Decoupled(new TLBundleA(params)))
    val d = Decoupled(new TLBundleD(params))
    val operation = Decoupled(new ActivationSramOperation)
    val read = Input(UInt(256.W))
    val clear = Input(Bool())
    val counters = Output(Vec(20, UInt(64.W)))
    val outstanding = Output(UInt(7.W))
  })
  val requests = Module(new Queue(new TLBundleA(params), 64, pipe = false, flow = false))
  val responses = Module(new Queue(new TLBundleD(params), 8, pipe = false, flow = false))
  val outstanding = RegInit(0.U(7.W))
  val incomingSecond = RegInit(false.B)
  val incomingPut = io.a.bits.opcode === TLMessages.PutFullData || io.a.bits.opcode === TLMessages.PutPartialData
  val canAccept = incomingSecond || outstanding < 32.U
  requests.io.enq.valid := io.a.valid && canAccept
  requests.io.enq.bits := io.a.bits
  io.a.ready := requests.io.enq.ready && canAccept
  val accepted = io.a.fire && !incomingSecond
  when(io.a.fire) {
    incomingSecond := incomingPut && io.a.bits.size === 6.U && !incomingSecond
  }

  val a = requests.io.deq.bits
  val put = a.opcode === TLMessages.PutFullData || a.opcode === TLMessages.PutPartialData
  val get = a.opcode === TLMessages.Get
  val second = RegInit(false.B)
  val putError = RegInit(false.B)
  val two = a.size === 6.U
  val lastOperation = !two || second
  val end = a.address +& (1.U(65.W) << a.size)
  val legal = (get || put) && a.size <= 6.U && a.param === 0.U &&
    a.address >= base.U && end <= (base + ActivationSramMap.bytes).U &&
    (a.address & ((1.U(65.W) << a.size) - 1.U)) === 0.U
  val error = !legal || a.corrupt || (put && second && putError)
  val needsResponse = get || lastOperation
  val credits = RegInit(0.U(4.W)) // FIFO occupancy plus BOTH pipeline stages
  val eligible = requests.io.deq.valid && (!needsResponse || credits < 8.U)
  io.operation.valid := eligible && !error
  io.operation.bits.write := put
  io.operation.bits.word := ((a.address - base.U) >> 5) + second.asUInt
  io.operation.bits.mask := a.mask
  io.operation.bits.data := a.data
  val issue = eligible && (error || io.operation.ready)
  val responseIssue = issue && needsResponse
  requests.io.deq.ready := issue && (put || lastOperation)
  when(issue) {
    second := two && !second
    when(put) { putError := Mux(lastOperation, false.B, error) }
  }

  val metadata = Wire(new TLBundleD(params))
  metadata := 0.U.asTypeOf(metadata)
  metadata.opcode := Mux(get, TLMessages.AccessAckData, TLMessages.AccessAck)
  metadata.size := a.size; metadata.source := a.source
  metadata.denied := error; metadata.corrupt := error && get
  val stage0Valid = RegNext(responseIssue, false.B)
  val stage1Valid = RegNext(stage0Valid, false.B)
  val stage0 = RegEnable(metadata, responseIssue)
  val stage1 = RegEnable(stage0, stage0Valid)
  responses.io.enq.valid := stage1Valid
  responses.io.enq.bits := stage1
  responses.io.enq.bits.data := Mux(stage1.denied, 0.U, io.read)
  assert(!stage1Valid || responses.io.enq.ready, "ASRAM irrevocable response has no reserved credit")
  io.d <> responses.io.deq
  credits := credits + responseIssue.asUInt - io.d.fire.asUInt
  assert(credits <= 8.U)
  assert(credits === responses.io.count +& stage0Valid.asUInt +& stage1Valid.asUInt,
    "ASRAM response credit does not match FIFO plus irrevocable pipeline")

  val returningSecond = RegInit(false.B)
  val retired = io.d.fire && (io.d.bits.opcode =/= TLMessages.AccessAckData ||
    io.d.bits.size =/= 6.U || returningSecond)
  when(io.d.fire) {
    returningSecond := io.d.bits.opcode === TLMessages.AccessAckData && io.d.bits.size === 6.U && !returningSecond
  }
  outstanding := outstanding + accepted.asUInt - retired.asUInt
  io.outstanding := outstanding
  assert(outstanding <= 32.U && !(retired && outstanding === 0.U))

  val counts = RegInit(VecInit(Seq.fill(20)(0.U(64.W))))
  val increments = Wire(Vec(20, UInt(64.W)))
  increments.foreach(_ := 0.U)
  increments(0) := accepted
  increments(1) := retired
  increments(2) := accepted && io.a.bits.opcode === TLMessages.Get
  increments(3) := accepted && io.a.bits.opcode === TLMessages.PutFullData
  increments(4) := accepted && io.a.bits.opcode === TLMessages.PutPartialData
  increments(5) := Mux(accepted && io.a.bits.opcode === TLMessages.Get, 1.U << io.a.bits.size, 0.U)
  increments(6) := Mux(io.operation.fire && put, PopCount(a.mask), 0.U)
  increments(7) := io.d.fire && io.d.bits.opcode === TLMessages.AccessAckData
  increments(8) := io.d.fire && io.d.bits.opcode === TLMessages.AccessAck
  increments(9) := io.a.valid && !io.a.ready
  increments(10) := io.d.valid && !io.d.ready
  increments(11) := requests.io.deq.valid && needsResponse && credits === 8.U
  increments(12) := io.operation.fire && get
  increments(13) := io.operation.fire && put
  increments(14) := io.operation.valid && !io.operation.ready
  increments(15) := issue && error
  increments(16) := issue && a.corrupt
  increments(17) := outstanding
  // 18: outstanding peak, 19: response credit peak; neither is a capacity.
  when(io.clear) {
    counts.foreach(_ := 0.U)
  }.otherwise {
    for(i <- 0 until 18) { counts(i) := counts(i) + increments(i) }
    counts(18) := Mux(outstanding > counts(18), outstanding, counts(18))
    counts(19) := Mux(credits > counts(19), credits, counts(19))
  }
  io.counters := counts
}

/** Both managers terminate at ONE store. DMA sees all reserved ASRAM windows:
  * only this lane's valid range succeeds; foreign windows/control/hole deny.
  * The CPU service manager exposes just this bank's complete reserved window.
  */
class ActivationSramTL(lane: Int)(implicit p: Parameters) extends LazyModule {
  require(lane >= 0 && lane < 3)
  private def port(address: Seq[freechips.rocketchip.diplomacy.AddressSet], name: String) =
    TLManagerNode(Seq(TLSlavePortParameters.v1(Seq(TLSlaveParameters.v1(
      address = address, regionType = RegionType.IDEMPOTENT, executable = false,
      supportsGet = TransferSizes(1, 64), supportsPutFull = TransferSizes(1, 64),
      supportsPutPartial = TransferSizes(1, 64), fifoId = Some(0),
      mayDenyGet = true, mayDenyPut = true).v2copy(name = Some(name))), beatBytes = 32, minLatency = 2)))
  val dmaNode = port(ActivationSramMap.reserved, s"activation-sram-$lane-dma")
  val serviceNode = port(Seq(ActivationSramMap.reserved(lane)), s"activation-sram-$lane-service")
  lazy val module = new Impl
  class Impl extends LazyModuleImp(this) {
    val clear = IO(Input(Bool()))
    val counters = IO(Output(Vec(2, Vec(20, UInt(64.W)))))
    val outstanding = IO(Output(Vec(2, UInt(7.W))))
    val ports = Seq(dmaNode, serviceNode).zipWithIndex.map { case (node, index) =>
      require(node.in.size == 1)
      val (tl, edge) = node.in.head
      val controller = Module(new ActivationSramPort(edge.bundle, ActivationSramMap.bases(lane)))
      controller.io.a <> tl.a; tl.d <> controller.io.d
      tl.b.valid := false.B; tl.b.bits := 0.U.asTypeOf(tl.b.bits)
      tl.c.ready := true.B; tl.e.ready := true.B
      controller.io.clear := clear
      counters(index) := controller.io.counters; outstanding(index) := controller.io.outstanding
      controller
    }
    val a = ports(0).io.operation; val b = ports(1).io.operation
    val preferService = RegInit(false.B)
    val conflict = a.valid && b.valid && a.bits.word === b.bits.word && (a.bits.write || b.bits.write)
    // Fixed reset priority followed by alternation: deterministic and no
    // starvation when both ports repeatedly access a word containing writes.
    a.ready := !conflict || !preferService
    b.ready := !conflict || preferService
    when(conflict && (a.fire || b.fire)) { preferService := !preferService }
    val memory = Module(new ActivationSramStore)
    memory.io.clock := clock
    memory.io.a_en := a.fire; memory.io.a_write := a.bits.write
    memory.io.a_word := a.bits.word; memory.io.a_mask := a.bits.mask; memory.io.a_data := a.bits.data
    memory.io.b_en := b.fire; memory.io.b_write := b.bits.write
    memory.io.b_word := b.bits.word; memory.io.b_mask := b.bits.mask; memory.io.b_data := b.bits.data
    ports(0).io.read := memory.io.a_read; ports(1).io.read := memory.io.b_read
    assert(!(a.fire && b.fire && a.bits.word === b.bits.word && (a.bits.write || b.bits.write)))
  }
}
