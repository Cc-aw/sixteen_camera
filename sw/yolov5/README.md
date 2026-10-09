# YOLOv5nu 640×480 Stage 8F 软件迁入

来源：`/mnt/data/fff/chipyard`，迁入日期：2026-09-09。本目录保留迁入模型材料，当前视频软件适配位于 `dim16_dual/`。所有源文件保留原内容、注释和版权；没有把同事代码的作者改为迁入者。

## 已复制内容

保留源工程相对层级，使 Python 脚本通过 `__file__` 推导出的 ROOT 指向本目录。

| 路径 | 内容 |
|---|---|
| `docs/YOLOV5NU*` | 算子数据流、NHWC/RVV 优化计划及阶段说明 |
| `scripts/` | 硬件感知量化、shared scale、图解析、Stage 8F AOT、验证、构建与原板测脚本 |
| `generators/gemmini/software/gemmini-ort/models/detection/stage8_640x480_hardware_aware/` | 最终 shared-scale ONNX、FP32/量化中间模型、manifest、69 张 SiLU LUT、整数参考 JSON/NPZ、五图 AOT |
| `generators/gemmini/software/gemmini-ort/models/detection/calibration/` | COCO128 校准图片与附属数据 |
| `generators/gemmini/software/gemmini-ort/models/detection/yolov5nu.pt` | 原始权重 |
| `generators/gemmini/software/gemmini-ort/models/detection/export_yolov5*.py` | 模型导出与量化代码 |
| `generators/gemmini/software/gemmini-rocc-tests/imagenet/` | AOT 生成器、640×480 源码/参数、Makefile、images.h 与辅助实现 |
| `generators/gemmini/software/gemmini-rocc-tests/include/` | Gemmini/RVV/SiLU 软件接口 |
| `generators/gemmini/software/gemmini-rocc-tests/riscv-tests/`、`rocc-software/` | 启动、链接、syscalls 与 RoCC 依赖 |
| `generators/gemmini/software/gemmini-rocc-tests/build/imagenet/` | 同事已编译的 640×480 ELF，仅保留作为来源参考 |
| `fpga/xcvu13p/tests/`、`fpga/xcvu13p/openocd/` | 原板测说明、五图 UART 记录与连接配置 |

874 个源文件，共 190,436,555 字节；逐文件来源、大小与哈希见 `SOURCE_MANIFEST.json`。独立验证产物位于 `validation/`，不覆盖迁入 AOT。

## 阅读结果

输入 `[1,3,480,640]`，ONNX 逻辑布局 NCHW，AOT 物理布局 NHWC；输出 `[1,84,6300]`。生成链路为 FP32 导出 → signed INT8 校准 → 7 个 Add 共享 scale 和 bias 重量化 → 图 manifest/LUT/整数参考 → 固定形状 C 和参数头 → 裸机 ELF。

Stage 8F 包含 76 个 Conv、69 个 fused SiLU、7 个共享尺度 Add、17 条 Concat→Conv split-K 边、4 组双消费者 SPAD 复用；arena 为 2,217,600 字节。检测头包含 RVV class candidate、sparse DFL 以及 CPU decode/NMS。profile 汇总存在包含关系，不能将 CPU operator 总计与 HEAD_CLASS/HEAD_DFL 重复相加。

原 tests README 写着 640×480 尚未板测，而算子数据流文档记录了板测结果；本次同时复制了其五图 UART 日志，保留文档原文。来源工程的结果不代表当前 N6 的结果。

## 本次验证

- 874 个文件复制前后 SHA256 一致；58 个 Python 文件 AST 解析、8 个 shell 脚本语法检查通过。
- 最终 ONNX 通过 `onnx.checker.check_model`，输入输出形状符合上文。
- 五图 AOT 的 shared Add / split-K / reuse / arena contract 全部符合 Stage 8F。
- 使用迁入脚本、模型、manifest、图片重新生成 image025：C、参数头、memory JSON 三个文件与来源 AOT **逐字节一致**。结果见 `validation/results.json`。
- 上述迁入验证未运行本工程 FPGA、修改 RTL 或生成比特流。

校验复制文件：

```bash
cd sw/yolov5
sha256sum -c SHA256SUMS
```

## 运行环境与后续适配

Python 生成依赖 NumPy、ONNX、Pillow；部分 host 验证另需 ONNX Runtime。完整重新导出/校准另需 OpenCV、Ultralytics/PyTorch。`SOURCE_PYTHON_VERSIONS.json` 记录本次用于生成验证的来源环境，null 表示未查到该 distribution，不代表完整重导出环境已就绪。没有复制 conda 环境或编译器；构建脚本需显式指定本机 `PYTHON` 和 `RISCV`，Spike 需另提供兼容的模拟器及 Gemmini 扩展。

迁入脚本的历史默认值多为 320×320。当前目标只使用 `stage8_640x480_hardware_aware`，运行时显式指定 640×480、模型和 manifest；没有迁入所有历史阶段的模型产物。来源 manifest/log 中的绝对路径是溯源信息，仍保留原样。

来源 `include/gemmini_params.h` 的参数为 DIM=32、BANK_NUM=4、BANK_ROWS=4096、ACC_ROWS=1024。合并新的计算 SoC 时，应核对动态 SiLU LUT、split-K、SPAD 容量、RVV、UART、时钟和缓存协议；来源 ELF 不能直接作为新 SoC 的验收固件。

当前单/双 worker 视频运行时见 [dim16_dual/README.md](dim16_dual/README.md)。原始迁入材料作为模型与整数参考对照保留。
