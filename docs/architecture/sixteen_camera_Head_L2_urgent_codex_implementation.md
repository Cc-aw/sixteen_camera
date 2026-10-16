# sixteen_camera：Head 与 L2 紧急硬件优化实施规范

> **执行对象：Codex。交付类型：可回退的硬件候选版本，不是新一轮诊断报告。**  
> **执行原则：不等待用户补充板测；直接实现、自动回归、重新生成 RTL，并在环境具备时完成一次集成综合与布局布线。**  
> **当前状态：本文是实施指令，本文生成时尚未修改项目 RTL、运行新仿真或取得上板性能。**

| 项目 | 本文采用的基线 |
| --- | --- |
| 日期 | 2026-10-15 |
| 仓库 | `Cc-aw/sixteen_camera` |
| 已核对分支 / 提交 | `main` / `3440bc10a15467f7ba42bb2ffac21a343e1956d6` |
| 硬件产品 | `triple32_v3_tensor` |
| Scala Config | `TaihangSoC1Rocket1RVV3Gemmini32x32MemoryParallelV3TensorIngressConfig` |
| 计算配置 | 1 Rocket、1 RVV、3 × Gemmini32，目标 100 MHz |
| 软件基线 | V33 自主前端独立三图基准；实时 Runtime 适配不属于本任务 |
| 诊断依据 | 用户提供的 `frontend_v34_parallelism_memory_analysis.md` |
| 必须实施 | **H1：Head 读路径解耦；L1：L2 secondary 共享池独立扩容** |
| 必须保留 | 当前正确性契约、基线回退、生成溯源、自动验证 |
| 不在授权内 | 下载 FPGA、下载固件、烧写 Flash、要求用户反复上板 A/B |

本文中的源码事实来自上述固定提交；性能事实来自用户报告；参数选择与新增架构是**本次工程设计决策**，不是报告已经验证的优化结论。出处见第 14 节。

---

## 0. 给执行者的总指令

直接完成下面两项硬件修改，不要将任务退回为“先加计数、等待用户测试、再决定修改”。允许补充仿真观测，但观测不得成为功能实现的前置人工环节。

**H1——Head 读路径：**在生产使用的 `axi4_head_uram_router_v3.sv` 中，将非 shadow 模式的读路径改为“请求缓冲 + 按 ID 保序的目的地调度 + DDR/Head 独立返回仲裁”。等待一个 ID 的旧 DDR 事务时，不应要求其他 ID 的 DDR 事务全部排空；Head 本地读执行期间，符合条件的 DDR AR 仍能推进。写路径维持当前实现。

**L1——L2 请求池：**为 secondary payload 容量新增独立参数，将当前每 bank 的共享请求池从 **34 项改为 68 项**。保留每 bank **32 个普通 MSHR + 2 个一致性 MSHR**、102 个逻辑队列、4 项读响应 credit、同步 payload RAM、现有 winner/reload/set 所有权机制。

两项修改分别形成可独立回退的提交或补丁，随后在同一候选配置中集成。默认候选版本开启 H1 + L1。不要为此维护多个生产 Config 或复制整套 SoC 产品目录。

**本轮主动收缩：不实现同 set 多 MSHR、不改 cache bank 地址映射、不增加 cache 数据容量、不恢复组合 same-tag reload bypass、不改 Head 写路径、不启用整套 DMA v2。**

若某项修改未通过必要的自动验证，应修复或隔离该项，不得删除断言、伪造 PASS、跳过后把整个候选版本宣布可用。工具缺失时继续完成其他可执行工作，留下准确的 BLOCKED 状态与复现命令，不等待用户提供新板测。

---

## 1. 为什么只做这两项

### 1.1 报告支持的事实

| 证据 | 报告数值 / 现象 | 本文如何使用 |
| --- | --- | --- |
| 正式性能 | V33 十二帧并行 `43,526,084` 周期；相对直接串行 `2.590440×` | 仅作为历史基线，不承诺本次达到 2.8× 或 3× |
| Head 局部阻塞 | tag8：Head 读排空 `191,245`；Head 前 AR 阻塞 `216,916`；Head 后 DDR S00 AR 阻塞 `57` 周期 | 优先解除 Head 路由中过宽的排空条件 |
| 不能只优化 Head | tag1 增加 `804,748` 周期，且没有 Head 排空；tag7 增加 `478,031` 周期 | 同时推进 L2 请求承接能力 |
| L2 排队 | 三路时两个 bank 的 secondary queue stall 分别为 `1,474,329` / `1,455,070` 周期 | 扩展真实共享池，不把逻辑队列数当成物理容量 |
| 缓存干扰 | 同十二帧、相同客户端逻辑请求量，refill 增加 `34.93%`，writeback 增加 `27.53%` | 说明存在额外流量；不宣称扩队列会自动消除它 |
| 设备侧压力 | `spad_wait` 是 DMA 请求接口反压，不是 scratchpad bank 冲突的专用计数 | 不盲改 scratchpad bank 或阵列结构 |

来源：[S1] §3、§7、§8.2、§9～§11。

### 1.2 不得混淆的版本边界

报告实际板测身份是 **MPV3 ABI 1.0 / 13 块**；当前仓库生成检查要求 **ABI 1.1**，硬件文档声明 14 块。不能把旧报告写成当前固定提交已经重新上板测得的结果。[S1 §2；S2；S9]

V34 是诊断版本，不能把诊断比值变化写成新优化成绩。本文不移植 V34、不修改 V33 的模型、图片、计划表内容、结果判断或测试帧数。[S1 §3；S11]

### 1.3 本次接受的取舍

H1 的定位证据更直接，但修改涉及 AXI 顺序与返回仲裁，必须有协议回归。L1 的改动较局部，但 68 项是此次选定的保守扩容值，**不是已经证明的最优深度，也不保证整网提速**。

不再要求用户补充性能归因，改为由 Codex 在本地证明“功能正确、结构生效、目标阻塞机制确实被解除”。无板测时，最终状态只能是**离线验证后的候选版本，整网性能待实测**。

---

## 2. 不可破坏的硬件与软件契约

