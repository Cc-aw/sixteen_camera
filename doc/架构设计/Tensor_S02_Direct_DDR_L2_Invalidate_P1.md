# Tensor S02 Direct DDR + L2 Invalidate 实施方案

## 1. 目标

当前 Tensor 写入路径经过 FBus / L2，板上写带宽约为 **170 MB/s**，无法满足 16 路 640×480@30 FPS 的输入需求。

单帧 YOLOv5nu 输入 Tensor：

```text
640 × 480 × 3 INT8
= 921600 B
```

16 路 × 30 FPS 所需持续写带宽：

```text
921600 × 480
≈ 442 MB/s
```

本阶段目标：

- Tensor 写入不再经过 FBus/L2；
- Tensor DMA 直接通过 DDR `S02_AXI` 写入 DDR；
- Gemmini 读取 Tensor 时仍保持原来的 **Gemmini → L2 → DDR** 路径；
- 使用 InclusiveCache 原生 `Invalidate64` 清除 Tensor Slot 在 L2 中的旧副本；
- 保持 Gemmini 第一层和整图性能，不接受 bypass L2 带来的性能下降。

---

## 2. 新架构

```text
                 Video Domain ~150 MHz

16 路视频
   │
   ▼
Tensor Packer
   │
   ▼
Shared Tensor DMA
   │
   ▼
AXI Write CDC
150 MHz → 300 MHz
   │
   ▼
DDR S02_AXI
   │
   ▼
Tensor Slot Pool
   │
   ├──────── write_done ──────────┐
   │                              │
   └──── L2 Invalidate old data ──┤
                                  ▼
                                READY
                                  │
                                  ▼
                         Gemmini0/1/2
                                  │
                                  ▼
                         InclusiveCache L2
                                  │
                                  ▼
                                 DDR
```

核心原则：

> **Tensor Producer 绕过 L2，Gemmini Consumer 保留 L2。**

---

## 3. 为什么这样设计

Gemmini 已有板测结果：

```text
正常经过 L2：
平均卷积约 1400 万 cycles

全程 bypass L2：
平均卷积约 2100 万 cycles

仅第一层 bypass：
额外增加约 200 万 cycles
```

因此不能让 Gemmini Tensor Load 绕过 L2。

问题只在于：

```text
S02 写 DDR
```

不会通知 InclusiveCache。

如果 L2 中还保存上一代 Tensor Slot 的 cache line，Gemmini 可能读到旧数据。

所以必须在 Slot 重用时执行：

```text
L2 Invalidate
```

---

## 4. 核心修改一：Tensor Writer 改走 S02

当前：

```text
Tensor DMA
→ tensor_memory_bridge
→ FBus
→ L2
→ S00
→ DDR
```

修改为：

```text
Tensor DMA
→ axi4_ui_write_cdc
→ S02_AXI
→ DDR
```

直接复用已有：

```text
rtl/bus/axi4_ui_write_cdc.sv
```

完成：

```text
video_clk ~150 MHz
→
ddr_ui_clk ~300 MHz
```

CDC。

`ddr_platform.sv` 中当前绑零的 `S02_AXI` 改为连接 Tensor AXI。

---

## 5. 核心修改二：恢复长 Burst

当前 Tensor DMA 为适配 FBus：

```text
BASE_BURST_BEATS = 2
HIGH_BURST_BEATS = 2
MAX_BURST_BEATS  = 2
```

即每 burst 仅：

```text
2 × 32 B = 64 B
```

切到 S02 后改为 DDR 友好的长 burst。

建议初始参数：

```text
BASE_BURST_BEATS = 32
HIGH_BURST_BEATS = 64
MAX_BURST_BEATS  = 64
```

即：

```text
1 KiB / 2 KiB burst
```

现有 DMA 已支持：

- 4 KiB AXI boundary；
- remaining bytes；
- FIFO available；
- descriptor scheduling。

不需要重写调度器。

---

## 6. 核心修改三：增加 Tensor L2 Invalidate Engine

新增：

```text
rtl/ai/tensor/tensor_l2_invalidate_engine.sv
```

InclusiveCache 已经提供原生控制寄存器：

```text
L2 Control Base : 0x02010000
Flush64         : 0x02010200
Invalidate64    : 0x02010280
```

Tensor 使用：

```text
Invalidate64
```

而不是 Flush。

原因：

```text
Video DMA = Tensor 唯一 Writer
Gemmini   = Tensor Read-only Consumer
CPU/RVV   = Production Path 不修改 Tensor Payload
```

因此旧 Tensor cache line 应当是 clean line，只需要丢弃旧副本。

### 第一版实现

单帧 Tensor：

```text
921600 B
```

64 B cache line：

```text
921600 / 64 = 14400 lines
```

Invalidate Engine：

