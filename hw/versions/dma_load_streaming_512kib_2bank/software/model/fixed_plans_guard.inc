_Static_assert(DIM == 32, "Regenerate fixed YOLO32 plans: DIM");
_Static_assert(BANK_NUM == 8, "Regenerate fixed YOLO32 plans: BANK_NUM");
_Static_assert(BANK_ROWS == 2048, "Regenerate fixed YOLO32 plans: BANK_ROWS");
_Static_assert(ACC_ROWS == 2048, "Regenerate fixed YOLO32 plans: ACC_ROWS");
_Static_assert(YOLO32_FIXED_PLANS == 1, "Fixed graph requires fixed plans build");
_Static_assert(YOLO32_FIXED_PACKETS == 1, "Fixed packet graph requires packet build");
_Static_assert(sizeof(elem_t) == 1 && sizeof(acc_t) == 4 && sizeof(acc_scale_t_bits) == 2,
               "Regenerate fixed convolution packet encoding");
_Static_assert(ADDR_LEN == 32 && ACC_SCALE_EXP_BITS == 5 && ACC_SCALE_SIG_BITS == 11,
               "Regenerate fixed convolution numeric encoding");
_Static_assert(GEMMINI_DISABLE_B_REUSE == 0 && GEMMINI_CONV_TILE_FENCE == 0,
               "Regenerate fixed convolution reuse/fence policy");
#ifndef HAS_FIRST_LAYER_OPTIMIZATIONS
#error "Regenerate fixed convolution first-layer encoding"
#endif
#ifdef GEMMINI_LEGACY_2BIT_ACTIVATION_ABI
#error "Regenerate fixed convolution activation encoding"
#endif
_Static_assert(YOLO32_PREPARED_PACKETS == 1, "Prepared graph requires prepared packet build");
#ifdef YOLOV5NU_STAGE8_MODE_8H_SPLITK_CONFIG_FENCE_MERGE
#error "Regenerate prepared WS packets for the changed fence policy"
#endif
_Static_assert(YOLO32_WAIT_REUSE == 1, "Annotated graph requires wait reuse build");
_Static_assert(YOLO32_MEMORY_OPS == 1, "Memory graph requires memory-ops build");
_Static_assert(YOLO32_RESIZE_BATCH == 1, "Resize build/generator mismatch");
_Static_assert(DIM == 32 && ACC_ROWS == 2048 && MAX_BLOCK_LEN == 2, "Resize batch ABI/capacity changed");
_Static_assert(YOLO32_RESIZE_ROWS == 0 && YOLO32_MEMORY_WAITS == 34, "Resize wait plan changed");
