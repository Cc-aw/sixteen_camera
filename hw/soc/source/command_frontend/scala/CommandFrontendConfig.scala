package tsmcchip.fpga.taihangsoc

import org.chipsalliance.cde.config.Config
import freechips.rocketchip.tile.commandfrontend.CommandFrontendKey

/** Enable the donor frontend while retaining the local TensorIngress shell. */
class WithThreeAutonomousCommandFrontends extends Config((site, here, up) => {
  case CommandFrontendKey => true
})
