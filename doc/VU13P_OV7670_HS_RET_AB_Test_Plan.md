# VU13P + ATK-FMC-EXTIO + OV7670  
# `HS ↔ RET` A/B 测试方案

## 1. 测试目的

当前现象不是“固定某个摄像头一定坏”，而是：

- 1~2 路摄像头时通常比较正常；
- 接到 3 路以后明显更容易不稳定；
- CAM2 / CAM3 整体比 CAM0 / CAM1 更稳定；
- 日志中有些异常通道仍能得到接近正确的 `1280 byte/line`，但 `frame lines` 明显错误；
- CAM3 在 FMC1 / FMC2 上都表现出非常好的 `geometry=0x01E00500`，且 `malformed` 极低。

因此提出一个待验证假设：

> **CAM0 / CAM1 / CAM2 当前把 `VS` 和 `HS/HREF` 放在同一组 FMC P/N 物理对上，可能使 HREF 的频繁翻转通过相邻走线、电平转换器、杜邦线和地弹等方式干扰 VS，造成 VS 毛刺或假边沿。**

这不是已经确认的结论。

本 A/B 测试的目标就是：

> **只改变 “HS 与 VS 是否处在同一 P/N 对” 这一项，其他所有条件保持不变，看稳定性是否显著变化。**

为了让变量最少，第一轮只测试 **CAM0**。

---

# 2. 为什么先选择 CAM0

CAM0 当前分配：

```text
VS   → LA20_P
HS   → LA20_N

RET  → LA23_P
SCL  → LA23_N
```

所以当前结构是：

```text
LA20_P/N
├── VS
└── HS       ← 两个视频时序信号紧邻

LA23_P/N
├── RET
└── SCL
```

其中：

- `VS`：每帧变化一次，应该非常安静；
- `HS/HREF`：每一行都会变化，活动频率远高于 VS；
- `RET/RESET`：摄像头初始化后基本保持静态；
- `SCL`：完成 SCCB 初始化后也基本保持静态。

因此 B 组只交换：

```text
HS ↔ RET
```

变成：

```text
LA20_P/N
├── VS
└── RET      ← 初始化后基本静态

LA23_P/N
├── HS
└── SCL      ← SCL初始化完成后基本静态
```

这样就把：

```text
VS + HS
```

拆开了。

---

# 3. A 组：保持当前接法

A 组是基准组，**不要修改任何接线和 XDC**。

CAM0 当前接法：

| OV7670 | EXTIO | VU13P FMC1 PACKAGE_PIN |
|---|---|---|
| VS | `LA20_P` | `H15` |
| HS/HREF | `LA20_N` | `H14` |
| RET/RESET | `LA23_P` | `C13` |
| SCL | `LA23_N` | `B13` |

关键结构：

```text
LA20_P → VS
LA20_N → HS

LA23_P → RET
LA23_N → SCL
```

A 组 XDC 保持：

```tcl
set_property PACKAGE_PIN H15 [get_ports {cam0_vsync}]
set_property IOSTANDARD LVCMOS18 [get_ports {cam0_vsync}]

set_property PACKAGE_PIN H14 [get_ports {cam0_href}]
set_property IOSTANDARD LVCMOS18 [get_ports {cam0_href}]

set_property PACKAGE_PIN C13 [get_ports {cam0_reset}]
set_property IOSTANDARD LVCMOS18 [get_ports {cam0_reset}]

set_property PACKAGE_PIN B13 [get_ports {cam0_scl}]
set_property IOSTANDARD LVCMOS18 [get_ports {cam0_scl}]
```

---

# 4. B 组：只交换 CAM0 的 HS 与 RET

## 4.1 物理接线变化

A 组：

```text
CAM0 HS  → LA20_N
CAM0 RET → LA23_P
```

B 组：

```text
CAM0 HS  → LA23_P
CAM0 RET → LA20_N
```

只有这两根线交换。

其他 CAM0 信号全部不动：

```text
3.3V
DGND
SCL
SDA
VS
PLK
XLK
D0~D7
PWDH
```

全部保持原接法。

---

## 4.2 B 组最终结构

```text
LA20_P → CAM0 VS
LA20_N → CAM0 RET

LA23_P → CAM0 HS
LA23_N → CAM0 SCL
```

也就是：

```text
             B组

LA20_P ───────── VS
LA20_N ───────── RET

LA23_P ───────── HS
LA23_N ───────── SCL
```

---

# 5. B 组必须同步修改 XDC

