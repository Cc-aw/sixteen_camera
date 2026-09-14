#!/usr/bin/env python3
"""Turn the validated Stage8F program into a dual-DIM16 cooperative runtime."""

from pathlib import Path

HERE = Path(__file__).resolve().parent
SOURCE = (HERE.parent / "model/"
          "yolov5nu-stage8f-dual-consumer-spad-reuse-img640x480-"
          "image025-profile.c")
OUTPUT = HERE / "yolov5nu_dim16_dual.c"

HARDWARE_CALLS = (
    "tiled_conv_auto(",
    "gemmini_splitk_",
    "gemmini_pair_splitk_",
    "gemmini_multislice_",
    "add_gemmini_shared",
)


def matching_brace(text: str, opening: int) -> int:
    depth = 1
    index = opening + 1
    while depth:
        if text[index] == "{":
            depth += 1
        elif text[index] == "}":
            depth -= 1
        index += 1
    return index - 1


def top_level_blocks(body: str, start: int) -> list[str]:
    blocks = []
    index = start
    while index < len(body):
        if body[index].isspace():
            index += 1
            continue
        if body[index] != "{":
            raise RuntimeError(f"unexpected non-block graph text at {index}")
        end = matching_brace(body, index)
        blocks.append(body[index:end + 1])
        index = end + 1
    return blocks


