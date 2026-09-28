// See LICENSE.Berkeley for license details.
// See LICENSE.SiFive for license details.

package freechips.rocketchip.tile

import chisel3._
import chisel3.util._
import chisel3.experimental.IntParam

import org.chipsalliance.cde.config._
import org.chipsalliance.diplomacy.lazymodule._

import freechips.rocketchip.rocket.{
  MStatus, HellaCacheIO, TLBPTWIO, CanHavePTW, CanHavePTWModule,
  SimpleHellaCacheIF, M_XRD, PTE, PRV, M_SZ
}
import freechips.rocketchip.tilelink.{
  TLNode, TLIdentityNode, TLClientNode, TLMasterParameters, TLMasterPortParameters
}
import freechips.rocketchip.util.InOrderArbiter

case object BuildRoCC extends Field[Seq[Parameters => LazyRoCC]](Nil)

class RoCCInstruction extends Bundle {
  val funct = Bits(7.W)
  val rs2 = Bits(5.W)
  val rs1 = Bits(5.W)
  val xd = Bool()
  val xs1 = Bool()
  val xs2 = Bool()
  val rd = Bits(5.W)
  val opcode = Bits(7.W)
}

class RoCCCommand(implicit p: Parameters) extends CoreBundle()(p) {
  val inst = new RoCCInstruction
  val rs1 = Bits(xLen.W)
  val rs2 = Bits(xLen.W)
  val status = new MStatus
}

class RoCCResponse(implicit p: Parameters) extends CoreBundle()(p) {
  val rd = Bits(5.W)
  val data = Bits(xLen.W)
}

class RoCCCoreIO(val nRoCCCSRs: Int = 0)(implicit p: Parameters) extends CoreBundle()(p) {
  val cmd = Flipped(Decoupled(new RoCCCommand))
  val resp = Decoupled(new RoCCResponse)
  val mem = new HellaCacheIO
  val busy = Output(Bool())
  val interrupt = Output(Bool())
  val exception = Input(Bool())
  val csrs = Flipped(Vec(nRoCCCSRs, new CustomCSRIO))

}

class RoCCIO(val nPTWPorts: Int, nRoCCCSRs: Int)(implicit p: Parameters) extends RoCCCoreIO(nRoCCCSRs)(p) {
  val ptw = Vec(nPTWPorts, new TLBPTWIO)
  val fpu_req = Decoupled(new FPInput)
  val fpu_resp = Flipped(Decoupled(new FPResult))
  // IPOAT（王志瑞）-I：Ingress 观测只属于 accelerator worker 接口，不能放进
  // RoCCCoreIO；后者还会被 Rocket core Flipped，放在那里会产生未初始化的 core 输出。
  // 这些 sideband 不参与 cmd ready，避免 credit 查询重新形成 Rocket/LoopConv 组合环。
  val loopconv_request_accept = Input(Bool())
  val loopconv_request_queue_count = Input(UInt(8.W))
  val loopconv_assembler_partial = Input(Bool())
}

/** Base classes for Diplomatic TL2 RoCC units **/
abstract class LazyRoCC(
  val opcodes: OpcodeSet,
  val nPTWPorts: Int = 0,
  val usesFPU: Boolean = false,
  val roccCSRs: Seq[CustomCSR] = Nil
)(implicit p: Parameters) extends LazyModule {
  val module: LazyRoCCModuleImp
  require(roccCSRs.map(_.id).toSet.size == roccCSRs.size)
  val atlNode: TLNode = TLIdentityNode()
  val tlNode: TLNode = TLIdentityNode()
  val stlNode: TLNode = TLIdentityNode()
}

class LazyRoCCModuleImp(outer: LazyRoCC) extends LazyModuleImp(outer) {
  val io = IO(new RoCCIO(outer.nPTWPorts, outer.roccCSRs.size))
  io := DontCare
}

/** Mixins for including RoCC **/

trait HasLazyRoCC extends CanHavePTW { this: BaseTile =>
  val roccs = p(BuildRoCC).map(_(p))
  val roccCSRs = roccs.map(_.roccCSRs) // the set of custom CSRs requested by all roccs
  require(roccCSRs.flatten.map(_.id).toSet.size == roccCSRs.flatten.size,
    "LazyRoCC instantiations require overlapping CSRs")
  roccs.map(_.atlNode).foreach { atl => tlMasterXbar.node :=* atl }
  roccs.map(_.tlNode).foreach { tl => tlOtherMastersNode :=* tl }
  roccs.map(_.stlNode).foreach { stl => stl :*= tlSlaveXbar.node }

