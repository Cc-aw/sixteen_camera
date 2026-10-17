# sixteen_camera：SW-P3 软件并行效率优化实施方案

> **执行对象：Codex。目标：在三路自主命令前端和既有 Head/L2 硬件方案之上，降低三路推理时的额外访存成本，向同前端 3× 扩展效率推进。**
>
> 本文是待实施的软件方案，不是已实现的优化或已验证的提速结论。无需等待用户补充板测即可开始实现与离线验证；性能选择保留到一次上板的自动对照流程。

| 项目 | 基线及边界 |
| --- | --- |
| 日期 | 2026-10-15 |
| 已读取远程源码 | `Cc-aw/sixteen_camera`，`main`，`3440bc10a15467f7ba42bb2ffac21a343e1956d6` |
| 软件执行路径 | `sw/benchmarks/frontend`：V33 自主前端独立三图基准 |
| 性能材料 | 用户提供的 `frontend_v34_parallelism_memory_analysis.md`，不是新硬件的测试日志 |
| 硬件配套 | H1 Head 读路径解耦；L1 secondary pool 34→68。本文不修改其 RTL、配置或 ABI |
| 数据来源说明 | 本次读取的是日志分析报告和仓库源码，没有重新取得、独立解析完整原始 UART 日志 |
| 正式任务 | S0 基线/原生计划接入；S1 缓存感知布局；S2 热点卷积 tiling 重选；S3 可关闭的短区间 Head 准入 |
| 软件产物 | 保留 V33；新增 SW-P3 候选 ELF、自动比较套件、完整溯源与回退 |
| 不在任务内 | 重构完整实时 Runtime、修改硬件、烧写 FPGA/Flash、改变模型精度、缩小输入、减少帧数 |

## 0. 执行决策

**主线为 S1 + S2，S3 仅作为独立可选策略，不默认叠加到正式候选。**

- S1 改变每 lane 私有可写缓冲的实际放置，尽量减少活跃访问窗口内的 set 冲突；不改变张量逻辑布局与生命周期。
- S2 针对 tag1/tag7 内的普通卷积，使用原生 Gemmini 规划器重新筛选少量 tile 几何；降低重复搬运、cache-line 访问成本及并发工作集压力，不以“更小 tile”作为目标。
- S3 只在现有两个 Head HOST 边界延后下一段的 RESUME，采用有界软准入；不增加全网按层同步，不阻止已经运行的前端，不延迟已经完成 Head 的正常发布。

这里的“3×”首先指**相同硬件、相同软件策略、相同工作量下，单自主前端与三自主前端的扩展比**。不得通过减慢串行、减少输入、改用长稳态窗口掩盖十二帧启动/排空，或替换较慢的分母来达标。

Codex 应直接实现可交付候选，而不是只提交一个诊断脚本。与此同时，若没有找到满足正确性与静态约束的 tiling 候选，必须保留该层基线并报告原因，不能强行改参数来制造“优化数量”。

## 1. 日志依据与收益边界

### 1.1 本轮实际指向的问题

| 报告事实 | 数值或现象 | 本方案的处理 |
| --- | --- | --- |
| V33 正式十二帧 | direct serial 112,751,701；frontend serial 110,975,914；frontend parallel 43,526,084 周期 | 作为历史参考，不视为 H1/L1 上的新成绩 |
| 图内延长主导 | 单帧图跨度平均增加 1,613,263.42 周期，占完整帧延长 97.40% | S1/S2 优先，CPU 小开销不作为主线 |
| 续帧已经较快 | 最长续帧间隙 171 周期 | 不重做 CPU 调度框架 |
| 逻辑请求量相同 | 单/三前端的客户端请求量相同 | 不把三路外存增加归因于“算了更多图” |
| 外存流量增加 | refill +93,624,448B（34.93%）；writeback +36,710,144B（27.53%） | 以缓存放置、tile 重复读取与活跃窗口为优化对象 |
| 主热点 | tag1 +804,748；tag7 +478,031；tag8 +177,838 周期 | tag1/7是大区间，不当作单层耗时 |
| Head 局部等待 | tag8 Head 读排空 191,245，上游 AR 阻塞 216,916，下游 AR 阻塞 57 周期 | H1 已针对结构；S3仅验证剩余流量节奏问题 |
| HOST 可见成本 | 三路 HOST 回调累计 601,305 周期，其中 PAD/copy 556,196 | 不承诺靠 HOST 精简填补 3× 缺口 |

