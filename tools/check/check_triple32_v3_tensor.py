#!/usr/bin/env python3
"""Check the generated merged SoC's actual interfaces and cache geometry."""
from pathlib import Path
import json
import re
import subprocess
import sys

ROOT = Path(__file__).resolve().parents[2]
rtl = Path(sys.argv[1]).resolve()
subprocess.run([sys.executable, str(ROOT / "tools/soc/shell/npu100_video/tests/check_merged_rtl.py"),
                str(rtl), "3", "TaihangSoCFPGATestHarness"], check=True)
top = (rtl / "TaihangSoCFPGATestHarness.sv").read_text()
for direction, name, width in [
    ("output", "axi4_mem_w_bits_data", 512), ("input", "axi4_mem_r_bits_data", 512),
    ("output", "axi4_mem_aw_bits_id", 2), ("input", "axi4_mem_b_bits_id", 2),
    ("input", "axi4_tensor_w_bits_data", 256), ("input", "axi4_tensor_aw_bits_id", 5),
    ("input", "axi4_tensor_aw_bits_addr", 33), ("output", "axi4_tensor_b_bits_id", 5),
    ("input", "axi4_fbus_w_bits_data", 256), ("output", "axi4_mmio_w_bits_data", 64),
    ("output", "memory_perf_command", 3), ("input", "memory_perf_data", 64),
]:
    assert re.search(rf"\b{direction}\s+\[{width-1}:0\]\s+{name}\b", top), name
assert not re.search(r"\bspi_", top)
cache = (rtl / "InclusiveCache.sv").read_text()
assert len(re.findall(r"^  InclusiveCacheBankScheduler(?:_\d+)?\s+\w+\s*\(", cache, re.M)) == 2
assert (rtl / "TaihangTensorIngress.sv").is_file()
assert "replay_release" in (rtl / "RoccCommandRouter.sv").read_text()
divider = (rtl / "IterativeIntegerDivider.sv").read_text()
assert "requestCapturePending" in divider and "requestIn1" in divider
metadata = list(rtl.parent.glob("*.l2.json"))
assert len(metadata) == 1, "Missing L2 generation metadata"
banks = json.loads(metadata[0].read_text())["banks"]
assert len(banks) == 2
for index, bank in enumerate(banks):
    assert bank["ways"] == 8 and bank["blockBytes"] == 64
    assert bank["setBits"] == [6, 7, 8, 9, 10, 11, 13, 14, 15]
    assert all(entry["mask"] & 4096 == 0 and (entry["base"] >> 12) & 1 == index
               for entry in bank["addresses"])
assert sum(bank["ways"] * (1 << len(bank["setBits"])) * bank["blockBytes"] for bank in banks) == 524288
headers = list((rtl / "include").glob("gemmini_params_32x32*custom*_xcvu13p.h"))
assert len(headers) == 3, "Expected three newly generated worker parameter headers"
print("TRIPLE32_V3_TENSOR_STRUCTURE=PASS memory=512/2 tensor=256/5 banks=2 workers=3")
