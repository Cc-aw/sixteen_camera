# 三图日志分析

`check_log.py` 检查保存的 UART 日志，`analyze_log.py` 解析并汇总数值/性能及 credit、Pool/PPU 状态。
其余文件是相邻解析模块；少量图/packet 常量从模型 `codegen` 导入，不复制执行核心。
直接执行 `python3 tools/analyze/yolov5nu/analyze_log.py --help` 查看参数。
测试由 `make test-model` 聚合，日志结果必须注明对应 bitstream、ELF 和来源 manifest。