来源：[S1] §3～§11。跨 lane、跨 bank、跨窗口的等待可能重叠，不得相加得到必可回收周期。`spad_wait` 是 DMA 请求接口反压，不是专用 scratchpad bank 冲突计数。

### 1.2 目标量化

以历史 V33 的单自主前端 110,975,914 周期为**固定参考**：

| 参考扩展比 | 十二帧并行周期上限（向下取整） | 相对历史并行基线所需下降 |
| --- | ---: | ---: |
| 2.8× | 39,634,255 | 8.94% |
| 2.9× | 38,267,556 | 12.08% |
| 2.95× | 37,618,953 | 13.57% |
| 3.0× | 36,991,971 | 15.01% |

相对 CPU direct serial 达到 3× 的历史门槛为 37,583,900 周期，需下降约 13.65%，这不是同一扩展指标。

历史同前端扩展比为 2.549642×，扩展效率约 84.99%。以 `Tserial/3` 为理想参考，历史十二帧并行仍有约 6,534,112.67 周期差距。该差距不是某一计数器的可回收预算。

H1/L1 会同时改变串行与并行周期；S1/S2 也可能同时加速两者。最终一律重新测分子和分母。**S1/S2/S3 不设置虚构的固定提速百分比，不能与硬件方案预估收益相加。**

### 1.3 版本约束

报告实际来自 MPV3 ABI 1.0/13 块；核对的仓库为 ABI 1.1/14 块。不得把新 ABI 的扩展计数写成旧日志已经测到。用户表示已有硬件侧方案，本文没有读取新的上板结果，也不判断 H1/L1 是否已在实际板上生效。[S1 §2；S2]

## 2. 先接对真实的软件生成路径

### 2.1 当前 V33 不是直接编译实时 model.c

已核对路径：[S3][S4][S5]

```text
sw/models/yolov5nu/frozen/frontend_v33/sources.lock.json
    → sw/benchmarks/frontend/scripts/prepare.py
    → build/firmware/frontend/native/
    → build/firmware/frontend/generated/graph.inc 等
    → sw/benchmarks/frontend/src/main.c + src/ppu.inc
    → V33 ELF
```

`prepare.py` 保留 native tile geometry、B reuse、FP16、MaxPool/Resize 和完成边界，且从冻结文件复制 `fixed_conv_packets.inc` 等。因此只修改 `sw/models/yolov5nu/src/model.c`、通用实时 generator 或已生成的 `build/.../graph.inc`，**不等于** V33 路径产生了新候选。

新增一个明确的 SW-P3 派生入口，由 `prepare.py` 的候选分支调用；冻结 V33 输入保持只读。禁止修改旧 SHA 锁后声称原生基线未变。

### 2.2 现有优化不得重复计功

保留并识别已有的静态内存规划、Concat 消除、B/权重复用、硬件 MaxPool、批量 Resize 和固定 packet。冻结 `memory_schedule_manifest.json` 已为 stage0、35、123、124、146、147 等记录 selected tiling；stage163/164保留原候选。[S6]

当前 V33 派生器还明确移除了旧 coroutine/credit polling/Head admission-window 调度。冻结文件里有旧 `phase_cycles=64000`、`cooldown_cycles=16000`，不表示修改这两个数字能直接控制当前自主前端。[S3][S6]

### 2.3 S0 最小交付

实现一个小型离线计划描述，不建设通用编译器框架。至少导出：

```text
stage_id, op_kind, logical_tensor_id
shape, physical_stride, read/write ranges
arena_class, logical_offset, logical_bytes, alignment
packet_count, config, geometry, launch, reuse/NULL semantics
SPAD/ACC use, existing DRAIN/HOST boundaries
head_id, original_plan_hash, candidate_plan_hash
```

报告中的 tag1/tag7只用于确定优先区域；具体层的静态压力排名从这些描述生成。不得把 tag1 的 804,748 周期全部记到 stage75。

## 3. S1：缓存感知的私有缓冲布局

### 3.1 目标与限制

不改变硬件 L2 映射，用软件缓冲地址在现有映射下减少**活跃窗口**冲突。它不是 L2 容量扩容，不保证整个网络驻留，不等于为每个 lane 独占一个 bank。

当前 L2：两 bank、每 bank 8 ways/512 sets、64B line；bank=A12，set=A6～A11及A13～A15。[S2]

对已经正确转换到 L2 所见地址空间的地址 A，验证器使用：

```python
bank = (A >> 12) & 1
set_index = ((A >> 6) & 0x3f) | (((A >> 13) & 0x7) << 6)
```