| 项目 | 本轮要求 |
| --- | --- |
| Gemmini | 3 × DIM32；不改阵列、数值格式、MaxPool、DMA 配置 |
| 时钟 | SoC 目标 100 MHz；不通过降频规避实现问题 |
| L2 | 两 bank、总 512 KiB、每 bank 8 ways / 512 sets、64B cache line |
| 地址映射 | bank A12；set A6～A11、A13～A15，保持不变 |
| L2 MSHR | 每 bank 32 个普通 + 2 个一致性，保持不变 |
| 总线 | SoC memory 512-bit、ID2；Tensor 256-bit、ID5，保持不变 |
| Head | 六个 1 MiB 槽；512-bit AXI 数据、256-bit PPU 本地读，保持不变 |
| ABI | 前端 custom3 控制、custom0/1/2 直接入口；不改软件可见接口 |
| 完成语义 | DRAIN、Gemmini busy、Head publication、slot ownership 与 PPU 生命周期不放宽 |
| 模型 | 完整 YOLOv5nu、既有输入和硬件 PPU，不减层、不改精度、不修改 golden |
| RTL 来源 | Scala 功能修改必须重新 elaboration；不得手工修补生成 RTL 替代源码修改 |
| 物理实现 | 保留当前 SLR / pblock / DDR 寄存切片策略；不新增宽泛 false path |

当前结构与配置依据：[S2]～[S9]。Head 地址 canonical 化只用于现有 Head 解码，**不得把清除 bit31 的处理扩展到所有 DDR 地址**。

软件观测到请求“被接收”不代表请求已完成。新队列中的描述符、已发出的事务、返回 FIFO 中的数据，均需纳入所属功能状态的生命周期；禁止提前返回完成以制造表面提速。

---

## 3. 修改文件与生成路径

### 3.1 Head 主修改文件

```text
hw/rtl/ai/postprocess/axi4_head_uram_router_v3.sv
hw/rtl/memory/postprocess_memory_bridge_v3.sv
```

公共读执行 / 请求队列逻辑确有必要拆分时，可新增一到两个小模块，并加入 `hw/manifests/rtl_manifest.tcl`。不要为了抽象而把局部修改扩展成总线框架重构。

只读核对并尽量不改：

```text
hw/rtl/ai/postprocess/head_uram_store.sv
hw/rtl/ai/postprocess/head_local_reader.sv
hw/rtl/memory/ddr_memory_subsystem.sv
hw/rtl/interfaces/axi4_if.sv
```

生产 bridge 实例化的是带 `_v3` 的 router；不要修改同目录旧版 `axi4_head_uram_router.sv` 后宣称生产路径已优化。[S3]

### 3.2 L2 主修改目录

以下简写 `CACHE_OVERLAY` 指：

```text
hw/soc/source/shell/memory_parallel_v3/chipyard/generators/
rocket-chip-inclusive-cache/design/craft/inclusivecache/src/
```

主要文件：

```text
CACHE_OVERLAY/Configs.scala
CACHE_OVERLAY/Parameters.scala            # 本次新增覆盖文件，见 §6.2
CACHE_OVERLAY/RegisteredListBuffer.scala  # 保留算法；只做必要参数/断言适配
CACHE_OVERLAY/Scheduler.scala             # 保留调度与 reload，核对参数接入
```

配置入口：

```text
hw/soc/source/shell/memory_parallel_v3/scala/MemoryParallelV3.scala
```

`MSHR.scala` 是必须回归的依赖，不是本轮默认修改对象。`ListBuffer.scala` 中的 `ListBufferParameters` 需要核对位宽，不要把旧 `ListBuffer` 的异步 peek 算法重新接回生产 Scheduler。

### 3.3 构建、检查和溯源

```text
tools/soc/build_triple32_v3_tensor.py
tools/check/check_triple32_v3_tensor.py
hw/manifests/current.json
hw/manifests/rtl_manifest.tcl
hw/soc/source/shell/IMPORT_MANIFEST.json
hw/soc/source/shell/REFERENCE_MANIFEST.json
```

读取实际 manifest 格式后，按项目既有规则更新修改项与新增覆盖文件的摘要。**不修改冻结 reference 原文件来逃避覆盖管理，不整体重写无关锁文件。**

当前生成器先恢复 reference，再安装 V3 overlay，再安装 command frontend integration；必须核对最终生效文件，不以“仓库里存在修改后的文件”代替实际编译闭包证据。[S8]

---

## 4. H1：Head 读路径的目标架构

### 4.1 现有问题与不得采用的修补

当前非 shadow 模式，Head AR 准入要求 `ddr_read_pending == 0`；进入本地读状态后，DDR AR 与 R 返回也受到共享读状态机约束。[S3]

因此以下改法均不合格：

- 只删除 `ddr_read_pending == 0`，但仍由一个 `read_state` 排他选择 DDR/Head 返回。
- 只在原 router 前增加普通 FIFO，Head 请求仍停在唯一队首等待所有 DDR 排空。
- 将全局等待换成按 ID 等待，却不能缓冲被阻塞请求，或仍在 Head 活跃时冻结全部 DDR AR。
- 允许同 ID 跨目标返回越序，或用提前返回 RLAST/B 来释放资源。

### 4.2 选定方案：按 ID 排队 + 单 ID 单活跃目标

本轮采用**不带通用数据重排缓冲器**的方案：

```text
上游 AR
  → 按 ARID 进入描述符 FIFO
  → 查看各 ID 队首、目标锁与资源条件
  → DDR AR 发射寄存级       → DDR
  → Head/错误响应执行器    → Head URAM

DDR R → 两项弹性缓冲 ─┐
                     ├→ 整个 burst 锁定的 R 仲裁 → 上游 R
Head R → 两项弹性缓冲 ┘
```

对每个 AXI ID、每个方向分别维护有序性。本轮只改读方向：同 ID 队首不能被后来的同 ID 请求绕过；某 ID 已有一个目标的保留/在途读时，不向另一个目标发射该 ID 的新读。不同 ID 可在 DDR 与 Head 间并行推进。

这里采用的 Single Slave per ID 思路有公开 AXI interconnect 设计依据，但该思路本身不能代替本项目的协议仿真。[S12]

**ARID 不是 Gemmini lane 编号。**当前外部 ID 宽度为 2，且生成路径包含 `TLToAXI4`、`AXI4IdIndexer` 和 `AXI4UserYanker`。依据真实外部 ARID/RID 工作，不按软件 worker、原 TileLink source 或猜测的 lane 映射解锁。[S10]

若真实负载的大量请求被压缩到同一个 AXI ID，本方案仍会保留该 ID 必需的等待；H02 证明的是硬件具备跨 ID 解耦能力，不证明实际负载一定利用它。本轮不因此扩大 ID 位宽或放松同 ID 顺序。

### 4.3 固定默认参数

以下参数是本次选定的工程默认值，不开展深度扫描：

