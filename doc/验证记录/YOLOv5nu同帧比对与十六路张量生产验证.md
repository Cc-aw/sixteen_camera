# YOLOv5nu 同帧比对与十六路张量生产验证

此文记录移除旧预处理之前的阶段。CH1–CH16 的 `x` 同帧逐字节比较已由板上验证通过；后续默认构建移除旧批量预处理，并将流式槽位接到推理调度。当前命令和验收方法见 [流式输入正式接入验证](YOLOv5nu流式输入正式接入验证.md)。

## 构建与下板

```bash
bash scripts/run_yolov5nu_tensor_slot_ingest_tests.sh
make -C sw
/mnt/data/Vivado/Vivado/2023.2/bin/vivado -mode batch \
  -source scripts/build_tensor_production_bitstream.tcl
bash scripts/download_bitstream.sh
bash sw/run.sh --no-build
```

只使用本次成功生成的 `prj/sixteen_camera.runs/impl_1/top_wrapper.bit`。构建日志必须出现 `TENSOR_PRODUCTION_BITSTREAM=PASS`，并检查 `prj/tensor_production_timing.rpt` 的时序结果。

## 同一帧逐字节比对

AI 默认停用；若已启用，按 `i` 停用并等待空闲。串口按 `x`：旁路抓取选中通道的一帧到 `0x33000000`，然后取得帧缓冲快照。帧缓冲管理器现在同时保存摄像头原始帧号和原有的成功写入计数；只有原始帧号与旁路帧号相等时，才运行旧预处理并比较全部 921600 字节。结果为 `TENSOR COMPARE PASS ch/frame/bytes=...` 或带首个差异偏移的 `FAIL`。若帧缓冲写入落后、跳帧或快照已转到下一帧，会打印 `SKIP frame mismatch`，应重试，不可计作像素比较失败。按 `N` 切换通道，再按 `x`，逐路验证 CH1–CH16。

## 十六路持续张量写入

串口按 `m` 启用十六路路径；每路有两块独立槽，物理地址沿用 Arena0/1 的对应成员，单槽间距 921600 字节。每路都有独立视频 tap 和张量 writer，但十六路共用一条 AXI 写口。板上十六路同时抓帧使输入 FIFO 溢出，因此当前版本采用轮转准入：同一时刻只抓取一路完整帧，完成写入后轮到下一路。这样验证所有通道的持续生产和槽位生命周期，但不代表十六路同时写入或每路 30 FPS 吞吐。AXI 写请求经逐级公平仲裁进入现有一致性 FBus。槽位在最终 AXI B 响应后才置 READY；READY 在软件释放前不会重写。槽满时跳过新帧并累计 `no_slot`，坏帧、FIFO 溢出和 AXI 错误不会发布 READY。

固件 `m` 模式会读取每个 READY 槽的帧号与字节数，检查帧号递增、字节数为 921600，然后释放槽位。每秒打印十六路完成计数及 `missed/no_slot/overflow/error`。再次按 `m` 停止接收新帧并等待进行中的写入和槽位释放，输出 `TENSOR PROD drained`。运行 `m` 时旧预处理和 AI runtime 不应启动；旧预处理硬件启动条件也增加了生产路径静止门控。

板上验收至少观察每路计数持续增长、`overflow=0`、`error=0x00000000`，并记录 `missed/no_slot` 及视频采集/显示异常。`missed` 统计生产路径未处于等待 SOF 状态时错过的源帧；在单路轮转准入下，它会正常增长。`no_slot` 是两个槽都尚未释放的情形。软件每次只验证元数据，不读取全部十六路张量，因此生产模式尚未进行逐槽内容哈希；内容一致性由逐路 `x` 验证。

## MMIO 补充

`FRAMEBUFFER_BASE=0x10140000`。原始源帧号在 `0x2CC`，由既有 `AI_META_INDEX` 快照邮箱选择。生产控制 `0x2D0`：bit0 启用，bit1 触发释放且读回时表示释放忙；释放掩码 `0x2D4`；READY/WRITING/ERROR 掩码分别为 `0x2D8/0x2DC/0x2E0`。槽索引 `0x2E4`，选中槽帧号/字节数 `0x2E8/0x2EC`；选中索引低四位对应通道的 `no_slot/overflow/missed` 计数为 `0x2F0/0x2F4/0x2F8`。槽索引 0–15 对应 Arena0，16–31 对应 Arena1。
