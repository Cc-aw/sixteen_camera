"""Resolve the selected SoC with the Tcl manifest used by Vivado."""
from pathlib import Path
import subprocess


def soc_collateral():
    root = Path(__file__).resolve().parents[2]
    result = subprocess.run(
        ["tclsh", str(root / "scripts/check/print_soc_collateral.tcl")],
        check=True, capture_output=True, text=True,
    )
    path = Path(result.stdout.strip())
    if not (path / "TaihangSoCFPGATestHarness.sv").is_file():
        raise FileNotFoundError(f"Selected SoC harness is missing: {path}")
    return path
