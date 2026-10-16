# S1 L2 扩容：1 MiB、四 bank 验证记录

2026-10-16。计划见 [实施计划](../architecture/l2-1mib-4bank-implementation.md)，
机器可读交付清单见 [验证清单](l2-1mib-4bank.json)。基线为保存的
`2326f08390f96cebfbb66fbb2afe14a3691fca7a`，保留该基线的 S1 Head、
TensorIngress、DDR mode1、S1 组合调度器和每 bank 34-entry fastPeek 请求池。
对照对象是该基线的两 bank RTL；历史 S1 `.bit` 的 Tensor／DDR 配置不同，
不能把本次仿真解释为与历史板测完全相同的整机对比。

## 实际修改

正式导出为四 bank、总 1048576 字节；每 bank 8 ways、512 sets、64 字节行，
bank 位为 A13:A12，完整 bank/set 周期为 128 KiB。每 bank 32 普通和 2 一致性
MSHR、102 逻辑队列不变。通过 Scala／Chisel／Diplomacy 重新生成完整互连和
SoC，正式目录只保留一套导出，`GENERATION_CONTEXT.json` 绑定 786 个生成文件。

内存统计升级为 ABI1.2，保留块 0–13，增加 bank2／3 块 14／15；原事件编号
含义保持，新增事件另占槽位。SW-P3 的地址着色、空间预留和 ELF 审核读取实际
几何信息。已有及并行的软件修改均保留。几何辅助代码和 SW-P3 适配已随并行
软件提交 `ecbd577` 保存；本次硬件提交在该提交之上记录 L2、生成 RTL、测试和
验证证据，未纳入另外三处仍未提交的 V34 软件修改。

## 自动验证

证据保存在 `build/reports/l2_1m_4bank/`，具体命令、日志与哈希在验证清单中。

| 项目 | 结果及范围 |
| --- | --- |
| 完整 RTL 重新生成、生产清单、当前产品身份 | 通过；唯一正式四 bank 导出 |
| 几何／产品身份主机测试 | 3／6 项通过 |
| S1 请求池随机测试 | 5 个种子，每个 20000 次操作通过 |
| 两／四 bank 一致性测试 | 通过；四个池各达到 34，每 bank 普通 MSHR 各达到 32 |
| CPU ownership、Probe／ReleaseData、脏行逐 bank flush | 通过；覆盖所有 bank 和排队读 |
| Tensor 一致性 | 两／四 bank 通过；冷整行写不取旧 DDR 数据，覆盖逐 bank 脏替换／CPU ownership |
| 统计 MMIO | 两／四 bank 通过；ABI、几何、槽位、peak、snapshot／clear、拆分读取及外部转发 |
| 原有 cache／memory-v3／PPU 回归 | 通过 |
| SW-P3 构建、布局与硬件绑定、主机协议测试 | 通过；对应已验证产物快照，不代表板测或实时 Runtime 适配 |
| 候选 Vivado 工程重建及属性审核 | 通过；审核的 scripts-only 操作没有执行综合 |
| bank 放置引导 Tcl | 两／四 bank 模拟层次通过，三 bank 拒绝；实际布局尚未执行 |
| `check-deps` | 未全通过：任务开始前已有 `prepare.py` 的软件导入哈希不匹配；硬件导入和冻结依赖检查通过 |

初期测试中发现的脏行 invalidate 期望错误、MSHR 压力测试释放条件错误已经
修正，并重跑最终一致性和 Tensor 测试。失败日志保留；交付清单引用最终通过的
日志。性能检查数据编码全部 33 位物理地址及拍内位置，强化检查后重新运行完整
矩阵，72 个主场景的周期结果与之前一致。

## 速度对照及限制

每种配置执行 76 组相同流量：72 个主场景及 4 个无背压长延迟冷读场景。
实际生成路径为 SystemBus → CoherenceManagerWrapper（L2／CacheCork）→
MemoryBus → S1 Head，使用 1／3／4 个合成客户端、两种延迟、两个种子，
逐拍核对数据、写回和响应归属。独立 L2 另有每种配置 32 组对照。

