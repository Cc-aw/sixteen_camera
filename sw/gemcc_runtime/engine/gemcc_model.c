#include "gemcc_model.h"

#include <stdint.h>
#include <string.h>

#if !defined(BAREMETAL)
#include <time.h>
#ifdef CLOCK_MONOTONIC
#define GEMCC_HAS_HOST_CLOCK 1
#endif
#endif

typedef struct GemccWorkspaceBlock {
  size_t bytes;
  struct GemccWorkspaceBlock *next;
  uintptr_t cookie;
  unsigned char padding[GEMCC_WORKSPACE_ALIGNMENT - 3 * sizeof(uintptr_t)];
} GemccWorkspaceBlock;

static GemccWorkspaceArena g_legacy_arena;
static GemccWorkspaceArena *g_active;

static unsigned char *arena_base(const GemccWorkspaceArena *arena) {
  return arena ? (unsigned char *)arena->base : 0;
}

static uintptr_t allocated_cookie(const GemccWorkspaceArena *arena,
                                  const GemccWorkspaceBlock *block) {
  return (uintptr_t)block ^ (uintptr_t)arena_base(arena) ^
         (uintptr_t)0xa110ca7eU;
}

static uintptr_t free_cookie(const GemccWorkspaceArena *arena,
                             const GemccWorkspaceBlock *block) {
  return (uintptr_t)block ^ (uintptr_t)arena_base(arena) ^
         (uintptr_t)0xfee1deadU;
}

static size_t align_workspace(size_t value) {
  return (value + GEMCC_WORKSPACE_ALIGNMENT - 1) &
         ~(size_t)(GEMCC_WORKSPACE_ALIGNMENT - 1);
}

static int bind_arena(GemccWorkspaceArena *arena, void *workspace,
                      size_t bytes) {
  if (!arena)
    return -1;
  if ((!workspace && bytes != 0) ||
      ((uintptr_t)workspace & (GEMCC_WORKSPACE_ALIGNMENT - 1)) != 0)
    return -1;
  arena->base = workspace;
  arena->capacity = bytes;
  arena->cursor = 0;
  arena->peak = 0;
  arena->free_list = 0;
  arena->error = 0;
  return 0;
}

static int activate_arena(GemccWorkspaceArena *arena) {
  if (!arena || !arena->base)
    return GEMCC_ERR_WORKSPACE;
  if (g_active)
    return GEMCC_ERR_STATE;
  g_active = arena;
  return GEMCC_OK;
}

static void deactivate_arena(GemccWorkspaceArena *arena) {
  if (g_active == arena)
    g_active = 0;
}

int gemcc_workspace_is_bound(void) {
  return g_active && g_active->base != 0;
}

int gemcc_workspace_owns(const void *ptr) {
  const unsigned char *p = (const unsigned char *)ptr;
  unsigned char *base = arena_base(g_active);
  return base && p >= base && p < base + g_active->capacity;
}

/* I: 当前 active arena 与请求字节数
 * P: 以 64B 对齐复用/分配 workspace block；只写独立 header，不初始化 payload
 * O: 未初始化的 payload 指针；失败返回空并置 arena error
 * A: shiroha_suki
 * T: 2026-08-29
 */
