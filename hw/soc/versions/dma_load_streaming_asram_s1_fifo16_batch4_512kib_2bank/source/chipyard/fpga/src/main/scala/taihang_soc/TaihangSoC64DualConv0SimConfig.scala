package tsmcchip.fpga.taihangsoc

import org.chipsalliance.cde.config.Config
import chisel3._
import chipyard.harness.{HarnessBinder, HasHarnessInstantiators}
import chipyard.iobinders.UARTPort

class WithConv0UARTTiedOff extends HarnessBinder({
  case (_: HasHarnessInstantiators, port: UARTPort, _: Int) =>
    port.io.rxd := true.B
    port.io.cts_n.foreach(_ := false.B)
})

/** Verilator harness for the unchanged dual Gemmini64 board configuration. */
class TaihangSoC64DualConv0SimConfig extends Config(
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
  new chipyard.harness.WithTieOffL2FBusAXI ++
  new TaihangSoC1Rocket1RVV2Gemmini64x64PackedFullOps256BitConfig)
