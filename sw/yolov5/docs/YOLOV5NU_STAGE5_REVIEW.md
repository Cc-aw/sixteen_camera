# YOLOv5nu Stage 5 复盘

## 定位

Stage 5 处理 tensor lifetime、静态 arena、原地覆盖和 producer-direct write。它不改变模型数学、量化、检测头、Decode 或 NMS。

## 5A：生命周期分析和 arena 复用

根据实际生成的 call schedule 计算每个 tensor 的 birth 和 last-use，让生命周期不重叠的 tensor 共享一片 `activation_arena[]`。

同时检查 live interval、offset/size 边界、32 元素对齐、Gemmini/DMA 地址对齐和 alias root。

```text
arena：819,200 bytes
ELF BSS：905,012 bytes
```

## 5B：删除死 tensor 和安全 Reshape view

删除 79 个不活跃 tensor 符号，并尝试把不改变物理顺序的 Reshape 变为 view。当前 location-major 检测头已经消除了安全独立 Reshape buffer，因此 `reshape_views=0`。5A/5B 的 arena 和 BSS 相同；5B 主要完成符号清理。

## 5C：SiLU/Add 原地覆盖

当输入在节点后不再使用且尺寸兼容时，允许：

```c
silu_lut_i8(tensor, tensor, ...);
add_ratio_i8(a, b, a, ...);
```

5C 覆盖 69 个 SiLU 和 7 个 Add，减少中间 buffer 写回和读取。

## 5D：producer 直接写入 Concat slice

对单消费者、scale/stride/生命周期安全的 producer，直接写入最终 Concat channel slice。当前实现 8 条 SiLU direct-Concat 和 1 条 Add direct-Concat，共 9 条。

## 涉及文件

- `generators/gemmini/software/gemmini-rocc-tests/imagenet/generate_yolov5nu_baremetal.py`
- `scripts/xcvu13p_build_yolov5nu_uart_baremetal.sh`
- `scripts/yolov5nu_validate_memory_plan.py`
- `scripts/yolov5nu_stage5_memory.py`
- `generators/gemmini/software/gemmini-rocc-tests/bareMetalC/yolov5nu_stage41_rvv_smoke.c`
- `scripts/xcvu13p_build_yolov5nu_stage41_rvv_smoke.sh`

归档：`fpga/xcvu13p/tests/yolov5nu_stage5_memory/`。

## 内存和性能

| 版本 | Arena | ELF BSS |
|---|---:|---:|
| 5A | 819,200 B | 905,012 B |
| 5B | 819,200 B | 905,012 B |
| 5C | 835,200 B | 921,012 B |
| 5D | 835,200 B | 921,012 B |

相对 Stage 4.1 的 `9,526,228 B`，5D BSS 降低约 `90.33%`。

image025 的 5C graph 为 `60.195M cycles`，5D 为 `60.488M cycles`。5C 在 scalar SiLU 下略快；5D 的 strided SiLU 写入抵消了部分 Concat copy 节省，但它保留了更适合后续硬件融合的目标布局。

五图 Stage 5D 平均：

```text
Graph：60.483M cycles
端到端：约 1.2191 s @ 50 MHz
吞吐率：0.8203 FPS
Fused SiLU：36.638M cycles
Concat：2.540M cycles
```

所有 Stage 5A-D smoke 和 Stage 5D 五图 FPGA 双跑均为 `398` records、`PASS`、zero exit 和 bit-exact。

## 5D 之后的硬件 SiLU 扩展

基于 5D 又建立了 Gemmini 动态 SiLU LUT V1：

- activation code：`SILU_LUT=6`
- RoCC funct：`CONFIG_SILU_LUT=26`
- 256x8-bit active LUT
- 每条命令写 8 项，每层 32 条命令
- 在 accumulator scale、RNE、int8 clip 后查询
- LoopConv 将 activation code 传到 mvout

相关 RTL 文件包括：

- `generators/gemmini/src/main/scala/gemmini/Activation.scala`
- `GemminiISA.scala`
- `AccumulatorScale.scala`
- `Scratchpad.scala`
- `StoreController.scala`
- `ReservationStation.scala`
- `Controller.scala`

软件入口包括：

- `generators/gemmini/software/gemmini-rocc-tests/include/gemmini.h`
- `.../silu_lut_store.c`
- `.../silu_lut_loop_conv.c`
- `.../silu_lut_yolov5nu.c`
- `scripts/yolov5nu_gemmini_silu_lut.py`

69 张真实 LUT 的 `17,664/17,664` 穷举、store/mvout、LoopConv、Spike、Verilator 和 FPGA image025 均通过。SiLU 从约 `36.216M` 降至约 `0.181M cycles`，整图达到约 `20.789M cycles / 2.353 FPS`。

这一硬件扩展属于 5D 之后的独立 RTL candidate，不覆盖原 5D 软件 baseline。
