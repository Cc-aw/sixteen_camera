package tsmcchip.fpga.taihangsoc

import org.chipsalliance.cde.config.Config
import saturn.common.VectorParams

/** IPOAT
 * I（Input 输入）： verified Scale32 SoC configuration and experimental window depth.
 * P（Process 处理）： reproduce its composition with only scale depth and header filename changed.
 * O（Output 输出）： independently named N3/N6/N8 configs; baseline class and artifacts are preserved.
 * A（Author 作者）：王志瑞
 * T（Time 时间）：2026-09-09（注释补充日期）
 */
class TaihangSoCScale32WindowConfig(n: Int, scheduler: String = "legacy") extends Config(
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
  new gemmini.DefaultGemminiConfig(TaihangSoC64Batch2Scale32GemminiConfig.config.copy(
    acc_scale_n_entries = n,
    acc_scale_scheduler = scheduler,
    headerFileName = s"gemmini_params_taihang_64x64_packed_batch2_acc512_scale32_n${n}${if (scheduler == "legacy") "" else "_chunked"}.h")) ++
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


/** IPOAT
 * I（Input 输入）： verified Scale32 SoC configuration and experimental window depth.
 * P（Process 处理）： reproduce its composition with only scale depth and header filename changed.
 * O（Output 输出）： independently named N3/N6/N8 configs; baseline class and artifacts are preserved.
 * A（Author 作者）：王志瑞
 * T（Time 时间）：2026-09-09（注释补充日期）
 */
class TaihangSoC1Rocket1RVV1Gemmini64x64PackedBatch2Scale32N3FullOps256BitConfig
  extends TaihangSoCScale32WindowConfig(3)

/** IPOAT
 * I（Input 输入）： verified Scale32 SoC configuration and experimental window depth.
 * P（Process 处理）： reproduce its composition with only scale depth and header filename changed.
 * O（Output 输出）： independently named N3/N6/N8 configs; baseline class and artifacts are preserved.
 * A（Author 作者）：王志瑞
 * T（Time 时间）：2026-09-09（注释补充日期）
 */
class TaihangSoC1Rocket1RVV1Gemmini64x64PackedBatch2Scale32N6FullOps256BitConfig
  extends TaihangSoCScale32WindowConfig(6)

/** IPOAT
 * I（Input 输入）： verified Scale32 SoC configuration and experimental window depth.
 * P（Process 处理）： reproduce its composition with only scale depth and header filename changed.
 * O（Output 输出）： independently named N3/N6/N8 configs; baseline class and artifacts are preserved.
 * A（Author 作者）：王志瑞
 * T（Time 时间）：2026-09-09（注释补充日期）
 */
class TaihangSoC1Rocket1RVV1Gemmini64x64PackedBatch2Scale32N8FullOps256BitConfig
  extends TaihangSoCScale32WindowConfig(8)

/** IPOAT
 * I（Input 输入）： Scale32 window depth and the explicit no-normalization scheduler selection.
 * P（Process 处理）： retain the existing SoC composition and use a separate config/header name.
 * O（Output 输出）： chunked scale experiment; legacy configurations keep their previous defaults.
 * A（Author 作者）：王志瑞
 * T（Time 时间）：2026-09-09（注释补充日期）
 */
class TaihangSoC1Rocket1RVV1Gemmini64x64PackedBatch2Scale32N3ChunkedFullOps256BitConfig
  extends TaihangSoCScale32WindowConfig(3, "chunked_no_norm")

/** IPOAT
 * I（Input 输入）： Scale32 window depth and the explicit no-normalization scheduler selection.
 * P（Process 处理）： retain the existing SoC composition and use a separate config/header name.
 * O（Output 输出）： chunked scale experiment; legacy configurations keep their previous defaults.
 * A（Author 作者）：王志瑞
 * T（Time 时间）：2026-09-09（注释补充日期）
 */
class TaihangSoC1Rocket1RVV1Gemmini64x64PackedBatch2Scale32N6ChunkedFullOps256BitConfig
  extends TaihangSoCScale32WindowConfig(6, "chunked_no_norm")

/** IPOAT
 * I（Input 输入）： Scale32 window depth and the explicit no-normalization scheduler selection.
 * P（Process 处理）： retain the existing SoC composition and use a separate config/header name.
 * O（Output 输出）： chunked scale experiment; legacy configurations keep their previous defaults.
 * A（Author 作者）：王志瑞
 * T（Time 时间）：2026-09-09（注释补充日期）
 */
class TaihangSoC1Rocket1RVV1Gemmini64x64PackedBatch2Scale32N8ChunkedFullOps256BitConfig
  extends TaihangSoCScale32WindowConfig(8, "chunked_no_norm")
