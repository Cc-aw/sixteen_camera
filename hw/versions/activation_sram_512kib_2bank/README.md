# ASRAM-1：三路私有 activation SRAM

以 [DMA/SPAD 版本](../dma_load_512kib_2bank/README.md) 为基础的独立候选。
固定三路 DIM32、100 MHz、512 KiB / 2 bank S1 L2，保留四种 DMA/SPAD
运行时模式及其默认 legacy 行为；streaming 目录不参与本候选。
实施范围与阶段见 [PLAN.md](PLAN.md)，实际验收状态见
[validation/status.json](validation/status.json)。

本目录保留实际 shell、frontend、TensorIngress、Head 路由源码副本。
生成操作只写私有工作区，不替换公共 `hw/soc/` 导出，不自动连接或下载开发板。
旧硬件 ID `2a95a4ca64390235` 只标识历史三模式基线，新 RTL 必须生成新身份。

| 位置 | 内容 |
| --- | --- |
| `activation_sram/scala/` | 双入口 TL 控制器、返回 credit、跨端口冲突控制和独立能力/统计页 |
| `activation_sram/resources/` | 每 bank 18×4 块 URAM288_BASE，共享双端口、32 字节 mask |
| `manifests/activation_sram.json` | 唯一地址/容量配置来源 |
| `software/` | 生成 C 常量和显式 arena view；软件集成验收状态另行记录 |
| `command_frontend/` | 本版私有 lane 分流、CPU/RVV 服务路径及 RAW 地址检查 |
| `soc_shell/` | 保留 DMA/SPAD 优化，增加本地普通存储范围的合法性检查 |
| `scripts/`、`tests/` | 私有生成入口、实际 TL/存储测试和 OOC |
| `constraints/` | 依据 DMA 512 KiB / 2 bank 实际布线修订的私有实现流程，见 [布局说明](constraints/README.md) |

三路地址为 `0x20000000`、`0x20400000`、`0x20800000`，各窗口预留 4 MiB，
仅前 `0x240000` 有效。控制页为 `0x20c00000`。DMA 只能成功访问本路有效区；
其余保留范围均 denied，不能落入 DDR。CPU/RVV 经独立服务路径使用同一份字节，
不声明 Acquire/原子操作/可执行属性。最终 PMA 及真实执行验证状态单列。

在本目录运行：

```sh
make check
make test-prepare
make test-store
make test-tl WORKSPACE=/tmp/sixteen-camera-dma-load-2bank-chipyard
make ooc OOC_OUTPUT=<新的报告目录>
make prepare SOC_REFERENCE=/home/wzr/chipyard WORKSPACE=<新的私有工作区>
make check-workspace WORKSPACE=<已准备的私有工作区>
make resume WORKSPACE=<已准备的私有工作区> CANDIDATE_OUTPUT=<新输出目录>
```

`test-tl` 使用真实 TL manager/controller 和行为存储；`test-store` 另行使用
Vivado 2023.2 的实际 URAM 原语模型验证字节 mask、容量边界及延迟。
二者均不等价于 Rocket/RVV 或真实 Gemmini 计算通过。
`make test-unit` 保留原 DMA 源码回归入口，其结果同样不能代替三路 ASRAM 集成。

生成回退使用同一源码、同一 SoC Config，通过 `ACTIVATION_SRAM_ENABLED=0`
关闭 ASRAM feature；新默认候选使用 `1`。两者须分别记录生成身份。
DDR/local 运行时切换和整网比较须在软件绑定及完整计划等价通过后验收。
不根据历史板测或当前模块测试宣称整网提速或 3×。

本版整机实现通过 `ASRAM_CANDIDATE_CONTEXT` 选择私有生成 RTL 和约束；
`VIVADO_PROJECT` 必须位于 `build/experiments/activation_sram/`。
不使用 DMA 版本的 bitstream 启动脚本，以免覆盖本版布局 hook。
负时序记录到报告和状态，不阻断 `write_bitstream`；不自动下载开发板。

```sh
make test-physical
make bitstream DMA_CONTEXT=<本版_GENERATION_CONTEXT.json> \
  ASRAM_BUILD_OUTPUT=<build/experiments/activation_sram/下的新目录>
```

生成上下文保持原始 RTL 身份。仅新增物理约束时，保存其原始来源清单到
`manifests/rtl_snapshots/`，核对全部生成输入和最终 RTL；新的构建另外记录当前
约束及板级输入的 SHA256，不修改历史生成上下文。