void *gemcc_workspace_alloc(size_t bytes) {
  if (!g_active || !g_active->base) {
    if (g_active)
      g_active->error = 1;
    return 0;
  }
  GemccWorkspaceArena *arena = g_active;
  unsigned char *base = arena_base(arena);
  GemccWorkspaceBlock **free_list = (GemccWorkspaceBlock **)&arena->free_list;
  size_t want = align_workspace(bytes ? bytes : 1);
  GemccWorkspaceBlock **best_link = 0;
  for (GemccWorkspaceBlock **link = free_list; *link; link = &(*link)->next) {
    GemccWorkspaceBlock *block = *link;
    if (block->bytes >= want &&
        (!best_link || block->bytes < (*best_link)->bytes))
      best_link = link;
  }
  if (best_link) {
    GemccWorkspaceBlock *block = *best_link;
    size_t remainder_bytes = block->bytes - want;
    if (remainder_bytes >= sizeof(GemccWorkspaceBlock) +
                               GEMCC_WORKSPACE_ALIGNMENT) {
      GemccWorkspaceBlock *remainder = (GemccWorkspaceBlock *)(
          (unsigned char *)block + sizeof(*block) + want);
      remainder->bytes = remainder_bytes - sizeof(*remainder);
      remainder->next = block->next;
      remainder->cookie = free_cookie(arena, remainder);
      *best_link = remainder;
      block->bytes = want;
    } else {
      *best_link = block->next;
    }
    block->next = 0;
    block->cookie = allocated_cookie(arena, block);
    return (unsigned char *)block + sizeof(*block);
  }

  size_t total = sizeof(GemccWorkspaceBlock) + want;
  size_t offset = align_workspace(arena->cursor);
  if (offset >= arena->capacity || total > arena->capacity - offset) {
    arena->error = 1;
    return 0;
  }
  GemccWorkspaceBlock *block = (GemccWorkspaceBlock *)(base + offset);
  block->bytes = want;
  block->next = 0;
  block->cookie = allocated_cookie(arena, block);
  arena->cursor = offset + total;
  if (arena->cursor > arena->peak)
    arena->peak = arena->cursor;
  return (unsigned char *)block + sizeof(*block);
}

void gemcc_workspace_free(void *ptr) {
  if (!ptr)
    return;
  if (!g_active || !g_active->base) {
    if (g_active)
      g_active->error = 1;
    return;
  }
  GemccWorkspaceArena *arena = g_active;
  unsigned char *base = arena_base(arena);
  if (!gemcc_workspace_owns(ptr) ||
      (unsigned char *)ptr < base + sizeof(GemccWorkspaceBlock)) {
    arena->error = 1;
    return;
  }
  GemccWorkspaceBlock *block = (GemccWorkspaceBlock *)(
      (unsigned char *)ptr - sizeof(GemccWorkspaceBlock));
  if (block->cookie != allocated_cookie(arena, block)) {
    arena->error = 1;
    return;
  }
  block->cookie = free_cookie(arena, block);

  GemccWorkspaceBlock *previous = 0;
  GemccWorkspaceBlock **link = (GemccWorkspaceBlock **)&arena->free_list;
  while (*link && *link < block) {
    previous = *link;
    link = &(*link)->next;
  }
  block->next = *link;
  *link = block;

  GemccWorkspaceBlock *next = block->next;
  if (next && (unsigned char *)block + sizeof(*block) + block->bytes ==
                  (unsigned char *)next) {
    block->bytes += sizeof(*next) + next->bytes;
    block->next = next->next;
  }
  if (previous &&
      (unsigned char *)previous + sizeof(*previous) + previous->bytes ==
          (unsigned char *)block) {
    previous->bytes += sizeof(*block) + block->bytes;
    previous->next = block->next;
  }
}

size_t gemcc_workspace_peak_bytes(void) {
  return g_active ? g_active->peak : 0;
}

int gemcc_workspace_failed(void) { return g_active ? g_active->error : 1; }

size_t gemcc_model_workspace_peak(const GemccModelInstance *inst) {
  return inst ? inst->arena.peak : 0;
}

int gemcc_model_workspace_failed(const GemccModelInstance *inst) {
  return inst ? inst->arena.error : 1;
}

static void copy_id(char *dest, size_t dest_bytes, const char *src) {
  if (!src)
    src = "";
  size_t n = strlen(src);
  if (n >= dest_bytes)
    n = dest_bytes - 1;
  memcpy(dest, src, n);
  dest[n] = 0;
}

