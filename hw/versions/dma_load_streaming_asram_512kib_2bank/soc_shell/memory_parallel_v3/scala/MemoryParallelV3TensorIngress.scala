package tsmcchip.fpga.taihangsoc

import org.chipsalliance.cde.config.Config

/** V3's banked cache and 512-bit memory exit, with a 256-bit coherent writer. */
class TaihangSoC1Rocket1RVV3Gemmini32x32MemoryParallelV3TensorIngressConfig extends Config(
  new WithThreeAutonomousCommandFrontends ++
  new WithTaihangTensorIngress ++
  new TaihangSoC1Rocket1RVV3Gemmini32x32MemoryParallelV3Config)

/** Saved S1 geometry, with the same current Head, Tensor and DDR integration. */
class TaihangSoC1Rocket1RVV3Gemmini32x32MemoryParallelV3TensorIngress2BankConfig extends Config(
  new WithMemoryParallelV3(2) ++
  new TaihangSoC1Rocket1RVV3Gemmini32x32MemoryParallelV3TensorIngressConfig)

/** Private single-bitstream DMA experiment on the original 512KiB geometry. */
class TaihangSoC1Rocket1RVV3Gemmini32x32MemoryParallelV3TensorIngress2BankDmaLoadConfig extends Config(
  new Config((site, here, up) => {
    case gemmini.DmaLoadRuntimeKey => true
    case gemmini.DmaLoadStreamingKey => sys.env.get("DMA_LOAD_STREAMING").contains("1")
    case freechips.rocketchip.tile.commandfrontend.DmaLoadBuildIdKey =>
      BigInt(sys.env.getOrElse("DMA_LOAD_BUILD_ID", throw new IllegalArgumentException("Missing DMA_LOAD_BUILD_ID provenance")), 16)
  }) ++
  new TaihangSoC1Rocket1RVV3Gemmini32x32MemoryParallelV3TensorIngress2BankConfig)
