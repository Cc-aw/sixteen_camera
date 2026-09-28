package gemmini

import chisel3._
import chisel3.util._
import chisel3.experimental.IntParam
import Util._

/** A fixed-latency fabric pipeline. USER_SLL_REG=FALSE prevents the short
  * Laguna TX/RX pairing that the router skipped repairing in the 0912 route.
  * Attributes must target a scalar UInt/Bool register: attributes on aggregate
  * Reg(Vec(...)) are discarded by aggregate lowering in this CIRCT version.
  */
object FabricShiftRegister {
  private val attributes = "shreg_extract = \"no\", USER_SLL_REG = \"FALSE\""

  def apply[T <: Data](in: T, cycles: Int): T = {
    require(cycles >= 0)
    (0 until cycles).foldLeft(in) { (data, _) =>
      val value = RegNext(data.asUInt)
      VivadoAttributes(value.toTarget, attributes)
      value.asTypeOf(data)
    }
  }

  def valid(in: Bool, cycles: Int): Bool = {
    require(cycles >= 0)
    (0 until cycles).foldLeft(in) { (data, _) =>
      val value = RegNext(data, false.B)
      VivadoAttributes(value.toTarget, attributes)
      value
    }
  }
}

/** Keep a register at each end of a skew delay. The middle may use
  * SRLs, but a distant input buffer no longer directly drives the SRL D pin.
  * These registers are taken from the existing delay, not added to it.
  */
object RegisteredSkewDelay {
  def apply[T <: Data](in: T, cycles: Int): T = {
    require(cycles >= 0)
    def endpoint(data: T): T = FabricShiftRegister(data, 1)
    if (cycles == 0) in
    else if (cycles == 1) endpoint(in)
    else endpoint(ShiftRegister(endpoint(in), cycles - 2))
  }
}

/** Payload registers are intentionally not reset. The owner carries validity. */
class TimingDualMac(packed: Boolean, outputWidth: Int = 20) extends BlackBox(Map(
  "PACKED" -> IntParam(if (packed) 1 else 0),
  "OUTPUT_WIDTH" -> IntParam(outputWidth))) with HasBlackBoxResource {
  require(outputWidth >= 20 && outputWidth <= 48)
  val io = IO(new Bundle {
    val clock = Input(Clock())
    val a = Input(SInt(8.W))
    val b0 = Input(SInt(8.W))
    val b1 = Input(SInt(8.W))
    val c0 = Input(SInt(outputWidth.W))
    val c1 = Input(SInt(outputWidth.W))
    val d0 = Output(SInt(outputWidth.W))
    val d1 = Output(SInt(outputWidth.W))
  })
  override def desiredName = "GemminiTimingMac"
  addResource("/vsrc/GemminiTimingMac.sv")
}

/** Two cycles for both implementations. Unpacked lanes register the product
  * before addition, allowing Vivado to use MREG and PREG in the same DSP.
  * The old unpacked primitive did multiply + add before PREG, then spent its
  * second cycle in fabric alignment registers. No payload register is reset.
  */
class PipelinedDualMac(packed: Boolean, outputWidth: Int = 20) extends Module {
  require(outputWidth >= 20 && outputWidth <= 48)
  val io = IO(new Bundle {
    val a = Input(SInt(8.W))
    val b0 = Input(SInt(8.W))
    val b1 = Input(SInt(8.W))
    val c0 = Input(SInt(outputWidth.W))
    val c1 = Input(SInt(outputWidth.W))
    val d0 = Output(SInt(outputWidth.W))
    val d1 = Output(SInt(outputWidth.W))
  })

  if (packed) {
    val mac = Module(new TimingDualMac(packed = true, outputWidth = outputWidth))
    mac.io.clock := clock
    mac.io.a := io.a
    mac.io.b0 := io.b0
    mac.io.b1 := io.b1
    mac.io.c0 := io.c0
    mac.io.c1 := io.c1
    io.d0 := mac.io.d0
    io.d1 := mac.io.d1
  } else {
    // Without this source-level attribute, Vivado maps these small INT8
    // multiplies to LUTs, defeating both the DSP budget and the pipeline.
    VivadoAttributes(this.toTarget, "use_dsp = \"yes\"")
    val product0 = RegNext(io.a * io.b0)
    val product1 = RegNext(io.a * io.b1)
    val addend0 = RegNext(io.c0)
    val addend1 = RegNext(io.c1)
    io.d0 := RegNext(product0 + addend0)
    io.d1 := RegNext(product1 + addend1)
  }
}

