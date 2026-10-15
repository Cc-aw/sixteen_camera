# sixteen_camera 单版本收敛与目录重构实施方案

> **文档版本**：1.0  
> **编写日期**：2026-10-15  
> **分析基线**：`main@def049ad2851bb38d511b276a3604b92c3f0acb3`（2026-10-14 的仓库状态）  
> **目标硬件**：`triple32_v3_tensor`（1 Rocket + 1 RVV + 3 × Gemmini32）  
> **目标软件**：YOLOv5nu **v26**（3 worker，正式版 credit=4）  
> **文档性质**：实施规范；**未对仓库执行重构、构建、综合或板测**。

## 0. 最终决策与范围

将 `sixteen_camera` 从带有历史兼容入口的研发仓库，收敛为**唯一硬件配置 + 唯一当前模型核心 + 两种运行入口**的工程。重构的重点是整理目录职责、生成依赖、构建命令、文档和无用历史代码，而不是重新设计已经完成 R0–R5 分层的 Runtime。

**主分支最终只交付：**

- **一套硬件**：当前 `triple32_v3_tensor`，三颗 DIM32 Gemmini，当前 MaxPool、MemoryParallelV3、TensorIngress、Head/PPU、视频与显示链路及现有 VU13P 时序策略。
- **一套模型执行核心**：当前 YOLOv5nu v26 三 worker，包含固定 tiling/packet、准备好的 WS/LUT、credit-cap4、wait reuse、硬件 Pool/Resize 和相应 ABI。
- **两个应用入口**：实时视频推理固件、image025/036/142 三图数值与性能基准。两者必须复用模型源码、包生成逻辑、参数以及 ABI，不维护两套独立核心。
- **一套受控验证集合**：覆盖当前硬件、视频、模型、Runtime、设备协议、异常/回收与性能基线。

**注意：**“三路推理”指三个计算 worker，**不等于把原十六路视频输入缩成三路**。当前十六路视频采集、Tensor 生产、DDR 通道和显示叠加属于交付系统的正常组成部分，不得因裁剪旧计算版本而删除。

### 0.1 本次明确不做

1. 不修改三颗 Gemmini 的计算架构、频率、RoCC opcode、DMA、L2、AXI、TensorIngress 或 PPU 协议。
2. 不调整 `credit=4`、`SAFE_MAX=4`、提交量、CPU quantum、FP/VCSR context、fixed plans/packets、wait reuse、Pool/Resize 算法或调度策略。
3. 不引入 v27/v28 software batch、额外模型、额外硬件配置或新的并行优化实验。
4. 不重写 Runtime Core、Scheduler、Resources、Services、Backend；其现有职责边界应继承。
5. 不通过删除测试、关闭编译告警、弱化协议检查来获得“更简洁”的效果。
6. 不将旧源码堆进 `archive/`、`backup/`、`legacy/` 形成新的杂物目录；使用 Git tag/branch 保存历史。
7. 不声称仅通过目录调整提高三 Gemmini 并行度；性能优化应当独立立项。

---

## 1. 当前工程现状与真正的问题

### 1.1 当前已有的收敛工作

截至基线提交：

- 根目录为 `hw/`、`sw/`、`tools/`、`tests/`、`docs/`；一级结构本身合理。
- `hw/soc/` 已只保存当前 `TaihangSoC1Rocket1RVV3Gemmini32x32MemoryParallelV3TensorIngressConfig` 的生成导出。
- 根 `Makefile` 默认 `SOC_VARIANT=triple32_v3_tensor`；`sw/Makefile` 拒绝其他 `SOC_VARIANT`。
- `sw/models/yolov5nu/triple32/v26.mk` 共用于实时视频与独立三图基准。
- `sw/src/ai/runtime/` 已完成应用、设备、资源、调度和服务的离线分层改造。

因此，本次不是从零开始的全仓库重构，而是**完成最后一轮版本剥离、归档边界和目录整理**。

### 1.2 当前主要问题

| 编号 | 现象 | 后果 | 优先级 |
|---|---|---|---|
| A1 | `tools/soc/` 内含真正参与 SoC 生成的 Scala/硬件 shell、MemoryParallelV3 覆盖与冻结参考依赖 | 工具代码与硬件源码混在一起，不便定位 SoC 修改点 | P0 |
| A2 | `hw/soc/` 导出目录为完整包名/Config 长目录 | 不便浏览，路径在 Tcl、Python 和 C 构建规则中反复出现 | P1 |
| A3 | `sw/models/yolov5nu/triple32/` 同时放执行核心、生成器、基准、日志分析及测试 | 查找实时三 worker 代码成本高，容易误改或误删 | P0 |
| A4 | v26 仍使用 `v17a` backend family、`dim16_dual` 冻结原始文件名和旧包含路径 | “旧名字”与“实际旧实现”难区分 | P0 |
| A5 | `sw/third_party/gemmini/` 与 `gemmini_v3/` 的引用关系尚未收敛为单一、明确的当前 ABI | 不清楚哪些公共头仍参与正式编译 | P1 |
| A6 | `README.md`、`sw/README.md`、模型和第三方依赖说明仍包含不同阶段叙述 | 阅读者不能直接判断当前交付版本 | P1 |
| A7 | 构建/测试入口包含 `test-v17a`、`test-runtime-r3` 等历史阶段名称，固件对象名也有 `hdmi_tx_test` | “要运行什么”不够直观 | P2 |
| A8 | 阶段验收记录与当前产品文档混排 | 历史性能结论容易被误认为当前硬件的板测结论 | P1 |

### 1.3 当前重要接口与引用位置

