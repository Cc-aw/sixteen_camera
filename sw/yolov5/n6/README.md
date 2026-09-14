# YOLOv5nu 640×480 → Gemmini64 N6 软件适配

2026-09-10，作者：王志瑞。状态：五图 ELF 编译完成，主机 split-K 检查通过，**尚未完成 N6 板测**。不修改 RTL，不生成新比特流。使用已冻结且通过 TinyYOLOv2 板测的 Scale32/N6/chunked_no_norm 硬件；它的 YOLOv5nu 正确性仍待验证。

## 适配内容

- `platform/` 固定当前 N6 软件接口及其来源哈希，参数使用原生成包：DIM=64、8×1024 SPAD rows、2048 ACC rows、custom3、busy CSR=0x7c2。启用既有 LoopConv credit admission，最多 4 个未退役请求。
- 使用现有 N6 的矩形卷积/SiLU 软件接口和原板上 UART/链接方式，UART=0x10020000、divisor=868、115200 baud，计时基准 100 MHz。
- 保留 7 个 shared Add、17 条 split-K edge、4 组双消费者复用、69 个动态 SiLU LUT；没有改量化参数或模型权重。
- split-K 允许 J=32 的输出尾块，向每个 partial 传递真实 pad_J；原有 K/I 尾块保留。tile I 同时受半 ACC 容量及半 SPAD 的 A+B 容量限制。双消费者使用两侧都可容纳的 tile I。
- CPU→Gemmini 之前清理输入及输出范围；Gemmini 完成后清理输出范围再交给 CPU/RVV。缓存操作复用已通过 N6 测试中的 64-byte flush 寄存器 0x02010200。LUT/scale 切换前等待 busy 清零；此路径以正确性为先，包含串行等待和缓存维护成本。
- 正常 Conv、split-K helper 和 shared Add 记录现有 8 个 DMA/Execute 递增事件，不改变 CounterFile RTL。
- 取消原 AOT 末尾无条件 PASS，改为比较独立 hardware integer reference：504000 个 class logits、504000 个 class score、6300 个候选 mask 以及候选位置的 4 个 DFL 值。检测输出的 top/NMS 仍保留打印，当前自动判定范围为这些 head 元素和 mask，不声称已自动比较 bbox/NMS 的所有浮点字段。

原样迁入的 874 个文件没有修改；`prepare.py` 从这些 AOT 生成 `build/yolov5nu_n6/<image>/main.c`，并链接来自 reference NPZ 的逐元素参考数据。源码及参数头不是对源仓库的软链接。

## 编译

在仓库根目录：

```bash
bash scripts/build_yolov5nu_n6_board.sh
```

默认使用 `/home/wzr/chipyard/.conda-env/riscv-tools/bin/riscv64-unknown-elf-gcc` 和已验证可读取参考数据的 `/mnt/data/fff/chipyard/.conda-env/bin/python`。可设置 `RISCV_ELF_PREFIX`、`YOLOV5NU_PYTHON`；Python 只需 NumPy，适配不重新导出或量化模型。

产物：

```text
build/yolov5nu_n6/025/yolov5nu_n6_image025.riscv
build/yolov5nu_n6/036/yolov5nu_n6_image036.riscv
build/yolov5nu_n6/142/yolov5nu_n6_image142.riscv
build/yolov5nu_n6/404/yolov5nu_n6_image404.riscv
build/yolov5nu_n6/650/yolov5nu_n6_image650.riscv
```

各 ELF 约 4.75 MiB，包含用于检查的参考张量；入口 0x80000000，RV64GCV/LP64D。逐图目录保存编译日志、map 和 ELF 属性；ELF_MANIFEST.json/SHA256SUMS 记录哈希。编译仅有既有链接脚本的 RWX LOAD segment warning，没有编译错误。

## 已完成验证与边界

