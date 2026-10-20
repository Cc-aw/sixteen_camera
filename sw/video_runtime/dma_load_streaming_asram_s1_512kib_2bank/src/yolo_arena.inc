/* Tensor offsets stay frozen. Local SPPF workspaces occupy physical ASRAM
 * beyond the logical activation arena, with guards between allocations. */
#ifndef __riscv
static int8_t host_local_backing[3][ASRAM_BYTES_PER_BANK+128] __attribute__((aligned(64)));
#endif
static const char *storage_name(unsigned profile) { return profile?"local_arena":"ddr_arena"; }
static unsigned yolo_sppf_local(void) { return storage_profile && YOLO_SPPF_ASRAM; }
static uintptr_t arena_dma_address(uintptr_t address,unsigned lane) {
    ActivationArenaView *view=&arena_views[lane];
    uintptr_t base=(uintptr_t)view->cpu_base;
    if(address>=base && address-base<view->logical_bytes) {
        int8_t *cpu;uintptr_t dma;
        if(!activation_memory_offset(view,address-base,1,&cpu,&dma))at_fail("arena_dma_range",address);
        return dma;
    }
    if(yolo_sppf_local()) {
        const size_t offsets[]={SPPF_PAD_OFFSET,SPPF_INTERMEDIATE_OFFSET};
        const size_t sizes[]={SPPF_PAD_BYTES,SPPF_INTERMEDIATE_BYTES};
        for(unsigned i=0;i<2;i++)if(address>=base+offsets[i] && address-base-offsets[i]<sizes[i])
            return view->dma_base+offsets[i]+(address-base-offsets[i]);
    }
    return address;
}
static bool yolo_completion(void *context,unsigned lane) {
    (void)context;
    if(lane>=3)return false;
#ifdef __riscv
    /* Frozen Rocket stalls FENCE on Saturn backend/trap-check busy. Saturn
       busy includes both TL reader/writer A-to-D inflights and HellaCache
       inflights. ASRAM acknowledges stores after physical commit. See the
       checked frozen RTL/source chain in validation/yolo_completion.md. */
    __asm__ volatile("fence rw,rw":::"memory");
#endif
    return true;
}
static void yolo_commit_lane(unsigned lane) {
    if(lane>=3 || !activation_memory_commit(&arena_views[lane],yolo_completion,NULL))
        at_fail("activation_memory_commit",lane);
}
static void yolo_bind_storage(unsigned profile,int quiescent) {
    if(profile>1 || !quiescent)at_fail("arena_switch_not_quiescent",profile);
#ifndef __riscv
    arena_caps=(ActivationSramCapabilities){.magic=0x41535231,.abi=0x10000,.enabled_mask=7,
        .physical_bytes=ASRAM_BYTES_PER_BANK,.logical_bytes=ASRAM_ARENA_BYTES,
        .data_width_bits=256,.clock_hz=ASRAM_CLOCK_HZ,.base={ASRAM_BASE_0,ASRAM_BASE_1,ASRAM_BASE_2}};
#endif
    for(unsigned lane=0;lane<3;lane++) {
        int8_t *local=NULL;
#ifndef __riscv
        local=host_local_backing[lane]+64;
        memset(host_local_backing[lane],0x6d,64);
        memset(host_local_backing[lane]+64+ASRAM_BYTES_PER_BANK,0x6d,64);
#endif
        int8_t *ddr=ddr_activation_backing[lane]+64;
        memset(ddr_activation_backing[lane],0x6d,64);
        if(!activation_memory_bind(&arena_views[lane],profile?ACTIVATION_MEMORY_LOCAL:ACTIVATION_MEMORY_DDR,
            lane,ddr,(uintptr_t)ddr,ASRAM_ARENA_BYTES,&arena_caps,local,quiescent))
            at_fail("arena_bind",lane);
        activation_arenas[lane]=arena_views[lane].cpu_base;
        memory_pad[lane]=profile && YOLO_SPPF_ASRAM ?
            arena_views[lane].cpu_base+SPPF_PAD_OFFSET:ddr_memory_pad[lane];
        memory_intermediate[lane]=profile && YOLO_SPPF_ASRAM ?
            arena_views[lane].cpu_base+SPPF_INTERMEDIATE_OFFSET:ddr_memory_intermediate[lane];
    }
    storage_profile=profile;
    yolo_fill_arenas(0);
}
static void yolo_fill_arenas(unsigned char value) {
    for(unsigned lane=0;lane<3;lane++) {
        memset(arena_views[lane].cpu_base,value,arena_views[lane].logical_bytes);
        volatile uint8_t *tail=(volatile uint8_t *)arena_views[lane].cpu_base+ASRAM_ARENA_BYTES;
        size_t guard=storage_profile?ASRAM_BYTES_PER_BANK-ASRAM_ARENA_BYTES:64;
        for(size_t i=0;i<guard;i++)tail[i]=0x6d;
        memset(memory_pad[lane],value,SPPF_PAD_BYTES);
        memset(memory_intermediate[lane],value,SPPF_INTERMEDIATE_BYTES);
        yolo_commit_lane(lane);
    }
}
static void yolo_check_guards(void) {
    for(unsigned lane=0;lane<3;lane++) {
        volatile uint8_t *tail=(volatile uint8_t *)arena_views[lane].cpu_base+ASRAM_ARENA_BYTES;
        size_t guard=storage_profile?ASRAM_BYTES_PER_BANK-ASRAM_ARENA_BYTES:64;
        for(size_t i=0;i<guard;i++) {
            size_t offset=ASRAM_ARENA_BYTES+i;
            if(yolo_sppf_local() &&
               ((offset>=SPPF_PAD_OFFSET && offset-SPPF_PAD_OFFSET<SPPF_PAD_BYTES) ||
                (offset>=SPPF_INTERMEDIATE_OFFSET && offset-SPPF_INTERMEDIATE_OFFSET<SPPF_INTERMEDIATE_BYTES)))continue;
            if(tail[i]!=0x6d)at_fail("arena_tail_guard",lane*guard+i);
        }
        for(unsigned i=0;i<64;i++) {
            if((uint8_t)ddr_activation_backing[lane][i]!=0x6d)at_fail("ddr_prefix_guard",lane*64+i);
#ifndef __riscv
            if((uint8_t)host_local_backing[lane][i]!=0x6d ||
               (uint8_t)host_local_backing[lane][64+ASRAM_BYTES_PER_BANK+i]!=0x6d)
                at_fail("host_local_guard",lane*64+i);
#endif
        }
    }
}
static uint64_t yolo_hash_arenas(void) {
    uint64_t value=0;
    for(unsigned lane=0;lane<3;lane++)value^=hash_bytes(arena_views[lane].cpu_base,ASRAM_ARENA_BYTES)<<(lane*3);
    return value;
}
