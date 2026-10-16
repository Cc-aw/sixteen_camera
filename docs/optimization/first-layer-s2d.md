# 首层 RVV 重排验证

这是独立的首层实验。生产模型、冻结 reference、默认固件和硬件配置均不变。
先在现有三路 DIM32/FP16、frontend ABI2 硬件上测试；不需要为这个实验重新生成 bitstream。
若当前板上还不是这一硬件 ABI，应先使用匹配的已有 bitstream。

## 计算与格式

原始首层为 `480×640×3 -> 240×320×16`，`6×6 / stride2 / pad2`。
RVV 将相邻 `2×2` RGB 像素排列为 12 通道，顺序为左上、右上、左下、右下，各保留 RGB。
首层等价为 `240×320×12` 输入、`3×3 / stride1 / pad1` 卷积。
权重离线置换，输入字节数、权重数量、输出形状、有效 MAC 数不变；沿用原 bias、FP16 scale、SiLU LUT。

实现位于 `sw/benchmarks/frontend/include/first_layer_s2d.h`。
RVV 使用 `vlseg6e8` 读取横向两个 RGB 像素，再用 `vssseg6e8` 将上下两行交织输出；支持尾部 VL 和非对齐字节地址。
原生 C helper 生成候选包，并逐项核对 reference 包不变及 SPAD/ACC 容量。
首层候选 tile 为 `[1,30,32,16,3,3,12]`，80 个卷积包。

## 构建与离线检查

在仓库根目录运行：

```sh
make test-first-layer-s2d
make test-first-layer-s2d-rtl
make program-first-layer-s2d PROGRAM_ARGS=--check
```

第一个命令构建私有 ELF，运行 host 测试、实际 RVV 指令 QEMU 测试，以及三张真实输入的全部整数累加结果等价检查。
QEMU 测试要求 `qemu-riscv64`，分别使用 VLEN128/256/512；实际板测要求 VLEN256。
第二个命令使用 Vivado/XSim 运行当前真实三路 DIM32 RTL，比较紧凑首层的原始/重排输出；不修改生产 RTL。
第三个命令检查 ELF 与下载环境，不连接开发板。

ELF 为：

```text
build/firmware/first-layer-s2d/yolov5_first_layer_s2d.elf
```

构建与审计文件均在私有目录 `build/firmware/first-layer-s2d/`。
离线验证不代表整幅图在板上的 Gemmini 输出或速度已通过。

2026-10-16 本次实现的离线结果：7 项测试通过；QEMU 的 VLEN128/256/512
实际 RVV 指令测试通过；三张真实输入的 3,686,400 个整数累加结果逐项一致。
当前三路真实 DIM32 RTL 的紧凑首层共 3,072 字节输出逐项一致，DMA 写 ACK 检查通过。
`make check` 和下载 `--check` 通过。RTL 证据在私有构建目录的 `rtl_evidence.json`。
完整首层随后完成上板验证，结果见下文；上述 RTL 证据仅记录离线仿真。

## 上板

打开 UART 日志保存后运行：

```sh
make program-first-layer-s2d
```

这个命令下载并启动上述独立 ELF，会替换正在运行的软件。实验不启动 PPU 或视频运行时。
板测应等待最终 `S2D1,PASS`；启动前的大 BSS 清零和计时外的完整比较也会耗时。
异常会输出 `S2D1,DIFF`、`S2D1,FAIL` 或 `S2D1,TRAP`，并停止。

## 串行、并行和重排开销

所有执行路径均使用真实图 025、036、142 以及首层真实权重。每个批次处理三张图：

| profile | 工作内容 | 重排是否计入总周期 |
| --- | --- | --- |
| reference | 原始 RGB 和 6×6 卷积 | 无重排 |
| prepacked | 预先用 RVV 重排，执行 3×3 卷积 | 不计，用于观察卷积潜力 |
| rvv_online | RVV 重排后执行 3×3 卷积 | 全部计入，用于决定是否值得使用 |

每种 profile 都分别执行：

- `serial`：lane0 依次处理三张图。
- `parallel`：lane0/1/2 各处理一张图。在线模式先重排一张并启动一路，再重排下一张，实现 CPU/Gemmini 重叠。

先运行一轮六种组合的 warmup，然后四轮正式测量，每种 profile/executor 累计 12 帧。
六种组合的执行顺序每轮反转；图像在三路间轮换。
每次测量前统一扫过 4MiB 缓冲区，形成相同缓存压力，但不宣称所有缓存行都被强制失效。
LUT 配置、表生成、输出 poison、缓存 sweep、计数器设置和输出比较均不在计时区间内。
计时包含 frontend 提交、轮询、ACK、完成 fence；在线模式还包含全部输入重排。