- 五图交叉编译/链接成功，入口地址、RISC-V ISA 属性已核对。
- `python3 sw/yolov5/n6/test_splitk.py`：直接提取已适配的 split-K C helper，通过独立标量 WS 模型执行 192 组用例、1000 次 partial 调用，对比输出和越界哨兵；覆盖 I 尾块/跨 tile、J32、K16/32、双 LUT 和 A 复用。测试使用单位输入/输出 scale，不替代真实浮点 requant、DMA、RTL 或 RVV 板测。
- 五图候选 mask 数量分别为 10/21/21/10/10，与独立参考 JSON 一致。
- 迁入的全部 874 个源文件哈希保持不变，构建脚本与生成脚本语法检查通过。
- 未运行整网 RTL 仿真、Spike 或硬件。不能据此宣称端到端数值/性能通过。

## 下板与日志

先确认板上下载的是冻结 N6，比特流位置：
`debug/versions/20260909_scale32_n6_chunked/bitstream/top_merged.bit`。

串口按已使用的 `/dev/ttyACM0`、115200/8N1 保存完整日志后，在仓库根目录加载第一张图：

```bash
bash scripts/run_yolov5nu_n6_board.sh 025
```

脚本只校验 ELF 哈希并调用既有 JTAG 软件加载流程，不下载比特流、不占用 UART。后续依次将 025 换成 036/142/404/650。推荐日志名 `log/yolov5nu_n6_640x480_image025_run1.log`。

末尾必须出现 `N6_CHECK` 四项 mismatches 全为 0，及 `RESULT: PASS - YOLOv5nu N6 hardware integer reference`。重启后至少复跑一次以检查确定性。

`YOLOV5NU_PROFILE` 保留原逐算子/检测头耗时；其中 Conv 计时包含本次缓存与计数采集开销。`N6_MEMORY` 提供每个硬件调用/双消费者组的计数，cycles 不含外层 pre/post cache flush；双消费者合并记录，不能解释成其中单个 Conv 的周期。`N6_CACHE` 单独汇总所有缓存维护时间和实际 flush 字节数，不能当作 DMA 搬运字节量。

RDMA_TL_WAIT 是请求 A 通道 valid&&!ready，不能直接表示 DDR 带宽饱和。事件可重叠，不能相加为总耗时；EXE_ACTIVE 是 compute 状态，不是真实 PE 有效 MAC 比例。只有数值检查通过后，才使用本次实际模型记录定位瓶颈。

## 2026-09-10：修正 v1 检查器的布局错误

用户 image025 首跑的三项 checksum、Top-10 和 NMS 与来源板测及 reference JSON 一致，但 v1 新增检查器错误地把实际 location-major 输出当作 class-major。对参考数组做转置再使用旧比较方式，可精确复现 class logits=463654、class scores=106 的 mismatches。DFL 同样用了错误索引，且错误索引会读到未计算的非候选位置，不能据此判断 40 个有效 DFL 值都计算错误。

v2 改为 logits/scores 实际 `p*80+c` 对参考 `c*6300+p`，DFL 实际 `p*4+e` 对参考 `e*6300+p`。独立候选 mask 检查保持不变。没有放宽正确性条件。

`test_head_check.py` 提取真实 C 检查器，对五图参考转为 location-major 后检查全零误差，再分别注入 logits、scores、有效 DFL 和 mask 错误，均能检测。五图 ELF 已重新编译，启动标识 `revision=n6_port_v2`；同时显式开启原 AOT 默认关闭的 `YOLOV5NU_PROFILE=1`，使逐算子/整网统计实际输出。

该次首跑是检查器错误的证据，不能回填为全元素板测 PASS。请加载 v2 ELF 再验证。比特流继续使用原 N6，无需重生成或更换。

## 当前候选 v3_opt：固定 N6 比特流的软件优化

产物改为 `build/yolov5nu_n6_opt/<image>/yolov5nu_n6_image<image>.riscv`；原 v2 ELF 保留在 `build/yolov5nu_n6/`，对应源码与通过日志保留在 `debug/yolov5nu_n6_v2_20260910/`。当前构建/加载脚本默认使用 opt 目录。

