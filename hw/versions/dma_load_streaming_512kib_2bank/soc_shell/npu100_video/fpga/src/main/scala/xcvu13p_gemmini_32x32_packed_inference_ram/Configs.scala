package chipyard.fpga.xcvu13p_gemmini_32x32_packed_inference_ram

import chisel3._

import org.chipsalliance.cde.config.{Config, Parameters}

import chipyard.config.{MultiRoCCKey, WithMultiRoCC}
import gemmini.{CapacityInKilobytes, Dataflow, GemminiConfigs}
import freechips.rocketchip.devices.debug.DebugModuleKey
import freechips.rocketchip.diplomacy.LazyModule
import freechips.rocketchip.tile.OpcodeSet
import saturn.common.VectorParams

/** Board-level policy for the self-contained 32x32 multi-Gemmini design. */
class WithXCVU13PGemmini32x32PackedInferenceRamTweaks(
  freqMHz: Double = 100.0,
  ddrSize: BigInt = BigInt(4) << 30,
  memDataBits: Int = 256) extends Config(
  new WithMergedVideoProductionRoCC ++
  new WithMergedBatch2Interfaces ++
  new WithMergedCompactL2 ++
  new WithXCVU13PGemmini32x32PackedInferenceRamAXI4MemPassthrough ++
  new WithXCVU13PGemmini32x32PackedInferenceRamUARTPassthrough ++
  new WithXCVU13PGemmini32x32PackedInferenceRamAXI4MemPunchthrough ++
  new WithXCVU13PGemmini32x32PackedInferenceRamUARTPunchthrough ++
  new WithXCVU13PGemmini32x32PackedInferenceRamJTAGTunnelDebug ++
  new freechips.rocketchip.subsystem.WithNBitMemoryBus(memDataBits) ++
  new chipyard.harness.WithHarnessBinderClockFreqMHz(freqMHz) ++
  new chipyard.harness.WithAllClocksFromHarnessClockInstantiator ++
  new chipyard.config.WithUniformBusFrequencies(freqMHz) ++
  new chipyard.clocking.WithPassthroughClockGenerator ++
  new chipyard.config.WithUART(
    baudrate = 115200,
    address = 0x10020000,
    txEntries = 64,
    rxEntries = 64) ++
  new chipyard.config.WithNoUART ++
  new testchipip.serdes.WithNoSerialTL ++
  new freechips.rocketchip.subsystem.WithExtMemSize(ddrSize) ++
  new freechips.rocketchip.subsystem.WithoutTLMonitors)

class WithXCVU13PGemmini32x32PackedInferenceRamNoDebugClockGate extends Config((site, here, up) => {
  case DebugModuleKey => up(DebugModuleKey).map(_.copy(clockGate = false))
})

object XCVU13PGemmini32x32PackedInferenceRamConfigs {
  // Start from the standard Gemmini API, then state every design choice that
  // affects this reproducible build. No local 32x32 configuration is imported.
  val config = GemminiConfigs.defaultConfig.copy(
    tileRows = 1,
    tileColumns = 8,
    meshRows = 32,
    meshColumns = 4,
    dataflow = Dataflow.WS,
    inputType = SInt(8.W),
    weightType = SInt(8.W),
    accType = SInt(32.W),
    spatialArrayInputType = SInt(8.W),
    spatialArrayWeightType = SInt(8.W),
    spatialArrayOutputType = SInt(24.W),
    use_dsp_output_shift = false,
    use_dsp_mac_blackbox = false,
    use_dsp_mac_packing = true,
    dsp_mac_unpack_stride = 2,
    timing_closure = true,
    // Production baseline. DMA v2 remains an explicit experiment below;
    // its board run did not demonstrate a network speedup and failed setup.
    dma_row_prefetch_entries = 0,
    dma_read_coalescing = false,
    scratchpad_dma_buffer_entries = 2,
    scratchpad_ex_burst = 0,
    tile_latency = 1,
    acc_latency = 4,
    result_buffer_rows = 512,
    silu_only = true,
    mvin_scale_args = GemminiConfigs.defaultConfig.mvin_scale_args.map(
      _.copy(multiplicand_t = gemmini.Float(5, 11))),
    acc_scale_args = GemminiConfigs.defaultConfig.acc_scale_args.map(
      _.copy(multiplicand_t = gemmini.Float(5, 11), num_scale_units = 64)),
    sp_capacity = CapacityInKilobytes(512),
    acc_capacity = CapacityInKilobytes(256),
    sp_banks = 8,
    acc_banks = 4,
    sp_singleported = true,
    acc_singleported = false,
    reservation_station_entries_ld = 16,
    reservation_station_entries_st = 8,
    reservation_station_entries_ex = 32,
    ld_queue_length = 16,
    st_queue_length = 8,
    ex_queue_length = 16,
    max_in_flight_mem_reqs = 32,
    dma_maxbytes = 64,
    dma_buswidth = 256,
    use_tlb = false,
    tlb_size = 8,
    use_transposer = false,
    has_training_convs = false,
    has_max_pool = true,
    has_nonlinear_activations = true,
    has_silu_lut = true,
    has_dw_convs = false,
    has_normalizations = false,
    has_first_layer_optimizations = true,
    has_loop_conv = true,
    acc_read_full_width = true,
    acc_read_small_width = true,
    ex_read_from_spad = true,
    ex_read_from_acc = true,
    ex_write_to_spad = true,
    ex_write_to_acc = true,
    // IPOAT（王志瑞）：单实例沿用已板测 custom3 worker 的 credit CSR ABI。
    busyCsrId = Some(0x7c2),
    loopConvStatusCsrId = Some(0x7c4),
    loopConvAcceptedCsrId = Some(0x7c6),
    loopConvRetiredCsrId = Some(0x7c7),
    loopConvSafeMax = 4,
    headerFileName = "gemmini_params_32x32_ws_dual_int8_dsp_inference_ram_xcvu13p.h"
  )

