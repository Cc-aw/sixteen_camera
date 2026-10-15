# 当前固件依赖

- `gemmini/`：唯一当前 DIM32/FP16 Gemmini ABI、RVV/NN/RoCC 支持头及上游 LICENSE；由原 V3 快照原样迁移。参数由当前 SoC 生成头提供。
- `board/`：板级 AXI IIC、时钟初始化及兼容头。
- `amd/`：冻结的 AMD/Xilinx BSP 编译源和相邻头，保留原 SPDX/版权声明。

根 `sources.lock.json` 锁定 board/AMD；Gemmini 自有 `gemmini/sources.lock.json` 记录来源和哈希。原始 donor/source 路径仅用于追溯，不参与编译。
`make check-deps` 校验源码锁和编译依赖；两个当前 ELF 的 `.d` 已证明退休 Gemmini 快照不参与编译。旧快照可从基线 tag 恢复。
