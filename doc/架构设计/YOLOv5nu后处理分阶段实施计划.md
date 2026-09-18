# YOLOv5nu 后处理分阶段实施计划

本文把后处理改造拆成可独立验证的功能阶段。各阶段先保证所有权和数值正确，
480 FPS 作为后续性能 Gate，不作为前期功能合入条件。

## 总体顺序

```text
P0 现有 PPU1 功能基线
 ↓
P1 独立 Head Slot 和直接输出
 ↓
P2 Head Slot 状态机与软件 PPU 队列
 ↓
P3 Gemmini/PPU 真正异步重叠
 ↓
P4 PPU 读带宽与 Sparse DFL outstanding
 ↓
P5 Device-owned memory 与安全恢复
 ↓
P6 480 FPS 性能收敛
```

## P0：冻结当前功能基线

当前 PPU 已实现三尺度 class reduction、Top-256、Sparse DFL、BBox、稳定排序、
class-aware NMS 和 10 项结果 RAM。保留 CPU fallback 与静态 image025 对照路径。

验收：normal、empty、dense、随机 DFL 和 NMS corpus 回归全部通过。

## P1：独立 Head Slot 和直接输出

状态：功能实现及板测 Gate 已通过（2026-09-18）。

每个 worker 的 4 MiB output arena 前 2 MiB 划为两个 1 MiB Head Slot。六个 raw
head 连续存放，总有效载荷 907200 B。最后六个 Gemmini Conv 直接写 Head Slot，
不经过 activation arena，也不执行 memcpy。当前 PPU 调度仍串行，完成后才切换到
另一个 slot，因此本阶段不宣称计算与后处理重叠。

当前双 worker 地址：

```text
worker0 slot A/B: 0x32000000 / 0x32100000
worker1 slot A/B: 0x32400000 / 0x32500000
```

未来 worker2 使用：

```text
worker2 slot A/B: 0x32800000 / 0x32900000
```

并发带宽诊断移到 worker0 output arena 的上半区 `0x32200000`，长度 2 MiB，
避免覆盖生产 Head Slot。

板测 Gate：

- `T` 静态 PPU/CPU 对照连续三次通过；
- 流式任务 status=0x2、positions=6300；
- worker0/1 均能完成任务；
- 连续任务观察到 slot A/B 交替；
- PPU、Gemmini、AXI error 为零。

### P1 板测结果

`T` 静态对照共执行 3 轮、每轮 3 次，9 次均为 `PASS`，检测分数均为
`score_milli=858`。100 MHz 下汇总如下：

| 指标 | 最小值 | 平均值 | 最大值 |
| --- | ---: | ---: | ---: |
| PPU 核心周期 | 101849 | 107956（1.080 ms） | 112802 |
| 硬件后处理 wall 周期 | 352724 | 359114（3.591 ms） | 364422 |
| 软件参考周期 | 15243589 | 15247480（152.475 ms） | 15250596 |

按全部样本平均值计算，硬件 wall 相对软件参考约加速 42.46 倍。硬件 wall 与
PPU 核心之间平均相差约 251158 周期（2.512 ms），说明当前主要可优化空间已经在
Head Slot 发布、cache flush 和 MMIO/结果回收路径，而不在 PPU 核心计算本身。

流式运行连续观察到：

- worker0/1 均返回 `status=0x2`，每项任务均扫描 `positions=6300`；
- 两个 worker 都按 `slot=0,1,0,1` 交替，证明生产路径实际使用独立 Head Slot；
- 8 项任务的 PPU 核心周期为 122029～182647，平均 155846（1.558 ms）；
- 首项任务从 16 个 candidate 经 NMS 得到 2 个结果，其余空帧正常得到 0 个结果；
- 日志中未出现 PPU、Gemmini 或 AXI 错误报告。

因此 P1 按功能 Gate 关闭。当前数据不代表系统已达到 480 FPS：静态 wall 时间仍为
3.591 ms，且完整 graph 周期约为 0x12B0000（约 196 ms）。这些分别由 P3～P5 的
异步重叠和内存发布优化，以及推理流水线的后续性能工作处理。

## P2：Head Slot 状态机与软件 PPU 队列

状态：功能实现、自动化回归及板测 Gate 已通过（2026-09-18）。

新增显式状态：

```text
FREE → WRITING → READY → PROCESSING → FREE
```

每个 slot 保存 job、worker、stream、frame、version、六段地址和错误状态。增加
深度为 Head Slot 总数的软件 ready queue。PPU仍一次处理一个 descriptor。

