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
#if YOLO32_MEMORY_SCHEDULE
    yolo32_memory_schedule_admit(1U);
#endif
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
#if YOLO32_CAPACITY_DIAG
        if (yolo32_independent_enabled)
            yolo32_capacity_prepare(gemmini_pool_active_worker,
                yolo32_stage(gemmini_pool_active_worker),1);
#endif
        if (yolo32_independent_enabled) yolo32_independent_conv_more(1);
        yolo32_packet_submit(plan,&plan->packets[tile],b->input,b->weights,b->bias,b->output);
    }
    if (yolo32_independent_enabled) {
#if YOLO32_CAPACITY_DIAG
        yolo32_capacity_prepare(gemmini_pool_active_worker,
            yolo32_stage(gemmini_pool_active_worker),0);
#endif
        yolo32_independent_conv_more(0);
        yolo32_independent_arm_tail_wait(15U);
    }
    yolo32_packet_submit(plan,&plan->packets[plan->count-1U],b->input,b->weights,b->bias,b->output);
}

static void yolo32_batch_ws_12(const struct yolo32_ws_binding *b) {
  ROCC_INSTRUCTION_RS1_RS2(XCUSTOM_ACC,prepared_ws_configs[0][0],prepared_ws_configs[0][1],0);
  ROCC_INSTRUCTION_RS1_RS2(XCUSTOM_ACC,prepared_ws_configs[1][0],prepared_ws_configs[1][1],0);
  ROCC_INSTRUCTION_RS1_RS2(XCUSTOM_ACC,prepared_ws_configs[2][0],prepared_ws_configs[2][1],0);
  ROCC_INSTRUCTION_RS1_RS2(XCUSTOM_ACC,prepared_ws_configs[3][0],prepared_ws_configs[3][1],0);
  for (unsigned iteration=0;iteration<18U;++iteration) {
    {
      const struct yolo32_prepared_ws_packet *p=&prepared_ws_packets[0U+iteration*1U];
      yolo32_bound_ws_submit(p,(uintptr_t)b->base[0]+p->offsets[0],(uintptr_t)b->base[1]+p->offsets[1],UINT64_C(0),(uintptr_t)b->base[8]+p->offsets[3]);
    }
  }
  {
    const struct yolo32_prepared_ws_packet *p=&prepared_ws_packets[18];
    if (yolo32_independent_enabled) yolo32_independent_arm_tail_wait(8U);
    yolo32_bound_ws_submit(p,(uintptr_t)b->base[0]+p->offsets[0],(uintptr_t)b->base[1]+p->offsets[1],UINT64_C(0),(uintptr_t)b->base[8]+p->offsets[3]);
  }
  gemmini_fence();
}

static void yolo32_batch_ws_14(const struct yolo32_ws_binding *b) {
  ROCC_INSTRUCTION_RS1_RS2(XCUSTOM_ACC,prepared_ws_configs[4][0],prepared_ws_configs[4][1],0);
  ROCC_INSTRUCTION_RS1_RS2(XCUSTOM_ACC,prepared_ws_configs[5][0],prepared_ws_configs[5][1],0);
  ROCC_INSTRUCTION_RS1_RS2(XCUSTOM_ACC,prepared_ws_configs[6][0],prepared_ws_configs[6][1],0);
  ROCC_INSTRUCTION_RS1_RS2(XCUSTOM_ACC,prepared_ws_configs[7][0],prepared_ws_configs[7][1],0);
  for (unsigned iteration=0;iteration<19U;++iteration) {
    ROCC_INSTRUCTION_RS1_RS2(XCUSTOM_ACC,prepared_ws_configs[8][0],prepared_ws_configs[8][1],0);
    {
      const struct yolo32_prepared_ws_packet *p=&prepared_ws_packets[19U+iteration*2U];
      if (yolo32_independent_enabled) yolo32_independent_arm_tail_wait(8U);
      yolo32_bound_ws_submit(p,(uintptr_t)b->base[0]+p->offsets[0],(uintptr_t)b->base[4]+p->offsets[1],(uintptr_t)b->base[6]+p->offsets[2],UINT64_C(0));
    }
    gemmini_fence();
    ROCC_INSTRUCTION_RS1_RS2(XCUSTOM_ACC,prepared_ws_configs[2][0],prepared_ws_configs[2][1],0);
    {
      const struct yolo32_prepared_ws_packet *p=&prepared_ws_packets[20U+iteration*2U];
      if (yolo32_independent_enabled) yolo32_independent_arm_tail_wait(8U);
      yolo32_bound_ws_submit(p,(uintptr_t)b->base[1]+p->offsets[0],(uintptr_t)b->base[4]+p->offsets[1],UINT64_C(0),(uintptr_t)b->base[8]+p->offsets[3]);
    }
    gemmini_fence();
  }
}

static void yolo32_batch_ws_26(const struct yolo32_ws_binding *b) {
  ROCC_INSTRUCTION_RS1_RS2(XCUSTOM_ACC,prepared_ws_configs[9][0],prepared_ws_configs[9][1],0);
  ROCC_INSTRUCTION_RS1_RS2(XCUSTOM_ACC,prepared_ws_configs[1][0],prepared_ws_configs[1][1],0);
  ROCC_INSTRUCTION_RS1_RS2(XCUSTOM_ACC,prepared_ws_configs[10][0],prepared_ws_configs[10][1],0);
  ROCC_INSTRUCTION_RS1_RS2(XCUSTOM_ACC,prepared_ws_configs[6][0],prepared_ws_configs[6][1],0);
  for (unsigned iteration=0;iteration<4U;++iteration) {
    {
      const struct yolo32_prepared_ws_packet *p=&prepared_ws_packets[57U+iteration*1U];
      yolo32_bound_ws_submit(p,(uintptr_t)b->base[0]+p->offsets[0],(uintptr_t)b->base[1]+p->offsets[1],UINT64_C(0),(uintptr_t)b->base[8]+p->offsets[3]);
    }
  }
  {
    const struct yolo32_prepared_ws_packet *p=&prepared_ws_packets[61];
    if (yolo32_independent_enabled) yolo32_independent_arm_tail_wait(8U);
    yolo32_bound_ws_submit(p,(uintptr_t)b->base[0]+p->offsets[0],(uintptr_t)b->base[1]+p->offsets[1],UINT64_C(0),(uintptr_t)b->base[8]+p->offsets[3]);
  }
  gemmini_fence();
}