- 编译阶段在主机运行平台头文件中原样提取的整数 tiler，为 58 个普通 Conv 生成显式 tile；板上直接调用 `tiled_conv`。未改变算法选择的 tile、张量形状、权重、量化和执行顺序。`tiles.json` 保存分块，`host_tiler.c` 保存实际搜索实现。
- arena 每个 64-byte 缓存行记录“自最近 CPU arena 操作以来已清理”。连续硬件算子不在 CPU 缓存中分配张量行，可跳过重复清理；每个 CPU/RVV profile 操作前保守清除全部记录。非 arena 范围始终执行原 flush，DMA 完成等待及每个实际 MMIO flush 的前后 fence 均保留。
- 默认只输出检测结果、数值校验和汇总，382 条逐 record 和 78 条 memory 明细不打印。需要详细诊断时用 `N6_VERBOSE_UART=1 bash scripts/build_yolov5nu_n6_board.sh` 重编译。
- 将三项 tensor summary 和 Top-10 打印全部移至 NMS 结束之后；从 graph_start 到 inference_cycles 为连续计时，正常路径不调用任何串口打印。新 `N6_INFERENCE` 的 FPS 使用 `100000000 / inference_cycles`，包含图计算、必要缓存维护、decode/NMS 和计数采集开销，不包含 UART、最终参考校验、模型启动、图片预处理与外部视频 I/O。日志到达时间、终端输出速度绝不作为帧率。
- NMS 阈值改用整数千分数输出，兼容 nano printf，避免浮点格式为空。

v3_opt 是待板测候选，不能预先承诺加速幅度；只使用最终 RESULT: PASS 的记录评估性能。首测仍运行 `bash scripts/run_yolov5nu_n6_board.sh 025`，应看到 `revision=n6_port_v3_opt`。建议保存为 `log/gemmini64_yolov5_opt_run1.log`。无需更换或生成比特流。

v3_opt 本地主机回归结果：192 组 split-K 数值/尾块检查通过；五图 location-major 检查器及四类错误注入通过；缓存行重复访问、CPU 操作重置、范围外地址和不合法 arena 回退检查通过。五图均确认 58 个显式 Conv 的所有非 tile 参数与 v2 相同，正常路径推理计时区间没有 printf/print 调用，参考校验位于计时终点之后。以上不代替 N6 板测。

## 当前候选 v4_direct_cache：保留静态分块/串口，恢复直接缓存清理

用户确认后，恢复 v2 的 `n6_flush` 原实现，包括范围计数和每行前后 fence；移除运行路径中的位图查询、更新及 CPU 操作前的位图清零。保留 v3 的 58 个预生成 Conv 分块、紧凑串口输出、location-major 逐元素校验和不含 UART/校验的连续推理计时。本次用于隔离 v3 缓存策略的性能影响，不预先判定收益。

新产物目录 `build/yolov5nu_n6_v4/`。当前构建/加载脚本默认使用 v4；v2 和 v3 ELF 仍分别保留在原目录，v3 源码及日志归档于 `debug/yolov5nu_n6_v3_20260910/`。

加载命令仍为 `bash scripts/run_yolov5nu_n6_board.sh 025`，确认启动 `revision=n6_port_v4_direct_cache`。建议保存日志为 `log/gemmini64_yolov5_v4_run1.log`。继续使用当前 N6 比特流。比较同一 image025 的 RESULT、N6_INFERENCE、N6_CACHE；单次结果不能代替重复运行及五图验收。

v4 源码回归检查通过：直接 flush 与 v2 逐字节相同；五图各 58 个显式 Conv 的分块、操作数及算子标签与 v3 相同；运行源码不再调用位图初始化/清零；计时区间无正常打印，最终参考校验在计时结束之后。五图生成源码均可由最终生成器与已记录的 tile 完整复现。该版本仍待板测，不标记性能 PASS。

## v5 详细计时版（2026-09-10）