| 场景 | 四 bank 相对两 bank 的周期变化 |
| --- | --- |
| 单 bank 热命中、单 bank 冲突读写 | 相同 |
| 分散 bank 热命中 | 最多减少 49.56%；观察到四个客户端同时返回 |
| 768 KiB 工作集 | 减少 34.89%–54.25%；所有对照的 refill 均减少 |
| 1280 KiB 工作集 | 减少 2.24%–51.05% |
| 冷流式读 | 随流量改变；8 个场景变慢，最大增加 0.9413% |

最大退化出现在 128-cycle 内存延迟、3 客户端且无背压：6374 → 6434 周期。
两版 refill 数相同，均达到未改变的共享 DDR 32 outstanding 上限；观察到该
瓶颈，不把全部差距归因于未经隔离的具体仲裁路径。本次扩容没有重做 S1 调度器。

以上是合成流量仿真结果。端点按 FIFO 返回，没有建模 DDR 控制器／PHY／寄存
切片，也没有覆盖内存跨 ID 乱序、完整 ELF 或 Gemmini 算术，不等同于板上模型
加速。未执行 FPGA／ELF 下载、板测或整网吞吐测量。

## 综合与候选产物

| 局部综合 | 100 MHz 未布局 WNS | 其他证据 |
| --- | --- | --- |
| L2 | +1.015 ns | 138940 LUT、80809 寄存器、272 BRAM tile、0 URAM |
| SystemBus | +3.473 ns | 综合通过 |
| MemoryBus | +6.804 ns | 综合通过 |

这些数值来自局部未布局综合，不能作为整机布线后时序结论。

按用户后续指令，整机综合使用独立工程
`build/projects/l2_1m_4bank_candidate/sixteen_camera.xpr`；运行 IP 综合和 `synth_1`，
状态、日志、资源及未布局时序估计保存在
`build/reports/l2_1m_4bank/full_synthesis/`。最终结果见本节及验证清单。
综合成功后自动接续 `impl_1` 到 `write_bitstream`，本轮按指令仅监听到综合结束。
后续状态保存在 `build/reports/l2_1m_4bank/full_implementation/state.json`。
比特流是否生成、布线时序是否通过分别记录，不把启动实现表述为已经完成。

整机 `synth_design` 已成功，命令耗时 35 分 08 秒；综合器统计为 0 errors、
0 critical warnings、1433 warnings。标准综合 DCP 已生成。关联全部 IP 后的
未布局层次资源统计为 961628 LUT、932932 寄存器、1605.5 BRAM tile、
372 URAM、3002 DSP，四个 L2 bank 均出现在综合网表层次中。
`synth_1/top_wrapper_utilization_synth.rpt` 尚未关联独立 IP，不能把该报告的
较小数值当作整机总量；以上总量来自 `full_synthesis/utilization.rpt`。
控制台还保留 Vivado 本地 TclStore 无写权限后回退安装目录等环境／IP 提示。
综合成功不代表布线后时序已经通过。

综合流程于 2026-10-16 16:17（北京时间）正常结束，`synth_1` 为 100%、
`synth_design Complete!`，综合 DCP SHA-256 为
`df275b5b062e97f705171d028600a6374f3dc9161e520d140219b13eeed949ba`。
未布局时序估计 WNS −1.142 ns、WHS −4.615 ns；`check_timing` 还报告
265 个 no-clock 引脚、335 个未约束内部端点。报告保存原始结果，未将其称为
时序验收通过，也没有为消除这些数字修改时钟或新增例外。
后续实现进程于 16:17 自动启动，目标为 `write_bitstream`；截至本次交付，
布局布线尚未完成、比特流尚未生成。本轮按要求在综合结束后停止监听。

## 回退

完整两 bank 基线及新生成的独立回退产物分别保存在报告目录的 `baseline/`、
`fallback/`。回退仍是 512 KiB、两 bank、mask0x1000、统计 ABI1.1；七个核心
控制模块规范化 RTL 与保存的 S1 基线一致。

```bash
python3 tools/soc/build_triple32_v3_tensor.py \
  --workspace <prepared-workspace> --resume --l2-banks 2 --no-export
```

该命令不替换正式四 bank 导出。需要恢复正式生产版本时，在独立 worktree 使用
保存的基线提交重新生成，避免覆盖当前并行软件修改。Head 本身未更改，仍可独立
采用原有 S1 恢复记录；L2 的两 bank 回退不要求切换 Head、Tensor 或 DDR 模式。
