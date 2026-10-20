# 当前验证集合

默认 S1 实时视频版本的入口：

- `make test-default`：拒绝错配硬件/ELF、对照完整 Tcl 清单验证 123 个板级 RTL、10 个 IP、6 个 XDC，以及四个下载/运行入口。
- `make test`：上述默认入口检查、固件构建、8 个 Runtime/backend 场景、19 个工具/HAL 测试及冻结 S1 采集 RTL。
- `make test-software`：固件构建及 Runtime/backend、工具/HAL 测试。
- `make test-input-rtl`：缺失输入许可停滞复现、47 帧连续生产、安全停止和旧取消错误复现。
- `make test-rtl RTL_RUN=<新名称>`：S1 原生三路 Gemmini/ASRAM 的 72 个数值用例，日志写入新的私有输出目录。

当前用例位于 `tests/default_s1/` 和 `sw/video_runtime/dma_load_streaming_asram_s1_512kib_2bank/tests/`。
`tests/host/`、其他旧定向 runner 和旧模型测试是历史基线；其原默认源码已删除，
不再由默认聚合入口调用，也不作为 S1 验收。恢复旧基线应从 Git 历史获取对应整套版本。
数据、LUT 和历史轨迹继续保留供独立实验参考。

离线通过与开发板验证分开记录，见 [当前验证](../docs/validation/current.md)。