const char *gemcc_status_string(int status) {
  switch (status) {
  case GEMCC_OK:
    return "ok";
  case GEMCC_ERR_INVALID_ARGUMENT:
    return "invalid argument";
  case GEMCC_ERR_ABI_MISMATCH:
    return "abi version mismatch";
  case GEMCC_ERR_HARDWARE_MISMATCH:
    return "hardware profile mismatch";
  case GEMCC_ERR_QUANT_MISMATCH:
    return "quantization profile mismatch";
  case GEMCC_ERR_MODEL_HASH:
    return "model hash mismatch";
  case GEMCC_ERR_BUFFER_TOO_SMALL:
    return "buffer too small";
  case GEMCC_ERR_WORKSPACE:
    return "workspace too small or unaligned";
  case GEMCC_ERR_UNINITIALIZED:
    return "descriptor uninitialized";
  case GEMCC_ERR_STATE:
    return "instance state illegal";
  case GEMCC_ERR_FORWARD:
    return "forward failed";
  case GEMCC_ERR_LAYOUT:
    return "layout mismatch";
  case GEMCC_ERR_DTYPE:
    return "dtype mismatch";
  case GEMCC_ERR_SHAPE:
    return "shape mismatch";
  default:
    return "unknown";
  }
}

static int same_id(const char *have, const char *want) {
  if (!have || !want || !have[0] || !want[0])
    return 0;
  return strcmp(have, want) == 0;
}

#ifndef GEMCC_HAS_MODEL_ABI
int gemcc_model_descriptor(GemccModelDescriptor *desc) {
  (void)desc;
  return GEMCC_ERR_UNINITIALIZED;
}

int gemcc_model_query(GemccModelInfo *info) {
  (void)info;
  return -1;
}

int gemcc_model_init(void *workspace, size_t workspace_bytes) {
  (void)workspace;
  (void)workspace_bytes;
  return -1;
}
#else
#include "model_abi.h"

#ifndef GEMCC_ABI_VERSION
#define GEMCC_ABI_VERSION GEMCC_MODEL_ABI_VERSION
#endif
#ifndef GEMCC_MODEL_ID
#define GEMCC_MODEL_ID "compiled-model"
#endif
#ifndef GEMCC_MODEL_HASH
#define GEMCC_MODEL_HASH ""
#endif
#ifndef GEMCC_HARDWARE_PROFILE_ID
#define GEMCC_HARDWARE_PROFILE_ID ""
#endif
#ifndef GEMCC_QUANT_MODE
#define GEMCC_QUANT_MODE ""
#endif
#ifndef GEMCC_QUANT_PROFILE_VERSION
#define GEMCC_QUANT_PROFILE_VERSION "0"
#endif
#ifndef GEMCC_INPUT_NAME
#define GEMCC_INPUT_NAME "input"
#endif
#ifndef GEMCC_OUTPUT_NAME
#define GEMCC_OUTPUT_NAME "output"
#endif
#ifndef GEMCC_INPUT_DTYPE
#define GEMCC_INPUT_DTYPE GEMCC_DTYPE_UNKNOWN
#endif
#ifndef GEMCC_OUTPUT_DTYPE
#define GEMCC_OUTPUT_DTYPE GEMCC_DTYPE_UNKNOWN
#endif
#ifndef GEMCC_INPUT_LAYOUT
#define GEMCC_INPUT_LAYOUT GEMCC_LAYOUT_UNKNOWN
#endif
#ifndef GEMCC_OUTPUT_LAYOUT
#define GEMCC_OUTPUT_LAYOUT GEMCC_LAYOUT_UNKNOWN
#endif
#ifndef GEMCC_INPUT_RANK
#define GEMCC_INPUT_RANK 0
#endif
#ifndef GEMCC_OUTPUT_RANK
#define GEMCC_OUTPUT_RANK 0
#endif
#ifndef GEMCC_INPUT_DIM0
#define GEMCC_INPUT_DIM0 0
#endif
#ifndef GEMCC_INPUT_DIM1
#define GEMCC_INPUT_DIM1 0
#endif
#ifndef GEMCC_INPUT_DIM2
#define GEMCC_INPUT_DIM2 0
#endif
#ifndef GEMCC_INPUT_DIM3
#define GEMCC_INPUT_DIM3 0
#endif
#ifndef GEMCC_OUTPUT_DIM0
#define GEMCC_OUTPUT_DIM0 0
#endif
#ifndef GEMCC_OUTPUT_DIM1
#define GEMCC_OUTPUT_DIM1 0
#endif
#ifndef GEMCC_OUTPUT_DIM2
#define GEMCC_OUTPUT_DIM2 0
#endif
#ifndef GEMCC_OUTPUT_DIM3
#define GEMCC_OUTPUT_DIM3 0
#endif
#ifndef GEMCC_CONSTANTS_BYTES
#define GEMCC_CONSTANTS_BYTES 0LL
#endif
#ifndef GEMCC_CONSTANTS_HASH
#define GEMCC_CONSTANTS_HASH ""
#endif
#ifndef GEMCC_CONSTANTS_MODE
#define GEMCC_CONSTANTS_MODE GEMCC_CONSTANTS_MODE_LINKED
#endif

