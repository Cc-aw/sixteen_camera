#!/usr/bin/env python3
"""Read-only inventory of build outputs; never removes files."""
from pathlib import Path
import subprocess

ROOT = Path(__file__).resolve().parents[2]
GROUPS = [
    ("build/firmware", "固件及编译中间文件；ELF 可能是板测版本，删除前核对"),
    ("build/bitstream", "比特流、DCP、对应报告；保留验证基线"),
    ("build/sim", "可重建仿真缓存；保留需要的诊断日志后可清理"),
    ("build/reports", "综合、检查及下载记录；按验证用途保留"),
    ("build/captures", "板上抓取数据；不可当作编译缓存清理"),
    ("sw/build", "旧固件及缓存；旧路径保留，新构建写 build/firmware"),
    ("build/bitstream_0918_video", "旧 triple64 构建和恢复检查点；保留"),
    ("build/ppu_phase2", "旧 PPU 综合、仿真及比特流混合记录；逐项判断"),
    ("build/sim_loopconv", "旧仿真及故障诊断证据；逐项判断"),
    ("build/twogemmini_audit", "旧 RTL 对比证据；保留"),
    ("reports", "旧时序和板测报告；保留原路径"),
    ("captures", "旧抓取数据；保留原路径"),
    ("obj_dir", "旧 Verilator 缓存；确认无进程使用后可清理"),
    (".Xil", "旧 Vivado 临时目录；确认无进程使用后可清理"),
    ("prj", "XPR/BD 源文件与 Vivado 运行目录混合；禁止整目录清理"),
    ("generated", "SoC RTL 和 IP 构建输入；保留"),
    ("artifacts", "冻结交付及验证基线；保留"),
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
