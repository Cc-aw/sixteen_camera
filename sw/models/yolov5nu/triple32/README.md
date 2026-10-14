# v26 三 worker 运行时

当前默认配置为 `v26.mk` 的 credit-cap4 正式版（关闭诊断采样和 v27/v28 software batch）。
新增 cooperative credit、查询复用、整包派发、13 处已证明的重复等待复用、
硬件 Pool/Resize 与 accumulator 容量决定的 Resize 行批次。PPU 保持 A 策略。

来源为开发工程 `sw/yolov5/triple32` 的共享源码，通过编译开关锁定 v26；
当前共享源码包含后续实验的禁用分支。`import_v26_manifest.json` 保留读取时的
来源哈希、适配后哈希和开发版 cap4 构建记录；来源共享源码的哈希与原 v26
构建记录有差异，当前移植重新构建和验证。`sources.lock.json` 校验当前本地闭包。
旧 `import_manifest.json` 和 `v17a.mk` 记录 V17 A 阶段。

`native/` 保留原 `dim16` API 名称；权重、原生生成输入、FP16 ABI 和 Head 布局不变。
构建直接使用匹配 TensorIngress SoC 的生成参数，开发目录不参与构建。

```sh
make firmware SOC_VARIANT=triple32_v3_tensor
make firmware-benchmark
make test-v26
make check-v26-firmware
make -C sw/models/yolov5nu/triple32 credit-cap3 credit-cap4-diag
```

实时路径保留稀疏 worker 启动、单 worker 跨帧复用、包/时间预算返回主循环，
每帧重置 credit 观察缓存和 wait-reuse 完成证明。Runtime、Tensor、Head/PPU 和
Overlay 的所有权协议沿用 R5。旧 ABI family profile 仍称 V17A，实际后端显示 v26。

详细配置、离线证据和上板步骤见 [v26 软件移植](../../../../docs/integration/triple32-v26-software.md)。