static void yolo32_batch_ws_31(const struct yolo32_ws_binding *b) {
  ROCC_INSTRUCTION_RS1_RS2(XCUSTOM_ACC,prepared_ws_configs[11][0],prepared_ws_configs[11][1],0);
  ROCC_INSTRUCTION_RS1_RS2(XCUSTOM_ACC,prepared_ws_configs[1][0],prepared_ws_configs[1][1],0);
  ROCC_INSTRUCTION_RS1_RS2(XCUSTOM_ACC,prepared_ws_configs[10][0],prepared_ws_configs[10][1],0);
  ROCC_INSTRUCTION_RS1_RS2(XCUSTOM_ACC,prepared_ws_configs[6][0],prepared_ws_configs[6][1],0);
  for (unsigned iteration=0;iteration<4U;++iteration) {
    {
      const struct yolo32_prepared_ws_packet *p=&prepared_ws_packets[62U+iteration*1U];
      yolo32_bound_ws_submit(p,(uintptr_t)b->base[0]+p->offsets[0],(uintptr_t)b->base[1]+p->offsets[1],UINT64_C(0),(uintptr_t)b->base[8]+p->offsets[3]);
    }
  }
  {
    const struct yolo32_prepared_ws_packet *p=&prepared_ws_packets[66];
    if (yolo32_independent_enabled) yolo32_independent_arm_tail_wait(8U);
    yolo32_bound_ws_submit(p,(uintptr_t)b->base[0]+p->offsets[0],(uintptr_t)b->base[1]+p->offsets[1],UINT64_C(0),(uintptr_t)b->base[8]+p->offsets[3]);
  }
  gemmini_fence();
}

static void yolo32_batch_ws_33(const struct yolo32_ws_binding *b) {
  ROCC_INSTRUCTION_RS1_RS2(XCUSTOM_ACC,prepared_ws_configs[4][0],prepared_ws_configs[4][1],0);
  ROCC_INSTRUCTION_RS1_RS2(XCUSTOM_ACC,prepared_ws_configs[12][0],prepared_ws_configs[12][1],0);
  ROCC_INSTRUCTION_RS1_RS2(XCUSTOM_ACC,prepared_ws_configs[13][0],prepared_ws_configs[13][1],0);
  ROCC_INSTRUCTION_RS1_RS2(XCUSTOM_ACC,prepared_ws_configs[7][0],prepared_ws_configs[7][1],0);
  for (unsigned iteration=0;iteration<10U;++iteration) {
    ROCC_INSTRUCTION_RS1_RS2(XCUSTOM_ACC,prepared_ws_configs[14][0],prepared_ws_configs[14][1],0);
    {
      const struct yolo32_prepared_ws_packet *p=&prepared_ws_packets[67U+iteration*2U];
      if (yolo32_independent_enabled) yolo32_independent_arm_tail_wait(8U);
      yolo32_bound_ws_submit(p,(uintptr_t)b->base[0]+p->offsets[0],(uintptr_t)b->base[4]+p->offsets[1],(uintptr_t)b->base[6]+p->offsets[2],UINT64_C(0));
    }
    gemmini_fence();
    ROCC_INSTRUCTION_RS1_RS2(XCUSTOM_ACC,prepared_ws_configs[10][0],prepared_ws_configs[10][1],0);
    {
      const struct yolo32_prepared_ws_packet *p=&prepared_ws_packets[68U+iteration*2U];
      if (yolo32_independent_enabled) yolo32_independent_arm_tail_wait(8U);
      yolo32_bound_ws_submit(p,(uintptr_t)b->base[1]+p->offsets[0],(uintptr_t)b->base[4]+p->offsets[1],UINT64_C(0),(uintptr_t)b->base[8]+p->offsets[3]);
    }
    gemmini_fence();
  }
}

static void yolo32_batch_ws_45(const struct yolo32_ws_binding *b) {
  ROCC_INSTRUCTION_RS1_RS2(XCUSTOM_ACC,prepared_ws_configs[15][0],prepared_ws_configs[15][1],0);
  ROCC_INSTRUCTION_RS1_RS2(XCUSTOM_ACC,prepared_ws_configs[1][0],prepared_ws_configs[1][1],0);
  ROCC_INSTRUCTION_RS1_RS2(XCUSTOM_ACC,prepared_ws_configs[16][0],prepared_ws_configs[16][1],0);
  ROCC_INSTRUCTION_RS1_RS2(XCUSTOM_ACC,prepared_ws_configs[13][0],prepared_ws_configs[13][1],0);
  for (unsigned iteration=0;iteration<2U;++iteration) {
    {
      const struct yolo32_prepared_ws_packet *p=&prepared_ws_packets[87U+iteration*1U];
      yolo32_bound_ws_submit(p,(uintptr_t)b->base[0]+p->offsets[0],(uintptr_t)b->base[1]+p->offsets[1],UINT64_C(0),(uintptr_t)b->base[8]+p->offsets[3]);
    }
  }
  {
    const struct yolo32_prepared_ws_packet *p=&prepared_ws_packets[89];
    if (yolo32_independent_enabled) yolo32_independent_arm_tail_wait(8U);
    yolo32_bound_ws_submit(p,(uintptr_t)b->base[0]+p->offsets[0],(uintptr_t)b->base[1]+p->offsets[1],UINT64_C(0),(uintptr_t)b->base[8]+p->offsets[3]);
  }
  gemmini_fence();
}

