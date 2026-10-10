package tsmcchip.fpga.taihangsoc

import chisel3._
import chisel3.util._
import org.chipsalliance.cde.config.{Config, Field, Parameters}
import org.chipsalliance.diplomacy.lazymodule.{LazyModule, LazyModuleImp, InModuleBody}
import freechips.rocketchip.amba.axi4._
import freechips.rocketchip.diplomacy.{AddressSet, IdRange}
import freechips.rocketchip.resources.SimpleDevice
import freechips.rocketchip.prci.{ClockSinkNode, ClockSinkParameters}
import freechips.rocketchip.regmapper.{RegField, RegWriteFn}
import freechips.rocketchip.subsystem._
import freechips.rocketchip.tilelink._
import testchipip.util.ClockedIO
import chipyard.iobinders.{GetSystemParameters, OverrideLazyIOBinder, Port}
import chipyard.harness.{HarnessBinder, HasHarnessInstantiators}

/** Slave-facing, write-only AXI. No AR/R pins are exported. */
class TensorWriteIO extends Bundle {
  private val ap = AXI4BundleParameters(addrBits = 33, dataBits = 256, idBits = 5)
  val aw = Flipped(Irrevocable(new AXI4BundleAW(ap)))
  val w = Flipped(Irrevocable(new AXI4BundleW(ap)))
  val b = Irrevocable(new AXI4BundleB(ap))
}

class TensorLineBeat extends Bundle {
  val source = UInt(5.W)
  val address = UInt(33.W)
  val data = UInt(256.W)
  val last = Bool()
}
class TensorLineAck extends Bundle {
  val source = UInt(5.W)
  val denied = Bool()
}

/** The plain ready/valid core is also emitted independently for protocol tests.
  * Records remain allocated until B; TL sources retire independently, only after
  * both A beats and D. This permits early D and arbitrary D ordering safely.
  */
class TaihangTensorIngressCore extends Module {
  val io = IO(new Bundle {
    val axi = new TensorWriteIO
    val a = Decoupled(new TensorLineBeat)
    val d = Flipped(Decoupled(new TensorLineAck))
    val stats = Output(Vec(13, UInt(64.W)))
  })
  val allocated = RegInit(VecInit(Seq.fill(64)(false.B)))
  val filled = RegInit(VecInit(Seq.fill(64)(false.B)))
  val issued = RegInit(VecInit(Seq.fill(64)(false.B)))
  val completed = RegInit(VecInit(Seq.fill(64)(false.B)))
  val addresses = Reg(Vec(64, UInt(33.W)))
  val ids = Reg(Vec(64, UInt(5.W)))
  val lengths = Reg(Vec(64, UInt(8.W)))
  val errors = Reg(Vec(64, UInt(2.W)))
  val data0 = Mem(64, UInt(256.W))
  val data1 = Mem(64, UInt(256.W))
  val allocPtr = RegInit(0.U(6.W))
  val wPtr = RegInit(0.U(6.W))
  val issuePtr = RegInit(0.U(6.W))
  val bPtr = RegInit(0.U(6.W))
  val wBeat = RegInit(0.U(8.W))

