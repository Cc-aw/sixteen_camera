# C1a G1：功能成立，当前控制没有兑现提速

**G1 功能原型：PASS；G2 / 物理实现：INSUFFICIENT_EVIDENCE。**

实际 RTL 两条描述符按物理 SPAD 半区选择，命中完整 Input tile 才省略 Mvin，并保留配置命令及真实完成路径。可关闭；Weight 复用未启用。生产 SoC、两个父候选和用户软件修改均未覆盖。

| 验证 | 结果 |
|---|---|
| 三路各一帧，166 个原生 stage/帧 | 全部完成，逐路 11,049 个原生命令/边界 |
| SPAD 消费值、最终 SPAD、全部输出写回 | 11,441,748 次读取、1,578,600 个输出 beat 逐字节一致 |
| Accumulator 原生 fence 边界 | 6,029,312 字节逐项一致 |
| 四模式、三路、三帧、不同数据、双 slot | 每路每模式 12 次请求、9 次新命中，完成 token 全闭合 |
| 原始配置/写入干扰 | 配置恢复及写入失效通过 |
| 隔离模式切换 | 0→1→2 与 2→3→0 通过；测试单独抑制 DRAIN 清空以验证模式失效本身 |
| 晚到 denied/corrupt、真实复位 | 命中后注入第二个 D beat 错误，复位重放逐字节通过 |
| 关闭回退 | 411,621 条 C0 事件及周期完全一致 |
| 协议及物理账本 | Mvin row/credit/ROB、Get/Put、bank 接收/提交全部闭合 |

三路全网共省略 48 个完整 Input tile，少发 **3,694,464 字节 Get（4.1665%）**。每路 16 个 tile、2,088 条实际 Mvin 被省略；原生已有的 54 个空 Input 请求没有重复计功。Weight/Bias 流量保持原值。

当前保守的全局 Load/Store/子生成器排空减少重叠：第 0 路私有低延迟功能窗口从 7,214,307 增至 7,277,810 周期，增加 63,503（0.8802%）。这不是系统吞吐测试；它说明仅省带宽还不足以推动物理实现。下一步应先收窄到相关写入/源区间的依赖，再做至少三组 seed、单路/三路及真实共享访存压力下的 G2。

模型使用完整真实 Gemmini RS/EX/FP16/SPAD/Accumulator/DMA，外存由私有确定性物理内存服务替代。HOST padding 执行实际原生操作；CPU/RVV/PPU 和共享 DDR/ASRAM 周期没有建模。生产 frontend 的失效接口及可综合导出尚未接入，地址契约限已验证的裸机恒等映射。没有综合、布局布线、bitstream、上板或新 WNS/FPS。

详见 [决策](decision.md)、[机器决策](decision.json)、[实现说明](../../analysis/c1a_design.md) 和 [实际 RTL 差异](rtl_overlay.patch)。原始数据保留在 `/mnt/data/wzr/13p/ov7670/sixteen_camera/build/experiments/csc_r1/g1_20261020_01`；本目录只归档可审阅结果，原始文件、输入、实际编译 RTL 和脚本 SHA 均绑定在各 manifest。