按本轮要求先收集耗时，再制定优化策略。沿用现有 N6 比特流及 v4 的分块、计算和直接缓存清理行为。默认开启 `N6_VERBOSE_UART=1`，产物目录 `build/yolov5nu_n6_v5/`；v4 ELF 和源码快照保留。新增代码 IPOAT 作者为王志瑞。

计时结果在推理结束后输出：

| 记录 | 含义及包含关系 |
|---|---|
| `N6_INFERENCE` | 连续图执行、解码、NMS；不含 UART、参考校验、输入预处理 |
| `YOLOV5NU_PROFILE record=` | 全部逐算子、SiLU 配置、Conv 子阶段、CPU 运算、检测头、解码和 NMS；Conv 子阶段不可再加到 Conv 总计 |
| `N6_SCOPE` | 每个硬件调用组的总时间，含前后缓存清理、显式等待、提交及计数采样开销；双消费者共用一个组 |
| `N6_FLUSH` | 每次缓存清理的组序号、64 字节对齐地址、范围字节数、耗时；phase=0 为调用前，1 为调用后 |
| `N6_MEMORY` | 每组调用窗口及 8 个硬件事件；事件相互重叠，不能当互斥耗时求和 |
| `N6_TIMING` | 调用组与缓存记录数量、溢出计数及小计；overflow 必须为 0 |
| `N6_REPORT` | 推理结束后主要结果与计时明细的格式化和 UART 调用时间，不含此行、后续校验和尾部输出 |
| `N6_VALIDATION` | 参考校验及该函数一行 N6_CHECK 输出时间，明确与推理隔离 |

`N6_SCOPE.wait_cycles` 只记录 runtime 的显式 busy/fence 等待，不覆盖 Gemmini 头文件内部的所有阻塞。`other_cycles` 是总时间扣除缓存和显式等待，仍包含提交、内部阻塞和计时开销，不能视为纯 CPU 计算。缓存 fence 开销属于 cache 项。新增记录写入内存会影响测得性能，v5 用于诊断，不能把它的 FPS 直接当作无测量开销的生产性能。

所有计时均为 100 MHz 下的 cycle（100 cycle = 1 微秒）。日志分析保留图执行与算子小计之间的未归属时间，避免把无法解释的时间硬归因于访存。现有计数器不能直接得出 DDR 带宽或真实 PE 利用率。

在仓库根目录，先打开串口终端：

```bash
picocom -b 115200 --databits 8 --parity n --stopbits 1 /dev/ttyACM0 | tee log/gemmini64_yolov5_v5_run1.log
```

保持串口终端运行，在另一终端加载软件（无需重新生成/下载比特流）：

```bash
bash scripts/run_yolov5nu_n6_board.sh 025
```

头部应显示 `revision=n6_port_v5_timing`。等到最终 `RESULT` 再结束日志；打印明细所需时间不计入 FPS。每个文件只保存一次完整运行。

```bash
python sw/yolov5/n6/analyze_timing.py log/gemmini64_yolov5_v5_run1.log --output log/gemmini64_yolov5_v5_run1.json
```

分析脚本核对缓存字节/耗时、组内拆分、记录数量和溢出，并生成耗时排序与未归属时间。先测试 025，取得日志后再分析优化策略。软件回归：`python sw/yolov5/n6/test_v5.py`。

## v6 卷积分块候选（2026-09-10）

当前构建/加载脚本使用 `build/yolov5nu_n6_v6/`，revision 为 `n6_port_v6_conv_tiles`。五图 ELF 编译完成，尚待板测。保留 v5 ELF 和 `debug/yolov5nu_n6_v5_20260910/source/` 源码快照。

仅调整 conv1 分块为 `[1,14,64,32,3,3,16]`、conv7 为 `[1,13,64,64,3,3,32]`，依次为 batch、输出行、输出列、输出通道、核行、核列、输入通道。原始容量公式核验通过；预计 LoopConv 分别 27、10 次。`tiles.json` 仍记录原搜索器的基线结果，实际覆盖后的参数以生成的 `main.c` 及本节为准。其他计算、缓存清理、量化、LUT 和 credit 安全上限保持原样。