注意：

> **只交换杜邦线但不改 XDC 是错误的。**

因为 FPGA 顶层端口仍然叫：

```text
cam0_href
cam0_reset
```

所以交换物理线以后，需要把这两个端口的 `PACKAGE_PIN` 对调。

A 组：

```tcl
cam0_href  → H14
cam0_reset → C13
```

B 组改成：

```tcl
cam0_href  → C13
cam0_reset → H14
```

完整修改如下。

### A 组原 XDC

```tcl
set_property PACKAGE_PIN H14 [get_ports {cam0_href}]
set_property IOSTANDARD LVCMOS18 [get_ports {cam0_href}]

set_property PACKAGE_PIN C13 [get_ports {cam0_reset}]
set_property IOSTANDARD LVCMOS18 [get_ports {cam0_reset}]
```

### B 组新 XDC

```tcl
set_property PACKAGE_PIN C13 [get_ports {cam0_href}]
set_property IOSTANDARD LVCMOS18 [get_ports {cam0_href}]

set_property PACKAGE_PIN H14 [get_ports {cam0_reset}]
set_property IOSTANDARD LVCMOS18 [get_ports {cam0_reset}]
```

以下两个保持不变：

```tcl
set_property PACKAGE_PIN H15 [get_ports {cam0_vsync}]
set_property IOSTANDARD LVCMOS18 [get_ports {cam0_vsync}]

set_property PACKAGE_PIN B13 [get_ports {cam0_scl}]
set_property IOSTANDARD LVCMOS18 [get_ports {cam0_scl}]
```

---

# 6. RTL 是否需要修改

正常情况下：

> **不需要修改 RTL。**

因为 RTL 仍然使用：

```text
cam0_vsync
cam0_href
cam0_reset
cam0_scl
```

我们只是改变了这些逻辑信号最终绑定到哪个 FPGA PACKAGE_PIN。

所以 B 组建议只做：

```text
修改两根杜邦线
+
交换 XDC 中 cam0_href / cam0_reset 的 PACKAGE_PIN
+
重新综合 / Implementation / Bitstream
```

不要同时：

- 改 OV7670 寄存器；
- 改 XCLK；
- 改 PCLK；
- 改图像格式；
- 改 FIFO；
- 改 DDR；
- 改 HDMI；
- 改 SCCB 时序。

否则 A/B 测试失去意义。

---

# 7. 测试前的硬件操作要求

所有换线都必须：

```text
P15/VU13P 完全断电
↓
确认板卡电源 LED 熄灭
↓
交换杜邦线
↓
再次核对
↓
上电
```

严禁带电拔插：

```text
3.3V
GND
RET
HS
```

尤其不要让 3.3V 误碰到普通 GPIO。

---

# 8. 第一阶段：单 CAM0 A/B

第一轮不要接 3 个摄像头。

只接：

```text
CAM0
```

目的是先确认 B 组本身没有接错。

## A1

使用原始接线 + 原 XDC：

```text
CAM0 单独运行
```

运行固定时间，例如：

```text
30 秒
```

记录一次日志。

## B1

断电后：

```text
交换 HS ↔ RET
```

烧入 B 组 Bitstream，再运行相同时间：

```text
30 秒
```

记录同样日志。

---

# 9. 第二阶段：三摄像头压力 A/B

真正有区分度的是这一阶段，因为当前问题主要在 3 路时暴露。

选择固定组合，例如：

```text
CAM0 + CAM2 + CAM3
```

注意：

> A、B 两组必须使用完全相同的三个摄像头模组、相同线长、相同物理位置。

## A2

```text
CAM0 使用 A 接法
CAM2 不变
CAM3 不变
```

运行：

```text
60 秒
```

保存日志。

## B2

断电。

只对 CAM0：

```text
HS ↔ RET
```

烧入 B 组 Bitstream。

CAM2/CAM3 完全不动。

运行：

```text
60 秒
```

保存日志。

---

# 10. 每轮必须记录的指标

不要只用“肉眼看屏幕稳不稳”。

每轮记录：

```text
PIPE
FB
CAM
```

至少关注以下数据。

## 10.1 geometry

最重要。

对于 640×480、16 bit/pixel：

```text
1280 byte/line
480 line/frame
```

正确 geometry：

```text
0x01E00500
```

拆解：

```text
0x01E0 = 480
0x0500 = 1280
```

所以：

```text
geometry == 0x01E00500
```

是第一优先级判断标准。

---

