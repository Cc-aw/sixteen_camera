# Taihang 专用 Tensor 写入口

新增 `axi4_tensor` 将视频 Tensor 写入接到 SBUS 的 L2 上游。原 FBus 保留给后处理读取及缓存发布。第一版支持 64B 对齐、256bit 两拍、全字节有效的 INCR 写；不支持读、窄写或其他长度。地址沿用现有两块 arena 的 CPU 别名 `0xb0000000` / `0xb1000000`，每块范围为 `0x00e10000` 字节。

通用 `AXI4ToTL` 的带 mask `Put` 会产生 `PutPartialData`。新入口收齐整行后使用无 mask 重载产生 `PutFullData(size=6)`。本地 InclusiveCache 对冷行整行覆盖可以申请 `AcquirePerm`，后级 CacheCork 直接返回权限，不必先取旧 DDR 数据；L2 的一致性 probe、替换和脏行写回仍然保留。

## 构建和选择

源文件交付在 `tools/soc/taihang_tensor_ingress/TensorIngress.scala`；构建脚本将它安装到 Chipyard 的 Taihang FPGA 包。脚本只在 `chipyard_fpga` 构建块增加缺少的 Chisel 编译插件，不替换其他配置或计算侧代码。默认本地 Chipyard 路径为 `/home/wzr/chipyard`，可用 `--chipyard` 指定。

```bash
python3 tools/soc/build_tensor_ingress.py --emit-core
make test-tensor-ingress
export SOC_CONFIG=tsmcchip.fpga.taihangsoc.TaihangSoCFPGATestHarness.TaihangSoC1Rocket1RVV2Gemmini16x16PackedFullOps256BitTensorIngressConfig
make check
TOOLCHAIN=/home/wzr/chipyard/.conda-env/riscv-tools/bin/riscv64-unknown-elf- \
  python3 tools/build/build_dual16_video_yolov5nu.py --tensor-ingress
make elaborate VIVADO_PROJECT="$PWD/build/tensor_ingress_project/tensor_ingress.xpr"
make bitstream VIVADO_PROJECT="$PWD/build/tensor_ingress_project/tensor_ingress.xpr"
```

`--variant single4` 生成对应的 single4 TensorIngress 配置。计算 ABI 沿用所继承的配置；现有 `SOC_VARIANT=dual16` / `single4` 固件仍与各自的新端口版本匹配。`SOC_CONFIG` 仅选择硬件。

Vivado 根据所选 harness 的实际 `axi4_tensor` 端口设置 `SOC_TENSOR_INGRESS` 宏。切换回旧配置会删除这个宏，Tensor 恢复原 FBus 路径。重新运行项目 setup 后再构建，不要手工留下宏。为避免干扰已有 Vivado 工程，新入口使用上面的独立项目路径。

## 事务和完成语义

- AXI AW/W/B：33bit 地址、256bit 数据、5bit ID；`AWLEN=1`、`AWSIZE=5`、INCR、非独占、64B 对齐、两拍 WSTRB 全为 1。
- 64 个事务记录及 4KiB 行缓冲，32 个独立 TL source。AXI ID 不决定 source，同一个 ID 可以有多个事务在途；B 按 AW 顺序返回。
- 两拍 A 使用同一地址和 source，中途不会插入其他请求；source 在 A 最后一拍和 D AccessAck 都完成后释放。B 只有此后才能返回，包括提前 AccessAck 的情况。
- 越界地址返回 DECERR；不支持的格式、部分字节使能、WLAST 与 AWLEN 不一致返回 SLVERR。消费 AWLEN 指定的所有数据拍后返回，不发送 TL 请求。不完整或非法 AXI 流量无法保证自行恢复，必须遵守 AW/W 配对。
- B 表示一致性写已确认，数据可能仍在 L2。Tensor READY 仍等待该帧所有 B 成功；它不代表 DDR 已写回。槽位继续按原协议释放。
- CDC 复用独立 AW/W/B FIFO，深度 32/512/32，不轮换 AXI ID。视频/SoC 时钟独立，显式设置 `RELATED_CLOCKS=0`；原视频/DDR UI 连接默认保持相关时钟配置。XDC 增加新路径的复位第一同步级例外，第二级仍正常计时。系统复位需同时清空生产者、CDC 两端和 SoC 入口；不支持仅重置一端后保留旧事务。
- 当前配置的 SBUS/CBUS 都使用同一个 100MHz 时钟。将配置片段移植到其他 SoC 时需保留这一条件，或为统计控制端口补上正确的时钟跨越。

## 板上统计

统计 CSR 位于 `0x02012000`，窗口 4KiB。`+0x00` 写 1 原子快照；`+0x08` 为版本 `0x54454e5300000001`。快照数据均为 64bit，全局复位清零，快照命令不会清计数器。裸机 helper 见 `sw/src/platform/tensor_ingress.h`；只可在带新入口的 bitstream 上调用，旧 SoC 没有这些寄存器。

| 偏移 | 内容 |
| --- | --- |
| 0x20 | SoC 周期 |
| 0x28 / 0x30 | W 接收有效字节 / B 成功完成字节 |
| 0x38 | B 错误事务数 |
| 0x40 / 0x48 | AW / W 背压周期 |
| 0x50 / 0x58 | TL A 背压 / source 耗尽周期 |
| 0x60 | B 背压周期 |
| 0x68 / 0x70 | 当前 / 最大在途 source 数 |
| 0x78 / 0x80 | 第一拍 A 到 AccessAck 延迟总和 / 最大值 |

使用两次快照的差值，在 100MHz 下计算：

```text
有效带宽 MB/s = Δcompleted_bytes × 100 / Δcycles
```

