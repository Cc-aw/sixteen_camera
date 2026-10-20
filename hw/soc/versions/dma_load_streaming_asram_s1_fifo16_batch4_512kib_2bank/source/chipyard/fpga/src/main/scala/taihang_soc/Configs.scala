package tsmcchip.fpga.taihangsoc

import chisel3.Data
import org.chipsalliance.cde.config.{Config, Parameters}

import org.chipsalliance.diplomacy.lazymodule.LazyModule
import freechips.rocketchip.tile.{LazyRoCC, LoopConvIngressDebugEscapeKey, OpcodeSet, RoCCBusyWriteBypassCSRsKey}
import freechips.rocketchip.devices.debug.DebugModuleKey

import gemmini.{Arithmetic, CapacityInKilobytes, Dataflow, Gemmini, GemminiArrayConfig}
import saturn.common.VectorParams

import chipyard.config.MultiRoCCKey

class WithNoDebugClockGate extends Config((site, here, up) => {
  case DebugModuleKey => up(DebugModuleKey).map(_.copy(clockGate = false))
})

/** IPOAT：仅供双 4x4 卡死定位配置使用的冻结后逃生开关
  * I（Input 输入）：诊断配置的显式启用。
  * P（Process 处理）：启用 blocked-RUN 逃生，并仅对白名单中的两组 debug control/select CSR
  *                  取消 RoCC busy 写阻塞；其他 SoC 配置继续使用默认关闭/空白名单。
  * O（Output 输出）：自动快照锁存后允许 Rocket 越过被阻塞且被丢弃的 RUN，并逐页导出快照。
  * A（Author 作者）：王志瑞
  * T（Time 时间）：2026-09-18
  */
class WithLoopConvIngressDebugEscape extends Config((site, here, up) => {
  case LoopConvIngressDebugEscapeKey => true
  case RoCCBusyWriteBypassCSRsKey => Seq(0x7ca, 0x7cc, 0x7d0, 0x7d2)
})

/** Taihang FPGA external interfaces with SPI deliberately omitted. */
class WithTaihangSoCNoSPITweaks(
  freqMHz: Double = 100.0,
  ddrSize: BigInt = BigInt(4) << 30,
  memDataBits: Int = 256,
) extends Config(
  new WithTaihangAXI4MemPassthrough ++
  new WithTaihangAXI4MMIOPassthrough ++
  new WithTaihangUARTPassthrough ++
  new WithTaihangAXI4MemPunchthrough ++
  new WithTaihangUARTPunchthrough ++
  new WithTaihangJTAGTunnelDebug ++
  new freechips.rocketchip.subsystem.WithNBitMemoryBus(memDataBits) ++
  new chipyard.harness.WithHarnessBinderClockFreqMHz(freqMHz) ++
  new chipyard.harness.WithAllClocksFromHarnessClockInstantiator ++
  new chipyard.config.WithUniformBusFrequencies(freqMHz) ++
  new chipyard.clocking.WithPassthroughClockGenerator ++
  new chipyard.config.WithUART(
    baudrate = 115200,
    address = 0x10020000,
    txEntries = 64,
    rxEntries = 64,
  ) ++
  new chipyard.config.WithNoUART ++
  new testchipip.serdes.WithNoSerialTL ++
  new freechips.rocketchip.subsystem.WithExtMemSize(ddrSize) ++
  new freechips.rocketchip.subsystem.WithoutTLMonitors)

/** Resource-reduced Gemmini instances for initial FPGA functional validation. */
object TaihangSoCGemminiConfigs {
  private val baseConfig = gemmini.GemminiConfigs.defaultConfig.copy(
    tileRows = 1,
    tileColumns = 1,
    meshRows = 4,
    meshColumns = 4,

    sp_capacity = CapacityInKilobytes(64),
    acc_capacity = CapacityInKilobytes(32),
    sp_banks = 2,
    acc_banks = 2,

    reservation_station_entries_ld = 8,
    reservation_station_entries_st = 4,
    reservation_station_entries_ex = 8,

    ld_queue_length = 8,
    st_queue_length = 4,
    ex_queue_length = 8,

    max_in_flight_mem_reqs = 8,
    dma_maxbytes = 64,
    dma_buswidth = 256,
    tlb_size = 4,
  )

  val gemmini0Config = baseConfig.copy(
    opcodes = OpcodeSet.custom3,
    busyCsrId = Some(0x7c2),
    headerFileName = "gemmini_params_taihang_4x4_gemmini0.h",
  )

  val gemmini1Config = baseConfig.copy(
    opcodes = OpcodeSet.custom2,
    busyCsrId = Some(0x7c3),
    headerFileName = "gemmini_params_taihang_4x4_gemmini1.h",
  )

  val gemmini2Config = baseConfig.copy(
    opcodes = OpcodeSet.custom1,
    busyCsrId = Some(0x7c4),
    headerFileName = "gemmini_params_taihang_4x4_gemmini2.h",
  )

  private[taihangsoc] def builder[T <: Data : Arithmetic, U <: Data, V <: Data](
    config: GemminiArrayConfig[T, U, V],
  ): Parameters => LazyRoCC = { p: Parameters =>
    implicit val q: Parameters = p
    LazyModule(new Gemmini(config))
  }
}

/** WS-only 32x32 Gemmini instances derived from the XCVU13P 64x64 policy. */
object TaihangSoC32GemminiConfigs {
  private val baseConfig = gemmini.GemminiConfigs.defaultConfig.copy(
    tileRows = 1,
    tileColumns = 1,
    meshRows = 32,
    meshColumns = 32,
    dataflow = Dataflow.WS,
    use_dsp_mac_blackbox = true,
    // TinyYOLOv2's conv0-4/6-7 descriptors rely on Gemmini's fused
    // stride-2 pooling, while the activation field requests LeakyReLU.
    // Keep WS dataflow, but retain these output-stage capabilities so the
    // generated hardware matches the existing software contract.
    has_max_pool = true,
    has_nonlinear_activations = true,
    sp_capacity = CapacityInKilobytes(512),
    acc_capacity = CapacityInKilobytes(128),
    sp_banks = 8,
    acc_banks = 4,
    reservation_station_entries_ld = 16,
    reservation_station_entries_st = 8,
    reservation_station_entries_ex = 32,
    ld_queue_length = 16,
    st_queue_length = 8,
    ex_queue_length = 16,
    max_in_flight_mem_reqs = 32,
    dma_maxbytes = 64,
    dma_buswidth = 256,
    tlb_size = 4,
  )

