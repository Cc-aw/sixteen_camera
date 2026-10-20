package chipyard.fpga.myboard

import org.chipsalliance.cde.config.Config
import saturn.common.VectorParams

/**
  * Common external interface for the video-only and full AI SoCs.
  *
  * Both variants expose the same 256-bit memory master, 256-bit coherent
  * front-bus slave, 64-bit MMIO master, UART, SPI, and JTAG tunnel ports.
  * The dedicated MMIO aperture keeps the generated address port compatible
  * with the existing AI top while avoiding its internal UART and SPI ranges.
  */
class WithVideoAICompatibleMyBoardInterfaces extends Config(
  new WithNoDebugClockGate ++
  new WithMyBoardAXI4InPassthrough ++
  new WithMyBoardUARTTweaks(freqMHz = 100.0, memDataBits = 256) ++
  new freechips.rocketchip.subsystem.WithCustomSlavePort(
    data_width = 256,
    id_bits = 4) ++
  new freechips.rocketchip.subsystem.WithCustomMMIOPort(
    base_addr = BigInt("11000000", 16),
    base_size = BigInt("01000000", 16),
    data_width = 64,
    id_bits = 4,
    maxXferBytes = 64))

/**
  * Fast implementation variant for standalone video validation.
  *
  * Keep the current video project's external contract (DDR master, video MMIO,
  * UART, JTAG and eight PL interrupts), while matching the validated AI memory
  * hierarchy used for DDR bring-up: a compact 64-bit system bus with the
  * broadcast coherence manager feeding a 256-bit external memory port.  No
  * coherent front-bus slave, SPI, Saturn RVV
  * unit, or Gemmini accelerator is instantiated in this variant.
  */
class RocketVideoOnlyAICompatibleMyBoardConfig extends Config(
  new WithNoDebugClockGate ++
  new WithMyBoardAXI4MemPassthrough ++
  new WithMyBoardAXI4MemPunchthrough ++
  new WithMyBoardStreamingVideoTweaks(freqMHz = 100.0) ++
  new freechips.rocketchip.subsystem.WithNExtTopInterrupts(8) ++
  new freechips.rocketchip.subsystem.WithCustomMMIOPort(
    base_addr = BigInt("40000000", 16),
    base_size = BigInt("01000000", 16),
    data_width = 64,
    id_bits = 4,
    maxXferBytes = 8) ++
  new freechips.rocketchip.subsystem.WithNBitMemoryBus(256) ++
  new freechips.rocketchip.subsystem.WithExtMemSize(BigInt(4) << 30) ++
  new chipyard.config.WithBroadcastManager ++
  new chipyard.config.WithSystemBusWidth(64) ++
  new freechips.rocketchip.rocket.WithNSmallCores(1) ++
  new chipyard.config.AbstractConfig)

/**
  * Final multicamera AI variant.
  *
  * This keeps the currently validated Large Gemmini and Saturn RVV parameters
  * while sharing the exact external port contract with the video-only SoC.
  */
class LargeGemminiRocketRVVDMAVideo8CamMyBoardConfig extends Config(
  new WithVideoAICompatibleMyBoardInterfaces ++
  new gemmini.DefaultGemminiConfig(MyBoardGemminiConfigs.largeConfig) ++
  new saturn.rocket.WithRocketVectorUnit(
    vLen = 128,
    dLen = 64,
    params = VectorParams(),
    useL1DCache = true) ++
  new freechips.rocketchip.rocket.WithNHugeCores(1) ++
  new chipyard.config.WithSystemBusWidth(256) ++
  new chipyard.config.AbstractConfig)
