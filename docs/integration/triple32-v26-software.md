# V3 + Tensor 的 v26 软件移植

2026-10-14 将开发工程 `/mnt/data/sunys/sixteen_camera_3x32_100mhz_timing_v3_2026-10-07`
的 v26 可用配置移入当前主分支，基线为 `b932ca6`（R5）。默认使用 credit-cap4
正式版，保留 cap3 对照和 cap3/cap4 诊断基准。硬件仍为已有 `triple32_v3_tensor`。

## 配置和来源

| 参数 | 当前值 |
| --- | --- |
| workers / DIM / clock | 3 / 32 / 100 MHz |
| native opcode | custom3、custom2、custom1 |
| credit limit / hardware SAFE_MAX | 4 / 4；cap3 对照为 3 / 4 |
| submit burst / CPU quantum | 1 个完整包 / 200 µs |
| context / scheduling | light（FP/VCSR 保留）/ fixed |
| packet preparation | fixed plans + fixed packets + prepared WS/LUT |
| submit optimization | credit query + packet dispatch |
| local wait | tail wait + 13 处静态证明的相邻等待复用 |
| Pool / Resize | 硬件 memory operators；Resize 按 accumulator 容量批处理 |
| Resize row setting | 0，生成的两处实际批次上限 15 / 12 行 |
| PPU / Head | A：局部完成后发布，整图完成后入队 |
| formal diagnostics / capacity sampling | 关闭 / 关闭 |
| software batch（v27/v28）/ RoCC layer profiling / supply hooks | 关闭 / 关闭 / 关闭 |

开发目录当前保存演进后的共享源码，不是独立冻结的 v26 checkout。本次从该共享
源码导入，按开发版 `credit-cap4` 的开关锁定 v26；保留被禁用的后续实验源码，
没有启用 v27/v28 策略。`import_v26_manifest.json` 同时记录来源源码 SHA、
适配后 SHA 和开发版原 cap4 构建 manifest；这些源码与原 v26 构建 manifest
中的部分 SHA 不同，因此当前 ELF 是重新构建的整合版，不能视为原 ELF 的复刻。

开发版日志 `p1_capacity_test.txt` 的 cap4 独立执行中位数为 11,919,168 cycles，
cap3 为 11,966,680 cycles（cap4 约快 0.397%）；cap4 串行/独立加速比约 2.340。
这些是开发工程板测证据，当前工程速度和数值正确性仍需下述板测确认。

权重、冻结原生模型、FP16 Gemmini ABI 和 Head 布局与移植前一致。参数使用
当前 SoC 的生成头，三个参数头均声明 SAFE_MAX=4；三个生成的 Gemmini RTL
均按 outstanding<4、ingress queue<2 且无 partial packet 给出 can_submit。
没有更改 RTL、SoC shell 或实现约束，也没有启动综合或下载开发板。

## 实时 Runtime 整合

`v26.mk` 同时服务视频与独立基准。视频启用 `YOLO32_LIVE=1`，沿用 R5 的
Core、EDF、Tensor lease、activation arena、六槽 Head/PPU Service、结果版本和 Overlay。
V17A 名称保留为内部 DIM32 ABI family profile；后端名称和启动信息显示 v26。

每个新帧独立重置该 worker 的 credit 计数、退休观察缓存、错误轮询计数及
wait-reuse 完成证明。旧帧必须完成并释放 native 所有权后才初始化新帧。
只有一个 worker 有任务时仍在包/时间边界返回视频循环；全部 WAITING 或
WAIT_CREDIT 时一次扫描返回，按活动帧计算超时，长期空闲不触发批次超时。

credit 使用 CPU 已发包数减 hardware retired，包含尚未被 accepted 的 ingress
指令。可复用的退休预算不替代入口权限；实际提交/恢复始终重新读取 can_submit。
Head 证明仍同时要求原生局部 ingress、accepted/retired 和 DMA 完成。

切换 cap3/4 或诊断开关会更新配置 stamp，并重编译所有相关对象（包括汇编、
基准 main/PPU）。视频交付脚本显式固定 cap4、diagnostic=0，防止外部环境使
编译参数与交付 manifest 不一致。模型源码、输入和依赖全部位于当前仓库。