  val gemmini0Config = baseConfig.copy(
    opcodes = OpcodeSet.custom3,
    busyCsrId = Some(0x7c2),
    headerFileName = "gemmini_params_taihang_32x32_gemmini0.h",
  )

  val gemmini1Config = baseConfig.copy(
    opcodes = OpcodeSet.custom2,
    busyCsrId = Some(0x7c3),
    headerFileName = "gemmini_params_taihang_32x32_gemmini1.h",
  )

  val gemmini2Config = baseConfig.copy(
    opcodes = OpcodeSet.custom1,
    busyCsrId = Some(0x7c4),
    headerFileName = "gemmini_params_taihang_32x32_gemmini2.h",
  )

  private[taihangsoc] def builder[T <: Data : Arithmetic, U <: Data, V <: Data](
    config: GemminiArrayConfig[T, U, V],
  ): Parameters => LazyRoCC = { p: Parameters =>
    implicit val q: Parameters = p
    LazyModule(new Gemmini(config))
  }
}

/**
  * Logical 128x128 WS Gemmini using two signed INT8 MACs per DSP48E2.
  *
  * The physical mesh has 128 rows and 64 columns. Each tile contains two
  * columns, preserving Gemmini's logical DIM=128 software interface while
  * halving the DSP count relative to an unpacked 128x128 array.
  */
object TaihangSoC128GemminiConfig {
  val config = gemmini.GemminiConfigs.defaultConfig.copy(
    tileRows = 1,
    tileColumns = 2,
    meshRows = 128,
    meshColumns = 64,

    dataflow = Dataflow.WS,
    use_dsp_mac_blackbox = false,
    use_dsp_mac_packing = true,

    // TinyYOLOv2 requires fused pooling and nonlinear activation support.
    has_max_pool = true,
    has_nonlinear_activations = true,

    sp_capacity = CapacityInKilobytes(512),
    acc_capacity = CapacityInKilobytes(256),
    sp_banks = 8,
    acc_banks = 4,

    reservation_station_entries_ld = 16,
    reservation_station_entries_st = 8,
    reservation_station_entries_ex = 32,

    ld_queue_length = 16,
    st_queue_length = 8,
    ex_queue_length = 16,

    max_in_flight_mem_reqs = 32,
    dma_maxbytes = 64,
    dma_buswidth = 256,

    tlb_size = 8,
    headerFileName = "gemmini_params_taihang_128x128_packed_fullops.h",
  )
}

/** Logical 64x64 WS Gemmini using the same dual-INT8 DSP packing scheme. */
object TaihangSoC64GemminiConfig {
  val config = TaihangSoC128GemminiConfig.config.copy(
    meshRows = 64,
    meshColumns = 32,
    headerFileName = "gemmini_params_taihang_64x64_packed_fullops.h",
  )
}

/** Performance-tuned single-instance 64x64 configuration. */
object TaihangSoC64SingleGemminiConfig {
  val config = TaihangSoC64GemminiConfig.config.copy(
    sp_capacity = CapacityInKilobytes(512),
    sp_banks = 8,
    acc_capacity = CapacityInKilobytes(256),
    acc_banks = 4,

    reservation_station_entries_ld = 16,
    reservation_station_entries_st = 8,
    reservation_station_entries_ex = 16,
    ld_queue_length = 16,
    st_queue_length = 8,
    ex_queue_length = 16,

    max_in_flight_mem_reqs = 32,
    use_tlb = false,
    use_transposer = false,
    has_training_convs = false,
    has_max_pool = true,

    // Keep the FP32 accumulator-scale ABI used by the generated Gemmini C
    // headers and YOLOv5nu quantization constants. Only replicate the scale
    // units; changing multiplicand_t to Float(5, 11) makes hardware consume
    // the low 16 bits of each FP32 scale as an unrelated FP16 value.
    acc_scale_args = TaihangSoC64GemminiConfig.config.acc_scale_args.map(
      _.copy(num_scale_units = 64)),

    // Export the same LoopConv credit-admission ABI used by the verified N6
    // software. The datapath, memory sizes, queues and scale implementation
    // remain those of TaihangSoC64SingleGemminiConfig.
    opcodes = OpcodeSet.custom3,
    busyCsrId = Some(0x7c2),
    loopConvStatusCsrId = Some(0x7c4),
    loopConvAcceptedCsrId = Some(0x7c6),
    loopConvRetiredCsrId = Some(0x7c7),
    loopConvSafeMax = 4,

    headerFileName =
      "gemmini_params_taihang_64x64_single_fp32scale64_physical.h",
  )
}

/** Two independent instances of the latest performance-tuned 64x64 Gemmini. */
object TaihangSoC64DualGemminiConfigs {
  private val baseConfig = TaihangSoC64SingleGemminiConfig.config

  val gemmini0Config = baseConfig.copy(
    opcodes = OpcodeSet.custom3,
    busyCsrId = Some(0x7c2),
    loopConvStatusCsrId = Some(0x7c4),
    loopConvAcceptedCsrId = Some(0x7c6),
    loopConvRetiredCsrId = Some(0x7c7),
    deadlockDebugControlCsrId = Some(0x7ca),
    deadlockDebugStatusCsrId = Some(0x7cb),
    deadlockDebugSelectCsrId = Some(0x7cc),
    deadlockDebugDataCsrId = Some(0x7cd),
    headerFileName =
      "gemmini_params_taihang_64x64_single_fp32scale64_gemmini0.h",
  )

  val gemmini1Config = baseConfig.copy(
    opcodes = OpcodeSet.custom2,
    busyCsrId = Some(0x7c3),
    loopConvStatusCsrId = Some(0x7c5),
    loopConvAcceptedCsrId = Some(0x7c8),
    loopConvRetiredCsrId = Some(0x7c9),
    deadlockDebugControlCsrId = Some(0x7d0),
    deadlockDebugStatusCsrId = Some(0x7d1),
    deadlockDebugSelectCsrId = Some(0x7d2),
    deadlockDebugDataCsrId = Some(0x7d3),
    headerFileName =
      "gemmini_params_taihang_64x64_single_fp32scale64_gemmini1.h",
  )

  private[taihangsoc] def builder[T <: Data : Arithmetic, U <: Data, V <: Data](
    config: GemminiArrayConfig[T, U, V],
  ): Parameters => LazyRoCC = { p: Parameters =>
    implicit val q: Parameters = p
    LazyModule(new Gemmini(config))
  }
}