static void yolo32_batch_ws_50(const struct yolo32_ws_binding *b) {
  ROCC_INSTRUCTION_RS1_RS2(XCUSTOM_ACC,prepared_ws_configs[17][0],prepared_ws_configs[17][1],0);
  ROCC_INSTRUCTION_RS1_RS2(XCUSTOM_ACC,prepared_ws_configs[1][0],prepared_ws_configs[1][1],0);
  ROCC_INSTRUCTION_RS1_RS2(XCUSTOM_ACC,prepared_ws_configs[16][0],prepared_ws_configs[16][1],0);
  ROCC_INSTRUCTION_RS1_RS2(XCUSTOM_ACC,prepared_ws_configs[13][0],prepared_ws_configs[13][1],0);
  for (unsigned iteration=0;iteration<2U;++iteration) {
    {
      const struct yolo32_prepared_ws_packet *p=&prepared_ws_packets[90U+iteration*1U];
      yolo32_bound_ws_submit(p,(uintptr_t)b->base[0]+p->offsets[0],(uintptr_t)b->base[1]+p->offsets[1],UINT64_C(0),(uintptr_t)b->base[8]+p->offsets[3]);
    }
  }
  {
    const struct yolo32_prepared_ws_packet *p=&prepared_ws_packets[92];
    if (yolo32_independent_enabled) yolo32_independent_arm_tail_wait(8U);
    yolo32_bound_ws_submit(p,(uintptr_t)b->base[0]+p->offsets[0],(uintptr_t)b->base[1]+p->offsets[1],UINT64_C(0),(uintptr_t)b->base[8]+p->offsets[3]);
  }
  gemmini_fence();
}

static void yolo32_batch_ws_55(const struct yolo32_ws_binding *b) {
  ROCC_INSTRUCTION_RS1_RS2(XCUSTOM_ACC,prepared_ws_configs[18][0],prepared_ws_configs[18][1],0);
  ROCC_INSTRUCTION_RS1_RS2(XCUSTOM_ACC,prepared_ws_configs[1][0],prepared_ws_configs[1][1],0);
  ROCC_INSTRUCTION_RS1_RS2(XCUSTOM_ACC,prepared_ws_configs[16][0],prepared_ws_configs[16][1],0);
  ROCC_INSTRUCTION_RS1_RS2(XCUSTOM_ACC,prepared_ws_configs[13][0],prepared_ws_configs[13][1],0);
  for (unsigned iteration=0;iteration<2U;++iteration) {
    {
      const struct yolo32_prepared_ws_packet *p=&prepared_ws_packets[93U+iteration*1U];
      yolo32_bound_ws_submit(p,(uintptr_t)b->base[0]+p->offsets[0],(uintptr_t)b->base[1]+p->offsets[1],UINT64_C(0),(uintptr_t)b->base[8]+p->offsets[3]);
    }
  }
  {
    const struct yolo32_prepared_ws_packet *p=&prepared_ws_packets[95];
    if (yolo32_independent_enabled) yolo32_independent_arm_tail_wait(8U);
    yolo32_bound_ws_submit(p,(uintptr_t)b->base[0]+p->offsets[0],(uintptr_t)b->base[1]+p->offsets[1],UINT64_C(0),(uintptr_t)b->base[8]+p->offsets[3]);
  }
  gemmini_fence();
}

static void yolo32_batch_ws_57(const struct yolo32_ws_binding *b) {
  ROCC_INSTRUCTION_RS1_RS2(XCUSTOM_ACC,prepared_ws_configs[4][0],prepared_ws_configs[4][1],0);
  ROCC_INSTRUCTION_RS1_RS2(XCUSTOM_ACC,prepared_ws_configs[19][0],prepared_ws_configs[19][1],0);
  ROCC_INSTRUCTION_RS1_RS2(XCUSTOM_ACC,prepared_ws_configs[20][0],prepared_ws_configs[20][1],0);
  ROCC_INSTRUCTION_RS1_RS2(XCUSTOM_ACC,prepared_ws_configs[7][0],prepared_ws_configs[7][1],0);
  for (unsigned iteration=0;iteration<5U;++iteration) {
    ROCC_INSTRUCTION_RS1_RS2(XCUSTOM_ACC,prepared_ws_configs[16][0],prepared_ws_configs[16][1],0);
    {
      const struct yolo32_prepared_ws_packet *p=&prepared_ws_packets[96U+iteration*2U];
      if (yolo32_independent_enabled) yolo32_independent_arm_tail_wait(8U);
      yolo32_bound_ws_submit(p,(uintptr_t)b->base[0]+p->offsets[0],(uintptr_t)b->base[4]+p->offsets[1],(uintptr_t)b->base[6]+p->offsets[2],UINT64_C(0));
    }
    gemmini_fence();
    ROCC_INSTRUCTION_RS1_RS2(XCUSTOM_ACC,prepared_ws_configs[21][0],prepared_ws_configs[21][1],0);
    {
      const struct yolo32_prepared_ws_packet *p=&prepared_ws_packets[97U+iteration*2U];
      if (yolo32_independent_enabled) yolo32_independent_arm_tail_wait(8U);
      yolo32_bound_ws_submit(p,(uintptr_t)b->base[1]+p->offsets[0],(uintptr_t)b->base[4]+p->offsets[1],UINT64_C(0),(uintptr_t)b->base[8]+p->offsets[3]);
    }
    gemmini_fence();
  }
}