地址别名转换使用项目真实约定，不新增全局清除 bit31 的捷径。对 Head 专用 decode 的规则，不得推广成所有指针的处理方法。

### 3.2 一个必须纠正的假设

当前冻结模型声明：[S7]

```c
activation_arenas[WORKER_COUNT][2217600] __attribute__((aligned(64)));
```

lane 间距 2,217,600B 对 64KiB 取模为 `0xD680`，**并非全部 lane 同色**。所以不能以“原地址完全同 set”为前提固定增加 4KiB、64KiB 或几 MiB。

在当前索引映射下，相差 64KiB 整数倍的同偏移不会改变 bank/set；仅相差 4KiB 主要改变 bank，且三 lane 无法一人独占一个二选一 bank。

应读取最终 ELF/map、实际 arena base 和逻辑范围，以真实地址计算。不要只看 `aligned(64)`，也不要只看源码中的数组大小。

### 3.3 第一版允许重定位的对象

- activation arena；
- convolution input/output scratch；
- `memory_pad` 与 `memory_intermediate`；
- 新建的命令表存储在证实有冲突时可纳入，但不是第一优先级。

**保持不动：**固定 Head 槽地址、Head 内部偏移、PPU descriptors、输入内容、权重/偏置内容、数值格式、TensorIngress ABI。

权重默认继续由三 lane 共享同一只读存储。不为“独立地址”复制三份权重；相同物理权重 line 在共享 L2 中只算一份，不要在静态评分里当三份冲突数据。

### 3.4 数据结构及迁移方式

为每类缓冲建立 `storage` 与 `view` 的区分：

```text
storage：分配对象，含对齐/偏移余量及可选 guard
view[lane]：计算使用的基址、逻辑容量、对齐、布局版本
```

先只平移整个私有 arena，保留 arena 内张量偏移与原有复用关系。禁止随意拆开共享/重叠视图，禁止修改所有张量的行 stride。

实现须覆盖 `select_worker_memory`、batch bindings、HOST PAD 指针、计划归一化、初始化与 host 测试。将数组改成指针后，不能继续用 `sizeof(pointer)` 作为缓冲长度；所有长度来自明确的逻辑容量。

不要在启动每帧时 memcpy 迁移整个 arena。布局在初始化/建表前固定，计划捕获使用最终 view 地址。

### 3.5 不等待板测的有界离线选址

选址是工程启发式，不是精确缓存模拟或已证明的最优解。

1. 保留原始布局作为必选候选；枚举 64B 对齐的 base 残值，覆盖当前低 16 位索引周期。
2. 用确定性的坐标下降/贪心搜索，而非全维度穷举；所有候选、seed、评分与最终地址都可复现。
3. 评分窗口使用当前层连续若干 packet 的潜在活跃数据，覆盖多种 lane 相对进度：同阶段、相邻 packet、局部落后一组。不能假装静态程序顺序就是三 lane 的真实执行交错。
4. 优先压低窗口内每 set 的不同 tag 压力和容量溢出代理指标；同时检查单 lane 局部性及两个 bank 的访问分布。
5. 权重、输入与输出不同访问类型分别统计；共享物理 line 去重；有效期之外的大数组不一次性计入活跃工作集。
6. 只修改基址时，操作、逻辑 payload、RAW 数、DRAIN 数和 HOST 序列必须完全不变。

静态分数不得叫“预计节省 N 周期”。若搜索未优于原布局，则保留原布局，并记录 `NO_BETTER_LAYOUT`，不得随机挑一个地址声称更好。

### 3.6 ELF 确定性

不要依赖一次链接后符号漂移的不稳定选择。优先对自有 storage 预留一个索引周期余量，使用已知对齐基址+选定偏移构造 view；保证在 storage 范围内。所有 profile 共用固定存储布置，切 profile 不通过重新链接任意漂移其他权重地址。

输出 `layout_manifest.json`：原始/候选实际地址、逻辑容量、padding、bank/set 残值、每窗口评分、额外存储字节、最终 ELF SHA。

### 3.7 S1 验收

地址合法、不重叠或仅保留原有合法别名；每类 scratch 的完整逻辑区间可访问；初始化无越界；18 张计划的数据无关性不变；**去除合法基址重定位后，S1 全部命令及 HOST 语义应与 V33 精确一致**。

该级别不需要放宽原 `normalize()` / plan compare，只应把归一化中的范围长度适配到显式 view。

## 4. S2：以三路访存成本筛选热点 tiling

### 4.1 优先范围