/**
  * One logical 64x64 Gemmini tuned for true multi-batch inference.
  *
  * A 64-column INT32 accumulator row is 256 bytes wide. 512 KiB therefore
  * provides 2048 rows, of which the convolution tiler can use 1024 while
  * double buffering. This gives batch=2 twice the resident output-tile space
  * of the older 256 KiB configuration without changing accumulation width.
  */
object TaihangSoC64Batch2GemminiConfig {
  val config = TaihangSoC64GemminiConfig.config.copy(
    dataflow = Dataflow.WS,
    use_dsp_mac_blackbox = false,
    use_dsp_mac_packing = true,

    sp_capacity = CapacityInKilobytes(512),
    acc_capacity = CapacityInKilobytes(512),
    sp_banks = 8,
    acc_banks = 4,

    has_training_convs = false,
    has_max_pool = true,
    has_nonlinear_activations = true,
    has_dw_convs = false,
    has_normalizations = false,
    has_first_layer_optimizations = true,
    has_loop_conv = true,
    use_transposer = false,

    acc_read_full_width = true,
    acc_read_small_width = true,
    ex_read_from_spad = true,
    ex_read_from_acc = true,
    ex_write_to_spad = true,
    ex_write_to_acc = true,

    // Retain the programmable Chisel SiLU LUT while sharing the expensive
    // HardFloat scale datapath across eight lanes.
    acc_scale_args = TaihangSoC64GemminiConfig.config.acc_scale_args.map(
      _.copy(num_scale_units = 8)),

    opcodes = OpcodeSet.custom3,
    busyCsrId = Some(0x7c2),
    loopConvStatusCsrId = Some(0x7c4),
    loopConvAcceptedCsrId = Some(0x7c6),
    loopConvRetiredCsrId = Some(0x7c7),
    // IPOAE-A（Author 作者：王志瑞）：64x64 Batch2 LoopConv LOAD2 UART 诊断记录器。
    loopConvTraceControlCsrId = Some(0x7ca),
    loopConvTraceStatusCsrId = Some(0x7cb),
    loopConvTraceSelectCsrId = Some(0x7cc),
    loopConvTraceDataCsrId = Some(0x7cd),
    loopConvSafeMax = 4,
    headerFileName =
      "gemmini_params_taihang_64x64_packed_batch2_acc512.h",
  )
}

/** Three independent logical 64x64 WS Gemminis using dual-INT8 DSP packing. */
object TaihangSoC64GemminiConfigs {
  private val baseConfig = TaihangSoC64GemminiConfig.config

  val gemmini0Config = baseConfig.copy(
    opcodes = OpcodeSet.custom3,
    busyCsrId = Some(0x7c2),
    headerFileName = "gemmini_params_taihang_64x64_packed_gemmini0.h",
  )

  val gemmini1Config = baseConfig.copy(
    opcodes = OpcodeSet.custom2,
    busyCsrId = Some(0x7c3),
    headerFileName = "gemmini_params_taihang_64x64_packed_gemmini1.h",
  )

  val gemmini2Config = baseConfig.copy(
    opcodes = OpcodeSet.custom1,
    busyCsrId = Some(0x7c4),
    headerFileName = "gemmini_params_taihang_64x64_packed_gemmini2.h",
  )

  private[taihangsoc] def builder[T <: Data : Arithmetic, U <: Data, V <: Data](
    config: GemminiArrayConfig[T, U, V],
  ): Parameters => LazyRoCC = { p: Parameters =>
    implicit val q: Parameters = p
    LazyModule(new Gemmini(config))
  }
}

/** Logical 16x16 WS Gemmini using the same dual-INT8 DSP packing scheme. */
object TaihangSoC16GemminiConfig {
  val config = TaihangSoC64GemminiConfig.config.copy(
    meshRows = 16,
    meshColumns = 8,
    // Fixed-WS inference configuration for TinyYOLOv2 and YOLOv5nu.
    has_training_convs = false,
    has_dw_convs = false,
    use_transposer = false,
    // Share eight HardFloat accumulator-scale lanes across the logical
    // 16-column output. This halves the scale hardware while preserving the
    // configured eight-cycle external scale latency.
    acc_scale_args = gemmini.GemminiConfigs.defaultConfig.acc_scale_args.map(
      _.copy(num_scale_units = 8)),
    headerFileName = "gemmini_params_taihang_16x16_packed_fullops.h",
  )
}

/** Two logical 16x16 WS Gemminis attached to hart 0 for fast FPGA bring-up. */
object TaihangSoC16GemminiConfigs {
  private val baseConfig = TaihangSoC16GemminiConfig.config

  val gemmini0Config = baseConfig.copy(
    opcodes = OpcodeSet.custom3,
    busyCsrId = Some(0x7c2),
    // IPOAE-A（Author 作者：王志瑞）：worker0 的 LoopConv request-credit 状态 CSR；与 0x7c2 busy
    // 分离，软件可在 CONFIG1 前实施滑动窗口 admission。
    loopConvStatusCsrId = Some(0x7c4),
    // IPOAE-A（Author 作者：王志瑞）：worker0 request-credit debug counters。
    loopConvAcceptedCsrId = Some(0x7c6),
    loopConvRetiredCsrId = Some(0x7c7),
    // LOAD2 address-path snapshot, readable by hart 0 for UART diagnostics.
    // 0x7ca..0x7cd are unused by the dual-16 configuration and are attached
    // only to custom3/gemmini0; custom2/gemmini1 keeps its existing CSR ABI.
    loopConvTraceControlCsrId = Some(0x7ca),
    loopConvTraceStatusCsrId = Some(0x7cb),
    loopConvTraceSelectCsrId = Some(0x7cc),
    loopConvTraceDataCsrId = Some(0x7cd),
    loopConvSafeMax = 4,
    headerFileName = "gemmini_params_taihang_16x16_packed_gemmini0.h",
  )

  val gemmini1Config = baseConfig.copy(
    opcodes = OpcodeSet.custom2,
    busyCsrId = Some(0x7c3),
    // IPOAE-A（Author 作者：王志瑞）：worker1 独立状态 CSR，不能复用 worker0 的 0x7c4。
    loopConvStatusCsrId = Some(0x7c5),
    // IPOAE-A（Author 作者：王志瑞）：worker1 独立计数，禁止与 worker0 拼接或共享。
    loopConvAcceptedCsrId = Some(0x7c8),
    loopConvRetiredCsrId = Some(0x7c9),
    loopConvSafeMax = 4,
    headerFileName = "gemmini_params_taihang_16x16_packed_gemmini1.h",
  )