  io.axi.aw.ready := !allocated(allocPtr)
  val addressOK = (io.axi.aw.bits.addr >= "hb0000000".U && io.axi.aw.bits.addr < "hb0e10000".U) ||
    (io.axi.aw.bits.addr >= "hb1000000".U && io.axi.aw.bits.addr < "hb1e10000".U)
  val formatOK = io.axi.aw.bits.addr(5, 0) === 0.U && io.axi.aw.bits.len === 1.U &&
    io.axi.aw.bits.size === 5.U && io.axi.aw.bits.burst === 1.U && io.axi.aw.bits.lock === 0.U
  when(io.axi.aw.fire) {
    allocated(allocPtr) := true.B
    filled(allocPtr) := false.B
    issued(allocPtr) := false.B
    completed(allocPtr) := false.B
    addresses(allocPtr) := io.axi.aw.bits.addr
    ids(allocPtr) := io.axi.aw.bits.id
    lengths(allocPtr) := io.axi.aw.bits.len
    errors(allocPtr) := Mux(!addressOK, 3.U, Mux(!formatOK, 2.U, 0.U))
    allocPtr := allocPtr + 1.U
  }
  io.axi.w.ready := allocated(wPtr) && !filled(wPtr)
  val wEnd = wBeat === lengths(wPtr)
  when(io.axi.w.fire) {
    when(wBeat === 0.U) { data0.write(wPtr, io.axi.w.bits.data) }
    when(wBeat === 1.U) { data1.write(wPtr, io.axi.w.bits.data) }
    when((!io.axi.w.bits.strb.andR || io.axi.w.bits.last =/= wEnd) && errors(wPtr) === 0.U) {
      errors(wPtr) := 2.U
    }
    when(wEnd) {
      filled(wPtr) := true.B
      wPtr := wPtr + 1.U
      wBeat := 0.U
    }.otherwise { wBeat := wBeat + 1.U }
  }

  val busy = RegInit(VecInit(Seq.fill(32)(false.B)))
  val acked = RegInit(VecInit(Seq.fill(32)(false.B)))
  val sentLast = RegInit(VecInit(Seq.fill(32)(false.B)))
  val denied = RegInit(VecInit(Seq.fill(32)(false.B)))
  val sourceRecord = Reg(Vec(32, UInt(6.W)))
  val startCycle = Reg(Vec(32, UInt(64.W)))
  val active = RegInit(false.B)
  val activeSource = Reg(UInt(5.W))
  val secondBeat = RegInit(false.B)
  val available = ~busy.asUInt
  val freeSource = PriorityEncoder(available)
  val headReady = allocated(issuePtr) && filled(issuePtr) && !issued(issuePtr)
  val cycle = RegInit(0.U(64.W))
  cycle := cycle + 1.U
  when(!active && headReady) {
    when(errors(issuePtr) =/= 0.U) {
      issued(issuePtr) := true.B
      completed(issuePtr) := true.B
      issuePtr := issuePtr + 1.U
    }.elsewhen(available.orR) {
      issued(issuePtr) := true.B
      busy(freeSource) := true.B
      acked(freeSource) := false.B
      sentLast(freeSource) := false.B
      denied(freeSource) := false.B
      sourceRecord(freeSource) := issuePtr
      activeSource := freeSource
      secondBeat := false.B
      active := true.B
    }
  }
  io.a.valid := active
  io.a.bits.source := activeSource
  io.a.bits.address := addresses(issuePtr)
  io.a.bits.data := Mux(secondBeat, data1.read(issuePtr), data0.read(issuePtr))
  io.a.bits.last := secondBeat
  when(io.a.fire) {
    when(!secondBeat) {
      startCycle(activeSource) := cycle
      secondBeat := true.B
    }.otherwise {
      sentLast(activeSource) := true.B
      active := false.B
      issuePtr := issuePtr + 1.U
    }
  }
  io.d.ready := true.B
  when(io.d.fire) {
    assert(busy(io.d.bits.source) && !acked(io.d.bits.source), "unexpected or duplicate Tensor AccessAck")
    acked(io.d.bits.source) := true.B
    denied(io.d.bits.source) := io.d.bits.denied
  }
  for (s <- 0 until 32) {
    when(busy(s) && acked(s) && sentLast(s)) {
      busy(s) := false.B
      completed(sourceRecord(s)) := true.B
      when(denied(s)) { errors(sourceRecord(s)) := 2.U }
    }
  }
  io.axi.b.valid := allocated(bPtr) && completed(bPtr)
  io.axi.b.bits := 0.U.asTypeOf(io.axi.b.bits)
  io.axi.b.bits.id := ids(bPtr)
  io.axi.b.bits.resp := errors(bPtr)
  when(io.axi.b.fire) {
    allocated(bPtr) := false.B
    bPtr := bPtr + 1.U
  }