首批扫描 tag1/tag7 内的普通卷积，按静态重复读取与活跃 footprint 排名，**最多启用六个 stage 的变化**。stage0和35作为已知存在历史 tiling 调整的核对对象，不预先认定它们仍最差。Head 六层作为次级候选，避免把主工作又缩回只改 Head。

58 个普通卷积的计划生成可参考 `fixed_packets.py`、`fixed_plans.py`，但候选必须以 V33 冻结模型和实际 Gemmini headers 为输入。当前 V33 冻结 packet 不能被通用 generator 的旧版本结果无条件覆盖。[S8][S9]

### 4.2 新的优化维度

原 `memory_schedule_manifest.json` 自述指标是 native logical payload，排除 cacheline/AXI 效应，并非周期模型。[S6]

本轮新增静态比较维度：

| 维度 | 目的 |
| --- | --- |
| logical input/weight/bias/output bytes | 避免缩 tile 后总搬运反而增加 |
| 64B line 覆盖、边界拆分与重复触及 | 区分有效 payload 和缓存粒度成本 |
| 连续 packet 的 input halo 重叠 | 发现切得过碎导致的重复读取 |
| 权重复用链与实际重复装载 | 保留已有 B reuse，不重复计算收益 |
| 部分 line 写的次数/范围 | 作为潜在读分配压力代理，不冒充实际 refill |
| 三 lane 活跃 footprint | 在共享 L2 约束下比较候选，而非只看单 lane SPAD 能否容纳 |
| packet/RAW/DRAIN 数及 padding 算量 | 防止访存代理分数更低但指令/计算成本大涨 |

只能把 line 触及及模拟替换量称为“静态估算”。cache hit、MSHR占用、AXI burst合并及 refill 的真实周期不由这个模型精确给出。

### 4.3 实际候选生成方式

不要直接手改已经编码的 `geometry[6]` 或 `launch[2]` 数字。采用：

```text
原生层语义 + 当前 tile
    → 有界合法空间 tile 候选
    → 原生 C Gemmini helpers 重新生成 packet
    → 解码、覆盖与依赖检查
    → 静态多指标筛选
    → 固定少量 stage 的最终候选
```

当前 `fixed_packets.py` 已展示用 host C 执行原生 tiling loop、SPAD helper、命令宏与 FP16 packer 的方法；继续复用这一机制，而不是在 Python 重新手写 FP16/指令编码。[S9]

第一版优先搜索空间维度；不随意改变 K 归约顺序，不改变量化/缩放/激活时机。改变输出通道分块仅在无部分累加/复用依赖变化且数值回归覆盖时允许。

**默认安全限制：**完整模型 logical payload 不增加；RAW 总数增幅不超过 5%；不新增逐 tile CPU HOST/等待；不增加 DRAIN 数；不改变矩阵实际数学工作。5% 是此次工程筛选上限，不是最优阈值。对所有代理指标无优势或无法证明数值等价的层保留原计划。

对 padding 算量增加的候选，即使 packet 减少也不能自动选取。每个启用层应给出候选前后对照，而不是只输出一个总分。

### 4.4 原生复用链是硬约束

`yolo32_conv_packet.offsets[4]` 包含 weight/output/bias/input；`UINT32_MAX` 表示 NULL，存在不重复装载、部分累加等状态语义。[S8]

因此禁止：

- 随机打乱 packets；
- 直接让 lane1 从 packet N/3 开始、lane2 从 2N/3 开始；
- 按 DDR 地址排序已编码 RAW；
- 仅凭 output 地址不同就认定两个 tile 完全独立。

这些改法可能先遇到“复用尚未加载的权重”，或改变 ACC 初始化、scratchpad 轮换与最终输出。独立 tile 顺序优化留作后续，除非此次已建立完整依赖证明；不列为本轮必交付功能。

### 4.5 面向 V33 的真正接入

`prepare.py` 候选分支必须明确加载 SW-P3 生成的 packet/plan，而基线分支继续精确加载冻结 V33。禁止直接更改 `frozen/frontend_v33`。

新计划仍在计时前捕获，运行期间仍由自主前端连续执行。不得为了动态决策恢复旧逐包 CPU 提交。

S2可能改变 packet/RAW总数：新候选必须有自己的 manifest 和 software profile标识，不能继续把它输出为“V33原始10870项且完全相同”。保留旧 V33 的全部硬编码一致性检查，仅对 SW-P3 引入独立的语义验证路径。

### 4.6 S2 正确性证明

至少验证：

