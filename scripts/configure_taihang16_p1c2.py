#!/usr/bin/env python3
"""Apply or verify the Chipyard source-capacity change required by P1C-2."""

import argparse
from pathlib import Path


CONFIG_NAME = (
    "TaihangSoC1Rocket1RVV2Gemmini16x16PackedFullOps256BitConfig"
)


def configure(chipyard_root: Path, apply: bool) -> None:
    subsystem = chipyard_root / (
        "generators/rocket-chip/src/main/scala/subsystem/Configs.scala"
    )
    taihang = chipyard_root / "fpga/src/main/scala/taihang_soc/Configs.scala"

    subsystem_text = subsystem.read_text()
    old_definition = (
        "class WithCustomSlavePort (data_width: Int, id_bits: Int) "
        "extends Config((site, here, up) => {\n"
        "  case ExtIn  => Some(SlavePortParams(beatBytes = data_width/8, "
        "idBits = id_bits, sourceBits = 4))\n})"
    )
    new_definition = (
        "class WithCustomSlavePort (data_width: Int, id_bits: Int, "
        "source_bits: Int = 4) extends Config((site, here, up) => {\n"
        "  case ExtIn  => Some(SlavePortParams(beatBytes = data_width/8, "
        "idBits = id_bits, sourceBits = source_bits))\n})"
    )
    if new_definition not in subsystem_text:
        if not apply or subsystem_text.count(old_definition) != 1:
            raise SystemExit(
                "WithCustomSlavePort is not P1C-2 capable; run with --apply"
            )
        subsystem.write_text(subsystem_text.replace(old_definition,
                                                    new_definition))

    taihang_text = taihang.read_text()
    marker = f"class {CONFIG_NAME} extends Config("
    start = taihang_text.index(marker)
    end = taihang_text.index("  ) ++", start)
    block = taihang_text[start:end]
    configured = "    source_bits = 7,\n"
    if configured not in block:
        old_id = "    id_bits = 4,\n"
        if not apply or block.count(old_id) != 1:
            raise SystemExit(
                f"{CONFIG_NAME} does not set source_bits=7; run with --apply"
            )
        block = block.replace(old_id, old_id + configured)
        taihang.write_text(taihang_text[:start] + block + taihang_text[end:])

    print("P1C2_CHIPYARD_CONFIG=PASS")
    print(f"CONFIG={CONFIG_NAME}")
    print("SOURCE_BITS=7")


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument(
        "--chipyard-root", type=Path, default=Path("/home/wzr/chipyard")
    )
    parser.add_argument(
        "--apply", action="store_true",
        help="modify Chipyard when the required settings are absent"
    )
    args = parser.parse_args()
    configure(args.chipyard_root, args.apply)


if __name__ == "__main__":
    main()
