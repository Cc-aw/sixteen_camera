# Generated and frozen integration inputs

- `soc/`: Chipyard-generated collateral. The Taihang dual-Gemmini tree named
  in `build/soc_manifest.tcl` is the only production SoC; the SmallRocket tree
  is retained for historical comparison and must not enter synthesis.
- `xilinx_ip/`: Vivado IP configurations and their adjacent generated output.
  Only the XCI files in `build/ip_manifest.tcl` are registered by project setup.

Do not edit generated RTL to fix functional behavior. Change its source in
Chipyard or `soc_shell/`, regenerate, then use
`scripts/sync_taihang16_rtl.sh` to update the frozen collateral.
