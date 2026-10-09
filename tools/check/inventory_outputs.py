#!/usr/bin/env python3
"""Read-only inventory of build outputs; never removes files."""
from pathlib import Path
import subprocess

ROOT = Path(__file__).resolve().parents[2]
GROUPS = [
    ("build/firmware", "固件与编译中间文件；保留板测版本"),
    ("build/vivado", "独立 Vivado 工作工程及生成数据"),
    ("build/bitstream", "比特流及对应构建报告"),
    ("build/sim", "可重建的仿真缓存"),
    ("build/reports", "检查、时序及下载记录"),
    ("build/captures", "板上抓取数据；保留"),
    ("build/history", "重构前的本地历史结果和抓取；保留"),
    ("hw/soc", "SoC 集成输入；保留"),
    ("hw/ip", "IP 重建 Tcl；旧本地 IP 输出已忽略"),
    ("hw/vivado", "源码 Tcl 与本地 Vivado 工程；生成物已忽略"),
]

def main():
    for relative, policy in GROUPS:
        path = ROOT / relative
        if path.exists():
            size = subprocess.check_output(["du", "-sh", "--", str(path)], text=True).split()[0]
        else:
            size = "-"
        print(f"{size:>6}  {relative}\n        {policy}")
    known = {name for name, _ in GROUPS if name.startswith("build/")}
    for path in sorted((ROOT / "build").glob("*")):
        if path.relative_to(ROOT).as_posix() not in known:
            print(f"  其他  {path.relative_to(ROOT)}（保留，未纳入自动清理）")

if __name__ == "__main__":
    main()