static void fill_tensor(GemccTensorDesc *tensor, const char *name, int32_t dtype,
                        int32_t layout, int32_t rank, int32_t elem_bytes,
                        int64_t elems, int64_t d0, int64_t d1, int64_t d2,
                        int64_t d3) {
  memset(tensor, 0, sizeof(*tensor));
  copy_id(tensor->name, sizeof(tensor->name), name);
  tensor->dtype = dtype;
  tensor->layout = layout;
  tensor->rank = rank;
  tensor->elem_bytes = elem_bytes;
  tensor->elems = elems;
  tensor->shape[0] = d0;
  tensor->shape[1] = d1;
  tensor->shape[2] = d2;
  tensor->shape[3] = d3;
}

int gemcc_model_descriptor(GemccModelDescriptor *desc) {
  if (!desc)
    return GEMCC_ERR_INVALID_ARGUMENT;
  if ((int)GEMCC_ABI_VERSION != GEMCC_MODEL_ABI_VERSION)
    return GEMCC_ERR_ABI_MISMATCH;
  memset(desc, 0, sizeof(*desc));
  desc->abi_version = GEMCC_MODEL_ABI_VERSION;
  copy_id(desc->model_id, sizeof(desc->model_id), GEMCC_MODEL_ID);
  copy_id(desc->model_hash, sizeof(desc->model_hash), GEMCC_MODEL_HASH);
  copy_id(desc->hardware_profile_id, sizeof(desc->hardware_profile_id),
          GEMCC_HARDWARE_PROFILE_ID);
  copy_id(desc->quant_mode, sizeof(desc->quant_mode), GEMCC_QUANT_MODE);
  copy_id(desc->quant_profile_version, sizeof(desc->quant_profile_version),
          GEMCC_QUANT_PROFILE_VERSION);
  fill_tensor(&desc->input, GEMCC_INPUT_NAME, GEMCC_INPUT_DTYPE,
              GEMCC_INPUT_LAYOUT, GEMCC_INPUT_RANK, GEMCC_INPUT_ELEM_BYTES,
              GEMCC_INPUT_ELEMS, GEMCC_INPUT_DIM0, GEMCC_INPUT_DIM1,
              GEMCC_INPUT_DIM2, GEMCC_INPUT_DIM3);
  fill_tensor(&desc->output, GEMCC_OUTPUT_NAME, GEMCC_OUTPUT_DTYPE,
              GEMCC_OUTPUT_LAYOUT, GEMCC_OUTPUT_RANK, GEMCC_OUTPUT_ELEM_BYTES,
              GEMCC_OUTPUT_ELEMS, GEMCC_OUTPUT_DIM0, GEMCC_OUTPUT_DIM1,
              GEMCC_OUTPUT_DIM2, GEMCC_OUTPUT_DIM3);
  desc->constants_bytes = GEMCC_CONSTANTS_BYTES;
  copy_id(desc->constants_hash, sizeof(desc->constants_hash),
          GEMCC_CONSTANTS_HASH);
  copy_id(desc->constants_mode, sizeof(desc->constants_mode),
          GEMCC_CONSTANTS_MODE);
  desc->constants_linked = GEMCC_CONSTANTS_LINKED;
  desc->workspace_bytes = GEMCC_WORKSPACE_BYTES;
  desc->workspace_alignment = GEMCC_WORKSPACE_ALIGNMENT;
  copy_id(desc->forward_entry, sizeof(desc->forward_entry), GEMCC_FORWARD_ENTRY);
  return GEMCC_OK;
}

