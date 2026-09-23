# Taihang 双 Gemmini16 SoC 可移植生成包

本目录用于在同版本 Chipyard 源码上安装并生成：

```text
TaihangSoC1Rocket1RVV2Gemmini16x16PackedFullOps256BitConfig
```

目标结构是 1 个 Huge Rocket、1 个 Saturn RVV，以及挂在 hart 0 上的 2 个
逻辑 16x16 packed FullOps Gemmini。系统总线和 FBus 均为 256 bit。

## 使用方法

把整个 `soc_shell/` 目录复制到 Chipyard 根目录，然后执行：

```bash
cd /path/to/chipyard
./soc_shell/generate_taihang16_soc.sh
```

也可以从其他位置显式指定 Chipyard：

```bash
./soc_shell/generate_taihang16_soc.sh --chipyard-root /path/to/chipyard
```

只安装源码配置、不生成 RTL：

```bash
./soc_shell/generate_taihang16_soc.sh --install-only
```

检查配置源码是否已安装：

```bash
./soc_shell/generate_taihang16_soc.sh --verify-only
```

检查生成产物：

```bash
./soc_shell/verify_generated_taihang16_soc.sh /path/to/chipyard
```

## 固定版本

- Chipyard: `0acc1e1de2d3284bcd4d876956932a013ffe1949`
- Gemmini: `8c3f9923a44a2fe2c7930587be297d6d4f8c09ca`
- Rocket-Chip: `55bcad0f59436de98ea510334121de8546b9e9d7`

脚本默认拒绝其他版本，因为源码覆盖层只对上述版本保证可复现。`--force` 可以
绕过版本检查，但这种构建不能视为与原 SoC 完全一致。

安装前，脚本会把将被覆盖的源码保存到 Chipyard 的
`.taihang_soc_backups/`，不会调用 `git reset` 或删除用户源码。

## 包含内容

- Taihang FPGA harness、IO binder、配置和资源文件；
- 该 SoC 使用的本地 Gemmini RTL 生成源码；
- Rocket-Chip 的 RoCC CSR、FBus source/fifo 容量和 debug 接口改动；
- `fpga/Makefile` 中的 `SUB_PROJECT=taihang_soc` 入口；
- 一键 RTL 生成脚本和生成结果检查脚本。

生成目录为：

```text
fpga/generated-src/tsmcchip.fpga.taihangsoc.TaihangSoCFPGATestHarness.TaihangSoC1Rocket1RVV2Gemmini16x16PackedFullOps256BitConfig/
```
