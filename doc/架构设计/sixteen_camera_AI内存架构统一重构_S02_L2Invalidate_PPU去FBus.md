# sixteen_camera：统一 AI 内存架构重构方案
## Tensor S02 Direct DDR + L2 Invalidate + PPU Local Reader + FBus 移除

**项目：** `Cc-aw/sixteen_camera`  
**目标平台：** Xilinx VU13P  
**当前 SoC：** 1×Rocket + 1×Saturn RVV + 3×Gemmini64，100 MHz  
**目标：** 在不牺牲 Gemmini L2 性能的前提下，提高 Tensor 写入带宽、简化 PPU 数据路径，并最终删除外部 FBus 以降低互连复杂度和时序压力。

---

# 1. 背景

当前系统已经进入 3×Gemmini64 @100 MHz 阶段。

现有关键性能结论：

```text
Tensor 经 FBus 写入 DDR：
≈ 170 MB/s

16 × 640×480 × 30 FPS Tensor 写入需求：
≈ 442 MB/s

Gemmini 正常经过 L2：
平均卷积 ≈ 1400 万 cycles

Gemmini 全部绕过 L2：
平均卷积 ≈ 2100 万 cycles

仅第一层绕过 L2：
额外增加 ≈ 200 万 cycles
```

因此可以明确得到两个结论：

1. **Tensor bulk write 不能继续依赖 FBus。**
2. **Gemmini DMA 不能绕过 L2。**

新的架构必须同时满足：

```text
Tensor Producer 高带宽写 DDR
+
Gemmini Consumer 保留 InclusiveCache L2
```

---

# 2. 当前架构问题

当前 AI 数据面可以概括为：

```text
Video
  │
  ▼
Tensor Packer
  │
  ▼
Tensor DMA
  │
  ▼
FBus
  │
  ▼
SoC coherent fabric / L2
  │
  ▼
DDR
```

PPU 部分：

```text
Gemmini Head
    │
    ▼
L2
    │
    ├── Flush64 publication
    ▼
Head URAM
    │
    ▼
PPU Local Reader
```

但是当前 SoC 仍然保留完整 FBus：

```text
External 256-bit AXI FBus
  │
  ├── Tensor bulk write
  ├── PPU/FBus diagnostic read
  ├── Head Flush64
  └── 未来 Tensor Invalidate64
```

这条 FBus 带来的额外结构包括：

```text
AXI4IdIndexer
AXI4Fragmenter
AXI4UserYanker
AXI4ToTL
TLFIFOFixer
FrontBus
宽 AXI routing
ID / outstanding bookkeeping
```

对 VU13P 多 SLR 布局来说，这些逻辑不仅占资源，也增加宽总线布线、互连 fan-in 与时序复杂度。

---

# 3. 目标统一架构

最终目标不是“优化 FBus”，而是让 FBus 从生产数据面彻底退出。

```text
                       ┌─────────────────────┐
                       │      Rocket/RVV     │
                       └──────────┬──────────┘
                                  │
                                  ▼
                           InclusiveCache
                              L2 512 KiB
                                  │
                                  ▼
                                MBUS
                                  │
                                  ▼
                                 S00
                                  │
                                  ▼
                                 DDR
                                  ▲
                                  │
              ┌───────────────────┴───────────────────┐
              │                                       │
        Tensor S02 Write                        Normal SoC memory
              │
Video → Tensor DMA → S02
              │
              ▼
        Tensor Slot Pool

3×Gemmini64:
Tensor Slot → InclusiveCache → DDR

PPU:
Head URAM → Local Reader → PPU

Cache Maintenance:
Head Flush64 ───────┐
                    ├── Cache Maintenance Port → InclusiveCache
Tensor Invalidate ──┘
```

核心设计思想：

> **Bulk Data 与 Cache Control 分离。**

---

# 4. 新架构职责划分

## 4.1 S00

保留：

```text
Rocket
RVV
3×Gemmini
InclusiveCache
MBUS
```

正常系统访存。

Gemmini 保持原有：

```text
Gemmini → InclusiveCache → DDR
```

不得改成全局 bypass。

## 4.2 S01

继续承担视频显示相关 DDR 流量：

```text
Framebuffer Writer
Display Reader
```