  // Archived DMA v2 experiment (2026-10-11), never selected by default.
  // Keep the implementation and exact settings for future investigation.
  // Individual experiments can use config.copy(...) instead of this preset.
  val experimentalMemoryDmaV2Config = config.copy(
    dma_row_prefetch_entries = 4,
    dma_read_coalescing = true,
    scratchpad_dma_buffer_entries = 4,
    scratchpad_ex_burst = 3
  )
}

/**
  * One Rocket core, the original Saturn vector unit, and one logical 32x32
  * INT8 Gemmini with WS dual-INT8 DSP packing and inference controls.
  * Nonlinear activation remains available for the YOLOv5 datapath.
  */
class RocketSaturnGemmini32x32PackedInferenceRamXCVU13PConfig extends Config(
  new WithXCVU13PGemmini32x32PackedInferenceRamNoDebugClockGate ++
  new WithXCVU13PGemmini32x32PackedInferenceRamTweaks ++
  new gemmini.DefaultGemminiConfig(XCVU13PGemmini32x32PackedInferenceRamConfigs.config) ++
  new saturn.rocket.WithRocketVectorUnit(
    vLen = 256,
    dLen = 128,
    params = VectorParams.dspParams,
    useL1DCache = true) ++
  new chipyard.config.WithSystemBusWidth(256) ++
  new freechips.rocketchip.rocket.WithNHugeCores(1) ++
  new chipyard.config.AbstractConfig)

object XCVU13PGemmini32x32PackedInferenceRamMultiConfigs {
  // All instances use the accepted 32x32 packed inference configuration.
  // Nonlinear activation is retained for the requested YOLOv5 datapath.
  // Functional resources are identical. Each worker has its own opcode/CSRs
  // and a source-level Scratchpad placement hint for the four-SLR device.
  val base = XCVU13PGemmini32x32PackedInferenceRamConfigs.config.copy(
    has_nonlinear_activations = true)
}

/**
  * One Rocket core, Saturn, and three independent 32x32 Gemmini instances.
  *
  * custom1, custom2, and custom3 select Gemmini0, Gemmini1, and Gemmini2.
  * Each instance has its own queues, DMA, scratchpad, accumulator, reservation
  * station, and completion state. The three instances retain the latest
  * 32x32 packed-inference settings: WS, dual-INT8 DSP packing, physical DMA
  * addresses, and the inference feature set with nonlinear activation
  * retained, and MaxPool enabled for all three workers. TLB, transposer,
  * and training-convolution remain disabled as in the latest 32x32 baseline.
  */