1. 每个输出元素覆盖完整，输出不重写遗漏，tile边界及padding合法。
2. 输入/权重/偏置地址、FP16配置与原生算子语义一致。
3. K累加顺序、bias应用次数、最终缩放/激活次数保持约束。
4. SPAD/ACC容量、地址轮换、复用关系与原生helper一致。
5. PAD与Head HOST的顺序不变，发布发生在真实完成之后。
6. CPU原生整数参考/已有模型测试和能运行的真实Gemmini局部RTL测试通过。只验证命令字段格式不等于证明数值正确。

离线缺少真实计算工具时，标记相应验证 `BLOCKED`，保留S1及已证明部分；不得用 mock scheduler PASS 冒充卷积算术 PASS。

## 5. S3：短区间 Head 软准入，可关闭

### 5.1 为什么不是主线

H1 已针对 Head 读路径的全局排空。新硬件可能使软件节流无益甚至有害。S3单独打包、默认关闭，不把它视为“必有收益”的修补。

也不要给全部 lane 设置几百万周期的启动间隔。那会增加十二帧 warm-up/排空，而且可能失去三 lane 共享相邻权重的时间局部性。

### 5.2 利用已有 HOST 边界，不增硬件接口

报告给出：[S1 §7、§14]

```text
HOST tag7：stage123/head3 已完成，随后进入 tag8 区间(stage124/head0)
HOST tag9：stage146/head4 已完成，随后进入 tag10 区间(stage147/head1)
```

只在 tag7/tag9 的下一段 RESUME 处做可选准入。这仅控制 tag8/tag10 这两个短区间，不把它称为覆盖 stage119～124 的整个 Head 分支。

**先按既有契约立即执行已完成 Head 的 publication，再决定何时恢复下一段。**不把延迟 PPU入队或延迟已完成Head发布，冒充减少已发生访存。

### 5.3 固定工程默认

```text
enabled = false                  # 正式候选默认关闭，独立 profile开启
soft_active_interval_cap = 2     # 软限制，不是永远只许两颗计算
max_defer_cycles = 16000          # SoC周期；候选工程值，不是已验证最佳值
```

第三个短区间请求最多推迟16,000周期；到期即放行，即便活跃数达到3。每次循环继续处理其他lane的HOST/DONE、PPU结果与watchdog，不可busy-wait堵住CPU服务。

不等待“其他lane到同一层”，不等待全部Head清空，不暂停已运行的lane，不新插入全局fence。当前不存在可安全任意暂停前端的接口，不得通过写寄存器或修改命令表内存干扰活跃前端。

### 5.4 状态机与完成条件

在 `parallel_batch()` 中把“HOST回调完成”和“RESUME发出”拆开：

```text
HOST_OBSERVED → HOST_SERVED → RESUME_PENDING → RESUMED
```

每个HOST只调用一次 `execute_host()`。延期期间记录原 tag、frame、lane、deadline；不能因 `held_events` 仍置位而重复发布 Head 或增加 `host_next`。

在下一对应 HOST（tag8/tag10）被真实观察到、并满足原本地完成边界后释放活跃标记；fault/reset/restart时明确清理。发出的RAW游标不代表计算完成，不能据此提前释放。

中断屏蔽/重开遵守现有前端协议；不要把“延期HOST”当成一个需要不停重读并重复ACK的新中断。预算到期、其他事件和PPU均可推进，软件单测要覆盖极端交错。

### 5.5 S3观测与失败条件

记录gate次数、累计/最大等待、超时放行、同时活跃数；计时区间内不打印UART。所有主动等待包含在总周期。

若总并行周期不降、仅Head等待计数下降，或者某lane延迟尾部增大而吞吐未改善，则关闭S3。S3不得为3×目标人为延迟串行测试。

## 6. 本轮明确不做的工作

| 不做 | 原因 |
| --- | --- |
| 删除DRAIN/清空fence | 日志的稳定DRAIN样本仍显示Gemmini busy；完成依赖未被证明冗余 |
| 全网按层barrier、共享大锁 | 会削弱独立前端，不能以三路“同时处于一层”代替高效率 |
| 重写CPU协程/提高轮询频率 | 已有续帧和服务开销不是主要证据点 |
| 修改Head物理地址/PPU布局 | 会破坏H1/L1的软件兼容边界 |
| 全局L2 bypass、缓存失效优化 | 属于硬件/一致性变更，不在本软件任务内 |
| 给每lane复制整模型权重 | 会增加容量占用，报告未证明需要这么做 |
| 为batch=2更换指标 | 改变任务与基准；此次保留十二帧、原图片和每帧完整模型 |
| 全面跨层fusion、重做内存planner | 过大；既有复用已经存在，先做有界布局/tiling派生 |
| 只精简PAD/HOST即承诺3× | 可见开销与所需差距不匹配，且累计数不能直接换算可省墙钟周期 |

