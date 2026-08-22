可行方案对比
方案	主要解决	推荐程度
PCLK → GC/CCIO → BUFG	PCLK 内部抖动/偏斜	★★★★★
IOB 寄存器直接采样 DVP	数据采样时序裕量	★★★★★
IDELAYE3 / MMCM 调采样点	数据与 PCLK 相位不好	★★★★★
VSYNC/HREF 数字毛刺滤波	串扰形成的短脉冲	★★★★★
高速 sysclk 过采样 PCLK	PCLK 偶发假边沿	★★★
FPGA 前加 Schmitt Buffer	严重模拟毛刺	★★★★
1. PCLK 一定走 Clock-Capable IO + BUFG

这是第一件应该检查的。

AMD 官方明确说，UltraScale 的外部用户时钟应该进入 GC（Global Clock）输入，GC 有到 BUFG、MMCM/PLL 等时钟资源的专用高速路径；普通 GPIO + fabric routing 不应该拿来作为对时序敏感的输入时钟。

正确结构类似：

Camera PCLK
    │
    ▼
GC / Clock-Capable Pin
    │
   IBUF
    │
   BUFG
    │
    ├───────────────┐
    ▼               ▼
D[7:0] FF        HREF / VSYNC FF

而不是：

PCLK
 │
普通 GPIO
 │
fabric routing
 │
LUT / FF

BUFG 本身并不会把已经进入 FPGA 的一个真实假脉冲“消掉”，但是它能保证：

PCLK 不再经过乱七八糟的普通布线；
整个采集逻辑获得低 skew 时钟；
后续 MMCM、IOB、IDELAY 等可以按标准 source-synchronous 方法工作。

AMD 的 BUFG 就是专门用于把时钟送到低偏斜全局时钟网络的。

所以对你的系统，我会先检查：

create_clock -name cam_pclk -period 41.667 [get_ports cam_pclk]

假设是 24 MHz。

并确保 cam_pclk 实际 PACKAGE_PIN 是 VU13P 的 GC pin。

2. D0~D7/HREF/VSYNC 第一拍直接放进 IOB

这个非常值得你做。

不要：

FPGA Pin
   │
   │ 很长的 FPGA fabric routing
   │
   ▼
CLB FF

而要尽量：

FPGA Pin
   │
   ▼
IOB Input FF   ← PCLK
   │
   ▼
内部逻辑

也就是：

always @(posedge cam_pclk_bufg) begin
    data_iob  <= cam_data;
    href_iob  <= cam_href;
    vsync_iob <= cam_vsync;
end

让第一层寄存器进入 IOB。

AMD 的 SelectIO 结构本身就提供 I/O 内的输入寄存器；官方设计方法也强调 source-synchronous 接口要正确使用 I/O 逻辑以及输入时序约束。

为什么这对你有帮助？

因为：

Camera
  │
  │ 杜邦线已经产生一定 skew
  ▼
FPGA PAD
  │
  ├── D0
  ├── D1
  ├── ...
  └── PCLK

你不希望进 FPGA 以后又增加：

D0  routing = 0.3 ns
D1  routing = 1.2 ns
D2  routing = 2.0 ns
...

把本来已经不大的采样窗口进一步吃掉。

把采样 FF 放进 IOB，就是尽量：

PAD → FF

这是我认为你应该首先实现的 FPGA 侧改动之一。

3. 用 IDELAYE3 把 D0~D7 调到 PCLK 眼图中央

这个特别适合你的 VU13P。

UltraScale/UltraScale+ SelectIO 有 IDELAYE3，可以对每一根输入数据线单独增加可编程延迟。AMD 官方说明 IDELAYE3 可以把输入信号延迟后送到输入寄存器、IDDR 或 ISERDES。

结构：

D0 ── IBUF ── IDELAYE3 ── FF
D1 ── IBUF ── IDELAYE3 ── FF
D2 ── IBUF ── IDELAYE3 ── FF
...
D7 ── IBUF ── IDELAYE3 ── FF


                       ▲
                       │
                     PCLK

假如你的实际波形是：

PCLK
       ↑
───────┐     ┌────────
       └─────┘


DATA
────XXX======XXXXXXXX
       ↑
      PCLK



PCLK 采样位置太靠近 DATA 翻转边缘。

通过 IDELAY：

DATA delayed
──────XXX=========XXXX
             ↑
            PCLK

把采样点放在：

      DATA VALID
<------------------->
          ↑
        PCLK
       中间位置

会显著增加噪声容限。

但有一个非常重要的地方
不要拿 IDELAYE3 去延迟 UltraScale 的 PCLK

AMD 官方直接说明：UltraScale 输入时钟不应该用 IDELAYE3 调相；如果要调整 clock phase，应该用 MMCM/PLL。

所以正确思路是：

数据需要调：


D[7:0]
   │
IDELAYE3
   │
   FF

或者：

PCLK
 │
MMCM
 │
phase shift
 │
 FF

而不是：

PCLK → IDELAYE3    ×
4. 用 MMCM 把 PCLK 相移 90° 左右

这个对 DVP 很有意思。

如果 Camera 是类似：

PCLK ↑
DATA 开始变化

而数据在：

       PCLK
        ↑
--------|---------------
DATA XXXX============XXX

上升沿附近并不是最稳定的位置，那么可以：

Camera PCLK
      │
     GC
      │
     MMCM
      │
      └── phase shifted PCLK

例如：

原始 PCLK


↑               ↑
|_______________|_______________


90° phase


      ↑               ↑
______|_______________|_________


DATA


XXXX================XXXX
      ↑
   最稳定区域

然后：

always @(posedge pclk_shifted)
    pixel <= cam_data;

这实际上不是“消除串扰”，而是：

把采样点搬离串扰、振铃、数据翻转最严重的位置。

实际工程中非常有效。

而且 AMD 明确推荐 UltraScale 需要调整输入 clock phase 时使用 MMCM。