class RocketSaturnGemmini32x32PackedInferenceRamMultiXCVU13PConfig extends Config(
  new WithMultiRoCC ++
  new Config((site, here, up) => {
    case MultiRoCCKey => Map(
      0 -> Seq(
        (p: Parameters) => {
          implicit val q: Parameters = p
          LazyModule(new gemmini.Gemmini(
            XCVU13PGemmini32x32PackedInferenceRamMultiConfigs.base.copy(
              dma_load_runtime_enable = p(gemmini.DmaLoadRuntimeKey),
              dma_load_streaming_enable = p(gemmini.DmaLoadStreamingKey),
              opcodes = OpcodeSet.custom1,
              fpgaScratchpadSlr = Some(0),
              // IPOAT（王志瑞）：每个 worker 独占一组 CSR；custom1 使用预留扩展段。
              busyCsrId = Some(0x7ca),
              loopConvStatusCsrId = Some(0x7cb),
              loopConvAcceptedCsrId = Some(0x7cc),
              loopConvRetiredCsrId = Some(0x7cd),
              headerFileName =
                "gemmini_params_32x32_ws_dual_int8_dsp_inference_ram_custom1_xcvu13p.h")))
        },
        (p: Parameters) => {
          implicit val q: Parameters = p
          LazyModule(new gemmini.Gemmini(
            XCVU13PGemmini32x32PackedInferenceRamMultiConfigs.base.copy(
              dma_load_runtime_enable = p(gemmini.DmaLoadRuntimeKey),
              dma_load_streaming_enable = p(gemmini.DmaLoadStreamingKey),
              opcodes = OpcodeSet.custom2,
              // Keep the established worker1 SLR placement. The MaxPool
              // timing-v2 floorplan instead moves the two L2 banks out of
              // SLR1 to relieve its measured routing/BRAM concentration.
              fpgaScratchpadSlr = Some(1),
              // IPOAT（王志瑞）：custom2 保持双 worker 板测使用的 CSR ABI。
              busyCsrId = Some(0x7c3),
              loopConvStatusCsrId = Some(0x7c5),
              loopConvAcceptedCsrId = Some(0x7c8),
              loopConvRetiredCsrId = Some(0x7c9),
              headerFileName =
                "gemmini_params_32x32_ws_dual_int8_dsp_inference_ram_custom2_xcvu13p.h")))
        },
        (p: Parameters) => {
          implicit val q: Parameters = p
          LazyModule(new gemmini.Gemmini(
            XCVU13PGemmini32x32PackedInferenceRamMultiConfigs.base.copy(
              dma_load_runtime_enable = p(gemmini.DmaLoadRuntimeKey),
              dma_load_streaming_enable = p(gemmini.DmaLoadStreamingKey),
              opcodes = OpcodeSet.custom3,
              fpgaScratchpadSlr = Some(3),
              // IPOAT（王志瑞）：custom3 保持双 worker 板测使用的 CSR ABI。
              busyCsrId = Some(0x7c2),
              loopConvStatusCsrId = Some(0x7c4),
              loopConvAcceptedCsrId = Some(0x7c6),
              loopConvRetiredCsrId = Some(0x7c7),
              headerFileName =
                "gemmini_params_32x32_ws_dual_int8_dsp_inference_ram_custom3_xcvu13p.h")))
        }
      )
    )
  }) ++
  new WithXCVU13PGemmini32x32PackedInferenceRamNoDebugClockGate ++
  new WithXCVU13PGemmini32x32PackedInferenceRamTweaks ++
  new saturn.rocket.WithRocketVectorUnit(
    vLen = 256,
    dLen = 128,
    params = VectorParams.dspParams,
    useL1DCache = true) ++
  new chipyard.config.WithSystemBusWidth(256) ++
  new freechips.rocketchip.rocket.WithNHugeCores(1) ++
  new chipyard.config.AbstractConfig)

/** Video Tensor writes use AXI IDs 18..31; PPU reads use IDs 0..17.
  * Keep every ID in a separate FIFO group and retain two read slots per ID.
  * The video/PPU MMIO aperture includes offsets through 0x13ffff.
  */
class WithMergedBatch2Interfaces extends Config(
  new WithMergedVideoFrontBus ++
  new WithMergedAXI4InPassthrough ++
  new WithMergedAXI4MMIOPassthrough ++
  new freechips.rocketchip.subsystem.WithCustomSlavePort(
    data_width = 256, id_bits = 5, source_bits = 7, fifo_bits = 5) ++
  new freechips.rocketchip.subsystem.WithCustomMMIOPort(
    base_addr = BigInt("10040000", 16), base_size = BigInt("200000", 16),
    data_width = 64, id_bits = 4, maxXferBytes = 64))

class WithMergedCompactL2 extends Config((site, here, up) => {
  case freechips.rocketchip.subsystem.InclusiveCacheKey =>
    // 64-byte lines / 32-byte beats = two beats per miss. memCycles=8
    // provided only four ordinary MSHRs shared by all three DMA engines.
    // Size for 64 cycles (640 ns at 100 MHz): 32 ordinary + two coherence
    // MSHRs, and corresponding secondary/Put buffers. This is queue sizing,
    // not an extra cache access delay.
    up(freechips.rocketchip.subsystem.InclusiveCacheKey).copy(memCycles = 64)
})

/** Match the internal FBus beat to the 256-bit video DMA/PPU AXI interface. */
class WithMergedVideoFrontBus extends Config((site, here, up) => {
  case freechips.rocketchip.subsystem.FrontBusKey =>
    up(freechips.rocketchip.subsystem.FrontBusKey, site).copy(beatBytes = 32)
})

/** Keep the current Rocket-Chip interfaces with normal production semantics. */
class WithMergedVideoProductionRoCC extends Config((site, here, up) => {
  case freechips.rocketchip.tile.LoopConvIngressDebugEscapeKey => false
  // Keep the protocol fixes, but do not synthesize the large debug snapshot
  // fabric used only by the standalone bring-up program.
  case freechips.rocketchip.tile.RoCCBusyWriteBypassCSRsKey => Seq.empty[Int]
  case freechips.rocketchip.tile.RoCCMbusBypassPorts => Map.empty[Int, Set[Int]]
})