## 4.3 S02

从当前空闲状态改为：

> **AI Tensor 专用高带宽 DDR Write Port**

数据流：

```text
Video 150 MHz
   │
   ▼
Tensor Packer
   │
   ▼
Tensor DMA
   │
   ▼
axi4_ui_write_cdc
150 MHz → 300 MHz
   │
   ▼
S02_AXI
   │
   ▼
DDR
```

Tensor bulk payload 不再进入 SoC FBus。

---

# 5. Tensor 写入路径修改

当前：

```text
Tensor DMA
→ tensor_memory_bridge
→ axi4_write_cdc
→ FBus
→ L2
→ S00
→ DDR
```

修改为：

```text
Tensor DMA
→ axi4_ui_write_cdc
→ S02
→ DDR
```

直接复用：

```text
rtl/bus/axi4_ui_write_cdc.sv
```

完成：

```text
video_clk ≈150 MHz
→
ddr_ui_clk ≈300 MHz
```

CDC。

`ddr_platform.sv` 当前绑零的 `S02_AXI` 改为连接真实 Tensor AXI。

---

# 6. Tensor Burst 恢复为 DDR 友好模式

当前 FBus 模式：

```text
BASE_BURST_BEATS = 2
HIGH_BURST_BEATS = 2
MAX_BURST_BEATS  = 2
```

原因：

```text
2 × 32 B = 64 B
```

正好对应 L2 cache line。

改走 S02 后，应恢复长 burst。

建议初始配置：

```text
BASE_BURST_BEATS = 32
HIGH_BURST_BEATS = 64
MAX_BURST_BEATS  = 64
```

即：

```text
1 KiB / 2 KiB burst
```

现有 Tensor DMA 已经支持 4 KiB AXI boundary、descriptor、FIFO available、remaining beats 和 outstanding accounting，因此无需重写 DMA scheduler。

---

# 7. 为什么 S02 写后必须处理 L2

S02 位于 SoC coherent fabric 之外。

因此：

```text
S02 → DDR
```

不会通知 InclusiveCache。

例如：

```text
Frame N:
Gemmini 读取 Tensor Slot A
→ 部分 cache line 留在 L2

Frame N+X:
S02 重新写 Slot A
→ DDR 已更新
→ L2 仍可能保留旧 Tensor
```

随后 Gemmini：

```text
Gemmini → L2 hit
→ 读到旧数据
```

所以必须建立明确的 Tensor publication boundary。

---

# 8. InclusiveCache 已有能力

当前 SoC 已经实现 Rocket-Chip InclusiveCache。

L2 参数：

```text
容量：512 KiB
Ways：8
Sets：1024
Cache line：64 B
```

现有 Cache Control：

```text
Base          0x02010000
Flush64       0x02010200
Flush32       0x02010240
Invalidate64  0x02010280
Invalidate32  0x020102c0
```

因此第一阶段无需修改 `Directory.scala`、`MSHR.scala`、`Scheduler.scala`，可直接复用已有 `Invalidate64`。

---

# 9. Tensor L2 Invalidate Engine

新增：

```text
rtl/ai/tensor/tensor_l2_invalidate_engine.sv
```

第一版工作方式：

```text
slot_base
   │
   ▼
Invalidate64(base + 0)
   │
wait completion
   │
Invalidate64(base + 64)
   │
wait completion
   │
...
```

单帧：

```text
921600 B
```

64 B cache line：

```text
921600 / 64
= 14400 lines
```

Tensor Input 是：

```text
Video DMA = 唯一 writer
Gemmini   = read-only consumer
CPU/RVV   = production path 不修改 payload
```

所以 Tensor Slot 中驻留的 L2 line 理论上应为 clean line，因此这里必须使用 `Invalidate`，而不是 `Flush`。

---

# 10. Tensor Slot Publication

当前 Slot READY：

```text
最后一笔 AXI B 成功
→ READY
```

修改为：

```text
write_done
&&
invalidate_done
&&
!write_error
&&
!invalidate_error
→ READY
```

定义：

```text
READY = DDR 新 Tensor 已完整写入
        +
        L2 中旧 Tensor 副本已清除
```

只有 READY 后才允许 Gemmini 使用。

