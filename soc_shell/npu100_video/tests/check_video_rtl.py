#!/usr/bin/env python3
"""Check the emitted video interface, not just the generator parameters."""
from pathlib import Path
import re
import sys

rtl = Path(sys.argv[1])
model = sys.argv[2] if len(sys.argv) > 2 else "TaihangSoCFPGATestHarness"
top = (rtl / (model + ".sv")).read_text()


def port(direction, name, width):
    dimensions = rf"\[{width - 1}:0\]\s+" if width > 1 else ""
    assert re.search(rf"\b{direction}\s+{dimensions}{name}\b", top), (direction, name, width)


for channel in ("aw", "ar"):
    port("input", f"axi4_fbus_{channel}_bits_id", 5)
    port("input", f"axi4_fbus_{channel}_bits_addr", 33)
for channel in ("b", "r"):
    port("output", f"axi4_fbus_{channel}_bits_id", 5)
port("input", "axi4_fbus_w_bits_data", 256)
port("output", "axi4_fbus_r_bits_data", 256)
for interface, width, address_width in (("mem", 256, 33), ("mmio", 64, 29)):
    for channel in ("aw", "ar"):
        port("output", f"axi4_{interface}_{channel}_bits_id", 4)
        port("output", f"axi4_{interface}_{channel}_bits_addr", address_width)
    port("output", f"axi4_{interface}_w_bits_data", width)
    port("input", f"axi4_{interface}_r_bits_data", width)
assert not re.search(r"\bspi_", top), "Unexpected board SPI port"
assert "replay_release" in (rtl / "RoccCommandRouter.sv").read_text()
divider = (rtl / "IterativeIntegerDivider.sv").read_text()
assert "requestCapturePending" in divider and "requestIn1" in divider
print("NPU100_VIDEO_RTL=PASS FBus=256/5 MMIO=64/4 memory=256/4 replay=yes divider_payload=yes")
