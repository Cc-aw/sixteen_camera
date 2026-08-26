# Gemmini 接入前接口约定

本工程保持当前视频 DDR 拓扑：

```text
S01 AW/W <- 16 路视频 DMA
S01 AR/R -> HDMI mosaic reader
S02 AR/R -> Batch preprocess 读取视频帧
```

当前没有 Gemmini SoC 的 coherent ExtIn/fbus 端口，因此预处理输出暂时继续
写 S02。未来接入 Gemmini 时参照 `demo/ai`，只拆分预处理器写通道：

```text
Preprocess AR/R -> S02（非缓存视频帧）
Preprocess AW/W -> fbus/ExtIn（coherent Batch Tensor）
```

不得把 MIG/DDR interconnect 的普通 S02 端口直接标记为 coherent。未来 SoC
需要保持与 `demo/ai` 相同的 256-bit AXI coherent 写入口，并提供 AW/W/B：

```text
AWID[3:0], AWADDR[32:0], AWLEN[7:0], AWSIZE[2:0], AWBURST[1:0]
AWLOCK, AWCACHE[3:0], AWPROT[2:0], AWQOS[3:0], AWVALID/AWREADY
WDATA[255:0], WSTRB[31:0], WLAST, WVALID/WREADY
BID[3:0], BRESP[1:0], BVALID/BREADY
```

软件可见内存契约：

```text
Arena0 input base = 0x30000000
Arena1 input base = 0x30800000
Batch member      = 416 * 416 * 3 = 0x0007ec00 bytes
Batch16 input     = 0x007ec000 bytes
```

这两个 8 MiB 区域目前仅是模型输入池，不是完整 Activation Arena。完整
Tensor/Weight/Output 内存布局必须由最终固定模型的离线规划结果决定。

软件 `AiBatchContext[2]` 与 Arena0/Arena1 一一对应，并在 Arena 回收前保留
`batch_id`、valid/fresh mask 以及 16 路 frame_id/timestamp/version，作为未来
Gemmini executor 的稳定提交接口。

软件通过 `AiModelRequest` 向模型后端提交 READY Batch。当前链接
`ai_model_backend_stub.c` 验证完整生命周期；未来将该文件替换为固定模型
Gemmini backend，保留 `submit()/poll()` 接口即可。
