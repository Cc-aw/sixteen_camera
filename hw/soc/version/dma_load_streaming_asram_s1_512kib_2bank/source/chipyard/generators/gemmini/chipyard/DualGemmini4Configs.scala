package chipyard

import chisel3.Data
import org.chipsalliance.cde.config.{Config, Parameters}
import freechips.rocketchip.diplomacy.LazyModule
import freechips.rocketchip.tile.{LazyRoCC, OpcodeSet}
import gemmini.{Arithmetic, CapacityInKilobytes, Gemmini, GemminiArrayConfig}
import saturn.common.VectorParams

/** Small, standard Chipyard simulation target for one hart driving two Gemminis. */
object DualGemmini4Configs {
  private val base = gemmini.GemminiConfigs.defaultConfig.copy(
    tileRows = 1,
    tileColumns = 1,
    meshRows = 4,
    meshColumns = 4,
    sp_capacity = CapacityInKilobytes(64),
    acc_capacity = CapacityInKilobytes(32),
    sp_banks = 2,
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

  val gemmini0 = base.copy(
    opcodes = OpcodeSet.custom3,
    busyCsrId = Some(0x7c2),
    headerFileName = "gemmini_params_taihang_4x4_gemmini0.h",
  )

  val gemmini1 = base.copy(
    opcodes = OpcodeSet.custom2,
    busyCsrId = Some(0x7c3),
    headerFileName = "gemmini_params_taihang_4x4_gemmini1.h",
  )

  def builder[T <: Data : Arithmetic, U <: Data, V <: Data](
    config: GemminiArrayConfig[T, U, V],
  ): Parameters => LazyRoCC = { p: Parameters =>
    implicit val q: Parameters = p
    LazyModule(new Gemmini(config))
  }
}

/** Places both Gemminis on Rocket hart 0: custom3/csr7c2 and custom2/csr7c3. */
class WithDualGemmini4OnHart0 extends Config((site, here, up) => {
  case chipyard.config.MultiRoCCKey => up(chipyard.config.MultiRoCCKey) ++ Map(
    0 -> Seq(
      DualGemmini4Configs.builder(DualGemmini4Configs.gemmini0),
      DualGemmini4Configs.builder(DualGemmini4Configs.gemmini1),
    ),
  )
})

/** Standard Chipyard harness target; suitable for positional ELF Verilator runs. */
class DualGemmini4RocketRVVConfig extends Config(
  new chipyard.config.WithMultiRoCC ++
  new WithDualGemmini4OnHart0 ++
  new saturn.rocket.WithRocketVectorUnit(
    vLen = 128,
    dLen = 64,
    params = VectorParams(),
    cores = Some(Seq(0)),
    useL1DCache = true,
  ) ++
  new freechips.rocketchip.rocket.WithNHugeCores(1) ++
  new chipyard.config.WithSystemBusWidth(256) ++
  new chipyard.config.AbstractConfig)

/** 16x16 counterpart used for meaningful dual-array timing measurements. */
object DualGemmini16Configs {
  private val base = gemmini.GemminiConfigs.defaultConfig.copy(
    tileRows = 1,
    tileColumns = 1,
    meshRows = 16,
    meshColumns = 16,
    sp_capacity = CapacityInKilobytes(128),
    acc_capacity = CapacityInKilobytes(32),
    sp_banks = 8,
    acc_banks = 4,
    reservation_station_entries_ld = 8,
    reservation_station_entries_st = 4,
    reservation_station_entries_ex = 16,
    ld_queue_length = 8,
    st_queue_length = 4,
    ex_queue_length = 8,
    max_in_flight_mem_reqs = 16,
    dma_maxbytes = 64,
    dma_buswidth = 256,
    tlb_size = 4,
  )

  val gemmini0 = base.copy(
    opcodes = OpcodeSet.custom3,
    busyCsrId = Some(0x7c2),
    headerFileName = "gemmini_params_dual_16x16_gemmini0.h",
  )
  val gemmini1 = base.copy(
    opcodes = OpcodeSet.custom2,
    busyCsrId = Some(0x7c3),
    headerFileName = "gemmini_params_dual_16x16_gemmini1.h",
  )
}

class WithDualGemmini16OnHart0 extends Config((site, here, up) => {
  case chipyard.config.MultiRoCCKey => up(chipyard.config.MultiRoCCKey) ++ Map(
    0 -> Seq(
      DualGemmini4Configs.builder(DualGemmini16Configs.gemmini0),
      DualGemmini4Configs.builder(DualGemmini16Configs.gemmini1),
    ),
  )
})

class DualGemmini16RocketRVVConfig extends Config(
  new chipyard.config.WithMultiRoCC ++
  new WithDualGemmini16OnHart0 ++
  new saturn.rocket.WithRocketVectorUnit(
    vLen = 128,
    dLen = 64,
    params = VectorParams(),
    cores = Some(Seq(0)),
    useL1DCache = true,
  ) ++
  new freechips.rocketchip.rocket.WithNHugeCores(1) ++
  new chipyard.config.WithSystemBusWidth(256) ++
  new chipyard.config.AbstractConfig)
