# sixteen_camera

Xilinx VU13P 十六路视频与 AI 平台。当前唯一硬件为 `triple32_v3_tensor`：1 Rocket、1 RVV、3 × Gemmini32，目标 100 MHz，含三路自主命令前端。
八路 OV7670 与 HDMI 封装的八路图像共组成十六路视频，保留采集、DDR、TensorIngress、Head/PPU 和 1080p60 显示叠加。

Gemmini 使用 custom0/1/2，custom3 用于前端控制。当前已接入 [V33 独立三图基准](sw/benchmarks/frontend/README.md)，包含正式版及 V33 诊断版。实时 v26 Runtime 尚未适配新 ABI，视频固件入口仍拒绝旧组合。硬件实现与接口见 [命令前端](docs/architecture/command-frontend.md)。

```bash
make help
make check-deps
make benchmark
make test-v33
make test-frontend SOC_WORKSPACE=<已生成工作区>
```

先配置 `tools/config/tools.local.mk`，工具和构建顺序见 [快速开始](docs/quickstart.md)。
硬件入口为 [hw/](hw/README.md)，软件入口为 [sw/](sw/README.md)，模型入口为 [YOLOv5nu](sw/models/yolov5nu/README.md)，完整导航见 [docs/](docs/README.md)。
V33 基准正式/诊断 ELF 位于 `build/firmware/frontend/`；`build/firmware/video/video.elf` 保留为尚未适配的实时固件。

`make soc SOC_REFERENCE=<Chipyard> SOC_WORKSPACE=<新目录>` 使用独立源码副本生成当前 SoC；`make project`、`make elaborate`、`make bitstream` 分别创建工程、检查 elaboration 和实现硬件。
`make test-rtl SOC_WORKSPACE=<已生成工作区>` 运行 RTL 聚合回归；`make help-tests` 列出定向测试。
下载当前匹配 bitstream 后，`make program` 下载 ELF；三图板测使用独立基准的 `M/t/a`。

当前验证状态和已知缺口见 [验收记录](docs/validation/current.md)。离线 PASS、整机时序和开发板数值/性能分别记录。
旧源码由 Git tag `before-single-version-refactor-20261015` 保存，重构过程见 [阶段记录](docs/validation/single-version-refactor.md)。