  nPTWPorts += roccs.map(_.nPTWPorts).sum
  nDCachePorts += roccs.size
}

trait HasLazyRoCCModule extends CanHavePTWModule
    with HasCoreParameters { this: RocketTileModuleImp =>

  val (respArb, cmdRouter) = if(outer.roccs.nonEmpty) {
    val respArb = Module(new RRArbiter(new RoCCResponse()(outer.p), outer.roccs.size))
    val cmdRouter = Module(new RoccCommandRouter(outer.roccs.map(_.opcodes))(outer.p))
    outer.roccs.zipWithIndex.foreach { case (rocc, i) =>
      rocc.module.io.ptw ++=: ptwPorts
      rocc.module.io.cmd <> cmdRouter.io.out(i)
      // IPOAT（王志瑞）-I：Router 的 ingress 观测只送到命中的 RoCC worker。该连接不参与
      // cmd ready 计算，credit status CSR 不会改变原有 RoCC 握手时序。
      rocc.module.io.loopconv_request_accept := cmdRouter.io.loopconv_request_accept(i)
      rocc.module.io.loopconv_request_queue_count := cmdRouter.io.loopconv_request_queue_count(i)
      rocc.module.io.loopconv_assembler_partial := cmdRouter.io.loopconv_assembler_partial(i)
      val dcIF = Module(new SimpleHellaCacheIF()(outer.p))
      dcIF.io.requestor <> rocc.module.io.mem
      dcachePorts += dcIF.io.cache
      respArb.io.in(i) <> Queue(rocc.module.io.resp)
    }
    (Some(respArb), Some(cmdRouter))
  } else {
    (None, None)
  }
  val roccCSRIOs = outer.roccs.map(_.module.io.csrs)
}

class AccumulatorExample(opcodes: OpcodeSet, val n: Int = 4)(implicit p: Parameters) extends LazyRoCC(opcodes) {
  override lazy val module = new AccumulatorExampleModuleImp(this)
}

class AccumulatorExampleModuleImp(outer: AccumulatorExample)(implicit p: Parameters) extends LazyRoCCModuleImp(outer)
    with HasCoreParameters {
  val regfile = Mem(outer.n, UInt(xLen.W))
  val busy = RegInit(VecInit(Seq.fill(outer.n){false.B}))

  val cmd = Queue(io.cmd)
  val funct = cmd.bits.inst.funct
  val addr = cmd.bits.rs2(log2Up(outer.n)-1,0)
  val doWrite = funct === 0.U
  val doRead = funct === 1.U
  val doLoad = funct === 2.U
  val doAccum = funct === 3.U
  val memRespTag = io.mem.resp.bits.tag(log2Up(outer.n)-1,0)

  // datapath
  val addend = cmd.bits.rs1
  val accum = regfile(addr)
  val wdata = Mux(doWrite, addend, accum + addend)

  when (cmd.fire && (doWrite || doAccum)) {
    regfile(addr) := wdata
  }

  when (io.mem.resp.valid) {
    regfile(memRespTag) := io.mem.resp.bits.data
    busy(memRespTag) := false.B
  }

  // control
  when (io.mem.req.fire) {
    busy(addr) := true.B
  }

  val doResp = cmd.bits.inst.xd
  val stallReg = busy(addr)
  val stallLoad = doLoad && !io.mem.req.ready
  val stallResp = doResp && !io.resp.ready

  cmd.ready := !stallReg && !stallLoad && !stallResp
    // command resolved if no stalls AND not issuing a load that will need a request

  // PROC RESPONSE INTERFACE
  io.resp.valid := cmd.valid && doResp && !stallReg && !stallLoad
    // valid response if valid command, need a response, and no stalls
  io.resp.bits.rd := cmd.bits.inst.rd
    // Must respond with the appropriate tag or undefined behavior
  io.resp.bits.data := accum
    // Semantics is to always send out prior accumulator register value

  io.busy := cmd.valid || busy.reduce(_||_)
    // Be busy when have pending memory requests or committed possibility of pending requests
  io.interrupt := false.B
    // Set this true to trigger an interrupt on the processor (please refer to supervisor documentation)

  // MEMORY REQUEST INTERFACE
  io.mem.req.valid := cmd.valid && doLoad && !stallReg && !stallResp
  io.mem.req.bits.addr := addend
  io.mem.req.bits.tag := addr
  io.mem.req.bits.cmd := M_XRD // perform a load (M_XWR for stores)
  io.mem.req.bits.size := log2Ceil(8).U
  io.mem.req.bits.signed := false.B
  io.mem.req.bits.data := 0.U // we're not performing any stores...
  io.mem.req.bits.phys := false.B
  io.mem.req.bits.dprv := cmd.bits.status.dprv
  io.mem.req.bits.dv := cmd.bits.status.dv
  io.mem.req.bits.no_resp := false.B
}

