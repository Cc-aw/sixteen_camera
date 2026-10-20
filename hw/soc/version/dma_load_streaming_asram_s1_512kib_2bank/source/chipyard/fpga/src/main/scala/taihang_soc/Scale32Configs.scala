package tsmcchip.fpga.taihangsoc

import org.chipsalliance.cde.config.Config
import saturn.common.VectorParams

/*
 * I: Input     输入：已验收的TaihangSoC64Batch2GemminiConfig参数。
 * P: Process   处理过程：复制配置，将输出缩放并行度设为32并使用独立头文件名。
 * O: Output    输出：64×64阵列的32路accumulator缩放候选配置。
 * A: Author    作者：王志瑞。
 * E: Exception 异常情况：继承配置无acc_scale_args时map保留None，不创建缩放参数；
 *              参数合法性由Gemmini生成过程检查。
 */
object TaihangSoC64Batch2Scale32GemminiConfig {
  val config = TaihangSoC64Batch2GemminiConfig.config.copy(
    acc_scale_args = TaihangSoC64Batch2GemminiConfig.config.acc_scale_args.map(
      _.copy(num_scale_units = 32)),
    headerFileName = "gemmini_params_taihang_64x64_packed_batch2_acc512_scale32.h",
  )
}

/*
 * I: Input     输入：32路Gemmini缩放候选及原单Rocket/RVV系统配置。
 * P: Process   处理过程：组合总线、外设、Rocket、RVV和Gemmini配置。
 * O: Output    输出：独立命名的32路缩放FPGA系统，供RTL生成使用。
 * A: Author    作者：王志瑞。
 * E: Exception 异常情况：配置不兼容或资源参数非法时由Chisel elaboration报告；
 *              FPGA资源是否满足需后续综合和实现确认。
 */
class TaihangSoC1Rocket1RVV1Gemmini64x64PackedBatch2Scale32FullOps256BitConfig extends Config(
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
  new gemmini.DefaultGemminiConfig(TaihangSoC64Batch2Scale32GemminiConfig.config) ++
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

