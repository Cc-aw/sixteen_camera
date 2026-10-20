package chipyard.fpga.myboard

import chisel3._
import org.chipsalliance.cde.config.Config
import gemmini.{CapacityInKilobytes, GemminiConfigs}
import freechips.rocketchip.devices.debug.DebugModuleKey
import saturn.common.VectorParams

class WithMyBoardTweaks(freqMHz: Double = 50.0, ddrSize: BigInt = BigInt(4) << 30, memDataBits: Int = 128) extends Config(
  new WithMyBoardAXI4MemPassthrough ++
  new WithMyBoardAXI4MemPunchthrough ++
  new WithJTAGTunnelDebug ++
  new freechips.rocketchip.subsystem.WithNBitMemoryBus(memDataBits) ++
  new chipyard.harness.WithHarnessBinderClockFreqMHz(freqMHz) ++
  new chipyard.harness.WithAllClocksFromHarnessClockInstantiator ++
  new chipyard.config.WithUniformBusFrequencies(freqMHz) ++
  new chipyard.clocking.WithPassthroughClockGenerator ++
  new chipyard.config.WithNoUART ++
  new testchipip.serdes.WithNoSerialTL ++
  new freechips.rocketchip.subsystem.WithExtMemSize(ddrSize) ++
  new freechips.rocketchip.subsystem.WithoutTLMonitors)

class WithMyBoardUARTTweaks(freqMHz: Double = 100.0, ddrSize: BigInt = BigInt(4) << 30, memDataBits: Int = 256) extends Config(
  new WithMyBoardAXI4MemPassthrough ++
  new WithMyBoardAXI4MMIOPassthrough ++
  new WithMyBoardUARTPassthrough ++
  new WithMyBoardSPIPassthrough ++
  new WithMyBoardAXI4MemPunchthrough ++
  new WithMyBoardUARTPunchthrough ++
  new WithMyBoardSPIPunchthrough ++
  new WithJTAGTunnelDebug ++
  new freechips.rocketchip.subsystem.WithNBitMemoryBus(memDataBits) ++
  new chipyard.harness.WithHarnessBinderClockFreqMHz(freqMHz) ++
  new chipyard.harness.WithAllClocksFromHarnessClockInstantiator ++
  new chipyard.config.WithUniformBusFrequencies(freqMHz) ++
  new chipyard.clocking.WithPassthroughClockGenerator ++
  new chipyard.config.WithSPI(address = 0x10031000) ++
  new chipyard.config.WithUART(baudrate = 115200, address = 0x10020000, txEntries = 64, rxEntries = 64) ++
  new chipyard.config.WithNoUART ++
  new testchipip.serdes.WithNoSerialTL ++
  new freechips.rocketchip.subsystem.WithExtMemSize(ddrSize) ++
  new freechips.rocketchip.subsystem.WithoutTLMonitors)

object MyBoardGemminiConfigs {
  val largeConfig = GemminiConfigs.defaultConfig.copy(
    tileRows = 1,
    tileColumns = 1,
    meshRows = 32,
    meshColumns = 32,

    sp_capacity = CapacityInKilobytes(512),
    acc_capacity = CapacityInKilobytes(128),
    sp_banks = 8,
    acc_banks = 4,

    reservation_station_entries_ld = 16,
    reservation_station_entries_st = 8,
    reservation_station_entries_ex = 32,

    ld_queue_length = 16,
    st_queue_length = 8,
    ex_queue_length = 16,

    max_in_flight_mem_reqs = 32,
    dma_maxbytes = 64,
    dma_buswidth = 256,

    tlb_size = 8,
    headerFileName = "gemmini_params_large_myboard.h"
  )

  val mediumConfig = largeConfig.copy(
    meshRows = 16,
    meshColumns = 16,
    headerFileName = "gemmini_params_medium_myboard.h"
  )
}

class WithNoRocketDCacheScratchpad extends freechips.rocketchip.rocket.RocketTileConfig(
  tp => tp.copy(dcache = tp.dcache.map(_.copy(scratch = None))))

class WithNoDebugClockGate extends Config((site, here, up) => {
  case DebugModuleKey => up(DebugModuleKey).map(_.copy(clockGate = false))
})

class RocketMyBoardConfig extends Config(
  new WithMyBoardUARTTweaks(freqMHz = 50.0, memDataBits = 128) ++
  new chipyard.RocketConfig)

class GemminiRocketMyBoardConfig extends Config(
  new WithMyBoardTweaks ++
  new gemmini.DefaultGemminiConfig ++
  new chipyard.config.WithSystemBusWidth(128) ++
  new freechips.rocketchip.rocket.WithNHugeCores(1) ++
  new chipyard.config.AbstractConfig)