  private[taihangsoc] def builder[T <: Data : Arithmetic, U <: Data, V <: Data](
    config: GemminiArrayConfig[T, U, V],
  ): Parameters => LazyRoCC = { p: Parameters =>
    implicit val q: Parameters = p
    LazyModule(new Gemmini(config))
  }
}

/** One packed 4x4 worker retaining the production worker0 opcode and CSR ABI. */
object TaihangSoCOne4x4GemminiConfig {
  val config = TaihangSoC16GemminiConfigs.gemmini0Config.copy(
    tileRows = 1,
    tileColumns = 2,
    meshRows = 4,
    meshColumns = 2,
    acc_scale_args = gemmini.GemminiConfigs.defaultConfig.acc_scale_args.map(
      _.copy(num_scale_units = 4)),
    headerFileName = "gemmini_params_taihang_single_4x4_packed.h",
  )
}

/** IPOAT：双 4x4 LoopConv 死锁诊断 Gemmini 参数
  * I（Input 输入）：Taihang 双 16x16 packed/full-ops 参数、两条独立 opcode 路由和 SAFE=4 契约。
  * P（Process 处理）：仅把逻辑阵列缩为 4x4（物理 4x2、每 PE 双列打包），保留两个 LoopConv slot、
  *                  RS/DMA/AccScale 策略，并给每颗 Gemmini 分配独立的 32 页诊断 CSR 窗口。
  * O（Output 输出）：custom3/custom2 两颗互不共享状态的 4x4 Gemmini 配置。
  * A（Author 作者）：王志瑞
  * T（Time 时间）：2026-09-17
  */
object TaihangSoC4x4LoopConvDebugGemminiConfigs {
  private val baseConfig = TaihangSoC16GemminiConfig.config.copy(
    tileRows = 1,
    tileColumns = 2,
    meshRows = 4,
    meshColumns = 2,
    acc_scale_args = gemmini.GemminiConfigs.defaultConfig.acc_scale_args.map(
      _.copy(num_scale_units = 4)),
  )

  val gemmini0Config = baseConfig.copy(
    opcodes = OpcodeSet.custom3,
    busyCsrId = Some(0x7c2),
    loopConvStatusCsrId = Some(0x7c4),
    loopConvAcceptedCsrId = Some(0x7c6),
    loopConvRetiredCsrId = Some(0x7c7),
    loopConvTraceControlCsrId = None,
    loopConvTraceStatusCsrId = None,
    loopConvTraceSelectCsrId = None,
    loopConvTraceDataCsrId = None,
    deadlockDebugControlCsrId = Some(0x7ca),
    deadlockDebugStatusCsrId = Some(0x7cb),
    deadlockDebugSelectCsrId = Some(0x7cc),
    deadlockDebugDataCsrId = Some(0x7cd),
    loopConvSafeMax = 4,
    headerFileName = "gemmini_params_taihang_4x4_loopconv_debug_gemmini0.h",
  )

  val gemmini1Config = baseConfig.copy(
    opcodes = OpcodeSet.custom2,
    busyCsrId = Some(0x7c3),
    loopConvStatusCsrId = Some(0x7c5),
    loopConvAcceptedCsrId = Some(0x7c8),
    loopConvRetiredCsrId = Some(0x7c9),
    deadlockDebugControlCsrId = Some(0x7d0),
    deadlockDebugStatusCsrId = Some(0x7d1),
    deadlockDebugSelectCsrId = Some(0x7d2),
    deadlockDebugDataCsrId = Some(0x7d3),
    loopConvSafeMax = 4,
    headerFileName = "gemmini_params_taihang_4x4_loopconv_debug_gemmini1.h",
  )

  private[taihangsoc] def builder[T <: Data : Arithmetic, U <: Data, V <: Data](
    config: GemminiArrayConfig[T, U, V],
  ): Parameters => LazyRoCC = { p: Parameters =>
    implicit val q: Parameters = p
    LazyModule(new Gemmini(config))
  }
}

/**
  * Instantiate exactly three Gemminis: two on hart 0 and one on hart 1.
  * RoCC accelerators are tile-local, so this avoids duplicating the pool on
  * both harts while still exercising accelerator access from each Rocket.
  */
class WithTaihangSoCThreeGemmini extends Config((site, here, up) => {
  case MultiRoCCKey => up(MultiRoCCKey) ++ Map(
    0 -> Seq(
      TaihangSoCGemminiConfigs.builder(TaihangSoCGemminiConfigs.gemmini0Config),
      TaihangSoCGemminiConfigs.builder(TaihangSoCGemminiConfigs.gemmini1Config),
    ),
    1 -> Seq(
      TaihangSoCGemminiConfigs.builder(TaihangSoCGemminiConfigs.gemmini2Config),
    ),
  )
})

/** Attach the two 4x4 Gemminis under test to the only hart 0 tile. */
class WithTaihangSoCTwoGemminiSingleHart extends Config((site, here, up) => {
  case MultiRoCCKey => up(MultiRoCCKey) ++ Map(
    0 -> Seq(
      TaihangSoCGemminiConfigs.builder(TaihangSoCGemminiConfigs.gemmini0Config),
      TaihangSoCGemminiConfigs.builder(TaihangSoCGemminiConfigs.gemmini1Config),
    ),
  )
})

/** Attach two 32x32 Gemminis to hart 0 and one to hart 1. */
class WithTaihangSoCThree32Gemmini extends Config((site, here, up) => {
  case MultiRoCCKey => up(MultiRoCCKey) ++ Map(
    0 -> Seq(
      TaihangSoC32GemminiConfigs.builder(TaihangSoC32GemminiConfigs.gemmini0Config),
      TaihangSoC32GemminiConfigs.builder(TaihangSoC32GemminiConfigs.gemmini1Config),
    ),
    1 -> Seq(
      TaihangSoC32GemminiConfigs.builder(TaihangSoC32GemminiConfigs.gemmini2Config),
    ),
  )
})

/** Attach all three 32x32 Gemminis to the single available hart 0 tile. */
class WithTaihangSoCThree32GemminiSingleHart extends Config((site, here, up) => {
  case MultiRoCCKey => up(MultiRoCCKey) ++ Map(
    0 -> Seq(
      TaihangSoC32GemminiConfigs.builder(TaihangSoC32GemminiConfigs.gemmini0Config),
      TaihangSoC32GemminiConfigs.builder(TaihangSoC32GemminiConfigs.gemmini1Config),
      TaihangSoC32GemminiConfigs.builder(TaihangSoC32GemminiConfigs.gemmini2Config),
    ),
  )
})

