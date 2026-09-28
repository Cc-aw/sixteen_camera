package tsmcchip.fpga.taihangsoc

import org.chipsalliance.cde.config.{Config, Parameters}
import chipyard.fpga.xcvu13p_gemmini_64x64_packed_inference_ram.{
  RocketSaturnGemmini64x64PackedInferenceRamMultiXCVU13PConfig,
  XCVU13PGemmini64x64PackedInferenceRamFPGATestHarness
}

/** Same external module name and AXI/UART ports as the current video system. */
class TaihangSoCFPGATestHarness(implicit p: Parameters)
    extends XCVU13PGemmini64x64PackedInferenceRamFPGATestHarness

class TaihangSoC1Rocket1RVV3Gemmini64x64PackedInference100MHzConfig extends Config(
  new RocketSaturnGemmini64x64PackedInferenceRamMultiXCVU13PConfig)