class LargeGemminiRocketMyBoardConfig extends Config(
  new WithMyBoardUARTTweaks(freqMHz = 100.0, memDataBits = 256) ++
  new freechips.rocketchip.subsystem.WithCustomMMIOPort(
    base_addr = BigInt("10040000", 16),
    base_size = BigInt("1000", 16),
    data_width = 64,
    id_bits = 4,
    maxXferBytes = 64) ++
  new gemmini.DefaultGemminiConfig(MyBoardGemminiConfigs.largeConfig) ++
  new chipyard.config.WithSystemBusWidth(256) ++
  new freechips.rocketchip.rocket.WithNHugeCores(1) ++
  new chipyard.config.AbstractConfig)

// DMA variant: exposes a 256-bit AXI slave port into the coherent front bus.
// Keep LargeGemminiRocketMyBoardConfig unchanged as the known-good fallback.
class LargeGemminiRocketDMAMyBoardConfig extends Config(
  new WithNoDebugClockGate ++
  new WithMyBoardAXI4InPassthrough ++
  new WithMyBoardUARTTweaks(freqMHz = 100.0, memDataBits = 256) ++
  new freechips.rocketchip.subsystem.WithCustomSlavePort(
    data_width = 256,
    id_bits = 4) ++
  new freechips.rocketchip.subsystem.WithCustomMMIOPort(
    base_addr = BigInt("10040000", 16),
    base_size = BigInt("1000", 16),
    data_width = 64,
    id_bits = 4,
    maxXferBytes = 64) ++
  new gemmini.DefaultGemminiConfig(MyBoardGemminiConfigs.largeConfig) ++
  new chipyard.config.WithSystemBusWidth(256) ++
  new freechips.rocketchip.rocket.WithNHugeCores(1) ++
  new chipyard.config.AbstractConfig)

// Full TinyYOLOv2 configuration: coherent frame DMA plus Saturn RVV maxpool.
// The non-RVV DMA config above remains available as the known-good fallback.
class LargeGemminiRocketRVVDMAMyBoardConfig extends Config(
  new WithNoDebugClockGate ++
  new WithMyBoardAXI4InPassthrough ++
  new WithMyBoardUARTTweaks(freqMHz = 100.0, memDataBits = 256) ++
  new freechips.rocketchip.subsystem.WithCustomSlavePort(
    data_width = 256,
    id_bits = 4) ++
  new freechips.rocketchip.subsystem.WithCustomMMIOPort(
    base_addr = BigInt("10040000", 16),
    base_size = BigInt("1000", 16),
    data_width = 64,
    id_bits = 4,
    maxXferBytes = 64) ++
  new gemmini.DefaultGemminiConfig(MyBoardGemminiConfigs.largeConfig) ++
  new saturn.rocket.WithRocketVectorUnit(
    vLen = 128,
    dLen = 64,
    params = VectorParams(),
    useL1DCache = true) ++
  new freechips.rocketchip.rocket.WithNHugeCores(1) ++
  new chipyard.config.WithSystemBusWidth(256) ++
  new chipyard.config.AbstractConfig)

// 16x16 variant of LargeGemminiRocketRVVDMAMyBoardConfig: same RVV DMA
// setup, only the Gemmini systolic array is shrunk to 16x16.
class MediumGemminiRocketRVVDMAMyBoardConfig extends Config(
  new WithNoDebugClockGate ++
  new WithMyBoardAXI4InPassthrough ++
  new WithMyBoardUARTTweaks(freqMHz = 100.0, memDataBits = 256) ++
  new freechips.rocketchip.subsystem.WithCustomSlavePort(
    data_width = 256,
    id_bits = 4) ++
  new freechips.rocketchip.subsystem.WithCustomMMIOPort(
    base_addr = BigInt("10040000", 16),
    base_size = BigInt("1000", 16),
    data_width = 64,
    id_bits = 4,
    maxXferBytes = 64) ++
  new gemmini.DefaultGemminiConfig(MyBoardGemminiConfigs.mediumConfig) ++
  new saturn.rocket.WithRocketVectorUnit(
    vLen = 128,
    dLen = 64,
    params = VectorParams(),
    useL1DCache = true) ++
  new freechips.rocketchip.rocket.WithNHugeCores(1) ++
  new chipyard.config.WithSystemBusWidth(256) ++
  new chipyard.config.AbstractConfig)

class RocketLargeMyBoardConfig extends Config(
  new WithMyBoardUARTTweaks(freqMHz = 100.0, memDataBits = 256) ++
  new freechips.rocketchip.subsystem.WithCustomMMIOPort(
    base_addr = BigInt("10040000", 16),
    base_size = BigInt("1000", 16),
    data_width = 64,
    id_bits = 4,
    maxXferBytes = 64) ++
  new chipyard.config.WithSystemBusWidth(256) ++
  new freechips.rocketchip.rocket.WithNHugeCores(1) ++
  new chipyard.config.AbstractConfig)