class  TranslatorExample(opcodes: OpcodeSet)(implicit p: Parameters) extends LazyRoCC(opcodes, nPTWPorts = 1) {
  override lazy val module = new TranslatorExampleModuleImp(this)
}

class TranslatorExampleModuleImp(outer: TranslatorExample)(implicit p: Parameters) extends LazyRoCCModuleImp(outer)
    with HasCoreParameters {
  val req_addr = Reg(UInt(coreMaxAddrBits.W))
  val req_rd = Reg(chiselTypeOf(io.resp.bits.rd))
  val req_offset = req_addr(pgIdxBits - 1, 0)
  val req_vpn = req_addr(coreMaxAddrBits - 1, pgIdxBits)
  val pte = Reg(new PTE)

  val s_idle :: s_ptw_req :: s_ptw_resp :: s_resp :: Nil = Enum(4)
  val state = RegInit(s_idle)

  io.cmd.ready := (state === s_idle)

  when (io.cmd.fire) {
    req_rd := io.cmd.bits.inst.rd
    req_addr := io.cmd.bits.rs1
    state := s_ptw_req
  }

  private val ptw = io.ptw(0)

  when (ptw.req.fire) { state := s_ptw_resp }

  when (state === s_ptw_resp && ptw.resp.valid) {
    pte := ptw.resp.bits.pte
    state := s_resp
  }

  when (io.resp.fire) { state := s_idle }

  ptw.req.valid := (state === s_ptw_req)
  ptw.req.bits.valid := true.B
  ptw.req.bits.bits.addr := req_vpn

  io.resp.valid := (state === s_resp)
  io.resp.bits.rd := req_rd
  io.resp.bits.data := Mux(pte.leaf(), Cat(pte.ppn, req_offset), -1.S(xLen.W).asUInt)

  io.busy := (state =/= s_idle)
  io.interrupt := false.B
  io.mem.req.valid := false.B
}

class  CharacterCountExample(opcodes: OpcodeSet)(implicit p: Parameters) extends LazyRoCC(opcodes) {
  override lazy val module = new CharacterCountExampleModuleImp(this)
  override val atlNode = TLClientNode(Seq(TLMasterPortParameters.v1(Seq(TLMasterParameters.v1("CharacterCountRoCC")))))
}