/** One barrel shifter for a TileLink write beat. Bytes below the first mask
  * bit are unobserved by PutPartialData. Padding the input handles the first
  * unaligned beat without a right shifter followed by another left shifter.
  */
class DmaWriteDataAlign(dataWidth: Int, beatBytes: Int, offsetBits: Int) extends Module {
  require(dataWidth % 8 == 0 && isPow2(beatBytes))
  val io = IO(new Bundle {
    val data = Input(UInt(dataWidth.W))
    val offset = Input(UInt(offsetBits.W))
    val mask = Input(UInt(beatBytes.W))
    val beat = Output(UInt((beatBytes * 8).W))
  })
  val firstByte = PriorityEncoder(io.mask)
  val padded = Cat(io.data, 0.U((beatBytes * 8).W))
  val offset = (io.offset +& beatBytes.U) - firstByte
  io.beat := padded >> (offset << 3)
}

class LocalSelect(groups: Int) extends BlackBox(Map("GROUPS" -> IntParam(groups)))
    with HasBlackBoxResource {
  val io = IO(new Bundle {
    val clock = Input(Clock())
    val d = Input(Bool())
    val q = Output(UInt(groups.W))
  })
  override def desiredName = "GemminiLocalSelect"
  addResource("/vsrc/GemminiLocalSelect.sv")
}

/** Ring window with registered pop. Payload entries never move. The pop
  * decision is captured before it changes read address/count, so execution
  * decode cannot feed a bank of payload register CEs in the same cycle. */
class RegisteredCommandWindow[T <: Data](gen: T, entries: Int, heads: Int = 3)
    extends Module {
  require(entries >= heads && heads >= 2)
  val io = IO(new Bundle {
    val enq = Flipped(Decoupled(gen))
    val bits = Output(Vec(heads, gen))
    val valid = Output(Vec(heads, Bool()))
    val pop = Input(UInt(2.W))
    val count = Output(UInt(log2Ceil(entries + 1).W))
  })
  val data = Reg(Vec(entries, gen))
  val raddr = RegInit(0.U((log2Ceil(entries) max 1).W))
  val waddr = RegInit(0.U((log2Ceil(entries) max 1).W))
  val count = RegInit(0.U(log2Ceil(entries + 1).W))
  val pendingPop = RegInit(0.U(2.W))
  io.enq.ready := count < entries.U
  io.count := count
  for (i <- 0 until heads) {
    io.bits(i) := data(wrappingAdd(raddr, i.U, entries))
    io.valid(i) := pendingPop === 0.U && count > i.U
  }
  when(io.enq.fire) {
    data(waddr) := io.enq.bits
    waddr := wrappingAdd(waddr, 1.U, entries)
  }
  when(pendingPop =/= 0.U) {
    raddr := wrappingAdd(raddr, pendingPop, entries)
    count := count - pendingPop + io.enq.fire
    pendingPop := 0.U
  }.otherwise {
    when(io.enq.fire) { count := count + 1.U }
    when(io.pop =/= 0.U) { pendingPop := io.pop }
  }
  assert(io.pop <= 2.U && io.pop <= count)
  assert(pendingPop === 0.U || io.pop === 0.U)
}

/** Synchronous BRAM FIFO with a two-entry prefetch queue. Storage count and
  * prefetched/read-in-flight elements all contribute to the externally visible
  * occupancy. No combinational data/ready bypass crosses the RAM. */
