package tsmcchip.fpga.taihangsoc

import org.chipsalliance.cde.config.Config

import chipyard.config.MultiRoCCKey
import freechips.rocketchip.rocket.RocketCoreConfig
import freechips.rocketchip.subsystem.{WithDTS, WithTimebase}

/** Explicit CPU requirements for the local OpenSBI/Linux software stack. */
class WithTaihangSingle4LinuxRocket extends RocketCoreConfig(_.copy(
  xLen = 64,
  bootFreqHz = BigInt(100000000),
  pgLevels = 3,
  useVM = true,
  useUser = true,
  useSupervisor = true,
  useAtomics = true,
  useAtomicsOnlyForIO = false,
  nPMPs = 8,
))

/** Keep the worker0 ABI while generating a separate Linux parameter header. */
class WithTaihangSingle4LinuxGemmini extends Config((site, here, up) => {
  case MultiRoCCKey => up(MultiRoCCKey) ++ Map(
    0 -> Seq(TaihangSoC16GemminiConfigs.builder(
      TaihangSoCOne4x4GemminiConfig.config.copy(
        headerFileName = "gemmini_params_taihang_single_4x4_packed_linux.h",
      ),
    )),
  )
})

/** Linux-capable single4 with the existing Taihang FPGA interfaces.
  *
  * CLINT derives its tick from the 100 MHz peripheral bus; 100 kHz therefore
  * means one tick per 1000 cycles. No SPI/SD controller is added: the initial
  * boot flow can use a JTAG-loaded OpenSBI payload and an initramfs.
  *
  * Busy/credit/accepted/retired CSRs retain their machine-mode addresses for
  * compatibility and diagnostics. Linux user software does not need to read
  * them: hardware handles ingress backpressure, and a RoCC-aware fence can
  * wait for completion. RoCC io.busy remains part of that synchronization.
  */
class TaihangSoC1Rocket1RVV1Gemmini4x4PackedFullOps256BitLinuxConfig extends Config(
  new WithTaihangSingle4LinuxRocket ++
  new WithTaihangSingle4LinuxGemmini ++
  new WithDTS(
    model = "Taihang single4 Linux",
    compat = Seq("tsmcchip,taihang-single4", "ucbbar,chipyard"),
  ) ++
  new WithTimebase(BigInt(100000)) ++
  new TaihangSoC1Rocket1RVV1Gemmini4x4PackedFullOps256BitConfig)
