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