| 参数 | 候选值 | 含义 |
| --- | ---: | --- |
| `READ_DECOUPLE` | 生产 bridge 显式设为 1 | router 公共默认可保留 0，兼容其他实例；生产路径必须实际开启 |
| `READ_QUEUE_DEPTH_PER_ID` | 8 | 每个 ID 等待发射的描述符 FIFO 深度，不是该 ID 的在途上限 |
| `READ_ACCEPT_LIMIT` | 32 | router 接收但尚未向上游完成的读事务总上限，覆盖排队/保留/在途/返回缓冲 |
| DDR 在途能力 | 保留 32 | 不把 32 笔能力误改成“每 ID 一笔” |
| DDR R 缓冲 | 2 beat | 同时切断数据与反向 ready 的长组合链 |
| Head R 缓冲 | 2 beat | 吸收本地同步读返回 |
| 本地 AXI Head burst | 最多 1 个活跃 burst | 本轮不并行化多个 URAM AXI burst；DDR 不受此全局限制 |

生产 `ID_WIDTH=2` 时共 4 个 ID FIFO。已发射描述符可从请求 FIFO 移除，但事务 credit 与目标锁必须继续保留至上游最终响应握手。因此每 ID 的 8 项请求队列**不应把同 ID 的 DDR outstanding 限制为 8 或 1**。

保留模块已有参数化能力；测试至少覆盖生产 `512/256/ID2` 与原 `256/256` 数据宽度组合。不得硬编码软件只使用某两个 ID。

### 4.4 兼容模式与写路径隔离

有效优化条件为：

```text
READ_DECOUPLE == 1 && SHADOW_DDR == 0
```

`READ_DECOUPLE=0` 必须保留原读路径，可用于回归与回退。`SHADOW_DDR=1` 维持原有 shadow 行为，不在本轮另行改造。

优先采用编译期 generate 分支拆分读控制，**写控制和六个 `head_uram_store` 实例保持共用**。不得同时实例化两份 6 MiB Head 数据存储；不得为回退复制整个 memory subsystem。

AW、W、B 的准入、数据归属、错误响应、写排空条件与 shadow 写入语义不变。读写握手可以独立发生，不能新增“有读在途就冻结全部写”的条件。

---

## 5. H1：实现必须满足的状态与协议规则

### 5.1 描述符与输入握手

每条描述符保存完整的现有 AR 元数据：`id/addr/len/size/burst/lock/cache/prot/qos`，以及固定下来的路由目标、Head bank、合法性结果。字段以实际 `axi4_if` 为准，不丢弃任何已存在的边带字段。

`s_axi.arready` 由对应 ID FIFO 的容量、全局接受 credit 和有效复位状态决定；不依赖另一个 ID 的 DDR 是否排空。仅在 `s_axi.arvalid && s_axi.arready` 时写入描述符、推进指针、增加接受计数。

对非法 Head burst，仍需接收后按原约定生成错误读响应，保留请求 ID、长度和每拍/最终拍语义。不得把无效请求静默丢弃，或错误地转发到 DDR。

Head 地址别名、FIXED/INCR 支持范围、窄访问和跨槽检查以现有实现为兼容基准。合法 AXI burst 不跨 4 KiB；不要用非法压力流量作为正常吞吐验收。

### 5.2 两种计数必须分开

**全局接受计数：**

```text
accepted_total_next = accepted_total
                    + upstream_AR_fire
                    - upstream_RLAST_fire
```

它包括排队中、发射暂存中、目标执行中以及返回缓冲中尚未完成的所有请求。

**按 ID 的已保留/在途计数：**

```text
issued_pending[id]_next = issued_pending[id]
                        + dispatch_reserve_for_this_id
                        - upstream_RLAST_fire_for_this_id
```

`dispatch_reserve` 是描述符从队列交给某个不能丢失的执行/发射暂存级的时刻。DDR AR 在发射寄存级中等待 `m_ddr_axi.arready` 时，也已经占有该 ID 的目标锁。

禁止只在 DDR AR 握手才加锁、却提前弹出请求，让后继同 ID Head 请求从间隙越过。禁止在 DDR RLAST 进入内部返回 FIFO 时解锁；此时上游可能尚未接收最后一拍。

旧的 DDR 物理边界统计计数可继续按 `DDR_AR_fire - DDR_RLAST_fire` 计算，**但它不是新功能目标锁的退休计数**。同周期加减必须统一更新，不用多个覆盖赋值产生漏加/漏减。

### 5.3 目的地锁与可发射条件

每 ID 至少维护：

```text
issued_pending[id]
active_target[id]    # DDR 或 LOCAL（含本地错误响应）
```

队首请求可被调度的必要条件为：

```text
队列非空
且（该 ID 没有已保留/在途请求，或队首目标等于 active_target[id]）
且目标执行/发射暂存级有空间
且相应 credit 可用
```

队列中已接收但未发射的请求不直接增加 `issued_pending`，它们的顺序由同 ID FIFO 保证。最后一笔退休与新笔保留同周期时，必须显式处理锁的保持/转换；保守多等一拍可以接受，越序不可以接受。

不同 ID 之间采用有界公平仲裁。只在实际 dispatch reserve 成功后推进轮询状态；不要将另一个 ID 的无关未完成请求纳入 Head 必须等待的条件。

### 5.4 AR 发射与 Head 执行独立

DDR AR 输出必须带保留寄存级。`ARVALID=1 && ARREADY=0` 期间，全部 AR 字段保持稳定，不能随下一轮轮询结果改变。

DDR AR 暂存级已满时，不再向该暂存级塞请求；但若本地执行器可用，其他 ID 的 Head 请求仍可以调度。反过来，本地 Head burst 活跃时，DDR 发射暂存级仍可接受符合顺序条件的 DDR 请求。

不允许重新引入一个 `READ_BUSY` 或单一全局 FSM，使所有目标只能二选一地运行。

### 5.5 R 返回与 burst 锁定

保留当前外部 memory 端口“不交织读 burst”的约定。DDR 与 Head 返回允许跨 ID 的完整 burst 先后变化，但对上游不能在一个 burst 的两个 beat 之间切换到另一个响应 burst。[S10]

R 仲裁规则：

1. 只选择已有可用首拍的响应来源；不要提前锁住一个尚无响应、可能等待其他路径推进的来源。
2. 某来源的首拍一旦在上游呈现 VALID，即使 READY 为 0，也要锁定来源和字段，不能切换。
3. 锁定保持至该 burst 的上游 `RVALID && RREADY && RLAST`。
4. 同 ID 完成顺序由目标锁、同 ID 队列以及 DDR 自身的同 ID 顺序共同保证。
5. 返回 FIFO 入队不等于上游退休。RID、RRESP、RLAST、RDATA 必须一同保存。