static void yolo32_batch_ws_69(const struct yolo32_ws_binding *b) {
  ROCC_INSTRUCTION_RS1_RS2(XCUSTOM_ACC,prepared_ws_configs[22][0],prepared_ws_configs[22][1],0);
  ROCC_INSTRUCTION_RS1_RS2(XCUSTOM_ACC,prepared_ws_configs[1][0],prepared_ws_configs[1][1],0);
  ROCC_INSTRUCTION_RS1_RS2(XCUSTOM_ACC,prepared_ws_configs[23][0],prepared_ws_configs[23][1],0);
  ROCC_INSTRUCTION_RS1_RS2(XCUSTOM_ACC,prepared_ws_configs[20][0],prepared_ws_configs[20][1],0);
  {
    const struct yolo32_prepared_ws_packet *p=&prepared_ws_packets[106];
    yolo32_bound_ws_submit(p,(uintptr_t)b->base[0]+p->offsets[0],(uintptr_t)b->base[1]+p->offsets[1],UINT64_C(0),(uintptr_t)b->base[8]+p->offsets[3]);
  }
  {
    const struct yolo32_prepared_ws_packet *p=&prepared_ws_packets[107];
    if (yolo32_independent_enabled) yolo32_independent_arm_tail_wait(8U);
    yolo32_bound_ws_submit(p,(uintptr_t)b->base[0]+p->offsets[0],(uintptr_t)b->base[1]+p->offsets[1],UINT64_C(0),(uintptr_t)b->base[8]+p->offsets[3]);
  }
  gemmini_fence();
}

static void yolo32_batch_ws_71(const struct yolo32_ws_binding *b) {
  ROCC_INSTRUCTION_RS1_RS2(XCUSTOM_ACC,prepared_ws_configs[4][0],prepared_ws_configs[4][1],0);
  ROCC_INSTRUCTION_RS1_RS2(XCUSTOM_ACC,prepared_ws_configs[24][0],prepared_ws_configs[24][1],0);
  ROCC_INSTRUCTION_RS1_RS2(XCUSTOM_ACC,prepared_ws_configs[25][0],prepared_ws_configs[25][1],0);
  ROCC_INSTRUCTION_RS1_RS2(XCUSTOM_ACC,prepared_ws_configs[7][0],prepared_ws_configs[7][1],0);
  for (unsigned iteration=0;iteration<3U;++iteration) {
    ROCC_INSTRUCTION_RS1_RS2(XCUSTOM_ACC,prepared_ws_configs[23][0],prepared_ws_configs[23][1],0);
    {
      const struct yolo32_prepared_ws_packet *p=&prepared_ws_packets[108U+iteration*2U];
      if (yolo32_independent_enabled) yolo32_independent_arm_tail_wait(8U);
      yolo32_bound_ws_submit(p,(uintptr_t)b->base[0]+p->offsets[0],(uintptr_t)b->base[4]+p->offsets[1],(uintptr_t)b->base[6]+p->offsets[2],UINT64_C(0));
    }
    gemmini_fence();
    ROCC_INSTRUCTION_RS1_RS2(XCUSTOM_ACC,prepared_ws_configs[26][0],prepared_ws_configs[26][1],0);
    {
      const struct yolo32_prepared_ws_packet *p=&prepared_ws_packets[109U+iteration*2U];
      if (yolo32_independent_enabled) yolo32_independent_arm_tail_wait(8U);
      yolo32_bound_ws_submit(p,(uintptr_t)b->base[1]+p->offsets[0],(uintptr_t)b->base[4]+p->offsets[1],UINT64_C(0),(uintptr_t)b->base[8]+p->offsets[3]);
    }
    gemmini_fence();
  }
}

static void yolo32_batch_ws_79(const struct yolo32_ws_binding *b) {
  ROCC_INSTRUCTION_RS1_RS2(XCUSTOM_ACC,prepared_ws_configs[4][0],prepared_ws_configs[4][1],0);
  ROCC_INSTRUCTION_RS1_RS2(XCUSTOM_ACC,prepared_ws_configs[27][0],prepared_ws_configs[27][1],0);
  ROCC_INSTRUCTION_RS1_RS2(XCUSTOM_ACC,prepared_ws_configs[25][0],prepared_ws_configs[25][1],0);
  ROCC_INSTRUCTION_RS1_RS2(XCUSTOM_ACC,prepared_ws_configs[7][0],prepared_ws_configs[7][1],0);
  for (unsigned iteration=0;iteration<3U;++iteration) {
    ROCC_INSTRUCTION_RS1_RS2(XCUSTOM_ACC,prepared_ws_configs[23][0],prepared_ws_configs[23][1],0);
    {
      const struct yolo32_prepared_ws_packet *p=&prepared_ws_packets[114U+iteration*4U];
      if (yolo32_independent_enabled) yolo32_independent_arm_tail_wait(8U);
      yolo32_bound_ws_submit(p,(uintptr_t)b->base[0]+p->offsets[0],(uintptr_t)b->base[4]+p->offsets[1],(uintptr_t)b->base[6]+p->offsets[2],UINT64_C(0));
    }
    gemmini_fence();
    ROCC_INSTRUCTION_RS1_RS2(XCUSTOM_ACC,prepared_ws_configs[23][0],prepared_ws_configs[23][1],0);
    {
      const struct yolo32_prepared_ws_packet *p=&prepared_ws_packets[115U+iteration*4U];
      if (yolo32_independent_enabled) yolo32_independent_arm_tail_wait(8U);
      yolo32_bound_ws_submit(p,(uintptr_t)b->base[1]+p->offsets[0],(uintptr_t)b->base[4]+p->offsets[1],UINT64_C(0),UINT64_C(0));
    }
    gemmini_fence();
    ROCC_INSTRUCTION_RS1_RS2(XCUSTOM_ACC,prepared_ws_configs[23][0],prepared_ws_configs[23][1],0);
    {
      const struct yolo32_prepared_ws_packet *p=&prepared_ws_packets[116U+iteration*4U];
      if (yolo32_independent_enabled) yolo32_independent_arm_tail_wait(8U);
      yolo32_bound_ws_submit(p,(uintptr_t)b->base[2]+p->offsets[0],(uintptr_t)b->base[4]+p->offsets[1],UINT64_C(0),UINT64_C(0));
    }
    gemmini_fence();
    ROCC_INSTRUCTION_RS1_RS2(XCUSTOM_ACC,prepared_ws_configs[23][0],prepared_ws_configs[23][1],0);
    {
      const struct yolo32_prepared_ws_packet *p=&prepared_ws_packets[117U+iteration*4U];
      if (yolo32_independent_enabled) yolo32_independent_arm_tail_wait(8U);
      yolo32_bound_ws_submit(p,(uintptr_t)b->base[3]+p->offsets[0],(uintptr_t)b->base[4]+p->offsets[1],UINT64_C(0),(uintptr_t)b->base[8]+p->offsets[3]);
    }
    gemmini_fence();
  }
}

