# 双 Gemmini16 单 dog DDR 测试基线

本目录保存一份固定的裸机测试 ELF，供 DDR、AXI 和 Gemmini 访存路径的
重复上板测试使用。同事只需获取本 Git 仓库，不依赖被忽略的
`demo/twoGemmini` 开发目录，也不需要重新编译测试程序。

## 1. 冻结文件

文件：

```text
gemmini16_tinyyolov2_dog_only_board.riscv
```

固定身份：

| 项目 | 值 |
|---|---|
| 架构 | RISC-V ELF64 little-endian |
| 入口地址 | `0x80000000` |
| 文件大小 | `17144832` bytes |
| SHA-256 | `f52d0eab0750a9bfe0c71a721061ccd874e8385cd5cef2f37d1a35da8c07a914` |
| 串口 | 115200 baud, 8N1 |

该 ELF 必须配合以下 SoC 配置生成的 bitstream 使用：

```text
TaihangSoC1Rocket1RVV2Gemmini16x16PackedFullOps256BitConfig
```

根目录的 `setup_vivado.tcl` 已固定选择该配置，并会输出：

```text
FROZEN_DOG_ELF_STATUS=READY
```

## 2. 测试内容与边界

测试镜像内置一个已经量化和预处理的 `416x416` dog 输入，运行完整
TinyYOLOv2，并检查检测结果、输出 tensor signature 和 Gemmini command credit。

本测试固定使用：

- worker0；
- Gemmini custom opcode `custom3`；
- busy CSR `0x7c2`；
- 已验证的 twoGemmini serial library 路径；
- DDR 中的模型权重、输入、中间 activation 和输出。

该 ELF 面向双 Gemmini SoC，但单次只向 worker0 提交一个 dog 推理任务，不会让
worker0 和 worker1 同时产生 DDR 压力。它适合建立稳定、可重复的单 Gemmini DDR
基线；双 Gemmini 并发带宽测试应使用另一份专用镜像，不能用本测试代替。

该程序不访问视频 MMIO，不依赖摄像头或 HDMI，也不会修改 FPGA bitstream。

## 3. 使用前准备

1. 使用 Vivado 2023.2 打开项目。
2. 如需重新初始化项目，在 Vivado Tcl Console 中执行：

   ```tcl
   source /absolute/path/to/sixteen_camera/setup_vivado.tcl
   ```

3. 下载与上述双 Gemmini16 配置匹配的 bitstream。
4. 关闭 Vivado Hardware Manager 对 JTAG 的占用。
5. 连接 115200 8N1 串口观察结果。

下载脚本默认使用以下工具；路径可通过同名环境变量覆盖：

- `OPENOCD_BIN`
- `OPENOCD_CFG`
- `GDB_BIN`
- `GDB_PYTHONHOME`
- `RISCV_ELF_PREFIX`

## 4. 离线校验 ELF

在仓库根目录执行：

```bash
./scripts/download_standalone_dog.sh --check
```

正确输出应包含：

```text
STANDALONE_DOG_CHECK=PASS
ENTRY=0x80000000
SHA256=f52d0eab0750a9bfe0c71a721061ccd874e8385cd5cef2f37d1a35da8c07a914
```

该命令只检查文件，不连接开发板。

## 5. 下载并运行

确认匹配的 bitstream 已经在 FPGA 中，然后执行：

```bash
./scripts/download_standalone_dog.sh
```

脚本会依次完成 ELF 架构、入口地址和 SHA-256 校验，然后通过 OpenOCD/GDB
下载到 DDR，并从 `0x80000000` 启动。脚本保留当前 bitstream。

## 6. 串口验收

启动信息应包含：

```text
GEMMINI16_TINYYOLOV2_DOG_ONLY image=dog.jpg worker=custom3/csr7c2 DIM=16 dataflow=WS
standalone dog inference start
```

最终通过标志为：

```text
RESULT: PASS - validated twoGemmini serial path detected dog on worker0
```

出现 `timeout`、`credit ... FAIL`、`signature_errors` 非零或最终 `RESULT: FAIL`
均表示本轮测试未通过，应保留完整串口日志和 OpenOCD 日志进行定位。

## 7. 冻结规则

不要原地重新编译或覆盖本 ELF。若测试程序、模型参数或调度方式发生变化，应建立
新的版本化 artifact 目录，记录新的文件大小、入口地址、SHA-256、匹配的 SoC
配置和上板验收输出，从而保证 DDR 对比测试始终使用同一份负载。