class TimingResultQueue[T <: Data](gen: T, depth: Int) extends Module {
  require(isPow2(depth) && depth >= 8)
  val io = IO(new Bundle {
    val enq = Flipped(Decoupled(gen))
    val deq = Decoupled(gen)
    val count = Output(UInt(log2Ceil(depth + 1).W))
  })
  val width = gen.getWidth
  val pieces = math.min(8, width)
  val pieceWidth = (width + pieces - 1) / pieces
  val memories = Seq.fill(pieces)(SyncReadMem(depth, UInt(pieceWidth.W)))
  val wr = RegInit(0.U(log2Ceil(depth).W))
  val rd = RegInit(0.U(log2Ceil(depth).W))
  val stored = RegInit(0.U(log2Ceil(depth + 1).W))
  val total = RegInit(0.U(log2Ceil(depth + 1).W))
  val pending = RegInit(false.B)
  val out = Module(new BankedShallowQueue(gen, 2, pipe = false, flow = false))
  val prefetch = stored =/= 0.U &&
    ((out.io.count +& pending.asUInt) < 2.U || out.io.deq.fire)
  val readData = Cat(memories.map(_.read(rd, prefetch)).reverse).asTypeOf(gen)
  pending := prefetch
  out.io.enq.valid := pending
  out.io.enq.bits := readData
  assert(!pending || out.io.enq.ready)
  io.deq <> out.io.deq
  io.enq.ready := total < depth.U
  io.count := total
  when(io.enq.fire) {
    for(i <- 0 until pieces) {
      memories(i).write(wr, io.enq.bits.asUInt(math.min(width - 1, (i + 1) * pieceWidth - 1), i * pieceWidth))
    }
    wr := wr + 1.U
  }
  when(prefetch) { rd := rd + 1.U }
  stored := stored + io.enq.fire - prefetch
  total := total + io.enq.fire - io.deq.fire
  assert(total <= depth.U)
}

/** Two carry-chain stages, exact modulo-2^32 addition. */
class LocalAccAdder extends Module {
  val io = IO(new Bundle {
    val a = Input(UInt(32.W))
    val b = Input(UInt(32.W))
    val sum = Output(UInt(32.W))
  })
  val low = RegNext(io.a(15, 0) +& io.b(15, 0))
  val highA = RegNext(io.a(31, 16))
  val highB = RegNext(io.b(31, 16))
  io.sum := RegNext(Cat((highA + highB + low(16))(15, 0), low(15, 0)))
}

class BankWriteToken(addrBits: Int, dataBits: Int) extends Bundle {
  val addr = UInt(addrBits.W)
  val data = UInt(dataBits.W)
  val mask = Vec(dataBits / 8, Bool())
  val acc = Bool()
  val ex = Bool()
}

/** Preserves acceptance order across EX/DMA/zero. Pending addresses remain
  * visible to the read arbiter until the request enters the memory pipeline. */
class OrderedBankWrites(addrBits: Int, dataBits: Int) extends Module {
  val io = IO(new Bundle {
    val enq = Flipped(Decoupled(new BankWriteToken(addrBits, dataBits)))
    val deq = Decoupled(new BankWriteToken(addrBits, dataBits))
    val readAddr = Input(UInt(addrBits.W))
    val readHazard = Output(Bool())
    val exPending = Output(Bool())
  })
  val q = Module(new BankedShallowQueue(new BankWriteToken(addrBits, dataBits), 2,
    pipe = false, flow = false))
  q.io.enq <> io.enq
  io.deq <> q.io.deq
  val valid = RegInit(VecInit(Seq.fill(2)(false.B)))
  val addr = Reg(Vec(2, UInt(addrBits.W)))
  val ex = Reg(Vec(2, Bool()))
  val w = RegInit(false.B)
  val r = RegInit(false.B)
  when(io.enq.fire) {
    valid(w) := true.B; addr(w) := io.enq.bits.addr; ex(w) := io.enq.bits.ex; w := !w
  }
  when(io.deq.fire) { valid(r) := false.B; r := !r }
  io.readHazard := (0 until 2).map(i => valid(i) && addr(i) === io.readAddr).reduce(_ || _) ||
    (io.enq.fire && io.enq.bits.addr === io.readAddr)
  io.exPending := (0 until 2).map(i => valid(i) && ex(i)).reduce(_ || _)
}
