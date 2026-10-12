# V17 A 三 worker 运行时

移植来源：开发工程 `sw/yolov5/triple32` 的 `ppu-head-clean` 配置。
原始文件及输入数据来源哈希保存在 `import_manifest.json`；移植后源码和输入
哈希保存在 `sources.lock.json`。开发目录只用于来源说明，不参与构建。

`native/` 是生成器的冻结输入，保留原来的 `dim16` 符号名以匹配模型 API。
实际模型由 `generate_parallel.py` 从原生 DIM32 ABI 生成，随后烘焙固定计划、
完整 RoCC 包、WS 包和 SiLU 表。权重共用上级 `aot/` 的 image025 模型；
三个量化输入单独保存在 `tests/data/yolov5nu/v17a`。

`v17a.mk` 固定单包提交、200 µs、light context、fixed policy、hot paths、
fixed plans/packets、idle priority、tail wait、prepared packets、PPU early 和
head clean；Class0 提前入队与 RoCC layer profiling 均关闭。

从仓库根目录运行：

```sh
make firmware SOC_VARIANT=triple32_v3_tensor
make firmware-benchmark
make test-v17a
```

实时固件复用现有视频、Tensor slot、EDF 调度、结果管理和硬件 overlay；
独立调度器支持稀疏启动、单 worker 复用及非阻塞 WAITING 扫描。
基准固件保留开发工程的三图数值比对和性能测试流程。
详细使用及验证边界见 `docs/integration/triple32-v17a-software.md`。
