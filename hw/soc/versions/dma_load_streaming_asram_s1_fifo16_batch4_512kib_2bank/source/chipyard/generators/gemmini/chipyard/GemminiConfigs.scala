package chipyard

import org.chipsalliance.cde.config.Config

// ------------------------------
// Configs with Gemmini RoCC
// ------------------------------

// DOC include start: GemminiRocketConfig
class GemminiRocketConfig extends Config(
  new gemmini.DefaultGemminiConfig ++                            // use Gemmini systolic array GEMM accelerator
  new freechips.rocketchip.rocket.WithNHugeCores(1) ++
  new chipyard.config.WithSystemBusWidth(128) ++
  new chipyard.config.AbstractConfig)
// DOC include end: GemminiRocketConfig

/** Complete Chipyard harness configuration for the 32x32 PnR Gemmini. */
class GemminiPnr32RocketConfig extends Config(
  new gemmini.DefaultGemminiConfig(gemmini.GemminiConfigs.myBoardConfig) ++
  new freechips.rocketchip.rocket.WithNHugeCores(1) ++
  new chipyard.config.WithSystemBusWidth(256) ++
  new chipyard.config.AbstractConfig)

class FPGemminiRocketConfig extends Config(
  new gemmini.GemminiFP32DefaultConfig ++                         // use FP32Gemmini systolic array GEMM accelerator
  new freechips.rocketchip.rocket.WithNHugeCores(1) ++
  new chipyard.config.WithSystemBusWidth(128) ++
  new chipyard.config.AbstractConfig)

class LeanGemminiRocketConfig extends Config(
  new gemmini.LeanGemminiConfig ++                                 // use Lean Gemmini systolic array GEMM accelerator
  new freechips.rocketchip.rocket.WithNHugeCores(1) ++
  new chipyard.config.WithSystemBusWidth(128) ++
  new chipyard.config.AbstractConfig)

class LeanGemminiPrintfRocketConfig extends Config(
  new gemmini.LeanGemminiPrintfConfig ++                                 // use Lean Gemmini systolic array GEMM accelerator
  new freechips.rocketchip.rocket.WithNHugeCores(1) ++
  new chipyard.config.WithSystemBusWidth(128) ++
  new chipyard.config.AbstractConfig)

/**
 * MyBoard: Large DIM32 Gemmini + DMA256 + Saturn RVV (vLen=128, dLen=64) @ 100 MHz.
 * Independent of stock GemminiRocketConfig / DIM16 pins.
 * Software profile: buddy i8-dim32-myboard (see /home/tsmc184/gky/buddy-gemmini).
 */
class LargeGemminiRocketRVVDMAMyBoardConfig extends Config(
  new gemmini.DefaultGemminiConfig(gemmini.GemminiConfigs.myBoardConfig) ++
  new saturn.rocket.WithRocketVectorUnit(128, 64, saturn.common.VectorParams.minParams) ++
  new freechips.rocketchip.rocket.WithNHugeCores(1) ++
  new chipyard.config.WithSystemBusWidth(256) ++
  new chipyard.config.WithTileFrequency(100.0) ++
  new chipyard.config.WithSystemBusFrequency(100.0) ++
  new chipyard.config.WithMemoryBusFrequency(100.0) ++
  new chipyard.config.WithPeripheryBusFrequency(100.0) ++
  new chipyard.config.AbstractConfig)

class ReRoCCManyGemminiConfig extends Config(
  new rerocc.WithReRoCC ++
  new gemmini.LeanGemminiConfig ++                              // rerocc tile3 is gemmini
  new gemmini.LeanGemminiConfig ++                              // rerocc tile2 is gemmini
  new gemmini.LeanGemminiConfig ++                              // rerocc tile1 is gemmini
  new gemmini.LeanGemminiConfig ++                              // rerocc tile0 is gemmini
  new freechips.rocketchip.rocket.WithNHugeCores(4) ++           // 4 rocket cores
  new chipyard.config.AbstractConfig)

class GemminiShuttleConfig extends Config(
  new gemmini.DefaultGemminiConfig ++                            // use Gemmini systolic array GEMM accel
  new shuttle.common.WithNShuttleCores ++
  new chipyard.config.AbstractConfig)
