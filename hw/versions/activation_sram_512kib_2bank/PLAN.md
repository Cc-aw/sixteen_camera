# ASRAM-1 实施计划

本版本从 `../dma_load_512kib_2bank/` 的独立源码快照派生，保留四种
DMA/SPAD 模式及 512 KiB / 2 bank S1 L2。历史三模式硬件标识
`2a95a4ca64390235` 只作资源和行为来源，不作为新硬件身份。
未提交的 `dma_load_streaming_512kib_2bank/` 不参与本版生成。

实施依据为
`docs/architecture/sixteen_camera_ASRAM1_private_activation_sram_codex_implementation.md`。
当前分支、dirty diff 和历史候选身份保存在
`build/experiments/activation_sram/512kib_2bank/baseline_identity.json`。

| 阶段 | 实现及准入证据 |
| --- | --- |
| M0 | 基线溯源；完整地址/alias 清单；物理 frontend lane 与 BuildRoCC/opcode/SLR 对应；按真实 DMA 范围审计 arena；资源预算 |
| M1 | 每路 72 URAM、真实双端口、32 字节 mask；请求队列/返回 credit；多 beat、冲突序列化、错误和复位回归 |
| M2 | CommandFrontendTL 后分流；后备过滤全部保留窗口；CPU/RVV 共享服务入口；PMA、source31、混合目标与真实 CPU/RVV 验证 |
| M3 | 显式 ActivationArenaView；DDR/local 两种存储策略；能力校验；完整计划归一化等价、完整访问范围和 guard；独立比较/诊断 ELF |
| M4 | 三路真实计算与原始数据比较；frontend/L2/PPU/Tensor/视频回归；私有 RTL 重新生成；OOC 及集成综合/布局布线 |
| M5 | 同硬件六组合比较套件、日志解析器、身份与哈希、回退说明；不自动连接或下载开发板 |

地址由 `manifests/activation_sram.json` 单源生成。选用低 32-bit 空闲区：
三路分别从 `0x20000000`、`0x20400000`、`0x20800000` 开始，各预留
4 MiB、有效 2.25 MiB；控制页 `0x20c00000`。已与历史候选 memmap
检查不重叠；最终以新候选各入口协商范围及行为回归验收，不能仅凭此表认为集成通过。

历史布局报告中 SLR0/1/2/3 的 URAM 分别为 124/188/0/60；新增三路
按目标 SLR0/1/3 放置时预算为 196/260/0/132，总计 588/1280。
这不是新设计的综合结果。基线 SLR1 CLB 占用 99%，整机 WNS=-1.467ns；
后续须保留 100 MHz 目标并如实报告新设计资源和时序。

保护既有算子、tiling、量化、SPAD/ACC、RAW/DRAIN/HOST、Head/PPU 发布协议。
不缩容量、spill、镜像 DDR、全局排空三路、关闭视频或修改既有 timing 例外。
模块测试、真实 TL、真实 CPU/RVV、真实 Gemmini、OOC、整机时序与板测分别记录。
任何阶段未完成均保持对应 NOT_RUN/FAIL/BLOCKED，不将历史或 mock 证据升级为本版 PASS。
