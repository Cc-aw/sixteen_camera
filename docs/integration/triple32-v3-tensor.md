# V3 Gemmini32 与专用 Tensor 写入口

新增硬件配置 `SOC_VARIANT=triple32_v3_tensor`，完整名称为
`TaihangSoC1Rocket1RVV3Gemmini32x32MemoryParallelV3TensorIngressConfig`。
本版从 Scala/Chisel 重新生成，组合开发工程的 Memory Parallel V3 与本仓库 TensorIngress。

## 硬件契约

| 项目 | 配置 |
| --- | --- |
| 计算 | 1 Rocket、1 RVV、3 个 Gemmini32，100 MHz |
| L2 | 两个 256 KiB bank，8 ways，512 sets，64B line |
| 银行选择 | A12；set bits 为 6–11、13–15 |
| MSHR | 每 bank 32 个普通请求及 2 个一致性请求 |
| SBUS / Gemmini DMA / Tensor AXI | 256 bit |
| L2 外侧 / SoC memory AXI / DDR S00 | 512 bit；S00 本地 ID 为 2 bit |
| DDR S00 | 32 read + 32 write outstanding，4 read/write threads |
| Head | 六个 1 MiB 槽，512-bit 存储、256-bit PPU 本地读取 |
| Tensor CSR | `0x02012000`，保留现有协议 |
| 内存统计 CSR | `0x02020000`，MPV3 ABI 1.1，14 个块 |

Tensor 收齐两拍数据后以 `PutFullData(size=6)` 写入 L2 上游。冷行整行覆盖
避免读取旧 DDR 内容。B 等待两拍 A 和 AccessAck 均完成；Tensor READY 不代表
DDR 已写回。保留现有独立 AW/W/B CDC 和共同复位协议。

Tensor client 的全局 TL source 范围为 512–543，全局 source 位宽因此为 10 bit。
原统计 block 0–12 不变，block 13 观测 Tensor 在双 bank L2 入口处的流量。
debug client 延续 V3 的统计边界，不计入客户端统计组。V4 实验未引入。

## 来源与生成

`tools/soc/shell/npu100_video/` 保存基础 Gemmini/Saturn/FPGA shell 和 RAM 推断脚本；
`memory_parallel_v3/` 保存 V3 配置及 Rocket/L2 覆盖；`reference/` 保存按原 V3
哈希恢复的 Rocket、Chipyard、L2 Scala 和构建输入。来源分别记录在
`IMPORT_MANIFEST.json`、`REFERENCE_MANIFEST.json` 和 `V3_EFFECTIVE_SCALA.sha256`。

统一入口顺序：新建私有工作区、恢复冻结依赖、基础 shell、V3 覆盖、Tensor 组合、
正常 SBT 编译、完整 elaboration、RAM 推断处理、结构检查和导出。
功能修改在 Scala/Chisel 中完成；RTL 后处理只使用原 V3 的 RAM 推断变换。
历史导入脚本保留来源，其旧目录布局不作为当前工程入口。

```bash
python3 tools/soc/build_triple32_v3_tensor.py \
  --reference /path/to/compatible/chipyard \
  --workspace /tmp/sixteen-camera-v3-tensor-chipyard
make check SOC_VARIANT=triple32_v3_tensor
```

其他构建依赖和工具由兼容 Chipyard 提供，所有源码修改和输出均在新工作区；
原参考树不修改。环境为 Chisel 6 / Scala 2.13.16、Java/SBT、firtool 和兼容缓存。
FPGA 使用 Vivado 2023.2。已有工作区可 `--resume`；更新 shell 源码后应准备新
工作区，`--resume` 不会覆盖安装新的 shell 源文件。

导出 `hw/soc/<完整配置名>/`，包括三个 worker 参数头、元数据及
`GENERATION_CONTEXT.json` 的有效源码和处理前后 RTL 哈希。同名旧导出移入
忽略的 `build/soc_backups/`。

## 工程和局部验证

```bash
make project SOC_VARIANT=triple32_v3_tensor
make test-memory-v3
make test-tensor test-ppu test-video test-software
python3 tests/rtl/run_memory_v3_tensor_cache_test.py \
  --workspace /tmp/sixteen-camera-v3-tensor-chipyard
python3 tools/soc/build_triple32_v3_tensor.py \
  --workspace /tmp/sixteen-camera-v3-tensor-chipyard --emit-core-only
python3 tests/rtl/run_tensor_ingress_tests.py \
  --core-dir build/sim/triple32_v3_tensor/core
python3 tools/check/run_triple32_v3_tensor_ooc.py \
  --output build/reports/triple32_v3_tensor_ooc
```

工程默认为独立的 `build/projects/triple32_v3_tensor/sixteen_camera.xpr`。
`make project` 只重建工程和 IP/BD 输出。已有不匹配的 DDR BD 会被拒绝。
V3 BD 使用被动 MIG Monitor，保留 512-bit CDC、outstanding 和 M00 register slice。

GUI 和命令行共用 `tools/build/triple32_v3/run_settings.tcl`：性能综合、retiming、
关闭资源共享、SHREG_MIN_SIZE=5、ExtraTimingOpt 布局、NoTimingRelaxation 与
TNS cleanup、前后 AggressiveExplore 和负 WNS 时追加优化。mesh DSP 保留
SLR0/1/3 放置和第三路前端软引导。配置切换会清理旧宏及 run 属性。

按用户要求，本次只做局部综合，不启动整机综合、布局布线或比特流生成。
OOC 的新输出目录保存各目标的真实依赖列表、DCP、资源、时序和 DRC；
可用 `--targets` 选择 TensorIngress、L2、SBUS、Head 和统计 CDC。
综合成功与时序达标分别记录，不代替布线后的整机时序。

缓存测试使用同一生成源码编译的真实双 bank InclusiveCache/CacheCork，覆盖冷行
整行写无旧 Get、两 bank 返回、三路请求与 Tensor 并发、CPU 脏行 probe、
Flush64、超过八路容量的脏行替换及 512-bit 外侧读回。
协议测试必须使用独立发射的 core，全 SoC 优化会移除仅用于测试的端口。

坏帧退役增加有效上下文检查并清除 ctx_bad，防止反复重装 flush 计时器。
扩展回归验证同一故障通道不复位即可重新准入和完成好帧。
匹配的 V17 A 固件已完成离线移植，使用 `make firmware SOC_VARIANT=triple32_v3_tensor`，
基准与验证见 [软件移植说明](triple32-v17a-software.md)。三路硬件需要对应 ABI 的固件。

本轮实际结果见 [局部综合与回归记录](../validation/triple32-v3-tensor.md)。
