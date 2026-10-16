# SW-P3 软件并行缓存候选

本实现从冻结 V33 派生独立自主前端基准，不修改冻结输入、实时 Runtime、Head 地址、PPU ABI 或硬件。默认选择 `reference`，关闭 S1/S2/S3 的运行时选择。输出保存在 `build/firmware/sw-p3/`；原 V33 保存在 `build/firmware/frontend/`。候选保留在显式 `SW_P3_MODE=compare` 构建中，产物隔离到 `build/firmware/sw-p3-compare/`。

## 构建与验证

```bash
make test-sw-p3
make audit-sw-p3
# 仅在需要重新比较候选时执行；会运行 S2 真实 RTL 数值测试。
make test-sw-p3 SW_P3_MODE=compare
make audit-sw-p3 SW_P3_MODE=compare
```

依赖沿用仓库工具配置、RV64GCV 编译器、host C、Python 和 `tests/requirements.txt`。默认 reference 测试不启动 S2 仿真。候选的真实计算测试使用 Vivado 2023.2 的 XSim 和当前导出中的三颗真实 DIM32/FP16 Gemmini；模拟内存和测试表独立生成到 `build/sim/sw_p3_tiling/`。

## 实现路径

- S0：`prepare.py` 的 `SW_P3=1` 分支派生独立源文件。冻结 Gemmini C helpers 精确重生成全部 58 个普通卷积，逐项比较 config、geometry、offsets、launch 和 NULL 语义；不使用通用 generator 覆盖冻结 packet。计划描述、候选参数及建表后的 18 张归一化命令表都可审计。
- S1：五类私有缓冲使用 storage/view 和显式容量。各 storage 对齐 64KiB，保留原 lane 间距的 reference view，候选仅平移整块 view。两轮确定性坐标下降对每个有效维度扫描全部 1024 个 64B 残值；搜索包含原颜色、多种 packet 相对进度和两个连续 packet 的窗口。共享权重 line 去重，Head 专用路径不参加 L2 评分。评分为活跃窗口不同 tag 的 set 压力代理，不是周期预测。
- S2：空间 tile 的有界扫描保持 K 和输出通道分块不变，使用冻结 C helpers 检查 SPAD/ACC 容量并重新编码。独立检查覆盖、读写范围、bias/最终输出、复用槽和 NULL 链。第一版仅允许具有完整真实数值证据的 stage18 晋升；其他候选逐层记录并保留基线。缺少有效证据时，`cache_plan` 自动使用冻结 tile。
- S3：仅在 tag7/tag9 已发布 Head 后决定 RESUME；tag8/tag10 观察到本地完成后释放标记。软上限 2、16,000 周期预算，继续服务其他 HOST/DONE/PPU/watchdog。服务与恢复分开，每个 HOST 只执行一次；默认 profile 关闭，fault/reset 清理状态。

固定 storage 和 volatile 布局参数使两次链接保持已评分对象地址；最终审计逐个检查私有缓冲、输入和权重地址未漂移。归一化全部 S1 命令及 HOST 必须与 V33 oracle 精确一致，旧 V33 检查不放宽。S2 使用独立的原生语义流验证，不冒充原始 10,870 项计划。

## 有限比较套件

默认 `yolov5_sw_p3_suite_12.elf` 只运行 `reference` 两轮，共 12 组、144 帧。`SW_P3_MODE=compare` 按正序和反序各运行一次四个 profile：`reference`、`layout`、`cache_plan`、`cache_plan_gate`。每 profile 都执行相同的十二帧 direct、lane0 单前端、三前端，以及 lane1/lane2 单独串行和按实际并行 job→lane 映射的串行回放。共 48 组、576 帧。

每组计时包含启动、HOST 服务、gate 等待、PPU 和排空；建表、初始化、守卫检查、全 40 字结果比较和日志在计时外。所有组使用单调 run/version ID，先完成 PPU/slot 回收再切组。所有 profile 使用相同初始化策略，缓存政策明确标记为 `warm_order_controlled`，没有未经验证的全局 cache invalidate。

加载用户选定硬件后，可显式调用下面的入口。构建和测试不会下载硬件或固件：

```bash
make program-sw-p3 PROGRAM_ARGS=--check  # 只检查，不连接板卡
make program-sw-p3                      # 操作者显式执行 ELF 下载
python3 sw/benchmarks/frontend/scripts/analyze_parallel_cache.py uart.log \
  --identity build/firmware/sw-p3/generated/identity.json --json comparison.json
```

硬件身份由加载清单声明，不把命令 ABI 当成板上 bitstream 指纹。解析器拒绝缺组、负载不完整、结果不一致、重复版本、错误 lane 配额、时间窗不完整、匹配回放错误和比例错误。输出同硬件绝对三路周期、各 profile 扩展比、效率和 reference/candidate 绝对增益；两轮结果不自动晋升候选。

## 产物与证据

`layout_manifest.json` 包含实际 ELF 地址、容量、padding、bank/set、各窗口和各 lane 分数、额外存储及 ELF SHA；`tiling_manifest.json` 包含每层保留原因及候选的 bytes/line/packet/算量变化。`sw_p3_manifest.json` 绑定编译器、配置、源文件、生成文件、旧/新 ELF 和硬件清单；`audit-sw-p3` 检查已有记录，文件变化必须重新构建。

