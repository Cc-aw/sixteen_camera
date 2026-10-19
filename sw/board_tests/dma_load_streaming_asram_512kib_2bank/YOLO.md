# 合并版 YOLOv5nu DDR / ASRAM 对照

源码和冻结模型从 `activation_sram_512kib_2bank` 复制；硬件替换为 A1 + ASRAM
新候选。模型权重、输入、量化、DIM32 tiling、B reuse、RAW/DRAIN/HOST、Head/PPU
协议不变。软件通过新 build ID 区分硬件，不以原 ASRAM 比特流代替新候选。

`make all host-check` 构建三份 ELF，按原生 worker/前端与 DDR/local 四种视图
比较完整归一化命令、阶段和数据计划。只移动 activation arena：权重、输入、scratch、
PAD、中间工作区、命令表和 Head 仍按原 DDR 路径。每路 arena 为 2,217,600 B，
每块物理 ASRAM 为 2,359,296 B，检查其余全部 141,696 B guard。

默认 `YOLO_ROUNDS=1`，可设 1～3。每轮两种 storage × 四种 DMA 模式 × 三种
执行器，共 24 个正式窗口，每窗口 12 帧；每窗口预热三帧，初始 DDR legacy direct
基准 12 帧。首轮共 372 次 PPU，编号始终递增。奇数轮反转 storage 顺序。

正式 ELF 计时从批次准备完成到全部 PPU 结果收回，包含 HOST/PPU/调度；比较、
UART、计数器读取和 guard 在计时之外。并行 ms/帧是批次吞吐摊销，不是单帧延迟。
诊断 ELF 运行中读取全部 907,200 B Head 和六次 PAD 源共 230,400 B，周期只作诊断。
所有路径比较 PPU 检测数量和全部 40 个结果字；它不证明独立检测精度。

当前先完成候选 RTL 仿真与离线软件审计，不生成比特流，不运行板测。
`hardware/target.json` 中空 bitstream/hash 代表尚未构建。下载脚本在此状态下拒绝执行。
后续正式运行仍使用 Makefile 的 program-bitstream / uart / program-model /
program-diagnostic / analyze 入口，届时需要显式绑定新候选的实际比特流 SHA256。
