# CSC-R1 首轮基线仿真记录

日期：2026-10-19。C0：`abd1c8c87558c7b0`；HEAD：`8d3aa31d8935cb000a3427638f55c5163d36bc0b`。

**决策：INSUFFICIENT_EVIDENCE。G0 尚未通过，没有生成或启用 CSC-R1 RTL。**

- 冻结原生 C 生成器回放：58 个普通卷积 stage、每 worker 固定序列 462 个包，逐项匹配。
- 代表层：8 层 × 4 DMA 模式 × 3 lane，共 96 项；完整紧凑层输出逐字节对照 legacy，通过行流/Get 闭合。
- ASRAM 联合：4 路由 × 4 模式 × 6 参数组 × 3 lane，共 288 项；真实生成 RTL、service TL 和 Vivado URAM 原语通过。
- denied/corrupt 晚到错误保持与协调复位恢复通过；离线分析器 20 个正反向用例通过。
- read_assembled 三路完整紧凑 trace：1,914 条 Mvin、32,298 次物理 Get、1,380,864 Get 字节。
- 每路重建 15,362 次 SPAD commit、15,392 次实际读响应；逐字节读取值、bank 队列和完成信用账本通过。
- 84 条命令仅满足值驻留诊断；源版本、转换/布局和原生依赖尚未证明，合法可跳过数保持 null。

代表层使用合成输入与缩小空间尺寸，不重放原生整网的层间生产关系。
紧凑层采用现有 memory-latency=1 功能选项；独立 ASRAM/fault 用例保留延迟/反压。
这些周期不用于网络 FPS 或 CSC-R1 性能结论。日志保留 XSIM 43-4099 timescale 告警。

初次 ASRAM 驱动生成有缩进错误，仅在新实验驱动中修复。延迟=7 的诊断被中止，
保留在 attempts.json，未纳入通过证据。正式生产与两个父候选未修改，无综合、实现、bitstream 或 FPGA 访问。
会话中原有 SPPF 优化元数据另有更新，当前文件保留；初始副本和哈希在原始实验目录，未作为仿真输入。

原始日志、生成测试台、输入和全部 CSV 位于仓库根下：
`build/experiments/csc_r1/run_20261019_180858/`。
本目录归档可读结果与哈希；`archive_sha256.json` 绑定归档文件，
`evidence_manifest.json` 绑定原始实验文件。复现入口见 ../../README.md。

后续仍需完整网络真实 Mvin/SPAD/EX 生命周期、单路 trace、原生源代际与 HOST/Head/PPU 边界，
以及完整网络权重，才能判断 G0。G1 候选与 G2 周期 A/B 保持 NOT_RUN。
