package chipyard.fpga.myboard

import chisel3._

import org.chipsalliance.cde.config.Parameters

import chipyard.harness.HasHarnessInstantiators

class MyBoardFPGATestHarness(implicit val p: Parameters) extends Module with HasHarnessInstantiators {
  def success: Bool = false.B

  def referenceClockFreqMHz: Double = getHarnessBinderClockFreqMHz
  def referenceClock: Clock = clock
  def referenceReset: Reset = reset

  instantiateChipTops()
}