## 10.2 malformed

第二重要。

观察：

```text
FB CHx written/drop/malformed
```

理想：

```text
malformed ≈ 0
```

例如：

```text
written=200
malformed=0~几次
```

可以认为很好。

如果：

```text
written=2
malformed=50000
```

就是明显异常。

---

## 10.3 written

正常工作时：

```text
written
```

应该持续增加。

如果：

```text
camera frames 很多
但是 written 很少
malformed 很多
```

说明摄像头接口产生了大量不能构成合法 framebuffer frame 的数据。

---

## 10.4 camera_frames / frames

观察是否稳定持续增长。

不要只看最终数值，因为测试持续时间不同会导致绝对值不同。

建议记录：

```text
测试开始
测试结束
```

或者所有实验统一运行 60 秒。

---

## 10.5 overflow

可以记录，但：

> **不要把 overflow 作为本次 A/B 的主要判据。**

因为现有实验中，即使 CAM3：

```text
geometry=0x01E00500
malformed≈1
```

其 CAM overflow 仍然可能很大。

说明目前这个 `overflow` 计数和“输入 DVP 几何是否正确”并不是一一对应关系。

本测试优先看：

```text
geometry
↓
malformed
↓
written
↓
frames
↓
overflow
```

---

# 11. 推荐记录表

每次测试都填一行：

| Test | Cameras | CAM0 wiring | geometry | written | malformed | camera frames | overflow | 肉眼显示 |
|---|---|---|---|---:|---:|---:|---:|---|
| A1 | CAM0 | VS+HS 同对 | | | | | | |
| B1 | CAM0 | VS+RET 同对 | | | | | | |
| A2 | CAM0+2+3 | VS+HS 同对 | | | | | | |
| B2 | CAM0+2+3 | VS+RET 同对 | | | | | | |

测试时间建议：

```text
单路：30 s
三路：60 s
```

如果有条件，每个实验重复：

```text
3 次
```

例如：

```text
A2-1
A2-2
A2-3

B2-1
B2-2
B2-3
```

这样可以避免“这次碰巧正常”的误判。

---

# 12. 如何判断假设是否成立

## 情况 1：B 组明显改善

例如 A2：

```text
geometry = 0x00030500
malformed = 数千/数万
```

而 B2：

```text
geometry = 0x01E00500
malformed ≈ 0
```

并且重复几次都如此。

结论：

> **强烈支持“VS 与 HREF 同 P/N 对会导致不稳定”的假设。**

下一步应重新规划 CAM0/CAM1/CAM2 接线。

---

## 情况 2：A/B 完全没差

例如：

```text
A2 不稳定
B2 也同样不稳定
```

而且 geometry / malformed 基本没有改善。

结论：

> **VS/HREF 同对不是主要原因。**

下一步重点转向：

```text
3.3V供电
GND回流
TXB0108
杜邦线长度
同时翻转噪声
PCLK/Data采样时序
```

此时把两根线恢复原状即可。

---

## 情况 3：B 单路好，但三路仍坏

例如：

```text
A1 正常
B1 正常

A2 很差
B2 仍然很差
```

说明：

> 单纯拆开 VS/HREF 不能解决多路负载问题。

更像：

```text
多路同时翻转
TXB0108驱动能力/边沿问题
供电/地弹
线束串扰
```

---

## 情况 4：B 比 A 有改善，但仍不完全稳定

例如：

```text
A2 malformed = 30000
B2 malformed = 300
```

geometry 也从随机变成大部分时间：

```text
0x01E00500
```

结论：

> VS/HREF 同对很可能是一个重要因素，但系统还有第二个问题。

后续继续：

```text
缩短杜邦线
增加GND
降低PCLK/XCLK
检查3.3V
优化TXB链路
```

---

# 13. 为什么不能只看 ACK

本次测试重点不是 SCCB ACK。

因为需要验证的是：

```text
视频采集阶段
VS / HREF
```

而 SCCB：

```text
SCL / SDA
```

主要在初始化阶段活动。

因此即使 A/B 两组的 SCCB 初始化都一样，本测试仍然可能有明显的视频稳定性差异。

本次最关键的结果是：

```text
geometry
malformed
written
```

---

# 14. 如果 CAM0 A/B 成功，如何扩展到 CAM1

CAM1 当前：

```text
VS   → LA29_P
HS   → LA29_N

RET  → LA31_P
SDA  → LA31_N
```

同样做：

```text
HS ↔ RET
```