`n6_credit_profile.h` 必须先于 gemmini.h 包含，才能接入已有 admission hook。新增 `N6_CREDIT` 每组输出 calls、waited_calls、wait_cycles、accepted、retired。等待周期只覆盖进入 credit 等待分支后的轮询区间，不含首次成功查询开销。它包含在原调用窗口及部分 scope other 内，不能和总耗时再次相加。硬件接收/完成计数使用 32 位无符号差值处理回绕。普通 Conv 预计 calls=accepted=retired；非 LoopConv helper 不应据此解释为没有硬件执行。

先运行 image025，串口终端：

```bash
picocom -b 115200 --databits 8 --parity n --stopbits 1 /dev/ttyACM0 | tee log/gemmini64_yolov5_v6_run1.log
```

另一个终端：

```bash
bash scripts/run_yolov5nu_n6_board.sh 025
```

无需更新比特流。正常路径 UART 与校验仍在连续推理计时之外。待最终 RESULT 输出后分析：

```bash
python sw/yolov5/n6/analyze_timing.py log/gemmini64_yolov5_v6_run1.log --output log/gemmini64_yolov5_v6_run1.json
```

通过条件：四项 mismatch=0、overflow=0、计时记录完整、硬件接收/完成与提交数匹配。重点对比 conv1/conv7 的 N6_MEMORY cycles 与 v5 的 4,835,918 / 2,525,221 cycles，并观察 RDMA 和 EXE 事件、总推理时间。未实测前不承诺加速比例。随后补测其余四图及重复运行。

回归测试 `python sw/yolov5/n6/test_v6.py`：五图生成 C 除两层 tile、版本字符串和 hook 头文件外与 v5 完全一致；缓存函数逐字一致；容量、真实 hook 主机测试及 v6 日志计数异常拒绝通过。编译仅有沿用链接布局的 RWX LOAD 提示。

### v6 启动后无输出：独立诊断版

image025 板上日志仅到 `Memory plan stage: 5d`，未得到 RESULT，因此不能宣称 v6 正确或判断具体阻塞层。原容量检查只验证软件模型，尚未证明新分块硬件执行路径可完成。

`scripts/build_yolov5nu_n6_diag.sh` 从 v6 image025 创建独立目录 `build/yolov5nu_n6_v6_diag/025/`，保留原分块/清理调用并添加启动、调用组、缓存阶段和命令阶段输出。runtime busy 轮询和 credit 轮询超过约 1 秒会打印 N6_TIMEOUT，包含层标签、busy、status、accepted、retired，然后停止软件。阻塞在单条 RoCC/MMIO 指令时软件超时不能打断，此时最后一条阶段日志仍可用于定位。

诊断版单图编译成功；两层 tile 与所有 flush 调用和 v6 一致。诊断日志会改变调度与时间，`N6_DIAG_INFERENCE performance_valid=0 uart_included=1` 不用于 FPS 比较。原 v6、v5 ELF 及默认测试脚本保持原样。

测试前先复位整个系统（包括 Gemmini；如不能确定，可重新下载同一 N6 比特流），避免上次未完成命令残留。打开串口保存 `log/gemmini64_yolov5_v6_diag_run1.log` 后，在另一终端执行 `bash scripts/run_yolov5nu_n6_diag.sh`。无需生成新的比特流。

## v7 第一层 64 列对齐对照（2026-09-10）

当前构建/加载脚本目标 `build/yolov5nu_n6_v7/`，revision=`n6_port_v7_conv0_align`。相对 v6 仅 conv0 tile 从 `[1,12,66,16,6,6,3]` 改为 `[1,12,64,16,6,6,3]`；保留 conv1/conv7 优化、其他计算参数、缓存和 credit 策略。v6 ELF 和源码快照保留。

预期 conv0 外部 LoopConv 次数仍为 100，conv1=27、conv7=10。内部计算分组静态推导 12960→7200，不是硬件实测计数，也不承诺同比加速。容量模型 SPAD=3965/4096、ACC=768/1024。FPS 仍排除串口与校验。

