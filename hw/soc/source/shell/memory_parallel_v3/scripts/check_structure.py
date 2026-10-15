#!/usr/bin/env python3
"""Audit generated SoC/DDR connectivity and address interleave before synthesis."""
import argparse
import hashlib
import json
import re
from pathlib import Path

v3 = Path(__file__).resolve().parents[1]
root = v3.parents[1]
p = argparse.ArgumentParser()
p.add_argument("chipyard", type=Path)
p.add_argument("ddr_ip", type=Path)
p.add_argument("report", type=Path)
a = p.parse_args()
gen = a.chipyard / "fpga/generated-src/tsmcchip.fpga.taihangsoc.TaihangSoCFPGATestHarness.TaihangSoC1Rocket1RVV3Gemmini32x32MemoryParallelV3Config"
rtl = gen / "gen-collateral"
checks = {}
def check(name, condition, evidence=None):
    checks[name] = {"pass": bool(condition), "evidence": evidence}
    if not condition:
        raise RuntimeError(name + ": " + repr(evidence))

for rel, sha in json.loads((v3 / "baseline.json").read_text()).items():
    check("baseline " + rel, hashlib.sha256((root / rel).read_bytes()).hexdigest() == sha)
banks = json.loads(next(gen.glob("*.l2.json")).read_text())["banks"]
check("two banks", len(banks) == 2)
check("512KiB total", sum(b["ways"] * 2**len(b["setBits"]) * b["blockBytes"] for b in banks) == 524288)
for n, b in enumerate(banks):
    check(f"bank{n} geometry", b["setBits"] == [6,7,8,9,10,11,13,14,15] and b["blockBytes"] == 64 and b["ways"] == 8)
    check(f"bank{n} address mask", all(x["mask"] & 4096 == 0 and (x["base"] >> 12) & 1 == n for x in b["addresses"]))
# All byte phases in the period of A12, not just aligned example addresses.
for name, base, stride in [("activations", 0x8254b4c0, 2217600), ("inputs", 0x822a7ac0, 921600)]:
    bad = [offset for offset in range(8192) if len({((base + i*stride + offset) >> 12) & 1 for i in range(3)}) != 2]
    check(name + " equal-offset three-worker bank distribution", not bad,
          {"base": hex(base), "stride": stride, "phases_checked": 8192, "all_three_same_bank": len(bad)})
top = (rtl / "TaihangSoCFPGATestHarness.sv").read_text().split("\n);")[0]
for signal, bits in [("axi4_mem_w_bits_data",512), ("axi4_mem_r_bits_data",512), ("axi4_mem_w_bits_strb",64),
                     ("axi4_mem_aw_bits_id",2), ("axi4_mem_ar_bits_id",2), ("axi4_mem_r_bits_id",2),
                     ("axi4_mem_b_bits_id",2), ("axi4_fbus_w_bits_data",256), ("axi4_fbus_aw_bits_id",5)]:
    check(signal, bool(re.search(r"\[" + str(bits-1) + r":0\]\s+" + signal + r"\b", top)), bits)
check("dual scheduler instances", len(re.findall(r"^  InclusiveCacheBankScheduler\s+", (rtl / "InclusiveCache.sv").read_text(), re.M)) == 2)
mshrs = re.findall(r"^  MSHR(?:_\d+)?\s+mshrs_\d+\s*\(", (rtl / "InclusiveCacheBankScheduler.sv").read_text(), re.M)
check("34 MSHRs per bank", len(mshrs) == 34, len(mshrs))
yanker = (rtl / "AXI4UserYanker_2.sv").read_text()
check("4x32 read + 4x32 write ID restoration queues", len(re.findall(r"^  Queue32_BundleMap\s+", yanker, re.M)) == 8)
mapping = json.loads(next(gen.glob("*.memmap.json")).read_text())["mapping"]
perf = [m for m in mapping if m["base"] == [0x02020000]]
check("uncached CPU MMIO", len(perf) == 1 and perf[0]["size"] == [65536] and perf[0]["c"] == [False])
intervals = sorted((b, b+s) for m in mapping for b,s in zip(m["base"],m["size"]))
check("nonoverlapping MMIO", all(x[1] <= y[0] for x,y in zip(intervals,intervals[1:])))
ddr = next(a.ddr_ip.glob("*.gen/sources_1/bd/design_1/synth/design_1.v")).read_text()
pins = re.findall(r"\.c0_ddr4_s_axi_(\w+)\(([^)]+)\)", ddr)
check("all MIG AXI connections preserved", len(pins) >= 37 and all(net == "m00_full_regslice_M_AXI_"+pin.upper() for pin,net in pins), len(pins))
tap = ddr.split("design_1_u_mig_perf_0 u_mig_perf",1)[1].split("endmodule",1)[0]
check("MIG monitor uses same wires", all(re.search(r"\.s_axi_"+pin+r"\("+re.escape(net)+r"\)", tap) for pin,net in pins))
xbar = next(a.ddr_ip.glob("*.gen/sources_1/bd/design_1/ip/design_1_xbar_0/synth/design_1_xbar_0.v")).read_text()
for param, value in {"C_AXI_DATA_WIDTH":"512", "C_AXI_ID_WIDTH":"4",
    "C_S_AXI_THREAD_ID_WIDTH":"96'H000000000000000000000002",
    "C_S_AXI_WRITE_ACCEPTANCE":"96'H000000010000000800000020",
    "C_S_AXI_READ_ACCEPTANCE":"96'H000000080000000100000020",
    "C_M_AXI_WRITE_ISSUING":"32'H00000020", "C_M_AXI_READ_ISSUING":"32'H00000020"}.items():
    check(param, f".{param}({value})" in xbar, value)
auto_cc = next(a.ddr_ip.glob("*.gen/sources_1/bd/design_1/ip/design_1_auto_cc_0/synth/design_1_auto_cc_0.v")).read_text()
check("S00 CDC native 512bit", ".C_AXI_DATA_WIDTH(512)" in auto_cc)
mem = next(rtl.glob("*.top.mems.v")).read_text()
check("V1 RAM inference retained", 'ram_style = "ultra"' in mem and 'ram_style = "block"' in mem)
report = {"status":"PASS", "checks":checks, "limits":"Structural checks and bank phase proof; not measured performance or routed timing."}
with a.report.open("x") as f:
    json.dump(report, f, indent=2)
    f.write("\n")
print(f"MEMORY_V3_STRUCTURE_PASS checks={len(checks)} report={a.report}")
