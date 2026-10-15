# 当前 Gemmini 硬件 ABI

当前硬件含三路自主命令前端，三颗 DIM32/FP16 Gemmini，目标 100 MHz，SAFE_MAX=4。
V33 独立基准已使用当前映射，入口为 `make benchmark` / `make test-v33`；现有实时 YOLOv5nu v26 Runtime 仍使用旧 custom3/custom2/custom1 映射，不能直接运行在新硬件上。
`make check` 校验硬件及 V33 来源映射；实时固件的 `make firmware` 和审核仍会提示 Runtime 适配尚未完成。

| 既有逻辑 worker | 前端 lane | native opcode | busy CSR | status CSR | accepted / retired CSR |
| --- | --- | --- | --- | --- | --- |
| 0 | 2 | custom2 | `0x7c2` | `0x7c4` | `0x7c6` / `0x7c7` |
| 1 | 1 | custom1 | `0x7c3` | `0x7c5` | `0x7c8` / `0x7c9` |
| 2 | 0 | custom0 | `0x7ca` | `0x7cb` | `0x7cc` / `0x7cd` |

custom3 是前端控制入口。32 字节命令表、HOST/RESUME、DRAIN、ACK、中断、地址范围和内存发布语义见 [前端接口](../architecture/command-frontend.md)。
参数来自当前导出 `gen-collateral/include/gemmini_params_32x32*custom*_xcvu13p.h`，不再生成旧 custom3 Gemmini 参数头。

前端配置移除旧 RegisteredIngressAtomicReserve 路由；RUN 的 accept 在实际 Gemmini handshake 时产生，旧 ingress queue_count/partial/debug 侧带接零。
前端拥有某路时，该路计算忙状态不阻塞 CPU fence；完成必须依据前端 HOST/DONE，不能沿用旧软件的全局 fence 假设。
下一次软件适配需同时处理 opcode/lane 对应、命令表发布、所有权、完成与错误排空，不能只改 opcode 常量。