DDR endpoint 可跨 ID 重排完整 burst，但必须满足当前协商的不交织约定。若实际生成链路显示不同要求，先按真实端口契约补足转换，不能通过修改 `interleavedId` 声明掩盖实现不一致。

### 5.6 Head URAM 与 PPU 本地读

保持 `head_uram_store.sv` 的单响应同步读接口、WSTRB 语义和无阵列复位结构。读取响应属于 AXI Head 还是 PPU，必须由握手时保存的 owner/bank/半字选择决定，不使用下一拍变化后的请求信号推导归属。[S4]

本轮可保留原有“一个 AXI Head burst 占用本地读执行器”的策略，不强制新增多 Head 流水或按 beat 抢占。必须做到：

- 已接受的 PPU 请求及其响应先正确排空，才能将所需本地读资源转给 AXI Head。
- Head 请求只是因为同 ID DDR 未退休而等待时，不提前永久占住本地读资源，也不因此阻断无关 PPU 请求。
- AXI Head 与 PPU 共用 RAM 响应时，没有重复消费、错 bank、错半字或响应丢失。
- 同步 RAM 读是不可撤销的，发起前为返回数据和 owner 标签保留空间；不能只看返回 FIFO 当前 count 而漏算 pending read。
- Head burst 结束与下一个 PPU/Head 接管的边界需要定向测试。

保留 slot publication/lease 约束；本轮不改变同一地址同时读写的架构定义，也不在 RTL 中假设未初始化 URAM 为零。

### 5.7 复位、稳定性与时序

复位清除队列有效位、指针、功能 credit、目标锁、返回 valid 与 owner；不复位 Head 数据数组。现有系统要求的共同复位边界不变：本轮不宣称支持 DDR 仍有旧响应时单独复位 router。

新增队列使用寄存边界，禁止把 `RREADY` 组合传播到 AR 准入或整条目的地仲裁链。两项返回缓冲应能在稳定流水后每周期传递一拍；满状态恢复允许保守气泡，不通过组合 ready 链换取指标。

不要注册整个 512-bit 深 payload 阵列，也不要把 URAM 读口改成异步多路选择。局部综合必须检查 URAM 推断没有消失。

### 5.8 H1 功能断言

至少覆盖：接受/完成守恒；FIFO 指针与 count 边界；`issued_pending` 不下溢；同 ID 目标一致；稳定 VALID 的 payload 稳定；RLAST 与 burst 拍数匹配；没有未接收请求的响应；单响应只消费一次；每个 ID FIFO 不越序。

`ARLEN+1` 的计算需至少 9 位，能表示 256 拍。源代码中不采用会将 255+1 截断为 0 的表达式。

## 6. L1：L2 secondary 共享池独立扩容

### 6.1 本轮具体修改

当前 Scheduler 使用：

```scala
new RegisteredListBuffer(
  ListBufferParameters(new QueuedRequest(params),
    3 * params.mshrs, params.secondary, false))
```

每 bank 的 `params.mshrs=34`，故逻辑队列数为 102。当前物理 payload 容量为 34 项，四项同步读返回 credit 是另一个容量，不是 102 份深队列。[S5；S6；S9]

本次目标：

```text
逻辑队列       102 → 102
payload 容量    34 → 68（每 bank）
普通 MSHR       32 → 32（每 bank）
一致性 MSHR      2 → 2（每 bank）
读响应 credit    4 → 4
cache 数据容量 512 KiB → 512 KiB（两个 bank 合计）
```

作用边界是承接更多已被 set 所有权约束的 secondary 请求，减少共享池先满带来的入口反压。**不宣称提高每 set 的服务并行度、不宣称减少缓存 miss、不宣称解决 tag1 的全部延长。**

### 6.2 参数必须与 `memCycles` 分离

当前参数文件中：

```scala
val secondary = max(mshrs, micro.memCycles - mshrs)
```

`memCycles` 还参与 MSHR、putLists、putBeats 等资源计算。不得为得到 68 项而直接把 `memCycles=64` 翻倍。[S7]

在当前 V3 overlay 下新增 `Parameters.scala` 覆盖文件，以冻结 reference 的同名文件为基线，仅增加本次必要参数。不要修改 `hw/soc/source/shell/reference/.../Parameters.scala` 原文件。

参数方案如下，字段名允许按仓库命名风格微调，但语义不变：

```scala
// 在 InclusiveCacheParams 和 InclusiveCacheMicroParameters 的末尾追加：
secondaryEntries: Option[Int] = None

// 在 InclusiveCacheParameters 中使用：
val secondary = micro.secondaryEntries.getOrElse(
  max(mshrs, micro.memCycles - mshrs))
require(secondary >= mshrs)
```

将 `Configs.scala` 中 `InclusiveCacheParams` 的读取/解构、构造 `InclusiveCacheMicroParameters` 的路径完整接通；默认 `None` 保持其他配置的旧行为。在当前 `WithMemoryParallelV3` 的 `.copy(...)` 中设置：

```scala
secondaryEntries = Some(68)
```

保留 `memCycles=64`、`sets=512`、`ways=8` 与原 bank mask。检查所有实际生效源码中的构造和模式匹配，防止 case class 增字段后只修改一个构造点、遗漏解构点。

本轮不新增 response credit 配置，不顺便改变其他缓存微架构参数。

### 6.3 保留 RegisteredListBuffer 的时序安全结构

保留：

```text
SyncReadMem payload
窄 head/tail/next 指针
4-entry responses Queue
pending read 纳入 credit 计算
同步 pop → RAM 返回 → result → MSHR reload
```

不要恢复异步 payload mux、`peekOH` 或组合 retire-to-reload bypass。当前 `io.push.ready := !used.andR` 及不在“满池同拍 pop”时立即重用释放槽的策略可以保留。**本轮不为消除这一拍气泡引入同址 RAM 读写冲突。**[S6]

若工具要求位宽显式化，只做语义等价的修正；不重写链表算法，不引入新 free-list 架构。

### 6.4 必须检查的位宽与边界

68 项不是 2 的幂。物理 entry 指针需要 7 位，但合法索引只有 0～67；逻辑 queue 索引仍为 7 位，合法范围 0～101。[S6；S13]

必须覆盖：

- entry 33→34、63→64、67，以及逻辑 queue 33、34、67、68、101。
- 空队列 push；单元素队列同时 push/pop；多元素队列头尾变化。
- 同队列与不同队列的同时 push/pop。
- 共享池全满后的 pop、下一拍再 push，以及在途同步返回。
- `used`、`UIntToOH`、`PriorityEncoder` 的有效宽度，非法索引不得参与 RAM 访问。
- 返回队列受反压且 pending read 已占 credit，不能溢出不可撤销的同步读返回。