本阶段只分离所有权，不提前释放 Gemmini worker。

当前实现要点：

- submit 时只能从 `FREE` Slot 取得所有权，并进入 `WRITING`；
- Head 全部完成后保存 job/worker/stream/frame/version 及六段物理地址，
  然后进入 `READY` 并按发布顺序进入 FIFO；
- 全局 PPU service 可由任意 worker 的 poll 推进，不再依赖必须再次轮询
  descriptor 所属 worker；
- PPU 每次只从 FIFO 取一项进入 `PROCESSING`，结果回收完成后才
  返回 `FREE`；
- PPU timeout 时 Slot 保持 `PROCESSING`，禁止在读通道可能仍在访存时
  误回收；
- 正常完成后依然交替使用 A/B Slot。

新固件前 8 项任务增加调度日志：

```text
AI PPU enqueue worker/slot/ready=...
AI PPU worker/slot/status/count/positions/candidates/nms/ready/cycles=...
```

P2 板测 Gate：

- `T` 静态软硬件对照仍连续通过；
- worker0/1 均出现 enqueue 和 completion，同一 worker 仍按 A/B 交替；
- `ready` 深度不超过当前 4 个 Head Slot，不出现队列、Slot 状态或
  worker 匹配错误；
- 流式结果 metadata 与提交的 job/stream/frame/version 一致；
- PPU、Gemmini、AXI error 为零。

### P2 板测结果

`T` 静态对照连续 3 次均为 `PASS`，检测分数均为
`score_milli=858`。100 MHz 下汇总如下：

| 指标 | 最小值 | 平均值 | 最大值 |
| --- | ---: | ---: | ---: |
| PPU 核心周期 | 102455 | 102747（1.027 ms） | 102977 |
| 硬件后处理 wall 周期 | 353675 | 354020（3.540 ms） | 354371 |
| 软件参考周期 | 14738933 | 14739557（147.396 ms） | 14740790 |
| 完整 graph 周期 | 19612013 | 19631463（196.315 ms） | 19645823 |

硬件 wall 相对软件参考约加速 41.63 倍。

流式运行的前 8 项任务显示：

- worker0/1 均按 `slot=0,1,0,1` 完成 `enqueue → completion`；
- enqueue 时 `ready=1`，completion 时 `ready=0`，状态转换和队列深度合法；
- 所有 completion 均为 `status=0x2`、`positions=6300`；
- candidate 数为 0～12，NMS 输入数与 candidate 数一致，输出为 0～2 个检测；
- PPU 核心周期为 145721～201685，平均 164367（1.644 ms）；
- 未出现 timeout、Slot/worker 匹配错误或 PPU、Gemmini、AXI error。

当前 graph 平均约 196.315 ms，远慢于 PPU，因此每个 descriptor 都在下一个
Head 发布前完成，板上未自然形成 FIFO 积压。FIFO 顺序、双 Slot 同时占用和
满 Slot 拒绝已由主机单元测试覆盖。因此 P2 按所有权与串行调度的功能 Gate
关闭；真正制造同 worker 的 Head 重叠和队列积压属于 P3。

## P3：Gemmini/PPU 异步重叠

状态：功能实现、自动化回归及板上异步重叠 Gate 已通过（2026-09-18）。

在 `HEAD_READY` 后：

1. 发布 Head Slot；
2. 将 descriptor 加入 PPU queue；
3. 释放 activation arena 和输入 Tensor Slot；
4. Gemmini worker 接受下一帧；
5. stream inflight 一直保持到 PPU completion。

需要把当前按 worker 返回最终结果的 backend ABI 拆成 compute completion 和 PPU
completion 两条路径。验收重点是 PPU 处理 frame N 时同一 worker 已开始 frame N+1，
且复用 activation arena 不改变 frame N 的检测结果。

当前实现：

- backend ABI 新增独立的 `poll_compute()` 和 `poll_result()`；
- `HEAD_READY` 后立即生成 compute completion，Gemmini worker context 与 activation
  arena 当即解绑，输入 Tensor Slot 在同一次 runtime service 释放；
- Head Slot descriptor 独立保留旧帧 metadata，因此 worker 的 request 数组被
  新帧覆盖后，PPU 仍按旧 job/stream/frame/version 生成结果；
- runtime 使用独立 post-job 表保持 stream inflight，只在 result completion 到达时
  更新 result manager、deadline 和 inflight 计数；
