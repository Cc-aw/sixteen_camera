# 最新三路 MaxPool + TensorIngress 离线验收

日期：2026-10-14。基线：`88a3b35`，v26软件移植完成后的主分支。
来源：`sixteen_camera_3x32_100mhz_memory_parallel_v3_maxpool_timing_v3_2026-10-13`。
当前唯一硬件入口：`triple32_v3_tensor`；配置名和软件 ABI 保持本工程名称。
实现及构建命令见 [当前硬件说明](../integration/triple32-v3-tensor.md)。

## 结果

| 检查 | 结果 |
| --- | --- |
| 完整Scala编译、elaboration、RAM处理与重新导出 | PASS；独立新工作区，无RTL功能补丁 |
| 最新生成结构 | PASS；三路MaxPool、双bank、五通道Queue2、one-hot request、Tensor端口、统计ABI1.1 |
| 实际工作区源码检查 | 当前新工作区PASS；旧工作区因旧ListBuffer源码被拒绝 |
| Scala shell/config/Replay/Memory DMA测试 | PASS |
| 真实L2 + Tensor功能 | PASS；3000cycles、95次双bank同时返回、64次Tensor事务与客户端完成重叠、32source IDs、2次probe、dirty flush/eviction |
| TensorIngress协议 | PASS；early Ack、乱序、同ID、source耗尽、record回绕、非法写、reset |
| 完整1920×1080显示 | PASS；1,036,800对像素、3804burst、588次4KiB拆分 |
| DVP事件队列 | PASS；463接受/463接收、23次定向overflow，满载与恢复 |
| UI返回压力 | PASS；512read beats、24writes、3462个满载周期；无丢失或乱序 |
| `test-video/test-tensor/test-memory-v3/test-cache/test-ppu` | PASS |
| `test-software/test-v26` | PASS；175native测试，无跳过；既有R0–R5 Host/RV64协议轨迹通过 |
| 当前v26视频/基准构建及实际ELF审核 | PASS；credit-cap4 formal，与当前硬件参数一致 |
| 新Vivado工程与实际SoC/DDR端口lint | PASS；DDR512/ID2、Tensor256/ID5、两个生产宏 |
| GUI属性及生成run脚本 | PASS；SSI_SpreadLogic_high、AlternateCLBRouting、TNS cleanup、AggressiveExplore及hooks一致 |
| synth_1/impl_1 | 未运行；仅使用`-scripts_only`审核脚本，两个run进度0% |
| 整机实现/bitstream/开发板下载/当前板端数值与性能 | 未执行 |

联合L2测试更新了测试刺激：内侧增加寄存器后，旧测试的“AXI valid脉冲与TL D恰好
同拍”不再覆盖所有并发窗口。新测试显式把客户端响应保留到Tensor事务开始，并
覆盖从AW到B整个在途区间；数据、source、probe/flush断言没有放宽。

现有软件回归继续记录 R0 Tensor版本回绕的 `correctness=FAIL / characterization=PASS`
标记，这个已知协议缺口没有在本次移植中修复。主机测试通过不代表板端性能已验证。

## 局部综合和时序

以下为 Vivado2023.2 对实际子系统的 out-of-context synthesis；不包含整机放置、
布线、最终时钟skew和板端测试。所有子系统均无未解析blackbox，保留DCP及报告。

| 子系统 | 目标时钟 | 局部setup WNS / ns |
| --- | --- | ---: |
| 双bank L2 | 100 MHz | 1.580 |
| MaxPool StoreController（3路复用同一生成模块）| 100 MHz | 6.489 |
| MaxPool StreamWriter / DMA | 100 MHz | 3.383 |
| TensorIngress | 100 MHz | 7.685 |
| MIG返回队列 | UI300 / video150 MHz | 1.638 |
| 显示mosaic | 150 MHz | 4.838 |
| DVP事件队列 | capture300 / video150 MHz | 2.196 |
| Tensor DMA | 150 MHz | 2.097 |
| 内存统计/本地reset | SoC100 / UI300 MHz | 2.267 |
| 相机前端/本地capture组 | capture300 / control24 MHz | 1.626 |

统计和相机初始OOC报告未带生产CDC例外，出现−0.297 / −0.277ns的首级同步器
跨钟违例。在同一已综合DCP上应用生产对应的首级D/异步assert例外及有限mailbox
max-delay/bus-skew后，得到表中结果。第二级D和业务路径继续计时，没有整域
false-path；统计约束只增加可选OOC层级参数，生产默认层级保持不变。

MIG RREADY的实际fanin只来自UI reset、两位occupancy寄存器和同步后的video
reset，确认CDC FIFO full/reset-pipe没有组合回传。相机五个本地capture寄存器和
统计三拍reset同步器在综合后保留。DVP FIFO写寄存边界也保留。
`report_cdc` 保留诊断提示，不作为全系统CDC sign-off；最终需检查真实实现报告。

## 清理和身份

`hw/soc/` 仅保留当前三路TensorIngress导出。五份旧硬件配置、single4/dual16固件
构建脚本及旧TensorIngress生成入口已退休。旧源码在Git历史，旧本地工程、固件和
导出备份在 `build/ports/latest-hardware/baseline/` 与 `build/soc_backups/`。
旧配置的主机mock/冻结轨迹保留，不能据此认为旧硬件仍可直接构建。

当前v26视频ELF SHA-256：
`3c000ab9b7d6bd6df26263d7bde61d1b480ceac9d05c41b7faed7c6137534c30`。
硬件更新没有改变软件指令/数据ABI；相同ELF哈希不表示旧bitstream可替代新硬件。
必须执行 `make bitstream` 并加载新结果，再运行v26独立基准的M/t/a及实时视频测试。

生成源码/原始和处理后RTL哈希见导出 `GENERATION_CONTEXT.json`。
当前闭包由 `hw/soc/source/shell/IMPORT_MANIFEST.json`、`LATEST_HARDWARE_IMPORT.json`
及 `make check-deps` 校验；来源开发目录未修改，构建不依赖该目录。
详细日志、checkpoint、资源/时序/CDC报告及机器可读汇总位于忽略的
`build/ports/latest-hardware/` 和 `build/reports/latest_*`。
