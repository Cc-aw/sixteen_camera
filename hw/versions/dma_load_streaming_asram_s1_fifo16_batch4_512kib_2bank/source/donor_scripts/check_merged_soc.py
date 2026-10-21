#!/usr/bin/env python3
"""Check the generated merged SoC's actual interfaces and cache geometry."""
from pathlib import Path
import argparse
import json
import re
import subprocess
import sys

FEATURE = Path(__file__).resolve().parents[1] / 'hw/versions/dma_load_streaming_asram_512kib_2bank'
sys.path.insert(0, str(FEATURE / "scripts"))
from l2_geometry import L2Geometry

parser = argparse.ArgumentParser(description=__doc__)
parser.add_argument("rtl", type=Path)
parser.add_argument("--l2-banks", type=int, choices=(2, 4))
parser.add_argument("--dma-load-runtime", action="store_true")
parser.add_argument("--s5-l2", action="store_true")
args = parser.parse_args()
rtl = args.rtl.resolve()
product = json.loads((FEATURE / "manifests/product.json").read_text())
geometry = L2Geometry(args.l2_banks or product.get("l2", {}).get("banks", 2))
secondary_entries = product["l2_secondary_entries"]
bridge = (FEATURE / "board_rtl/postprocess_memory_bridge_v3.sv").read_text()
s1_l2 = product.get("l2_implementation") == "s1_combinational"
if s1_l2:
    assert secondary_entries == 34 and not product['head_read_decouple']
    assert "READ_DECOUPLE" not in bridge
    head = (FEATURE / "board_rtl/axi4_head_uram_router_v3.sv").read_text()
    assert "head_read_decoupler" not in head and "READ_ACCEPT_LIMIT" not in head
else:
    assert f".READ_DECOUPLE(1'b{int(product['head_read_decouple'])})" in bridge, "Head configuration disagrees with production manifest"
