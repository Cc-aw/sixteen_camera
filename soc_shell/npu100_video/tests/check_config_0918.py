#!/usr/bin/env python3
"""Verify that the timing revision preserves the requested hardware shape."""
from pathlib import Path
import re

root = Path(__file__).resolve().parents[1]
config = (root / "fpga/src/main/scala/xcvu13p_gemmini_64x64_packed_inference_ram/Configs.scala").read_text()

expected = {
    "clock": r"freqMHz:\s*Double\s*=\s*100\.0",
    "spatial output": r"spatialArrayOutputType\s*=\s*SInt\(24\.W\)",
    "FP16 scale units": r"multiplicand_t\s*=\s*gemmini\.Float\(5,\s*11\),\s*num_scale_units\s*=\s*64",
    "RS load": r"reservation_station_entries_ld\s*=\s*16",
    "RS store": r"reservation_station_entries_st\s*=\s*8",
    "RS execute": r"reservation_station_entries_ex\s*=\s*32",
    "load queue": r"ld_queue_length\s*=\s*16",
    "store queue": r"st_queue_length\s*=\s*8",
    "execute queue": r"ex_queue_length\s*=\s*16",
    "DMA outstanding": r"max_in_flight_mem_reqs\s*=\s*32",
}
for name, pattern in expected.items():
    assert re.search(pattern, config), f"missing preserved 0918 setting: {name}"

assert "spatialArrayOutputType = SInt(20.W)" not in config
assert "spatialArrayOutputType = SInt(32.W)" not in config
print("NPU_0918_CONFIG=PASS clock=100 scale=64 RS=16/8/32 queues=16/8/16 DMA=32 PE=INT24")
