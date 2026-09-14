#!/usr/bin/env bash

set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
GEMMINI_DIR="${ROOT_DIR}/generators/gemmini/software/gemmini-rocc-tests"
MODEL_DIR="${ROOT_DIR}/generators/gemmini/software/gemmini-ort/models/detection"
MODEL="${YOLOV5NU_MODEL:-${MODEL_DIR}/yolov5nu-gemmini-int8-img320.onnx}"
MANIFEST="${YOLOV5NU_MANIFEST:-${MODEL%.onnx}.graph.json}"
IMAGE="${YOLOV5NU_IMAGE:-${MODEL_DIR}/calibration/coco128/images/train2017/000000000009.jpg}"
STEM="${YOLOV5NU_STEM:-yolov5nu-gemmini-img320}"
RISCV="${RISCV:-${ROOT_DIR}/.conda-env/riscv-tools}"
PYTHON="${PYTHON:-python}"
EXTRA_CFLAGS="${YOLOV5NU_CFLAGS:-}"
EXTRA_LFLAGS="${YOLOV5NU_LFLAGS:-}"
NMS_SCORE_THRESHOLD="${YOLOV5NU_NMS_SCORE_THRESHOLD:-0.25}"
NMS_IOU_THRESHOLD="${YOLOV5NU_NMS_IOU_THRESHOLD:-0.45}"
PHYSICAL_LAYOUT="${YOLOV5NU_PHYSICAL_LAYOUT:-nchw-bridge}"
SILU_MODE="${YOLOV5NU_SILU_MODE:-separate}"
SILU_KERNEL="${YOLOV5NU_SILU_KERNEL:-scalar}"
KERNEL_MODE="${YOLOV5NU_KERNEL_MODE:-scalar}"
COPY_KERNEL="${YOLOV5NU_COPY_KERNEL:-${KERNEL_MODE}}"
ADD_KERNEL="${YOLOV5NU_ADD_KERNEL:-${KERNEL_MODE}}"
MAXPOOL_KERNEL="${YOLOV5NU_MAXPOOL_KERNEL:-${KERNEL_MODE}}"
RESIZE_KERNEL="${YOLOV5NU_RESIZE_KERNEL:-${KERNEL_MODE}}"
HEAD_LOWERING="${YOLOV5NU_HEAD_LOWERING:-generic}"
HEAD_KERNEL="${YOLOV5NU_HEAD_KERNEL:-baseline}"
HEAD_OUTPUT_MODE="${YOLOV5NU_HEAD_OUTPUT_MODE:-full}"
HEAD_CANDIDATE_KERNEL="${YOLOV5NU_HEAD_CANDIDATE_KERNEL:-scalar}"
STAGE7_MODE="${YOLOV5NU_STAGE7_MODE:-none}"
STAGE8_MODE="${YOLOV5NU_STAGE8_MODE:-none}"
STAGE8_ADD_NAME="${YOLOV5NU_STAGE8_ADD_NAME:-/model.2/m/m.0/Add}"
MEMORY_STAGE="${YOLOV5NU_MEMORY_STAGE:-none}"
DIAGNOSTIC_LAYER_STATS="${YOLOV5NU_DIAGNOSTIC_LAYER_STATS:-0}"
DISABLE_FUSED_SILU_CONV="${YOLOV5NU_DISABLE_FUSED_SILU_CONV:-}"
DIAGNOSTIC_FINGERPRINT="${YOLOV5NU_DIAGNOSTIC_FINGERPRINT:-0}"

GENERATOR_EXTRA_ARGS=()
if [[ "${DIAGNOSTIC_LAYER_STATS}" == "1" ]]; then
  GENERATOR_EXTRA_ARGS+=(--diagnostic-layer-stats)
fi
if [[ -n "${DISABLE_FUSED_SILU_CONV}" ]]; then
  GENERATOR_EXTRA_ARGS+=(--disable-fused-silu-conv "${DISABLE_FUSED_SILU_CONV}")
fi
if [[ "${DIAGNOSTIC_FINGERPRINT}" == "1" ]]; then
  GENERATOR_EXTRA_ARGS+=(--diagnostic-fingerprint)
fi

if [[ ! -x "${RISCV}/bin/riscv64-unknown-elf-gcc" ]]; then
  echo "error: RISC-V compiler not found under ${RISCV}" >&2
  exit 2
