package chipyard.fpga.myboard

import chisel3._

import chipyard.harness.{HarnessBinder, HasHarnessInstantiators}
import chipyard.iobinders.{AXI4InPort, AXI4MMIOPort, AXI4MemPort, ExtIntPort, SPIPort, UARTPort}

class WithMyBoardAXI4MemPassthrough extends HarnessBinder({
  case (_: HasHarnessInstantiators, port: AXI4MemPort, _: Int) =>
    val mem = IO(chiselTypeOf(port.io.bits)).suggestName("axi4_mem")
    mem <> port.io.bits
})

class WithMyBoardAXI4MMIOPassthrough extends HarnessBinder({
  case (_: HasHarnessInstantiators, port: AXI4MMIOPort, _: Int) =>
    val mmio = IO(chiselTypeOf(port.io.bits)).suggestName("axi4_mmio")
    mmio <> port.io.bits
})

/** Expose the ChipTop external interrupt vector at the FPGA harness boundary. */
class WithMyBoardExtInterruptPassthrough extends HarnessBinder({
  case (_: HasHarnessInstantiators, port: ExtIntPort, _: Int) =>
    val interrupts = IO(Input(chiselTypeOf(port.io))).suggestName("ext_interrupts")
    port.io := interrupts
})

class WithMyBoardAXI4InPassthrough extends HarnessBinder({
  case (_: HasHarnessInstantiators, port: AXI4InPort, _: Int) =>
    val fbus = IO(chiselTypeOf(port.io.bits)).suggestName("axi4_fbus")
    fbus <> port.io.bits
})

class WithMyBoardUARTPassthrough extends HarnessBinder({
  case (_: HasHarnessInstantiators, port: UARTPort, _: Int) =>
    val uart = IO(chiselTypeOf(port.io)).suggestName("uart")
    uart <> port.io
})

class WithMyBoardSPIPassthrough extends HarnessBinder({
  case (_: HasHarnessInstantiators, port: SPIPort, _: Int) =>
    val spi = IO(chiselTypeOf(port.io)).suggestName("spi")
    spi <> port.io
})