int gemcc_model_query(GemccModelInfo *info) {
  GemccModelDescriptor desc;
  int status = gemcc_model_descriptor(&desc);
  if (status != GEMCC_OK || !info)
    return -1;
  info->abi_version = desc.abi_version;
  info->workspace_bytes = desc.workspace_bytes;
  info->input_elem_bytes = desc.input.elem_bytes;
  info->output_elem_bytes = desc.output.elem_bytes;
  info->input_elems = desc.input.elems;
  info->output_elems = desc.output.elems;
  return 0;
}

int gemcc_model_init(void *workspace, size_t workspace_bytes) {
  if (workspace_bytes < (size_t)GEMCC_WORKSPACE_BYTES)
    return -1;
  if (g_active && g_active != &g_legacy_arena)
    return -1;
  if (bind_arena(&g_legacy_arena, workspace, workspace_bytes) != 0)
    return -1;
  g_active = &g_legacy_arena;
  return 0;
}
#endif

static int require_instance(const GemccModelInstance *inst) {
  if (!inst)
    return GEMCC_ERR_INVALID_ARGUMENT;
  if (inst->magic != GEMCC_INSTANCE_MAGIC)
    return GEMCC_ERR_UNINITIALIZED;
  return GEMCC_OK;
}

void gemcc_model_instance_init(GemccModelInstance *inst) {
  if (!inst)
    return;
  memset(inst, 0, sizeof(*inst));
  inst->magic = GEMCC_INSTANCE_MAGIC;
  inst->state = GEMCC_INSTANCE_EMPTY;
}

int gemcc_model_create(GemccModelInstance *inst,
                       const GemccModelDescriptor *desc,
                       const GemccLoadConfig *config) {
  int status;
  if (!inst || !desc)
    return GEMCC_ERR_INVALID_ARGUMENT;
  status = require_instance(inst);
  if (status != GEMCC_OK)
    return status;
  if (inst->state == GEMCC_INSTANCE_CREATED ||
      inst->state == GEMCC_INSTANCE_READY)
    return GEMCC_ERR_STATE;
  if (inst->state != GEMCC_INSTANCE_EMPTY &&
      inst->state != GEMCC_INSTANCE_DESTROYED)
    return GEMCC_ERR_STATE;
  if (desc->abi_version != GEMCC_MODEL_ABI_VERSION)
    return GEMCC_ERR_ABI_MISMATCH;
  if (!config)
    return GEMCC_ERR_INVALID_ARGUMENT;
  if (!same_id(desc->hardware_profile_id, config->hardware_profile_id))
    return GEMCC_ERR_HARDWARE_MISMATCH;
  if (!same_id(desc->quant_mode, config->quant_mode))
    return GEMCC_ERR_QUANT_MISMATCH;
  if (!same_id(desc->quant_profile_version, config->quant_profile_version))
    return GEMCC_ERR_QUANT_MISMATCH;
  if (!same_id(desc->model_hash, config->model_hash))
    return GEMCC_ERR_MODEL_HASH;
  inst->descriptor = desc;
  inst->constants = 0;
  inst->constants_bytes = 0;
  inst->workspace = 0;
  inst->workspace_bytes = 0;
  inst->device = 0;
  memset(&inst->arena, 0, sizeof(inst->arena));
  inst->device_ready = 0;
  inst->state = GEMCC_INSTANCE_CREATED;
  inst->magic = GEMCC_INSTANCE_MAGIC;
  return GEMCC_OK;
}

int gemcc_model_bind_constants(GemccModelInstance *inst, const void *bytes,
                               size_t n) {
  int status = require_instance(inst);
  (void)bytes;
  (void)n;
  if (status != GEMCC_OK)
    return status;
  /* v2 constants are linked into the ELF.  There is no replaceable blob. */
  return GEMCC_ERR_INVALID_ARGUMENT;
}

int gemcc_model_bind_workspace(GemccModelInstance *inst, void *workspace,
                               size_t bytes) {
  int status = require_instance(inst);
  if (status != GEMCC_OK)
    return status;
  if (inst->state != GEMCC_INSTANCE_CREATED)
    return GEMCC_ERR_STATE;
  if (!inst->descriptor)
    return GEMCC_ERR_UNINITIALIZED;
  if (!workspace ||
      bytes < (size_t)inst->descriptor->workspace_bytes ||
      ((uintptr_t)workspace &
       (size_t)(inst->descriptor->workspace_alignment - 1)) != 0)
    return GEMCC_ERR_WORKSPACE;
  inst->workspace = workspace;
  inst->workspace_bytes = bytes;
  return GEMCC_OK;
}

