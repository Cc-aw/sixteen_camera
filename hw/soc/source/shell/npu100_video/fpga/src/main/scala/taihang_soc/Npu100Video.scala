package tsmcchip.fpga.taihangsoc

import org.chipsalliance.cde.config.{Config, Parameters}
import chipyard.fpga.xcvu13p_gemmini_32x32_packed_inference_ram.{
  RocketSaturnGemmini32x32PackedInferenceRamMultiXCVU13PConfig,
  XCVU13PGemmini32x32PackedInferenceRamFPGATestHarness
}

/** Same external module name and AXI/UART ports as the current video system. */
class TaihangSoCFPGATestHarness(implicit p: Parameters)
    extends XCVU13PGemmini32x32PackedInferenceRamFPGATestHarness

class TaihangSoC1Rocket1RVV3Gemmini32x32PackedInference100MHzConfig extends Config(
  new RocketSaturnGemmini32x32PackedInferenceRamMultiXCVU13PConfig)