/** Attach all three packed 64x64 Gemminis to the single Rocket tile. */
class WithTaihangSoCThree64GemminiSingleHart extends Config((site, here, up) => {
  case MultiRoCCKey => up(MultiRoCCKey) ++ Map(
    0 -> Seq(
      TaihangSoC64GemminiConfigs.builder(TaihangSoC64GemminiConfigs.gemmini0Config),
      TaihangSoC64GemminiConfigs.builder(TaihangSoC64GemminiConfigs.gemmini1Config),
      TaihangSoC64GemminiConfigs.builder(TaihangSoC64GemminiConfigs.gemmini2Config),
    ),
  )
})

/** Attach both performance-tuned packed 64x64 Gemminis to hart 0. */
class WithTaihangSoCTwo64GemminiSingleHart extends Config((site, here, up) => {
  case MultiRoCCKey => up(MultiRoCCKey) ++ Map(
    0 -> Seq(
      TaihangSoC64DualGemminiConfigs.builder(TaihangSoC64DualGemminiConfigs.gemmini0Config),
      TaihangSoC64DualGemminiConfigs.builder(TaihangSoC64DualGemminiConfigs.gemmini1Config),
    ),
  )
})

/** Attach gemmini0 and gemmini1 to the only available hart 0 tile. */
class WithTaihangSoCTwo32GemminiSingleHart extends Config((site, here, up) => {
  case MultiRoCCKey => up(MultiRoCCKey) ++ Map(
    0 -> Seq(
      TaihangSoC32GemminiConfigs.builder(TaihangSoC32GemminiConfigs.gemmini0Config),
      TaihangSoC32GemminiConfigs.builder(TaihangSoC32GemminiConfigs.gemmini1Config),
    ),
  )
})

/** Attach two packed 16x16 Gemminis to the only available hart 0 tile. */
class WithTaihangSoCTwo16GemminiSingleHart extends Config((site, here, up) => {
  case MultiRoCCKey => up(MultiRoCCKey) ++ Map(
    0 -> Seq(
      TaihangSoC16GemminiConfigs.builder(TaihangSoC16GemminiConfigs.gemmini0Config),
      TaihangSoC16GemminiConfigs.builder(TaihangSoC16GemminiConfigs.gemmini1Config),
    ),
  )
})

/** Attach the production-compatible worker0 alone to hart 0. */
class WithTaihangSoCOne4x4GemminiSingleHart extends Config((site, here, up) => {
  case MultiRoCCKey => up(MultiRoCCKey) ++ Map(
    0 -> Seq(TaihangSoC16GemminiConfigs.builder(TaihangSoCOne4x4GemminiConfig.config)),
  )
})

/** IPOAT：单 hart 双 4x4 诊断挂接
  * I（Input 输入）：MultiRoCCKey 与两颗诊断 Gemmini builder。
  * P（Process 处理）：按 custom3、custom2 顺序挂到 hart 0，与双 16x16 拓扑一致。
  * O（Output 输出）：hart 0 上两条独立 RoCC 路由。
  * A（Author 作者）：王志瑞
  * T（Time 时间）：2026-09-17
  */
class WithTaihangSoCTwo4x4LoopConvDebugGemminiSingleHart extends Config((site, here, up) => {
  case MultiRoCCKey => up(MultiRoCCKey) ++ Map(
    0 -> Seq(
      TaihangSoC4x4LoopConvDebugGemminiConfigs.builder(TaihangSoC4x4LoopConvDebugGemminiConfigs.gemmini0Config),
      TaihangSoC4x4LoopConvDebugGemminiConfigs.builder(TaihangSoC4x4LoopConvDebugGemminiConfigs.gemmini1Config),
    ),
  )
})

/**
  * Bring-up configuration retaining DDR, UART, MMIO, coherent DMA and JTAG.
  * It removes SPI and uses
  * two Rocket+RVV tiles with a total of three resource-reduced 4x4 Gemminis.
  */
class TaihangSoC2Rocket2RVV3Gemmini4x4Config extends Config(
  new WithNoDebugClockGate ++
  new WithTaihangAXI4InPassthrough ++
  new WithTaihangSoCNoSPITweaks(freqMHz = 100.0, memDataBits = 256) ++
  new freechips.rocketchip.subsystem.WithCustomSlavePort(
    data_width = 256,
    id_bits = 4,
  ) ++
  new freechips.rocketchip.subsystem.WithCustomMMIOPort(
    // Match the legacy video MMIO ABI. The FPGA fabric decodes the complete
    // 16 MiB aperture beginning at 0x40000000 (GPIO through camera blocks).
    base_addr = BigInt("40000000", 16),
    base_size = BigInt("1000000", 16),
    data_width = 64,
    id_bits = 4,
    maxXferBytes = 64,
  ) ++
  new chipyard.config.WithMultiRoCC ++
  new WithTaihangSoCThreeGemmini ++
  new saturn.rocket.WithRocketVectorUnit(
    vLen = 128,
    dLen = 64,
    params = VectorParams(),
    cores = Some(Seq(0, 1)),
    useL1DCache = true,
  ) ++
  new freechips.rocketchip.rocket.WithNHugeCores(2) ++
  new chipyard.config.WithSystemBusWidth(256) ++
  new chipyard.config.AbstractConfig)

/** Verilator harness for the 4x4 bring-up design.
  *
  * The FPGA configuration exposes memory, MMIO, UART, and the coherent F-Bus
  * as top-level pins. Override only those harness connections so the standard
  * Chipyard TestHarness can load and run a bare-metal ELF.
  */
class TaihangSoC1Rocket1RVV2Gemmini4x4Config extends Config(
  new WithNoDebugClockGate ++
  new WithTaihangAXI4InPassthrough ++
  new WithTaihangSoCNoSPITweaks(freqMHz = 100.0, memDataBits = 256) ++
  new freechips.rocketchip.subsystem.WithCustomSlavePort(
    data_width = 256,
    id_bits = 4,
  ) ++
  new freechips.rocketchip.subsystem.WithCustomMMIOPort(
    // Match the legacy video MMIO ABI and expose the complete 16 MiB fabric aperture.
    base_addr = BigInt("40000000", 16),
    base_size = BigInt("1000000", 16),
    data_width = 64,
    id_bits = 4,
    maxXferBytes = 64,
  ) ++
  new chipyard.config.WithMultiRoCC ++
  new WithTaihangSoCTwoGemminiSingleHart ++
  new saturn.rocket.WithRocketVectorUnit(
    vLen = 128,
    dLen = 64,
    params = VectorParams(),
    cores = Some(Seq(0)),
    useL1DCache = true,
  ) ++
  new freechips.rocketchip.rocket.WithNHugeCores(1) ++
  new chipyard.config.WithSystemBusWidth(256) ++
  new chipyard.config.AbstractConfig)