  def countWhen(event: Bool, amount: UInt = 1.U): UInt = {
    val value = RegInit(0.U(64.W))
    when(event) { value := value + amount }
    value
  }
  val flight = PopCount(busy)
  val maxFlight = RegInit(0.U(64.W))
  when(flight > maxFlight) { maxFlight := flight }
  // D is allowed in the same cycle as the first A beat.
  val firstAWithD = io.a.fire && !secondBeat && io.a.bits.source === io.d.bits.source
  val latency = Mux(firstAWithD, 0.U, cycle - startCycle(io.d.bits.source))
  val maxLatency = RegInit(0.U(64.W))
  when(io.d.fire && latency > maxLatency) { maxLatency := latency }
  io.stats := VecInit(Seq(
    cycle,
    countWhen(io.axi.w.fire, PopCount(io.axi.w.bits.strb)),
    countWhen(io.axi.b.fire && io.axi.b.bits.resp === 0.U, 64.U),
    countWhen(io.axi.b.fire && io.axi.b.bits.resp =/= 0.U),
    countWhen(io.axi.aw.valid && !io.axi.aw.ready),
    countWhen(io.axi.w.valid && !io.axi.w.ready),
    countWhen(io.a.valid && !io.a.ready),
    countWhen(!active && headReady && errors(issuePtr) === 0.U && !available.orR),
    countWhen(io.axi.b.valid && !io.axi.b.ready),
    flight.pad(64), maxFlight,
    countWhen(io.d.fire, latency), maxLatency))
}

class TaihangTensorIngress(controlBeatBytes: Int)(implicit p: Parameters) extends LazyModule {
  val node = TLClientNode(Seq(TLMasterPortParameters.v1(Seq(TLClientParameters(
    name = "tensor-writer", sourceId = IdRange(0, 32), requestFifo = false)))))
  val control = TLRegisterNode(Seq(AddressSet(BigInt("02012000", 16), 0xfff)),
    new SimpleDevice("tensor-ingress", Seq("taihang,tensor-ingress-1")), beatBytes = controlBeatBytes)
  lazy val module = new TaihangTensorIngressModule(this)
}
class TaihangTensorIngressModule(outer: TaihangTensorIngress) extends LazyModuleImp(outer) {
    val io = IO(new TensorWriteIO)
    val core = Module(new TaihangTensorIngressCore)
    core.io.axi <> io
    val (tl, edge) = outer.node.out.head
    require(edge.bundle.dataBits == 256, "Tensor ingress requires a 256-bit SBUS")
    tl.a.valid := core.io.a.valid
    tl.a.bits := edge.Put(core.io.a.bits.source, core.io.a.bits.address, 6.U, core.io.a.bits.data)._2
    core.io.a.ready := tl.a.ready
    core.io.d.valid := tl.d.valid
    core.io.d.bits.source := tl.d.bits.source
    core.io.d.bits.denied := tl.d.bits.denied
    tl.d.ready := core.io.d.ready
    tl.b.ready := true.B
    tl.c.valid := false.B
    tl.c.bits := 0.U.asTypeOf(tl.c.bits)
    tl.e.valid := false.B
    tl.e.bits := 0.U.asTypeOf(tl.e.bits)
    when(tl.d.fire) { assert(tl.d.bits.opcode === TLMessages.AccessAck) }
    val snapshot = RegInit(VecInit(Seq.fill(13)(0.U(64.W))))
    val snapshotCommand = RegWriteFn((valid: Bool, data: UInt) => {
      when(valid && data(0)) { snapshot := core.io.stats }
      true.B
    })
    outer.control.regmap((Seq(
      0x00 -> Seq(RegField.w(32, snapshotCommand)),
      0x08 -> Seq(RegField.r(64, "h54454e5300000001".U(64.W)))) ++
      (0 until 13).map(i => (0x20 + 8*i) -> Seq(RegField.r(64, snapshot(i))))): _*)
}

