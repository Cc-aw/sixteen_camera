# 当前 S1 验证状态

默认版本为 DMA streaming + ASRAM S1，L2 512 KiB / 2 bank；硬件 ID `e037701c8d7cfc59`。
[当前生产身份](../../hw/manifests/current.json) 绑定硬件源、生成 RTL、板级工程和实时视频固件。
[默认切换记录](default-s1.json) 记录移除范围及离线验证。

用户已确认实时视频功能正常。软件包归档 `s1_live_01` 日志快照：completed=16950、published=16950、
软件 errors=0、fault=0，capture/admission mask=0xff。检测框持续更新的视觉结果来自用户实测确认。
原始快照和 SHA、当时 ELF SHA 位于
`sw/video_runtime/dma_load_streaming_asram_s1_512kib_2bank/validation/board_s1_live_01.{json,txt}`。
该快照记录持续运行，不据此声称停止排空已在板上通过；硬件 error_slots 是另一组位掩码，未当作软件 errors。

现有离线回归覆盖 8 个真实 Runtime/backend 场景、19 个工具/HAL 测试，
原生 S1 采集 RTL 验证缺失输入、持续采集和安全停止，同时复现旧中途取消的不可释放 ERROR。
三路原生 Gemmini/ASRAM 的 72 个数值用例证据保留在 S1 硬件包 validation/。
具体结果与历史修复分列于软件、硬件各自 validation/，Host mock 与开发板结果分别记录。

导入比特流 SHA256 `cb907a77e0c0bf97f5074208956884517d349485003a8d6613ca61b9f7e93a01`，
布局 URAM 588（ASRAM 216、Head 192），route errors=0，WNS −3.068 ns、WHS +0.001 ns。
现有负时序保留用于板上验证，未增加 bitgen 时序门禁。
本次提升默认只复用现有硬件，未重新综合、布局布线或自动连接开发板。
