package tsmcchip.fpga.taihangsoc

import org.chipsalliance.cde.config.Config
import saturn.common.VectorParams

/** IPOAT：V03优化版单一板测候选参数
 * I（Input 输入）：既有Taihang DIM64 packed/FullOps Scale32参数。
 * P（Process 处理）：选择N6 chunked调度，启用VI及跨行；保留原请求资格判断，使用独立参数头名称。
 * O（Output 输出）：供独立候选SoC使用的Gemmini配置；原配置默认值不变。
 * A（Author 作者）：王志瑞
 * T（Time 时间）：2026-09-09
 */
object TaihangSoC64V03OptimizedGemminiConfig {
  val config = TaihangSoC64Batch2Scale32GemminiConfig.config.copy(
    acc_scale_n_entries = 6,
    acc_scale_scheduler = "chunked_no_norm",
    virtual_i_enable = true,
    virtual_i_cross_row = true,
    headerFileName = "gemmini_params_taihang_64x64_packed_batch2_acc512_scale32_n6_v03opt.h")
  require(config.meshRows * config.tileRows == 64 && config.meshColumns * config.tileColumns == 64)
  require(config.use_dsp_mac_packing && config.acc_scale_args.get.num_scale_units == 32)
  require(!config.acc_scale_perf_enable)
}

/** IPOAT：V03优化版完整SoC生成入口
 * I（Input 输入）：固定的V03候选参数及原100MHz/256bit Taihang平台配置。
 * P（Process 处理）：复用原Scale32窗口配置的SoC组成，仅替换单个Gemmini参数。
 * O（Output 输出）：独立命名的RTL候选；不覆盖旧生成目录或原比特流。
 * A（Author 作者）：王志瑞
 * T（Time 时间）：2026-09-09
 */
class TaihangSoC1Rocket1RVV1Gemmini64x64PackedBatch2Scale32N6V03OptimizedFullOps256BitConfig extends Config(
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
  new gemmini.DefaultGemminiConfig(TaihangSoC64V03OptimizedGemminiConfig.config) ++
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