---

# 11. Invalidate 与 S02 写并行

不要串行：

```text
S02 write
→ invalidate
→ READY
```

应并行：

```text
旧 Slot 被 Gemmini release
            │
      ┌─────┴─────┐
      │           │
      ▼           ▼
L2 Invalidate   S02 Write
      │           │
      ▼           ▼
 inv_done      write_done
      │           │
      └─────┬─────┘
            ▼
          READY
```

安全前提：

1. Gemmini 已经 release 旧 Slot；
2. CPU/RVV production path 不访问 Tensor payload；
3. S02 写不会创建新的 L2 cache entry。

---

# 12. Tensor Slot 生命周期

建议逻辑生命周期：

```text
FREE
 ↓
RECLAIM
 ↓
WRITING + INVALIDATING
 ↓
WAIT_PUBLICATION
 ↓
READY
 ↓
GEMMINI_READING
 ↓
RELEASE
 ↓
FREE
```

每个 Slot 至少记录：

```text
write_done
invalidate_done
write_error
invalidate_error
frame_id
version
generation
```

---

# 13. PPU 数据路径去 FBus

当前 PPU production 已默认使用：

```text
Head URAM Local Reader
```

而不是 FBus reader。

生产路径应固定为：

```text
Head URAM
→ head_local_reader
→ PPU
```

下一阶段删除 production FBus read fallback，包括：

```text
fbus_read_engine
Local/FBus runtime source switch
FBus Head read fallback
```

---

# 14. PPU Head Publication

当前 Head publication：

```text
Gemmini Head
   │
   ▼
L2 dirty lines
   │
   ▼
ppu_cache_publish_engine
   │
   ▼
FBus
   │
   ▼
InclusiveCache Flush64
   │
   ▼
Head URAM Router
```

PPU 使用 FBus 不是为了传 Head payload，而只是为了发送：

```text
Flush64(address)
```

这种 cache-control command。

因此可以用专用 Cache Maintenance Port 替代整个 FBus。

---

# 15. Cache Maintenance Port

目标新增一个极窄的 SoC sideband：

```text
cache_maint_valid
cache_maint_ready

cache_maint_op
cache_maint_addr[32:0]

cache_maint_done
cache_maint_error
```

操作定义：

```text
OP_FLUSH      = 0
OP_INVALIDATE = 1
```

使用者：

```text
Head Publication Engine
→ FLUSH

Tensor Invalidate Engine
→ INVALIDATE
```

---

# 16. Cache Maintenance Arbiter

建议统一结构：

```text
Head Flush Engine ───────┐
                         │
                         ▼
                  Cache Maint Arbiter
                         │
                         ▼
                Cache Maintenance Port
                         │
                         ▼
                  InclusiveCache

Tensor Invalidate Engine ┘
```

内部 request：

```text
valid
op
addr
```

response：

```text
done
error
```

---

# 17. Cache Maintenance Port 与 InclusiveCache 的连接

当前 InclusiveCache 内部已经存在：

```text
io_req_valid
io_req_ready
io_req_bits_address
io_req_bits_invalidate
io_resp_valid
```

这与目标 sideband 几乎完全一致。

推荐做法：

```text
Current MMIO Flush/Invalidate ──┐
                                ▼
                         Small Arbiter
                                ▲
External Cache Maint Port ──────┘
                                │
                                ▼
                  InclusiveCacheBankScheduler
```

不需要重写 L2，只需要给当前 cache-maintenance request source 增加第二个入口。

---

# 18. PPU Flush Engine 简化

当前：

```text
AW
→ W
→ B
→ next line
```

以后：

```text
REQUEST(addr, FLUSH)
→ wait done
→ next line
```

状态机可从：

```text
IDLE
AW
W
B
NEXT
```

简化为：

```text
IDLE
REQUEST
WAIT_DONE
NEXT
```

Tensor Invalidate Engine 使用同样接口。

---

# 19. 为什么最终可以删除 FBus

新架构完成后，各生产流量已经全部有明确去向：

```text
Tensor bulk write
→ S02

Gemmini memory traffic
→ InclusiveCache / S00

PPU Head read
→ URAM Local Reader

Head Flush
→ Cache Maintenance Port

Tensor Invalidate
→ Cache Maintenance Port
```

