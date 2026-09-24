#!/usr/bin/env python3
"""Run acceptance=1 versus acceptance=8 on the actual Vivado crossbar RTL."""

from __future__ import annotations

import argparse
import os
from pathlib import Path
import re
import subprocess
import tempfile


REPO = Path(__file__).resolve().parents[1]
VIVADO_ROOT = Path(
    os.environ.get(
        "VIVADO_ROOT",
        "/media/tsmc/6a3f28f3-1a75-4d55-baf2-a6aa8be84a59/"
        "tools/vivado2023.2/Vivado/2023.2",
    )
)


def run(command: list[str], cwd: Path) -> str:
    completed = subprocess.run(
        command,
        cwd=cwd,
        check=False,
        text=True,
        stdout=subprocess.PIPE,
        stderr=subprocess.STDOUT,
    )
    if completed.returncode:
        print(completed.stdout, end="")
        raise SystemExit(
            f"command failed with exit status {completed.returncode}: "
            + " ".join(command)
        )
    return completed.stdout


def run_snapshot(snapshot: str, cwd: Path) -> str:
    """Run the xelab kernel directly when the host xsim Tcl front-end fails."""
    kernel = cwd / "xsim.dir" / snapshot / "xsimk"
    env = os.environ.copy()
    vivado_lib = str(VIVADO_ROOT / "lib/lnx64.o")
    old_library_path = env.get("LD_LIBRARY_PATH", "")
    env["LD_LIBRARY_PATH"] = (
        f"{vivado_lib}:{old_library_path}" if old_library_path else vivado_lib
    )
    process = subprocess.Popen(
        [str(kernel)],
        cwd=cwd,
        env=env,
        text=True,
        stdin=subprocess.PIPE,
        stdout=subprocess.PIPE,
        stderr=subprocess.STDOUT,
    )
    assert process.stdin is not None
    assert process.stdout is not None
    output_lines: list[str] = []

    def read_until(marker: str) -> None:
        while True:
            line = process.stdout.readline()
            if not line:
                raise SystemExit(
                    f"simulation kernel exited before reporting {marker}: {kernel}"
                )
            output_lines.append(line)
            if marker in line:
                return

    read_until("=elaboration-done")
    process.stdin.write("-exec-run\n")
    process.stdin.flush()
    read_until('reason="run-complete"')
    process.stdin.write("-exec-continue\n")
    process.stdin.flush()
    read_until("*stopped,reason=")
    process.stdin.write("-gdb-exit\n")
    process.stdin.flush()
    process.stdin.close()
    output_lines.append(process.stdout.read())
    returncode = process.wait()
    output = "".join(output_lines)
    if returncode:
        print(output, end="")
        raise SystemExit(
            f"simulation kernel failed with exit status {returncode}: {kernel}"
        )
    return output


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("--transactions", type=int, default=4096)
    parser.add_argument("--source-period", type=int, default=6)
    parser.add_argument("--latency", type=int, default=48)
    args = parser.parse_args()

    bin_dir = VIVADO_ROOT / "bin"
    ip_dir = VIVADO_ROOT / "data/ip/xilinx"
    sources = [
        ip_dir / "generic_baseblocks_v2_1/hdl/generic_baseblocks_v2_1_vl_rfs.v",
        ip_dir / "axi_infrastructure_v1_1/hdl/axi_infrastructure_v1_1_vl_rfs.v",
        ip_dir / "axi_register_slice_v2_1/hdl/axi_register_slice_v2_1_vl_rfs.v",
        ip_dir / "axi_data_fifo_v2_1/hdl/axi_data_fifo_v2_1_vl_rfs.v",
        ip_dir / "axi_crossbar_v2_1/hdl/axi_crossbar_v2_1_vl_rfs.v",
        REPO / "sim/tb_ddr_axi_crossbar_throughput.sv",
    ]
    include_dir = ip_dir / "axi_infrastructure_v1_1/hdl"
    for path in [
        bin_dir / "xvlog",
        bin_dir / "xelab",
        include_dir,
        *sources,
    ]:
        if not path.exists():
            raise SystemExit(f"missing required simulation input: {path}")

    with tempfile.TemporaryDirectory(prefix="ddr-xbar-sim-") as temp_name:
        temp = Path(temp_name)
        run(
            [
                str(bin_dir / "xvlog"),
                "--sv",
                "--include",
                str(include_dir),
                *map(str, sources),
            ],
            temp,
        )

        results: dict[tuple[int, int], dict[str, float]] = {}
        for acceptance in (1, 8):
            for mode in (0, 1, 2):
                snapshot = f"xbar_a{acceptance}_m{mode}"
                elaborate = [
                    str(bin_dir / "xelab"),
                    "tb_ddr_axi_crossbar_throughput",
                    "-s", snapshot,
                    "--generic_top", f"ACCEPTANCE={acceptance}",
                    "--generic_top", f"MODE={mode}",
                    "--generic_top", f"TRANSACTIONS={args.transactions}",
                    "--generic_top", f"SOURCE_PERIOD={args.source_period}",
                    "--generic_top", f"RESPONSE_LATENCY={args.latency}",
                ]
                run(elaborate, temp)
                output = run_snapshot(snapshot, temp)
                match = re.search(
                    r"CROSSBAR_RESULT .*?cycles=(\d+) .*?read_MBps=([0-9.]+) "
                    r"write_MBps=([0-9.]+) aggregate_MBps=([0-9.]+) "
                    r"read_max=(\d+) write_max=(\d+) failed=(\d+)",
                    output,
                )
                if not match:
                    raise SystemExit(f"missing result for acceptance={acceptance} mode={mode}")
                print(match.group(0))
                cycles, read_bw, write_bw, aggregate_bw, read_max, write_max, failed = (
                    float(value) for value in match.groups()
                )
                if failed != 0:
                    raise SystemExit(f"protocol failure for acceptance={acceptance} mode={mode}")
                results[(acceptance, mode)] = {
                    "cycles": cycles,
                    "read": read_bw,
                    "write": write_bw,
                    "aggregate": aggregate_bw,
                    "read_max": read_max,
                    "write_max": write_max,
                }

        for mode, label, metric in (
            (0, "read", "read"),
            (1, "write", "write"),
            (2, "read_write", "aggregate"),
        ):
            before = results[(1, mode)][metric]
            after = results[(8, mode)][metric]
            print(
                f"CROSSBAR_AB mode={label} acceptance1_MBps={before:.3f} "
                f"acceptance8_MBps={after:.3f} speedup={after / before:.3f}x"
            )


if __name__ == "__main__":
    main()
