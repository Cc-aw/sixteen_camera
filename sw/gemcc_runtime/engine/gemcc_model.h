/*
 * Model-level runtime ABI.
 *
 * Product execution is one compiled forward.  This header describes the
 * compiled model, one loaded instance, and one run request.  Runtime must
 * not parse ONNX, compatibility layer tables, or a JSON execution menu.
 */
#ifndef GEMCC_MODEL_H
#define GEMCC_MODEL_H

#include "gemcc_device.h"

#include <stddef.h>
#include <stdint.h>

#define GEMCC_MODEL_ABI_VERSION 2
#define GEMCC_WORKSPACE_ALIGNMENT 64
#define GEMCC_MAX_RANK 8
#define GEMCC_ID_CHARS 80
#define GEMCC_HASH_CHARS 65
#define GEMCC_CONSTANTS_MODE_LINKED "linked"
#define GEMCC_CONSTANTS_LINKED 1

#define GEMCC_DTYPE_UNKNOWN 0
#define GEMCC_DTYPE_I8 1
#define GEMCC_DTYPE_I32 2
#define GEMCC_DTYPE_F32 3

#define GEMCC_LAYOUT_UNKNOWN 0
#define GEMCC_LAYOUT_NCHW 1
#define GEMCC_LAYOUT_NHWC 2

#define GEMCC_INSTANCE_EMPTY 0
#define GEMCC_INSTANCE_CREATED 1
#define GEMCC_INSTANCE_READY 2
#define GEMCC_INSTANCE_DESTROYED 3
#define GEMCC_INSTANCE_MAGIC 0x474d4343u /* 'GMCC' */

#define GEMCC_OK 0
#define GEMCC_ERR_INVALID_ARGUMENT 1
#define GEMCC_ERR_ABI_MISMATCH 2
#define GEMCC_ERR_HARDWARE_MISMATCH 3
#define GEMCC_ERR_QUANT_MISMATCH 4
#define GEMCC_ERR_MODEL_HASH 5
#define GEMCC_ERR_BUFFER_TOO_SMALL 6
#define GEMCC_ERR_WORKSPACE 7
#define GEMCC_ERR_UNINITIALIZED 8
#define GEMCC_ERR_STATE 9
#define GEMCC_ERR_FORWARD 10
#define GEMCC_ERR_LAYOUT 11
#define GEMCC_ERR_DTYPE 12
#define GEMCC_ERR_SHAPE 13

#ifdef __cplusplus
extern "C" {
#endif

typedef struct GemccTensorDesc {
  char name[GEMCC_ID_CHARS];
  int32_t dtype;
  int32_t layout;
  int32_t rank;
  int64_t shape[GEMCC_MAX_RANK];
  int32_t elem_bytes;
  int64_t elems;
} GemccTensorDesc;

typedef struct GemccModelDescriptor {
  int32_t abi_version;
  char model_id[GEMCC_ID_CHARS];
  char model_hash[GEMCC_HASH_CHARS];
  char hardware_profile_id[GEMCC_ID_CHARS];
  char quant_mode[16];
  char quant_profile_version[16];
  GemccTensorDesc input;
  GemccTensorDesc output;
  int64_t constants_bytes;
  char constants_hash[GEMCC_HASH_CHARS];
  char constants_mode[16];
  int32_t constants_linked;
  int64_t workspace_bytes;
  int32_t workspace_alignment;
  char forward_entry[GEMCC_ID_CHARS];
} GemccModelDescriptor;

typedef struct GemccLoadConfig {
  const char *hardware_profile_id;
  const char *quant_mode;
  const char *quant_profile_version;
  const char *model_hash;
} GemccLoadConfig;

typedef struct GemccWorkspaceArena {
  void *base;
  size_t capacity;
  size_t cursor;
  size_t peak;
  void *free_list;
  int32_t error;
} GemccWorkspaceArena;

typedef struct GemccModelInstance {
  uint32_t magic;
  const GemccModelDescriptor *descriptor;
  const void *constants;
  size_t constants_bytes;
  void *workspace;
  size_t workspace_bytes;
  const GemccDeviceHooks *device;
  GemccWorkspaceArena arena;
  int32_t state;
  int device_ready;
} GemccModelInstance;

#define GEMCC_MODEL_INSTANCE_INITIALIZER                                       \
  { .magic = GEMCC_INSTANCE_MAGIC, .state = GEMCC_INSTANCE_EMPTY }

typedef struct GemccRunRequest {
  const void *input;
  size_t input_bytes;
  void *output;
  size_t output_bytes;
  int32_t dtype;
  int32_t layout;
  int32_t rank;
  int64_t shape[GEMCC_MAX_RANK];
  void *workspace;
  size_t workspace_bytes;
  int enable_profiling;
  uint32_t flags;
} GemccRunRequest;

typedef struct GemccProfileStats {
  /* Host/Spike elapsed time only.  Not MyBoard mcycle. */
  uint64_t host_ns;
  size_t workspace_peak_bytes;
  int32_t last_status;
} GemccProfileStats;

typedef struct GemccModelInfo {
  int32_t abi_version;
  int64_t workspace_bytes;
  int32_t input_elem_bytes;
  int32_t output_elem_bytes;
  int64_t input_elems;
  int64_t output_elems;
} GemccModelInfo;

int gemcc_model_descriptor(GemccModelDescriptor *desc);
void gemcc_model_instance_init(GemccModelInstance *inst);
int gemcc_model_create(GemccModelInstance *inst,
                       const GemccModelDescriptor *desc,
                       const GemccLoadConfig *config);
int gemcc_model_bind_constants(GemccModelInstance *inst, const void *bytes,
                               size_t n);
int gemcc_model_bind_workspace(GemccModelInstance *inst, void *workspace,
                               size_t bytes);
int gemcc_model_init_instance(GemccModelInstance *inst,
                              const GemccDeviceHooks *hooks);
int gemcc_model_run(GemccModelInstance *inst, const GemccRunRequest *req,
                    GemccProfileStats *stats);
int gemcc_model_destroy(GemccModelInstance *inst);
const char *gemcc_status_string(int status);

/* v0 wrappers used by existing Spike/bare-metal harnesses. */
int gemcc_model_query(GemccModelInfo *info);
int gemcc_model_init(void *workspace, size_t workspace_bytes);
int gemcc_model_forward(const void *input, void *output);

/* Returns uninitialized payload; residency/initialization is not per alloc. */
void *gemcc_workspace_alloc(size_t bytes);
void gemcc_workspace_free(void *ptr);
int gemcc_workspace_is_bound(void);
int gemcc_workspace_owns(const void *ptr);
size_t gemcc_workspace_peak_bytes(void);
int gemcc_workspace_failed(void);
size_t gemcc_model_workspace_peak(const GemccModelInstance *inst);
int gemcc_model_workspace_failed(const GemccModelInstance *inst);

#ifdef __cplusplus
}
#endif

#endif /* GEMCC_MODEL_H */
