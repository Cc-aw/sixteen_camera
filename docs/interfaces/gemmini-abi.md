# 当前 Gemmini ABI

唯一正式模型为 YOLOv5nu v26，三颗 DIM32 Gemmini，100 MHz，credit limit 与硬件 SAFE_MAX 均为 4。
`hw/manifests/current.json` 记录配对身份；`make check` 校验实际生成参数、门控及两个 Make 入口展开的配置。

| worker | native opcode | busy CSR | status CSR | accepted / retired CSR |
| --- | --- | --- | --- | --- |
| 0 | custom3 | `0x7c2` | `0x7c4` | `0x7c6` / `0x7c7` |
| 1 | custom2 | `0x7c3` | `0x7c5` | `0x7c8` / `0x7c9` |
| 2 | custom1 | `0x7ca` | `0x7cb` | `0x7cc` / `0x7cd` |

参数来自当前导出 `gen-collateral/include/gemmini_params_32x32*custom*_xcvu13p.h`；公共实现位于唯一 `sw/third_party/gemmini/`，保留来源锁和许可。
当前 backend 的 V17A-family 与冻结输入的 dim16_dual 名称保留，不是可选择的旧生产配置。

CPU 已发包数减 hardware retired 构成 outstanding，包含尚未 accepted 的 ingress 指令。
退休预算复用不替代 can_submit；实际提交/恢复仍读取入口许可，保持 outstanding<4、queue<2 和无 partial packet 的门控。
提交单位为完整 packet，burst=1，CPU quantum=200 µs；切换保留现有 light FP/VCSR context。

fixed plans、fixed packets、prepared WS/LUT、13 处静态证明的 wait reuse 和 Pool/Resize 的批次边界保持原样。
Resize rows 设置为 0，由当前 accumulator 容量计算批次；不启用 software batch。
Head 发布仍要求 native local ingress、accepted/retired 和 DMA 完成证明。
`make test-model` 验证命令流与数值，`make check-v26-firmware` 审核实际 ELF 的上下文、PPU 屏障和正式版身份。
