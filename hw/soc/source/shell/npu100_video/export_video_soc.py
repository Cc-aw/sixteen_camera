#!/usr/bin/env python3
"""Export checked Taihang collateral into the existing video project's layout."""
import hashlib
import json
import shutil
import sys
import tempfile
from datetime import datetime, timezone
from pathlib import Path

rtl, checkout, destination = map(lambda p: Path(p).resolve(), sys.argv[1:])
config = rtl.parent.name
if not (rtl / "TaihangSoCFPGATestHarness.sv").is_file():
    raise SystemExit("Missing TaihangSoCFPGATestHarness.sv")
destination.mkdir(parents=True, exist_ok=True)
stage = Path(tempfile.mkdtemp(prefix=".npu100-export-", dir=destination))
try:
    shutil.copytree(rtl, stage / "gen-collateral")
    hashes = []
    for folder in ("generators", "fpga/src"):
        for source in sorted((checkout / folder).rglob("*.scala")):
            if "target" not in source.parts:
                digest = hashlib.sha256(source.read_bytes()).hexdigest()
                hashes.append(f"{digest}  {source.relative_to(checkout)}\n")
    (stage / "EFFECTIVE_SCALA.sha256").write_text("".join(hashes))
    context = {
        "config": config,
        "sub_project": "taihang_soc",
        "generated_at_utc": datetime.now(timezone.utc).isoformat(),
        "build_workspace": str(checkout),
        "source_workspace": json.loads((checkout / ".npu100-video-workspace.json").read_text()),
        "build_sbt_sha256": hashlib.sha256((checkout / "build.sbt").read_bytes()).hexdigest(),
        "validation": "RTL structure, AXI ports, FBus ID groups; no Vivado implementation",
    }
    (stage / "GENERATION_CONTEXT.json").write_text(json.dumps(context, indent=2) + "\n")
    target = destination / config
    if target.exists():
        # Keep the previous generation outside the selectable SoC trees.
        backups = destination.parent / "soc-backups"
        backups.mkdir(exist_ok=True)
        backup = backups / (config + "." + datetime.now(timezone.utc).strftime("%Y%m%dT%H%M%S%fZ"))
        target.rename(backup)
        try:
            stage.rename(target)
        except BaseException:
            backup.rename(target)
            raise
    else:
        stage.rename(target)
    print(f"NPU100_VIDEO_EXPORTED={target / 'gen-collateral'}")
finally:
    if stage.exists():
        shutil.rmtree(stage)