static void yolo32_batch_ws_85(const struct yolo32_ws_binding *b) {
  ROCC_INSTRUCTION_RS1_RS2(XCUSTOM_ACC,prepared_ws_configs[4][0],prepared_ws_configs[4][1],0);
  ROCC_INSTRUCTION_RS1_RS2(XCUSTOM_ACC,prepared_ws_configs[13][0],prepared_ws_configs[13][1],0);
  ROCC_INSTRUCTION_RS1_RS2(XCUSTOM_ACC,prepared_ws_configs[7][0],prepared_ws_configs[7][1],0);
  for (unsigned iteration=0;iteration<3U;++iteration) {
    ROCC_INSTRUCTION_RS1_RS2(XCUSTOM_ACC,prepared_ws_configs[23][0],prepared_ws_configs[23][1],0);
    {
      const struct yolo32_prepared_ws_packet *p=&prepared_ws_packets[126U+iteration*4U];
      if (yolo32_independent_enabled) yolo32_independent_arm_tail_wait(8U);
      yolo32_bound_ws_submit(p,(uintptr_t)b->base[0]+p->offsets[0],(uintptr_t)b->base[4]+p->offsets[1],(uintptr_t)b->base[6]+p->offsets[2],UINT64_C(0));
    }
    gemmini_fence();
    yolo32_packed_silu_lut(packed_silu_luts[34]);
    gemmini_fence();
    ROCC_INSTRUCTION_RS1_RS2(XCUSTOM_ACC,prepared_ws_configs[28][0],prepared_ws_configs[28][1],0);
    ROCC_INSTRUCTION_RS1_RS2(XCUSTOM_ACC,prepared_ws_configs[29][0],prepared_ws_configs[29][1],0);
    {
      const struct yolo32_prepared_ws_packet *p=&prepared_ws_packets[127U+iteration*4U];
      if (yolo32_independent_enabled) yolo32_independent_arm_tail_wait(8U);
      yolo32_bound_ws_submit(p,(uintptr_t)b->base[1]+p->offsets[0],(uintptr_t)b->base[4]+p->offsets[1],UINT64_C(0),(uintptr_t)b->base[8]+p->offsets[3]);
    }
    gemmini_fence();
    ROCC_INSTRUCTION_RS1_RS2(XCUSTOM_ACC,prepared_ws_configs[23][0],prepared_ws_configs[23][1],0);
    {
      const struct yolo32_prepared_ws_packet *p=&prepared_ws_packets[128U+iteration*4U];
      if (yolo32_independent_enabled) yolo32_independent_arm_tail_wait(8U);
      yolo32_bound_ws_submit(p,UINT64_C(0),(uintptr_t)b->base[5]+p->offsets[1],(uintptr_t)b->base[7]+p->offsets[2],UINT64_C(0));
    }
    gemmini_fence();
    yolo32_packed_silu_lut(packed_silu_luts[35]);
    gemmini_fence();
    ROCC_INSTRUCTION_RS1_RS2(XCUSTOM_ACC,prepared_ws_configs[30][0],prepared_ws_configs[30][1],0);
    ROCC_INSTRUCTION_RS1_RS2(XCUSTOM_ACC,prepared_ws_configs[29][0],prepared_ws_configs[29][1],0);
    {
      const struct yolo32_prepared_ws_packet *p=&prepared_ws_packets[129U+iteration*4U];
      if (yolo32_independent_enabled) yolo32_independent_arm_tail_wait(8U);
      yolo32_bound_ws_submit(p,UINT64_C(0),(uintptr_t)b->base[5]+p->offsets[1],UINT64_C(0),(uintptr_t)b->base[9]+p->offsets[3]);
    }
    gemmini_fence();
  }
}

static void yolo32_batch_ws_93(const struct yolo32_ws_binding *b) {
  ROCC_INSTRUCTION_RS1_RS2(XCUSTOM_ACC,prepared_ws_configs[4][0],prepared_ws_configs[4][1],0);
  ROCC_INSTRUCTION_RS1_RS2(XCUSTOM_ACC,prepared_ws_configs[31][0],prepared_ws_configs[31][1],0);
  ROCC_INSTRUCTION_RS1_RS2(XCUSTOM_ACC,prepared_ws_configs[20][0],prepared_ws_configs[20][1],0);
  ROCC_INSTRUCTION_RS1_RS2(XCUSTOM_ACC,prepared_ws_configs[7][0],prepared_ws_configs[7][1],0);
  for (unsigned iteration=0;iteration<5U;++iteration) {
    ROCC_INSTRUCTION_RS1_RS2(XCUSTOM_ACC,prepared_ws_configs[32][0],prepared_ws_configs[32][1],0);
    {
      const struct yolo32_prepared_ws_packet *p=&prepared_ws_packets[138U+iteration*2U];
      if (yolo32_independent_enabled) yolo32_independent_arm_tail_wait(8U);
      yolo32_bound_ws_submit(p,(uintptr_t)b->base[0]+p->offsets[0],(uintptr_t)b->base[4]+p->offsets[1],(uintptr_t)b->base[6]+p->offsets[2],UINT64_C(0));
    }
    gemmini_fence();
    ROCC_INSTRUCTION_RS1_RS2(XCUSTOM_ACC,prepared_ws_configs[16][0],prepared_ws_configs[16][1],0);
    {
      const struct yolo32_prepared_ws_packet *p=&prepared_ws_packets[139U+iteration*2U];
      if (yolo32_independent_enabled) yolo32_independent_arm_tail_wait(8U);
      yolo32_bound_ws_submit(p,(uintptr_t)b->base[1]+p->offsets[0],(uintptr_t)b->base[4]+p->offsets[1],UINT64_C(0),(uintptr_t)b->base[8]+p->offsets[3]);
    }
    gemmini_fence();
  }
}

