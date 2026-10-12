_Static_assert(sizeof(struct yolo32_prepared_ws_packet) == 88, "WS packet table layout");
_Static_assert(sizeof(struct yolo32_prepared_ws_step) == 4, "WS step table layout");
static inline void yolo32_packed_silu_lut(const uint64_t packed[32]) {
    for (unsigned word = 0; word < 32; ++word)
        ROCC_INSTRUCTION_RS1_RS2(XCUSTOM_ACC, word * 8U, packed[word], 26);
}
static inline uint64_t yolo32_ws_address(const struct yolo32_prepared_ws_packet *p,
                                       unsigned index, const void *const bases[10]) {
    return p->roles[index] == 255U ? UINT64_C(0) :
           (uintptr_t)bases[p->roles[index]] + p->offsets[index];
}
static void yolo32_prepared_ws(const struct yolo32_prepared_ws_plan *plan,
                              const void *const bases[10]) {
    for (unsigned i = 0; i < plan->count; ++i) {
        const struct yolo32_prepared_ws_step *step = &plan->steps[i];
        switch (step->kind) {
        case 0: {
            const uint64_t *config = prepared_ws_configs[step->index];
            ROCC_INSTRUCTION_RS1_RS2(XCUSTOM_ACC, config[0], config[1], 0);
            break;
        }
        case 1: {
            const struct yolo32_prepared_ws_packet *p = &prepared_ws_packets[step->index];
#if YOLO32_TAIL_WAIT
            if (yolo32_independent_enabled && i + 1U < plan->count &&
                plan->steps[i + 1U].kind == 3U)
                yolo32_independent_arm_tail_wait(8U);
#endif
            /* Keep the six native instructions together. Only funct 8 can
             * suspend this stack; all four bases are worker-local bindings. */
            ROCC_INSTRUCTION_RS1_RS2(XCUSTOM_ACC, p->bounds[0], p->bounds[1], 9);
            ROCC_INSTRUCTION_RS1_RS2(XCUSTOM_ACC, yolo32_ws_address(p,0,bases), yolo32_ws_address(p,1,bases), 10);
            ROCC_INSTRUCTION_RS1_RS2(XCUSTOM_ACC, yolo32_ws_address(p,2,bases), yolo32_ws_address(p,3,bases), 11);
            ROCC_INSTRUCTION_RS1_RS2(XCUSTOM_ACC, p->strides[0], p->strides[1], 12);
            ROCC_INSTRUCTION_RS1_RS2(XCUSTOM_ACC, p->strides[2], p->strides[3], 13);
            ROCC_INSTRUCTION_RS1_RS2(XCUSTOM_ACC, p->launch[0], p->launch[1], 8);
            break;
        }
        case 2:
            yolo32_packed_silu_lut(packed_silu_luts[step->index]);
            break;
        case 3:
            gemmini_fence();
            break;
        default:
            yolo32_fail("prepared_ws_step");
        }
    }
}
