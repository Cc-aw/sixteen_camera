# 当前系统文档

- [快速开始](quickstart.md)：依赖、SoC 生成、Vivado、固件、基准、下载和测试顺序。
- [硬件架构](architecture/hardware.md)：十六路视频、TensorIngress、三 Gemmini32、L2/DDR、Head/PPU 和显示。
- [软件架构](architecture/software.md)：应用、Runtime、backend、模型与资源生命周期。
- [内存映射](interfaces/memory-map.md)：MMIO、DDR、CPU alias 与可见性。
- [Gemmini ABI](interfaces/gemmini-abi.md)：三个 worker、CSR、credit、上下文、Pool/Resize 和配对检查。
- [Tensor/PPU 协议](interfaces/tensor-ppu.md)：描述符、release ack、Head、receipt 和 overlay。
- [当前验收](validation/current.md)：当前身份、离线证据、整机实现与板测状态。

目录整理的逐阶段结果、路径映射和退休依据见 [实施记录](validation/single-version-refactor.md)。
历史演进文档不作为当前构建说明；原始版本可通过基线 tag 和 Git history 查询。