static void yolo32_batch_ws_99(const struct yolo32_ws_binding *b) {
  ROCC_INSTRUCTION_RS1_RS2(XCUSTOM_ACC,prepared_ws_configs[4][0],prepared_ws_configs[4][1],0);
  ROCC_INSTRUCTION_RS1_RS2(XCUSTOM_ACC,prepared_ws_configs[6][0],prepared_ws_configs[6][1],0);
  ROCC_INSTRUCTION_RS1_RS2(XCUSTOM_ACC,prepared_ws_configs[7][0],prepared_ws_configs[7][1],0);
  for (unsigned iteration=0;iteration<5U;++iteration) {
    ROCC_INSTRUCTION_RS1_RS2(XCUSTOM_ACC,prepared_ws_configs[33][0],prepared_ws_configs[33][1],0);
    {
      const struct yolo32_prepared_ws_packet *p=&prepared_ws_packets[148U+iteration*4U];
      if (yolo32_independent_enabled) yolo32_independent_arm_tail_wait(8U);
      yolo32_bound_ws_submit(p,(uintptr_t)b->base[0]+p->offsets[0],(uintptr_t)b->base[4]+p->offsets[1],(uintptr_t)b->base[6]+p->offsets[2],UINT64_C(0));
    }
    gemmini_fence();
    yolo32_packed_silu_lut(packed_silu_luts[40]);
    gemmini_fence();
    ROCC_INSTRUCTION_RS1_RS2(XCUSTOM_ACC,prepared_ws_configs[34][0],prepared_ws_configs[34][1],0);
    ROCC_INSTRUCTION_RS1_RS2(XCUSTOM_ACC,prepared_ws_configs[16][0],prepared_ws_configs[16][1],0);
    {
      const struct yolo32_prepared_ws_packet *p=&prepared_ws_packets[149U+iteration*4U];
      if (yolo32_independent_enabled) yolo32_independent_arm_tail_wait(8U);
      yolo32_bound_ws_submit(p,(uintptr_t)b->base[1]+p->offsets[0],(uintptr_t)b->base[4]+p->offsets[1],UINT64_C(0),(uintptr_t)b->base[8]+p->offsets[3]);
    }
    gemmini_fence();
    ROCC_INSTRUCTION_RS1_RS2(XCUSTOM_ACC,prepared_ws_configs[33][0],prepared_ws_configs[33][1],0);
    {
      const struct yolo32_prepared_ws_packet *p=&prepared_ws_packets[150U+iteration*4U];
      if (yolo32_independent_enabled) yolo32_independent_arm_tail_wait(8U);
      yolo32_bound_ws_submit(p,UINT64_C(0),(uintptr_t)b->base[5]+p->offsets[1],(uintptr_t)b->base[7]+p->offsets[2],UINT64_C(0));
    }
    gemmini_fence();
    yolo32_packed_silu_lut(packed_silu_luts[41]);
    gemmini_fence();
    ROCC_INSTRUCTION_RS1_RS2(XCUSTOM_ACC,prepared_ws_configs[35][0],prepared_ws_configs[35][1],0);
    ROCC_INSTRUCTION_RS1_RS2(XCUSTOM_ACC,prepared_ws_configs[16][0],prepared_ws_configs[16][1],0);
    {
      const struct yolo32_prepared_ws_packet *p=&prepared_ws_packets[151U+iteration*4U];
      if (yolo32_independent_enabled) yolo32_independent_arm_tail_wait(8U);
      yolo32_bound_ws_submit(p,UINT64_C(0),(uintptr_t)b->base[5]+p->offsets[1],UINT64_C(0),(uintptr_t)b->base[9]+p->offsets[3]);
    }
    gemmini_fence();
  }
}

static void yolo32_batch_ws_107(const struct yolo32_ws_binding *b) {
  ROCC_INSTRUCTION_RS1_RS2(XCUSTOM_ACC,prepared_ws_configs[4][0],prepared_ws_configs[4][1],0);
  ROCC_INSTRUCTION_RS1_RS2(XCUSTOM_ACC,prepared_ws_configs[36][0],prepared_ws_configs[36][1],0);
  ROCC_INSTRUCTION_RS1_RS2(XCUSTOM_ACC,prepared_ws_configs[13][0],prepared_ws_configs[13][1],0);
  ROCC_INSTRUCTION_RS1_RS2(XCUSTOM_ACC,prepared_ws_configs[7][0],prepared_ws_configs[7][1],0);
  for (unsigned iteration=0;iteration<10U;++iteration) {
    ROCC_INSTRUCTION_RS1_RS2(XCUSTOM_ACC,prepared_ws_configs[10][0],prepared_ws_configs[10][1],0);
    {
      const struct yolo32_prepared_ws_packet *p=&prepared_ws_packets[168U+iteration*2U];
      if (yolo32_independent_enabled) yolo32_independent_arm_tail_wait(8U);
      yolo32_bound_ws_submit(p,(uintptr_t)b->base[0]+p->offsets[0],(uintptr_t)b->base[4]+p->offsets[1],(uintptr_t)b->base[6]+p->offsets[2],UINT64_C(0));
    }
    gemmini_fence();
    ROCC_INSTRUCTION_RS1_RS2(XCUSTOM_ACC,prepared_ws_configs[37][0],prepared_ws_configs[37][1],0);
    {
      const struct yolo32_prepared_ws_packet *p=&prepared_ws_packets[169U+iteration*2U];
      if (yolo32_independent_enabled) yolo32_independent_arm_tail_wait(8U);
      yolo32_bound_ws_submit(p,(uintptr_t)b->base[1]+p->offsets[0],(uintptr_t)b->base[4]+p->offsets[1],UINT64_C(0),(uintptr_t)b->base[8]+p->offsets[3]);
    }
    gemmini_fence();
  }
}