class TinyRocketDDRMyBoardConfig extends Config(
  new WithMyBoardTweaks ++
  new WithNoRocketDCacheScratchpad ++
  new testchipip.soc.WithNoScratchpads ++
  new chipyard.config.WithBroadcastManager ++
  new freechips.rocketchip.rocket.With1TinyCore ++
  new chipyard.config.AbstractConfig)

class SmallRocketDDRMyBoardConfig extends Config(
  new WithMyBoardTweaks ++
  new chipyard.config.WithBroadcastManager ++
  new freechips.rocketchip.rocket.WithNSmallCores(1) ++
  new chipyard.config.AbstractConfig)

/**
  * Minimal DDR bring-up SoC for the AI board DDR block design.
  *
  * The small Rocket and 64-bit system bus keep implementation pressure low,
  * while the exported memory AXI port remains 256 bits to match S00_AXI
  * exactly.  JTAG tunnel debug is retained; UART, SPI and external MMIO are
  * deliberately absent from the top-level contract.
  */
class SmallRocketDDR256MyBoardConfig extends Config(
  new WithNoDebugClockGate ++
  new WithMyBoardTweaks(freqMHz = 100.0, memDataBits = 256) ++
  new chipyard.config.WithBroadcastManager ++
  new chipyard.config.WithSystemBusWidth(64) ++
  new freechips.rocketchip.rocket.WithNSmallCores(1) ++
  new chipyard.config.AbstractConfig)

/**
  * FPGA harness and peripheral policy for the first, DDR-less streaming-video
  * integration stage. Video pixels remain entirely in programmable-logic
  * streaming datapaths; Rocket only configures and services the video IP.
  */
class WithMyBoardStreamingVideoTweaks(freqMHz: Double = 100.0) extends Config(
  new WithMyBoardAXI4MMIOPassthrough ++
  new WithMyBoardUARTPassthrough ++
  new WithMyBoardExtInterruptPassthrough ++
  new WithMyBoardUARTPunchthrough ++
  new WithJTAGTunnelDebug ++
  new chipyard.harness.WithHarnessBinderClockFreqMHz(freqMHz) ++
  new chipyard.harness.WithAllClocksFromHarnessClockInstantiator ++
  new chipyard.config.WithUniformBusFrequencies(freqMHz) ++
  new chipyard.clocking.WithPassthroughClockGenerator ++
  new chipyard.config.WithUART(
    baudrate = 115200,
    address = 0x10020000,
    txEntries = 64,
    rxEntries = 64) ++
  new chipyard.config.WithNoUART ++
  new testchipip.serdes.WithNoSerialTL ++
  new freechips.rocketchip.subsystem.WithoutTLMonitors)

/**
  * Stage-A control SoC for 4K60-in / 1080p60-out streaming video.
  *
  * - one small RV64 Rocket (no RVV, Gemmini, or other RoCC accelerator)
  * - 1 MiB on-chip scratchpad; no external memory port / DDR dependency
  * - 16 MiB, 64-bit AXI4 MMIO aperture for the video subsystem
  * - eight programmable-logic interrupt inputs
  */
class RocketStreamingVideoMyBoardConfig extends Config(
  new WithNoDebugClockGate ++
  new WithMyBoardStreamingVideoTweaks(freqMHz = 100.0) ++
  new freechips.rocketchip.subsystem.WithNExtTopInterrupts(8) ++
  new freechips.rocketchip.subsystem.WithCustomMMIOPort(
    base_addr = BigInt("40000000", 16),
    base_size = BigInt("01000000", 16),
    data_width = 64,
    id_bits = 4,
    maxXferBytes = 8) ++
  new testchipip.soc.WithMbusScratchpad(
    base = 0x80000000L,
    size = 1 << 20,
    banks = 2,
    partitions = 1) ++
  new testchipip.soc.WithNoScratchpads ++
  new freechips.rocketchip.subsystem.WithNoMemPort ++
  new chipyard.config.WithBroadcastManager ++
  new chipyard.config.WithSystemBusWidth(64) ++
  new freechips.rocketchip.rocket.WithNSmallCores(1) ++
  new chipyard.config.AbstractConfig)

/**
  * Streaming-video control SoC with a real external DDR memory port.
  *
  * This keeps the Stage-A UART, video MMIO aperture, and PL interrupts, but
  * removes the on-chip scratchpad/WithNoMemPort policy.  The exported
  * 256-bit AXI4 memory master is intended to connect to the XCVU13P DDR4 MIG
  * and is also the CPU-visible backing store used by AXI VDMA.
  */
class RocketStreamingVideoDDRMyBoardConfig extends Config(
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
  * Video-control extension of the validated SmallRocketDDR256 bring-up SoC.
  *
  * Keeps the small Rocket, 64-bit system bus, broadcast coherence manager and
  * 256-bit external DDR port, then adds only the interfaces required by the
  * RTL video subsystem: UART, one 64-bit MMIO master and eight PL interrupts.
  * SPI and accelerators remain absent.
  */
class SmallRocketVideoDDR256MyBoardConfig extends Config(
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
