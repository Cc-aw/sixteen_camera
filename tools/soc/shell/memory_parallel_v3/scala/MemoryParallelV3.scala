package tsmcchip.fpga.taihangsoc

import chisel3._
import org.chipsalliance.cde.config.{Config, Parameters}
import org.chipsalliance.diplomacy.bundlebridge._
import org.chipsalliance.diplomacy.lazymodule.InModuleBody
import freechips.rocketchip.subsystem._
import chipyard.iobinders.{GetSystemParameters, OverrideLazyIOBinder, Port}
import chipyard.harness.{HarnessBinder, HasHarnessInstantiators}

case class MemoryPerfPort(getIO: () => MemoryParallelPerfExternal) extends Port[MemoryParallelPerfExternal]
class WithMemoryPerfIO extends OverrideLazyIOBinder({ (system: BaseSubsystem) => {
  implicit val p: Parameters = GetSystemParameters(system)
  val source = system.anyLocationMap.required[BundleBridgeSource[MemoryParallelPerfExternal]](MemoryParallelPerfLocation)
  val sink = BundleBridgeSink[MemoryParallelPerfExternal]()
  sink := source
  InModuleBody {
    val port = IO(new MemoryParallelPerfExternal).suggestName("memory_perf")
    port <> sink.bundle
    (Seq(MemoryPerfPort(() => port)), Nil)
  }
}})
class WithMemoryPerfHarness extends HarnessBinder({
  case (_: HasHarnessInstantiators, port: MemoryPerfPort, _: Int) =>
    val perf = IO(chiselTypeOf(port.io)).suggestName("memory_perf")
    perf <> port.io
})
class WithMemoryParallelV3 extends Config((site, here, up) => {
  case SubsystemBankedCoherenceKey => up(SubsystemBankedCoherenceKey, site).copy(nBanks = 2, bankMask = Some(BigInt(0x1000)))
  case InclusiveCacheKey => up(InclusiveCacheKey, site).copy(sets = 512, ways = 8, memCycles = 64)
  case MemoryBusKey => up(MemoryBusKey, site).copy(beatBytes = 64)
  case ExtMem => up(ExtMem, site).map(x => x.copy(master = x.master.copy(beatBytes = 64, idBits = 2)))
  case MemoryParallelPerfKey => true
})
class TaihangSoC1Rocket1RVV3Gemmini32x32MemoryParallelV3Config extends Config(
  new WithMemoryPerfIO ++ new WithMemoryPerfHarness ++ new WithMemoryParallelV3 ++
  new TaihangSoC1Rocket1RVV3Gemmini32x32PackedInference100MHzConfig)
