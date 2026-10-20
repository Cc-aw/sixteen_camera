package tsmcchip.fpga.taihangsoc

import chisel3._
import chisel3.reflect.DataMirror

import org.chipsalliance.cde.config.Parameters
import org.chipsalliance.diplomacy.lazymodule.InModuleBody

import freechips.rocketchip.devices.debug._
import freechips.rocketchip.amba.axi4.AXI4Bundle
import freechips.rocketchip.subsystem.{BaseSubsystem, CanHaveMasterAXI4MemPort, ExtMem, HasTileLinkLocations, MBUS, MemoryBusKey, PBUS}
import freechips.rocketchip.prci.{ClockSinkNode, ClockSinkParameters}
import freechips.rocketchip.util.{PSDTestMode, ResetCatchAndSync}

import sifive.blocks.devices.uart.HasPeripheryUART
import sifive.fpgashells.ip.xilinx.bscan2.JTAGTUNNEL
import testchipip.util.ClockedIO

import chipyard.iobinders.{AXI4MemPort, GetSystemParameters, OverrideLazyIOBinder, UARTPort}

class WithTaihangAXI4MemPunchthrough extends OverrideLazyIOBinder({
  (system: CanHaveMasterAXI4MemPort) => {
    implicit val p: Parameters = GetSystemParameters(system)
    val clockSinkNode = p(ExtMem).map(_ => ClockSinkNode(Seq(ClockSinkParameters())))
    clockSinkNode.map(_ := system.asInstanceOf[HasTileLinkLocations].locateTLBusWrapper(MBUS).fixedClockNode)
    def clockBundle = clockSinkNode.get.in.head._1

    InModuleBody {
      val ports = system.mem_axi4.zipWithIndex.map { case (m, i) =>
        val port = IO(new ClockedIO(DataMirror.internal.chiselTypeClone[AXI4Bundle](m))).suggestName(s"axi4_mem_${i}")
        port.bits <> m
        port.clock := clockBundle.clock
        AXI4MemPort(() => port, p(ExtMem).get, system.memAXI4Node.edges.in(i), p(MemoryBusKey).dtsFrequency.get.toInt)
      }.toSeq
      (ports, Nil)
    }
  }
})

class WithTaihangUARTPunchthrough extends OverrideLazyIOBinder({
  (system: HasPeripheryUART) => {
    implicit val p: Parameters = GetSystemParameters(system)
    val bus = system.asInstanceOf[HasTileLinkLocations].locateTLBusWrapper(PBUS)

    InModuleBody {
      val ports = system.uart.zipWithIndex.map { case (u, i) =>
        val port = IO(DataMirror.internal.chiselTypeClone(u)).suggestName(s"uart_${i}")
        port <> u
        UARTPort(() => port, i, (bus.dtsFrequency.get / 1000000).toInt)
      }
      (ports, Nil)
    }
  }
})

class WithTaihangJTAGTunnelDebug extends OverrideLazyIOBinder({
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
            subsystem.resetctrl.map { rcio =>
              rcio.hartIsInReset.foreach { _ := clockBundle.reset.asBool }
            }
            debug.extTrigger.foreach { t =>
              t.in.req := false.B
              t.out.ack := t.out.req
            }
            debug.disableDebug.foreach { _ := false.B }

            Debug.connectDebugClockAndReset(Some(debug), clockBundle.clock)

            debug.systemjtag.foreach { j =>
              val tck = Wire(Bool())
              val tms = Wire(Bool())
              val tdi = Wire(Bool())
              val tdo = Wire(Bool())
              val tdoEn = Wire(Bool())

              withClockAndReset(clockBundle.clock, clockBundle.reset) {
                JTAGTUNNEL(tck, tms, tdi, tdo, tdoEn)
              }

              j.reset := ResetCatchAndSync(tck.asClock, clockBundle.reset.asBool)
              j.mfr_id := p(JtagDTMKey).idcodeManufId.U(11.W)
              j.part_number := p(JtagDTMKey).idcodePartNum.U(16.W)
              j.version := p(JtagDTMKey).idcodeVersion.U(4.W)
              j.jtag.TCK := tck.asClock
              j.jtag.TMS := tms
              j.jtag.TDI := tdi
              tdo := j.jtag.TDO.data
              tdoEn := j.jtag.TDO.driven
            }

            require(debug.apb.isEmpty)
            (Nil, Nil)
          }.getOrElse((Nil, Nil))
      }
    }
  }
})