不要误把 102 个逻辑队列改成 204，也不要把 `3*params.mshrs` 改成 `3*params.secondary`。

### 6.5 Scheduler / MSHR 的受保护逻辑

当前 set 匹配按 `status.set`，不是完整 cache line 地址；同步 reload 阶段通过 `reloadReserved` / `awaiting_reload` 保留 set 所有权。当前 same-tag reload 也重新查询目录，`repeat := false`。[S5]

以下部分保持原样，除非自动回归证明扩容适配需要局部修正：

```text
setMatches / alloc / queue / nestB / nestC
prioFilter 与 B/C 优先级
winner 注册与提交时重验
reloadWaiting / reloadReadFilter
preferReload 与目录分配仲裁
reloadReserved / awaiting_reload
repeat := false
```

本轮不要试图让同 set 的不同 tag 同时获得多个普通 MSHR，不释放尚未 reload 完成的 set，不把“有空闲 MSHR”当成可以绕过 set 所有权的理由。

三路 Head 同偏移在现有地址布局下可能竞争同 bank/set，是此前源码分析的候选原因；**本文不把该推断升级为已测主因，也不据此修改 bank/set 映射**。

### 6.6 L1 的物理实现边界

payload 额外容量为每 bank `34 × P` bit，其中 P 是生成后的 `QueuedRequest` 宽度；两 bank 合计 `68 × P` bit，另有指针/位图增加。不要在报告中估写固定 BRAM 数量，必须读取实际综合结果。

重点检查 68 位空闲编码、指针读写和 Scheduler 入口路径是否成为新的时序瓶颈。保留同步 payload 存储，不允许把整个 payload 变成组合选择的大型寄存器阵列。

若 L1 导致不可接受的实现问题，先做局部等价时序修复；仍未通过时保留 H1、独立回退 L1 至 34，并如实记录 L1 未交付。不得通过减少 MSHR、修改 cache 容量或添加时序豁免掩盖问题。

---

## 7. 统计与 ABI：不让观测改动拖累功能交付

本轮不建立新的软件诊断模式，不修改 MPV3 块数或软件可见寄存器布局。保持当前 ABI 1.1 与现有计数槽位的原始事件定义；验证新行为所需的详细计数优先放在 testbench / bind monitor 中。

**特别注意 Head 旧计数：**旧事件包含“当前入口呈现 Head AR 且 DDR pending 非零”的原始条件。新请求可能已经进入内部 FIFO，旧计数下降不一定表示等待消失，只可能是等待位置变化。[S1 §11、§17；S3]

因此：

- 不把旧 Head 排空计数下降作为本次单独的性能验收。
- 维持旧原始条件时，在新验证文档中明确其兼容性含义；不要悄悄换成新事件而仍称旧 ABI 完全同义。
- 需要真正的 queued wait、per-ID wait、不同目标重叠等指标时，在仿真监视器独立输出。
- 原统计 CLEAR/STOP 不得清除新功能计数、队列、目标锁或在途事务。
- 不为仪表化引入跨 SLR 的高扇出时序路径。

建议 testbench 输出：

```text
H1: accepted/completed、各 ID 队列峰值、各 ID pending 峰值
H1: same_id_target_wait、local_wait_while_other_id_ddr_live
H1: local_completion_while_other_id_ddr_live
H1: ddr_ar_while_local_active、ddr_r_stall、local_r_stall
L1: accepted/result、payload_peak、pool_full、response_credit_stall
L1: 每队列参考模型深度、总池占用、各类同步 push/pop 覆盖
```

这些是离线机制验证指标，不是新的板测成绩。

---

## 8. 自动验证：Codex 必须执行，不交给用户人工循环

### 8.1 验证策略

先运行局部实际 RTL 的测试，再做集成回归，最后只对通过的 H1+L1 候选进行一次完整物理实现。允许用旧版参数做局部仿真对照，不要求用户再生成/下载多个板测比特流。

Python 参考模型可以作为 scoreboard，但不能仅运行一份 Python 算法模型就声称硬件测试通过。必须驱动修改后的 SystemVerilog / Chisel 生成 RTL。

现有 V33、前端、PPU、TensorIngress 与 V3 时序修复测试入口应继续使用；V26 Runtime 测试不能替代当前 V33 ABI 的验收。[S11]

### 8.2 新增测试入口

建议新增以下路径；这些路径是**待实现交付项**，不是声称仓库已经存在：

```text
tests/rtl/head_l2_urgent/
    README.md
    run_tests.py
    tb_head_router_ordering.sv
    tb_head_router_progress.sv
    test_registered_secondary_pool.py
    test_l2_secondary_integration.py
```

可沿用现有测试工具组织方式，不强制为了文件名另造框架。为 `Makefile` 新增：

```text
make test-head-read-decouple
make test-l2-secondary-capacity SOC_WORKSPACE=<当前新生成工作区>
make test-head-l2-urgent SOC_WORKSPACE=<当前新生成工作区>
```

聚合入口必须传播失败码，输出 JSON/文本摘要和日志路径；固定随机种子，可重复运行。缺关键工具返回 BLOCKED，不伪装成通过。

### 8.3 H1 必测场景

| 编号 | 场景 | 硬性判断 |
| --- | --- | --- |
| H01 | 纯 DDR、多笔同 ID、32 笔在途 | 不退化为一次一笔；数据和顺序正确，稳定无反压流下可持续发射 |
| H02 | ID0 DDR 长延迟；ID1 Head | ID1 Head 能在 ID0 DDR 尚未向上游完成时完成；旧版不能做到这一点 |
| H03 | ID0 旧 DDR；ID0 Head；ID0 新 DDR | 保持上述顺序；新 DDR 不越过同 ID Head |
| H04 | 一个 ID 的 Head 等待其旧 DDR；另一个 ID 持续请求 | 在资源可用时，另一 ID 请求继续发射，不能被统一队首堵住 |
| H05 | Head 本地 burst 活跃；其他 ID DDR AR | DDR AR 继续握手，不受本地读 FSM 全局冻结 |
| H06 | DDR 与 Head 同时有 RVALID，上游 RREADY 随机反压 | payload 稳定、按完整 burst 仲裁、没有丢拍/重拍/交织 |
| H07 | DDR 跨 ID 重排完整 burst | RID、同 ID 顺序与终拍正确；不依赖全局按 AR 顺序返回 |
| H08 | PPU 已接受请求、随后 Head 接管；不同 bank/上下半字 | 响应归属正确，原本地端口语义不变 |
| H09 | FIXED/INCR、窄访问、有效边界与非法 Head 请求 | 合法访问数据正确；非法访问按原错误契约完整返回 |
| H10 | 各队列满、全局 credit 满、同周期接受/退休 | 无溢出、下溢、credit 丢失，解除反压后全部排空 |
| H11 | 复位与空闲恢复 | 只测试系统支持的共同复位；无幽灵响应、不清除 URAM 数据数组 |
| H12 | 读写混合、WSTRB 部分写、shadow / legacy 模式 | 原写行为与回退模式正确，不能因读优化破坏 publication/写完成 |