使用已确认正确的同一 N6 比特流。串口终端：

```bash
picocom -b 115200 --databits 8 --parity n --stopbits 1 /dev/ttyACM0 | tee log/gemmini64_yolov5_v7_run1.log
```

另一终端：

```bash
bash scripts/run_yolov5nu_n6_board.sh 025
```

等最终 RESULT 输出后：

```bash
python sw/yolov5/n6/analyze_timing.py log/gemmini64_yolov5_v7_run1.log --output log/gemmini64_yolov5_v7_run1.json
```

重点比较 conv0 N6_MEMORY（v6=2719594 cycles）、EXE/RDMA、credit 等待及连续推理（v6=25774213 cycles）；检查四项 mismatch=0、overflow=0 和调用计数一致。软件回归：`python sw/yolov5/n6/test_v7.py`。其他四图编译产物一并提供，板测正确性尚待确认。

## v8 访存诊断（2026-09-10）

两套分块使用相同诊断实现：`v6` 保留首层12×66，`v7` 使用12×64；其他计算完全对应各自基线。当前加载脚本默认 image025/v6。输出目录分别为 `build/yolov5nu_n6_v8_ddr_v6/`、`build/yolov5nu_n6_v8_ddr_v7/`，各含五图 ELF。原版本 ELF 保留。未修改缓存维护或 RTL，继续使用已确认正确的 N6 比特流。

构建命令：`bash scripts/build_yolov5nu_n6_board.sh v6` 或 `v7`。头部分别为 `n6_port_v8_ddr_v6`、`n6_port_v8_ddr_v7`。

八个普通事件改为：加载请求端回压、存储请求端回压、EXE active、RDMA active、WDMA active、RDMA TL请求受阻、RDMA TLB等待、WDMA TL请求受阻。`N6_MEMORY` 使用准确的字段标签；不再输出本次没有选中的 load_active、store_active、exe_q_block。

新增每组 `N6_DMA`：

- `rdma_bytes_raw`：现有硬件原始值，64字节双拍响应重复计数，不能直接作为带宽分子。
- `wdma_transaction_bytes`：写事务覆盖字节，不按写mask折算有效字节。
- `rdma_occupancy_cycles`、`wdma_occupancy_cycles`：逐周期在途事务数积分，非纯DDR延迟。
- `rdma_multibeat_overcount=1 ddr_bytes_measured=0`：明确计数限制。

每组先配置普通事件并重置计数，完成等待后保存全部8项，再切换4个槽读取外部累加器；切换期间不重置计数，下一组重新配置。外部计数器一直累计，不要求开始时占用事件槽。计数/日志格式化不在层调用窗口内，但采样软件开销仍在总推理计时内；UART 和参考校验继续排除。

分析脚本给出 DMA 32/64字节响应量 `[ceil(raw/2), raw]` 的范围及平均在途事务数近似值，前提为单组32位累计量未回绕。它不会输出伪精确DDR带宽。每组已重置；全图不能直接套用未重置情况下的安全假设。

先跑 v6 分块诊断，串口终端：

```bash
picocom -b 115200 --databits 8 --parity n --stopbits 1 /dev/ttyACM0 | tee log/gemmini64_yolov5_v8_ddr_v6_run1.log
```

另一终端：

```bash
bash scripts/run_yolov5nu_n6_board.sh 025 v6
```

等最终 RESULT 后结束本次串口记录，再为 v7 建立新日志：

```bash
picocom -b 115200 --databits 8 --parity n --stopbits 1 /dev/ttyACM0 | tee log/gemmini64_yolov5_v8_ddr_v7_run1.log
```

另一终端：

```bash
bash scripts/run_yolov5nu_n6_board.sh 025 v7
```

一份日志只保存一次运行，勿同时打开两个串口程序。分析命令：

```bash
python sw/yolov5/n6/analyze_timing.py log/gemmini64_yolov5_v8_ddr_v6_run1.log --output log/gemmini64_yolov5_v8_ddr_v6_run1.json
python sw/yolov5/n6/analyze_timing.py log/gemmini64_yolov5_v8_ddr_v7_run1.log --output log/gemmini64_yolov5_v8_ddr_v7_run1.json
```

