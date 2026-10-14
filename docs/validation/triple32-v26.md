# v26 软件移植离线验收

日期：2026-10-14。基线：`main` 的 `b932ca6`（R5）。
默认目标：`triple32_v3_tensor` / v26 credit-cap4 / formal。
实现和上板步骤见 [集成说明](../integration/triple32-v26-software.md)。

## 本次结果

| 检查 | 结果 |
| --- | --- |
| `make test-v26` | PASS；175 项 native Python 回归，无跳过；原有 live/backend 回归通过 |
| v26 sparse live cap3/cap4 | Host 与 QEMU RV64GCV/RVV256 全部 PASS；真实正式版 light 汇编 |
| `make test-software` | PASS；全部 host 脚本退出码 0 |
| R5 Application、生产 Backend、ELF audit fixture 的最终补验 | PASS |
| 三变体视频 ELF | triple32_v3_tensor、dual16、single4 均 PASS |
| 独立基准 ELF | cap4 formal（默认）、cap3 formal、cap4 diagnostic 均 PASS |
| 同目录配置切换 | cap3 formal → cap4 diagnostic → cap4 formal，main/independent/task_switch 全部重编译；正式上下文无 rdcycle，诊断版有 rdcycle |
| `make check-v26-firmware` | PASS；实际 ELF 的 PPU 顺序屏障、FP/VCSR light context、credit/Pool/Resize 路径、配置和三路硬件容量检查通过 |
| `make check-deps SOC_VARIANT=triple32_v3_tensor` | PASS；源码锁、构建依赖闭包、工具和 production manifest 通过 |
| `make program ... PROGRAM_ARGS=--check` | PASS；仅检查工具/ELF，没有连接开发板 |
| fixed plans / memory kernels | 两份完整 JSON 均与开发版 credit-cap4 一致 |
| 源码边界 | `hw/`、Runtime Core/services、设备 HAL、PPU/Overlay 策略及 `sw/src/main.c` 无变更 |
| 当前工程上板数值/性能 | 未执行；开发工程的速度不能代替当前整合版测试 |
| 综合、布局布线、bitstream、板端下载 | 未执行；本次没有硬件改动 |

主机回归保留已有 R0 Tensor version 回绕的 `correctness=FAIL / characterization=PASS`
特征标记；它是已记录的协议缺口，本次没有改变该行为。上述软件脚本通过表示
对应回归断言通过，不表示板上数值或该既有缺口已经修复。

## 交付身份

视频 ELF SHA-256：
`3c000ab9b7d6bd6df26263d7bde61d1b480ceac9d05c41b7faed7c6137534c30`。

默认三图基准 ELF SHA-256：
`37a9686c7f0174903eb7899cd5151f434d3d50ea5e42201b5d9dadeaa4af4d33`。

cap3 formal 基准 SHA-256：
`1a66b4fae0c54e874c0549b20b6b35a34edad8de1d8ecbc00101c9cb70fb5308`。

cap4 diagnostic 基准 SHA-256：
`9c8dc597ae7861a5fb1618227f61baf8d6332fa787d5d5a23f23d7d41d5ef387`。

这些 SHA 对应本次离线构建，后续构建以同名 manifest 的实际 ELF 哈希为准。
开发版 v26 原 ELF 与当前演进共享源码并非相同源码快照，导入时同时保存二者
身份并重新构建验证，没有宣称当前交付 ELF 与开发版原 ELF 字节相同。

## 证据位置

忽略目录 `build/ports/v26/` 保存：迁移前源码/ELF、读取时开发版源码与
原 cap4 manifest/ELF、开发版性能日志、最终三变体与基准 ELF/map/反汇编、
依赖源码 SHA、生成计划、构建参数、配置切换记录和全部测试日志。
`final/validation.json` 汇总身份和检查结果。
可提交来源记录为 `sw/models/yolov5nu/triple32/import_v26_manifest.json`；
当前源码与输入的闭包由 `sources.lock.json` 校验，构建不依赖开发目录。
