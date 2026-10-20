package chipyard.fpga.myboard

import org.chipsalliance.cde.config.Config
import freechips.rocketchip.tile.OpcodeSet
import gemmini.CapacityInKilobytes
import saturn.common.VectorParams


// Resource-reduced 16x16 Gemmini parameters for the eight-accelerator build.
// Each Rocket hart receives the same four-opcode set, so the hart selects the
// group and custom3/custom2/custom1/custom0 selects one Gemmini in that group.
object ReducedEightGemminiConfigs {
  private val baseConfig = MyBoardGemminiConfigs.mediumConfig.copy(
    sp_capacity = CapacityInKilobytes(128),
    acc_capacity = CapacityInKilobytes(32),
  )

  val gemmini0Config = baseConfig.copy(
    opcodes = OpcodeSet.custom3,
    headerFileName = "gemmini_params_reduced_16x16_gemmini0.h",
  )

  val gemmini1Config = baseConfig.copy(
    opcodes = OpcodeSet.custom2,
    headerFileName = "gemmini_params_reduced_16x16_gemmini1.h",
  )

  val gemmini2Config = baseConfig.copy(
    opcodes = OpcodeSet.custom1,
    headerFileName = "gemmini_params_reduced_16x16_gemmini2.h",
  )

  val gemmini3Config = baseConfig.copy(
    opcodes = OpcodeSet.custom0,
    headerFileName = "gemmini_params_reduced_16x16_gemmini3.h",
  )
}


// Two Rocket harts, each with four reduced 16x16 Gemminis and one Saturn RVV
// unit. The existing Quad and single-Gemmini MyBoard configs remain untouched.
class DualRocketEightReducedGemminiRVVDMAMyBoardConfig extends Config(
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
  new chipyard.config.WithMultiRoCC ++
  new chipyard.config.WithMultiRoCCFromBuildRoCC(0, 1) ++
  new gemmini.DefaultGemminiConfig(ReducedEightGemminiConfigs.gemmini0Config) ++
  new gemmini.DefaultGemminiConfig(ReducedEightGemminiConfigs.gemmini1Config) ++
  new gemmini.DefaultGemminiConfig(ReducedEightGemminiConfigs.gemmini2Config) ++
  new gemmini.DefaultGemminiConfig(ReducedEightGemminiConfigs.gemmini3Config) ++
  new saturn.rocket.WithRocketVectorUnit(
    vLen = 128,
    dLen = 64,
    params = VectorParams(),
    useL1DCache = true) ++
  new freechips.rocketchip.rocket.WithNHugeCores(2) ++
  new chipyard.config.WithSystemBusWidth(256) ++
  new chipyard.config.AbstractConfig)