H02 的确定性示例：预写 Head 数据，发出一个 ID0 的 DDR 读，将其合法返回延迟人为拉长；随后发出 ID1 的 Head 读，上游 RREADY 保持 1。scoreboard 必须观察到 **Head 完成时 ID0 仍有未退休读**。只看到 Head AR 提前进入 FIFO 不算通过。

H04 的确定性示例：保持 ID0 的旧 DDR 读未完成，把 ID0 Head 请求送入内部队列，再发 ID1 DDR 请求。下游可接受且 credit 足够时，ID1 DDR AR 应在 ID0 旧事务退休之前握手。

旧版和新版比较采用“每 ID 的有序响应内容 + 完成守恒”，不比较全局响应顺序或逐周期完全一致，因为跨 ID 并行是本次预期改变。

固定随机回归建议至少 5 个种子、每种子 10,000 笔混合合法请求；对极端边界使用定向测试。仿真若因容量或环境需要分批，应保留累计请求数、种子与覆盖情况，不虚报运行量。

### 8.4 L1 必测场景

对 `queues=102`、`entries=34/68` 的实际 `RegisteredListBuffer` 分别运行参考模型校验。至少验证：

| 编号 | 场景 | 硬性判断 |
| --- | --- | --- |
| L01 | 不 pop，连续入队至满 | 34/68 配置分别恰好容纳 34/68 条；下一条反压，无覆盖 |
| L02 | 所有逻辑 queue 索引与物理 entry 边界 | 无截断、别名和越界，包含 index101、entry67 |
| L03 | 随机 push/pop/result.ready | result 的队列身份与数据按该队列 FIFO 顺序一致 |
| L04 | 同 queue 最后一个元素同时 push/pop | 新头尾正确，不丢新元素，不重复旧元素 |
| L05 | 多元素同 queue、不同 queue 并发 | 链表连接和空闲位图守恒 |
| L06 | result 长时间不 ready，同步读已经 pending | credit 计入 pending，响应不丢失，最终能够排空 |
| L07 | 满池 pop 后重新分配 | 不发生同拍释放槽不安全复用，无同步 RAM 同址冲突 |
| L08 | 真实双 bank L2，same-set 请求与 reload | 接受/返回守恒，set 所有权不丢，新增条目最终全部退休 |
| L09 | 原 V3 reload/目录/一致性回归 | 原测试不删减，B/C 嵌套、写回与 reload 正确 |

随机回归建议至少 5 个种子、每种子 20,000 个周期，并在结束时停止 push、解除反压，排空全部结果，与参考队列逐条匹配。

L01 证明的是**新增缓冲容量确实可用**，不是整网吞吐提高。L08/L09 才是与现有 cache 协议连接后的必要检查。

### 8.5 必须执行的集成检查

在正确重建工作区后，执行已有入口，并保存各自真实结果：

```bash
make test-memory-v3
make test-cache
make test-ppu
make test-tensor-ingress SOC_WORKSPACE="$SOC_WORKSPACE"
make test-v3-timing-repair SOC_WORKSPACE="$SOC_WORKSPACE"
make test-frontend SOC_WORKSPACE="$SOC_WORKSPACE"
make test-v33
```

执行者先核对当前 Makefile / 测试脚本的实际依赖。不要把命令名不存在、工具缺失、测试内部 SKIP 或旧 assembly 被复用的情况记录为 PASS。

若某个旧测试只断言“Head 必须全局等待”，应将该时序断言限定到 legacy 模式；保留其数据、顺序、反压和错误检查，并给优化模式增加新行为测试。不能简单删除整条测试。

---

## 9. 更新结构检查与生成溯源

当前 `tools/check/check_triple32_v3_tensor.py` 显式检查 `RegisteredListBuffer_q102_e34` 及 payload 深度 34。这是需要同步修改的真实检查点，而不是可以绕开的构建障碍。[S9]

候选版本必须检查：

```text
两个 L2 bank
每 bank 34 个 MSHR 实例（32 普通 + 2 一致性）
RegisteredListBuffer 的 queues=102、entries=68
payload 为深度 68 的同步 1R1W 存储
4 个返回 credit 与 pending read 保留
winner / reloadWaiting / reloadReadFilter 保留
awaiting_reload / reloadReserved 保留
没有组合 peekOH payload bypass
原 cache 几何、地址位与总容量不变
SoC memory=512/ID2、Tensor=256/ID5、Gemmini=3×32
生产 bridge 的 Head READ_DECOUPLE 实際开启
MPV3 ABI1.1 和前端 ABI 不变
```

允许结构检查从单一 manifest 读取预期 secondary 深度，或提供明确的测试期 `--expected-secondary-entries`。**生产检查不能写成“34 或 68 都算通过”**，否则旧 RTL 混入时无法发现。

当前产品的准确值为 68；legacy 局部测试显式使用 34。不要只在 console PASS 字符串中写 68，却没有检查生成内存和真实例化。

重新生成必须使用新建私有 Chipyard 工作区或通过源码一致性校验的当前工作区。旧 `--resume` / `--emit-core-only` 不会自动更新 assembly；必须让 Scala 编译结果与 overlay 摘要吻合。[S8]

交付清单记录：基线提交、修改文件 SHA256、实际生效 Scala 摘要、生成 RTL SHA256、参数头摘要、测试源码摘要，以及产生 bitstream 时的 bitstream SHA256。不得把本地文件摘要当成 FPGA 已加载文件指纹。

---

## 10. Codex 的执行顺序

### C0：确认基线，不重做性能研究

读取仓库 `AGENTS.md`、当前 manifest、相关源码与本规范。记录 `git status` 和 HEAD；保护已有未提交修改，不执行 `git reset --hard`、不覆盖用户文件。

若工作区 HEAD 已前进，核对相关文件差异并在实际 HEAD 上落实相同契约，不强行回退到本文提交。报告中记录实际基线和相对本文的差异。除结构确实不兼容外，不向用户索要新的性能日志。

检查现有 Vivado/Scala/仿真器路径和兼容 Chipyard reference。使用项目已有工具配置，不假定私人服务器路径。不要改动共享 reference，也不要终止正在运行的 Vivado 任务。