## 7. 文件与任务划分

### 7.1 已存在、必须核对的入口

```text
sw/benchmarks/frontend/scripts/prepare.py
sw/benchmarks/frontend/scripts/manifest.py
sw/benchmarks/frontend/scripts/check_elf.py
sw/benchmarks/frontend/src/main.c
sw/benchmarks/frontend/src/ppu.inc
sw/benchmarks/frontend/src/link.ld
sw/benchmarks/frontend/Makefile
sw/models/yolov5nu/frozen/frontend_v33/sources.lock.json
sw/models/yolov5nu/frozen/frontend_v33/parallel_model.inc
sw/models/yolov5nu/frozen/frontend_v33/fixed_conv_packets.inc
sw/models/yolov5nu/frozen/frontend_v33/memory_schedule_manifest.json
sw/models/yolov5nu/codegen/fixed_packets.py
sw/models/yolov5nu/codegen/fixed_plans.py
```

冻结文件只读。通用codegen helper可复用，但必须验证和V33冻结版本兼容；不能用较旧helpers生成不同计算再改golden。

### 7.2 建议新增，属于本次交付而不是现有文件

```text
sw/benchmarks/frontend/scripts/parallel_cache_plan.py
sw/benchmarks/frontend/scripts/parallel_cache_verify.py
sw/benchmarks/frontend/src/parallel_cache_layout.inc
sw/benchmarks/frontend/src/parallel_cache_gate.inc
sw/benchmarks/frontend/scripts/analyze_parallel_cache.py
tests/model/frontend_parallel_cache/
docs/optimization/sw-p3-parallel-cache.md
```

可以按现有工程风格调整小文件边界，不借机重构全部Runtime。新入口命名使用SW-P3/profile，避免擅自占用已有V34诊断版本名。

### 7.3 分阶段交付

| 阶段 | 必交付内容 | 与用户板测的关系 |
| --- | --- | --- |
| S0 | V33严格基线、实际生效路径、候选manifest及静态计划描述 | 不等待板测 |
| S1 | view/storage布局、确定性选址、逻辑等价证明、layout-only ELF/profile | 不等待板测 |
| S2 | 热点候选选择、原生packet重生成、数值/依赖验证、组合候选 | 不等待板测；无合法优势候选时保留该层 |
| S3 | 两个短区间有界准入、fake-device状态测试、默认off | 不等待板测；独立开关 |
| 验证集成 | 一次上板可运行的有限比较套件和离线解析器 | 只准备入口，不自动下载硬件/固件 |

不要回退或覆盖用户正在实现的H1/L1。工作树有未提交修改时记录并隔离本次软件改动，不执行破坏性清理。

## 8. 自动测试与证据等级

### 8.1 必须保留现有V33测试

基线命令在核对提交上已存在：[S5]

```bash
make test-v33
```

它覆盖建表/oracle、实际调度函数fake-device、PPU生命周期、日志和ELF等，不自动等于真实硬件算术通过。

新增下列目标（先实现Makefile，再运行；它们不是当前仓库已有命令）：

```bash
make test-sw-p3
make benchmark-sw-p3
make audit-sw-p3
```

禁止放宽旧 `native_workload_changed`、原生计划逐项对比或旧日志解析的校验规则，以便候选“通过”。旧V33不变，SW-P3用独立的变更契约验证。

### 8.2 最低测试矩阵

| 类别 | 场景 |
| --- | --- |
| 布局 | 三lane五类私有buffer；所有18张计划；长度/64B对齐/越界/guard；基线和候选颜色；实际ELF地址 |
| alias | 原有重叠tensor view不变；输入只读；Head固定；权重只读共享 |
| 计划 | 两次建表数据无关；S1归一化完全一致；S2覆盖、复用与数值约束独立检查 |
| scheduler | 一lane/三lane；两个HOST同时到达；gate到期；DONE和PPU返回交错；fault/timeout/reset |
| publication | 每Head每版本一次；所有者/slot/generation匹配；清理完成前不允许PPU消费 |
| 结果 | 独立原生模型参考、逐层/逐Head适用检查；PPU完整40字比较；必要真实Gemmini局部计算 |
| 工具/构建 | 冻结输入hash、候选plan hash、ELF/map/disassembly、ABI检查、缺工具真实标注 |

