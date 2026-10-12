/* Original ROCC macro preserves worker dispatch, profiling and the packet-end
 * scheduling hook. Functions 16..21 cannot suspend halfway through a packet. */
_Static_assert(sizeof(struct yolo32_conv_packet) == 80, "Unexpected packet table layout");
static inline uint64_t yolo32_packet_address(const void *base, uint32_t offset) {
    return offset == UINT32_MAX ? UINT64_C(0) : (uintptr_t)base + offset;
}
static inline void yolo32_packet_config(const struct yolo32_conv_packet_plan *plan) {
    ROCC_INSTRUCTION_RS1_RS2(XCUSTOM_ACC, plan->config[0], plan->config[1], 0);
    ROCC_INSTRUCTION_RS1_RS2(XCUSTOM_ACC, plan->config[2], plan->config[3], 0);
}
static inline void yolo32_packet_submit(const struct yolo32_conv_packet_plan *plan,
        const struct yolo32_conv_packet *packet, const elem_t *input,
        const elem_t *weights, const acc_t *bias, elem_t *output) {
    ROCC_INSTRUCTION_RS1_RS2(XCUSTOM_ACC, plan->config[4], plan->config[5], 16);
    ROCC_INSTRUCTION_RS1_RS2(XCUSTOM_ACC, packet->geometry[0], packet->geometry[1], 17);
    ROCC_INSTRUCTION_RS1_RS2(XCUSTOM_ACC, packet->geometry[2], packet->geometry[3], 18);
    ROCC_INSTRUCTION_RS1_RS2(XCUSTOM_ACC, packet->geometry[4], packet->geometry[5], 19);
    ROCC_INSTRUCTION_RS1_RS2(XCUSTOM_ACC,
        yolo32_packet_address(weights, packet->offsets[0]),
        yolo32_packet_address(output, packet->offsets[1]), 20);
    ROCC_INSTRUCTION_RS1_RS2(XCUSTOM_ACC,
        yolo32_packet_address(bias, packet->offsets[2]),
        yolo32_packet_address(input, packet->offsets[3]), 21);
    ROCC_INSTRUCTION_RS1_RS2(XCUSTOM_ACC, packet->launch[0], packet->launch[1], 15);
}
struct yolo32_fixed_conv_args {
    const struct yolo32_conv_packet_plan *plan;
    const elem_t *input, *weights;
    const acc_t *bias;
    elem_t *output;
};
static struct yolo32_fixed_conv_args fixed_parallel_args[3];
static void yolo32_fixed_conv(const struct yolo32_conv_packet_plan *plan,
        const elem_t *input, const elem_t *weights, const acc_t *bias, elem_t *output) {
    if (parallel_collecting) {
        unsigned w = gemmini_pool_active_worker;
        if (w >= 3 || (parallel_pending & (1U << w)))
            yolo32_fail("parallel_duplicate_descriptor");
        fixed_parallel_args[w] = (struct yolo32_fixed_conv_args){plan,input,weights,bias,output};
        parallel_pending |= 1U << w;
        return;
    }
    yolo32_packet_config(plan);
    for (unsigned tile = 0; tile < plan->count; ++tile) {
#if YOLO32_TAIL_WAIT
        if (yolo32_independent_enabled && tile + 1U == plan->count)
            yolo32_independent_arm_tail_wait(15U);
#endif
        yolo32_packet_submit(plan, &plan->packets[tile], input, weights, bias, output);
    }
}
static void parallel_execute(void) {
    if (parallel_pending != 7) yolo32_fail("parallel_incomplete_descriptors");
    const struct yolo32_fixed_conv_args *ref = &fixed_parallel_args[0];
    for (unsigned w = 1; w < 3; ++w) {
        if (ref->plan != fixed_parallel_args[w].plan) yolo32_fail("parallel_packet_plan");
        if (ref->weights != fixed_parallel_args[w].weights) yolo32_fail("parallel_field_weights");
        if (ref->bias != fixed_parallel_args[w].bias) yolo32_fail("parallel_field_bias");
    }
    parallel_collecting = 0;
    for (unsigned w = 0; w < 3; ++w) {
        gemmini_pool_active_worker = w;
        yolo32_packet_config(ref->plan);
    }
    for (unsigned tile = 0; tile < ref->plan->count; ++tile) {
        for (unsigned w = 0; w < 3; ++w) {
            const struct yolo32_fixed_conv_args *args = &fixed_parallel_args[w];
            gemmini_pool_active_worker = w;
            yolo32_packet_submit(args->plan, &args->plan->packets[tile],
                                args->input, args->weights, args->bias, args->output);
        }
        ++parallel_stats.tile_groups;
        parallel_sample_busy();
    }
    parallel_drain();
    ++parallel_stats.conv_groups;
    parallel_pending = 0;
}