/* I: 已 bind workspace 的 instance；hooks 为 Library/Host/测试桩
 * P: 核对 HAL、绑 arena、调幂等 device init（Library 物理设备首次 flush），
 *    再按 residency 预置 workspace 与链接常量页
 * O: GEMCC_OK 或错误码；成功则 state=READY
 * A: shiroha_suki, shiroha_suki
 * T: 2026-08-27, 2026-08-28, 2026-08-29
 */
int gemcc_model_init_instance(GemccModelInstance *inst,
                              const GemccDeviceHooks *hooks) {
  int status = require_instance(inst);
  if (status != GEMCC_OK)
    return status;
  if (inst->state != GEMCC_INSTANCE_CREATED)
    return GEMCC_ERR_STATE;
  if (!inst->descriptor || !inst->workspace)
    return GEMCC_ERR_UNINITIALIZED;
  inst->device = hooks ? hooks : gemcc_host_device_hooks();
  if (!same_id(inst->descriptor->hardware_profile_id,
               inst->device->hardware_profile_id))
    return GEMCC_ERR_HARDWARE_MISMATCH;
  if (bind_arena(&inst->arena, inst->workspace, inst->workspace_bytes) != 0)
    return GEMCC_ERR_WORKSPACE;
  if (inst->device->init && inst->device->init(inst->device->ctx) != 0)
    return GEMCC_ERR_FORWARD;
  if (inst->device->residency) {
    inst->device->residency(inst->device->ctx, inst->workspace,
                            inst->workspace_bytes, /*write=*/1);
    {
      extern const unsigned char gemcc_linked_constants[] __attribute__((weak));
      extern const unsigned char gemcc_linked_constants_end[]
          __attribute__((weak));
      const unsigned char *lo = gemcc_linked_constants;
      const unsigned char *hi = gemcc_linked_constants_end;
      if (lo && hi && hi > lo)
        inst->device->residency(inst->device->ctx, (void *)lo,
                                (size_t)(hi - lo), /*write=*/0);
    }
  }
  inst->device_ready = 1;
  inst->state = GEMCC_INSTANCE_READY;
  return GEMCC_OK;
}

static int check_request(const GemccModelInstance *inst,
                         const GemccRunRequest *req) {
  const GemccModelDescriptor *desc = inst->descriptor;
  size_t in_need = (size_t)desc->input.elems * (size_t)desc->input.elem_bytes;
  size_t out_need =
      (size_t)desc->output.elems * (size_t)desc->output.elem_bytes;
  if (!req->input || !req->output)
    return GEMCC_ERR_INVALID_ARGUMENT;
  if (req->input_bytes < in_need || req->output_bytes < out_need)
    return GEMCC_ERR_BUFFER_TOO_SMALL;
  if (req->dtype && req->dtype != desc->input.dtype)
    return GEMCC_ERR_DTYPE;
  if (req->layout && req->layout != desc->input.layout)
    return GEMCC_ERR_LAYOUT;
  if (req->rank) {
    if (req->rank != desc->input.rank)
      return GEMCC_ERR_SHAPE;
    for (int i = 0; i < req->rank && i < GEMCC_MAX_RANK; ++i) {
      if (req->shape[i] && req->shape[i] != desc->input.shape[i])
        return GEMCC_ERR_SHAPE;
    }
  }
  if (req->workspace || req->workspace_bytes) {
    if (req->workspace != inst->workspace ||
        (req->workspace_bytes && req->workspace_bytes != inst->workspace_bytes))
      return GEMCC_ERR_WORKSPACE;
  }
  return GEMCC_OK;
}

static uint64_t host_now_ns(void) {
#ifdef GEMCC_HAS_HOST_CLOCK
  struct timespec ts;
  if (clock_gettime(CLOCK_MONOTONIC, &ts) != 0)
    return 0;
  return (uint64_t)ts.tv_sec * 1000000000ull + (uint64_t)ts.tv_nsec;
#else
  return 0;
#endif
}

