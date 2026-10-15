# SW Runtime R1b：PPU Device HAL

日期：2026-10-13。基线：`b4629f5`（R1a），实施分支：`main`。
先按用户要求快进合入 R0/R1a，删除两个已合并的开发分支；后续保留分阶段提交，直接在主分支实现。
本阶段对应 [重构设计](sw-runtime-refactor.md) R1 的 PPU 边界，
机器可读证据见 [验证记录](../validation/sw-runtime-r1b.json)。完整 R1 仍待 R1c。

## 1. 设备层与兼容层

| 文件 | 变更 |
| --- | --- |
| `sw/src/drivers/ppu/ai_ppu_device.h` | 设备描述符、队列完成元数据、publication receipt、原始 detection、计数及接口；不带 Runtime job/worker owner |
| `sw/src/drivers/ppu/ai_ppu_device_publication.c` | 六 bank/CPU alias、generation、begin/select/publish/abort、receipt 读取和 generation/status 校验 |
| `sw/src/drivers/ppu/ai_ppu_device_queue.c` | 队列启用/expect/submit/peek/pop、单命令地址提交、状态/reader/计数/原始 detection 读取 |
| `sw/src/ai/postprocess/ai_ppu_publication.c`、`ai_ppu_queue.c` | 原 API 兼容适配，转换原 Head 描述符及结果类型；设备实现通过这两个原编译入口各包含一次 |
| `sw/src/ai/backend/ai_model_backend_yolov5nu.c` | 所有直接 PPU CSR 访问接设备接口；仍负责 cache flush、时钟/超时、Head 所有权、完整身份匹配、回收及 fault 策略 |
| `tools/check/check_firmware.py` | ELF 检查沿 PPU 适配调用继续追踪设备函数，防止屏障藏在下层而被误判 |
| `tests/host/`、`tests/data/runtime/r1a/`、根 Makefile | 冻结旧 publication/queue/backend oracle；设备、live/legacy 后端轨迹及 ELF 审计负例；增加两个测试入口 |

保留旧文件作为**过渡编译入口**有明确原因：V17A 的 ordered MMIO 只配置于原 publication/queue
两个对象，且冻结模型的 benchmark Makefile/测试直接引用这些路径。两份设备 `.c` 在对应适配文件
中各编译一次，原 Makefile 和模型快照保持；当前不能再同时将这两份设备源加入独立链接对象。
固件 `.d` 依赖覆盖被包含的设备实现，修改设备源码会触发原对象重编译。
后续统一构建/目录迁移再将设备对象独立接线，保持相同 per-object 屏障边界。

新设备类型只带硬件地址和 stream/frame/version/generation。
原 `AiHeadSlotDescriptor`、`AiPpuQueueResult` 及模型请求/完成 ABI 均未修改。
兼容 submit 在 readiness 成功后才转换描述符，并调用 `submit_ready()`，避免提前读 metadata
或多读一次 readiness；独立设备 `submit()` 仍执行原 readiness 预检。
peek 无结果时不改调用者输出，peek 不自动 pop，也不自动释放 Head。

## 2. 保持的行为

- begin 的探测、bank 选择、allocated 校验、generation 增量与回读、publish receipt 位掩码及 abort 顺序保持；generation 回绕到 0 的旧行为保留。
- abort 先写 abort/fence，再看 clean busy；忙时不发 release。此接口仍不能单独证明所有消费方已经停止。
- queued submit 仍交错写 class/DFL 地址；单命令路径仍先写全部 class，再写全部 DFL。未合并两种顺序或增加屏障。
- queue metadata 保留完整 64 位 frame；结果的 bank/generation/stream/frame/version/count/status/cycles 顺序保持。
- live receipt 仍按 status → generation → masks 读取；状态/generation 校验移入设备纯比较接口，publication mask 收齐及超时仍由后端判断。
- Compute Done、PPU admit、Result Done、Head release、错误匹配不 pop、故障保持占有、CPU fallback banner 与 UART 参数保持。

V17A 两个 PPU 对象继续使用 `yolo32_ppu_io_barrier`；Tensor/通用 backend/模型对象未扩散该编译宏。
后端 live 初始化的原显式 read barrier 保留。设备不会替调用者 flush cache、调度模型或决定资源归属。
模型计算、RoCC/context、缓存操作实现、硬件及 source lock 均未改变。

## 3. 验证

| 命令 | 结果 |
| --- | --- |
| `make test-ppu-device` | PASS；普通/ordered 两种模式分别 664/716 个事件，完整 CSR/屏障文本轨迹与冻结 R1a 一致；覆盖六 bank/alias、缺失硬件/无效 bank、busy/ack 错误、generation 回绕、receipt、busy clean abort、重复操作、队列背压/完整 metadata、原始结果和计数 |
| `make test-runtime-ppu-hal` | PASS；live identity/generation-fault/abort-gap/all-workers 分别 350/127/37/769 个事件；1/2 worker 的 publication-on/flush-fallback/reader-busy/PPU-error/timeout/CPU-fallback 各 54/40/56/84/47/3 个事件；MMIO、屏障、cache 操作、模拟 cycle、身份及 UART 参数一致 |
| `bash tests/host/run_v17a_elf_audit_test.sh` | PASS；原 inline 与适配 tail call 两种合法形式通过；缺失 barrier、下层 global fence 两个负例被拒绝 |
| `make test-software` | PASS；全部当时的 host runners、ABI/QEMU、R0 及 R1a 回归；新增 legacy 路径及审计负例随后单独通过 |
| `make test-v17a` | PASS；101 个 Python 用例、Host/RV64 QEMU live context/backend，未跳过 |
| `make test-ppu SOC_VARIANT=triple32_v3_tensor` | PASS；publication manager、gate/mux、Head cache 和 PPU 集成 RTL 回归 |
| `make firmware SOC_VARIANT=triple32_v3_tensor` | PASS；V17A 三 worker 实时固件 |
| `make firmware SOC_VARIANT=dual16` | PASS；双 worker 固件 |
| `make firmware SOC_VARIANT=single4` | PASS；单 worker 固件 |
| `make firmware-benchmark` | PASS；三图基准固件，原模型构建入口保持 |
| `make check-v17a-firmware check-deps SOC_VARIANT=triple32_v3_tensor` | PASS；适配后的真实 ELF 屏障、light context、manifest/source lock 与源依赖闭包 |

新增设备/后端 Host 对照均使用 `-O2 -Wall -Wextra -Werror`。
legacy 路径使用模型 double，额外 V17A 头编译宏只为复用测试 fixture；不声称模拟了真实 Gemmini/DMA。
模拟 cycle 对照只证明操作/计时调用轨迹一致，实际板上新增函数调用与类型转换开销未测量。
生成 ELF、map、反汇编、依赖快照与日志保存在忽略的 `build/runtime-refactor/r1b/`。

## 4. 剩余边界与回退

板上下载、UART 捕获、FPS 测量均 NOT_RUN；未启动完整综合或布局布线。
R0-GAP-01（abort 缺少停止证明）、R0-GAP-02（Tensor version 回绕误判 stale）仍为目标契约 FAIL，
characterization 通过只表示现状未变。多 stream 同时双 READY 的交错限制也保持 R0 记录。
诊断模块与冻结模型的独立 PPU orchestration 仍保留原路径，后续按接口/后处理阶段迁移。

本次可整体 revert 到 `b4629f5`，无需恢复已删除的开发分支。
下一步 R1c 抽 overlay/cache 能力边界后签收完整 R1；R2 再处理资源身份及有停止证明的安全回收。
