/* Generated stage code selects fixed address roles. Runtime never interprets
 * WS step kinds or roles; native packets and all original waits are retained. */
struct yolo32_conv_binding { const elem_t *input, *weights; const acc_t *bias; elem_t *output; };
struct yolo32_ws_binding { const void *base[10]; };
#define YOLO32_BOUND_WS_WORKER(w,op) \
static __attribute__((noinline)) void yolo32_bound_ws_worker##w( \
        const struct yolo32_prepared_ws_packet *p,uint64_t a,uint64_t b,uint64_t d,uint64_t c) { \
    YOLO32_EMIT_FIXED(op,9,p->bounds[0],p->bounds[1]); \
    YOLO32_EMIT_FIXED(op,10,a,b); \
    YOLO32_EMIT_FIXED(op,11,d,c); \
    YOLO32_EMIT_FIXED(op,12,p->strides[0],p->strides[1]); \
    YOLO32_EMIT_FIXED(op,13,p->strides[2],p->strides[3]); \
    YOLO32_EMIT_FIXED(op,8,p->launch[0],p->launch[1]); \
    GEMMINI_POOL_COMMAND_RETURN_HOOK(8); \
}
YOLO32_BOUND_WS_WORKER(0,3)
YOLO32_BOUND_WS_WORKER(1,2)
YOLO32_BOUND_WS_WORKER(2,1)
#undef YOLO32_BOUND_WS_WORKER
static inline void yolo32_bound_ws_submit(const struct yolo32_prepared_ws_packet *p,
        uint64_t a,uint64_t b,uint64_t d,uint64_t c) {
    switch (gemmini_pool_active_worker) {
    case 0: yolo32_bound_ws_worker0(p,a,b,d,c); break;
    case 1: yolo32_bound_ws_worker1(p,a,b,d,c); break;
    case 2: yolo32_bound_ws_worker2(p,a,b,d,c); break;
    default: yolo32_fail("bound_ws_worker");
    }
}
static void yolo32_bound_conv(const struct yolo32_conv_packet_plan *plan,
        const struct yolo32_conv_binding *b) {
    if (parallel_collecting) {
        yolo32_fixed_conv(plan,b->input,b->weights,b->bias,b->output);
        return;
    }
    yolo32_packet_config(plan);
    for (unsigned tile=0;tile+1U<plan->count;++tile) {
        if (yolo32_independent_enabled) yolo32_independent_conv_more(1);
        yolo32_packet_submit(plan,&plan->packets[tile],b->input,b->weights,b->bias,b->output);
    }
    if (yolo32_independent_enabled) {
        yolo32_independent_conv_more(0);
        yolo32_independent_arm_tail_wait(15U);
    }
    yolo32_packet_submit(plan,&plan->packets[plan->count-1U],b->input,b->weights,b->bias,b->output);
}