### C1：先形成 H1 可验证提交

实现按 ID 描述符队列、目的地锁、独立 DDR AR 发射级、本地执行与 R 仲裁；保留 legacy/shadow 和写路径。完成 H01～H12、局部回归与 lint 后形成独立提交/补丁。

不要先重建整套 SoC 来验证手写 Head router；用局部仿真快速排除协议问题。

### C2：形成 L1 参数化与扩容提交

新增独立 secondary 参数，完成 68 项配置、位宽检查、结构检查适配、L01～L07。保留 MSHR、Scheduler 与返回 credit 的算法。形成独立提交/补丁。

### C3：重建一次集成 SoC

在环境已确定路径后，使用项目真实入口：

```bash
python3 tools/soc/build_triple32_v3_tensor.py \
  --reference "$SOC_REFERENCE" \
  --workspace "$SOC_WORKSPACE"
```

`SOC_WORKSPACE` 必须是为当前任务准备的私有目录，不等于 reference，也不位于 reference 内。并发与 JVM 内存使用项目配置并结合实际可用资源限制，避免同时启动多份全量 SBT/Vivado 构建。

确认 H1 和 L1 都进入生产源清单及生成产物，执行 §8.5 的集成回归与 L08/L09。

### C4：运行离线验收流水线

新增聚合脚本或 Make 入口，依次执行新测试、必要旧测试、结构检查、局部综合。输出结果 JSON、文本汇总、命令和日志文件。

`make check` 不通过时修正真实 manifest / 源码 / 生成不一致；不得禁用检查。当前视频 Runtime 不在任务范围，禁止通过解除 `make firmware` 的 ABI 阻断让旧固件看似可用。

### C5：在工具与资源具备时完成一次候选实现

局部与集成测试通过后，执行：

```bash
make project
make elaborate
make bitstream
```

这是对**一个集成候选版本**的完整构建，不要求逐项生成多个比特流做用户板测。沿用项目构建锁；当前有别的实现运行时，不杀进程、不并行占用同一工程，记录资源占用状态。

若现有环境不具备完整工具/许可证/资源，交付完成的源码、自动测试、生成产物和准确的 BLOCKED 记录，不伪造综合或实现成绩。

### C6：交付与停止条件

交付代码/补丁、文档、报告、可用的生成产物；环境具备且最终时序通过时交付候选 bitstream。**不自动下载或烧写，不要求用户再跑一组诊断才结束任务。**

不得在构建失败后悄悄调用允许负 setup 时序的旧实验脚本导出“通过版”。失败产物不能替换已知基线。

---

## 11. 时序、功能与性能的验收分层

| 层级 | 通过条件 | 不能推导的结论 |
| --- | --- | --- |
| A：源码与结构 | 参数与实际例化吻合，生产路径生效，关键契约不变 | 不代表 RTL 功能正确 |
| B：局部 RTL | H/L 定向与随机测试通过，无顺序/数据/credit 错误 | 不代表完整 SoC 正确 |
| C：集成回归 | 实际双 bank L2、前端、PPU、Tensor 与 V33 自动回归通过 | 不代表 FPGA 已上板 |
| D：物理实现 | 完整 route 完成；setup/hold、CDC/bus-skew 等既有门禁通过 | 不代表推理 FPS 已提高 |
| E：板测 | 本任务不要求执行，标记 NOT_RUN | 不能宣称达到 2.8×/3× 或节省某个百分比 |

最终实现保持 100 MHz 目标。至少记录最终 WNS/TNS、WHS/THS、route status、未约束路径/相关 CDC 与 bus-skew 结果、LUT/FF/BRAM/URAM/DSP 使用。OOC WNS 只能用于局部判断，不能替代完整布局布线结果。

H1 的最低机制验收是“其他 ID DDR 尚未退休时，Head 已经完成”以及“Head 活跃时 DDR AR 仍推进”；L1 的最低机制验收是“68 项容量真实生效且保持同步返回和 cache 协议正确”。不能以计数器变小、代码减少、插入 FIFO 或软件返回更快代替这些验收。

没有新板测，报告必须保留：

```text
BOARD_RUN=NOT_RUN
MODEL_THROUGHPUT=NOT_MEASURED
SPEEDUP_2P8_OR_3P0=NOT_CLAIMED
```

这不阻止提交硬件候选版本，但禁止将候选命名为“已上板验证的性能提升版”。

---

## 12. 回退与故障处理

### 12.1 独立回退

| 项目 | 回退方式 | 不允许的回退 |
| --- | --- | --- |
| H1 | 生产 bridge 将 `READ_DECOUPLE` 设回 0，重新构建；或回退 H1 独立提交 | 改回旧 v26 前端/软件 ABI |
| L1 | secondaryEntries 显式改回 34，同步检查预期并重新生成；或回退 L1 独立提交 | 仅替换生成 RTL、不改 Scala / manifest |
| 全候选 | 通过 Git 与产物摘要恢复任务前基线 | 覆盖用户无关修改、删除唯一已知可用 bitstream |

只在自动验证证明某项未通过时隔离它。不得因为没有用户板测就默认不实施两项功能，也不得因为希望“两项全开”而忽略失败。

### 12.2 常见失败必须如何处理

**旧 e34 RTL 仍被使用：**检查 V3 overlay、command frontend integration 的覆盖顺序、私有工作区与 assembly 来源。重新生成，不将检查改成兼容 e34/e68 任意值。

**Head 同 ID 越序：**检查锁的分配时刻是否晚于 FIFO pop，以及是否在内部 R FIFO 入队时提前解锁。修复后重跑同 ID 跨目标与 RREADY 反压测试。

**H1 仍全局阻塞：**检查共享 read FSM、DDR 发射暂存级和本地执行器是否仍共用全局 busy；检查 Head 等待是否只是从接口转移到单一队首。

**L1 队列别名/掉数据：**检查 68 项的 7 位物理指针、queue index101、pending read credit，以及 full-pop/last-element 并发边界。不要用扩大 timeout 掩盖未退休请求。

**仿真通过而 URAM 推断消失：**恢复 reset-free RAM 数据路径和单独 valid/owner 控制；不接受大量寄存器替代 Head URAM。

**时序不通过：**定位新增控制或回压路径，做注册化等价修复；不能关闭 timing check、扩大时钟周期或添加覆盖全通路的 false path。

---

## 13. 必须交付的文件与最终摘要

建议新增/更新：

