package chipyard.fpga.xcvu13p_gemmini_32x32_packed_inference_ram
import org.chipsalliance.cde.config.Parameters
import freechips.rocketchip.subsystem._
import chipyard.config.MultiRoCCKey
import chipyard.harness.HarnessBinderClockFrequencyKey
import sifive.blocks.devices.spi.PeripherySPIKey
object VideoSoCConfigTest extends App {
  val p: Parameters = new tsmcchip.fpga.taihangsoc.TaihangSoC1Rocket1RVV3Gemmini32x32PackedInference100MHzConfig
  val in = p(ExtIn).get
  assert(in.beatBytes == 32 && in.idBits == 5 && in.sourceBits == 7 && in.fifoBits == 5)
  assert(p(FrontBusKey).beatBytes == 32)
  assert(p(SystemBusKey).beatBytes == 32 && p(MemoryBusKey).beatBytes == 32)
  assert(p(HarnessBinderClockFrequencyKey) == 100.0)
  val mmio = p(ExtBus).get
  assert(mmio.base == BigInt("10040000", 16) && mmio.size == BigInt("200000", 16))
  assert(mmio.beatBytes == 8 && mmio.idBits == 4 && mmio.maxXferBytes == 64)
  for (offset <- Seq(0, 0x10000, 0x20000, 0x30000, 0x50000, 0x100000, 0x130000, 0x13ffff)) {
    val address = BigInt("10040000", 16) + offset
    assert(address >= mmio.base && address < mmio.base + mmio.size)
  }
  assert(p(PeripherySPIKey).isEmpty)
  assert(p(MultiRoCCKey)(0).size == 3)
  assert(p(InclusiveCacheKey).memCycles == 64)
  assert(!p(freechips.rocketchip.tile.LoopConvIngressDebugEscapeKey))
  assert(p(freechips.rocketchip.tile.RoCCBusyWriteBypassCSRsKey).isEmpty)
  assert(p(freechips.rocketchip.tile.RoCCMbusBypassPorts).isEmpty)
  val g = XCVU13PGemmini32x32PackedInferenceRamConfigs.config
  assert(g.meshRows * g.tileRows == 32 && g.meshColumns * g.tileColumns == 32)
  assert(g.tileRows == 1 && g.tileColumns == 8)
  assert(g.spatialArrayOutputType.getWidth == 24 && g.accType.getWidth == 32)
  assert(g.dsp_mac_unpack_stride == 2 && g.timing_closure)
  assert(g.max_in_flight_mem_reqs == 32)
  assert(g.dma_row_prefetch_entries == 0 && !g.dma_read_coalescing)
  assert(g.scratchpad_dma_buffer_entries == 2 && g.scratchpad_ex_burst == 0)
  println("NPU100_VIDEO_CONFIG=PASS clock=100 workers=3 mesh=32x32 FBus=256 ID=5 source=7 fifo=5 MMIO=2MiB SPI=off")
}