此时已经没有 production path 需要 FBus。

---

# 20. 删除 FBus 后可删除的 SoC 结构

当前配置中的：

```text
WithMergedVideoFrontBus
WithCustomSlavePort(
    data_width = 256,
    id_bits = 5,
    source_bits = 7,
    fifo_bits = 5
)
```

最终可从 production SoC 移除。

对应生成 RTL 中以下逻辑也可退出：

```text
AXI4IdIndexer
AXI4Fragmenter
AXI4UserYanker
AXI4ToTL
TLFIFOFixer
TLInterconnectCoupler_fbus_*
```

前提是确认这些实例只服务该外部 FBus。

---

# 21. 视频工程可清理模块

可删除或从 production manifest 退出：

```text
tensor_memory_bridge.sv
```

原 FBus Tensor bulk write 逻辑。

PPU 可删除：

```text
fbus_read_engine
```

以及：

```text
Local/FBus runtime source switch
```

生产 PPU 固定 Local Reader。

如果 `axi4_channel_join` 只用于 FBus read/write 合并，也可删除。

原：

```text
ppu_publication_write_mux
```

替换为：

```text
cache_maint_arbiter
```

---

# 22. `postprocess_memory_bridge` 目标简化

当前：

```text
postprocess_memory_bridge
├── Head Publication Manager
├── PPU Cache Publish AXI Engine
├── Publication AXI Mux
├── FBus Reader
├── Local Reader
├── Head URAM Router
└── FBus Channel Join
```

最终：

```text
postprocess_memory_bridge
├── Head Publication Manager
├── Head Flush Engine
├── Local Reader
├── Head URAM Router
└── Cache Maint Request
```

---

# 23. 目标整体架构

```text
                    ┌──────────────────────────┐
                    │       Rocket / RVV       │
                    └────────────┬─────────────┘
                                 │
            ┌────────────────────┼────────────────────┐
            │                    │                    │
            ▼                    ▼                    ▼
       Gemmini0             Gemmini1             Gemmini2
            │                    │                    │
            └────────────────────┼────────────────────┘
                                 ▼
                          InclusiveCache
                            L2 512 KiB
                                 │
                                 ▼
                                MBUS
                                 │
                                 ▼
                                S00
                                 │
                                 ▼
                                DDR
                                 ▲
                                 │
                             S02 Tensor
                                 ▲
                                 │
Video → Tensor Packer → Tensor DMA

Head:
Gemmini → L2 → Flush → Head URAM → PPU

Cache Maintenance:
Head Flush Engine ────────┐
                          ├→ Cache Maint Port → InclusiveCache
Tensor Invalidate Engine ─┘
```

---

# 24. 分阶段实施

## Phase A：Tensor S02 + Invalidate

完成：

```text
Tensor DMA → S02
长 burst
Tensor L2 Invalidate Engine
write_done && invalidate_done → READY
```

此阶段暂时允许 Cache Invalidate command 继续借现有 FBus。

目标：

```text
Tensor write > 442 MB/s
Gemmini 第一层保持 L2 性能
无 stale Tensor
```

## Phase B：PPU 固定 Local Reader

删除 production：

```text
fbus_read_engine
Local/FBus source switch
FBus Head read fallback
```

保留：

```text
Head URAM Local Reader
```

验证：

```text
3 workers
6 Head Slots
PPU bit-exact
Result/Overlay 正确
```

## Phase C：Cache Maintenance Sideband

新增：

```text
cache_maint_valid
cache_maint_op
cache_maint_addr
cache_maint_ready
cache_maint_done
```

先迁移：

```text
Head Flush64
```

再迁移：

```text
Tensor Invalidate64
```

验证 cache-control 结果与现有 MMIO/FBus 路径完全一致。

## Phase D：删除 FBus

确认：

```text
Tensor 不再使用 FBus
PPU read 不再使用 FBus
Cache control 不再使用 FBus
```

然后删除：

```text
external FBus AXI
WithCustomSlavePort
WithMergedVideoFrontBus
FBus channel join
FBus reader
Tensor FBus bridge
相关 diagnostics
```

重新生成 3×Gemmini64 SoC RTL。

---