应在实际计算和后处理并发时测量至少 10 秒，记录每路帧进度、错误、数据校验及背压统计。当前 `640×480×3×16×30` 要求 442.368 MB/s，写通路验收目标为持续 600 MB/s。仿真和理论端口容量不能替代这一板测结果。
验证 600 MB/s 余量时，输入源必须提供足够数据；固定 16 路各 30 帧只会产生 442.368 MB/s，不能仅凭低于 600 的读数判定入口受限。

诊断固件输出 `build/firmware/gemmini_dual16_tensor_ingress_video_yolov5nu.elf`，使用独立构建目录，不覆盖原固件。启动后按 `g` 保存首次快照，在实际负载下运行至少 10 秒后再按 `g`，输出 `completed_MBps` 和各阶段背压差值。该命令可在 Tensor 生产和 AI 运行中执行。固件启用新 CSR 访问，只能搭配 TensorIngress bitstream。

板级 I²C/时钟驱动必须使用 `sw/src/platform/platform.h` 的 CPU 地址表，不能使用第三方快照中的内部 BD 地址表。构建规则通过 `-iquote` 选择项目头文件，并在 Makefile 更新时重编这两个驱动。若启动异常为 `mcause=7, mtval=0x40010040`，这是旧驱动访问了错误的 I²C 复位地址；本 SoC 正确地址为 `0x10050040`。2026-10-10 已重编诊断 ELF 并核对反汇编，重新下载修正后的 ELF 即可，不需因此重编 FPGA。

TL A 背压高说明 SBUS/L2 接收受限；source 耗尽同时伴随响应延迟升高说明完成延迟限制在途窗口；B 背压高说明完成返回链路受限。这些计数器定位的是入口边界，不能独自区分所有 L2/DDR 内部原因。

## 验证

`run_tensor_ingress_tests.py` 验证提前 AccessAck、D 乱序、同 ID 多事务、source 耗尽、记录回绕、错误输入及整体复位。

`run_tensor_ingress_l2_test.py` 使用新配置实际生成的入口、InclusiveCache、CacheCork 和 SRAM 模型，并经过新的板级 CDC。覆盖冷行整行覆盖无旧数据 Get、驻留行覆盖、模拟 CPU 持有脏行时的 ProbeAckData、一组超过八路的替换写回、读回校验、CSR 快照。额外将请求改为 PutPartialData 作为对照，检查冷行确实需要读取旧数据。这个测试验证缓存行为，不代表真实 DDR 或推理并发下的板上吞吐。

完整 FPGA 时序及板上带宽须以对应配置的综合、布局布线报告与实际运行记录为准。

## 当前验证结果（2026-10-10）

- dual16 和 single4 的新 SoC RTL 均已生成。入口协议测试、两种配置的真实 L2/CDC 测试，以及原 Tensor DMA 回归通过。
- dual16 FPGA 综合及比特流生成完成，但布局布线时序未收敛：WNS 为 `-7.237ns`，TNS 为 `-182811.844ns`，setup 失败端点为 122003；最差报告路径位于 Rocket tile 内部 DSP 运算链。比特流生成成功不代表时序验收通过。
- 诊断 ELF 的第三方板级驱动地址选择已修复。`axi_iic_init` 的复位访问由错误的 `0x40010040` 改为 SoC CPU 可见的 `0x10050040`，已核对头文件依赖和最终 ELF 反汇编。修正后 ELF SHA256 为 `2cac11c3ea2246df23a9ab0e37dbb061cdf2bf3c4c8948da412010311f629410`。

用户提供的板上 `W` 测试使用八路摄像头、准入数 8、64B 写事务，记录如下：

| 项目 | 结果 |
| --- | --- |
| 数据拍 / 传输字节 | 67240730 / 2151703360B |
| SoC 周期 / 测试时长 | 1000002152 / 10.00002152s |
| 传输带宽 | 215.1699 MB/s（UART 整数显示 215） |
| 发出事务 / 收到 B 响应 | 33620365 / 33620365 |
| 排空后在途 / 最大在途 | 0 / 24 |
| 数据饥饿 / AW 背压 / W 背压 | 0 / 0 / 0 |
| 视频时钟域 B 等待周期 | 864816064 |
| 溢出 / 槽位错误掩码 | 0 / `0x00000008` |

前七秒 CH1–CH8 基本达到各 30 FPS；随后 CH4 成功完成计数停在 237，末次周期报告 missed 合计为 34。`0x8` 表示 CH4 第一槽位的错误标志，不是错误原因码；首次错误的类型及 AXI 响应错误计数未取得，不能将收到全部 B 响应等同于全部写入成功。

八路各 30 FPS 的输入量为 221.184 MB/s，本次观测达到约 97.3%，约为此前 17 MB/s 的 12.7 倍。当前测试使用真实视频源，不能据此确定新端口最大带宽，也没有验证十六路 442.368 MB/s 或持续 600 MB/s 的余量。

代码审查发现尚未修复的坏帧恢复缺陷：`ctx_bad && channel_desc_pending == 0` 的退役分支没有检查 `ctx_active` 或清除 `ctx_bad`，会在坏帧退役后持续将 `flush_count` 重装为 8，阻止该通道再次准入。这与出错后 CH4 持续停路的现象一致，但首次坏帧原因仍待确认。现有故障回归验证了排空及其他通道继续工作，未验证同一故障通道重新抓帧。

`bwait` 的条件是存在未完成事务且当前没有 B valid，不表示 AXI 被阻塞；它使用视频时钟域，不能直接除以 SoC 周期计算等待占比。当前结果保留为带宽改进及故障记录，稳定性和完整时序验收均未通过。
