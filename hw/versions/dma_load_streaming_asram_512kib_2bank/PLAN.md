# 合并版实施与验收

1. ASRAM 完整源码快照作为底座，迁入 Stream A1；记录两个父版本及本地 SHA256。
2. 保留 ASRAM 地址过滤与本地 planner，合并 A1 行就绪、事务最后片段与最终信用保护。
3. 编译实际本地 Scala，验证 buffered/streaming 单元、ASRAM 控制器和实际 URAM 存储。
4. 生成独立完整 SoC RTL，验证身份、三个 worker、四模式、PMA 和保留范围。
5. 联合真实 Gemmini/Reader/ASRAM，验证 DDR/local/混合路径、提前写、反压、边界、错误和排空。
6. 首层/代表层/参数化 SPAD 与 frontend 回归；软件三 ELF 审计、原生计划等价和故障注入。
7. 保存本候选来源、仿真命令及结果，明确尚未执行的 CPU/RVV、整网板测与物理实现。

正式软件保持模型、输入、tiling、RAW/DRAIN/HOST、Head/PPU 发布协议。原始 Head/PAD
诊断与正式计时分离。不得将父版本板测或假设备结果升级为本版本真实硬件通过。
