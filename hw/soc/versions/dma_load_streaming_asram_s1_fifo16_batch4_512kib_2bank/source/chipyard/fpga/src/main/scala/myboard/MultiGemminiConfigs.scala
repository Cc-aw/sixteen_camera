package chipyard.fpga.myboard

import org.chipsalliance.cde.config.Config
import freechips.rocketchip.subsystem.{CacheBlockBytes, InSubsystem, NumTiles, RocketCrossingParams, RocketTileAttachParams, SystemBusKey, TilesLocated}
import freechips.rocketchip.tile.{FPUParams, OpcodeSet, RocketTileParams}
import freechips.rocketchip.rocket.{DCacheParams, ICacheParams, MulDivParams, RocketCoreParams}
import gemmini.GemminiConfigs
import saturn.common.VectorParams


// Gemmini 1 config: same as largeConfig but on custom2 instead of custom3.
object DualGemminiConfigs {
  val gemmini0Config = MyBoardGemminiConfigs.largeConfig.copy(
    busyCsrId = Some(0x7c2),
  )

  val gemmini1Config = MyBoardGemminiConfigs.largeConfig.copy(
    opcodes = OpcodeSet.custom2,
    headerFileName = "gemmini_params_large_myboard_gemmini1.h",
    busyCsrId = Some(0x7c3),
  )
}

// Timing-convergence variant: preserve both DIM32 arrays and the 256-bit DMA
// datapath, while reducing storage depth and command-window fanout.
object DualGemminiConvergentConfigs {
  val gemmini0Config = MyBoardGemminiConfigs.largeConfig.copy(
    sp_capacity = gemmini.CapacityInKilobytes(256),
    acc_capacity = gemmini.CapacityInKilobytes(64),
    reservation_station_entries_ld = 8,
    reservation_station_entries_st = 4,
    reservation_station_entries_ex = 16,
    ld_queue_length = 8,
    st_queue_length = 4,
    ex_queue_length = 8,
    max_in_flight_mem_reqs = 16,
    tlb_size = 4,
    busyCsrId = Some(0x7c2),
  )

  val gemmini1Config = gemmini0Config.copy(
    opcodes = OpcodeSet.custom2,
    headerFileName = "gemmini_params_large_myboard_gemmini1.h",
    busyCsrId = Some(0x7c3),
  )
}

// Small dual-Gemmini test configuration.  Both arrays are 8x8; the reduced
// memories keep this build useful for FPGA bring-up while preserving the
// same custom-opcode and busy-CSR software contract as the DIM32 pool.
object DualGemmini8Configs {
  private val baseConfig = MyBoardGemminiConfigs.largeConfig.copy(
    meshRows = 8,
    meshColumns = 8,
    sp_capacity = gemmini.CapacityInKilobytes(64),
    acc_capacity = gemmini.CapacityInKilobytes(32),
    sp_banks = 4,
    acc_banks = 2,
    reservation_station_entries_ld = 8,
    reservation_station_entries_st = 4,
    reservation_station_entries_ex = 8,
    ld_queue_length = 8,
    st_queue_length = 4,
    ex_queue_length = 8,
    max_in_flight_mem_reqs = 8,
    dma_maxbytes = 64,
    dma_buswidth = 256,
    tlb_size = 4,
  )

  val gemmini0Config = baseConfig.copy(
    busyCsrId = Some(0x7c2),
    headerFileName = "gemmini_params_8x8_myboard.h",
  )

  val gemmini1Config = baseConfig.copy(
    opcodes = OpcodeSet.custom2,
    busyCsrId = Some(0x7c3),
    headerFileName = "gemmini_params_8x8_myboard_gemmini1.h",
  )
}


// FPGA-oriented replacement for WithNHugeCores. It preserves the huge core's
// ISA/FPU geometry while making cache associativity selectable for congested
// FPGA implementations.
class WithNMyBoardFPGACores(n: Int, cacheWays: Int = 8) extends Config((site, here, up) => {
  case TilesLocated(InSubsystem) => {
    val prev = up(TilesLocated(InSubsystem))
    val idOffset = up(NumTiles)
    val fpgaCore = RocketTileParams(
      core = RocketCoreParams(
        mulDiv = Some(MulDivParams(
          mulUnroll = 8,
          mulEarlyOut = true,
          divEarlyOut = true,
        )),
        useVM = false,
        useZba = true,
        useZbb = true,
        useZbs = true,
        fpu = Some(FPUParams(minFLen = 16))),
      dcache = Some(DCacheParams(
        nSets = 64,
        nWays = cacheWays,
        nTLBSets = 1,
        nTLBWays = 4,
        rowBits = site(SystemBusKey).beatBits,
        nMSHRs = 0,
        blockBytes = site(CacheBlockBytes))),
      icache = Some(ICacheParams(
        nSets = 64,
        nWays = cacheWays,
        rowBits = site(SystemBusKey).beatBits,
        blockBytes = site(CacheBlockBytes))))
    List.tabulate(n)(i => RocketTileAttachParams(
      fpgaCore.copy(tileId = i + idOffset),
      RocketCrossingParams()
    )) ++ prev
  }
  case NumTiles => up(NumTiles) + n
})


// Dual-Gemmini MyBoard config based on LargeGemminiRocketDMAMyBoardConfig:
// two 32x32 Gemminis (custom3/custom2), DMA FBUS slave port.
class DualLargeGemminiRocketDMAMyBoardConfig extends Config(
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
  new gemmini.DefaultGemminiConfig(DualGemminiConfigs.gemmini0Config) ++
  new gemmini.DefaultGemminiConfig(DualGemminiConfigs.gemmini1Config) ++
  new freechips.rocketchip.rocket.WithNHugeCores(1) ++
  new chipyard.config.WithSystemBusWidth(256) ++
  new chipyard.config.AbstractConfig)


