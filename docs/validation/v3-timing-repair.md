# V3 共享内存时序修复移植（2026-10-15）

来源为 `/mnt/data/sunys/sixteen_camera_3x32_100mhz_timing_v3_2026-10-07/`
中的 `soc_shell/memory_parallel_v3_timing_repair`，合入 `def049a` 的最新三路
MaxPool + TensorIngress 配置。仍只有 `triple32_v3_tensor` 一个生产配置。
未导入 autonomous frontend 或其软件；v26、Runtime R5、CSR ABI1.1 保持兼容。

## 移植内容

- L2 的32个普通 MSHR 分成四组，各8个；另外保留两个一致性 MSHR。
  仲裁先寄存 winner 身份，再根据实时可用性原子提交各通道操作。
- 每 bank 的102个逻辑请求队列共享34条目的同步 payload RAM，使用窄
  head/tail/link 指针和4个预留读响应 credit，替代异步 fast-peek payload 路径。
- 退休和 refill 分离，包含同拍入队的 set 保留；refill 公平仲裁并重新读取
  directory，取消 retire/peek/repeat metadata 的组合旁路。B/C 高编号队列
  的索引加法保留进位。同一 MSHR 连续复用会增加延迟。
- DDR 最终五通道 `REG_*=1`，使用 FWD/REV + skid buffer。
  `make project` 同步更新已有 BD 并重新生成 IP。
- 保留 mesh SLR0/1/3、L2 SLR0/2 引导；新增 DDR crossbar/final slice
  的 SLR0 软引导，没有 routing containment、额外 false-path 或降频。

从私有工作区 `/tmp/sixteen-camera-v3-repair-chipyard` 完整编译、elaborate、
lower 并重新导出当前 SoC。相对基线，collateral 增加4个文件、退休4个、改变6个；
三个 Gemmini、LoopConv、TensorIngress 和 MemoryParallelPerf 的 RTL 哈希均未变。
`GENERATION_CONTEXT.json`、同步 RAM 配置及 shell 源码摘要一并更新。
当前源码来源和哈希见 `hw/soc/source/shell/LATEST_HARDWARE_IMPORT.json` 的
`timing_repair`，依赖检查包含该部分。

## 离线验证

| 项目 | 结果 |
| --- | --- |
| 完整 SoC 生成和结构检查 | PASS；双 bank、34 MSHR/bank、同步共享 RAM、五通道 Queue2、三路 MaxPool、Tensor ABI1.1 |
| RegisteredListBuffer 随机测试 | PASS；2013次 push/pop，374次末项 pop 与同拍 push；含 pool满、响应反压及排空 |
| 双 bank L2 测试 | PASS；2530周期、89次并行返回、2次probe、dirty flush、每客户端32 source、96个同set交错tag请求 |
| Tensor + V3 L2 并发 | PASS；3374周期、76次并行返回、72次Tensor事务重叠、2次probe；dirty flush/eviction与冷行整行覆盖无DDR Get |
| 厂商 DDR 切片仿真 | PASS；五通道各300拍并含反压，mode7为849周期/最长连续1拍，mode1为425周期/最长连续127拍 |
| v26 固件重建及 ELF 审计 | PASS；cap4、diag0；硬件生成 manifest 已更新 |
| production manifest / 工具和来源依赖 | PASS |
| Tensor DMA / Head / 统计 CDC / L2发布 | PASS；含坏帧排空、stall恢复、六槽、32 outstanding和reset in flight |
| Tensor协议core / 实际SoC与DDR wrapper | PASS |
| L2局部综合 | PASS；无blackbox；100 MHz内部setup WNS +1.451 ns |
| TensorIngress局部综合 | PASS；无blackbox；100 MHz内部setup WNS +7.685 ns |
| Vivado工程与生成脚本审计 | PASS；五通道mode1、512bit/ID2/32 outstanding、新placement hook；synth/impl进度均0% |

`make test-tensor-ingress` 的 L2 入口原先仍固定引用已退休的双路配置；现在调用
当前双 bank V3 的 shell 回归，默认从生成上下文取工作区，也支持
`SOC_WORKSPACE` 显式指定。协议 core 仍由新的 assembly 独立 emit 后测试。

v26 ELF SHA256：
`3c000ab9b7d6bd6df26263d7bde61d1b480ceac9d05c41b7faed7c6137534c30`。

复现新增测试：

```bash
make test-v3-timing-repair SOC_WORKSPACE=/tmp/sixteen-camera-v3-repair-chipyard
make test-tensor-ingress SOC_WORKSPACE=/tmp/sixteen-camera-v3-repair-chipyard
```

局部综合报告和 DCP 位于 `build/reports/v3_timing_repair_ooc/`。
工程审计只重置未启动的 run 并执行 `-scripts_only`；遇到真实综合/实现进度会拒绝重置。
日志和逐项证据保存在忽略的 `build/ports/v3-timing-repair/`，审计最终日志为
`project-audit-retry.log`，机器可读结果为 `validation.json`。
DDR 周期数字是独立流水线仿真结果，不是整板推理性能；局部综合的 setup slack
只覆盖内部寄存器路径，不包含板级 I/O 延迟，也不代表全设计布局布线结果。本次不运行完整综合、布局布线或上板测试。