case object TaihangTensorIngressKey extends Field[Boolean](false)
trait CanHaveTaihangTensorIngress { this: BaseSubsystem =>
  val tensorIngress = if (p(TaihangTensorIngressKey)) {
    val sbus = locateTLBusWrapper(SBUS)
    val cbus = locateTLBusWrapper(CBUS)
    val domain = sbus.generateSynchronousDomain("tensor_ingress")
    val writer = domain { LazyModule(new TaihangTensorIngress(cbus.beatBytes)) }
    sbus.coupleFrom("tensor_writer") { _ := TLBuffer() := writer.node }
    // Taihang uses a uniform synchronous 100MHz bus clock configuration.
    cbus.coupleTo("tensor_ingress_control") { writer.control := TLFragmenter(cbus.beatBytes, cbus.blockBytes) := _ }
    val domainPort = domain { InModuleBody {
      val port = IO(new TensorWriteIO).suggestName("tensor_axi")
      port <> writer.module.io
      port
    } }
    Some((domainPort, sbus))
  } else None
  val tensorWriteIO = tensorIngress.map { case (domainPort, _) => InModuleBody {
    val port = IO(new TensorWriteIO).suggestName("tensor_axi")
    port <> domainPort
    port
  } }
}
class TaihangTensorDigitalTop(implicit p: Parameters) extends chipyard.DigitalTop with CanHaveTaihangTensorIngress
case class TensorAXI4InPort(getIO: () => ClockedIO[TensorWriteIO]) extends Port[ClockedIO[TensorWriteIO]]
class WithTaihangTensorIO extends OverrideLazyIOBinder({ (system: CanHaveTaihangTensorIngress) =>
  implicit val p: Parameters = GetSystemParameters(system)
  val clockSink = system.tensorIngress.map { case (_, bus) =>
    val sink = ClockSinkNode(Seq(ClockSinkParameters()))
    sink := bus.fixedClockNode
    sink
  }
  InModuleBody {
    val ports = system.tensorWriteIO.toSeq.map { internal =>
      val port = IO(new ClockedIO(new TensorWriteIO)).suggestName("axi4_tensor")
      port.bits <> internal
      port.clock := clockSink.get.in.head._1.clock
      TensorAXI4InPort(() => port)
    }
    (ports, Nil)
  }
})
class WithTaihangTensorPassthrough extends HarnessBinder({
  case (_: HasHarnessInstantiators, port: TensorAXI4InPort, _: Int) =>
    val tensor = IO(chiselTypeOf(port.io.bits)).suggestName("axi4_tensor")
    tensor <> port.io.bits
})
class WithTaihangTensorIngress extends Config(
  new WithTaihangTensorPassthrough ++ new WithTaihangTensorIO ++ new Config((site, here, up) => {
    case TaihangTensorIngressKey => true
    case chipyard.BuildSystem => (p: Parameters) => new TaihangTensorDigitalTop()(p)
  }))
class TaihangSoC1Rocket1RVV2Gemmini16x16PackedFullOps256BitTensorIngressConfig extends Config(
  new WithTaihangTensorIngress ++ new TaihangSoC1Rocket1RVV2Gemmini16x16PackedFullOps256BitConfig)
class TaihangSoC1Rocket1RVV1Gemmini4x4PackedFullOps256BitTensorIngressConfig extends Config(
  new WithTaihangTensorIngress ++ new TaihangSoC1Rocket1RVV1Gemmini4x4PackedFullOps256BitConfig)

object EmitTaihangTensorIngressCore extends App {
  _root_.circt.stage.ChiselStage.emitSystemVerilogFile(new TaihangTensorIngressCore, args,
    Array("--disable-all-randomization", "--strip-debug-info"))
}
