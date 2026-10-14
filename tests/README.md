# 回归测试

`host/` 保存六组当前软件单元测试。`rtl/` 保存定向回归入口，testbench 按 `rtl/benches/{common,video,memory,tensor,ppu}` 分组。`data/yolov5nu/` 是整数参考 corpus；NumPy 依赖见 `requirements.txt`。

在仓库根运行 `make test-software test-video test-tensor test-ppu`。`make test-cache` 使用最新三路 SoC 的真实生成 L2 控制模块。`bash tests/rtl/run_yolov5nu_postprocess_tests.sh` 运行模型后处理 corpus/RTL 检查。

软件/RTL 中的三 worker 队列测试覆盖通用资源容量，当前交付模型使用三个 DIM32 v26 worker。历史 dual 板测入口不再对应当前硬件。当前板测使用 v26 独立基准的 `M/t/a`；离线测试不会连接开发板。

`make test-video-pipeline` 校验完整 1920×1080 帧、4KiB burst 分拆、事件 FIFO 满载恢复和持续返回背压。真实双 bank L2/Tensor 测试使用最新生成工作区，内侧 A/B/C/D/E 均为两条目寄存队列；并发刺激显式保留响应到 Tensor 事务开始，不依赖旧延迟的偶然同拍。