class TaihangSoC1Rocket1RVV2Gemmini4x4SimConfig extends Config(
  new TaihangSoC1Rocket1RVV2Gemmini4x4Config ++
  new testchipip.boot.WithNoCustomBootPin ++
  new testchipip.serdes.WithSerialTL ++
  new chipyard.harness.WithAbsoluteFreqHarnessClockInstantiator ++
  new chipyard.iobinders.WithDebugIOCells ++
  new chipyard.harness.WithUARTAdapter ++
  new chipyard.harness.WithBlackBoxSimMem ++
  new chipyard.harness.WithSimAXIMMIO ++
  new chipyard.harness.WithTieOffL2FBusAXI)

/** Two Huge Rocket cores, two Saturn RVV units, and three WS-only 32x32 Gemminis. */
class TaihangSoC2Rocket2RVV3Gemmini32x32Config extends Config(
  new WithNoDebugClockGate ++
  new WithTaihangAXI4InPassthrough ++
  new WithTaihangSoCNoSPITweaks(freqMHz = 100.0, memDataBits = 256) ++
  new freechips.rocketchip.subsystem.WithCustomSlavePort(
    data_width = 256,
    id_bits = 4,
  ) ++
  new freechips.rocketchip.subsystem.WithCustomMMIOPort(
    base_addr = BigInt("10040000", 16),
    base_size = BigInt("1000", 16),
    data_width = 64,
    id_bits = 4,
    maxXferBytes = 64,
  ) ++
  new chipyard.config.WithMultiRoCC ++
  new WithTaihangSoCThree32Gemmini ++
  new saturn.rocket.WithRocketVectorUnit(
    vLen = 128,
    dLen = 64,
    params = VectorParams(),
    cores = Some(Seq(0, 1)),
    useL1DCache = true,
  ) ++
  new freechips.rocketchip.rocket.WithNHugeCores(2) ++
  new chipyard.config.WithSystemBusWidth(256) ++
  new chipyard.config.AbstractConfig)

/** One Huge Rocket, one Saturn RVV, and three WS-only 32x32 Gemminis. */
class TaihangSoC1Rocket1RVV3Gemmini32x32Config extends Config(
  new WithNoDebugClockGate ++
  new WithTaihangAXI4InPassthrough ++
  new WithTaihangSoCNoSPITweaks(freqMHz = 100.0, memDataBits = 256) ++
  new freechips.rocketchip.subsystem.WithCustomSlavePort(
    data_width = 256,
    id_bits = 4,
  ) ++
  new freechips.rocketchip.subsystem.WithCustomMMIOPort(
    base_addr = BigInt("10040000", 16),
    base_size = BigInt("1000", 16),
    data_width = 64,
    id_bits = 4,
    maxXferBytes = 64,
  ) ++
  new chipyard.config.WithMultiRoCC ++
  new WithTaihangSoCThree32GemminiSingleHart ++
  new saturn.rocket.WithRocketVectorUnit(
    vLen = 128,
    dLen = 64,
    params = VectorParams(),
    cores = Some(Seq(0)),
    useL1DCache = true,
  ) ++
  new freechips.rocketchip.rocket.WithNHugeCores(1) ++
  new chipyard.config.WithSystemBusWidth(256) ++
  new chipyard.config.AbstractConfig)

/** One Huge Rocket, one Saturn RVV, and two WS-only 32x32 Gemminis. */
class TaihangSoC1Rocket1RVV2Gemmini32x32Config extends Config(
  new WithNoDebugClockGate ++
  new WithTaihangAXI4InPassthrough ++
  new WithTaihangSoCNoSPITweaks(freqMHz = 100.0, memDataBits = 256) ++
  new freechips.rocketchip.subsystem.WithCustomSlavePort(
    data_width = 256,
    id_bits = 4,
  ) ++
  new freechips.rocketchip.subsystem.WithCustomMMIOPort(
    base_addr = BigInt("10040000", 16),
    base_size = BigInt("1000", 16),
    data_width = 64,
    id_bits = 4,
    maxXferBytes = 64,
  ) ++
  new chipyard.config.WithMultiRoCC ++
  new WithTaihangSoCTwo32GemminiSingleHart ++
  new saturn.rocket.WithRocketVectorUnit(
    vLen = 128,
    dLen = 64,
    params = VectorParams(),
    cores = Some(Seq(0)),
    useL1DCache = true,
  ) ++
  new freechips.rocketchip.rocket.WithNHugeCores(1) ++
  new chipyard.config.WithSystemBusWidth(256) ++
  new chipyard.config.AbstractConfig)

/**
  * Preferred Taihang TinyYOLOv2 configuration: one Huge Rocket, one
  * DSP-oriented Saturn RVV unit, and one packed FullOps 128x128 Gemmini.
  */
class TaihangSoC1Rocket1RVV1Gemmini128x128PackedFullOpsConfig extends Config(
  new WithNoDebugClockGate ++
  new WithTaihangAXI4InPassthrough ++
  new WithTaihangSoCNoSPITweaks(freqMHz = 100.0, memDataBits = 512) ++
  new freechips.rocketchip.subsystem.WithCustomSlavePort(
    data_width = 512,
    id_bits = 4,
  ) ++
  new freechips.rocketchip.subsystem.WithCustomMMIOPort(
    base_addr = BigInt("10040000", 16),
    base_size = BigInt("1000", 16),
    data_width = 64,
    id_bits = 4,
    maxXferBytes = 64,
  ) ++
  new gemmini.DefaultGemminiConfig(TaihangSoC128GemminiConfig.config) ++
  new saturn.rocket.WithRocketVectorUnit(
    vLen = 256,
    dLen = 128,
    params = VectorParams.dspParams,
    cores = Some(Seq(0)),
    useL1DCache = true,
  ) ++
  new freechips.rocketchip.rocket.WithNHugeCores(1) ++
  new chipyard.config.WithSystemBusWidth(512) ++
  new chipyard.config.AbstractConfig)

