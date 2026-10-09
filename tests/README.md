# 回归测试

`host/` 保存六组当前软件单元测试。`rtl/` 保存定向回归入口，testbench 按 `rtl/benches/{common,video,memory,tensor,ppu}` 分组。`data/yolov5nu/` 是整数参考 corpus；NumPy 依赖见 `requirements.txt`。

在仓库根运行 `make test-software test-video test-tensor test-ppu`。`make test-cache SOC_VARIANT=single4` 选择另一份 SoC 的真实生成 L2 控制模块。`bash tests/rtl/run_yolov5nu_postprocess_tests.sh` 运行模型后处理 corpus/RTL 检查。

软件/RTL 中的三 worker 队列测试覆盖通用资源容量，当前交付模型只支持一或两个 worker。包含 UART/JTAG 的 `run_yolov5nu_dual_correctness.sh` 是板测入口；离线测试不会运行它。
