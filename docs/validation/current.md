# 当前交付与验收

日期：2026-10-15。唯一身份为 `triple32_v3_tensor` + YOLOv5nu v26，
3 × DIM32、100 MHz、credit=4、hardware SAFE_MAX=4；十六路视频完整保留。
真实路径见 [交付清单](../../hw/manifests/current.json)。

实时 ELF 为 `build/firmware/video/video.elf`，其 JSON 记录硬件生成记录、参数、
模型来源锁、fixed plans、memory kernels、编译开关和 ELF SHA。
三图 ELF 为 `build/firmware/benchmark/benchmark.elf`，对应 `capacity_manifest.json`。
源码迁移前的恢复基线为 `before-single-version-refactor-20261015`（`cd361f5`）。

| 验收项 | 当前结果与证据 |
| --- | --- |
| P0 真实基线 | PASS；13 个命令、175 项模型测试；[机器记录](single-version-baseline.json) |
| 单产品身份 | PASS；错误配置被拒绝，实际头文件/门控与 Make 配置配对 |
| 新工作区 SoC 生成 | PASS（P2）；SBT/Chisel/firtool 正常生成，781 个 collateral 文件与基线一致 |
| 视频/基准共享模型 | PASS；同一 model.mk、源码/冻结输入/参数；16 项 v26 plans/packets 一致 |
| 执行代码等价 | PASS（P3/P4）；视频及基准 `.text` 与 P0 一致 |
| 软件回归 | PASS（P4 修正审核测试路径后）；175 项模型测试无跳过，全部 Host/RV64 runner 通过 |
| RTL 聚合 | PASS（P2）；视频整帧、Tensor DMA/Ingress、真实 L2、MemoryParallelV3、PPU、cache |
| P5 导航与工具检查 | PASS；175 原生测试无跳过、33 个 Host runner、构建/ELF/依赖/链接检查及自动 core + L2 回归；日志位于 `build/refactor/p5/` |
| 无旧产物的干净 checkout 验证 | PASS（`3d52a66`）；两份固件、175 项模型测试、33 个 Host runner、`test-rtl` 聚合、timing repair 和最终依赖；[机器记录](single-version-final.json) |
| 本轮 Vivado 工程 / RTL elaboration | PASS；实际 SoC/DDR port lint、GUI/batch 属性与 timing hook 审核均 PASS |
| 本轮整机综合 / 实现 / bitstream / 最终 setup、hold、WNS/TNS、bus skew | INTERRUPTED_RESOURCE；26 个 IP 综合 PASS，整机 synth_1 因共享机器 RAM/swap 耗尽主动停止；impl/bitstream/最终时序未执行或未生成 |
| 当前 bitstream + ELF 的视频持续推理、回收、drain/restart、overlay | PENDING；未执行本轮板测 |
| 当前三图 `M/t/a` 数值与性能 | PENDING；未执行本轮板测，不引用旧开发工程成绩充当当前结果 |

逐阶段命令、路径映射、删除依据、失败与修正见 [实施记录](single-version-refactor.md)。
原始日志、依赖、哈希、ELF 和生成结果比较分别位于忽略的 `build/refactor/p0` 至 `p5`。
旧本地产物保留，不能将旧 bitstream 与当前 ELF 混用。

R0 Tensor 版本回绕仍存在已知缺口：测试输出 `characterization=PASS / correctness=FAIL`。
本轮未改版本比较或协议，不声称已修复。当前 V17A-family adapter、冻结 native 输入为
正式依赖；禁用实验分支和冻结辅助工具的进一步裁剪因证据不完整而保留，见
[退休/保留清单](single-version-retirements.json)。

基线硬件的局部综合和时序修复分别见 [硬件原验收](latest-hardware.md) 与
[V3 修复记录](v3-timing-repair.md)。这些记录只属于各自身份和测试范围，不能替代本轮
新工程的整机实现或板端证据。板测验收流程见 [快速开始](../quickstart.md)。