/** 256-bit bus variant of the packed FullOps 128x128 Taihang configuration. */
class TaihangSoC1Rocket1RVV1Gemmini128x128PackedFullOps256BitConfig extends Config(
  new WithNoDebugClockGate ++
  new WithTaihangAXI4InPassthrough ++
  new WithTaihangSoCNoSPITweaks(freqMHz = 100.0, memDataBits = 256) ++
  new freechips.rocketchip.subsystem.WithCustomSlavePort(
    data_width = 256,
    id_bits = 4,
  ) ++
  new freechips.rocketchip.subsystem.WithCustomMMIOPort(
    base_addr = BigInt("10040000", 16),
    base_size = BigInt("1000", 16),
    data_width = 64,
    id_bits = 4,
    maxXferBytes = 64,
  ) ++
  new gemmini.DefaultGemminiConfig(TaihangSoC128GemminiConfig.config) ++
  new saturn.rocket.WithRocketVectorUnit(
    vLen = 256,
    dLen = 128,
    params = VectorParams.dspParams,
    cores = Some(Seq(0)),
    useL1DCache = true,
  ) ++
  new freechips.rocketchip.rocket.WithNHugeCores(1) ++
  new chipyard.config.WithSystemBusWidth(256) ++
  new chipyard.config.AbstractConfig)

/** One Huge Rocket, one Saturn RVV, and one packed FullOps 64x64 Gemmini. */
class TaihangSoC1Rocket1RVV1Gemmini64x64PackedFullOps256BitConfig extends Config(
  new WithNoDebugClockGate ++
  new WithTaihangAXI4InPassthrough ++
  new WithTaihangSoCNoSPITweaks(freqMHz = 100.0, memDataBits = 256) ++
  new freechips.rocketchip.subsystem.WithCustomSlavePort(
    data_width = 256,
    id_bits = 4,
  ) ++
  new freechips.rocketchip.subsystem.WithCustomMMIOPort(
    base_addr = BigInt("10040000", 16),
    base_size = BigInt("1000", 16),
    data_width = 64,
    id_bits = 4,
    maxXferBytes = 64,
  ) ++
  new gemmini.DefaultGemminiConfig(TaihangSoC64SingleGemminiConfig.config) ++
  new saturn.rocket.WithRocketVectorUnit(
    vLen = 256,
    dLen = 128,
    params = VectorParams.dspParams,
    cores = Some(Seq(0)),
    useL1DCache = true,
  ) ++
  new freechips.rocketchip.rocket.WithNHugeCores(1) ++
  new chipyard.config.WithSystemBusWidth(256) ++
  new chipyard.config.AbstractConfig)

/** One Huge Rocket, one Saturn RVV, and two performance-tuned packed 64x64 Gemminis. */
class TaihangSoC1Rocket1RVV2Gemmini64x64PackedFullOps256BitConfig extends Config(
  new WithLoopConvIngressDebugEscape ++
  new WithTaihangPostprocessFrontBus ++
  new WithNoDebugClockGate ++
  new WithTaihangAXI4InPassthrough ++
  new WithTaihangSoCNoSPITweaks(freqMHz = 100.0, memDataBits = 256) ++
  new freechips.rocketchip.subsystem.WithCustomSlavePort(
    data_width = 256,
    id_bits = 5,
    source_bits = 7,
    fifo_bits = 5,
  ) ++
  new freechips.rocketchip.subsystem.WithCustomMMIOPort(
    base_addr = BigInt("10040000", 16),
    base_size = BigInt("200000", 16),
    data_width = 64,
    id_bits = 4,
    maxXferBytes = 64,
  ) ++
  new chipyard.config.WithMultiRoCC ++
  new WithTaihangSoCTwo64GemminiSingleHart ++
  new saturn.rocket.WithRocketVectorUnit(
    vLen = 256,
    dLen = 128,
    params = VectorParams.dspParams,
    cores = Some(Seq(0)),
    useL1DCache = true,
  ) ++
  new freechips.rocketchip.rocket.WithNHugeCores(1) ++
  new chipyard.config.WithSystemBusWidth(256) ++
  new chipyard.config.AbstractConfig)

/**
  * One Huge Rocket, one Saturn RVV, and one packed 64x64 Gemmini with a
  * 512-KiB accumulator for batch=2 convolution tiling.
  */
class TaihangSoC1Rocket1RVV1Gemmini64x64PackedBatch2FullOps256BitConfig extends Config(
  new WithNoDebugClockGate ++
  new WithTaihangAXI4InPassthrough ++
  new WithTaihangSoCNoSPITweaks(freqMHz = 100.0, memDataBits = 256) ++
  new freechips.rocketchip.subsystem.WithCustomSlavePort(
    data_width = 256,
    id_bits = 4,
  ) ++
  new freechips.rocketchip.subsystem.WithCustomMMIOPort(
    base_addr = BigInt("10040000", 16),
    base_size = BigInt("1000", 16),
    data_width = 64,
    id_bits = 4,
    maxXferBytes = 64,
  ) ++
  new gemmini.DefaultGemminiConfig(TaihangSoC64Batch2GemminiConfig.config) ++
  new saturn.rocket.WithRocketVectorUnit(
    vLen = 256,
    dLen = 128,
    params = VectorParams.dspParams,
    cores = Some(Seq(0)),
    useL1DCache = true,
  ) ++
  new freechips.rocketchip.rocket.WithNHugeCores(1) ++
  new chipyard.config.WithSystemBusWidth(256) ++
  new chipyard.config.AbstractConfig)

/** One Huge Rocket, one Saturn RVV, and one packed FullOps 16x16 Gemmini. */
class TaihangSoC1Rocket1RVV1Gemmini16x16PackedFullOps256BitConfig extends Config(
  new WithNoDebugClockGate ++
  new WithTaihangAXI4InPassthrough ++
  new WithTaihangSoCNoSPITweaks(freqMHz = 100.0, memDataBits = 256) ++
  new freechips.rocketchip.subsystem.WithCustomSlavePort(
    data_width = 256,
    id_bits = 4,
  ) ++
  new freechips.rocketchip.subsystem.WithCustomMMIOPort(
    base_addr = BigInt("10040000", 16),
    base_size = BigInt("200000", 16),
    data_width = 64,
    id_bits = 4,
    maxXferBytes = 64,
  ) ++
  new gemmini.DefaultGemminiConfig(TaihangSoC16GemminiConfig.config) ++
  new saturn.rocket.WithRocketVectorUnit(
    vLen = 256,
    dLen = 128,
    params = VectorParams.dspParams,
    cores = Some(Seq(0)),
    useL1DCache = true,
  ) ++
  new freechips.rocketchip.rocket.WithNHugeCores(1) ++
  new chipyard.config.WithSystemBusWidth(256) ++
  new chipyard.config.AbstractConfig)