- [仓库 README](https://github.com/Cc-aw/sixteen_camera/blob/def049ad2851bb38d511b276a3604b92c3f0acb3/README.md)
- [根 Makefile](https://github.com/Cc-aw/sixteen_camera/blob/def049ad2851bb38d511b276a3604b92c3f0acb3/Makefile)
- [软件 Makefile](https://github.com/Cc-aw/sixteen_camera/blob/def049ad2851bb38d511b276a3604b92c3f0acb3/sw/Makefile)
- [当前硬件集成说明](https://github.com/Cc-aw/sixteen_camera/blob/def049ad2851bb38d511b276a3604b92c3f0acb3/docs/integration/triple32-v3-tensor.md)
- [v26 软件移植说明](https://github.com/Cc-aw/sixteen_camera/blob/def049ad2851bb38d511b276a3604b92c3f0acb3/docs/integration/triple32-v26-software.md)
- [当前 v26 公共构建规则](https://github.com/Cc-aw/sixteen_camera/blob/def049ad2851bb38d511b276a3604b92c3f0acb3/sw/models/yolov5nu/triple32/v26.mk)
- [Runtime 软件说明](https://github.com/Cc-aw/sixteen_camera/blob/def049ad2851bb38d511b276a3604b92c3f0acb3/sw/README.md)

上述链接固定于本方案的分析基线。如果实施时 `main` 已有新的提交，应以新的 HEAD 重新生成迁移清单，**不得直接覆盖新增文件**。

---

## 2. 目标目录：一级不变，二三级按职责收敛

以下为**建议的最终结构**，不是当前结构原样复制。目标是：只看路径就能判断一个文件归谁维护、在何处参与生成以及由哪个测试覆盖。

```text
sixteen_camera/
├── README.md                           # 唯一产品与快速开始
├── AGENTS.md                           # 面向维护者/代码代理的固定约束
├── Makefile                            # 当前产品的统一入口
├── .gitignore
├── .gitattributes
│
├── hw/                                 # 硬件源代码与实现输入
│   ├── README.md
│   ├── rtl/                            # 手写板级 RTL（保留现有层次）
│   │   ├── top_wrapper.sv
│   │   ├── ai/                         # Tensor、PPU/后处理、AI 周边
│   │   ├── bus/                        # 总线适配、桥接
│   │   ├── common/                     # FIFO、CDC 等共享单元
│   │   ├── control/                    # SoC 集成和 MMIO/控制
│   │   ├── interfaces/                 # 公共接口
│   │   ├── memory/                     # 板级 DDR、AXI 数据路径
│   │   ├── si5338/                     # 时钟配置相关硬件
│   │   └── video/                      # 采集、帧缓存、输出、叠加
│   ├── soc/
│   │   ├── README.md
│   │   ├── source/
│   │   │   └── shell/                  # 原 tools/soc/shell 中当前生成源码及依赖
│   │   └── generated/
│   │       ├── gen-collateral/         # 唯一三 Gemmini32 导出
│   │       ├── include/                # 若生成流程实际将头放在此层，按清单确定
│   │       └── ...                     # 保留必要生成上下文与来源锁
│   ├── constraints/                    # 当前板级、CDC、实现约束
│   ├── ip/                             # 当前 Xilinx IP 重建 Tcl
│   ├── vivado/                         # 工程、BD 重建 Tcl
│   └── manifests/                      # 当前 RTL/IP/XDC/SoC 清单与配对契约
│
├── sw/                                 # 裸机软件与模型
│   ├── README.md
│   ├── Makefile
│   ├── linker_ai_video.ld
│   ├── src/
│   │   ├── main.c
│   │   ├── app/                         # 应用入口、事件循环、串口命令
│   │   ├── board/                       # 板级初始化和 xparameters
│   │   ├── platform/                    # 启动、时钟、cache、barrier、console
│   │   ├── video/                       # 摄像头和视频服务
│   │   ├── drivers/
│   │   │   ├── tensor/                 # Tensor HAL
│   │   │   ├── ppu/                    # PPU HAL
│   │   │   └── overlay/                # Overlay HAL
│   │   ├── ai/
│   │   │   ├── runtime/
│   │   │   │   ├── core/               # 生命周期、主推进与统计
│   │   │   │   ├── resources/          # job/tensor/Head/arena 所有权
│   │   │   │   ├── scheduler/          # EDF/worker 派发
│   │   │   │   └── services/           # Tensor/result/postprocess/overlay
│   │   │   ├── backend/                # Runtime ↔ 当前模型适配
│   │   │   └── postprocess/            # 检测、PPU 发布、显示映射
│   │   └── diagnostics/                # 带宽、Tensor/PPU/Runtime 诊断
│   ├── models/
│   │   └── yolov5nu/
│   │       ├── README.md
│   │       ├── model.mk                 # 单一 v26 模型规则
│   │       ├── src/                     # 当前三 worker 核心
│   │       ├── include/                 # 当前接口与 RVV/Head 头
│   │       ├── codegen/                 # tiling、packet、prepared 等生成器
│   │       ├── frozen/                  # 不应随意修改的生成器原始输入
│   │       │   └── native/
│   │       ├── assets/                  # 当前必需 AOT、权重、参数
│   │       └── sources.lock.json
│   ├── benchmarks/
│   │   └── triple_infer/              # image025/036/142 基准与自测外壳
│   └── third_party/
│       ├── README.md
│       ├── board/                       # 板级 AXI IIC/时钟依赖
│       ├── amd/                         # 当前 BSP 使用的冻结驱动
│       └── gemmini/                     # *最终*当前 ABI；合并前暂留旧目录
│
├── tools/
│   ├── README.md
│   ├── build/                         # bitstream、firmware 构建入口
│   ├── soc/                           # SoC 生成脚本；不再容纳主要硬件源码
│   ├── program/                       # bitstream、ELF 下载
│   ├── check/                         # 完整性/ABI/ELF/生成等检查
│   ├── generate/                      # 跨组件通用 LUT、辅助生成
│   ├── analyze/                       # UART、性能、对比分析
│   ├── timing/                        # WNS/TNS、时序报告分析
│   └── config/                        # tools.example.mk、未提交本地覆盖
│
├── tests/
│   ├── README.md
│   ├── requirements.txt
│   ├── host/                          # 当前 Runtime、驱动和业务行为
│   ├── rtl/                           # Tensor、视频、缓存、PPU RTL
│   ├── model/yolov5nu/                # 当前模型/生成器原生回归
│   └── data/                          # 当前 golden、LUT、输入 corpus
│
├── docs/
│   ├── README.md
│   ├── quickstart.md
│   ├── architecture/
│   │   ├── hardware.md
│   │   └── software.md
│   ├── interfaces/
│   │   ├── memory-map.md
│   │   ├── gemmini-abi.md
│   │   └── tensor-ppu.md
│   └── validation/
│       └── current.md
│
└── build/                             # 本地工程、ELF、仿真、报告；Git 忽略
```

**关于 `hw/soc/generated/`：**上述示意只表示缩短生成导出外层目录。实际 `gen-collateral/include/`、RTL、JSON 的相对布局必须根据本仓库真实生成结果确认，不能通过“看起来整齐”就变更生成器内部文件树；首轮允许暂时保留原超长目录，通过清单/软别名解决查找问题。

---

## 3. `hw/` 各文件夹逐项分析

| 当前目录 | 当前职责与结论 | 实施建议 | 保留级别 |
|---|---|---|---|
| `hw/rtl/` | 板级顶层、视频、AI、总线、DDR 等手写 RTL，已按功能分目录 | 保留层次，补模块入口索引；仅修正确有错误的归属 | **必须** |
| `hw/rtl/top_wrapper.sv` | 工程顶层集成入口 | 不改模块名/层次，仅维护引用 | **必须** |
| `hw/rtl/control/` | SoC 接入、寄存控制与集成；包含 `control_soc_subsystem.sv` | 保留 | **必须** |
| `hw/rtl/memory/`、`bus/` | FPGA 板级存储与视频/AI 数据流通路 | 保留，并区分板级 AXI 与 SoC 内部 L2 | **必须** |
| `hw/rtl/video/` | 十六路视频输入、Tensor 生产、显示等链路 | 完整保留 | **必须** |
| `hw/rtl/ai/` | TensorIngress 接入周边、PPU/Head/Overlay 等 AI 外设 | 保留；源 SoC 内部逻辑与板级外设分开说明 | **必须** |
| `hw/rtl/common/`、`interfaces/` | 共享 FIFO/CDC/接口等基础模块 | 保留，避免过度抽象 | **必须** |
| `hw/rtl/si5338/` | 当前时钟相关模块 | 若生产清单仍使用则保留 | 依赖验证 |
| `hw/constraints/` | 现用板级约束和时序策略 | 原样保留；尤其不要大面积修改层级筛选 | **必须** |
| `hw/ip/` | Vivado 2023.2 使用的 IP 重建 Tcl | 保留；IP 输出产物留在 `build/` | **必须** |
| `hw/vivado/` | Vivado/DDR BD 工程重建 Tcl | 保留，只修正改目录后的输入路径 | **必须** |
| `hw/manifests/` | `ip_manifest.tcl`、`rtl_manifest.tcl`、`soc_manifest.tcl`、`xdc_manifest.tcl` | 保留，增加当前唯一配对身份检查 | **必须** |
| `hw/soc/<超长 Config 名>/` | 当前唯一 Gemmini32 ×3 的生成结果 | 机械迁移为短别名；完整 Config 仍保存在元数据 | **必须** |
| `hw/configs/taihang_soc/LinuxConfigs.scala` | 当前仓库仍留有 single4 Linux 配置源文件 | 确认无生产生成依赖后删除，若目录空则整体删除 | **应清理** |
| `tools/soc/shell/` | 当前 SoC 的 Scala/Chisel shell、MemoryParallelV3 覆盖、冻结生成依赖 | **源内容移入 `hw/soc/source/`**；生成脚本仍放 tools | **必须迁移** |

### 硬件迁移边界

- 完整 Scala 类名 `TaihangSoC1Rocket1RVV3Gemmini32x32MemoryParallelV3TensorIngressConfig` **不改**。
- 三个 Gemmini 的 generated RTL、参数头与 `SAFE_MAX=4` 契约必须保留。
- 保留当前 MemoryParallelV3 双 bank L2、512-bit 记忆出口、TensorIngress 端口、三路 MaxPool、Head/PPU 通道。
- 源码迁移后重新生成必须使用正常 Chisel/SBT/firtool 流程；禁止仅通过替换输出 Verilog 文字修复源码映射。
- Vivado timing Tcl、placement/pblock、约束及自动脚本应保持既有策略；路径调整不应默默丢失 XDC 或 Tcl hook。

---

## 4. `sw/` 各文件夹逐项分析

### 4.1 现有软件分层继续使用

| 目录 | 唯一职责 | 重构动作 |
|---|---|---|
| `sw/src/app/` | 启动、UART 命令、模式管理、事件循环 | 保留；避免新增模型执行细节 |
| `sw/src/board/` | FPGA 板级初始化、GPIO、BSP 参数 | 保留 `xparameters.h` 与现用源码 |
| `sw/src/platform/` | CPU 启动、cache flush、屏障、cycle、console | 保留；外设地址与缓存 alias 不允许隐式改变 |
| `sw/src/video/` | 视频驱动和流服务 | 保留，十六路视频功能不裁剪 |
| `sw/src/drivers/tensor/` | Tensor 描述符、release ack、生产者 MMIO | 保留；只做设备级协议 |
| `sw/src/drivers/ppu/` | PPU 设备发布/读取协议 | 保留有效当前驱动，退休适配壳需检查调用 |
| `sw/src/drivers/overlay/` | overlay MMIO、box/label、commit | 保留 |
| `sw/src/ai/runtime/core/` | Runtime 主状态、推进、管线协调、统计 | 不重写 |
| `sw/src/ai/runtime/resources/` | job/tensor/head/arena 租约与资源回收 | 不重写；故障持有策略不能弱化 |
| `sw/src/ai/runtime/scheduler/` | 帧选择、worker 派发与 credit 之外的系统级调度 | 不改变调度策略 |
| `sw/src/ai/runtime/services/` | Tensor、结果、PPU/overlay 服务 | 不把 MMIO 重新塞进核心层 |
| `sw/src/ai/backend/` | 通用模型事件与当前 YOLOv5nu 后端的接合 | 只保留当前路径与必要 ABI 适配 |
| `sw/src/ai/postprocess/` | Head/PPU 结果发布、检测框、显示映射 | 保留当前等价链路 |
| `sw/src/diagnostics/` | 带宽、Tensor、Runtime、PPU/结果诊断 | 保留当前有用功能；历史诊断模式归档 |

### 4.2 模型目录是主要整理对象

当前 `sw/models/yolov5nu/` 下并存 `aot/`、`include/`、`runtime/`、`triple32/`；其中 `triple32` 是当前模型的执行核心，但也塞入大量构建、生成、日志与基准材料。

**建议迁移表**（所有目标路径均以 `sw/` 起算）：

| 源路径/文件 | 目标路径/目录 | 迁移原则 |
|---|---|---|
| `models/yolov5nu/triple32/model.c` | `models/yolov5nu/src/model.c` | 原实现优先机械迁移 |
| `triple32/independent.c/.h` | `models/yolov5nu/src/` | 三 worker 协作核心，不删 |
| `triple32/task_switch.S`、`task_context_config.h` | `models/yolov5nu/src/` | 保留 ABI/上下文布局 |
| `triple32/v26.mk` | `models/yolov5nu/model.mk` | 统一视频与基准 include 入口，保持原参数 |
| `triple32/generate_parallel.py` | `models/yolov5nu/codegen/` | 与 `fixed_plans.py`、`fixed_packets.py` 等整体迁移 |
| `triple32/fixed_plans.py`、`fixed_packets.py`、`prepared_packets.py` | `models/yolov5nu/codegen/` | 不拆断相互导入；统一重定位资源文件 |
| `triple32/memory_kernels.py`、其他**当前参与生成的** Python/`.inc` | `codegen/` 或 `src/` | 依生成期/编译期用途细分，先核实引用 |
| `triple32/native/` | `models/yolov5nu/frozen/native/` | 不因 `dim16_dual` 旧文件名删掉冻结输入 |
| `models/yolov5nu/aot/` | `models/yolov5nu/assets/` | 仅当前所需权重、AOT/参数数据；维护来源哈希 |
| `models/yolov5nu/include/` | 保持 `include/` | 当前 RVV 辅助、模型布局头等 |
| `models/yolov5nu/runtime/` | 核实后拆为 `codegen/`、`include/`、必要源 | **不可先整体删除**，后端仍包含其中模型接口 |
| `triple32/main.c`、`compare.c`、输入生成与 PPU 基准外壳 | `benchmarks/triple_infer/` | 基准可单独构建，但必须复用模型目标文件 |
| `triple32/analyze_log.py`、能力/内存日志解析等 | `tools/analyze/` | 仅主机诊断使用时迁移；先确认具体模块导入 |
| `triple32/tests/` | `tests/model/yolov5nu/` | 保留当前原生数值与 packet 回归 |
| `import_v26_manifest.json`、来源 SHA 记录 | 明确放于模型元数据区或 `docs/validation/` | 当前来源锁必须继续可校验 |

**禁止误删：**

- 当前 `v26.mk` 使用 `triple32/native/yolov5nu_dim16_dual.c` 作为生成器输入。旧文件名不能证明它是旧产品代码。
- 当前 `ai_model_backend_yolov5nu.c` 包含 `yolov5nu_dim16_dual.h`，并使用其检测结果结构；先替换全部调用点，后退出旧接口路径。
- `V17A` 目前也是**当前 v26 使用的内部 ABI family 名称**。旧 `test-v17a` 别名可以裁剪，但被正式编译的 `rt_backend_v17a.c` 不能按文件名直接删除。
- `sw/third_party/gemmini/` 与 `gemmini_v3/` 两个 include 源当前同时出现在构建配置中。先解析 `.d` 编译依赖，确认实际来源，再收敛为一个当前 ABI。

### 4.3 实时推理与基准的正确分层

```text
sw/src/app/  ──────────────► sw/src/ai/runtime/ ───► sw/src/ai/backend/
  (实时视频)                    (帧/任务/资源)             │
                                                           ▼
sw/benchmarks/triple_infer/ ─────────────────────► sw/models/yolov5nu/src/
  (三图/自测/计时)                                      │
                                                         ▼
                                            当前 Gemmini32 ABI + 三套 RoCC
```

基准入口保留 `M`（硬件 Pool/Resize）、`t`（数值对比）、`a`（性能）的现有用途；不要在实时视频主循环里插入固定输入自测。

### 4.4 模型代码应满足的边界

- `model.c`：当前模型执行与层级协作，**不负责**串口和视频模式。
- `independent.c`：三 worker 提交、等待、退休跟踪、credit/执行协作；**不负责**摄像头帧队列。
- `codegen/`：离线生成 fixed plans、fixed/prepared packets、memory kernels；所有输入有来源锁。
- `backend/`：接收 Runtime job、启动指定 worker、向 Head/PPU 回传完成事件；**不复制**模型层计算实现。
- `benchmarks/triple_infer/`：固定三图输入、对比、测时和串口入口；不维护专有 tiling/内核副本。

---

## 5. `tools/`、`tests/`、`docs/` 的整理方案

### 5.1 `tools/`

| 目标目录 | 应包含 | 不应包含 |
|---|---|---|
| `build/` | 当前固件/bitstream 构建包装、实现策略 Tcl | 模型权重、SoC Scala 主源码 |
| `soc/` | Chipyard 工作区准备、覆盖安装、生成与导出入口 | 大量参与硬件生成的 Scala shell 源码 |
| `program/` | 下载脚本、设备选择、ELF 检查 | 各版本独立下载脚本副本 |
| `check/` | Manifest、生成闭包、工具版本、ELF/ABI/工程一致性 | 正常业务算法 |
| `generate/` | 跨多个子系统共享的 LUT 或数据生成工具 | YOLOv5nu 专属 fixed-plan 生成器 |
| `analyze/` | 三图 UART、credit、内存/Pool/PPU 数据解析 | 嵌入式运行源码 |
| `timing/` | WNS/TNS、route、bus-skew 等报告解析 | RTL 源码 |
| `config/` | `tools.example.mk` 和未提交的 `tools.local.mk` | 硬编码个人绝对路径 |

目标：工具目录只放**构建、部署、检查、分析工具**，不承担“隐藏的硬件源码仓库”。

### 5.2 `tests/`

- `host/`：Runtime ABI、设备 HAL、ownership、scheduler、fault、Facade、backend 及应用行为。
- `rtl/`：视频整帧、FIFO、MIG、Tensor DMA/Ingress、MemoryParallelV3、L2/PPU 及关键时序相关仿真。
- `model/yolov5nu/`：v26 fixed plans/packets、Split-K、FP16、credit、wait reuse、Pool/Resize、三 worker 场景。
- `data/`：当前 image025/036/142、golden、LUT、NMS/整数 corpus 等必要测试数据。

**不能删除仅一颗或两颗 worker 活跃的用例**：三颗硬件仍需测试稀疏负载、worker 复用、无任务返回主循环、长时间空闲和 drain。

可重新命名 `test-runtime-r3/r4a/r4b/r5`，但相关事件轨迹、协议和应用测试应继续受统一入口覆盖。不要把迁移后“测试数量减少”作为成功标准。

### 5.3 `docs/`

文档导航仅向新维护者暴露**当前系统**：

| 文档 | 必须回答的问题 |
|---|---|
| `README.md`（根） | 项目当前是什么，唯一硬件/软件组合是什么，如何快速开始 |
| `docs/quickstart.md` | 工具依赖、SoC 生成、Vivado、固件、基准、下载、测试的顺序 |
| `docs/architecture/hardware.md` | 十六路视频、TensorIngress、3×32 Gemmini、L2/DDR、Head/PPU/显示如何连接 |
| `docs/architecture/software.md` | app → runtime → backend → model 与资源生命周期 |
| `docs/interfaces/memory-map.md` | 设备地址、DDR 区间、cache alias 与可见性契约 |
| `docs/interfaces/gemmini-abi.md` | 三 worker、opcode、credit/retired、context、Pool/Resize、配置与模型配对 |
| `docs/interfaces/tensor-ppu.md` | Tensor 描述符、release、Head 发布、PPU receipt、overlay 提交协议 |
| `docs/validation/current.md` | 哪些离线通过，哪些只完成局部综合，哪些已整机实现/上板，当前性能证据归属 |

原 `sw-runtime-r1a/r1b/r1c/r2/r3/r4a/r4b/r5`、旧配置集成说明、阶段性时序报告不应占用主导航。先提取当前有效的设计结论、状态和已知缺口；历史全文使用 Git tag/提交查阅。研究性诊断证据如果仍为当前验收必需，则保留并从 `current.md` 精确链接，不应笼统全删。

---

## 6. 配置和构建入口

### 6.1 唯一的交付身份

建议在 `hw/manifests/` 建立机器可读的**当前交付清单**（具体名称可为 `current.json`），内容至少包括：

- `hardware_alias = triple32_v3_tensor`
- 完整的 Scala Config 类名及生成目录映射
- `worker_count = 3`、`gemmini_dim = 32`、`clock_hz = 100000000`
- `model = yolov5nu`、`runtime_profile = v26`、`credit_limit = 4`
- 真实的 SoC 参数头位置、模型源/生成输入位置、来源锁和生成上下文记录
- 软硬件 ABI/模型配置校验项目

**清单用于选择与校验，不代替真实生成参数**。如 `SAFE_MAX`、RoCC 路径、内存参数头与清单不一致，应使生产构建失败，而不是静默调整常量。

### 6.2 对外 Make 命令收敛

| 目标命令 | 用途 | 当前是否直接存在 |
|---|---|---|
| `make help` | 日常构建入口 | 是 |
| `make check` | 当前闭包/Manifest 检查 | 是 |
| `make soc` | 当前 SoC 源码生成 | **待添加别名**；当前为 `soc-triple32-v3-tensor` |
| `make project` | Tcl 创建 Vivado 工程 | 是 |
| `make bitstream` | 当前 bitstream | 是 |
| `make firmware` | 实时视频 v26 ELF | 是 |
| `make benchmark` | 三图 v26 ELF | **待添加别名**；当前为 `firmware-benchmark` |
| `make test-software` | 全部 host + 模型回归 | **需扩展覆盖定义** |
| `make test-rtl` | RTL 总入口 | **待添加**；当前存在多项独立命令 |
| `make program` | 载入匹配 ELF | 是 |

保留 `make test-tensor`、`make test-ppu`、`make test-video-pipeline` 等精细入口，供定向回归使用，但将默认 `help` 缩为常用指令；历史 R1/R2/R3 等可迁移到 `make help-tests` 和测试文档。移除旧产品用的 `SOC_VARIANT` 选项，不是消灭未来开发分支：开发新硬件仍可新开分支，但主分支只有一个正式身份。

### 6.3 生成结果与本地产物

推荐：

```text
build/
├── firmware/
│   ├── video/video.elf
│   └── benchmark/benchmark.elf
├── projects/triple32_v3_tensor/
├── bitstream/triple32_v3_tensor/<run-id>/
├── reports/
├── sim/
└── history/              # 仅本机留存，Git 忽略；不是源码 archive
```

`hdmi_tx_test.*` 和 `yolo32.*` 是当前构建产物命名，不必继续暴露为产品名字；但路径改动前先同步下载脚本、ELF 检查和 test fixture。生成/初始化文件（例如真实构建依赖的 `.mem`、`.hex`、`.coe`）应按**用途**判断，不能通过全局扩展名忽略误删。

---

## 7. 保留、删除与延期处理清单

### 7.1 必须保留

1. 当前 `triple32_v3_tensor` 完整生成闭包：Shell/Scala/Chisel 依赖、输出 RTL、参数头、生成记录和使用中的约束。
2. 三颗 Gemmini32 的 RoCC、credit、accepted/retired、can_submit、DMA/Memory Parallel V3 与 MaxPool/Resize 契约。
3. 当前 YOLOv5nu v26 正式执行源码、模型冻结输入、权重和计划/packet 生成器。
4. 实时视频 Runtime R5 分层、设备 HAL、资源所有权、错误路径、Head/PPU/overlay 与缓存发布逻辑。
5. 三图基准和当前有效的独立/稀疏 worker、延迟 DMA、资源占有与恢复测试。
6. 当前第三方实际编译到的软件依赖、许可与来源记录。

### 7.2 确认依赖后应删除

- `hw/configs/taihang_soc/LinuxConfigs.scala` 等只服务于退休 single4 Linux 配置的入口。
- 旧 single4/dual16 硬件专用构建入口、单独生产配置和已退休的硬件导出。
- 不再使用的历史 `v17a` **构建入口**及其对外文档（但不是当前仍在编译的 V17A-family 适配器）。
- 当前 v26 的正式依赖闭包以外，且未被当前回归引用的实验版模型源码、重复导出和日志工具副本。
- 已被统一版本替代的历史 Make 别名和空目录。

### 7.3 先延期、后裁剪

| 候选项 | 为什么不能立即删除 | 何时可以删除 |
|---|---|---|
| `rt_backend_v17a.c` | v26 当前实时后端仍选择该 ABI profile | 当前适配被新命名实现替换并通过 host + RV64 等价验证 |
| `yolov5nu_dim16_dual.*` | 当前生成器输入与后端类型可能仍引用 | 全部引用收敛且生成/结果比对通过 |
| `sw/third_party/gemmini/`、`gemmini_v3/` | include 闭包同时涉及两者 | 对预处理 include、`.d` 和各 ELF 实际源证明完成 |
| R0–R5 测试输入与冻结轨迹 | 当前运行时行为等价的证据 | 已迁移到新测试入口，当前路径可复核 |
| 旧来源与导入 manifest | 保存当前版本来源和适配哈希 | 新锁文件完成等价追溯且已记录旧 hash |

### 7.4 删除的强制证据

每一个拟删除的源码文件都应满足：

- `git grep` / `rg` 无当前**直接调用**；
- Make/Tcl/Python/Scala 构建路径与动态加载无当前**间接引用**；
- 编译生成的 `.d` 和文件清单里不存在不可替代依赖；
- 其用途如已被替换，存在明确的新文件与等价测试；
- 已将删除前的版本通过 Git tag/branch 留存。

以上任一条不满足，先标记为 **BLOCKED**，不要仅凭文件名中的 `single`、`dual`、`v17a`、`dim16` 等字符串删除。

---

## 8. 分阶段实施与逐阶段验收

### P0 — 冻结真实基线（先做，不删除文件）

**任务：**

- 检查当前 `git status` 与 HEAD；工作区未提交更改不可被覆盖。
- 创建基线 tag（例如 `before-single-version-refactor-20261015`），记录提交 SHA。
- 保存 `git ls-files`、生产清单、固件实际编译/链接命令、关键 `.d`、生成输入 SHA、SoC RTL 参数头哈希与来源锁。
- 记录硬件导出数、`SOC_VARIANT` 支持值、`MODEL_WORKERS=3`、`MODEL_DIM=32`、v26 参数和实际当前 Make 目标。
- 先运行当前已有离线回归；**如已有失败，注明基线失败，不能声称重构造成或修复了它**。

建议开始时执行：

```bash
git status --short
git rev-parse HEAD
git ls-files > /tmp/sixteen-camera-before-files.txt
# 确认工作区干净、准备好可回退提交后再执行：
git tag -a before-single-version-refactor-20261015 -m "before single-version cleanup"

make check
make test-v26
make test-software
make test-video
make test-tensor
make test-ppu
```

**退出条件：**基线文件清单、构建闭包、功能测试与已知失败列表可追溯。

### P1 — 单产品身份与入口收敛

**任务：**

- 明确唯一 `triple32_v3_tensor` 与 v26 配对契约。
- 机器可读清单检查生成参数与软件配置一致。
- 生产构建不接受旧 single4/dual16 的选项。
- 根 Makefile 简化 `help`，先加新 alias，暂保留对应的旧执行命令以便验证。

**退出条件：**单版本生产构建无歧义；旧配置不能静默生成不匹配固件。

### P2 — 仅机械迁移硬件目录

**任务：**

- 将 `tools/soc/shell` 中的当前 SoC 源码与冻结依赖迁移至 `hw/soc/source/`。
- 更新 SoC 生成 Python、SBT 过滤/安装规则、Tcl 清单、Vivado 路径、README 和来源记录。
- 若采用 `hw/soc/generated/` 短路径，先证明生成器、固件头文件、Vivado 工程全部从新路径读取；完整 Config 类名不变。
- 对 Scala/Rtl 内容做 hash/diff 核对。仅路径变动时不应该引入行为逻辑差异。

**退出条件：**干净工作区可以成功生成当前 SoC，生成结果与冻结基线具有可解释的逐文件对应关系，现有 RTL 测试通过。

### P3 — 仅机械迁移模型与基准

**任务：**

- 将 `triple32/` 分为 `src/`、`codegen/`、`frozen/`、基准与工具分析区。
- `v26.mk` 转为单一 `model.mk` 引入路径；严禁修改其原有语义参数。
- 保留当前模型原始接口名，先完成 Make/Python/include 路径修改；命名清理放后一个提交。
- 视频与基准继续指向同一模型目标/生成结果。
- 确认 `sw/Makefile` 对 `YOLO32_PPU_ORDERED_MMIO`、`light context` 和 config stamp 的构建行为不变。

**退出条件：**`make firmware`、`make firmware-benchmark`、`make test-v26` 和 host 测试均满足基线，三图模型源码没有生成第二套副本。

### P4 — 精确清除历史代码与无用兼容层

**任务：**

- 根据真实依赖图删除已退休的 single4/dual16 配置、旧构建、无引用实现。
- 逐步将 V17A family 的对外旧命名隔离；如需改 API 名，单独提交并进行 Host/RV64 等价回归。
- 核实 Gemmini 公共 include 的实际来源，在来源许可和完整构建依赖保留的前提下再合并 `third_party`。
- 移除空目录和不再维护的历史构建别名；不创建新的历史源码仓库。

**退出条件：**无当前生产依赖断裂、无新增协议差异、源文件减少的依据可以逐项审计。

### P5 — 整理测试和文档导航

**任务：**

- 将模型原生测试纳入 `tests/model/yolov5nu`；新增 `test-rtl` 等便利聚合入口。
- 将 `README`、`docs/architecture`、`docs/interfaces` 收敛为当前视角。
- 保留所需验证材料；仅从主导航移除历史流水账。
- 删除路径迁移后的无效链接、旧生成命令和硬编码私有开发路径。

**退出条件：**新开发者无需知道 single4/dual16/V17A 的演进历史，即可准确找到当前 RTL、Gemmini 调度、模型代码、固件/基准构建和验证入口。

### P6 — 干净构建、整机实现与上板验证（独立验收）

**任务：**

- 在新 checkout 且没有旧生成产物的环境中，执行 `check`、SoC 生成、模型生成、固件、基准及全部回归。
- 对当前 `triple32_v3_tensor` 完成 Vivado RTL elaborate、综合、实现与 bitstream；记录最终 setup/hold、route、WNS/TNS、bus skew。
- 下载匹配 v26 固件；测试视频采集、持续推理、PPU/overlay、排空和重启。
- 对三图基准执行 `M/t/a`；要求数值 PASS、零 mismatch；性能与对应旧开发工程数据区分归属。

**退出条件：**`docs/validation/current.md` 对每项结果给出当前硬件+固件身份、日期、测试命令与证据路径；未执行的板测必须标注 **PENDING**。

---

## 9. 现有版本验收命令（迁移前后均应适用）

> 以下为基线 `Makefile` **已经提供**的命令；不是假设重构后才存在的新目标。运行依赖具体工具链和本机 Vivado/RISC-V 环境，缺失依赖应明确报告。

### 9.1 软件与模型

```bash
make check
make firmware SOC_VARIANT=triple32_v3_tensor
make firmware-benchmark
make test-v26
make test-software
make check-v26-firmware
```

### 9.2 RTL/视频/缓存

```bash
make test-video
make test-video-pipeline
make test-tensor
make test-tensor-ingress
make test-memory-v3
make test-ppu
make test-cache
```

### 9.3 Vivado 工程与 SoC 生成

```bash
make check-deps
make project
make elaborate

# 当前生成入口；需要预先准备对应参考 Chipyard/工具链
make soc-triple32-v3-tensor SOC_WORKSPACE=/path/to/workspace

# 整机实现是独立的、耗时且依赖真实工具和约束的任务
make bitstream
```

### 9.4 后续真实板测

视频固件应以匹配的当前 bitstream 下载；基准使用当前三图 ELF。可沿用已存在的下载命令和 `M/t/a` 测试流程。必须同时保存当前 bitstream、ELF 和模型生成 manifest/哈希，防止不同版本混跑。

### 9.5 关键行为不变量（每阶段对照）

```text
3 x Gemmini32 / 100 MHz
v26 正式版 / credit limit = 4 / hardware SAFE_MAX = 4
native opcode custom3/custom2/custom1
fixed plans + fixed/prepared packets
wait reuse + light FP/VCSR context
memory Pool/Resize and batch boundaries
Tensor release/ack and cache visibility
Head publication/PPU ordered MMIO
job/frame/version identity, ownership, timeout/drain/restart
video capture → tensor → inference → overlay
```

**数值与性能判定：**不能单凭 ELF SHA 相同与否判断行为等价，因为构建路径变化可能改变调试信息；应对编译选项、模型计划与指令包、协议轨迹、三图输出和性能统计同时比对。没有在本次新 bitstream + 新 ELF 上实测的成绩，不应宣称已验证。

---

## 10. 重构验收矩阵

| 维度 | 必须满足的验收条件 | 证据 |
|---|---|---|
| 唯一硬件 | 正式构建只有 `triple32_v3_tensor` | 当前清单 + `make check` |
| 唯一模型 | 仅 v26 三 worker 正式路径 | 构建规则 + link map + 运行日志 |
| 共享实现 | 视频、三图基准复用同一模型/ABI | Make 依赖和源文件哈希 |
| 目录可理解 | 各目录 README 列出职责、依赖、入口和所属测试 | README/文件树审核 |
| 生成闭包 | 不依赖旧绝对路径/旁置 Chipyard 私有工程 | 新 checkout SoC 生成和文件完整性检查 |
| 功能正确 | 模型三图、PPU、Tensor、缓存、Runtime 无新增失败 | 原生/Host/RTL 回归 |
| 异常处理 | credit 拒绝、延迟退休、超时、故障持有、drain 不弱化 | fault/resource/scheduler 测试 |
| 时序不失配 | Vivado 约束、hook、布局策略均被正确加载 | 工程审计与最终实现报告 |
| 真实板测 | 当前配置的完整视频与 `M/t/a`，零 mismatch | UART log + bitstream/ELF manifest |
| 历史保留 | 删除项可从 tag/提交恢复 | Git history 和基线 tag |

### 10.1 明确的失败条件

出现下列任何问题，应停止本阶段并回滚本阶段提交：

- 当前模型生成器找不到冻结输入，或靠开发者机器上的历史文件路径才可构建。
- 硬件配置名与参数头/软件 profile 不匹配，构建却继续完成。
- 修改了指令包、credit 预算、等待/完成证明、PPU 顺序或资源所有权而没有专门的语义变更评审。
- 真正的双 bank L2、TensorIngress、三路 MaxPool 或板级时序 Tcl 在新工程中丢失。
- 基准程序和视频程序不再共享同一 v26 核心。
- 通过删除失败用例、减少资源回收测试或关闭检查来“修复”重构失败。

---

## 11. 推荐提交粒度及 Codex 执行规则

建议一个阶段最多覆盖一种变化类型，便于审计和回退：

| 提交类型 | 内容 | 是否允许改业务逻辑 |
|---|---|---|
| `docs:` | 基线和当前架构导航 | 否 |
| `build:` | 单版本清单、Make alias、构建工具检查 | 否 |
| `refactor(hw):` | SoC 源/导出路径及 Tcl/Python 引用 | 否 |
| `refactor(sw):` | 模型与基准目录机械迁移 | 否 |
| `refactor(api):` | 旧 ABI 命名替换（独立提交） | 应保持行为等价 |
| `chore:` | 已证明无依赖的历史代码清理 | 否 |
| `test:` | 测试归位、验证当前构建和回归 | 否 |

对 Codex 的执行约束：

1. 每阶段开始前输出**实际旧路径 → 新路径映射**和**删除候选清单**，不做模糊的全仓库批量移动。
2. 每阶段修改后同时更新 Make/Tcl/Python/头文件/测试/README 引用；不能留下未发现的断链。
3. 在 P2/P3 目录迁移期间，**只允许机械修改路径和构建入口**，不得顺手合并函数、改代码逻辑、改变优化开关。
4. 删除旧实现前，先输出“为什么确认为未参与当前依赖闭包”的证据。
5. 每个阶段提交前运行对应可执行测试，并在提交说明中记录 PASS/FAIL/SKIP 与原因。
6. 不使用 `rm -rf` 清除整个 `build/` 而不先保存本地需要的 bitstream、ELF 和测量结果；`build/` 是本地产物，不是源码历史。
7. 未实际运行 Vivado、板测或性能对照时，报告中必须明确写 **NOT RUN**，不得用旧报告补成新 PASS。

### 可直接交给 Codex 的执行任务

> 在仓库 `Cc-aw/sixteen_camera` 中，基于当前 HEAD，按照《sixteen_camera 单版本收敛与目录重构实施方案》执行。唯一正式交付配置为 `triple32_v3_tensor`，当前模型为 YOLOv5nu v26 三 worker、credit=4；保留十六路视频底座与实时视频、三图基准两个入口。先执行 P0 并建立可恢复基线，再按 P1–P5 逐阶段提交；P6 按可用工具分别验证，不要声称未经执行的综合或板测已通过。重构仅整理目录、路径、构建、文档和已证明无依赖的历史代码；不改变 Gemmini/SoC、模型执行、Runtime、PPU、缓存发布、内存映射、时序约束、指令包和调度算法。每阶段提供旧/新路径映射、删除依据、测试结果与风险；遇到无法确定的构建依赖时保留文件并说明，而不是盲删。

---

## 12. 预期成果及后续工作

重构后最直接的导航应该是：

```text
找板级 RTL                 → hw/rtl/
找三 Gemmini SoC 源         → hw/soc/source/
找当前生成 SoC RTL/参数     → hw/soc/generated/
找 Vivado 构建与时序约束    → hw/vivado/、hw/constraints/
找实时主循环               → sw/src/app/
找帧选择和 worker 调度     → sw/src/ai/runtime/scheduler/
找任务、Tensor、Head 所有权→ sw/src/ai/runtime/resources/
找当前三 Gemmini 模型执行  → sw/models/yolov5nu/src/
找固定 plans/packets       → sw/models/yolov5nu/codegen/
找模型生成原始输入         → sw/models/yolov5nu/frozen/
找三图基准                 → sw/benchmarks/triple_infer/
找设备寄存器操作           → sw/src/drivers/
找性能日志分析             → tools/analyze/
找当前架构、接口与验收     → docs/
```

**工程原则：**先实现“只剩一套可复现的当前产品”，再研究三 Gemmini 并行度、NoC、L2 bypass、Tensor 数据通路或计算调度的性能优化。这两类修改分开提交、分开量测，才能准确判断性能变化来自何处。
