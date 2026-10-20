package tsmcchip.fpga.taihangsoc

import chisel3._

import chipyard.harness.{HarnessBinder, HasHarnessInstantiators}
import chipyard.iobinders.{AXI4InPort, AXI4MMIOPort, AXI4MemPort, UARTPort}

class WithTaihangAXI4MemPassthrough extends HarnessBinder({
  case (_: HasHarnessInstantiators, port: AXI4MemPort, _: Int) =>
    val mem = IO(chiselTypeOf(port.io.bits)).suggestName("axi4_mem")
    mem <> port.io.bits
})

class WithTaihangAXI4MMIOPassthrough extends HarnessBinder({
  case (_: HasHarnessInstantiators, port: AXI4MMIOPort, _: Int) =>
    val mmio = IO(chiselTypeOf(port.io.bits)).suggestName("axi4_mmio")
    mmio <> port.io.bits
})

class WithTaihangAXI4InPassthrough extends HarnessBinder({
  case (_: HasHarnessInstantiators, port: AXI4InPort, _: Int) =>
    val fbus = IO(chiselTypeOf(port.io.bits)).suggestName("axi4_fbus")
    fbus <> port.io.bits
})

class WithTaihangUARTPassthrough extends HarnessBinder({
  case (_: HasHarnessInstantiators, port: UARTPort, _: Int) =>
    val uart = IO(chiselTypeOf(port.io)).suggestName("uart")
    uart <> port.io
})