/** One Huge Rocket, one Saturn RVV, and two packed FullOps 16x16 Gemminis. */
class WithTaihangPostprocessFrontBus extends Config((site, here, up) => {
  case freechips.rocketchip.subsystem.FrontBusKey =>
    up(freechips.rocketchip.subsystem.FrontBusKey, site).copy(beatBytes = 32)
})

class TaihangSoC1Rocket1RVV2Gemmini16x16PackedFullOps256BitConfig extends Config(
  new WithTaihangPostprocessFrontBus ++
  new WithNoDebugClockGate ++
  new WithTaihangAXI4InPassthrough ++
  new WithTaihangSoCNoSPITweaks(freqMHz = 100.0, memDataBits = 256) ++
  new freechips.rocketchip.subsystem.WithCustomSlavePort(
    data_width = 256,
    id_bits = 5,
    source_bits = 7,
    fifo_bits = 5,
  ) ++
  new freechips.rocketchip.subsystem.WithCustomMMIOPort(
    base_addr = BigInt("10040000", 16),
    base_size = BigInt("200000", 16),
    data_width = 64,
    id_bits = 4,
    maxXferBytes = 64,
  ) ++
  new chipyard.config.WithMultiRoCC ++
  new WithTaihangSoCTwo16GemminiSingleHart ++
  new saturn.rocket.WithRocketVectorUnit(
    vLen = 256,
    dLen = 128,
    params = VectorParams.dspParams,
    cores = Some(Seq(0)),
    useL1DCache = true,
  ) ++
  new freechips.rocketchip.rocket.WithNHugeCores(1) ++
  new chipyard.config.WithSystemBusWidth(256) ++
  new chipyard.config.AbstractConfig)

/** Production Taihang interfaces with one packed logical 4x4 Gemmini. */
class TaihangSoC1Rocket1RVV1Gemmini4x4PackedFullOps256BitConfig extends Config(
  new WithTaihangPostprocessFrontBus ++
  new WithNoDebugClockGate ++
  new WithTaihangAXI4InPassthrough ++
  new WithTaihangSoCNoSPITweaks(freqMHz = 100.0, memDataBits = 256) ++
  new freechips.rocketchip.subsystem.WithCustomSlavePort(
    data_width = 256,
    id_bits = 5,
    source_bits = 7,
    fifo_bits = 5,
  ) ++
  new freechips.rocketchip.subsystem.WithCustomMMIOPort(
    base_addr = BigInt("10040000", 16),
    base_size = BigInt("200000", 16),
    data_width = 64,
    id_bits = 4,
    maxXferBytes = 64,
  ) ++
  new chipyard.config.WithMultiRoCC ++
  new WithTaihangSoCOne4x4GemminiSingleHart ++
  new saturn.rocket.WithRocketVectorUnit(
    vLen = 256,
    dLen = 128,
    params = VectorParams.dspParams,
    cores = Some(Seq(0)),
    useL1DCache = true,
  ) ++
  new freechips.rocketchip.rocket.WithNHugeCores(1) ++
  new chipyard.config.WithSystemBusWidth(256) ++
  new chipyard.config.AbstractConfig)

/** IPOAT：双 4x4 LoopConv 死锁诊断 SoC
  * I（Input 输入）：已验证的 Taihang 双 16x16 FPGA 总线、单 Rocket/RVV 与前端总线拓扑。
  * P（Process 处理）：原样保留 256-bit 系统/前端总线，只替换为双 4x4 诊断 Gemmini 挂接。
  * O（Output 输出）：可由 taihang_soc FPGA harness 直接生成的诊断 RTL 配置。
  * A（Author 作者）：王志瑞
  * T（Time 时间）：2026-09-17
  */
class TaihangSoC1Rocket1RVV2Gemmini4x4LoopConvDebugConfig extends Config(
  new WithLoopConvIngressDebugEscape ++
  new WithTaihangPostprocessFrontBus ++
  new WithNoDebugClockGate ++
  new WithTaihangAXI4InPassthrough ++
  new WithTaihangSoCNoSPITweaks(freqMHz = 100.0, memDataBits = 256) ++
  new freechips.rocketchip.subsystem.WithCustomSlavePort(
    data_width = 256,
    id_bits = 5,
    source_bits = 7,
    fifo_bits = 5,
  ) ++
  new freechips.rocketchip.subsystem.WithCustomMMIOPort(
    base_addr = BigInt("10040000", 16),
    base_size = BigInt("200000", 16),
    data_width = 64,
    id_bits = 4,
    maxXferBytes = 64,
  ) ++
  new chipyard.config.WithMultiRoCC ++
  new WithTaihangSoCTwo4x4LoopConvDebugGemminiSingleHart ++
  new saturn.rocket.WithRocketVectorUnit(
    vLen = 256,
    dLen = 128,
    params = VectorParams.dspParams,
    cores = Some(Seq(0)),
    useL1DCache = true,
  ) ++
  new freechips.rocketchip.rocket.WithNHugeCores(1) ++
  new chipyard.config.WithSystemBusWidth(256) ++
  new chipyard.config.AbstractConfig)

/** One Huge Rocket, one Saturn RVV, and three independent packed 64x64 Gemminis. */
class TaihangSoC1Rocket1RVV3Gemmini64x64PackedFullOps256BitConfig extends Config(
  new WithNoDebugClockGate ++
  new WithTaihangAXI4InPassthrough ++
  new WithTaihangSoCNoSPITweaks(freqMHz = 100.0, memDataBits = 256) ++
  new freechips.rocketchip.subsystem.WithCustomSlavePort(
    data_width = 256,
    id_bits = 4,
  ) ++
  new freechips.rocketchip.subsystem.WithCustomMMIOPort(
    base_addr = BigInt("10040000", 16),
    base_size = BigInt("1000", 16),
    data_width = 64,
    id_bits = 4,
    maxXferBytes = 64,
  ) ++
  new chipyard.config.WithMultiRoCC ++
  new WithTaihangSoCThree64GemminiSingleHart ++
  new saturn.rocket.WithRocketVectorUnit(
    vLen = 256,
    dLen = 128,
    params = VectorParams.dspParams,
    cores = Some(Seq(0)),
    useL1DCache = true,
  ) ++
  new freechips.rocketchip.rocket.WithNHugeCores(1) ++
  new chipyard.config.WithSystemBusWidth(256) ++
  new chipyard.config.AbstractConfig)
