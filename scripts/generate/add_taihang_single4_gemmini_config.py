#!/usr/bin/env python3
"""Add a single packed 4x4 Gemmini variant of the production Taihang SoC."""

from pathlib import Path
import argparse


CONFIG_NAME = "TaihangSoC1Rocket1RVV1Gemmini4x4PackedFullOps256BitConfig"
ROOT = Path("/home/wzr/chipyard")


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("--chipyard-root", type=Path, default=ROOT)
    args = parser.parse_args()
    path = args.chipyard_root / "fpga/src/main/scala/taihang_soc/Configs.scala"
    source = path.read_text()
    if f"class {CONFIG_NAME} extends Config(" in source:
        print(f"CONFIG_ALREADY_PRESENT={CONFIG_NAME}")
        return

    marker = "/** IPOAT：双 4x4 LoopConv 死锁诊断 Gemmini 参数"
    assert source.count(marker) == 1
    source = source.replace(marker, '''/** One packed 4x4 worker retaining the production worker0 opcode and CSR ABI. */
object TaihangSoCOne4x4GemminiConfig {
  val config = TaihangSoC16GemminiConfigs.gemmini0Config.copy(
    tileRows = 1,
    tileColumns = 2,
    meshRows = 4,
    meshColumns = 2,
    acc_scale_args = gemmini.GemminiConfigs.defaultConfig.acc_scale_args.map(
      _.copy(num_scale_units = 4)),
    headerFileName = "gemmini_params_taihang_single_4x4_packed.h",
  )
}

''' + marker)

    marker = "/** IPOAT：单 hart 双 4x4 诊断挂接"
    assert source.count(marker) == 1
    source = source.replace(marker, '''/** Attach the production-compatible worker0 alone to hart 0. */
class WithTaihangSoCOne4x4GemminiSingleHart extends Config((site, here, up) => {
  case MultiRoCCKey => up(MultiRoCCKey) ++ Map(
    0 -> Seq(TaihangSoC16GemminiConfigs.builder(TaihangSoCOne4x4GemminiConfig.config)),
  )
})

''' + marker)

    marker = "/** IPOAT：双 4x4 LoopConv 死锁诊断 SoC"
    assert source.count(marker) == 1
    source = source.replace(marker, f'''/** Production Taihang interfaces with one packed logical 4x4 Gemmini. */
class {CONFIG_NAME} extends Config(
  new WithTaihangPostprocessFrontBus ++
  new WithNoDebugClockGate ++
  new WithTaihangAXI4InPassthrough ++
  new WithTaihangSoCNoSPITweaks(freqMHz = 100.0, memDataBits = 256) ++
  new freechips.rocketchip.subsystem.WithCustomSlavePort(
    data_width = 256,
    id_bits = 5,
    source_bits = 7,
    fifo_bits = 5,
  ) ++
  new freechips.rocketchip.subsystem.WithCustomMMIOPort(
    base_addr = BigInt("10040000", 16),
    base_size = BigInt("200000", 16),
    data_width = 64,
    id_bits = 4,
    maxXferBytes = 64,
  ) ++
  new chipyard.config.WithMultiRoCC ++
  new WithTaihangSoCOne4x4GemminiSingleHart ++
  new saturn.rocket.WithRocketVectorUnit(
    vLen = 256,
    dLen = 128,
    params = VectorParams.dspParams,
    cores = Some(Seq(0)),
    useL1DCache = true,
  ) ++
  new freechips.rocketchip.rocket.WithNHugeCores(1) ++
  new chipyard.config.WithSystemBusWidth(256) ++
  new chipyard.config.AbstractConfig)

''' + marker)
    path.write_text(source)
    print(f"CONFIG_ADDED={CONFIG_NAME}")
    print(f"FILE={path}")


if __name__ == "__main__":
    main()