fi

"${PYTHON}" "${ROOT_DIR}/scripts/yolov5nu_graph_parser.py" \
  --model "${MODEL}" --output "${MANIFEST}"
"${PYTHON}" "${GEMMINI_DIR}/imagenet/generate_yolov5nu_baremetal.py" \
  --model "${MODEL}" --manifest "${MANIFEST}" --image "${IMAGE}" --stem "${STEM}" \
  --physical-layout "${PHYSICAL_LAYOUT}" \
  --silu-mode "${SILU_MODE}" \
  --silu-kernel "${SILU_KERNEL}" \
  --kernel-mode "${KERNEL_MODE}" \
  --copy-kernel "${COPY_KERNEL}" \
  --add-kernel "${ADD_KERNEL}" \
  --maxpool-kernel "${MAXPOOL_KERNEL}" \
  --resize-kernel "${RESIZE_KERNEL}" \
  --head-lowering "${HEAD_LOWERING}" \
  --head-kernel "${HEAD_KERNEL}" \
  --head-output-mode "${HEAD_OUTPUT_MODE}" \
  --head-candidate-kernel "${HEAD_CANDIDATE_KERNEL}" \
  --stage7-mode "${STAGE7_MODE}" \
  --stage8-mode "${STAGE8_MODE}" \
  --stage8-add-name "${STAGE8_ADD_NAME}" \
  --memory-stage "${MEMORY_STAGE}" \
  "${GENERATOR_EXTRA_ARGS[@]}" \
  --nms-score-threshold "${NMS_SCORE_THRESHOLD}" \
  --nms-iou-threshold "${NMS_IOU_THRESHOLD}"

if [[ "${SILU_KERNEL}" == "opencv-rvv" ]]; then
  source "${ROOT_DIR}/scripts/opencv_rvv_baremetal_env.sh"
  OPENCV_OBJECT_DIR="${ROOT_DIR}/build/xcvu13p/opencv_rvv/${STEM}"
  OPENCV_OBJECT="${OPENCV_OBJECT_DIR}/yolov5nu_silu_opencv_rvv.o"
  mkdir -p "${OPENCV_OBJECT_DIR}"
  "${OPENCV_RVV_CXX}" \
    "-march=${OPENCV_RVV_ARCH}" "-mabi=${OPENCV_RVV_ABI}" \
    -O2 -mcmodel=medany -std=c++11 -ffunction-sections -fdata-sections \
    -fno-exceptions -fno-rtti -fno-threadsafe-statics -fno-use-cxa-atexit \
    -DOPENCV_DISABLE_THREAD_SUPPORT \
    -include "${ROOT_DIR}/fpga/xcvu13p/tests/opencv_rvv/include/opencv_rvv_baremetal_compat.hpp" \
    -I"${ROOT_DIR}/fpga/xcvu13p/tests/opencv_rvv/include" \
    -I"${GEMMINI_DIR}" -I"${OPENCV_RVV_SOURCE}/modules/core/include" \
    -c "${GEMMINI_DIR}/imagenet/yolov5nu_silu_opencv_rvv.cpp" \
    -o "${OPENCV_OBJECT}"
  EXTRA_LFLAGS="${EXTRA_LFLAGS} ${OPENCV_OBJECT}"
fi

make -B \
  -C "${GEMMINI_DIR}/build/imagenet" \
  -f "${GEMMINI_DIR}/imagenet/Makefile" \
  abs_top_srcdir="${GEMMINI_DIR}" \
  src_dir="${GEMMINI_DIR}/imagenet" \
  XLEN=64 \
  CC_BAREMETAL="${RISCV}/bin/riscv64-unknown-elf-gcc" \
  RVV=1 \
  EXTRA_CFLAGS="${EXTRA_CFLAGS}" \
  LFLAGS="${EXTRA_LFLAGS}" \
  "${STEM}-baremetal-uart"

ELF="${GEMMINI_DIR}/build/imagenet/${STEM}-baremetal-uart"
echo
echo "Built: ${ELF}"
echo "Load it with:"
echo "  sudo ${ROOT_DIR}/scripts/xcvu13p_openocd_load_elf.sh ${ELF} 0x80000000"