class CharacterCountExampleModuleImp(outer: CharacterCountExample)(implicit p: Parameters) extends LazyRoCCModuleImp(outer)
  with HasCoreParameters
  with HasL1CacheParameters {
  val cacheParams = tileParams.dcache.get

  private val blockOffset = blockOffBits
  private val beatOffset = log2Up(cacheDataBits/8)

  val needle = Reg(UInt(8.W))
  val addr = Reg(UInt(coreMaxAddrBits.W))
  val count = Reg(UInt(xLen.W))
  val resp_rd = Reg(chiselTypeOf(io.resp.bits.rd))

  val addr_block = addr(coreMaxAddrBits - 1, blockOffset)
  val offset = addr(blockOffset - 1, 0)
  val next_addr = (addr_block + 1.U) << blockOffset.U

  val s_idle :: s_acq :: s_gnt :: s_check :: s_resp :: Nil = Enum(5)
  val state = RegInit(s_idle)

  val (tl_out, edgesOut) = outer.atlNode.out(0)
  val gnt = tl_out.d.bits
  val recv_data = Reg(UInt(cacheDataBits.W))
  val recv_beat = RegInit(0.U(log2Up(cacheDataBeats+1).W))

  val data_bytes = VecInit(Seq.tabulate(cacheDataBits/8) { i => recv_data(8 * (i + 1) - 1, 8 * i) })
  val zero_match = data_bytes.map(_ === 0.U)
  val needle_match = data_bytes.map(_ === needle)
  val first_zero = PriorityEncoder(zero_match)

  val chars_found = PopCount(needle_match.zipWithIndex.map {
    case (matches, i) =>
      val idx = Cat(recv_beat - 1.U, i.U(beatOffset.W))
      matches && idx >= offset && i.U <= first_zero
  })
  val zero_found = zero_match.reduce(_ || _)
  val finished = Reg(Bool())

  io.cmd.ready := (state === s_idle)
  io.resp.valid := (state === s_resp)
  io.resp.bits.rd := resp_rd
  io.resp.bits.data := count
  tl_out.a.valid := (state === s_acq)
  tl_out.a.bits := edgesOut.Get(
                       fromSource = 0.U,
                       toAddress = addr_block << blockOffset,
                       lgSize = lgCacheBlockBytes.U)._2
  tl_out.d.ready := (state === s_gnt)

  when (io.cmd.fire) {
    addr := io.cmd.bits.rs1
    needle := io.cmd.bits.rs2
    resp_rd := io.cmd.bits.inst.rd
    count := 0.U
    finished := false.B
    state := s_acq
  }

  when (tl_out.a.fire) { state := s_gnt }

  when (tl_out.d.fire) {
    recv_beat := recv_beat + 1.U
    recv_data := gnt.data
    state := s_check
  }

  when (state === s_check) {
    when (!finished) {
      count := count + chars_found
    }
    when (zero_found) { finished := true.B }
    when (recv_beat === cacheDataBeats.U) {
      addr := next_addr
      state := Mux(zero_found || finished, s_resp, s_acq)
      recv_beat := 0.U
    } .otherwise {
      state := s_gnt
    }
  }

  when (io.resp.fire) { state := s_idle }

  io.busy := (state =/= s_idle)
  io.interrupt := false.B
  io.mem.req.valid := false.B
  // Tie off unused channels
  tl_out.b.ready := true.B
  tl_out.c.valid := false.B
  tl_out.e.valid := false.B
}

class BlackBoxExample(opcodes: OpcodeSet, blackBoxFile: String)(implicit p: Parameters)
    extends LazyRoCC(opcodes) {
  override lazy val module = new BlackBoxExampleModuleImp(this, blackBoxFile)
}

class BlackBoxExampleModuleImp(outer: BlackBoxExample, blackBoxFile: String)(implicit p: Parameters)
    extends LazyRoCCModuleImp(outer)
    with RequireSyncReset
    with HasCoreParameters {

  val blackbox = {
    val roccIo = io
    Module(
      new BlackBox( Map( "xLen" -> IntParam(xLen),
                         "PRV_SZ" -> IntParam(PRV.SZ),
                         "coreMaxAddrBits" -> IntParam(coreMaxAddrBits),
                         "dcacheReqTagBits" -> IntParam(roccIo.mem.req.bits.tag.getWidth),
                         "M_SZ" -> IntParam(M_SZ),
                         "mem_req_bits_size_width" -> IntParam(roccIo.mem.req.bits.size.getWidth),
                         "coreDataBits" -> IntParam(coreDataBits),
                         "coreDataBytes" -> IntParam(coreDataBytes),
                         "paddrBits" -> IntParam(paddrBits),
                         "vaddrBitsExtended" -> IntParam(vaddrBitsExtended),
                         "FPConstants_RM_SZ" -> IntParam(FPConstants.RM_SZ),
                         "fLen" -> IntParam(fLen),
                         "FPConstants_FLAGS_SZ" -> IntParam(FPConstants.FLAGS_SZ)
                   ) ) with HasBlackBoxResource {
        val io = IO( new Bundle {
                      val clock = Input(Clock())
                      val reset = Input(Reset())
                      val rocc = chiselTypeOf(roccIo)
                    })
        override def desiredName: String = blackBoxFile
        addResource(s"/vsrc/$blackBoxFile.v")
      }
    )
  }

  blackbox.io.clock := clock
  blackbox.io.reset := reset
  blackbox.io.rocc.cmd <> io.cmd
  io.resp <> blackbox.io.rocc.resp
  io.mem <> blackbox.io.rocc.mem
  io.busy := blackbox.io.rocc.busy
  io.interrupt := blackbox.io.rocc.interrupt
  blackbox.io.rocc.exception := io.exception
  io.ptw <> blackbox.io.rocc.ptw
  io.fpu_req <> blackbox.io.rocc.fpu_req
  blackbox.io.rocc.fpu_resp <> io.fpu_resp

}

