package tsmcchip.fpga.taihangsoc

import org.chipsalliance.cde.config.Config

/** Common HTIF/DRAM simulation harness for an exact Gemmini4 attachment A/B. */
class WithTaihangGemmini4CompareSimHarness extends Config(
  new testchipip.boot.WithNoCustomBootPin ++
  new testchipip.serdes.WithSerialTL(Seq(
    testchipip.serdes.SerialTLParams(
      client = Some(testchipip.serdes.SerialTLClientParams(totalIdBits = 4)),
      phyParams = testchipip.serdes.DecoupledExternalSyncSerialPhyParams(
        phitWidth = 32, flitWidth = 32),
      bundleParams = testchipip.serdes.TLSerdesser.STANDARD_TLBUNDLE_PARAMS.copy(dataBits = 256))
  )) ++
  new chipyard.harness.WithAbsoluteFreqHarnessClockInstantiator ++
  new chipyard.iobinders.WithDebugIOCells ++
  new chipyard.harness.WithSimTSIOverSerialTL ++
  new WithConv0UARTTiedOff ++
  new chipyard.harness.WithBlackBoxSimMem ++
  new chipyard.harness.WithSimAXIMMIO ++
  new chipyard.harness.WithTieOffL2FBusAXI)

/** Gemmini reader/writer attach directly to MBUS. */
class TaihangGemmini4MbusBypassCompareSimConfig extends Config(
  new WithTaihangGemmini4CompareSimHarness ++
  new TaihangSoC1Rocket1RVV1Gemmini4x4MbusBypassConfig)

/** Same one-Gemmini base and CPU uncached alias; Gemmini DMA stays on SBUS/L2. */
class TaihangGemmini4SbusBaselineCompareSimConfig extends Config(
  new WithTaihangGemmini4CompareSimHarness ++
  new freechips.rocketchip.subsystem.WithExtMemSbusBypass ++
  new TaihangSoC1Rocket1RVV1Gemmini4x4PackedFullOps256BitConfig)
