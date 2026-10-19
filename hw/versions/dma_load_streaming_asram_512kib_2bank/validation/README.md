# 合并版功能仿真验收

状态：**MERGED_FUNCTIONAL_SIMULATION_PASS**。
主候选 `abd1c8c87558c7b0`；同源码、A1 关闭对照 `a07ef7954280e07b`。
完整身份、覆盖和待办见 [status.json](status.json)，严格汇总见
[simulation.json](simulation.json)。完整 SoC RTL 在忽略的
`build/experiments/dma_stream_asram/candidate_02/`，没有替换生产导出。

| 验证 | 实际结果 |
| --- | --- |
| RowAssembler | 全部 C=1～32、合法 P、N=1/2/3/31/32、半区裁剪/尾部/反压，共 2,975 项 |
| A1/关闭对照源单元 | DDR/local、三种优化模式、两种 C、晚到错误/终止信用等 72 项 |
| 地址规划 | 三块 SRAM、全部 64 个源偏移、容量末端/空洞/控制页/关闭配置，共 4,766 项；另保留原 DDR planner 单元 |
| ASRAM 存储 | 同一全容量 wrapper，行为模型及 Vivado 2023.2 URAM288_BASE 原语均通过；36 个边界、1,152 个 byte mask、双端口 |
| TL 控制器 | 每 bank 589 项，三个 bank 共 1,767 项；多 beat、credit、反压、错误、冲突及复位 |
| 三路真实 Gemmini + ASRAM | 四模式 × 六组参数 × 三路 × DDR/local/两种混合路由，共 288 项；真实 service TL 初始化和回读 |
| 首层 | DDR 和 local 各四模式 × 三路；真实 DIM32、FP16、SiLU；原始/折叠输出、矩阵、HOST/IRQ 隔离及写确认通过 |
| 代表层 | stage 0/2/4/5/8/10/59/132，四模式 × 三路，共 96 项；完整输出对照 legacy |
| 逻辑行/Get 闭合 | 96 组原始行流与物理 Get 预测闭合；返回字节为根据地址推导的值，不是外部 DDR 计量 |
| 晚到错误 | DDR 和 ASRAM 的 denied/corrupt，部分 SPAD 写后不发布 DONE，保持 fault/busy，协调复位后恢复 |
| MemoryMux | 全部 64 个 source、物理地址 bit32、source31 lease、multibeat 和反压 |
| Buffered 对照 | 四模式 × 三路 C3/N32/P6 无提前写；与主候选同工作负载的 Get 与实际 SPAD 写次数一致 |
| 配套软件 | 三 ELF 审计、四种完整归一化计划/阶段等价、20 个 host 测试及无板卡访问 preflight |
| 其他检查 | 源码/生成 RTL/工作区审计、prepare 拒绝路径、四项物理来源测试、功能证据负例、生产清单和 video/tensor/PPU/video-pipeline 回归 |

三路计算使用本候选生成的实际 Gemmini/Reader/Group/SPAD RTL，ASRAM 联合测试实例化
实际三块 ActivationSramTL 和未修改的 Xilinx 功能原语。测试地址选择/D 返回仲裁是
仿真连接，不等于执行整机 Rocket/Saturn。首层和八个代表层缩小空间尺寸，保留通道、
权重、原生 tiling、缩放与指令打包；不是整网 RTL 推理。

代表层用 `--memory-latency 1` 缩短测试 DDR 的返回等待；输入、权重、指令、比较
范围和实际 Get 工作量不变。独立的联合/源单元测试继续验证延迟末事务、返回反压和
fault。所有这些仿真周期都不作为 FPGA 性能结果。

主候选额外限制了 32 字节窗口内动态移位的表示位宽，避免父版本继承的超宽信号；
Group/RowAssembler 生成常量的最大位宽为 768/758。源单元采用原逐输入/反向重复写
模型作为独立期望，覆盖所有合法 C/P，正常数据语义保持。

完成记录归档在 [evidence/](evidence/)，包括原始模拟器输出、源单元、Get 闭合和
两个完整生成上下文。字节 SHA256 在 [archive_hashes.json](archive_hashes.json)。
原始 CSV trace、生成 RTL、ELF、工程及缓存仍在忽略的 build 输出；并未提交二进制。
中间候选和诊断运行不参与验收，见 [attempts.json](attempts.json)。

重验汇总（仓库根目录，原 build 输出仍存在时）：

```sh
python3 -B tests/model/dma_load/analyze_traces.py \
  build/experiments/dma_stream_asram/layers_03
python3 -B hw/versions/dma_load_streaming_asram_512kib_2bank/scripts/verify_simulation.py \
  --context build/experiments/dma_stream_asram/candidate_02/GENERATION_CONTEXT.json \
  --buffered-context build/experiments/dma_stream_asram/candidate_buffered_02/GENERATION_CONTEXT.json \
  --evidence-map build/experiments/dma_stream_asram/evidence_map.json \
  --output hw/versions/dma_load_streaming_asram_512kib_2bank/validation/simulation.json
```

尚未执行：本候选完整 CPU/RVV 指令启动、完整网络 RTL 推理、综合/布局布线、
bitstream、上板诊断、原始 Head/PAD 板测和长期稳定性。CPU/Saturn 完成链的十份 RTL
与已板测的 ASRAM 父版本逐字节相同，来源与回调证明保存在配套软件的 validation；
此事实不升级为本候选 CPU/RVV 执行通过。新时序和资源仍须实测。