static void yolo32_batch_ws_118(const struct yolo32_ws_binding *b) {
  ROCC_INSTRUCTION_RS1_RS2(XCUSTOM_ACC,prepared_ws_configs[4][0],prepared_ws_configs[4][1],0);
  ROCC_INSTRUCTION_RS1_RS2(XCUSTOM_ACC,prepared_ws_configs[13][0],prepared_ws_configs[13][1],0);
  ROCC_INSTRUCTION_RS1_RS2(XCUSTOM_ACC,prepared_ws_configs[7][0],prepared_ws_configs[7][1],0);
  for (unsigned iteration=0;iteration<3U;++iteration) {
    ROCC_INSTRUCTION_RS1_RS2(XCUSTOM_ACC,prepared_ws_configs[16][0],prepared_ws_configs[16][1],0);
    {
      const struct yolo32_prepared_ws_packet *p=&prepared_ws_packets[188U+iteration*4U];
      if (yolo32_independent_enabled) yolo32_independent_arm_tail_wait(8U);
      yolo32_bound_ws_submit(p,(uintptr_t)b->base[0]+p->offsets[0],(uintptr_t)b->base[4]+p->offsets[1],(uintptr_t)b->base[6]+p->offsets[2],UINT64_C(0));
    }
    gemmini_fence();
    yolo32_packed_silu_lut(packed_silu_luts[50]);
    gemmini_fence();
    ROCC_INSTRUCTION_RS1_RS2(XCUSTOM_ACC,prepared_ws_configs[38][0],prepared_ws_configs[38][1],0);
    ROCC_INSTRUCTION_RS1_RS2(XCUSTOM_ACC,prepared_ws_configs[39][0],prepared_ws_configs[39][1],0);
    {
      const struct yolo32_prepared_ws_packet *p=&prepared_ws_packets[189U+iteration*4U];
      if (yolo32_independent_enabled) yolo32_independent_arm_tail_wait(8U);
      yolo32_bound_ws_submit(p,(uintptr_t)b->base[1]+p->offsets[0],(uintptr_t)b->base[4]+p->offsets[1],UINT64_C(0),(uintptr_t)b->base[8]+p->offsets[3]);
    }
    gemmini_fence();
    ROCC_INSTRUCTION_RS1_RS2(XCUSTOM_ACC,prepared_ws_configs[16][0],prepared_ws_configs[16][1],0);
    {
      const struct yolo32_prepared_ws_packet *p=&prepared_ws_packets[190U+iteration*4U];
      if (yolo32_independent_enabled) yolo32_independent_arm_tail_wait(8U);
      yolo32_bound_ws_submit(p,UINT64_C(0),(uintptr_t)b->base[5]+p->offsets[1],(uintptr_t)b->base[7]+p->offsets[2],UINT64_C(0));
    }
    gemmini_fence();
    yolo32_packed_silu_lut(packed_silu_luts[51]);
    gemmini_fence();
    ROCC_INSTRUCTION_RS1_RS2(XCUSTOM_ACC,prepared_ws_configs[40][0],prepared_ws_configs[40][1],0);
    ROCC_INSTRUCTION_RS1_RS2(XCUSTOM_ACC,prepared_ws_configs[39][0],prepared_ws_configs[39][1],0);
    {
      const struct yolo32_prepared_ws_packet *p=&prepared_ws_packets[191U+iteration*4U];
      if (yolo32_independent_enabled) yolo32_independent_arm_tail_wait(8U);
      yolo32_bound_ws_submit(p,UINT64_C(0),(uintptr_t)b->base[5]+p->offsets[1],UINT64_C(0),(uintptr_t)b->base[9]+p->offsets[3]);
    }
    gemmini_fence();
  }
}

static void yolo32_batch_ws_130(const struct yolo32_ws_binding *b) {
  ROCC_INSTRUCTION_RS1_RS2(XCUSTOM_ACC,prepared_ws_configs[4][0],prepared_ws_configs[4][1],0);
  ROCC_INSTRUCTION_RS1_RS2(XCUSTOM_ACC,prepared_ws_configs[41][0],prepared_ws_configs[41][1],0);
  ROCC_INSTRUCTION_RS1_RS2(XCUSTOM_ACC,prepared_ws_configs[20][0],prepared_ws_configs[20][1],0);
  ROCC_INSTRUCTION_RS1_RS2(XCUSTOM_ACC,prepared_ws_configs[7][0],prepared_ws_configs[7][1],0);
  for (unsigned iteration=0;iteration<5U;++iteration) {
    ROCC_INSTRUCTION_RS1_RS2(XCUSTOM_ACC,prepared_ws_configs[16][0],prepared_ws_configs[16][1],0);
    {
      const struct yolo32_prepared_ws_packet *p=&prepared_ws_packets[200U+iteration*2U];
      if (yolo32_independent_enabled) yolo32_independent_arm_tail_wait(8U);
      yolo32_bound_ws_submit(p,(uintptr_t)b->base[0]+p->offsets[0],(uintptr_t)b->base[4]+p->offsets[1],(uintptr_t)b->base[6]+p->offsets[2],UINT64_C(0));
    }
    gemmini_fence();
    ROCC_INSTRUCTION_RS1_RS2(XCUSTOM_ACC,prepared_ws_configs[42][0],prepared_ws_configs[42][1],0);
    {
      const struct yolo32_prepared_ws_packet *p=&prepared_ws_packets[201U+iteration*2U];
      if (yolo32_independent_enabled) yolo32_independent_arm_tail_wait(8U);
      yolo32_bound_ws_submit(p,(uintptr_t)b->base[1]+p->offsets[0],(uintptr_t)b->base[4]+p->offsets[1],UINT64_C(0),(uintptr_t)b->base[8]+p->offsets[3]);
    }
    gemmini_fence();
  }
}