数据守卫不是每帧计时区间内的大范围扫描。完整golden比对和报告输出安排在计时外；不得省略真实推理或PPU服务。

### 8.3 分清三类结论

- `STRUCTURAL_PASS`：新布局/新packet确实进入生成/ELF。
- `FUNCTIONAL_PASS`：已执行的实际数值/协议测试通过；列明覆盖范围，mock不可替代真实计算。
- `PERFORMANCE_PASS`：固定硬件上的正式总周期对照，只有真正运行后才能给出。

在当前对话环境只交付方案，不宣称上述任何实现已由本文完成。

## 9. 一次上板的有限自动比较

用户无需反复人工改参数。生成一个 suite 和一个自动解析器；加载选定H1/L1比特流后，软件按既定顺序运行以下最多四个profile。

| profile | 内容 |
| --- | --- |
| reference | 冻结V33计算/调度语义与参考布局 |
| layout | 只启用S1 |
| cache_plan | S1+通过验证的S2；正式候选默认 |
| cache_plan_gate | cache_plan+S3；独立候选 |

每profile保留单前端和三前端的相同十二帧工作量；CPU direct参考另列。至少做一次正序、一次反序，以暴露顺序和缓存状态影响；是否增加重复数由自动套件配置，不转化成人工前置测试。

### 9.1 同一ELF基线的边界

同一suite内 `reference` 是相同程序框架中的参考路径，**不是旧V33 ELF的逐字节复现**，因为新代码可能影响链接地址/指令cache。保持旧V33 ELF及其SHA，必要时同一下载脚本可以在不重烧比特流的条件下顺序加载旧V33和suite。

布局和输入/权重的固定section或view应避免profile切换改变无关地址。建立所有profile共用的存储与初始化协议；不在只给候选的计时前预热其权重。

每profile同一有效cache初始化/预热政策，不能一方cold、一方warm。不要新加未经验证的全局cache invalidate；无法保证cold时明确标记warm/order-controlled测试。

### 9.2 完成与版本唯一性

不能简单复用 `executor*FRAMES+f+1` 作为整个suite中不重复的frame/version。不同profile/pass使用单调session/run标识，并正确排空PPU、回收slot、刷新publication generation，避免旧结果误认作新结果。

建表、切profile与比对在计时外完成；执行中延后RESUME、PPU等待、启动和排空都包含在组周期内。不能通过缩短计时窗制造3×。

### 9.3 指标

同时输出：

```text
Tserial(profile, hardware)
Tparallel(profile, hardware)
Sfrontend = Tserial / Tparallel
efficiency = Sfrontend / 3
absolute_gain = Tparallel(reference, hardware) / Tparallel(candidate, hardware)
per_lane_frames / per_image_frames
input/model/plan/ELF hashes
hardware identity supplied by build/download manifest
```

旧硬件历史112,751,701/110,975,914只作参考，不能当H1/L1硬件的实时分母。命令ABI版本不是已加载比特流的SHA；没有板上指纹则标记“加载清单声明的硬件身份”。

S1按lane布局不同，需防止刻意减慢lane0抬高串行分母：记录各lane的单独表现；可在扩展测试中按并行运行实际job→lane映射做串行回放，作为matched审计。不要取最慢lane或最慢profile当正式分母。保持原V33 lane0口径另列，变化时明确名称。

### 9.4 最终选择原则

先保证完整结果一致，再比较同硬件绝对三路周期和同策略扩展比。只因比值升高、但并行总周期未改善的候选不接受。小幅变化仅有一两轮且波动区间重叠时标记未证实，不自动晋升。

S3无收益则关闭。S2部分层无收益可以回退这些层，不撤回已证明有效的S1；但无实测时都只能叫候选。

自动诊断快照只在硬件能力支持时读取；ABI1.0、1.1的块数、reserved槽、统计语义分别识别。需要新增软件日志schema时版本化解析器，不把新事件塞入旧槽位。

## 10. Codex最终交付清单

| 产物 | 必须说明 |
| --- | --- |
| 实际软件diff | S1/S2/S3分别可回退；不含无关RTL/Runtime变更 |
| 基线与候选ELF | 文件SHA、编译器、profile、对应配置；旧V33保留 |
| layout_manifest.json | 实际地址、容量、padding、候选评分；不是周期预测 |
| tiling_manifest.json | 哪些层变化、native参数、bytes/line/packet/算量变化、保留层原因 |
| verification.json | 每项PASS/FAIL/BLOCKED及实际命令、日志路径 |
| 比较suite及解析器 | 一次运行、有限profile、同负载、完整结果、明确计时口径 |
| 交付说明 | 实现状态、离线证据、已知风险、回退、未执行板测明确标注 |

