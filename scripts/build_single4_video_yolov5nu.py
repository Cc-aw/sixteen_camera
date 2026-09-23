#!/usr/bin/env python3
"""Build a one-worker DIM4 video YOLOv5nu ELF without editing dual-DIM16 sources."""

from pathlib import Path
import argparse
import hashlib
import shutil
import subprocess


ROOT = Path(__file__).resolve().parents[1]
SOURCE = ROOT / "sw"
CHIPYARD = Path("/home/wzr/chipyard")
PARAMS = (CHIPYARD / "generators/gemmini/software/gemmini-rocc-tests/include/"
          "gemmini_params_taihang_single_4x4_packed.h")
WORK = SOURCE / "build/single4_video/work"
OUTPUT = SOURCE / "build/gemmini_single4_video_yolov5nu.elf"


def replace_once(path: Path, old: str, new: str) -> None:
    data = path.read_text()
    if data.count(old) != 1:
        raise RuntimeError(f"expected exactly one variant marker in {path}: {old!r}")
    path.write_text(data.replace(old, new))


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("--output", type=Path, default=OUTPUT,
                        help="ELF destination; the default keeps the existing name")
    output = parser.parse_args().output.resolve()
    params = PARAMS.read_text()
    if "#define DIM 4" not in params or "#define XCUSTOM_ACC 3" not in params:
        raise RuntimeError("generated parameters are not DIM4/custom3")

    WORK.mkdir(parents=True, exist_ok=True)
    shutil.copy2(SOURCE / "Makefile", WORK / "Makefile")
    shutil.copy2(SOURCE / "linker_ai_video.ld", WORK / "linker_ai_video.ld")
    shutil.copytree(SOURCE / "src", WORK / "src", dirs_exist_ok=True)
    model_dir = WORK / "yolov5/dim16_dual"
    model_dir.mkdir(parents=True, exist_ok=True)
    for path in (SOURCE / "yolov5/dim16_dual").iterdir():
        if path.is_file():
            shutil.copy2(path, model_dir / path.name)
    generator_link = WORK / "yolov5/generators"
    if not generator_link.exists():
        generator_link.symlink_to(SOURCE / "yolov5/generators", target_is_directory=True)
    yolov2_link = WORK / "yolov2"
    if not yolov2_link.exists():
        yolov2_link.symlink_to(SOURCE / "yolov2", target_is_directory=True)

    replace_once(WORK / "src/ai_model_backend.h",
                 "#define AI_MODEL_WORKER_COUNT 2U",
                 "#define AI_MODEL_WORKER_COUNT 1U")
    replace_once(WORK / "src/ai_batch_runtime_stream.c",
                 "#define STREAM_MODEL_TIMEOUT (SOC_CLOCK_HZ * UINT64_C(50))",
                 "#define STREAM_MODEL_TIMEOUT (SOC_CLOCK_HZ * UINT64_C(300))")
    replace_once(model_dir / "yolov5nu_dim16_dual.h",
                 "#define YOLOV5NU_DIM16_WORKER_COUNT 2U",
                 "#define YOLOV5NU_DIM16_WORKER_COUNT 1U")
    replace_once(model_dir / "yolov5nu_dim16_dual.c",
                 "#define GEMMINI_POOL_RUNTIME_DISPATCH 1",
                 "/* One accelerator: use XCUSTOM_ACC=3 for every Gemmini command. */\nextern unsigned gemmini_pool_active_worker;")
    replace_once(model_dir / "yolov5nu_dim16_dual.c",
                 '#if DIM != 16\n#error "This runtime requires the current DIM16 Gemmini parameters"',
                 '#if DIM != 4\n#error "Single-worker video runtime requires DIM4 Gemmini parameters"')
    replace_once(model_dir / "yolov5nu_dim16_dual.c",
                 "  if (worker_id == 0U) {\n    ROCC_INSTRUCTION(3, result, config, placeholder, k_COUNTER);\n  } else {\n    ROCC_INSTRUCTION(2, result, config, placeholder, k_COUNTER);\n  }",
                 "  (void)worker_id;\n  ROCC_INSTRUCTION(3, result, config, placeholder, k_COUNTER);")
    replace_once(model_dir / "yolov5nu_dim16_dual.c",
                 "  if (worker_id == 0U)\n    __asm__ volatile (\"csrr %0, 0x7c2\" : \"=r\" (value) :: \"memory\");\n  else\n    __asm__ volatile (\"csrr %0, 0x7c3\" : \"=r\" (value) :: \"memory\");",
                 "  (void)worker_id;\n  __asm__ volatile (\"csrr %0, 0x7c2\" : \"=r\" (value) :: \"memory\");")
    replace_once(WORK / "src/ai_model_backend_yolov5nu.c",
                 "YOLOv5nu dual + hardware postprocess",
                 "YOLOv5nu single4 + hardware postprocess")
    replace_once(WORK / "src/ai_model_backend_yolov5nu.c",
                 "YOLOv5nu dual CPU postprocess",
                 "YOLOv5nu single4 CPU postprocess")
    replace_once(WORK / "src/main.c",
                 "t=fixed image dual Gemmini test",
                 "t=fixed image single Gemmini test")

    reference_root = (SOURCE / "../../../ALL_MIPI_HDMI/4k/4k60to1k60").resolve()
    if not reference_root.is_dir():
        raise RuntimeError(f"board support tree is missing: {reference_root}")
    command = [
        "make", "-C", str(WORK), "-j4", "AI_MODEL=yolov5nu",
        f"REFERENCE_ROOT={reference_root}", f"GEMMINI_PARAMS={PARAMS}",
        "all",
    ]
    print("BUILD_COMMAND=" + " ".join(command), flush=True)
    subprocess.run(command, check=True)
    built_elf = WORK / "build/hdmi_tx_test.elf"
    if not built_elf.is_file():
        raise RuntimeError(f"build did not create {built_elf}")
    output.parent.mkdir(parents=True, exist_ok=True)
    shutil.copy2(built_elf, output)
    digest = hashlib.sha256(output.read_bytes()).hexdigest()
    print(f"SINGLE4_VIDEO_ELF={output}")
    print(f"SINGLE4_VIDEO_SHA256={digest}")
    print("SINGLE4_VIDEO_BUILD=PASS")


if __name__ == "__main__":
    main()