static void yolo32_batch_ws_141(const struct yolo32_ws_binding *b) {
  ROCC_INSTRUCTION_RS1_RS2(XCUSTOM_ACC,prepared_ws_configs[4][0],prepared_ws_configs[4][1],0);
  ROCC_INSTRUCTION_RS1_RS2(XCUSTOM_ACC,prepared_ws_configs[20][0],prepared_ws_configs[20][1],0);
  ROCC_INSTRUCTION_RS1_RS2(XCUSTOM_ACC,prepared_ws_configs[7][0],prepared_ws_configs[7][1],0);
  for (unsigned iteration=0;iteration<2U;++iteration) {
    ROCC_INSTRUCTION_RS1_RS2(XCUSTOM_ACC,prepared_ws_configs[43][0],prepared_ws_configs[43][1],0);
    {
      const struct yolo32_prepared_ws_packet *p=&prepared_ws_packets[210U+iteration*4U];
      if (yolo32_independent_enabled) yolo32_independent_arm_tail_wait(8U);
      yolo32_bound_ws_submit(p,(uintptr_t)b->base[0]+p->offsets[0],(uintptr_t)b->base[4]+p->offsets[1],(uintptr_t)b->base[6]+p->offsets[2],UINT64_C(0));
    }
    gemmini_fence();
    yolo32_packed_silu_lut(packed_silu_luts[60]);
    gemmini_fence();
    ROCC_INSTRUCTION_RS1_RS2(XCUSTOM_ACC,prepared_ws_configs[44][0],prepared_ws_configs[44][1],0);
    ROCC_INSTRUCTION_RS1_RS2(XCUSTOM_ACC,prepared_ws_configs[23][0],prepared_ws_configs[23][1],0);
    {
      const struct yolo32_prepared_ws_packet *p=&prepared_ws_packets[211U+iteration*4U];
      if (yolo32_independent_enabled) yolo32_independent_arm_tail_wait(8U);
      yolo32_bound_ws_submit(p,(uintptr_t)b->base[1]+p->offsets[0],(uintptr_t)b->base[4]+p->offsets[1],UINT64_C(0),(uintptr_t)b->base[8]+p->offsets[3]);
    }
    gemmini_fence();
    ROCC_INSTRUCTION_RS1_RS2(XCUSTOM_ACC,prepared_ws_configs[43][0],prepared_ws_configs[43][1],0);
    {
      const struct yolo32_prepared_ws_packet *p=&prepared_ws_packets[212U+iteration*4U];
      if (yolo32_independent_enabled) yolo32_independent_arm_tail_wait(8U);
      yolo32_bound_ws_submit(p,UINT64_C(0),(uintptr_t)b->base[5]+p->offsets[1],(uintptr_t)b->base[7]+p->offsets[2],UINT64_C(0));
    }
    gemmini_fence();
    yolo32_packed_silu_lut(packed_silu_luts[61]);
    gemmini_fence();
    ROCC_INSTRUCTION_RS1_RS2(XCUSTOM_ACC,prepared_ws_configs[45][0],prepared_ws_configs[45][1],0);
    ROCC_INSTRUCTION_RS1_RS2(XCUSTOM_ACC,prepared_ws_configs[23][0],prepared_ws_configs[23][1],0);
    {
      const struct yolo32_prepared_ws_packet *p=&prepared_ws_packets[213U+iteration*4U];
      if (yolo32_independent_enabled) yolo32_independent_arm_tail_wait(8U);
      yolo32_bound_ws_submit(p,UINT64_C(0),(uintptr_t)b->base[5]+p->offsets[1],UINT64_C(0),(uintptr_t)b->base[9]+p->offsets[3]);
    }
    gemmini_fence();
  }
}

static void yolo32_batch_ws_153(const struct yolo32_ws_binding *b) {
  ROCC_INSTRUCTION_RS1_RS2(XCUSTOM_ACC,prepared_ws_configs[4][0],prepared_ws_configs[4][1],0);
  ROCC_INSTRUCTION_RS1_RS2(XCUSTOM_ACC,prepared_ws_configs[46][0],prepared_ws_configs[46][1],0);
  ROCC_INSTRUCTION_RS1_RS2(XCUSTOM_ACC,prepared_ws_configs[25][0],prepared_ws_configs[25][1],0);
  ROCC_INSTRUCTION_RS1_RS2(XCUSTOM_ACC,prepared_ws_configs[7][0],prepared_ws_configs[7][1],0);
  for (unsigned iteration=0;iteration<3U;++iteration) {
    ROCC_INSTRUCTION_RS1_RS2(XCUSTOM_ACC,prepared_ws_configs[23][0],prepared_ws_configs[23][1],0);
    {
      const struct yolo32_prepared_ws_packet *p=&prepared_ws_packets[218U+iteration*2U];
      if (yolo32_independent_enabled) yolo32_independent_arm_tail_wait(8U);
      yolo32_bound_ws_submit(p,(uintptr_t)b->base[0]+p->offsets[0],(uintptr_t)b->base[4]+p->offsets[1],(uintptr_t)b->base[6]+p->offsets[2],UINT64_C(0));
    }
    gemmini_fence();
    ROCC_INSTRUCTION_RS1_RS2(XCUSTOM_ACC,prepared_ws_configs[47][0],prepared_ws_configs[47][1],0);
    {
      const struct yolo32_prepared_ws_packet *p=&prepared_ws_packets[219U+iteration*2U];
      if (yolo32_independent_enabled) yolo32_independent_arm_tail_wait(8U);
      yolo32_bound_ws_submit(p,(uintptr_t)b->base[1]+p->offsets[0],(uintptr_t)b->base[4]+p->offsets[1],UINT64_C(0),(uintptr_t)b->base[8]+p->offsets[3]);
    }
    gemmini_fence();
  }
}