/* I: READY instance 与 run request（input/output 范围）
 * P: 激活 workspace；Spike 只按 descriptor 的有效 tensor 字节 residency；fence；
 *    调 forward
 * O: GEMCC_OK 或错误码；可选写入 stats
 * A: shiroha_suki, shiroha_suki
 * T: 2026-08-27, 2026-08-28, 2026-08-29
 */
int gemcc_model_run(GemccModelInstance *inst, const GemccRunRequest *req,
                    GemccProfileStats *stats) {
  int status;
  if (!req)
    return GEMCC_ERR_INVALID_ARGUMENT;
  status = require_instance(inst);
  if (status != GEMCC_OK)
    return status;
  if (inst->state == GEMCC_INSTANCE_EMPTY)
    return GEMCC_ERR_UNINITIALIZED;
  if (inst->state != GEMCC_INSTANCE_READY || !inst->descriptor)
    return GEMCC_ERR_STATE;
  status = check_request(inst, req);
  if (status != GEMCC_OK)
    return status;
  size_t input_bytes = (size_t)inst->descriptor->input.elems *
                       (size_t)inst->descriptor->input.elem_bytes;
  size_t output_bytes = (size_t)inst->descriptor->output.elems *
                        (size_t)inst->descriptor->output.elem_bytes;
  if (g_active)
    return GEMCC_ERR_STATE;
  if (bind_arena(&inst->arena, inst->workspace, inst->workspace_bytes) != 0)
    return GEMCC_ERR_WORKSPACE;
  status = activate_arena(&inst->arena);
  if (status != GEMCC_OK)
    return status;
  if (inst->device && inst->device->residency) {
    inst->device->residency(inst->device->ctx, (void *)req->input,
                            input_bytes, /*write=*/0);
    inst->device->residency(inst->device->ctx, req->output, output_bytes,
                            /*write=*/1);
  }
  if (inst->device && inst->device->fence)
    inst->device->fence(inst->device->ctx);
  uint64_t t0 = req->enable_profiling ? host_now_ns() : 0;
  int rc = gemcc_model_forward(req->input, req->output);
  uint64_t t1 = req->enable_profiling ? host_now_ns() : 0;
  if (inst->device && inst->device->fence)
    inst->device->fence(inst->device->ctx);
  if (inst->arena.error)
    status = GEMCC_ERR_WORKSPACE;
  else if (rc != 0)
    status = GEMCC_ERR_FORWARD;
  if (stats) {
    stats->host_ns = (t1 > t0) ? (t1 - t0) : 0;
    stats->workspace_peak_bytes = inst->arena.peak;
    stats->last_status = status;
  }
  deactivate_arena(&inst->arena);
  return status;
}

int gemcc_model_destroy(GemccModelInstance *inst) {
  int status = require_instance(inst);
  if (status != GEMCC_OK)
    return status;
  if (inst->state == GEMCC_INSTANCE_DESTROYED ||
      inst->state == GEMCC_INSTANCE_EMPTY)
    return GEMCC_ERR_STATE;
  if (g_active == &inst->arena)
    return GEMCC_ERR_STATE;
  if (inst->device_ready && inst->device && inst->device->shutdown) {
    inst->device->shutdown(inst->device->ctx);
    inst->device_ready = 0;
  }
  inst->descriptor = 0;
  inst->constants = 0;
  inst->workspace = 0;
  inst->device = 0;
  memset(&inst->arena, 0, sizeof(inst->arena));
  inst->magic = GEMCC_INSTANCE_MAGIC;
  inst->state = GEMCC_INSTANCE_DESTROYED;
  return GEMCC_OK;
}

__attribute__((weak))
int gemcc_model_forward(const void *input, void *output) {
  (void)input;
  (void)output;
  return -2; /* no compiled @forward object linked */
}

/* Compatibility board dumps used this hook; the model object has none. */
__attribute__((weak))
void gemcc_dump_layer_ticks(void) {}

#ifdef BAREMETAL
int *__errno(void) {
  static int e;
  return &e;
}
#endif
