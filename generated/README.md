# SoC 集成示例与 IP 输入

- `soc/`：双 Gemmini16 和单 Gemmini4 的冻结集成示例。它们提供现有 wrapper 的参考连接，不规定后续计算 SoC。
- `xilinx_ip/`：Vivado IP 配置及相邻生成材料。仅 `config/manifests/ip_manifest.tcl` 中的 XCI 由工程 setup 注册。

`config/manifests/soc_manifest.tcl` 默认选择 `dual16`。新的兼容 SoC 可放入 `soc/<配置名>/gen-collateral/`，通过 `SOC_CONFIG=<配置名>` 选择。

生成 RTL 的功能修改应回到对应 SoC 源工程，再重新生成并同步。双 Gemmini16 的参考生成包位于 `soc_shell/`；同步入口为 `scripts/generate/sync_taihang16_rtl.sh`。
