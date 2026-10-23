# S1 FIFO16 Team 时序优化 S3

以相邻 Team 移植版为固定补丁基线，迁入外部 S3 已采用的完整时序优化策略。
`manifests/SOURCE_OVERLAY.json` 固定父配方；七个已有 Scala 文件的差异保存在
`patches/timing_s3.patch`，新增 `DmaLoadIngress.scala` 保存在 `overlay/`。
9,712 个完整源码文件仅在忽略的 `build/source_overlay/` 中重建。
板级 RTL/IP 配置、约束和实现 hook 在本版本内独立保存，与其他硬件版本的组织方式一致。

## 迁入内容

- Controller/ReservationStation：命令元数据和依赖检查流水线，以及相应配置状态快照。
- DMA/Group：保留故障保护，最终完成 credit 避开片段到达当拍。
- DmaLoadIngress：两级弹性流水，分开 stride 乘法、地址范围检查与路径分派。
- Scratchpad：合流后双项返回缓冲，元数据使用寄存器，宽数据保留 LUTRAM，busy 覆盖缓冲。
- L2 SourceC/SourceD：保留 eviction/refill 仲裁修复，SourceD 使用寄存队首和 skid，两个位置均参与冲突保护。
- Tensor CDC：源侧弹性缓冲及同步器局部约束；HDMI 统计计数事件寄存，视频数据通路保持原接口时序。
- 物理策略：DDR UI 和 Tensor video 域局部性；摄像头第二级采样 FF 按 IO bank 限定 clock region。
- Vivado：重定时、`ExploreWithRemap`、`SSI_SpreadSLLs`、`AggressiveExplore`、
  `AlternateCLBRouting -tns_cleanup` 和布线后物理优化；不使用原来的强制控制复制 hook。

三路 DIM32、FP16 数学 ABI、100 MHz、FIFO16/fetch4、512 KiB 双 bank L2、私有 ASRAM、
mode2、MVIN skip 和 DirectA32 保持。流水级会增加部分首次访问和恢复延迟，不能据此推定应用性能不变。

## 重建与验证

在本目录执行，工具路径沿用仓库 `tools/config/tools.local.mk`：

```sh
make audit-source
make soc
make check
python3 -B scripts/audit_timing.py --generated build/timing_generated_final
make test-frontend RTL_RUN=s3_acceptance
make test-rtl RTL_RUN=s3_acceptance
make test-timing
make test-ingress
make test-fault
make project
make elaborate
# 需要重新实现时：
make bitstream
```

`WORKSPACE`、`OUTPUT`、`PROJECT_OUTPUT` 均在本版本私有 `build/` 下。
`make soc` 要求全新输出；工作区中断后可显式使用 `SOC_FLAGS=--resume`。
输入变更后仍必须选择新的 WORKSPACE/OUTPUT，不复用过期生成身份。
`make project` 创建 `build/timing_project_01/s3.xpr`，不自行启动综合或实现。
负时序不阻止显式请求的 bitgen，也不会被记录为时序通过。

`audit-source` 验证重建后的完整源码、板级输入和 ABI 与冻结 S3 一致。
`audit_timing.py --generated ...` 进一步逐文件比对新生成 RTL，仅允许三个 worker 的
硬件 ID 常量因本地构建身份发生变化。测试输出和综合、布局布线缓存均不进入源码载荷。

## 身份与证据边界

来源：`/mnt/data/sunys/dma_load_streaming_asram_s1_fifo16_team_port_512kib_2bank_timing_s3_2026-10-22/`，
对应外部硬件 ID `545a937878f2f3b6`；冻结哈希见 `manifests/TIMING_SOURCE.json`。
本地补丁配方、脚本和构建输入产生自己的新硬件 ID，不能直接套用外部 ID 或旧板测结论。
本版本没有复制外部完整 Chipyard、Vivado 工程或比特流，也不依赖该外部目录重建源码。

首份本地生成的硬件 ID 为 `853cfcbbfc1644c9`。生成后只修正了 RTL 审核脚本对
大写十六进制字面量的处理；`manifests/SOURCE_LAYOUT_MIGRATION.json` 精确限定这一项
审核工具差异，保留原生成上下文、源文件与 RTL 的全部哈希。未来重新生成按当时配方计算新身份。
已重建的 Vivado 工程可通过 `tests/timing/check_project.tcl` 审核实际策略、hook、IP 和路径归属，
该审核不启动综合或实现。
RS 原版对照以压缩测试夹具和 SHA-256 固定在 `tests/timing/fixtures/rs_original/`，
测试时仅在私有 build 输出中解压，不读取未提交的父版生成物。

外部 S3 最终 checkpoint 和报告的 WNS 为 **-0.236 ns**，TNS 为 **-186.235 ns**，
不是完全收敛；布局阶段的 +0.211 ns 不作为最终结果。该外部比特流已由操作者完成
普通模型 102 帧、DirectA 诊断 102 帧及 DirectA 模型 102 帧的同板一致性测试。
这些测试不代表独立 CPU 黄金值验证，也不代表本地重新实现后的板测。
普通/DirectA 的三路 ASRAM 吞吐分别为 39.22/39.55 FPS，数值来自无诊断插桩模型测试。

本地已完成完整 SoC 生成，859 个生成文件与外部已测 S3 的差异仅为三个硬件 ID 常量。
163 个前端用例、16 条 RoCC 路由命令、72 个 DMA/ASRAM 数值用例、三路 matmul/LoopConv/SiLU、
三路故障复位、1,800 条 RS 命令、SourceC/SourceD、Ingress/Group、HDMI、真实 XPM CDC、
13 项源码重建工具测试及实际 Vivado 工程策略审核均通过。
本地综合和布局布线尚未启动，尚未生成本地 bitstream，不能据此报告本地时序闭合。
汇总和证据哈希见 [`validation/status.json`](validation/status.json)，当前入口见
[`manifests/current_timing.json`](manifests/current_timing.json)。

生产默认、原 Team 和 FIFO16/batch4
版本均保持原入口；板卡操作由操作者执行，本地物理实现和板测状态单独验收。
