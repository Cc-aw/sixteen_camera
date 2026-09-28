#!/usr/bin/env python3
"""Record and verify the exact Scala/resources and generated RTL of this build."""
import argparse
import hashlib
from pathlib import Path


def source_files(root):
    folders = ("src/main", "fpga/src/main", "rocket-chip/src/main", "saturn/src/main")
    files = [p for folder in folders for p in (root / folder).rglob("*") if p.is_file()]
    files += [root / "fpga/scripts" / name for name in (
        "apply_xcvu13p_gemmini_64x64_acc256_wide_uram.sh",
        "apply_xcvu13p_soc_cache_bram.sh", "apply_result_bram.sh")]
    return files


def manifest(base, files):
    return "".join(f"{hashlib.sha256(p.read_bytes()).hexdigest()}  {p.relative_to(base).as_posix()}\n"
                   for p in sorted(files))


def rtl_files(rtl):
    excluded = {"RTL_MANIFEST.sha256", "SOURCE_MANIFEST.sha256", "SOURCE_FINGERPRINT"}
    return [p for p in rtl.rglob("*") if p.is_file() and p.name not in excluded]


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("mode", choices=("hash", "write", "check"))
    parser.add_argument("--root", type=Path, required=True)
    parser.add_argument("--rtl", type=Path)
    args = parser.parse_args()
    root = args.root.resolve()
    source = manifest(root, source_files(root))
    digest = hashlib.sha256(source.encode()).hexdigest()
    if args.mode == "hash":
        print(digest)
        return
    rtl = args.rtl.resolve()
    rtl_manifest = manifest(rtl, rtl_files(rtl))
    expected = {"SOURCE_MANIFEST.sha256": source, "SOURCE_FINGERPRINT": digest + "\n",
                "RTL_MANIFEST.sha256": rtl_manifest}
    for name, contents in expected.items():
        path = rtl / name
        if args.mode == "write":
            path.write_text(contents)
        elif not path.is_file() or path.read_text() != contents:
            raise SystemExit(f"Manifest mismatch: {path}; regenerate RTL after a source change")
    print(f"NPU_0914_MANIFEST=PASS source={digest}")


if __name__ == "__main__":
    main()
