_Static_assert(sizeof(struct yolo32_prepared_ws_packet) == 88, "WS packet table layout");
_Static_assert(sizeof(struct yolo32_prepared_ws_step) == 4, "WS step table layout");
#if YOLO32_PACKET_DISPATCH
#include "packet_dispatch_runtime.inc"
#define YOLO32_DEFINE_LUT_WORKER(worker,opcode) \
static __attribute__((noinline)) void yolo32_lut_worker##worker(const uint64_t packed[32]) { \
    for (unsigned word=0;word<32;++word) \
        YOLO32_EMIT_FIXED(opcode,26,word*8U,packed[word]); \
}
YOLO32_DEFINE_LUT_WORKER(0,3)
YOLO32_DEFINE_LUT_WORKER(1,2)
YOLO32_DEFINE_LUT_WORKER(2,1)
#undef YOLO32_DEFINE_LUT_WORKER
#endif
static inline void yolo32_packed_silu_lut(const uint64_t packed[32]) {
#if YOLO32_PACKET_DISPATCH
    switch (gemmini_pool_active_worker) {
    case 0: yolo32_lut_worker0(packed); break;
    case 1: yolo32_lut_worker1(packed); break;
    case 2: yolo32_lut_worker2(packed); break;
    default: yolo32_fail("packet_worker");
    }
#else
    for (unsigned word = 0; word < 32; ++word)
        ROCC_INSTRUCTION_RS1_RS2(XCUSTOM_ACC, word * 8U, packed[word], 26);
#endif
}
static inline uint64_t yolo32_ws_address(const struct yolo32_prepared_ws_packet *p,
                                       unsigned index, const void *const bases[10]) {
#if YOLO32_SUPPLY_DIAG
    unsigned w=gemmini_pool_active_worker, token=yolo32_diag_push(w,DIAG_ADDRESS);
#endif
    uint64_t address=p->roles[index] == 255U ? UINT64_C(0) :
           (uintptr_t)bases[p->roles[index]] + p->offsets[index];
#if YOLO32_SUPPLY_DIAG
    __asm__ volatile("" : "+r"(address) :: "memory");
    yolo32_diag_pop(w,token);
#endif
    return address;
}
#if YOLO32_PACKET_DISPATCH
#include "packet_dispatch_runtime.inc"
#define YOLO32_DEFINE_WS_WORKER(worker,opcode) \
static __attribute__((noinline)) void yolo32_ws_worker##worker( \
        const struct yolo32_prepared_ws_packet *p,const void *const bases[10]) { \
    YOLO32_EMIT_FIXED(opcode,9,p->bounds[0],p->bounds[1]); \
    YOLO32_EMIT_FIXED(opcode,10,yolo32_ws_address(p,0,bases),yolo32_ws_address(p,1,bases)); \
    YOLO32_EMIT_FIXED(opcode,11,yolo32_ws_address(p,2,bases),yolo32_ws_address(p,3,bases)); \
    YOLO32_EMIT_FIXED(opcode,12,p->strides[0],p->strides[1]); \
    YOLO32_EMIT_FIXED(opcode,13,p->strides[2],p->strides[3]); \
    YOLO32_EMIT_FIXED(opcode,8,p->launch[0],p->launch[1]); \
    GEMMINI_POOL_COMMAND_RETURN_HOOK(8); \
}
YOLO32_DEFINE_WS_WORKER(0,3)
YOLO32_DEFINE_WS_WORKER(1,2)
YOLO32_DEFINE_WS_WORKER(2,1)
#undef YOLO32_DEFINE_WS_WORKER
#endif
static inline void yolo32_ws_submit(const struct yolo32_prepared_ws_packet *p,
                                    const void *const bases[10]) {
#if YOLO32_PACKET_DISPATCH
    switch (gemmini_pool_active_worker) {
    case 0: yolo32_ws_worker0(p,bases); break;
    case 1: yolo32_ws_worker1(p,bases); break;
    case 2: yolo32_ws_worker2(p,bases); break;
    default: yolo32_fail("packet_worker");
    }
#else
    ROCC_INSTRUCTION_RS1_RS2(XCUSTOM_ACC,p->bounds[0],p->bounds[1],9);
    ROCC_INSTRUCTION_RS1_RS2(XCUSTOM_ACC,yolo32_ws_address(p,0,bases),yolo32_ws_address(p,1,bases),10);
    ROCC_INSTRUCTION_RS1_RS2(XCUSTOM_ACC,yolo32_ws_address(p,2,bases),yolo32_ws_address(p,3,bases),11);
    ROCC_INSTRUCTION_RS1_RS2(XCUSTOM_ACC,p->strides[0],p->strides[1],12);
    ROCC_INSTRUCTION_RS1_RS2(XCUSTOM_ACC,p->strides[2],p->strides[3],13);
    ROCC_INSTRUCTION_RS1_RS2(XCUSTOM_ACC,p->launch[0],p->launch[1],8);
#endif
}
static void yolo32_prepared_ws(const struct yolo32_prepared_ws_plan *plan,
                              const void *const bases[10]) {
#if YOLO32_SUPPLY_DIAG
    unsigned diag_worker=gemmini_pool_active_worker;
    unsigned diag_token=yolo32_diag_push(diag_worker,DIAG_INTERPRET);
#endif
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
            yolo32_ws_submit(p,bases);
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
#if YOLO32_SUPPLY_DIAG
    yolo32_diag_pop(diag_worker,diag_token);
#endif
}
