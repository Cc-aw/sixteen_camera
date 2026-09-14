# YOLOv5nu Stage 1 复盘

## 定位

Stage 1 是基于 Stage 0 的 layout-only 候选，目标是将中间 feature map 改为 NHWC 常驻，减少 Gemmini Conv 前后的 NCHW/NHWC 转换。

## 核心改动

ONNX 仍保持标准 NCHW 逻辑语义，只有 AOT backend 改变物理存储布局：

```text
输入离线 CHW -> HWC 打包
    -> 75 个 Conv 直接消费/产生 NHWC
    -> NHWC Sigmoid/Mul/Add/Concat/MaxPool/Resize
    -> 6 个检测头 NHWC -> NCL 边界
    -> 原有 DFL、Decode、NMS
```

静态 contract：

```text
直接 NHWC Conv：75
保留 bridge 的 DFL Conv：1
检测头 reorder：6
NHWC feature Concat：13
profile records：482
```

`/model.24/dfl/conv/Conv` 保留 bridge，因为 DFL 仍使用原逻辑布局。

## 涉及文件

- `scripts/yolov5nu_graph_parser.py`：增加 `nhwc_resident` 物理布局描述。
- `generators/gemmini/software/gemmini-rocc-tests/imagenet/generate_yolov5nu_baremetal.py`：增加 `--physical-layout nchw-bridge|nhwc`。
- `scripts/xcvu13p_build_yolov5nu_uart_baremetal.sh`：传递 `YOLOV5NU_PHYSICAL_LAYOUT`。
- `scripts/yolov5nu_validate_nhwc_layout.py`：验证布局边界和随机 Concat/Reshape/Resize/MaxPool 索引。
- `scripts/yolov5nu_stage1_nhwc.py`：构建五图 ELF、检查 UART 双跑并对照 Stage 0。

归档：`fpga/xcvu13p/tests/yolov5nu_stage1_nhwc/`。

## 验证

随机 NHWC Concat、NHWC-to-NCL Reshape、nearest Resize 和 SAME MaxPool 索引全部通过。五个 RV64GCV ELF 在 FPGA 上各运行两次，全部为 `482` records、`PASS`、zero exit，并与 Stage 0 的 final tensor、Top-10、NMS bit-exact。

## 性能

五图平均：

```text
Stage 0 graph：429,906,990 cycles
Stage 1 graph：356,624,734 cycles
graph 加速：  1.2055x

Stage 0 端到端：8,656.866 ms
Stage 1 端到端：7,191.218 ms
端到端加速：  1.2038x
吞吐率：      0.1391 FPS
```

Conv layout cycles 从约 `95.51M` 降至约 `1.12M`，但部分开销转移到检测头 Reshape，Stage 1 后的新热点是 Mul、Sigmoid 和 Concat。

## 结论

Stage 1 证明了 NHWC 常驻布局正确且有效，作为后续 Stage 2 SiLU、Stage 3 RVV kernel 和检测头 lowering 的基础。