def build() -> str:
    source = SOURCE.read_text()
    main_at = source.index("int main(void) {")
    main_open = source.index("{", main_at)
    main_close = matching_brace(source, main_open)
    prefix = source[:main_at]
    main_body = source[main_open + 1:main_close]
    graph_marker = "uint64_t graph_start = yolo_profile_clock();"
    graph_at = main_body.index(graph_marker) + len(graph_marker)
    graph_end = main_body.index("uint64_t graph_cycles", graph_at)
    blocks = top_level_blocks(main_body[:graph_end], graph_at)
    if len(blocks) != 167:
        raise RuntimeError(f"expected 167 graph blocks, got {len(blocks)}")
    hardware_count = sum(any(call in block for call in HARDWARE_CALLS)
                         for block in blocks)
    if hardware_count != 78:
        raise RuntimeError(f"expected 78 accelerator blocks, got {hardware_count}")

    prefix = prefix.replace(
        '#include "include/gemmini.h"',
        '#define GEMMINI_POOL_RUNTIME_DISPATCH 1\n'
        '#include "include/gemmini.h"')
    prefix = prefix.replace(
        '#include "yolov5nu-stage8f-dual-consumer-spad-reuse-img640x480-'
        'image025-profile_params.h"',
        '#include "yolov5nu-stage8f-dual-consumer-spad-reuse-img640x480-'
        'image025-profile_params.h"\n'
        '#include "yolov5nu_dim16_dual.h"\n\n'
        '#if DIM != 16\n'
        '#error "This runtime requires the current DIM16 Gemmini parameters"\n'
        '#endif')
    prefix = prefix.replace(
        "static elem_t activation_arena[2217600] row_align(1);",
        "static elem_t activation_arenas[YOLOV5NU_DIM16_WORKER_COUNT]"
        "[2217600] row_align(1);\nstatic elem_t *activation_arena;")
    prefix = prefix.replace(
        "static elem_t conv_input_scratch[YOLOV5NU_CONV_INPUT_SCRATCH] "
        "row_align(1);",
        "static elem_t conv_input_scratches[YOLOV5NU_DIM16_WORKER_COUNT]"
        "[YOLOV5NU_CONV_INPUT_SCRATCH] row_align(1);\n"
        "static elem_t *conv_input_scratch;")
    prefix = prefix.replace(
        "static elem_t conv_output_scratch[YOLOV5NU_CONV_OUTPUT_SCRATCH] "
        "row_align(1);",
        "static elem_t conv_output_scratches[YOLOV5NU_DIM16_WORKER_COUNT]"
        "[YOLOV5NU_CONV_OUTPUT_SCRATCH] row_align(1);\n"
        "static elem_t *conv_output_scratch;")

    cases = []
    for stage, block in enumerate(blocks):
        block = block.replace("yolov5nu_input", "model_input")
        wait = any(call in block for call in HARDWARE_CALLS)
        tail = ("      context->stage++;\n"
                "      context->waiting = 1U;\n"
                "      context->poll_armed = 0U;\n"
                "      return YOLOV5NU_DIM16_RUNNING;" if wait else
                "      context->stage++;\n      break;")
        cases.append(f"    case {stage}U:\n{block}\n{tail}")

    runtime = r'''

unsigned gemmini_pool_active_worker;

enum { YOLOV5NU_GRAPH_STAGE_COUNT = 167U };

struct yolov5nu_worker_context {
  const elem_t *input;
  uint32_t stage;
  uint32_t active;
  uint32_t waiting;
  uint32_t poll_armed;
  uint64_t silu_config_cycles[69];
};

static struct yolov5nu_worker_context
  worker_contexts[YOLOV5NU_DIM16_WORKER_COUNT];

static inline uint64_t read_worker_busy(uint32_t worker_id) {
  uint64_t value;
  if (worker_id == 0U)
    __asm__ volatile ("csrr %0, 0x7c2" : "=r" (value) :: "memory");
  else
    __asm__ volatile ("csrr %0, 0x7c3" : "=r" (value) :: "memory");
  return value & 1U;
}

static void select_worker_memory(uint32_t worker_id) {
  gemmini_pool_active_worker = worker_id;
  activation_arena = activation_arenas[worker_id];
  conv_input_scratch = conv_input_scratches[worker_id];
  conv_output_scratch = conv_output_scratches[worker_id];
}

void yolov5nu_dim16_dual_init(void) {
  memset(worker_contexts, 0, sizeof(worker_contexts));
  gemmini_pool_active_worker = 0U;
}

int yolov5nu_dim16_worker_is_idle(uint32_t worker_id) {
  return worker_id < YOLOV5NU_DIM16_WORKER_COUNT &&
         worker_contexts[worker_id].active == 0U;
}

int yolov5nu_dim16_worker_start(uint32_t worker_id, const int8_t *input) {
  struct yolov5nu_worker_context *context;
  if (worker_id >= YOLOV5NU_DIM16_WORKER_COUNT || input == NULL ||
      !yolov5nu_dim16_worker_is_idle(worker_id))
    return YOLOV5NU_DIM16_ERROR;
  context = &worker_contexts[worker_id];
  memset(context, 0, sizeof(*context));
  context->input = (const elem_t *)input;
  context->active = 1U;
  select_worker_memory(worker_id);
  gemmini_flush(0);
  return YOLOV5NU_DIM16_RUNNING;
}

int yolov5nu_dim16_worker_start_reference(uint32_t worker_id) {
  return yolov5nu_dim16_worker_start(worker_id,
                                     (const int8_t *)yolov5nu_input);
}

uint64_t yolov5nu_dim16_worker_busy(uint32_t worker_id) {
  return worker_id < YOLOV5NU_DIM16_WORKER_COUNT ?
         read_worker_busy(worker_id) : 0U;
}

uint32_t yolov5nu_dim16_worker_stage(uint32_t worker_id) {
  return worker_id < YOLOV5NU_DIM16_WORKER_COUNT ?
         worker_contexts[worker_id].stage : YOLOV5NU_GRAPH_STAGE_COUNT;
}

int yolov5nu_dim16_worker_poll(uint32_t worker_id,
    struct yolov5nu_dim16_result *result) {
  struct yolov5nu_worker_context *context;
  const elem_t *model_input;
  uint64_t *silu_config_cycles;
  if (worker_id >= YOLOV5NU_DIM16_WORKER_COUNT || result == NULL)
    return YOLOV5NU_DIM16_ERROR;
  context = &worker_contexts[worker_id];
  if (context->active == 0U)
    return YOLOV5NU_DIM16_ERROR;
  select_worker_memory(worker_id);
  model_input = context->input;
  silu_config_cycles = context->silu_config_cycles;

  if (context->waiting != 0U) {
    if (context->poll_armed == 0U) {
      context->poll_armed = 1U;
      return YOLOV5NU_DIM16_RUNNING;
    }
    if (read_worker_busy(worker_id) != 0U)
      return YOLOV5NU_DIM16_RUNNING;
    gemmini_fence();
    context->waiting = 0U;
  }

  for (;;) {
    switch (context->stage) {
'''
    runtime += "\n".join(cases)
    runtime += r'''
    default: {
      struct Detection nms_detections[YOLOV5NU_DIM16_MAX_DETECTIONS];
      int nms_count;
      uint64_t logits_hash = UINT64_C(1469598103934665603);
      uint64_t scores_hash = UINT64_C(1469598103934665603);
      uint64_t dfl_hash = UINT64_C(1469598103934665603);
      int64_t logits_sum = 0;
      int64_t scores_sum = 0;
      int64_t dfl_sum = 0;
      decode_all_compute(tensor_252, 0.1129496917f, tensor_248,
                         0.007530334406f);
      nms_count = decode_nms_from_candidates(0.25f, 0.45f,
                                             nms_detections);
      result->count = nms_count < 0 ? 0U : (uint32_t)nms_count;
      if (result->count > YOLOV5NU_DIM16_MAX_DETECTIONS)
        result->count = YOLOV5NU_DIM16_MAX_DETECTIONS;
      for (uint32_t index = 0U; index < 504000U; ++index) {
        logits_sum += tensor_246[index];
        logits_hash ^= (uint8_t)tensor_246[index];
        logits_hash *= UINT64_C(1099511628211);
        scores_sum += tensor_248[index];
        scores_hash ^= (uint8_t)tensor_248[index];
        scores_hash *= UINT64_C(1099511628211);
      }
      for (uint32_t position = 0U; position < 6300U; ++position) {
        if (dfl_candidate_mask[position] == 0U)
          continue;
        for (uint32_t edge = 0U; edge < 4U; ++edge) {
          elem_t value = tensor_252[position * 4U + edge];
          dfl_sum += value;
          dfl_hash ^= (uint8_t)value;
          dfl_hash *= UINT64_C(1099511628211);
        }
      }
      result->class_logits_checksum = logits_sum;
      result->class_logits_fnv1a = logits_hash;
      result->class_scores_checksum = scores_sum;
      result->class_scores_fnv1a = scores_hash;
      result->sparse_dfl_checksum = dfl_sum;
      result->sparse_dfl_fnv1a = dfl_hash;
      result->dfl_candidate_count = (uint32_t)head_dfl_candidate_count;
      for (uint32_t index = 0U; index < result->count; ++index) {
        result->detections[index].score = nms_detections[index].score;
        result->detections[index].center_x = nms_detections[index].cx;
        result->detections[index].center_y = nms_detections[index].cy;
        result->detections[index].width = nms_detections[index].w;
        result->detections[index].height = nms_detections[index].h;
        result->detections[index].class_id = nms_detections[index].cls;
      }
      context->active = 0U;
      context->waiting = 0U;
      return YOLOV5NU_DIM16_DONE;
    }
    }
  }
}
'''
    return prefix + runtime


if __name__ == "__main__":
    OUTPUT.write_text(build())
    print(f"generated {OUTPUT}")
