package tsmcchip.fpga.taihangsoc

import org.chipsalliance.cde.config.Config
import freechips.rocketchip.tile.RoCCMbusBypassPorts

/** Route selected dedicated RoCC DMA masters to MBUS. Keys are tile IDs. */
class WithTaihangRoCCMbusBypass(ports: Map[Int, Set[Int]]) extends Config((site, here, up) => {
  case RoCCMbusBypassPorts => up(RoCCMbusBypassPorts) ++ ports
})

/** Small validation platform: CPU/RVV/PTW stay coherent; only Gemmini DMA bypasses L2.
  * The high CPU memory alias permits test-buffer initialization/readback without
  * allocating L1/L2 lines. Gemmini uses the corresponding original SoC PA.
  * Keep the ordinary MBUS crossbar here; MBus NoC is a separate experiment.
  */
class TaihangSoC1Rocket1RVV1Gemmini4x4MbusBypassConfig extends Config(
  new WithTaihangRoCCMbusBypass(Map(0 -> Set(0))) ++
  new freechips.rocketchip.subsystem.WithExtMemSbusBypass ++
  new TaihangSoC1Rocket1RVV1Gemmini4x4PackedFullOps256BitConfig)
