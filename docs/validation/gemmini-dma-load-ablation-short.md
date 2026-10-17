# DMA/SPAD 四模式对照与十二帧短测离线验证

日期：2026-10-17。按用户要求不生成新比特流，不下载硬件或 ELF。
原硬件 build ID `2a95a4ca64390235`、原三模式 bitstream、包内生成上下文及生产
`hw/soc` 导出均保持原样。旧硬件仍不能执行新增 SPAD-only 模式。

## 改动及测量口径

| ID | 模式 | 跨行 TL 合并 | SPAD 行组装 |
| --- | --- | --- | --- |
| 0 | legacy | 关 | 关 |
| 1 | read_coalesced | 开 | 关 |
| 2 | read_assembled | 开 | 开 |
| 3 | spad_assembled | 关 | 开 |

第四模式保留与联合模式相同的命令收集、有序返回缓冲和完成机制，只关闭跨逻辑行
读取合并。它是本实现内部的控制变量对照，不是完全去掉 Group 缓冲的另一套路径。

首层和整网每模式／executor 正式 12 帧，三路各 4 帧；每项预热 3 帧。
整网额外 direct 基准 12 帧；旧三模式正式 72 帧、总计 102 次提交，
四模式正式 96 帧、总计 132 次提交。首层四个三帧窗口累计为 12 帧。
逐阶段扫描默认取消，成功批次不再打印逐 HOST 边界。完整 PPU 结果及计数比较、
失败时 expected/actual、真实帧号、计数快照和 HOST 边界均保留。

当前默认固件可在原三模式硬件上短测，输出 `ablation=missing_spad_only`。
`DMA_ABLATION=1` 要求第四模式，旧硬件明确失败；不会通过改模式名假造对照。
历史 schema=1 严格解析保留，新短测使用 schema=2，整网 firmware revision=3。

## 实际离线检查

- `make check`：生产清单及当前生成硬件身份通过。
- 独立包 `make test check preflight`：两份 RV64GCV ELF 构建、native/adapted
  计划等价、20 项 host 测试、软件／硬件身份与编译依赖审计、离线下载预检查通过。
- host 测试执行真实首层／整网套件循环及 PPU 分配函数，检查三／四模式的精确帧数、
  run 连续性、均衡分配、编号溢出、失败输出、缺帧／缺计数／截断／模式错误拒绝。
  计算和计时是合成的，不作为板测性能证据。
- `tests/model/dma_load` 的 7 项参考／旧日志测试通过。
- `run_dma_load_tests.py --unit-only`：实际编译当前源码，使用原已验证依赖 jar，
  3,520 组 planner、650 组 assembler、mode 2／3 各 10 个混合命令、1,600 周期
  有序 bank 队列、ID8～34 计数 ABI、四模式控制与拒绝、真实 Reader 回归通过。
- 针对同一 C=3／N=32／起址低六位 59 的命令，实测单元请求数为 mode 2 的
  3 个及 mode 3 的 33 个；新模式每个物理有效片段不跨逻辑行。两模式的重放数据、
  地址、mask、组装标志、乱序返回和完成比较均通过。

单元证据目录：`build/experiments/dma_load/ablation_units_20261017_final/`。
机器摘要见 [JSON](gemmini-dma-load-ablation-short.json)。

## 范围限制

本轮新增模式只做源码单元回归，未生成新的完整 SoC RTL 候选、未跑四模式真实
Gemmini 整合回归／新 OOC／完整布局布线，也未上板，因此没有 SPAD-only 的整网
周期或数值验收结论。已更新的整合 runner 根据上下文要求三／四模式覆盖，未来
四模式候选必须重新取得对应证据。原候选时序和偶发数值错误问题没有在本轮关闭。
