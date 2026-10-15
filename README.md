# sixteen_camera

Xilinx VU13P 十六路视频与 AI 平台。当前唯一交付为 `triple32_v3_tensor`：1 Rocket、1 RVV、3 × Gemmini32，100 MHz，配合 YOLOv5nu v26 三 worker、credit=4。
八路 OV7670 与 HDMI 封装的八路图像共组成十六路视频，保留采集、DDR、TensorIngress、Head/PPU 和 1080p60 显示叠加。

实时视频与 image025/036/142 三图基准共用模型源码、生成器、权重和 ABI。交付身份及真实路径由 [current.json](hw/manifests/current.json) 记录，生产构建拒绝退休配置或不匹配参数。

```bash
make help
make check-deps
make firmware
make benchmark
make test-software
```

先配置 `tools/config/tools.local.mk`，工具和构建顺序见 [快速开始](docs/quickstart.md)。
硬件入口为 [hw/](hw/README.md)，软件入口为 [sw/](sw/README.md)，模型入口为 [YOLOv5nu](sw/models/yolov5nu/README.md)，完整导航见 [docs/](docs/README.md)。
视频 ELF 位于 `build/firmware/video/video.elf`，基准 ELF 位于 `build/firmware/benchmark/benchmark.elf`。

`make soc SOC_REFERENCE=<Chipyard> SOC_WORKSPACE=<新目录>` 使用独立源码副本生成当前 SoC；`make project`、`make elaborate`、`make bitstream` 分别创建工程、检查 elaboration 和实现硬件。
`make test-rtl SOC_WORKSPACE=<已生成工作区>` 运行 RTL 聚合回归；`make help-tests` 列出定向测试。
下载当前匹配 bitstream 后，`make program` 下载 ELF；三图板测使用独立基准的 `M/t/a`。

当前验证状态和已知缺口见 [验收记录](docs/validation/current.md)。离线 PASS、整机时序和开发板数值/性能分别记录。
旧源码由 Git tag `before-single-version-refactor-20261015` 保存，重构过程见 [阶段记录](docs/validation/single-version-refactor.md)。
