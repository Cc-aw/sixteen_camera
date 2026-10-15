package chipyard.fpga.xcvu13p_gemmini_64x64_packed_inference_ram

import chisel3._

import org.chipsalliance.cde.config.Parameters

import chipyard.harness.HasHarnessInstantiators

class XCVU13PGemmini64x64PackedInferenceRamFPGATestHarness(implicit val p: Parameters)
    extends Module
    with HasHarnessInstantiators {
  def success: Bool = false.B

  def referenceClockFreqMHz: Double = getHarnessBinderClockFreqMHz
  def referenceClock: Clock = clock
  def referenceReset: Reset = reset

  instantiateChipTops()
}