先在 lane0 用原始计划生成三张图的 reference 输出。所有 warmup/正式组合都比较全部 `3,686,400` 字节输出。
同时检查 packed 输入与标量排列逐字节一致，以及输入/输出前后的 canary。
任意一个字节不一致都会失败，不能只比较 hash 或部分输出。

输出三个 `S2D1,SUMMARY`：

- `parallel_speedup_x1000 = serial_cycles / parallel_cycles × 1000`：同一 profile 的并行加速比。
- `parallel_efficiency_x1000 = serial_cycles / (3 × parallel_cycles) × 1000`：三路利用率，1000 表示 100%。
- `serial_gain_x1000`、`parallel_gain_x1000`：同执行方式下 reference 周期除以当前 profile 周期；大于 1000 表示候选更快。

`RESULT.pack_cycles` 为在线模式 CPU 在 RVV 重排及其发布 fence 上花的周期之和。
并行时它与卷积可以重叠，不能从总周期直接相减来得到纯卷积周期。
各窗口还记录三个 Gemmini 的 RS、EX、DMA 请求背压、TL A 背压、执行端 A/B/D 等待事件之和。
计数器可能重叠，且并行时三个 lane 的事件总和可能大于批次墙钟周期；不能相加当作可节省时间。
`load_req_wait/store_req_wait` 对应 `dma.req.valid && !dma.req.ready`，并非直接的 SPAD bank 冲突计数。

## 分析日志

将完整原始 UART 保存为例如 `tests/log/first_layer_s2d.log`，运行：

```sh
python3 sw/benchmarks/frontend/scripts/analyze_first_layer_s2d.py \
  tests/log/first_layer_s2d.log
```

生成 `build/reports/first_layer_s2d.txt` 和 `.json`，列出串行/并行周期、并行加速比、利用率及相对 reference 的收益。
分析器只接受最后一个完整会话，严格检查 24 条正式、6 条 warmup 记录及三个 summary 的算术关系。
缺记录、重复记录、FAIL、损坏或最后会话未结束均失败；不会从旧会话补记录。

最终判断看 `rvv_online` 的串行和并行收益，尤其是包含全部重排开销后的并行周期。
`prepacked` 的收益仅表示省掉运行时重排后的潜力，可用于判断是否值得让 Tensor 生产端直接生成该格式。
这里得到的是首层加速比，不能直接当成整网或整机 FPS 的加速比。

## 2026-10-16 上板对比结果

原始 UART 归档为 [board_20261016.uart.txt](../../tests/data/first_layer_s2d/board_20261016.uart.txt)，
SHA256 为 `66c5065fa6cc00eb33aba16c8593a2df3949daea1ca13b1806217fe0811a02ff`。
使用上述严格分析器验证通过：24 条正式记录、6 条 warmup、三个 summary 和最终 PASS 完整，
累计比较 110,592,000 字节输出，全部逐字节一致。
日志没有记录 bitstream 标识，不能据此认定已验证新四 bank L2 硬件。

以下每项为四轮累计 12 帧周期，频率 100MHz；warmup 不计入。

| profile | 串行周期 | 三路并行周期 | 并行加速比 | 相对 reference 串行收益 | 相对 reference 并行收益 |
| --- | ---: | ---: | ---: | ---: | ---: |
| reference | 28,628,290 | 10,099,130 | 2.8347× | 1.0000× | 1.0000× |
| prepacked | 6,875,833 | 2,410,250 | 2.8527× | 4.1636× | 4.1901× |
| rvv_online | 27,052,169 | 22,695,223 | 1.1920× | 1.0583× | 0.4450× |

预重排后的卷积收益明显，但不包含重排成本。RVV 在线重排让串行耗时减少 5.51%，
三路并行耗时却增加 124.72%。在线重排在串行窗口累计消耗 20,184,062 周期，
并行窗口累计消耗 20,404,060 周期；折合每帧约 16.82ms 和 17.00ms，
分别占对应窗口的 74.61% 和 89.90%。当前独立首层实验主要受 CPU 重排吞吐限制。
生产默认仍保留 reference。

复现结果分析：

```sh
python3 sw/benchmarks/frontend/scripts/analyze_first_layer_s2d.py \
  tests/data/first_layer_s2d/board_20261016.uart.txt
```

整网尚未接入本候选，也未实测整网收益。此前 V34 的 12 帧串行/并行周期分别为
111,021,078 和 43,552,864，对应 2.5491×；它与这里的独立首层实验具有不同的缓存与调度环境。
若假设其余层完全不变、预重排免费，用本实验首层周期差替换整网首层，估计串行平均每帧
92.52ms 降至 74.39ms，三路整批耗时 435.53ms 降至 358.64ms。
这只是跨实验估计，不能作为整网板测结果，也不能用于预测硬件请求合并的实际收益。
在线重排能否与后续网络层重叠需要完整集成后另测。