先检查四项 mismatch、溢出、78组DMA记录与credit计数，再比较第一层原始字节、在途占用和回压。两套诊断计时才是本轮直接对照；新增计数开销不能误判为分块性能变化。尚未实现输入重排。

## M01 首层输入重排（2026-09-11）

候选目录 `build/yolov5nu_n6_m01/`，revision=`n6_port_m01_s2d2`。基于 v8/v6 现有五图生成物，仅重写第一层输入/权重布局和卷积参数，其他层保持一致；现有 v8 默认脚本不变，使用独立 M01 脚本。

输入由 RVV 每帧重排：`[480,640,3] → [240,320,12]`，通道顺序为左上RGB、右上RGB、左下RGB、右下RGB。权重离线由6×6×3×16排列为3×3×12×16，卷积 stride2/pad2 改为 stride1/pad1；bias、scale、SiLU LUT及第一层输出地址/形状保持一致。新增独立921600字节对齐输入缓冲，不覆盖原activation arena。

首层 tile=`[1,16,64,16,3,3,12]`；原容量模型 SPAD=1296/4096、ACC=1024/1024；预期75次LoopConv。输入重排后由原首层输入flush位置清理新缓冲区，清理字节数仍为921600，实际成本（包括脏行写回）进入首层scope。缓存算法保持原样。

计时从每帧重排前开始，日志包含 `N6_PREP kind=s2d2 cycles=... bytes=921600 included_in_inference=1`。`N6_INFERENCE input_preprocessing_included=1` 与此前基线的0有意不同；它包含新引入的重排，基线没有这一准备步骤。公平比较整帧总时间，以及 `prep + conv0 scope`；不能仅比较 graph_cycles 或排除新输入flush。UART、参考校验仍在计时之外。解析结果新增 `first_layer_including_preparation_cycles`。

构建：

```bash
bash scripts/build_yolov5nu_n6_m01.sh
```

基于当前已确认正确的 N6 比特流，串口终端：

```bash
picocom -b 115200 --databits 8 --parity n --stopbits 1 /dev/ttyACM0 | tee log/gemmini64_yolov5_m01_run1.log
```

另一终端：

```bash
bash scripts/run_yolov5nu_n6_m01.sh 025
```

等待最终 RESULT 输出；分析：

```bash
python sw/yolov5/n6/analyze_timing.py log/gemmini64_yolov5_m01_run1.log --output log/gemmini64_yolov5_m01_run1.json
```

先测试025，之后可按相同命令替换为036/142/404/650并分别保存日志。板测前不承诺正确性/性能。主机验证包括实际标量打包函数、RVV地址模型/尾段、五图完整第一层整数累加结果、权重变换、下游生成代码一致及计时边界；RVV指令真实执行和硬件最终量化/LUT仍需下板验证。

回归命令：`PYTHONDONTWRITEBYTECODE=1 /mnt/data/fff/chipyard/.conda-env/bin/python sw/yolov5/n6/test_m01.py`，以及 `python sw/yolov5/n6/test_m01_timing.py`。输入测试使用宏长度声明，解析器兼容该形式。源模型及同事代码快照不修改。新增代码IPOAT作者王志瑞，日期2026-09-11。

## DMA profiling 候选（2026-09-11）

新增有效请求/TL 事务直方图、正确的读返回字节、写 mask 字节和在途统计。需要新 profiling ABI v1 比特流，旧 N6 会明确报接口缺失。

构建：`bash scripts/build_yolov5nu_n6_dma_profile.sh v6`；运行：`bash scripts/run_yolov5nu_n6_dma_profile.sh 025 v6`。五图软件已编译，尚未下板。串口排除，新增计数读取开销计入整帧。

[完整说明](../../../doc/Gemmini64_实现架构包_20260908/docs/09_DMA_profiling与请求统计_20260911.md)