```text
docs/architecture/head-l2-urgent.md
    最终实际实现、参数、握手/所有权、回退与本规范差异。

docs/validation/head-l2-urgent.md
    已执行命令、真实结果、日志路径、限制、未运行项目。

tests/rtl/head_l2_urgent/
    可本地重复运行的实际 RTL 测试与 README。

build/reports/head_l2_urgent/
    implementation_manifest.json
    validation_results.json
    validation_summary.txt
    head_progress_comparison.json
    l2_capacity_comparison.json
    logs/...
```

报告目录沿用仓库忽略规则；不要把大型 waveform、临时工作区、工具缓存全量提交。将必要的小型验收摘要和复现命令保存在可审阅文档中。

`implementation_manifest.json` 至少记录：实际起始/结束提交或 patch 摘要、H1 启用状态、L1 实际深度、所有保持不变的核心规格、有效源码/RTL 摘要、环境工具版本、测试日志摘要、bitstream 摘要（若实际生成）、未上板状态。

`validation_results.json` 每个任务包含：`command`、`status`、`exit_code`（未执行时为 null）、`log`、`reason`、`source_fingerprint`。状态使用 PASS / FAIL / BLOCKED / NOT_RUN，不把关键测试的 SKIP 汇总成 PASS。

Codex 最终回复按以下内容报告，不重复要求用户诊断：

```text
实际基线：...
H1：已实现/已隔离，生产 READ_DECOUPLE=...
L1：已实现/已隔离，实际 secondary entries=...
保持不变：MSHR=32+2/bank，bank=2，L2=512KiB，SoC=100MHz，软件 ABI=...
自动测试：哪些 PASS，哪些 FAIL/BLOCKED/NOT_RUN，附路径
RTL：是否真实重新生成，产物与摘要路径
实现：是否完成，最终 setup/hold/route/bus-skew 结果或未运行原因
候选 bitstream：路径与 SHA256；未生成则明确写未生成
上板：NOT_RUN；没有宣称整网性能提升
回退：H1/L1 独立提交或精确补丁/参数恢复步骤
```

### 可直接交给 Codex 的启动指令

> 请在 `Cc-aw/sixteen_camera` 当前工作区按本文件实施 H1 + L1。不要停留在分析或重新列候选方案，也不要要求我先进行新一轮板测。H1 实现按 ID 保序的 Head 读路径解耦，保留写路径及 shadow/legacy；L1 独立参数化并将每 bank secondary pool 从 34 扩至 68，保持 32+2 个 MSHR、102 个逻辑队列、4 项返回 credit、两 bank、512KiB 与现有 reload/set 所有权机制不变。完成实际 RTL 定向/随机测试、生成溯源和现有集成回归；环境具备时完成一个候选版本的完整综合布局布线。不要下载 FPGA 或固件，不改模型、golden 和软件 ABI。分别保留 H1/L1 回退，输出实际完成状态与日志，未执行的项目明确标记，不宣称尚未测得的上板收益。

---

## 14. 依据与可追溯来源

### 14.1 来源分层

**[S1] 用户报告**：`frontend_v34_parallelism_memory_analysis.md`，标题《三路 Gemmini32 自主前端 v34：并行度与访存瓶颈诊断报告》。本文使用其 §2～§3、§7～§11、§17；报告没有提供本次新硬件的实测数据。

下列仓库文件均以提交 `3440bc10a15467f7ba42bb2ffac21a343e1956d6` 为核对基线，不依赖随时间变化的 `main` 内容。相对路径可在该提交中定位：

| 编号 | 文件 / 位置 | 本文使用的内容 |
| --- | --- | --- |
| S2 | `hw/manifests/current.json`；`docs/architecture/hardware.md`；`docs/integration/triple32-v3-tensor.md` | 产品身份、总线/cache 规格、V33/Runtime 边界 |
| S3 | `hw/rtl/ai/postprocess/axi4_head_uram_router_v3.sv`；`hw/rtl/memory/postprocess_memory_bridge_v3.sv` | 当前全局排空、生产实例、Head/DDR 返回控制 |
| S4 | `hw/rtl/ai/postprocess/head_uram_store.sv` | 同步读、部分写、单响应和 URAM 无数据复位要求 |
| S5 | `CACHE_OVERLAY/Scheduler.scala`；`CACHE_OVERLAY/MSHR.scala` | set 级匹配、secondary 入队、winner/reload、set 所有权 |
| S6 | `CACHE_OVERLAY/RegisteredListBuffer.scala` | SyncReadMem、共享 entry、4-credit 返回、pending read |
| S7 | `hw/soc/source/shell/reference/generators/rocket-chip-inclusive-cache/design/craft/inclusivecache/src/Parameters.scala`；`CACHE_OVERLAY/Configs.scala`；`hw/soc/source/shell/memory_parallel_v3/scala/MemoryParallelV3.scala` | secondary 默认公式、memCycles 关联资源、参数传递与配置 |
| S8 | `tools/soc/build_triple32_v3_tensor.py` | reference/overlay/前端覆盖顺序、工作区校验、生成与摘要 |
| S9 | `tools/check/check_triple32_v3_tensor.py` | e34/depth34 固定断言、34 MSHR、cache 几何与 ABI1.1 检查 |
| S10 | `hw/soc/source/shell/reference/generators/rocket-chip/src/main/scala/subsystem/Ports.scala` | TL→AXI/ID 转换与不交织返回声明 |
| S11 | `tests/README.md`；`Makefile` | V33、前端、PPU、Tensor、V3 测试与构建入口 |
| S13 | `CACHE_OVERLAY/ListBuffer.scala`，`ListBufferParameters` | queueBits/entryBits 的参数化定义 |

`CACHE_OVERLAY` 的完整展开见 §3.2。本规范中的新文件、新 Make 目标、新参数和 68 项选择均是待实施设计，不属于这些来源中的既有功能。

### 14.2 外部协议核对

**[S12] AMD 官方 AXI 文档**：`Use of ID Signals` 与 `Avoiding Deadlock Using Single Slave Per ID`。只用于核对同 ID 的返回顺序、不同 ID 的并行以及按 ID 限制活跃目标的设计原则；不把 SmartConnect 产品实现等同于本项目手写 router。

供执行者核对的定位地址：

```text
https://docs.amd.com/r/en-US/pg247-smartconnect/Use-of-ID-Signals
https://docs.amd.com/r/en-US/pg059-axi-interconnect/Avoiding-Deadlock-Using-Single-Slave-Per-ID
https://github.com/Cc-aw/sixteen_camera/tree/3440bc10a15467f7ba42bb2ffac21a343e1956d6
```

**最终边界：本任务交付有功能与物理实现证据支撑的硬件候选，不将“没有时间继续板测”解释为可以跳过正确性验证，也不把局部仿真效果写成整网性能成绩。**
