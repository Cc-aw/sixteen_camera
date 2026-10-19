#!/usr/bin/env python3
"""Exercise vendor crossbar RTL with V3's propagated ID/credit parameters."""
from pathlib import Path
import importlib.util
import os
import re
import sys

v3 = Path(__file__).resolve().parents[1]
root = v3.parents[1]
out = Path(sys.argv[1]).resolve()
out.mkdir(parents=True, exist_ok=False)
os.environ.setdefault("VIVADO_ROOT", "/mnt/data/Vivado/Vivado/2023.2")
spec = importlib.util.spec_from_file_location("xsim_util", root / "scripts/run_ddr_axi_crossbar_throughput_test.py")
util = importlib.util.module_from_spec(spec)
spec.loader.exec_module(util)
ip = util.VIVADO_ROOT / "data/ip/xilinx"
sources = [ip / f"{name}/hdl/{name}_vl_rfs.v" for name in [
    "generic_baseblocks_v2_1", "axi_infrastructure_v1_1", "axi_register_slice_v2_1",
    "axi_data_fifo_v2_1", "axi_crossbar_v2_1"]]
log = util.run([str(util.VIVADO_ROOT / "bin/xvlog"), "--sv", "--include", str(ip / "axi_infrastructure_v1_1/hdl"),
    *map(str, sources), str(v3 / "tests/tb_memory_v3_crossbar.sv")], out)
(out / "compile.log").write_text(log)
for mode in (0, 1, 2):
    name = f"crossbar_{mode}"
    log = util.run([str(util.VIVADO_ROOT / "bin/xelab"), "tb_memory_v3_crossbar", "-s", name,
        "--generic_top", f"MODE={mode}"], out)
    (out / f"elaborate_{mode}.log").write_text(log)
    log = util.run_snapshot(name, out)
    (out / f"simulate_{mode}.log").write_text(log)
    result = re.search(r"CROSSBAR_RESULT[^\n]+", log)
    assert result and "failed=0" in result[0], log
    assert mode == 1 or "read_max=32" in result[0], result[0]
    assert mode == 0 or "write_max=32" in result[0], result[0]
    print(result[0], flush=True)