class OpcodeSet(val opcodes: Seq[UInt]) {
  def |(set: OpcodeSet) =
    new OpcodeSet(this.opcodes ++ set.opcodes)

  def matches(oc: UInt) = opcodes.map(_ === oc).reduce(_ || _)
}

object OpcodeSet {
  def custom0 = new OpcodeSet(Seq("b0001011".U))
  def custom1 = new OpcodeSet(Seq("b0101011".U))
  def custom2 = new OpcodeSet(Seq("b1011011".U))
  def custom3 = new OpcodeSet(Seq("b1111011".U))
  def all = custom0 | custom1 | custom2 | custom3
}

/**
  * IPOAT（王志瑞）：LoopConv request-level 有序命令路径。
  *
  * LoopConv 的软件 ABI 仍是 CONFIG1..CONFIG6、RUN 七条 RoCC command。前六条只写入
  * staging，RUN 是唯一的提交点；提交后 Queue 的一个元素就是一个完整 request，而不是
  * 7 条可以在 Queue16 边界处分裂的 command。普通 command 与 request 共用同一个有序
  * stream，因此不能越过尚未提交或尚未下发的 LoopConv request。
  */
class RegisteredIngressAtomicReserve(fifoDepth: Int = 16)(implicit p: Parameters)
    extends CoreModule()(p) {
  val io = IO(new Bundle {
    val in = Flipped(Decoupled(new RoCCCommand))
    val out = Decoupled(new RoCCCommand)
    val busy = Output(Bool())
    // IPOAT（王志瑞）-O：这三个信号仅用于 software credit 的状态观测；它们不反馈到
    // ingress ready，因此不会把 Gemmini 的完成路径组合地接回 Rocket 前端。
    val request_accept = Output(Bool())
    val request_queue_count = Output(UInt(8.W))
    val assembler_partial = Output(Bool())
    val replay_release = Output(Bool())
  })

  require(fifoDepth >= 7,
    "LoopConv request FIFO requires capacity for one seven-command request")

  // IPOAT（王志瑞）-I：LoopConv 的软件 ABI 固定为 CONFIG1..CONFIG6、RUN 七条 funct。
  // 不依赖 Gemmini Scala 包，避免 rocket-chip 与 Gemmini generator 形成反向依赖。
  val loopConvConfig1 = 16.U(7.W)
  val loopConvConfig2 = 17.U(7.W)
  val loopConvConfig3 = 18.U(7.W)
  val loopConvConfig4 = 19.U(7.W)
  val loopConvConfig5 = 20.U(7.W)
  val loopConvConfig6 = 21.U(7.W)
  val loopConvRun = 15.U(7.W)
  val loopConvIdle = 127.U(7.W)

  def isLoopConvFunct(funct: UInt): Bool = {
    Seq(loopConvConfig1, loopConvConfig2, loopConvConfig3,
      loopConvConfig4, loopConvConfig5, loopConvConfig6, loopConvRun)
      .map(_ === funct).reduce(_ || _)
  }

  def nextAcceptFunct(funct: UInt): UInt = {
    MuxLookup(funct, loopConvIdle)(Seq(
      loopConvConfig1 -> loopConvConfig2,
      loopConvConfig2 -> loopConvConfig3,
      loopConvConfig3 -> loopConvConfig4,
      loopConvConfig4 -> loopConvConfig5,
      loopConvConfig5 -> loopConvConfig6,
      loopConvConfig6 -> loopConvRun,
      loopConvRun -> loopConvIdle))
  }

  // IPOAT（王志瑞）-I：每个 stream item 不是一条 RoCC command，而是普通 command 或完整的
  // 七条 LoopConv command。以 2 个完整 request 对应原 Queue16 的 14 条已提交 command；
  // 另有一个六条 staging request，因此不会在物理 FIFO 边界留下半个已提交 request。
  class StreamItem extends Bundle {
    val isLoopConv = Bool()
    val command = new RoCCCommand
    val loopConvPacket = Vec(7, new RoCCCommand)
  }
  val requestDepth = math.max(2, fifoDepth / 7)
  val stream = Module(new Queue(new StreamItem, entries = requestDepth,
    useSyncReadMem = true))

  // IPOAT（王志瑞）-P：staging 只在 CONFIG1 到 RUN 之间有效。CONFIG1..6 不会发送到
  // Gemmini；只有 RUN 使整个 packet 原子地进入有序 stream。
  val packetActive = RegInit(false.B)
  val acceptExpectedFunct = RegInit(loopConvConfig1)
  val stagingCommands = Reg(Vec(6, new RoCCCommand))
  val inputFunct = io.in.bits.inst.funct.asUInt
  val inputIsPacket = isLoopConvFunct(inputFunct)
  val inputIsNormal = !inputIsPacket
  val inputIsConfig = inputFunct >= loopConvConfig1 && inputFunct <= loopConvConfig6
  val inputIsRun = inputFunct === loopConvRun

  val protocolAllowed =
    (!packetActive && inputIsNormal) ||
      (!packetActive && inputFunct === loopConvConfig1) ||
      (packetActive && inputFunct === acceptExpectedFunct)
  val inputNeedsStreamEntry = inputIsNormal || inputIsRun
  val normalInputReady = protocolAllowed && (!inputNeedsStreamEntry || stream.io.enq.ready)
  io.in.ready := normalInputReady

  // Preserve the blocked command across Rocket replay gaps, when valid and
  // bits are no longer available. Release rocc_blocked as soon as the original
  // command can be accepted; the replay still uses the normal enqueue path.
  val ingressCommandBlocked = RegInit(false.B)
  val blockedIngressFunct = RegInit(0.U(7.W))
  when (io.in.valid && !normalInputReady) {
    ingressCommandBlocked := true.B
    blockedIngressFunct := inputFunct
  }.elsewhen (io.in.fire) {
    ingressCommandBlocked := false.B
  }
  val blockedIsPacket = isLoopConvFunct(blockedIngressFunct)
  val blockedIsNormal = !blockedIsPacket
  val blockedIsRun = blockedIngressFunct === loopConvRun
  val blockedProtocolAllowed =
    (!packetActive && blockedIsNormal) ||
      (!packetActive && blockedIngressFunct === loopConvConfig1) ||
      (packetActive && blockedIngressFunct === acceptExpectedFunct)
  val blockedNeedsStreamEntry = blockedIsNormal || blockedIsRun
  val blockedCommandReady = blockedProtocolAllowed &&
    (!blockedNeedsStreamEntry || stream.io.enq.ready)
  io.replay_release := ingressCommandBlocked && blockedCommandReady
  val inputFire = io.in.fire

  val packetToCommit = Wire(Vec(7, new RoCCCommand))
  packetToCommit.take(6).zipWithIndex.foreach { case (command, index) =>
    command := stagingCommands(index)
  }
  packetToCommit(6) := io.in.bits

  stream.io.enq.valid := io.in.valid && protocolAllowed && inputNeedsStreamEntry
  stream.io.enq.bits.isLoopConv := inputIsRun
  stream.io.enq.bits.command := io.in.bits
  stream.io.enq.bits.loopConvPacket := packetToCommit

  // IPOAT（王志瑞）-O：只有 RUN 与完整 packet 的 enqueue 握手才算一个 request 已接受。
  // CONFIG1..6 仅更新 staging，不能提前消耗 software credit。
  io.request_accept := stream.io.enq.fire && inputIsRun
  io.request_queue_count := stream.io.count
  io.assembler_partial := packetActive

  // IPOAT（王志瑞）-P：流头是完整 request 时，将其七条 command 连续串行化。下游可在
  // 任一 command 处反压，但 packet 仍保留在 stream 头部，绝不会退化为 Queue16 的半包状态。
  val packetCommandIndex = RegInit(0.U(3.W))
  val streamHead = stream.io.deq.bits
  val headPacketLast = streamHead.isLoopConv && packetCommandIndex === 6.U
  io.out.valid := stream.io.deq.valid
  io.out.bits := Mux(streamHead.isLoopConv,
    streamHead.loopConvPacket(packetCommandIndex), streamHead.command)
  stream.io.deq.ready := io.out.ready && (!streamHead.isLoopConv || headPacketLast)

  when (io.out.fire && streamHead.isLoopConv) {
    packetCommandIndex := Mux(headPacketLast, 0.U, packetCommandIndex + 1.U)
  }

  when (inputFire && inputIsConfig) {
    switch (inputFunct) {
      is (loopConvConfig1) { stagingCommands(0) := io.in.bits }
      is (loopConvConfig2) { stagingCommands(1) := io.in.bits }
      is (loopConvConfig3) { stagingCommands(2) := io.in.bits }
      is (loopConvConfig4) { stagingCommands(3) := io.in.bits }
      is (loopConvConfig5) { stagingCommands(4) := io.in.bits }
      is (loopConvConfig6) { stagingCommands(5) := io.in.bits }
    }
  }
  when (inputFire && inputIsPacket) {
    packetActive := !inputIsRun
    acceptExpectedFunct := nextAcceptFunct(inputFunct)
  }

  // IPOAT（王志瑞）-O：busy 覆盖已提交 stream、正在输出的 packet 和尚未 RUN 提交的 staging；
  // Rocket 前端不会把正在组装的 request 误判为空闲。
  io.busy := stream.io.deq.valid || packetActive

  // IPOAT（王志瑞）-A：普通 command 不能穿越 staging packet，LoopConv 的输入 ABI 只能按
  // CONFIG1..CONFIG6、RUN 前进；这些断言不参与功能 ready 路径。
  when (inputFire && inputIsPacket) {
    assert((!packetActive && inputFunct === loopConvConfig1) ||
      (packetActive && inputFunct === acceptExpectedFunct),
      "LoopConv request assembler command order violation")
  }
  when (inputFire && inputIsNormal) {
    assert(!packetActive,
      "A normal RoCC command bypassed an incomplete LoopConv request")
  }
  when (io.out.fire && streamHead.isLoopConv) {
    assert(packetCommandIndex <= 6.U,
      "LoopConv request serializer command index exceeded packet size")
  }
}

