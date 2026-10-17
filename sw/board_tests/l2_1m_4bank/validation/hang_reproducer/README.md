# 历史卡死诊断代码

这些文件保存2026-10-17诊断时的实际代码，使用本功能目录内复制的依赖。
它们不是正式性能程序；当前Git归档任务没有运行这些脚本或连接硬件。
工具路径与串口路径按当时主机保留；正式使用入口仍为功能目录的Makefile。

- `rocc_probe.c`：route0查询三路前端，已执行通过；route1仅构建，未执行。
- `build_trace.py`、`reference_trace.c`：每条前256命令及之后每128条加标记，
  对应precise日志。更早的前64条版本已被覆盖，未记录当时ELF哈希。
- `build_trace_dense.py`、`reference_trace_dense.c`：前1024条密集标记，构建未执行。
- `build_frontend_only.py`、`reference_frontend_only.c`：跳过direct，首帧5秒超时；
  旧watchdog原因字符串未同步修改，完成标记也不用于正式数值验收。
- `build_trace_fenced.py`、`reference_trace_fenced.c`：逐LoopConv附加fence的实验，
  仅构建，未执行，不能称为有效绕过或修复。
- `run_capture.py`：实际下载与UART捕获助手，输出只用于此次诊断。
- `inspect.py`、`run_inspect.py`：保留失败现场采样方式。原始卡死无法暂停；
  后一次访问的是诊断失败自旋，加载的符号为reference，不能恢复原始阻塞调用栈。

构建脚本先从本目录的冻结reference生成临时C，再使用本地 `build/generated/`
和 `build/obj/`。复现前需完成正式 `make all`；重新构建会产生新的构建身份，
不能把历史日志直接绑定到新的ELF。证据和哈希见上级 `board_status_20261017.json`。
