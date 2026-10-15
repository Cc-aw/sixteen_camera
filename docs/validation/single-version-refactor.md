# 单版本收敛实施记录

实施日期：2026-10-15。规范见
[实施方案](../architecture/sixteen_camera_single_version_refactor.md)。

## P0：真实基线

- 实施 HEAD：`cd361f5c0180d212979f229df3df1b4b3dc104e4`，包含方案分析基线之后的 V3 shared-memory timing repair。
- 恢复 tag：`before-single-version-refactor-20261015`。
- 初始工作区只有未跟踪的实施方案；保留原文，不覆盖用户改动。
- 本机证据：`build/refactor/p0/`，包含 HEAD、status、2174 项 tracked file 清单、全部源文件 SHA-256、原始方案、145 项现有固件/bitstream/依赖记录、`.d` 副本及两个入口的完整 Make dry-run。
- 路径映射：无。删除候选：无。现有 `build/` 产物保留。
- 唯一生产硬件：`triple32_v3_tensor`；完整 Config 类名不变；软件 `MODEL_WORKERS=3`、`MODEL_DIM=32`；三个参数头 `SAFE_MAX=4`；默认 v26 credit=4。

全部 13 个基线命令退出成功；`test-v26` 运行 175 项原生测试，无跳过。
R0 Tensor 版本回绕仍为 `characterization=PASS / correctness=FAIL`，不是本次修复。
当前两个固件构建完成后的 `.d`、ELF、map、生成输入/计划/包和 stamp 另存于
`build/refactor/p0/firmware-after/`，用于后续等价比对。

| 命令 | 结果 | 秒 |
| --- | --- | ---: |
| `make check` | PASS | 0.0 |
| `make test-v26` | PASS | 188.2 |
| `make test-software` | PASS | 41.9 |
| `make test-video` | PASS | 48.6 |
| `make test-tensor` | PASS | 83.7 |
| `make test-ppu` | PASS | 2.7 |
| `make test-video-pipeline` | PASS | 0.6 |
| `make test-memory-v3` | PASS | 0.2 |
| `make test-cache` | PASS | 0.1 |
| `make firmware` | PASS | 0.2 |
| `make firmware-benchmark` | PASS | 3.8 |
| `make check-v26-firmware` | PASS | 0.1 |
| `make check-deps` | PASS | 0.7 |

Vivado 工程、elaboration、综合、实现及板测：**NOT RUN**（P0）。
旧报告和旧开发板日志不能作为本次重构的硬件验收。

## P1：单产品身份与入口

路径映射：无。删除候选：无。新增 `hw/manifests/current.json`，记录唯一硬件、
Config、真实导出路径、三份参数头、模型规则/源码/冻结输入、来源锁和生成记录。
长 Config 目录保留，P2 不调整生成器内部目录布局。

`make check` 校验 JSON 身份、三个参数头的 DIM/SAFE_MAX/opcode、实际生成 RTL 的
credit/admission 门控，以及视频/基准 Make 展开的参数和关键模型开关。
Tcl 入口使用同一清单并拒绝旧选择器；直接视频构建也执行配对检查。
新增 `soc`、`benchmark`、`test-model`、`test-rtl` 和 `help-tests`；
`test-software` 同时覆盖原生模型与全部 Host runner。
原阶段测试和旧兼容别名暂留，行为及测试覆盖未裁剪。

本机证据：`build/refactor/p1/`。新建五项隔离参数 fixture 测试，并检查七种错误
配置均被拒绝（single4、dual16、错误 Config、worker 数、credit 参数等）。
视频/基准 ELF、fixed plans、packets 和 memory kernels 与 P0 的 27 项比较逐字节相同。
`make check-deps`、五项新 fixture、七种错误选择器、视频/基准构建、ELF 审核、
`make test-software` 全部 PASS；后者含 175 项原生模型测试及全部 Host/RV64 runner。
Vivado/综合/实现/板测：**NOT RUN**（P1）。

## P2：硬件源码机械迁移

| 旧路径 | 新路径 |
| --- | --- |
| `tools/soc/shell/` | `hw/soc/source/shell/` |
| `tools/soc/taihang_tensor_ingress/` | `hw/soc/source/tensor_ingress/` |

共迁移 569 个文件，逐文件映射见
[硬件路径清单](single-version-hardware-paths.json)。删除候选：无。
566 个文件逐字节相同；源码包的 README 和两份来源元数据仅更新位置/追溯字段。
Scala、RTL、SBT 内容不变；原来源哈希保留。生成脚本仍位于 `tools/soc/`。
导出长目录及 `gen-collateral/include/` 布局保留，完整 Config 类名不变。

`make soc SOC_WORKSPACE=/tmp/sixteen-camera-single-version-chipyard` 在新的独立
Chipyard 副本中完成 SBT 编译、Chisel/firtool、原 RAM 处理和结构检查。
与 P0 的 807 个导出文件相比，只有生成记录的时间/工作区和两份 annotation 中的
hierarchy 文件路径改变；全部 `gen-collateral` 内容（包括 RTL、参数和初始化文件）相同。
不是对 Verilog 进行源码映射替换。独立 protocol core 也通过正常生成流程导出。

`make check-deps`、`make test-rtl SOC_WORKSPACE=/tmp/sixteen-camera-single-version-chipyard`
全部 PASS，包含视频/整帧时序、Tensor DMA/恢复、TensorIngress protocol、真实双 bank L2、
MemoryParallelV3、PPU、当前生成 cache controller；视频重构建与实际 ELF 审核也 PASS。
本机证据：`build/refactor/p2/`，包括完整生成日志、源文件及生成文件比较。
Vivado/综合/实现/板测：**NOT RUN**（P2）。