## 构建和离线验证

```sh
make firmware SOC_VARIANT=triple32_v3_tensor
make firmware-benchmark
make test-v26
make test-software
make check-v26-firmware
make check-deps SOC_VARIANT=triple32_v3_tensor
make -C sw/models/yolov5nu/triple32 credit-cap3 credit-cap4-diag
```

视频 ELF：`build/firmware/gemmini_triple32_v3_tensor_video_yolov5nu.elf`。
默认基准：`build/firmware/triple32_v26_benchmark/yolo32.elf`。
对照/诊断基准：`build/firmware/triple32_v26_credit_cap3/yolo32.elf` 和
`build/firmware/triple32_v26_credit_cap4_diag/yolo32.elf`。

视频 JSON 记录配置、参数、源码锁、生成计划和 ELF 哈希；基准
`capacity_manifest.json` 记录三图输入、工具链、计划和 ELF 哈希。
`check-v26-firmware` 审核实际 ELF 的 PPU read barrier、light FP/VCSR context、
正式版无上下文诊断计时、credit/Pool/Resize 代码路径及三个 Gemmini 入口容量。
旧 `test-v17a` / `check-v17a-firmware` 入口已退休；使用 `test-v26` / `check-v26-firmware`。

离线回归覆盖包参数与顺序、Split-K、FP16、credit 上限/入口变化/错误/超时、
等待证明复用、Pool/Resize 数值和 guard、延迟 DMA、真实 RVV256/full/light
上下文，以及现有 R0–R5 的应用与资源生命周期。新增实时 cap3/cap4 回归在
Host 和 QEMU 上覆盖稀疏 worker、入口拒绝、预算耗尽、退休延迟、计数回绕、
Head 发布、单 worker 复用和长空闲；真实汇编使用正式版诊断关闭配置。
175 项原生回归与全部软件脚本通过，见 [离线验收](../validation/triple32-v26.md)。
详细运行证据保存于忽略的 `build/ports/v26/logs/`，迁移前 ELF/源码保存在同目录 baseline。

## 上板验证

2026-10-14 后续硬件已升级为三路 MaxPool / timing 策略并合并 TensorIngress，
旧硬件规格已退休；请先按 [当前硬件说明](triple32-v3-tensor.md) 重新生成、加载最新bitstream。
以下软件命令仍适用，前文“本次没有硬件改动”仅指v26软件移植阶段。

使用已经验证的 V3 + Tensor bitstream。实时视频下载：

```sh
make program SOC_VARIANT=triple32_v3_tensor PROGRAM_ARGS=--no-build
```

串口 115200 8N1；启动应出现 `native=v26 credit_limit=4 memory_ops=1`
和 `diagnostic=0`。`h/v/s` 检查命令、视频和 AI 状态，`i` 启用推理；观察结果、
Tensor/Head 回收和 overlay，随后 `i` 排空，再启用，确认可以持续运行和复用。
保留当前本地 JTAG 序列号配置；下载时先释放 Vivado 对该目标的占用。

三图数值和计时验证使用独立基准，不在实时视频中执行固定输入命令：

```sh
ELF_FILE="$PWD/build/firmware/triple32_v26_benchmark/yolo32.elf" \
  make program SOC_VARIANT=triple32_v3_tensor PROGRAM_ARGS=--no-build
```

依次发送 `M`、`t`、`a` 并保存完整日志：`M` 校验三 worker 的 Pool/Resize
逐元素结果和 guard；`t` 先生成串行基准再比较独立执行的原始 Head 与 PPU 结果；
`a` 运行五模式、预热与五轮计时。必须看到 memory、独立执行和 benchmark
PASS 且零 mismatch。输入025/036/142的开发版检测数为1/2/5，仍以逐字节比对为准。

```sh
python3 tools/analyze/yolov5nu/analyze_log.py /path/to/v26-uart.log --latest
```

需要对照时下载 cap3 ELF，用同样的 M/t/a 流程比较。诊断版下载对应
`credit_cap4_diag` ELF，`d/D` 分别每16/64次查询采样；诊断计时不能混入正式版成绩。
最终以当前 bitstream + 当前整合版 ELF 的完整日志确认数值、稳定性与性能。
