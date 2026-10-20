# CSC-R1 完整 G0 仿真评估

基线：`abd1c8c87558c7b0`，HEAD：`8d3aa31d8935cb000a3427638f55c5163d36bc0b`。

**G0：PASS。物理实现决策：INSUFFICIENT_EVIDENCE；G1/G2 尚未执行。**

- 三路、每路连续两帧，原生 166 个非终止阶段；每路每帧 462 个 Conv 包、224 个 WS 包及 5 个 memory kernel。
- 实际 Mvin：421,746；实际 Get：3,863,988 次、177,340,416 字节。
- 通过源版本、完整提交、同址同布局和无覆盖核验的完整 Load：19,608；对应 Get 字节 13,390,080，占 7.550495%。
- Input 单独对应 5.686582%，Weight 对应 1.863914%；零填充命中不计入 Get 字节。
- 独立固定时序删除模型省略全部合格 Load 的写入后，每次真实 SRAM 读仍逐字节一致；原信用/完成时间保留。

这些是 C0 中已证明的数据复用机会，尚非候选 RTL 的实际省略数或周期提速。
功能内存服务为每路私有，不包含共享 DDR/ASRAM 仲裁、CPU/RVV 与 PPU 时间；不报告 FPS。
lane 0 同时作为单路功能对照，明确复用同一证据，不构成单路/三路吞吐对照。

原生 `gemmini_timeout=10000` 会拒绝合法长池化；隔离复现以现有
`+gemmini_timeout=60000` 正常完成，保留所有 RTL 断言。失败/中止诊断均被排除。
原 96 项四模式紧凑层、288 项实际 ASRAM/URAM 及晚到错误/复位证据仍在 `../g0/`，不改写旧归档。

建议下一阶段先验证最小 C1a Input 原型；有界描述符能覆盖多少机会及真实周期收益仍须 G1/G2。
未综合、未布局布线、未生成 bitstream、未访问 FPGA，也未修改正式 SoC 或父候选。

完整决策见 [decision.md](decision.md)，逐阶段统计见 [per_stage_opportunity.csv](per_stage_opportunity.csv)。
原始日志、输入、生成包装及完整 trace 保留在 `build/experiments/csc_r1/g0_full_20261019_01`。
`archive_sha256.json` 绑定本目录；`current_source_origins.json` 对应完整 G0 源码，
原 `manifests/SOURCE_ORIGINS.json` 保留首轮紧凑检查点的历史身份。
