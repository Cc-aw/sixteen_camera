# Memory Parallel V3 的 Gemmini ABI

`include/gemmini.h`、FP16 编码和计数器头来自开发工程的
`soc_shell/npu100_video/software/gemmini-rocc-tests/include`。其余原生 NN、
RVV 和 RoCC 支持头在本仓库冻结，构建不依赖开发目录。

参数必须通过 `-include` 指向 `hw/soc/...MemoryParallelV3TensorIngressConfig/`
新生成的 DIM32 custom3 参数头。`gemmini_params.h` 对未选择参数的构建报错，
避免意外使用旧 DIM16/FP32 ABI。worker 0/1/2 分别使用 custom3/custom2/custom1。

`LICENSE` 保留 Gemmini 上游许可；各文件保留原有版权说明。
来源和内容哈希见 `sources.lock.json`，可用 `make check-deps` 校验。
