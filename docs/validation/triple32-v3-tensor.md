# V3 + Tensor 硬件移植验证

日期：2026-10-12。配置：`triple32_v3_tensor`。

验证范围为生成、工程重建、功能仿真和局部综合；按用户要求未启动整机综合、布局布线或比特流生成。

| 局部模块 | 综合 WNS（ns） | DRC 违例 | 结果 |
| --- | ---: | ---: | --- |
| TensorIngress | +7.685 | 0 | PASS |
| 双 bank L2 | +0.275 | 0 | PASS |
| SBUS | +4.129 | 0 | PASS |
| Head router | +7.345 | 0 | PASS |
| 统计 CDC | +2.273 | 0 | PASS |

Tensor/L2/SBUS/Head 使用 100 MHz 局部时钟；统计 CDC 使用 300 MHz 源域和 100 MHz 目标域，以及原 V3 的有限 payload 延迟约束。以上是综合后局部内部路径，不包含整机布线与板级 I/O 时序。

Head 综合检查确认为 192 个 URAM288。各模块无未解析 black box；Tensor 项的资源报告也未报告 black box。

已通过：

- 正常 SBT 编译、完整 SoC elaboration、原 V3 RAM 推断处理及生成结构检查。
- 双 bank、512 KiB、A12 映射、每 bank 34 MSHR、三 worker 和接口宽度检查。
- Tensor 协议：提前 AccessAck、乱序、同 ID 多事务、source 耗尽、record 回绕、错误写和复位。
- 实际双 bank L2/CacheCork：2643 周期、95 次双 bank 同时返回、30 次 Tensor 与其他客户端完成重叠、2 次 CPU probe；冷行写无旧 Get，脏行 flush 和十个 tag 的替换读回通过。
- 六槽 Head：masked/narrow 写、窄读、半字选择与背压。DDR outstanding/order 测试通过。
- 统计快照、跨时钟、在途 clear/reset 测试通过。
- Tensor DMA 原回归及新增同一故障通道再次完成好帧的回归通过。
- PPU publication/generation/abort/error/reset 与六任务回归、视频和全部 host 软件回归通过。
- 新 Vivado 工程重建通过；板级 wrapper 对实际 SoC/DDR 端口声明的 lint 通过。

报告与 DCP：

- `build/reports/triple32_v3_tensor_ooc/tensor/`：`result.txt`、`timing.rpt`、`utilization.rpt`、`drc.rpt`、`synthesized.dcp`。
- `build/reports/triple32_v3_tensor_ooc/l2/`：`result.txt`、`timing.rpt`、`utilization.rpt`、`drc.rpt`、`synthesized.dcp`。
- `build/reports/triple32_v3_tensor_ooc_remaining/sbus/`：`result.txt`、`timing.rpt`、`utilization.rpt`、`drc.rpt`、`synthesized.dcp`。
- `build/reports/triple32_v3_tensor_ooc_remaining/head/`：`result.txt`、`timing.rpt`、`utilization.rpt`、`drc.rpt`、`synthesized.dcp`。
- `build/reports/triple32_v3_tensor_ooc_remaining/counters/`：`result.txt`、`timing.rpt`、`utilization.rpt`、`drc.rpt`、`synthesized.dcp`。

汇总与 DCP 哈希：`build/reports/triple32_v3_tensor_validation.json`。有效生成源码及 RTL 哈希保存在导出目录的 `GENERATION_CONTEXT.json`。

新工程：`build/projects/triple32_v3_tensor/sixteen_camera.xpr`。两套旧硬件配置保留独立选择入口，配套 V17 A 固件已完成离线移植与回归，详见
[软件验证说明](../integration/triple32-v17a-software.md)；未进行板上运行。

保留的已知警告：原 V3 L2 Scheduler 存在两处 5-bit 动态索引访问 34 项 Vec 的 Chisel 警告；Vivado 在当前受限环境无法写入用户 TclStore，回退到安装目录。SBUS 两个时钟端口是同一 100 MHz SoC 时钟的同步域别名。
