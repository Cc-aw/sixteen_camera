#!/usr/bin/env python3
"""Check the generated merged SoC's actual interfaces and cache geometry."""
from pathlib import Path
import json
import re
import subprocess
import sys

ROOT = Path(__file__).resolve().parents[2]
rtl = Path(sys.argv[1]).resolve()
product = json.loads((ROOT / "hw/manifests/current.json").read_text())
secondary_entries = product["l2_secondary_entries"]
bridge = (ROOT / "hw/rtl/memory/postprocess_memory_bridge_v3.sv").read_text()
assert f".READ_DECOUPLE(1'b{int(product['head_read_decouple'])})" in bridge, "Head configuration disagrees with production manifest"
subprocess.run([sys.executable, str(ROOT / "hw/soc/source/shell/npu100_video/tests/check_merged_rtl.py"),
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
router = (rtl / "RoccCommandRouter.sv").read_text()
assert "replay_release" not in router and "RegisteredIngressAtomicReserve" not in router
for lane, opcode in enumerate(("B", "2B", "5B", "7B")):
    assert re.search(rf"matches_{lane}\s*=\s*\w+\s*==\s*7'h{opcode}\b", router), (lane, opcode)
tile = (rtl / "RocketTile.sv").read_text()
assert len(re.findall(r"^  CommandFrontendCluster\s+\w+\s*\(", tile, re.M)) == 1
assert len(re.findall(r"^  CommandFrontendTL(?:_\d+)?\s+\w+\s*\(", tile, re.M)) == 3
assert len(re.findall(r"^  CommandFrontendEngine\s+\w+\s*\(",
                      (rtl / "CommandFrontendCluster.sv").read_text(), re.M)) == 3
busy = re.search(r"\.io_rocc_busy\s+\(([^\n]+)", tile)[1]
assert all(f"~(_commandFrontend_io_stream_owner[{lane}])" in busy for lane in range(3))
assert "_commandFrontend_io_transport_busy" in busy and "_respArb_io_out_valid" in busy
assert re.search(r"\.io_rocc_interrupt\s+\(_commandFrontend_io_interrupt\)", tile)
assert len(re.findall(r"\.io_loopconv_request_accept\s+\([^\n]+== 7'hF\)", tile)) == 3
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
assert {re.search(r"custom(\d)", p.name)[1] for p in headers} == {"0", "1", "2"}
for channel, module in zip("ABCDE", ("SinkA", "SourceB", "SinkC", "SourceD", "SinkE")):
    body = (rtl / f"{module}.sv").read_text()
    queues = re.findall(r"^  (Queue2_TLBundle" + channel + r"_\S+)\s+\w+\s*\(", body, re.M)
    assert len(queues) == 1, (module, queues)
    queue = (rtl / f"{queues[0]}.sv").read_text()
    assert "assign io_enq_ready = ~full;" in queue and "assign io_deq_valid = ~empty;" in queue
scheduler = (rtl / "InclusiveCacheBankScheduler.sv").read_text()
assert re.search(rf"RegisteredListBuffer_q102_e{secondary_entries}(?:_\d+)?\s+requests\s*\(", scheduler)
assert "reloadWaiting" in scheduler and "reloadReadFilter" in scheduler and "winner" in scheduler
assert ".io_peekOH" not in scheduler, "Old combinational secondary payload bypass remains"
mshr = (rtl / "MSHR.sv").read_text()
assert "awaiting_reload" in mshr and "io_reloadReserved" in mshr
pool = (rtl / f"RegisteredListBuffer_q102_e{secondary_entries}.sv").read_text()
assert "payload" in pool and "pending" in pool
assert re.search(r"_responses_io_count\} \+ \{3'h0, pending\} < 4'h4", pool), "Pending read must consume one of four response credits"
response_module = re.search(r"^  (Queue4_\w+) responses \(", pool, re.M)
assert response_module, "Missing four-entry secondary response queue"
response_body = (rtl / (response_module[1] + ".sv")).read_text()
assert re.search(r"reg  \[1:0\]  enq_ptr_value", response_body)
assert re.search(rf"reg +\[{(secondary_entries-1).bit_length()-1}:0\] +head_101;", pool), "Queue101 and 7-bit entry pointers must survive"
assert re.search(rf"reg +\[{secondary_entries-1}:0\] +used;", pool)
mems = list(rtl.parent.glob("*.conf"))
assert any(re.search(rf"name payload_ext depth {secondary_entries} width \d+ ports write,read", p.read_text()) for p in mems), "Secondary payload must use synchronous 1R1W RAM"
assert len(re.findall(r"^  MSHR(?:_\d+)?\s+\w+\s*\(", scheduler, re.M)) == 34
for name in ("Gemmini", "Gemmini_1", "Gemmini_2"):
    worker = (rtl / f"{name}.sv").read_text()
    store = re.search(r"^  (StoreController(?:_\d+)?)\s+store_controller\s*\(", worker, re.M)
    loop = re.search(r"^  (LoopConv(?:_\d+)?)\s+\w+\s*\(", worker, re.M)
    assert store and loop, name
    store_body = (rtl / f"{store[1]}.sv").read_text()
    expression = re.search(r"assign io_dma_req_bits_pool_en\s*=\s*([^;]+);", store_body)
    assert expression and "pool_stride" in expression[1] and "wrow_counter" in expression[1], name
    loop_body = (rtl / f"{loop[1]}.sv").read_text()
    for slot in (0, 1):
        assert f"loops_{slot}_outer_bounds_pool_size <= _cmd_q_io_deq_bits_cmd_rs1[31:16]" in loop_body
        assert f"loops_{slot}_no_pool <= _cmd_q_io_deq_bits_cmd_rs2[0]" in loop_body
perf = (rtl / "MemoryParallelPerf.sv").read_text()
assert "4d50563300010001" in perf.lower(), "Tensor memory statistics ABI 1.1 is missing"
print(f"TRIPLE32_V3_TENSOR_STRUCTURE=PASS frontend=3 control=custom3 direct=custom0/1/2 memory=512/2 tensor=256/5 banks=2 workers=3 MaxPool=3 full_inner_buffers=5 registered_secondary_pool={secondary_entries}x102 grouped_scheduler=on stats_ABI=1.1")