# 25. 必须保持的不变量

## Tensor

```text
Video DMA = 唯一 producer
Gemmini = read-only consumer
CPU/RVV 不修改 production Tensor payload
```

## Head

```text
Gemmini = producer
Head URAM = backing store
PPU = consumer
READY 前 PPU 禁止读取
```

## Gemmini

必须继续：

```text
Gemmini → InclusiveCache → DDR
```

不允许为了简化一致性而全局 bypass L2。

## Display

本次 AI 内存重构不能造成：

```text
HDMI underflow
Display frame corruption
视频写入 starvation
```

---

# 26. 性能计数

Tensor：

```text
tensor_write_cycles
tensor_write_bytes
tensor_MBps
tensor_aw_stall
tensor_w_stall
tensor_b_wait
tensor_outstanding_max
```

Invalidate：

```text
invalidate_cycles
invalidate_lines
invalidate_errors
```

Head Flush：

```text
flush_cycles
flush_lines
flush_errors
```

总体：

```text
tensor_publication_cycles
graph_cycles
first_layer_cycles
ppu_cycles
graph_to_overlay_cycles
```

---

# 27. 验收标准

## Tensor

```text
写带宽 > 442 MB/s
建议生产目标 ≥ 550~600 MB/s
```

## 一致性

```text
1000+ Slot reuse
无 stale Tensor
无 CRC 错误
无 generation 错配
```

## Gemmini

要求：

```text
第一层 cycles 接近原 L2 baseline
整图 cycles 接近原 L2 baseline
```

不能出现：

```text
第一层 bypass +约 200 万 cycles
```

## PPU

要求：

```text
Head Local Reader only
bit-exact
3 worker / 6 slot 全通过
```

## Cache Maintenance

要求：

```text
Flush64 正确
Invalidate64 正确
request/response 无丢失
无重复 completion
abort/reset 无死锁
```

## 系统

要求：

```text
Display underflow = 0
Tensor overflow = 0
AXI error = 0
Gemmini error = 0
PPU error = 0
```

---

# 28. 时序目标

删除 FBus 后重点比较：

```text
WNS
TNS
L2 setup endpoints
SBus/L2 routing congestion
跨 SLR 宽总线数量
LUT/FF
AXI/TL adapter 数量
```

预期收益主要来自：

```text
减少 256-bit external FBus routing
减少 AXI→TL adapter
减少 FBus ID / ordering logic
减少 SBus/L2 ingress fan-in
```

但不能预设：

```text
L2 Directory 内部最差路径一定自动消失
```

最终必须以 full place/route report 为准。

---

# 29. 推荐 Git 提交拆分

```text
feat(tensor): route production tensor writes through DDR S02
perf(tensor): enable long DDR bursts for tensor DMA
feat(cache): add tensor slot invalidate engine
refactor(tensor): publish slots after write and invalidate completion

refactor(ppu): remove production fbus reader fallback
refactor(ppu): make local head reader the only production source

feat(cache): add dedicated cache maintenance sideband
refactor(cache): move head flush to cache maintenance port
refactor(cache): move tensor invalidate to cache maintenance port

refactor(soc): remove external fbus production interface
chore(soc): remove obsolete fbus adapters and diagnostics
```

---

# 30. 最终结论

本次修改不是两个独立优化，而是一项统一的 AI Memory Architecture 重构。

最终职责：

```text
Bulk Tensor Write
→ S02

Gemmini Memory
→ InclusiveCache / S00

PPU Head Read
→ URAM Local Reader

Head Flush
→ Cache Maintenance Port

Tensor Invalidate
→ Cache Maintenance Port
```

最终目标：

> **将 FBus 从生产数据面完全移除，把系统分成 DDR Bulk Data Plane、Gemmini Coherent Memory Plane、PPU Local Memory Plane 和 Cache Maintenance Control Plane。**

这样既解决：

```text
Tensor FBus 170 MB/s 带宽不足
```

又避免：

```text
Gemmini bypass L2
导致第一层 +约 200 万 cycles、
整图约 1400 万 → 2100 万 cycles
```

同时还可以显著减少宽 AXI/FBus/TL 互连，为 VU13P 多 SLR 布线和时序收敛创造更好的条件。
