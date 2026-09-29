#!/usr/bin/env python3
"""Apply or verify the Chipyard source capacity and independent AXI ID groups for FBus."""

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

    ports = chipyard_root / (
        "generators/rocket-chip/src/main/scala/subsystem/Ports.scala"
    )
    ports_text = ports.read_text()
    old_params = "case class SlavePortParams(beatBytes: Int, idBits: Int, sourceBits: Int)"
    new_params = "case class SlavePortParams(beatBytes: Int, idBits: Int, sourceBits: Int, fifoBits: Int = 1)"
    if new_params not in ports_text:
        if ports_text.count(old_params) != 1:
            raise SystemExit("Unexpected SlavePortParams definition")
        ports_text = ports_text.replace(old_params, new_params)
        ports_text = ports_text.replace("  private val fifoBits = 1\n", "", 1)
        marker = '  slavePortParamsOpt.map { params =>\n    fbus.coupleFrom'
        replacement = ('  slavePortParamsOpt.map { params =>\n'
                       '    val fifoBits = params.fifoBits\n'
                       '    require(fifoBits >= 0 && fifoBits <= params.idBits)\n'
                       '    require(params.sourceBits >= fifoBits + 1)\n'
                       '    fbus.coupleFrom')
        if ports_text.count(marker) != 1:
            raise SystemExit("Unexpected slave AXI coupling")
        ports_text = ports_text.replace(marker, replacement)
    if ports_text != ports.read_text():
        if not apply:
            raise SystemExit("Slave AXI ID groups are not configurable; run --apply")
        ports.write_text(ports_text)

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
    previous_definition = new_definition
    new_definition = new_definition.replace(
        "source_bits: Int = 4)", "source_bits: Int = 4, fifo_bits: Int = 1)"
    ).replace("sourceBits = source_bits)", "sourceBits = source_bits, fifoBits = fifo_bits)")
    if previous_definition in subsystem_text:
        old_definition = previous_definition
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

    taihang_text = taihang.read_text()
    start = taihang_text.index(marker)
    end = taihang_text.index("  ) ++", start)
    block = taihang_text[start:end]
    if "    fifo_bits = 5,\n" not in block:
        if not apply or block.count(configured) != 1:
            raise SystemExit("Target does not set fifo_bits=5; run --apply")
        if "    fifo_bits = 4,\n" in block:
            block = block.replace("    fifo_bits = 4,\n", "    fifo_bits = 5,\n")
        elif "    fifo_bits = 3,\n" in block:
            block = block.replace("    fifo_bits = 3,\n", "    fifo_bits = 5,\n")
        else:
            block = block.replace(configured, configured + "    fifo_bits = 5,\n")
        taihang.write_text(taihang_text[:start] + block + taihang_text[end:])

    taihang_text = taihang.read_text()
    start = taihang_text.index(marker)
    end = taihang_text.index("  ) ++", start)
    block = taihang_text[start:end]
    if "    id_bits = 5,\n" not in block:
        if not apply or block.count("    id_bits = 4,\n") != 1:
            raise SystemExit("Target requires a five-bit external AXI ID; run --apply")
        block = block.replace("    id_bits = 4,\n", "    id_bits = 5,\n")
        taihang_text = taihang_text[:start] + block + taihang_text[end:]
    width_config = (
        "class WithTaihangPostprocessFrontBus extends Config((site, here, up) => {\n"
        "  case freechips.rocketchip.subsystem.FrontBusKey =>\n"
        "    up(freechips.rocketchip.subsystem.FrontBusKey, site).copy(beatBytes = 32)\n"
        "})\n\n"
    )
    if width_config not in taihang_text:
        if not apply:
            raise SystemExit("Missing 256-bit postprocess FrontBus config; run --apply")
        taihang_text = taihang_text.replace(marker, width_config + marker, 1)
    target_prefix = marker + "\n  new WithTaihangPostprocessFrontBus ++"
    if target_prefix not in taihang_text:
        if not apply:
            raise SystemExit("Target FrontBus is not 256-bit; run --apply")
        taihang_text = taihang_text.replace(marker, target_prefix, 1)
    if apply and taihang_text != taihang.read_text():
        taihang.write_text(taihang_text)

    print("FRONT_BUS_BITS=256")
    print("P1C2_CHIPYARD_CONFIG=PASS")
    print("AXI_ID_GROUPS=32")
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
