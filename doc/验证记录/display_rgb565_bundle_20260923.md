# Display RGB565 分阶段验证记录（2026-09-23）

## 实现范围

- Canonical 640×480 RGB888 流保持为 AI Tensor 输入；Display 分支在写 DDR 前缩至 360×270，并转换为 RGB565。
- 每行存储 368 像素，其中末尾 8 像素补零；256-bit AXI 每拍 16 像素、每行 23 拍、行步长 736 B。
- 4 个 256 KiB slot/通道。16 路默认基址为 `0x08000000 + channel * 0x00100000`，占用连续 16 MiB。
- Mosaic 和单路全屏均从新 RGB565 帧读取；overlay 在 RGB888 恢复之后运行。Reader 租约延续到 overlay 最后一拍被接受。
- 单 4×4 Gemmini 的新软件 ELF 为 `sw/build/gemmini_single4_video_yolov5nu_rgb565.elf`；原单 4×4 ELF 未覆盖。

## 分阶段门禁

| 阶段 | 定向仿真 | 综合或展开 |
| --- | --- | --- |
| DISP-P0 | 旧视频回归 `VIDEO_REFACTOR_TESTS=PASS`，含 16 路旧 Mosaic、writer 完成与帧管理 | 旧 Reader 独立综合通过；该旧脚本使用接口默认宽度，仅作行为基线，不作 256-bit 资源对比 |
| DISP-P1 | 连续 3 帧 460800 个输入拍，得到 145800 个输出拍；覆盖输入间歇、输出背压、帧边界与丢弃尾部的错误传播 | `DISPLAY_SCALER_SYNTHESIS=PASS`，显式 48→32-bit 接口，92 LUT、136 FF、0 DSP |
| DISP-P2 | 8 行写出 184 个完整 AXI 拍、25 个写响应；覆盖 8 个 padding 像素、4 KiB burst 边界、AW/W 停顿与 B 后完成 | `DISPLAY_FRAME_DMA_SYNTHESIS=PASS`，显式 256-bit AXI/32-bit RGB565 接口 |
| DISP-P3 | 16 路 4×4 Mosaic 整帧 1036800 输出拍逐拍比对；缺失 CH7 为黑块；长 DDR 停顿触发 1 次 underflow，恢复后完整输出 | `MOSAIC_RGB565_SYNTHESIS=PASS`，184×256-bit 双行缓存综合为 4 个 RAMB36，770 LUT、684 FF、0 DSP |
| DISP-P4 | 单路全屏整帧逐拍比对；集成 Reader 连续切换 Mosaic→全屏两帧，验证 overlay 后才释放帧；overlay 原有框绘制测试和紧凑 4-slot 帧管理测试通过 | `DISPLAY_READER_COMPACT_SYNTHESIS=PASS`，两种 Reader 加 overlay；Vivado 顶层 `synth_design -rtl` 展开通过 |

综合使用 `xcvu13p-fhga2104-2-i` 和 Vivado 2023.2。独立综合顶层显式实例化真实 256-bit AXI 接口，避免将 `axi4_if` 的 64-bit 默认宽度误当作生产宽度。

顶层 RTL 展开为 0 errors，但已有 `video_memory_ports.sv` 多驱动和约束相关 critical warnings；本记录仅确认 Display 改动能在当前工程中展开，尚不是全系统综合、时序或布线签核。

## 软件与容量

`sw/src/hdmi_tx.c` 单独编译通过。新单 4×4 ELF 构建通过，SHA-256：`bf02be32c71f722b4d8775adee37dfcce39b783432bc3e642d7dfbd8fbf50fe2`。原 ELF SHA-256 仍为 `ae4ceb372e0c65b471bd0e17adf9a86e79bef29b01304eb73956d392a2c73df0`。

按 16 路、输入 30 FPS、1080p60 Mosaic 计算，Display DDR 理论写入约 95.4 MB/s、读取约 190.8 MB/s，合计约 286.2 MB/s。该数值是布局参数推算，尚未用板上 AXI 计数器实测。

## 后续门禁

- 保持 4 slot。DISP-P5 的 4→3 评估需要上板采集 drop、writer FIFO 峰值、reader underflow、AXI stall 和 frame age；当前没有实测依据。
- 本阶段未运行布局布线、未生成比特流、未上板。与已提交的 PCLK 阶段一起做最终时序和板测。