subprocess.run([sys.executable, str(FEATURE / "soc_shell/npu100_video/tests/check_merged_rtl.py"),
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
assert len(re.findall(r"^  InclusiveCacheBankScheduler(?:_\d+)?\s+\w+\s*\(", cache, re.M)) == geometry.banks
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
if args.dma_load_runtime:
    interrupt = re.search(r"\.io_rocc_interrupt\s+\(([^\n]+)\)", tile)[1]
    assert all(name in interrupt for name in ("_commandFrontend_io_interrupt",
        "_applyOrElse_io_interrupt", "_applyOrElse_1_io_interrupt", "_applyOrElse_2_io_interrupt"))
    assert '.io_dma_load_mode' not in tile, 'Runtime mode wiring must be pruned in fixed-mode hardware'
    scratchpad = (rtl / "Scratchpad.sv").read_text()
    assert re.search(r"DmaLoadGroup\s+group\s*\(", scratchpad)
    assert re.search(r"DmaLoadRowAssembler\s+assembler\s*\(", scratchpad)
else:
    assert re.search(r"\.io_rocc_interrupt\s+\(_commandFrontend_io_interrupt\)", tile)
assert len(re.findall(r"\.io_loopconv_request_accept\s+\([^\n]+== 7'hF\)", tile)) == 3
divider = (rtl / "IterativeIntegerDivider.sv").read_text()
assert "requestCapturePending" in divider and "requestIn1" in divider
metadata = list(rtl.parent.glob("*.l2.json"))
assert len(metadata) == 1, "Missing L2 generation metadata"
assert L2Geometry.from_metadata(metadata[0]) == geometry
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
if args.s5_l2:
    assert "cachedHeads" in scheduler and "mshr_selectOH_masked" in scheduler
    assert ".io_planAllocate" in scheduler and ".io_repeatCommit" in scheduler
    mshr = (rtl / "MSHR.sv").read_text()
    assert "allocatedPlan" in mshr and "directoryPlan" in mshr
    pool = (rtl / "ListBuffer_QueuedRequest_q102_e34_fast.sv").read_text()
    assert "headPayload" in pool and "successorPayload" in pool
    assert not list(rtl.glob("RegisteredListBuffer*"))
elif s1_l2:
    assert re.search(r"ListBuffer_QueuedRequest_q102_e34_fast\s+requests\s*\(", scheduler)
    assert "robin_filter" in scheduler and ".io_peekOH" in scheduler
    assert "reloadWaiting" not in scheduler and "winner" not in scheduler
    assert "RegisteredListBuffer" not in scheduler and "prefetched" not in scheduler
    mshr = (rtl / "MSHR.sv").read_text()
    assert "awaiting_reload" not in mshr and "io_reloadReserved" not in mshr
    pool = (rtl / "ListBuffer_QueuedRequest_q102_e34_fast.sv").read_text()
    assert re.search(r"reg +\[33:0\] +used;", pool)
    assert re.search(r"reg +\[33:0\] +frontOH_101;", pool)
    assert "dataSlots_33_" in pool and "dataSlots_34_" not in pool
    assert "responseValid" not in pool and "pending" not in pool
    assert not list(rtl.glob("RegisteredListBuffer*"))
    for module, channel in (("SourceA", "A"), ("SinkD", "D")):
        body = (rtl / (module + ".sv")).read_text()
        queue = re.search(r"^  (Queue2_TLBundle"+channel+r"_\S+) \w+ \(", body, re.M)
        assert queue and "d_bypass" not in body
        qbody = (rtl / (queue[1] + ".sv")).read_text()
        assert "assign io_enq_ready = ~full;" in qbody and "assign io_deq_valid = ~empty;" in qbody
else:
    sink_d = (rtl / "SinkD.sv").read_text()
    if "d_bypass" in sink_d:
        # Performance configuration: preserve occupancy-only READY and registered
        # control acknowledgements while data responses may use an empty queue.
        assert re.search(r"d_bypass = ~_d_queue_io_deq_valid & io_d_valid & io_d_bits_opcode\[0\]", sink_d)
        assert ".io_enq_ready        (io_d_ready)" in sink_d
        outer_d = re.search(r"^  (Queue2_TLBundleD_\S+) d_queue", sink_d, re.M)
        assert outer_d
        outer_d_body = (rtl / (outer_d[1] + ".sv")).read_text()
        assert "assign io_enq_ready = ~full;" in outer_d_body
        assert "assign io_deq_valid = ~empty;" in outer_d_body
        outer_a = re.search(r"^  (Queue2_TLBundleA_\S+) io_a_q", (rtl / "SourceA.sv").read_text(), re.M)
        assert outer_a
        outer_a_body = (rtl / (outer_a[1] + ".sv")).read_text()
        assert "assign io_enq_ready = ~full;" in outer_a_body
        assert "io_enq_valid | ~empty" in outer_a_body
    assert re.search(rf"RegisteredListBuffer_q102_e{secondary_entries}(?:_\d+)?\s+requests\s*\(", scheduler)
    assert "reloadWaiting" in scheduler and "reloadReadFilter" in scheduler and "winner" in scheduler
    assert ".io_peekOH" not in scheduler, "Old combinational secondary payload bypass remains"
    mshr = (rtl / "MSHR.sv").read_text()
    assert "awaiting_reload" in mshr and "io_reloadReserved" in mshr
    pool = (rtl / f"RegisteredListBuffer_q102_e{secondary_entries}.sv").read_text()
    assert "payload" in pool and "pending" in pool
    if "responseValid_0" in pool:
        assert len(re.findall(r"reg +responseValid_\d+;", pool)) == 4
        credit = re.search(r"wire \[3:0\] +outstanding = ([^;]+);", pool)
        assert credit and "{3'h0, pending}" in credit[1]
        assert all(f"responseValid_{i}" in credit[1] for i in range(4))
        assert "outstanding < 4'h4" in pool, "Pending RAM read must consume a result credit"
        assert "outstanding < 4'h3" in pool, "Prefetch must reserve an urgent result credit"
        assert re.search(r"reg +\[1:0\] +lockedSlot;", pool)
        assert "io_eligible" in scheduler and "prefetchSafe" in scheduler
    else:
        # Independently rebuildable original synchronous-pool fallback.
        assert re.search(r"_responses_io_count\} \+ \{3'h0, pending\} < 4'h4", pool)
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
version = "4d50563300010002" if geometry.banks == 4 else "4d50563300010001"
assert version in perf.lower(), "Tensor memory statistics ABI disagrees with L2 profile"
cluster = (rtl / 'CommandFrontendCluster.sv').read_text()
assert "64'h10004" in cluster.lower(), 'Expected read_assembled-only capability'
assert 'reg  [1:0]  dmaLoadMode' not in cluster and 'dmaLoadMode_0 <=' not in cluster
assert 'modes_0 <=' not in (rtl / 'DmaLoadGroup.sv').read_text()
print(f"MERGED_S1_STRUCTURE=PASS frontend=3 banks={geometry.banks} MaxPool=3 l2=S5_CACHED_HEADS dma=READ_ASSEMBLED_ONLY mode_id=2 capability=0x10004")
