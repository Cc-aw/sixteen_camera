# 工具入口

默认版本由 `hw/manifests/current.json` 选择。根目录 `make help` 列出当前入口。

| 入口 | 用途 |
| --- | --- |
| `check/check_current_product.py` | S1 硬件、固件、DMA/ASRAM/L2 ABI 配对检查 |
| `check/check_dependencies.py` | S1 冻结源码、生成 RTL、比特流及本地固件依赖审计 |
| `build/build_s1.py`、`build_s1.tcl` | S1 工程重建、elaboration、综合与 bitgen |
| `program/` | 默认 S1 bitstream / ELF 下载包装，实际实现由视频软件包提供 |
| S1 硬件包 `scripts/generate.py` | 独立 Scala 工作区生成，不覆盖导入产物 |
| S1 软件包 `scripts/` | 模型准备、ELF 身份、串口、日志和板测 |
| `config/` | 工具配置示例及忽略的本机覆盖 |

其他 `soc/`、综合诊断、分析和时序工具保留为显式历史实验入口；不再选择旧默认 SoC/固件。
原 donor/source 路径只用于追溯。生成文件放在对应包私有 build/，大型产物不提交。