建议状态输出：

```text
SW_P3_SOURCE_BASELINE=<commit>
SW_P3_LAYOUT=<ENABLED|NO_BETTER_LAYOUT|BLOCKED>
SW_P3_TILING_CHANGED_STAGES=<list>
SW_P3_HEAD_GATE_DEFAULT=OFF
SW_P3_HARDWARE_ABI_CHANGED=NO
SW_P3_MODEL_CHANGED=NO
SW_P3_NUMERICAL_TESTS=<coverage and result>
SW_P3_BOARD_PERFORMANCE=NOT_MEASURED
```

没有进行板测时，最后一项不得改为PASS或“预计达到3×”。

## 11. 交给Codex的执行提示

> 按本文实施SW-P3，不重新提出一轮需要用户先上板的诊断计划。保护现有Head/L2硬件改动和冻结V33。先接通实际frontend生成链，再完成S1缓存感知布局与S2少量热点tiling派生；S3仅实现可关闭的有界Head准入，默认off。不新增全网按层同步，不删DRAIN，不改变Head/PPU ABI，不复制三份权重，不以更慢串行为分母。完成自动正确性测试、候选ELF、独立回退与一次上板可跑的有限比较suite。静态模型只用于选候选，不宣称周期收益；无法证明的层保留原计划，缺工具如实标注并继续其他工作。

## 12. 证据索引

源事实、从源码推导的关系、工程选择在正文中分别标明。仓库路径均以固定提交 `3440bc10a15467f7ba42bb2ffac21a343e1956d6` 为依据，执行时需核对用户工作树是否有更新；不回退用户的新改动。

- **[S1]** `frontend_v34_parallelism_memory_analysis.md`：§2版本/覆盖；§3正式指标；§4～§6服务和完成；§7热点定义；§9/§10额外流量与L2；§11 Head；§14既有软件优化与建议；§15证据边界。
- **[S2]** `sixteen_camera_Head_L2_urgent_codex_implementation.md`：§0选定H1/L1、§2契约；及仓库 `hw/soc/source/shell/memory_parallel_v3/scala/MemoryParallelV3.scala`、`docs/integration/triple32-v3-tensor.md`。
- **[S3]** `sw/benchmarks/frontend/scripts/prepare.py`：`freeze()`、`generate()`、固定packet复制、native graph派生和retained/removed manifest。
- **[S4]** `sw/benchmarks/frontend/src/main.c`：`normalized_address()`、`capture()`、`prepare_model()`、`execute_host()`、`parallel_batch()`、`prepare_batch()`。
- **[S5]** `sw/benchmarks/frontend/Makefile`：实际生成依赖、host/oracle比较、ELF/audit、`tests/model/frontend_v33`接入。
- **[S6]** `sw/models/yolov5nu/frozen/frontend_v33/memory_schedule_manifest.json`：既有选定tile与指标定义。旧调度字段不等于V33自主前端启用了旧调度策略。
- **[S7]** `sw/models/yolov5nu/frozen/frontend_v33/parallel_model.inc`：`activation_arenas`大小及tensor offsets、conv scratch、worker绑定。
- **[S8]** `sw/models/yolov5nu/frozen/frontend_v33/fixed_conv_packets.inc`：packet结构、NULL offsets、`yolo32_packet_submit()`和`yolo32_fixed_conv()`。
- **[S9]** `sw/models/yolov5nu/codegen/fixed_packets.py`：`native_program()`、`bake()`；原生helpers、FP16 packer与7指令packet生成机制。
- **[S10]** `sw/benchmarks/frontend/src/ppu.inc`：slot/版本/发布/结果生命周期。该文件必须在改动S3和多profile suite时重新审核。

**本文所增加的布局搜索策略、静态成本模型、最多六层/RAW 5%约束、Head软上限2与16,000周期预算均为候选工程决策，报告并未验证它们的收益。**

### 输入附件指纹

```text
frontend_v34_parallelism_memory_analysis.md
SHA256 ed7f448e802509d9d1bf0ac08a94ace38b2eb5e43776a0a52a92e7c3bd790e26

sixteen_camera_Head_L2_urgent_codex_implementation.md
SHA256 6111275b18394dac5985d6779b6d37507b0fb3ffe02668034fdaa5df853e7c07
```