B 组变成：

```text
VS   → LA29_P
RET  → LA29_N

HS   → LA31_P
SDA  → LA31_N
```

VU13P FMC1 当前 PACKAGE_PIN：

```text
LA29_P → D11
LA29_N → D10

LA31_P → F14
LA31_N → E14
```

所以 CAM1 B 组 XDC：

```tcl
# VS 不变
set_property PACKAGE_PIN D11 [get_ports {cam1_vsync}]

# HS: D10 -> F14
set_property PACKAGE_PIN F14 [get_ports {cam1_href}]

# RESET: F14 -> D10
set_property PACKAGE_PIN D10 [get_ports {cam1_reset}]

# SDA 不变
set_property PACKAGE_PIN E14 [get_ports {cam1_sda}]
```

---

# 15. 如果 CAM0 A/B 成功，如何扩展到 CAM2

CAM2 当前：

```text
VS   → LA05_N
HS   → LA05_P

SDA  → LA08_N
RET  → LA08_P
```

同样交换：

```text
HS ↔ RET
```

B 组：

```text
VS   → LA05_N
RET  → LA05_P

SDA  → LA08_N
HS   → LA08_P
```

VU13P FMC1 当前 PACKAGE_PIN：

```text
LA05_N → V14
LA05_P → W14

LA08_N → M12
LA08_P → M13
```

所以 B 组：

```tcl
# VS 不变
set_property PACKAGE_PIN V14 [get_ports {cam2_vsync}]

# HS: W14 -> M13
set_property PACKAGE_PIN M13 [get_ports {cam2_href}]

# RESET: M13 -> W14
set_property PACKAGE_PIN W14 [get_ports {cam2_reset}]

# SDA 不变
set_property PACKAGE_PIN M12 [get_ports {cam2_sda}]
```

---

# 16. CAM3 为什么先不动

CAM3 当前：

```text
VS  → LA07_P
SDA → LA07_N

HS  → LA11_P
SCL → LA11_N
```

VS 和 HS 已经不在同一 P/N 对。

并且已有实验中 CAM3 的结果非常好：

```text
geometry = 0x01E00500
malformed ≈ 1
```

所以：

> CAM3 暂时作为“稳定参考通道”。

A/B 测试期间尽量不要修改 CAM3。

---

# 17. 最推荐的完整实验顺序

```text
Step 1
当前Bitstream
CAM0单独
→ A1

Step 2
断电
CAM0交换 HS/RET
修改XDC并生成B Bitstream
→ B1

Step 3
确认B1能正常启动

Step 4
恢复A Bitstream和A接线
连接 CAM0 + CAM2 + CAM3
→ A2，60秒

Step 5
断电
只修改CAM0 HS/RET
换B Bitstream
CAM2/CAM3完全不动
→ B2，60秒

Step 6
A2 / B2各重复3次

Step 7
比较：
geometry
malformed
written
```

---

# 18. A/B 测试最重要的原则

整个实验只允许改变一个因素：

```text
A：
VS 与 HS 同一 P/N 对

B：
VS 与 RET 同一 P/N 对
```

其他全部保持一致：

```text
同一个 OV7670
同一块 EXTIO
同一个 FMC
同样的供电
同样的线长
同样的寄存器表
同样的 XCLK
同样的图像格式
同样的 DDR/HDMI 软件
同样的测试时长
```

否则无法判断改善到底来自哪里。

---

# 19. 回退方法

如果 B 组没有改善：

断电后恢复：

```text
CAM0 HS  → LA20_N
CAM0 RET → LA23_P
```

并恢复 XDC：

```tcl
set_property PACKAGE_PIN H14 [get_ports {cam0_href}]
set_property PACKAGE_PIN C13 [get_ports {cam0_reset}]
```

重新生成原始 Bitstream 即可。

这个 A/B 测试没有永久修改硬件，可以完全恢复。

---

# 20. 当前判断标准

最强的成功证据是：

```text
A2：
geometry 不稳定
malformed 很高

B2：
geometry 稳定为 0x01E00500
malformed 接近 0
```

如果出现这个结果，再把相同策略应用到 CAM1/CAM2。

如果 A/B 无明显差异，则停止在这个方向继续投入时间，转而测试：

1. 独立 3.3V 供电；
2. 更多 GND 回流；
3. 缩短杜邦线；
4. 降低 XCLK / PCLK；
5. TXB0108 多路同时翻转问题；
6. FPGA 输入采样边沿/时序。
