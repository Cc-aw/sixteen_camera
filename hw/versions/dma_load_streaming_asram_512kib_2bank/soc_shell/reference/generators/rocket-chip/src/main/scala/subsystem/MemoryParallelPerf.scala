package freechips.rocketchip.subsystem

import chisel3._
import chisel3.util._
import org.chipsalliance.cde.config._
import org.chipsalliance.diplomacy.bundlebridge._
import org.chipsalliance.diplomacy.lazymodule._
import freechips.rocketchip.diplomacy.{AddressSet, SimpleDevice}
import freechips.rocketchip.regmapper._
import freechips.rocketchip.tilelink._
import freechips.rocketchip.util.Location

case object MemoryParallelPerfKey extends Field[Boolean](false)
case object MemoryParallelPerfLocation extends Location[BundleBridgeSource[MemoryParallelPerfExternal]]("memory_parallel_perf")

// Dedicated registered-control/frozen-data sideband; no functional bus signals
// are driven through this interface. All external-facing signals use 100 MHz.
class MemoryParallelPerfExternal extends Bundle {
  val command = Output(UInt(3.W))
  val request = Output(Bool())
  val acknowledge = Input(Bool())
  val index = Output(UInt(9.W))
  val data = Input(UInt(64.W))
  val available = Input(Bool())
}

class MemoryParallelCounterBank(peakMask: BigInt = 0) extends Module {
  val io = IO(new Bundle {
    val command = Flipped(Valid(UInt(3.W)))
    val events = Input(Vec(32, UInt(16.W)))
    val index = Input(UInt(5.W))
    val data = Output(UInt(64.W))
  })
  // Register observations and controls together. This removes the counters
  // from the cache's control paths without moving the measurement boundary.
  val events = RegNext(io.events, 0.U.asTypeOf(io.events))
  val cmd = RegNext(io.command, 0.U.asTypeOf(io.command))
  val enabled = RegInit(false.B)
  val live = RegInit(VecInit(Seq.fill(32)(0.U(64.W))))
  val frozen = RegInit(VecInit(Seq.fill(32)(0.U(64.W))))
  when(cmd.valid && cmd.bits === 1.U) { enabled := true.B }
  when(cmd.valid && (cmd.bits === 2.U || cmd.bits === 3.U)) { enabled := false.B }
  for (i <- 0 until 32) {
    when(enabled) {
      if (peakMask.testBit(i)) {
        when(events(i) > live(i)) { live(i) := events(i) }
      } else { live(i) := live(i) + events(i) }
    }
    when(cmd.valid && cmd.bits === 4.U) { frozen(i) := live(i) }
    when(cmd.valid && cmd.bits === 3.U) { live(i) := 0.U; frozen(i) := 0.U }
  }
  val timestamp = RegInit(0.U(64.W))
  timestamp := timestamp + 1.U
  when(cmd.valid && cmd.bits === 4.U) { frozen(31) := timestamp }
  io.data := frozen(io.index)
}

class MemoryParallelPerf(beatBytes: Int)(implicit p: Parameters) extends LazyModule {
  val device = new SimpleDevice("memory-performance", Seq("taihang,memory-performance-v3"))
  val node = TLRegisterNode(Seq(AddressSet(BigInt("02020000", 16), 0xffff)), device,
    beatBytes = beatBytes, concurrency = 1)
  val external = BundleBridgeSource(() => new MemoryParallelPerfExternal)
  lazy val module = new Impl
  class Impl extends LazyModuleImp(this) {
    val io = IO(new Bundle { val events = Input(Vec(7, Vec(32, UInt(16.W)))) })
    val ext = external.bundle
    val command = RegInit(0.U(3.W))
    val request = RegInit(false.B)
    val busy = RegInit(false.B)
    val enabled = RegInit(false.B)
    val valid = RegInit(false.B)
    val sequence = RegInit(0.U(32.W))
    val selected = RegInit(0.U(9.W))
    val pulse = WireInit(false.B)
    val commandData = WireInit(0.U(3.W))
    val invalidCommand = RegInit(false.B)
    val localCmd = Wire(Valid(UInt(3.W)))
    localCmd.valid := pulse || !ext.available
    localCmd.bits := Mux(ext.available, commandData, 3.U)
    ext.command := command
    ext.request := request
    ext.index := selected
    when(busy && ext.acknowledge === request) {
      busy := false.B
      when(command === 4.U) { valid := true.B; sequence := sequence + 1.U }
    }
    when(!ext.available) {
      busy := false.B; valid := false.B; enabled := false.B; request := false.B
    }
    val banks = (0 until 7).map { i =>
      val b = Module(new MemoryParallelCounterBank(if(i >= 5) BigInt(1) << 11 else BigInt(0)))
      b.io.command := localCmd
      b.io.events := io.events(i)
      b.io.index := selected(4,0)
      b
    }
    val localData = VecInit(banks.map(_.io.data))
    val readData = Mux(selected(8,5) < 7.U, localData(selected(7,5)), ext.data)
    val status = Cat(0.U(59.W), invalidCommand, ext.available, valid, enabled, busy)
    val control = RegField.w(32, RegWriteFn((write: Bool, data: UInt) => {
      val ready = !busy && ext.available
      when(write && ready) {
        when(data >= 1.U && data <= 4.U) {
          pulse := true.B; commandData := data(2,0)
          command := data(2,0); request := !request; busy := true.B
          invalidCommand := false.B
          when(data === 1.U) { enabled := true.B }
          when(data === 2.U || data === 3.U) { enabled := false.B }
          when(data === 3.U || data === 4.U) { valid := false.B }
        }.otherwise { invalidCommand := true.B }
      }
      ready
    }))
    val indexField = RegField(32, RegReadFn(selected.pad(32)), RegWriteFn((write: Bool, data: UInt) => {
      when(write) { selected := data(8,0) }
      true.B
    }))
    val frozenData = Mux(valid && !busy, readData, 0.U(64.W))
    node.regmap(
      0x00 -> Seq(RegField.r(64, "h4d50563300010000".U(64.W))), // MPV3, ABI 1.0
      0x08 -> Seq(control),
      0x10 -> Seq(RegField.r(64, status)),
      0x18 -> Seq(RegField.r(64, sequence.pad(64))),
      0x20 -> Seq(indexField),
      0x28 -> Seq(RegField.r(64, frozenData)),
      0x30 -> Seq(RegField.r(64, 0x1000.U(64.W))),
      0x38 -> Seq(RegField.r(64, 524288.U(64.W))),
      0x40 -> Seq(RegField.r(64, 100000000.U(64.W))),
      0x48 -> Seq(RegField.r(64, 300000000.U(64.W))),
      0x50 -> Seq(RegField.r(64, 13.U(64.W))),
      0x58 -> Seq(RegField.r(64, 2.U(64.W))),
      0x60 -> Seq(RegField.r(64, 512.U(64.W))),
      0x68 -> Seq(RegField.r(64, 32.U(64.W)))
    )
  }
}
