package tsmcchip.fpga.taihangsoc

import org.chipsalliance.cde.config.Config
import chipyard.config.MultiRoCCKey

/** IPOAT：单核、双核 Gemmini64 bypass 使用各 bank 独立的 accumulator 加法器。
  * I（Input 输入）：dual64 worker 参数与 count（1 或 2）。
  * P（Process 处理）：仅覆盖 acc_use_shared_adder=false，消除共享加法器的跨 bank 高扇出选择路径。
  * O（Output 输出）：保持 acc_latency、容量及软件接口不变的 bypass 配置；其他配置仍使用默认共享模式。
  * A（Author 作者）：Codex
  * T（Time 时间）：2026-09-27
  */
class WithTaihangBypassGemmini64Count(count: Int) extends Config((site, here, up) => {
  case MultiRoCCKey =>
    require(count == 1 || count == 2)
    val workers = Seq(
      TaihangSoC64DualGemminiConfigs.builder(TaihangSoC64DualGemminiConfigs.gemmini0Config.copy(acc_use_shared_adder = false)),
      TaihangSoC64DualGemminiConfigs.builder(TaihangSoC64DualGemminiConfigs.gemmini1Config.copy(acc_use_shared_adder = false)))
    up(MultiRoCCKey) ++ Map(0 -> workers.take(count))
})

/** Ordinary SBUS/MBUS; external AXI slave ingress disabled.
  * CPU uncached alias and outward MMIO remain available.
  */
class WithTaihangGemmini64BypassBase(count: Int) extends Config(
  new WithTaihangBypassGemmini64Count(count) ++
  new WithTaihangRoCCMbusBypass(Map(0 -> (0 until count).toSet)) ++
  new freechips.rocketchip.subsystem.WithNoSlavePort ++
  new freechips.rocketchip.subsystem.WithExtMemSbusBypass ++
  new freechips.rocketchip.subsystem.WithInclusiveCache(nWays = 4, capacityKB = 128) ++
  new freechips.rocketchip.subsystem.WithNBanks(1) ++
  new TaihangSoC1Rocket1RVV2Gemmini64x64PackedFullOps256BitConfig)

class TaihangSoC1Rocket1RVV1Gemmini64x64MbusBypass128KiBL2NoFbusConfig
    extends Config(new WithTaihangGemmini64BypassBase(1))

class TaihangSoC1Rocket1RVV2Gemmini64x64MbusBypass128KiBL2NoFbusConfig
    extends Config(new WithTaihangGemmini64BypassBase(2))
