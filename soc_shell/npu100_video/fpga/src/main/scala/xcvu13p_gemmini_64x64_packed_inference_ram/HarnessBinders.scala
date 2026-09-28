package chipyard.fpga.xcvu13p_gemmini_64x64_packed_inference_ram

import chisel3._

import chipyard.harness.{HarnessBinder, HasHarnessInstantiators}
import chipyard.iobinders.{AXI4InPort, AXI4MMIOPort, AXI4MemPort, SPIPort, UARTPort}

/** Board-facing passthrough binders kept in this configuration package. */
class WithXCVU13PGemmini64x64PackedInferenceRamAXI4MemPassthrough extends HarnessBinder({
  case (_: HasHarnessInstantiators, port: AXI4MemPort, _: Int) =>
    val mem = IO(chiselTypeOf(port.io.bits)).suggestName("axi4_mem")
    mem <> port.io.bits
})

class WithXCVU13PGemmini64x64PackedInferenceRamUARTPassthrough extends HarnessBinder({
  case (_: HasHarnessInstantiators, port: UARTPort, _: Int) =>
    val uart = IO(chiselTypeOf(port.io)).suggestName("uart")
    uart <> port.io
})

class WithXCVU13PGemmini64x64PackedInferenceRamSPIPassthrough extends HarnessBinder({
  case (_: HasHarnessInstantiators, port: SPIPort, _: Int) =>
    val spi = IO(chiselTypeOf(port.io)).suggestName("spi")
    spi <> port.io
})

class WithMergedAXI4InPassthrough extends HarnessBinder({
  case (_: HasHarnessInstantiators, port: AXI4InPort, _: Int) =>
    val dma = IO(chiselTypeOf(port.io.bits)).suggestName("axi4_fbus")
    dma <> port.io.bits
})
class WithMergedAXI4MMIOPassthrough extends HarnessBinder({
  case (_: HasHarnessInstantiators, port: AXI4MMIOPort, _: Int) =>
    val mmio = IO(chiselTypeOf(port.io.bits)).suggestName("axi4_mmio")
    mmio <> port.io.bits
})
