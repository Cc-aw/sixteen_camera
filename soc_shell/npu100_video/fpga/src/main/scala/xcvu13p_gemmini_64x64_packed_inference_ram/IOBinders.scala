package chipyard.fpga.xcvu13p_gemmini_64x64_packed_inference_ram

import chisel3._
import chisel3.reflect.DataMirror

import org.chipsalliance.cde.config.Parameters
import org.chipsalliance.diplomacy.lazymodule.InModuleBody

import freechips.rocketchip.amba.axi4.AXI4Bundle
import freechips.rocketchip.devices.debug._
import freechips.rocketchip.prci.{ClockSinkNode, ClockSinkParameters}
import freechips.rocketchip.resources.{Resource, ResourceAddress, ResourceBinding}
import freechips.rocketchip.subsystem.{BaseSubsystem, CanHaveMasterAXI4MemPort, ExtMem, HasTileLinkLocations, MBUS, MemoryBusKey, PBUS}
import freechips.rocketchip.util.{PSDTestMode, ResetCatchAndSync}

import sifive.blocks.devices.spi.{HasPeripherySPI, MMCDevice}
import sifive.blocks.devices.uart.HasPeripheryUART
import sifive.fpgashells.ip.xilinx.bscan2.JTAGTUNNEL
import testchipip.util.ClockedIO

import chipyard.iobinders.{AXI4MemPort, GetSystemParameters, OverrideLazyIOBinder, SPIPort, UARTPort}

class WithXCVU13PGemmini64x64PackedInferenceRamAXI4MemPunchthrough extends OverrideLazyIOBinder({
  (system: CanHaveMasterAXI4MemPort) => {
    implicit val p: Parameters = GetSystemParameters(system)
    val clockSinkNode = p(ExtMem).map(_ => ClockSinkNode(Seq(ClockSinkParameters())))
    clockSinkNode.map(_ := system.asInstanceOf[HasTileLinkLocations].locateTLBusWrapper(MBUS).fixedClockNode)
    def clockBundle = clockSinkNode.get.in.head._1

    InModuleBody {
      val ports = system.mem_axi4.zipWithIndex.map { case (mem, index) =>
        val port = IO(new ClockedIO(DataMirror.internal.chiselTypeClone[AXI4Bundle](mem)))
          .suggestName(s"axi4_mem_$index")
        port.bits <> mem
        port.clock := clockBundle.clock
        AXI4MemPort(
          () => port,
          p(ExtMem).get,
          system.memAXI4Node.edges.in(index),
          p(MemoryBusKey).dtsFrequency.get.toInt)
      }.toSeq
      (ports, Nil)
    }
  }
})

class WithXCVU13PGemmini64x64PackedInferenceRamUARTPunchthrough extends OverrideLazyIOBinder({
  (system: HasPeripheryUART) => {
    implicit val p: Parameters = GetSystemParameters(system)
    val bus = system.asInstanceOf[HasTileLinkLocations].locateTLBusWrapper(PBUS)

    InModuleBody {
      val ports = system.uart.zipWithIndex.map { case (uart, index) =>
        val port = IO(DataMirror.internal.chiselTypeClone(uart)).suggestName(s"uart_$index")
        port <> uart
        UARTPort(() => port, index, (bus.dtsFrequency.get / 1000000).toInt)
      }
      (ports, Nil)
    }
  }
})

class WithXCVU13PGemmini64x64PackedInferenceRamSPIPunchthrough extends OverrideLazyIOBinder({
  (system: HasPeripherySPI) => {
    implicit val p: Parameters = GetSystemParameters(system)
    if (system.tlSpiNodes.nonEmpty) ResourceBinding {
      Resource(new MMCDevice(system.tlSpiNodes.head.device, 1), "reg").bind(ResourceAddress(0))
    }

    InModuleBody {
      val ports = system.spi.zipWithIndex.map { case (spi, index) =>
        val port = IO(spi.cloneType).suggestName(s"spi_$index")
        port <> spi
        SPIPort(() => port)
      }
      (ports, Nil)
    }
  }
})

class WithXCVU13PGemmini64x64PackedInferenceRamJTAGTunnelDebug extends OverrideLazyIOBinder({
  (system: HasPeripheryDebug) => {
    implicit val p: Parameters = GetSystemParameters(system)
    val tlbus = system.asInstanceOf[BaseSubsystem].locateTLBusWrapper(p(ExportDebug).slaveWhere)
    val clockSinkNode = system.debugOpt.map(_ => ClockSinkNode(Seq(ClockSinkParameters())))
    clockSinkNode.map(_ := tlbus.fixedClockNode)
    def clockBundle = clockSinkNode.get.in.head._1

    InModuleBody {
      system.asInstanceOf[BaseSubsystem] match {
        case subsystem: HasPeripheryDebug =>
          subsystem.debug.map { debug =>
            subsystem.psd.psd.foreach { _ <> 0.U.asTypeOf(new PSDTestMode) }
            subsystem.resetctrl.map { resetController =>
              resetController.hartIsInReset.foreach { _ := clockBundle.reset.asBool }
            }
            debug.extTrigger.foreach { trigger =>
              trigger.in.req := false.B
              trigger.out.ack := trigger.out.req
            }
            debug.disableDebug.foreach { _ := false.B }

            Debug.connectDebugClockAndReset(Some(debug), clockBundle.clock)

            debug.systemjtag.foreach { jtag =>
              val tck = Wire(Bool())
              val tms = Wire(Bool())
              val tdi = Wire(Bool())
              val tdo = Wire(Bool())
              val tdoEnable = Wire(Bool())

              withClockAndReset(clockBundle.clock, clockBundle.reset) {
                JTAGTUNNEL(tck, tms, tdi, tdo, tdoEnable)
              }

              jtag.reset := ResetCatchAndSync(tck.asClock, clockBundle.reset.asBool)
              jtag.mfr_id := p(JtagDTMKey).idcodeManufId.U(11.W)
              jtag.part_number := p(JtagDTMKey).idcodePartNum.U(16.W)
              jtag.version := p(JtagDTMKey).idcodeVersion.U(4.W)
              jtag.jtag.TCK := tck.asClock
              jtag.jtag.TMS := tms
              jtag.jtag.TDI := tdi
              tdo := jtag.jtag.TDO.data
              tdoEnable := jtag.jtag.TDO.driven
            }

            require(debug.apb.isEmpty)
            (Nil, Nil)
          }.getOrElse((Nil, Nil))
      }
    }
  }
})