- 4 项 backend result FIFO 与 8 项 runtime post-job 表覆盖“4 个 raw Head 正在
  READY/PROCESSING + 4 个已完成结果待消费”的最坏所有权边界；
- stop/drain 会等待 input slot、post-job、PPU 及 result FIFO 全部排空；
- 两个 Head Slot 均被占用时，submit 返回可重试背压，runtime 不将其记为故障。

主机重叠测试会故意延迟 worker0 旧 job 的 result completion，已验证 worker0
在旧结果未返回时可以释放 input slot、接收另一 stream 的新 job，之后旧结果
仍按原 metadata 发布。

新板测日志格式：

```text
AI GRAPH start worker/slot/job/ppu_status=...
AI PPU enqueue worker/slot/job/ready/cycles=...
AI PPU worker/slot/job/status/count/positions/candidates/nms/ready/cycles=...
```

P3 板测 Gate：

- `T` 静态对照继续通过；
- worker0/1 的 graph start、Head enqueue 和 PPU completion 中 job/slot 可正确一一对应；
- 至少一次新 `GRAPH start` 捕获到前一 job 的 PPU `BUSY`，或在 PPU 已经过快
  而无法自然观测时，确认无 Slot/metadata/inflight 错误；
- 结果仍通过 job/worker/stream/frame/version 校验，不出现 stale 覆盖；
- disable/drain 后 `post_inflight=0` 且 runtime 可返回 idle；
- 无 PPU timeout、Gemmini 或 AXI error。

### P3 首次板测与调度修正

首次板测的 `T` 静态对照为 `PASS`，流式路径 8 个 job 的 worker/slot/job
均正确对应，Slot 按 A/B 交替，PPU 全部为 `status=0x2`。但所有后续
`GRAPH start` 捕获的 `ppu_status` 也都是 `0x2`，而且日志顺序始终是旧 job
PPU completion 在前、同 worker 新 job start 在后，因此该轮只验证了两阶段
所有权和 metadata 正确，没有验证到板上实际重叠。

该轮流式 graph 计时为 384.136～438.459 ms，平均 427.098 ms；PPU 核心
为 1.607～1.814 ms，平均 1.688 ms。由于 PPU 在 runtime 释放输入和重新
dispatch 前已完成，随后将成功 compute completion 的 input release 从下一轮 poll
前移到当前 service，并在回收 result completion 前立即尝试 dispatch 空闲
worker。主机延迟结果测试在此修正后继续通过，新 ELF 需再次板测
`GRAPH start` 时的 PPU busy/read-busy 位。

### P3 二次板测结果

调度修正后，job 3～8 在启动新 graph 时均捕获到
`ppu_status=0x9`（`BUSY | READ_BUSY`），而前一 job 的 PPU completion
随后才以 `status=0x2` 返回。这直接证明同一 worker 已在 PPU
处理 frame N 时启动 frame N+1 的 Gemmini graph，板上异步重叠
成立。

本轮 8 个 job 的 graph 计时为 384.295～455.855 ms，平均
439.528 ms；PPU 核心计时为 1.093～1.282 ms，平均
1.182 ms。worker/slot/job 一一对应，Head Slot 按 A/B 交替，所有
PPU completion 均为 `status=0x2`，未观察到 stale 或所有权错误。

## P4：PPU 吞吐优化

按风险从低到高实施：

1. class read 使用可配置大 burst，DFL 保持 64 B；
2. 三个连续 class tensor 合并为一次 504000 B 命令；
3. Sparse DFL descriptor FIFO；
4. 相邻 candidate 合并 burst；
5. 分散 candidate 多 outstanding；
6. class reducer 从 8 B/fold 提升到 16 B/fold。

功能 Gate 始终包括 normal、empty、超过256候选、同分 tie 和 IoU 阈值边界。

## P5：Device-owned memory 与恢复

短期保留 Gemmini fence 和 Head Slot range flush。随后使用硬件 range maintenance
或经过验证的 non-cacheable/device memory 路径删除 CPU逐line flush。

错误恢复必须经过：

```text
STOP_ISSUE → DRAIN → QUIESCENT → invalidate slot → RESET
```

软件 timeout 不能直接把 Head Slot 标记为 FREE。

## P6：性能收敛

最终单 PPU 平均 service interval 目标小于 1.5 ms，系统完成间隔小于 2.083 ms。
只有在单 PPU 无法满足该目标且 DDR/QoS 已排除后，才评估第二颗 PPU。
