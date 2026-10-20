package tsmcchip.fpga.taihangsoc

import chisel3._
import sifive.blocks.inclusivecache.InclusiveCachePortParameters
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
class WithMemoryParallelV3(nBanks: Int = 4) extends Config((site, here, up) => {
  case SubsystemBankedCoherenceKey =>
    require(nBanks == 2 || nBanks == 4, "V3 supports the saved two-bank and four-bank profiles")
    up(SubsystemBankedCoherenceKey, site).copy(nBanks = nBanks,
      bankMask = Some(BigInt(nBanks - 1) << 12))
  // Register all five channels at each bank boundary. The two-entry,
  // non-flow/non-pipe queues break BOTH data and ready combinational chains
  // while sustaining one beat per cycle once the pipeline is populated.
  // Keep S1's per-bank capacity and exterior buffers. Four identical 256 KiB
  // banks provide 1 MiB; the two-bank fallback provides the saved 512 KiB.
  case InclusiveCacheKey => up(InclusiveCacheKey, site).copy(
    sets = 512, ways = 8, memCycles = 64,
    bufInnerInterior = InclusiveCachePortParameters.full)
  case MemoryBusKey => up(MemoryBusKey, site).copy(beatBytes = 64)
  case ExtMem => up(ExtMem, site).map(x => x.copy(master = x.master.copy(beatBytes = 64, idBits = 2)))
  case MemoryParallelPerfKey => true
})
class TaihangSoC1Rocket1RVV3Gemmini32x32MemoryParallelV3Config extends Config(
  new WithMemoryPerfIO ++ new WithMemoryPerfHarness ++ new WithMemoryParallelV3 ++
  new TaihangSoC1Rocket1RVV3Gemmini32x32PackedInference100MHzConfig)