class RoccCommandRouter(opcodes: Seq[OpcodeSet], fifoDepth: Int = 16)(implicit p: Parameters)
    extends CoreModule()(p) {
  val io = IO(new Bundle {
    val in = Flipped(Decoupled(new RoCCCommand))
    val out = Vec(opcodes.size, Decoupled(new RoCCCommand))
    val busy = Output(Bool())
    // IPOAT（王志瑞）-O：按 opcode 保持独立的 ingress request 观测，供各 RoCC worker
    // 自己维护 credit；不跨 worker 聚合，避免 custom2/custom3 相互干扰。
    val loopconv_request_accept = Output(Vec(opcodes.size, Bool()))
    val loopconv_request_queue_count = Output(Vec(opcodes.size, UInt(8.W)))
    val loopconv_assembler_partial = Output(Vec(opcodes.size, Bool()))
  })

  require(fifoDepth > 0)
  // IPOAT（王志瑞）-I：每个 opcode 独立拥有 registered ingress + atomic reserve + Queue16，
  // custom2/custom3 的 backpressure 和 shadow state 互不共享。
  val paths = opcodes.map(_ => Module(new RegisteredIngressAtomicReserve(fifoDepth)))
  val matches = opcodes.map(_.matches(io.in.bits.inst.opcode))

  paths.zipWithIndex.foreach { case (path, i) =>
    path.io.in.valid := io.in.valid && matches(i)
    path.io.in.bits := io.in.bits
    io.out(i) <> path.io.out
    io.loopconv_request_accept(i) := path.io.request_accept
    io.loopconv_request_queue_count(i) := path.io.request_queue_count
    io.loopconv_assembler_partial(i) := path.io.assembler_partial
  }

  val matched_ready = opcodes.indices.map(i => matches(i) && paths(i).io.in.ready)
  // Wake Rocket even when replay has withdrawn valid and the opcode bits.
  val replay_release_ready = paths.map(_.io.replay_release)
    .reduceOption(_ || _).getOrElse(false.B)
  io.in.ready := matched_ready.reduceOption(_ || _).getOrElse(false.B) || replay_release_ready
  // IPOAT（王志瑞）-O：保留原有 router busy 语义，并把 ingress 内尚未进入 Queue16 的 command
  // 纳入 busy；输入 valid 仍然直接反映 Rocket 当前是否有待接受 command。
  io.busy := io.in.valid || paths.map(_.io.busy).reduceOption(_ || _).getOrElse(false.B)

  // IPOAT（王志瑞）-A：一个 Rocket command 只能命中一个 accelerator opcode。
  assert(PopCount(VecInit(matches)) <= 1.U,
    "Custom opcode matched for more than one accelerator")
}
