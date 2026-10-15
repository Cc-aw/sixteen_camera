# V33 前端基准软件移植验收

日期：2026-10-15。范围为 standalone V33 正式版和 V33 HOST/PPU 服务诊断版，不导入 V34，不适配实时 Runtime，不修改硬件。

供体目录：`/mnt/data/sunys/sixteen_camera_3x32_100mhz_timing_v3_2026-10-07/sw/yolov5/triple32/frontend`。
执行器、IRQ、启动、HOST/PPU 回调保持供体 V33 源码；源文件和原始哈希见 `sw/benchmarks/frontend/IMPORT_MANIFEST.json`。冻结43项计算/数据输入，其中22项复用仓库内字节相同的已有文件，其余保存到 `sw/models/yolov5nu/frozen/frontend_v33/`。权重 SHA256 与已有模型一致。

供体的 v32 ELF 仅保留其来源哈希，不复制为生成依赖或交付产物。原供体构建清单已过期，本轮从本地锁定输入重新派生计算图并编译两份 ELF，绑定当前硬件生成记录与三个参数头。

| 检查 | 结果 |
| --- | --- |
| 当前硬件 ABI | PASS；DIM32、8×2048 SPAD、2048 ACC rows、FP16 编码与冻结模型一致，使用实际 custom0 参数 |
| 两份 RV64GCV ELF | PASS；入口0x82000000，IRQ按RV64GC编译，旧调度CSR及协程未链接 |
| 建表与原生 oracle | PASS；18张表，逐项比较原 worker_poll 的命令/操作数/等待/HOST边界，建表不依赖或修改张量内容 |
| 真实调度函数 + 假设备 | PASS；正式/诊断两种构建，不等时完成、合并中断、配额、复用和故障注入 |
| 原生 PPU 发布/队列/槽生命周期 | PASS；36帧、ping-pong、全部40结果字及错误注入 |
| 日志契约 | PASS；10项，包括实际C报告语句、丢行、重复、边界和伪PASS |
| 当前硬件/输入/ELF 配对清单、来源与依赖闭包 | PASS；124项文件摘要，冻结源与实际编译副本双重验证 |
| 干净输出目录重建及下载检查 | PASS；正式/诊断均通过离线下载检查，未连接开发板 |
| 配对失效保护 | PASS；编译副本被改、诊断ELF误作正式版均被拒绝，恢复后通过 |
| 供体派生结果和执行器对照 | PASS；12个派生文件、9个执行器/IRQ/启动/ABI源文件逐字节一致 |
| JTAG下载、当前硬件三组36帧数值/性能与时序 | 未执行 |

复现与产物路径见 [V33 入口](../../sw/benchmarks/frontend/README.md)。本轮日志在 `build/reports/v33/`。

本地调度/PPU测试使用模拟时序与数据，不模拟 Gemmini 数学。完整模型命令与原生 oracle 对照通过，不等于板上输出正确；供体历史2.590倍吞吐比不作为本仓库成绩。供体 bit 的已知 WNS=-1.990 ns，当前仓库新硬件尚无整机实现/板测签核，详见 [硬件前端验收](command-frontend.md)。

机器记录见 [v33-frontend.json](v33-frontend.json)。干净输出保留在 `build/firmware/frontend_clean/`；当前硬件的实时 Runtime 未适配保护仍生效。
