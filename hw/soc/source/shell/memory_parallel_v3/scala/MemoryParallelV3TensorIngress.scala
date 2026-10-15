package tsmcchip.fpga.taihangsoc

import org.chipsalliance.cde.config.Config

/** V3's banked cache and 512-bit memory exit, with a 256-bit coherent writer. */
class TaihangSoC1Rocket1RVV3Gemmini32x32MemoryParallelV3TensorIngressConfig extends Config(
  new WithThreeAutonomousCommandFrontends ++
  new WithTaihangTensorIngress ++
  new TaihangSoC1Rocket1RVV3Gemmini32x32MemoryParallelV3Config)