`verification.json` 分别记录结构/协议、数值和板测。假设备测试覆盖实际调度函数、实际 suite、PPU 生命周期及错误注入，不能证明卷积算术。stage18 的数值测试覆盖三 lane 全部输出、FP16 缩放和非恒等 LUT，并以冻结原生 CPU 卷积核核对独立整数 oracle；它不等于全模型、真实权重的板上精度验证。

回退直接选择 `reference`、关闭 tiling 或 gate，或使用保留的 V33 ELF。无有效真实计算证据的 tile 不启用；S3 仅为独立候选。板上性能状态始终为 `NOT_MEASURED`，直到用户实际运行比较套件后再报告。

## 2026-10-16 板测与默认选择

用户提供的 `tests/log/sw_p3` 通过严格解析：48 组、576 帧，全部 40 字结果一致，六项输入/模型/计划/布局身份与该 ELF 相符。两轮三路周期如下：

| Profile | 正序 | 反序 | 两轮平均相对 reference |
| --- | ---: | ---: | ---: |
| reference | 43,554,857 | 43,604,042 | — |
| layout | 43,549,240 | 43,588,356 | 快 0.024% |
| cache_plan | 43,606,673 | 43,581,696 | 慢 0.034% |
| cache_plan_gate | 43,605,143 | 43,555,282 | 慢 0.002% |

基线两轮波动约 0.113%，未证明候选有稳定性能收益。用户决定保持 reference 默认。原板测日志、UART 身份和解析报告已归档到 `build/reports/sw_p3_board_20261016/`；本次改默认前已有一次重建覆盖了原板测 ELF，保留的 `pre_default_build/` 快照与板测身份不同，不能冒充该次板测 ELF。对应报告为 `build/reports/sw_p3_board_comparison.json`。这些数据来自用户下载的同一份 bitstream，不代表后来修改的硬件已上板验证。

## V34 访存与 HOST 分段诊断

按用户指定项目的 V34 方法移植独立诊断入口，来源与原文件 SHA 记录在 `sw/benchmarks/frontend/IMPORT_V34.json`。构建不依赖该外部路径。保持冻结 V33 模型、切块、18 张计划和原有 12 个 HOST 边界；不插入额外逐层屏障，不启用 S1/S2/S3。原 V33 正式入口不变。

```bash
make test-v34
make audit-v34
make program-v34 PROGRAM_ARGS=--check  # 仅检查文件，不连接板卡
# 开启 115200 8N1 串口日志，确认已加载相符硬件后执行：
make program-v34
```

ELF 为 `build/firmware/frontend-v34/yolov5_frontend_boundary_diag_12.elf`。先完成 direct/单前端/三前端各 12 帧，再完成 13 对单路/三路短窗口，每个短窗口 3 帧。硬件计数器可用时共 114 次完整推理，外加三路客户端映射校准前缀。第一条 `ATSOFT1,PASS` 只表示主测试结束，继续录制直到：

```text
ATSOFT1,DIAG_COMPLETE,version=34,boundary_records=468,short_window_pairs=13,memory_available=1,marker=ALL_DIAGNOSTICS_COMPLETE
```

```bash
python3 sw/benchmarks/frontend/scripts/analyze_log.py tests/log/uart_v34.log \
  --json build/reports/frontend_v34.json --report build/reports/frontend_v34_cycles.txt
```

| 观察范围 | 采集内容 |
| --- | --- |
| 每帧 13 段 | 12 个 HOST 和图尾的 pending、确认、CPU 服务、RESUME 时间；共享 IRQ 提示 |
| 前端状态 | 每 100,000 CPU 周期查询真实 RUN/DRAIN/HOST FSM、FIFO、取表/发令数和稳定游标 |
| 每路 Gemmini | 逐帧 RS active、load/store DMA wait、load/store SPAD wait、exec active 六项事件 |
| 全访存链路 | Gemmini/CPU/FBus/Tensor 客户端；L2 请求、命中、MSHR、secondary 阻塞、refill/writeback；Head 排空；AXI、DDR、MIG、视频链路 |
| 对照窗口 | 同图025、lane0 的 13 个原生 HOST/图尾段，单路对三路；每份快照保留全部块的 32 槽 |

兼容 MPV3 ABI 1.0 的 13 块、ABI 1.1 的 14/16 块和当前 ABI 1.2 的 16 块。ABI 1.2 解码全部四个 L2 bank（5、6、14、15），Tensor 块13，以及客户端的四 bank 请求分布。100/300 MHz 域分别解释周期。未知 ABI 或探测到 MMIO 访问异常时明确输出计数器不可用，主诊断仍完成，不把缺数据解释为零停顿。

Gemmini 计数器只在前端持有之前和 DONE/ACK 释放之后访问；HOST_WAIT 仍持有所有权，禁止此时发送直接计数器指令。MPV3 选择器和全部数据读取在计时之外，分段启停与采样成本另行记录。

这里是 **13 个原生段的观测时间**，不是 166 层的独立硬件完成时间；Gemmini 六项事件是逐帧累计。先用匹配短窗口定位明显延长的段及其等待来源，再决定是否需要对该段增加逐层诊断。真实 HOST 等待只给出观测上下界；各 lane 重叠的等待不能直接相加当作整组可节省周期。正式性能继续使用无诊断的 reference。
