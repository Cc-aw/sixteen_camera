#!/usr/bin/env python3
"""Compare like workloads and bind four-bank evidence to the official RTL."""
import argparse
import csv
import hashlib
import json
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]


def sha(path):
    return hashlib.sha256(path.read_bytes()).hexdigest()


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--baseline", type=Path, required=True)
    parser.add_argument("--candidate", type=Path, required=True)
    parser.add_argument("--output", type=Path, required=True)
    parser.add_argument("--additional-baseline", type=Path)
    parser.add_argument("--additional-candidate", type=Path)
    args = parser.parse_args()
    reports = [json.loads(path.read_text()) for path in (args.baseline, args.candidate)]
    additional_hashes = {}
    assert bool(args.additional_baseline) == bool(args.additional_candidate)
    if args.additional_baseline:
        for primary, path in zip(reports, (args.additional_baseline, args.additional_candidate)):
            extra = json.loads(path.read_text())
            assert extra["geometry"] == primary["geometry"]
            assert extra["compiled_sources_sha256"] == primary["compiled_sources_sha256"]
            assert extra["binary_sha256"] == primary["binary_sha256"]
            primary["results"] += extra["results"]
            additional_hashes[str(path)] = sha(path)
    assert [r["geometry"]["banks"] for r in reports] == [2, 4]
    manifests = []
    for path, report in zip((args.baseline, args.candidate), reports):
        manifest = path.parent / "compiled_sources.json"
        assert sha(manifest) == report["compiled_sources_sha256"]
        data = json.loads(manifest.read_text())
        assert sha(path.parent / "banked_memory_workload.svh") == data["workload_sha256"]
        assert sha(path.parent / "tb_banked_memory.sv") == data["bench_sha256"]
        for name, expected in data["rtl_sha256"].items():
            assert sha(path.parent / "rtl" / name) == expected, name
        assert sha(path.parent / "obj/Vtb_banked_memory") == report["binary_sha256"]
        manifests.append(data)
    assert manifests[0]["workload_sha256"] == manifests[1]["workload_sha256"]
    for name in ("axi4_if.sv", "head_uram_store.sv", "axi4_head_uram_router_v3.sv"):
        assert manifests[0]["rtl_sha256"][name] == manifests[1]["rtl_sha256"][name]
    product = json.loads((ROOT / "hw/manifests/current.json").read_text())
    context_path = ROOT / product["generation_context"]
    context = json.loads(context_path.read_text())
    rtl = ROOT / product["collateral_directory"]
    for name, expected in context["final_rtl_sha256"].items():
        assert sha(rtl / name) == expected, name
    handwritten = {p.name: p for p in (ROOT / "hw/rtl").rglob("*") if p.is_file()}
    for name, expected in manifests[1]["rtl_sha256"].items():
        if name in context["final_rtl_sha256"]:
            assert context["final_rtl_sha256"][name] == expected, "Candidate simulation is stale: " + name
        else:
            assert name in handwritten and sha(handwritten[name]) == expected, name
    def key(row):
        return tuple(row[name] for name in ("case", "lanes", "delay", "stalls", "seed", "requests"))
    rows = [{key(row): row for row in report["results"]} for report in reports]
    assert all(len(rows[i]) == len(reports[i]["results"]) for i in range(2)), "Duplicate scenarios"
    assert rows[0].keys() == rows[1].keys()
    compared = []
    for k in sorted(rows[0]):
        before, after = rows[0][k], rows[1][k]
        compared.append(dict(after, baseline_cycles=before["cycles"],
                             baseline_refill_lines=before["refill_lines"],
                             baseline_writeback_lines=before["writeback_lines"],
                             cycle_change_percent=100 * (after["cycles"] / before["cycles"] - 1)))
    local = [r for r in compared if r["case"] == 1 or (r["case"] == 0 and r["lanes"] == 1)]
    assert local and all(r["cycles"] == r["baseline_cycles"] for r in local), "Single-bank hit pipeline changed"
    assert any(r["parallel4"] > 0 for r in compared), "No actual four-client simultaneous returns observed"
    capacity = [r for r in compared if r["case"] == 3]
    assert capacity and all(r["refill_lines"] < r["baseline_refill_lines"] for r in capacity), "768 KiB capacity benefit absent"
    report = dict(baseline_commit="2326f08390f96cebfbb66fbb2afe14a3691fca7a",
                  baseline_sha256=sha(args.baseline), candidate_sha256=sha(args.candidate),
                  additional_results_sha256=additional_hashes,
                  generation_context_sha256=sha(context_path), scenarios=len(compared),
                  single_bank_hit_cycles="IDENTICAL", four_client_parallel_returns="OBSERVED",
                  capacity_768k_refill_reduction="OBSERVED_IN_ALL_CASES", results=compared,
                  slower_scenarios=[r for r in compared if r["cycles"] > r["baseline_cycles"]],
                  scope=reports[1]["path"], DDR_CONTROLLER_PHY_REGISTER_SLICE="NOT_MODELED",
                  ELF_GEMMINI_ARITHMETIC="NOT_RUN", BOARD_PERFORMANCE="NOT_MEASURED",
                  FULL_SYSTEM_SYNTHESIS="SEE_FULL_SYNTHESIS_STATE",
                  FULL_IMPLEMENTATION="SEE_FULL_IMPLEMENTATION_STATE", BITSTREAM="SEE_FULL_IMPLEMENTATION_STATE")
    args.output.parent.mkdir(parents=True, exist_ok=True)
    args.output.write_text(json.dumps(report, indent=2) + "\n")
    with args.output.with_suffix(".csv").open("w", newline="") as output:
        writer = csv.DictWriter(output, fieldnames=list(compared[0]))
        writer.writeheader(); writer.writerows(compared)
    print(f"L2_BANK_EXPANSION_COMPARISON=PASS scenarios={len(compared)} slower={len(report['slower_scenarios'])}")


if __name__ == "__main__":
    main()
