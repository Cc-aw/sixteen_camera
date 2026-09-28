static struct yolov5nu_dim16_profile
  frame_profiles[YOLOV5NU_DIM16_WORKER_COUNT];

static inline uint64_t yolo_frame_profile_clock(void) {
  uint64_t value;
  asm volatile("rdcycle %0" : "=r"(value));
  return value;
}

#if YOLOV5NU_PROFILE
#define YOLOV5NU_PROFILE_MAX_RECORDS 512
static struct YoloProfileRecord yolo_profile_records[YOLOV5NU_PROFILE_MAX_RECORDS];
static int yolo_profile_record_count;

static inline void yolo_profile_reset(void) {
  yolo_profile_record_count = 0;
}

static inline uint64_t yolo_profile_clock(void) {
  return yolo_frame_profile_clock();
}

static inline uint64_t yolo_profile_begin(int kind, const char *kind_name, const char *name) {
  (void)kind; (void)kind_name; (void)name;
  return yolo_profile_clock();
}

static void yolo_profile_add(int kind, const char *kind_name, const char *name, uint64_t cycles) {
  struct yolov5nu_dim16_profile *profile =
    &frame_profiles[gemmini_pool_active_worker];
  if (kind == PROFILE_CONV_GEMMINI)
    profile->rocc_submit_cycles += cycles;
  else if (kind == PROFILE_MAXPOOL)
    profile->rvv_maxpool_cycles += cycles;
  else if (kind == PROFILE_RESIZE)
    profile->rvv_resize_cycles += cycles;
  else if (kind == PROFILE_ADD || kind == PROFILE_CONCAT ||
           kind == PROFILE_RESHAPE || kind == PROFILE_TRANSPOSE ||
           kind == PROFILE_CONV_IN_LAYOUT ||
           kind == PROFILE_CONV_OUT_LAYOUT ||
           kind == PROFILE_HEAD_CLASS || kind == PROFILE_HEAD_DFL)
    profile->rvv_copy_requant_cycles += cycles;
  if (yolo_profile_record_count < YOLOV5NU_PROFILE_MAX_RECORDS) {
    yolo_profile_records[yolo_profile_record_count++] = (struct YoloProfileRecord){
      kind, kind_name, name, cycles
    };
  }
}
#else
static inline void yolo_profile_reset(void) {}

static inline uint64_t yolo_profile_clock(void) {
  return yolo_frame_profile_clock();
}

static inline uint64_t yolo_profile_begin(int kind, const char *kind_name, const char *name) {
  (void)kind; (void)kind_name; (void)name;
  return yolo_profile_clock();
}
static inline void yolo_profile_add(int kind, const char *kind_name, const char *name, uint64_t cycles) {
  struct yolov5nu_dim16_profile *profile =
    &frame_profiles[gemmini_pool_active_worker];
  (void)kind_name; (void)name;
  if (kind == PROFILE_CONV_GEMMINI)
    profile->rocc_submit_cycles += cycles;
  else if (kind == PROFILE_MAXPOOL)
    profile->rvv_maxpool_cycles += cycles;
  else if (kind == PROFILE_RESIZE)
    profile->rvv_resize_cycles += cycles;
  else if (kind == PROFILE_ADD || kind == PROFILE_CONCAT ||
           kind == PROFILE_RESHAPE || kind == PROFILE_TRANSPOSE ||
           kind == PROFILE_CONV_IN_LAYOUT ||
           kind == PROFILE_CONV_OUT_LAYOUT ||
           kind == PROFILE_HEAD_CLASS || kind == PROFILE_HEAD_DFL)
    profile->rvv_copy_requant_cycles += cycles;
}
#endif

static inline void yolo_profile_fence(void) {
  uint64_t start = yolo_frame_profile_clock();
  asm volatile("fence" ::: "memory");
  frame_profiles[gemmini_pool_active_worker].fence_cycles +=
    yolo_frame_profile_clock() - start;
}

#undef gemmini_fence
#define gemmini_fence() yolo_profile_fence()

enum {
  FRAME_COUNTER_BUSY = 0,
  FRAME_COUNTER_LOAD_DMA_WAIT,
  FRAME_COUNTER_LOAD_SPAD_WAIT,
  FRAME_COUNTER_EXEC_ACTIVE,
  FRAME_COUNTER_STORE_DMA_WAIT,
  FRAME_COUNTER_STORE_SPAD_WAIT
};

static uint32_t frame_counter_access(uint32_t worker_id, uint32_t config) {
  uint32_t result;
  uint32_t placeholder = 0U;
  if (worker_id == 0U) {
    ROCC_INSTRUCTION(3, result, config, placeholder, k_COUNTER);
  } else if (worker_id == 1U) {
    ROCC_INSTRUCTION(2, result, config, placeholder, k_COUNTER);
  } else {
    ROCC_INSTRUCTION(1, result, config, placeholder, k_COUNTER);
  }
  return result;
}

static void frame_counter_reset(uint32_t worker_id) {
  (void)frame_counter_access(worker_id, 0x1U);
}

static void frame_counter_configure(uint32_t worker_id, uint32_t index,
                                    uint32_t event) {
  uint32_t config = ((index & 7U) << 4) | 0x8U |
                    ((event & 0x3fU) << 12);
  (void)frame_counter_access(worker_id, config);
}

static uint32_t frame_counter_read(uint32_t worker_id, uint32_t index) {
  return frame_counter_access(worker_id, (index & 7U) << 4);
}

static void frame_counter_start(uint32_t worker_id) {
  memset(&frame_profiles[worker_id], 0, sizeof(frame_profiles[worker_id]));
  frame_counter_reset(worker_id);
  frame_counter_configure(worker_id, FRAME_COUNTER_BUSY,
                          RESERVATION_STATION_ACTIVE_CYCLES);
  frame_counter_configure(worker_id, FRAME_COUNTER_LOAD_DMA_WAIT,
                          LOAD_DMA_WAIT_CYCLE);
  frame_counter_configure(worker_id, FRAME_COUNTER_LOAD_SPAD_WAIT,
                          LOAD_SCRATCHPAD_WAIT_CYCLE);
  frame_counter_configure(worker_id, FRAME_COUNTER_EXEC_ACTIVE,
                          EXE_ACTIVE_CYCLE);
  frame_counter_configure(worker_id, FRAME_COUNTER_STORE_DMA_WAIT,
                          STORE_DMA_WAIT_CYCLE);
  frame_counter_configure(worker_id, FRAME_COUNTER_STORE_SPAD_WAIT,
                          STORE_SCRATCHPAD_WAIT_CYCLE);
}

static void frame_counter_finish(uint32_t worker_id) {
  struct yolov5nu_dim16_profile *profile = &frame_profiles[worker_id];
  (void)frame_counter_access(worker_id, 0x4U);
  profile->gemmini_busy_cycles =
    frame_counter_read(worker_id, FRAME_COUNTER_BUSY);
  profile->gemmini_load_stall_cycles =
    (uint64_t)frame_counter_read(worker_id, FRAME_COUNTER_LOAD_DMA_WAIT) +
    frame_counter_read(worker_id, FRAME_COUNTER_LOAD_SPAD_WAIT);
  profile->gemmini_exec_cycles =
    frame_counter_read(worker_id, FRAME_COUNTER_EXEC_ACTIVE);
  profile->gemmini_store_stall_cycles =
    (uint64_t)frame_counter_read(worker_id, FRAME_COUNTER_STORE_DMA_WAIT) +
    frame_counter_read(worker_id, FRAME_COUNTER_STORE_SPAD_WAIT);
}