```text
IDLE
 ↓
发送 Invalidate64(slot_base)
 ↓
等待 completion
 ↓
addr += 64
 ↓
重复 14400 次
 ↓
DONE
```

第一版不修改 InclusiveCache / Directory 内部实现。

---

## 7. 核心修改四：修改 Tensor Slot Publication

原来：

```text
最后一个 AXI B 成功
        ↓
      READY
```

修改为：

```text
        write_done
            &&
      invalidate_done
            &&
        no_error
            ↓
          READY
```

即：

```text
READY = DDR 新 Tensor 已完整写入
        +
        L2 中旧 Tensor 副本已失效
```

此后 Gemmini 才允许消费这个 Slot。

---

## 8. Invalidate 与 S02 写并行

不要串行执行：

```text
S02 写完
→ invalidate
→ READY
```

推荐：

```text
旧 Slot 被 Gemmini 释放
          │
     ┌────┴────┐
     │         │
     ▼         ▼
L2 Invalidate  S02 写下一帧
     │         │
     ▼         ▼
 inv_done   write_done
     │         │
     └────┬────┘
          ▼
        READY
```

因为：

- Gemmini 已不再访问该 Slot；
- S02 写不会创建新的 L2 entry；
- CPU/RVV 不访问生产 Tensor payload。

因此二者可以安全并行。

---

## 9. Tensor Slot 生命周期

建议统一为：

```text
FREE
 ↓
WRITING / INVALIDATING
 ↓
WAIT_PUBLICATION
 ↓
READY
 ↓
GEMMINI_READING
 ↓
RECLAIM
 ↓
FREE
```

逻辑上需要记录：

```text
write_done
invalidate_done
write_error
invalidate_error
generation/version
```

Slot 只有在两条路径都完成后才能发布。

---

## 10. FBus 后续用途

Tensor bulk payload 改走 S02 后，FBus 不删除。

FBus 继续承担：

```text
PPU Head Flush64
Tensor Invalidate64
诊断
其他 coherent control transaction
```

即：

```text
FBus 从“大数据搬运路径”
变成
“Cache Control / Coherent Control 路径”
```

---

## 11. 第一阶段不修改的内容

本阶段不修改：

```text
3×Gemmini64
Gemmini DMA 正常 L2 路径
Rocket
RVV
InclusiveCache 内部 Directory/MSHR
PPU 算法
Head Slot
YOLOv5nu Graph
```

尤其不能改成 Gemmini bypass L2。

---

## 12. 建议增加的性能计数

Tensor DMA：

```text
tensor_write_cycles
tensor_write_bytes
tensor_write_MBps
AW stall
W stall
B wait
outstanding max
```

Invalidate：

```text
invalidate_cycles
invalidate_lines
invalidate_error
```

Publication：

```text
tensor_publication_cycles
```

定义：

```text
publication_cycles
=
Slot 开始写
→ write_done && invalidate_done
```

---

## 13. 验收标准

### 正确性

必须满足：

```text
Tensor CRC 正确
Slot A/B 重复复用无 stale
Gemmini 推理结果正确
AXI response error = 0
Invalidate error = 0
```

建议至少连续：

```text
1000+ Slot reuse
```

无错误。

### Tensor 写带宽

生产最低要求：

```text
> 442 MB/s
```

建议至少达到：

```text
550~600 MB/s+
```

留出系统竞争余量。

### Gemmini 性能

必须保持：

```text
第一层继续通过 L2
整图继续通过 L2
```

不能再次出现：

```text
第一层 bypass +约 200 万 cycles
```

的性能损失。

### 系统

同时检查：

```text
Display underflow = 0
Tensor overflow = 0
Tensor AXI error = 0
Gemmini error = 0
```

---

## 14. 实施顺序

```text
P1.1
Tensor DMA → S02_AXI

P1.2
Tensor burst 2 → 32/64 beats

P1.3
实现 tensor_l2_invalidate_engine
调用 InclusiveCache Invalidate64

P1.4
Slot READY 改为：
write_done && invalidate_done

P1.5
仿真 stale-cache / slot reuse

P1.6
上板跑真实 YOLOv5nu
检查 Tensor 带宽、第一层 cycles、整图 cycles
```

---

## 15. 最终目标

第一阶段完成后的生产路径：

```text
Video
 ↓
Tensor Packer
 ↓
Tensor DMA
 ↓
S02 Direct DDR Write
 ↓
Tensor Slot
 ↓
L2 Invalidate Publication
 ↓
READY
 ↓
3×Gemmini64
 ↓
InclusiveCache L2
 ↓
DDR
```

该方案同时解决：

```text
FBus Tensor 写带宽不足
+
Gemmini bypass L2 性能严重下降
```

最终形成：

> **S02 负责高带宽 Tensor 写入，InclusiveCache 保留为 Gemmini 的高性能读缓存，Tensor Slot 在 generation/reuse 边界通过显式 Invalidate 保证一致性。**