// Dual-Gemmini variant of LargeGemminiRocketRVVDMAMyBoardConfig:
// keep the coherent FBUS input, Saturn RVV, and all board interfaces while
// attaching two identical 32x32 Gemminis on custom3 and custom2.
class DualLargeGemminiRocketRVVDMAMyBoardConfig extends Config(
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
  new gemmini.DefaultGemminiConfig(DualGemminiConfigs.gemmini0Config) ++
  new gemmini.DefaultGemminiConfig(DualGemminiConfigs.gemmini1Config) ++
  new saturn.rocket.WithRocketVectorUnit(
    vLen = 128,
    dLen = 64,
    params = VectorParams(),
    useL1DCache = true) ++
  new freechips.rocketchip.rocket.WithNHugeCores(1) ++
  new chipyard.config.WithSystemBusWidth(256) ++
  new chipyard.config.AbstractConfig)


// Timing-oriented dual-Gemmini FPGA variant. The original
// DualLargeGemminiRocketRVVDMAMyBoardConfig remains available unchanged.
class DualLargeGemminiFPGARocketRVVDMAMyBoardConfig extends Config(
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
  new gemmini.DefaultGemminiConfig(DualGemminiConfigs.gemmini0Config) ++
  new gemmini.DefaultGemminiConfig(DualGemminiConfigs.gemmini1Config) ++
  new saturn.rocket.WithRocketVectorUnit(
    vLen = 128,
    dLen = 64,
    params = VectorParams(),
    useL1DCache = true) ++
  new WithNMyBoardFPGACores(1) ++
  new chipyard.config.WithSystemBusWidth(256) ++
  new chipyard.config.AbstractConfig)


// Dual DIM32 convergence-first configuration. The original dual configs remain
// unchanged for resource/performance comparison and rollback.
class DualLargeGemminiConvergentRocketRVVDMAMyBoardConfig extends Config(
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
  new gemmini.DefaultGemminiConfig(DualGemminiConvergentConfigs.gemmini0Config) ++
  new gemmini.DefaultGemminiConfig(DualGemminiConvergentConfigs.gemmini1Config) ++
  new saturn.rocket.WithRocketVectorUnit(
    vLen = 128,
    dLen = 64,
    params = VectorParams(),
    useL1DCache = true) ++
  new WithNMyBoardFPGACores(1, cacheWays = 4) ++
  new chipyard.config.WithSystemBusWidth(256) ++
  new chipyard.config.AbstractConfig)


// Dual 8x8 Gemmini smoke-test configuration.  The board interfaces, coherent
// DMA port, and Saturn RVV unit match the existing dual DIM32 configuration so
// generated RTL can be swapped into the same test harness.
class DualGemmini8RocketRVVDMAMyBoardConfig extends Config(
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
  new gemmini.DefaultGemminiConfig(DualGemmini8Configs.gemmini0Config) ++
  new gemmini.DefaultGemminiConfig(DualGemmini8Configs.gemmini1Config) ++
  new saturn.rocket.WithRocketVectorUnit(
    vLen = 128,
    dLen = 64,
    params = VectorParams(),
    useL1DCache = true) ++
  new freechips.rocketchip.rocket.WithNHugeCores(1) ++
  new chipyard.config.WithSystemBusWidth(256) ++
  new chipyard.config.AbstractConfig)


// Quad-Gemmini configs: four 16x16 Gemminis, one per custom opcode
// (custom3/custom2/custom1/custom0), each with its own params header.
object QuadGemminiConfigs {
  val gemmini0Config = MyBoardGemminiConfigs.mediumConfig

  val gemmini1Config = MyBoardGemminiConfigs.mediumConfig.copy(
    opcodes = OpcodeSet.custom2,
    headerFileName = "gemmini_params_medium_myboard_gemmini1.h",
  )

  val gemmini2Config = MyBoardGemminiConfigs.mediumConfig.copy(
    opcodes = OpcodeSet.custom1,
    headerFileName = "gemmini_params_medium_myboard_gemmini2.h",
  )

  val gemmini3Config = MyBoardGemminiConfigs.mediumConfig.copy(
    opcodes = OpcodeSet.custom0,
    headerFileName = "gemmini_params_medium_myboard_gemmini3.h",
  )
}


// Quad-Gemmini MyBoard config based on MediumGemminiRocketRVVDMAMyBoardConfig:
// four 16x16 Gemminis (custom3/custom2/custom1/custom0), Saturn RVV unit,
// DMA FBUS slave port.
class QuadMediumGemminiRocketRVVDMAMyBoardConfig extends Config(
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
  new gemmini.DefaultGemminiConfig(QuadGemminiConfigs.gemmini0Config) ++
  new gemmini.DefaultGemminiConfig(QuadGemminiConfigs.gemmini1Config) ++
  new gemmini.DefaultGemminiConfig(QuadGemminiConfigs.gemmini2Config) ++
  new gemmini.DefaultGemminiConfig(QuadGemminiConfigs.gemmini3Config) ++
  new saturn.rocket.WithRocketVectorUnit(
    vLen = 128,
    dLen = 64,
    params = VectorParams(),
    useL1DCache = true) ++
  new freechips.rocketchip.rocket.WithNHugeCores(1) ++
  new chipyard.config.WithSystemBusWidth(256) ++
  new chipyard.config.AbstractConfig)
