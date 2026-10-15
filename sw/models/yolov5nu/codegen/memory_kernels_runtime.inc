/* DDR batch kernels adapted from the colleague's yolov5nu_gemmini_memory.h.
 * Compile against this project's native FP16 ABI and worker dispatch. */
static elem_t memory_pad[3][17*22*128] __attribute__((aligned(64)));
static elem_t memory_intermediate[3][15*20*128] __attribute__((aligned(64)));
static Yolo32MemoryStats memory_stats[3];
const Yolo32MemoryStats *yolo32_memory_stats(unsigned w) {
    return w<3 ? &memory_stats[w] : NULL;
}
static unsigned memory_worker(void) {
    unsigned w=gemmini_pool_active_worker;
    if (w>=3) yolo32_fail("memory_worker");
    return w;
}
static void memory_fill(elem_t *dst,size_t n,elem_t value) {
#ifdef __riscv_vector
    while (n) {
        size_t vl;
        __asm__ volatile("vsetvli %0, %1, e8, m8, ta, ma\n\t"
                         "vmv.v.x v0, %2\n\t"
                         "vse8.v v0, (%3)"
            : "=&r"(vl) : "r"(n),"r"((intptr_t)value),"r"(dst)
            : "memory","v0","v1","v2","v3","v4","v5","v6","v7");
        n-=vl; dst+=vl;
    }
#else
    while (n--) *dst++=value;
#endif
}
static void memory_pad_input(const elem_t *src,elem_t *pad,int h,int w,int c) {
    size_t stride=(size_t)(w+2)*c;
    memory_fill(pad,stride,elem_t_min);
    memory_fill(pad+(h+1)*stride,stride,elem_t_min);
    for (int y=0;y<h;++y) {
        elem_t *row=pad+(y+1)*stride;
        memory_fill(row,c,elem_t_min);
        yolov5nu_rvv_copy_i8(src+(size_t)y*w*c,row+c,(size_t)w*c);
        memory_fill(row+(w+1)*c,c,elem_t_min);
    }
}
static void memory_load(const elem_t *src,uint32_t addr,int cols,int rows) {
    yolo32_independent_memory_submit();
    ++memory_stats[memory_worker()].mvin;
    gemmini_extended_mvin(src,addr,cols,rows);
}
static void memory_store(elem_t *dst,uint32_t addr,int cols,int rows) {
    yolo32_independent_memory_submit();
    ++memory_stats[memory_worker()].mvout;
    gemmini_extended_mvout(dst,addr,cols,rows);
}
static void memory_wait(void) {
    ++memory_stats[memory_worker()].waits;
    /* This macro is scoped to yolo32_model_fence by model.c. Independent
     * workers yield; serial/legacy controls retain the native fence. */
    gemmini_fence();
}
static void memory_pool3(const elem_t *pad,elem_t *dst,int h,int w,int c) {
    int positions=(h+2)*(w+2),blocks=MAX_BLOCK_LEN;
    if (blocks>ACC_ROWS/positions) blocks=ACC_ROWS/positions;
    if (blocks<1 || h+2>255 || w+2>255) yolo32_fail("memory_pool_capacity");
    const uint32_t acc=UINT32_C(1)<<31;
    gemmini_extended4_config_ld(c,MVIN_SCALE_IDENTITY,true,positions,0);
    gemmini_extended2_config_st(c,NO_ACTIVATION,ACC_SCALE_IDENTITY,
                               1,3,w,h,w,h+2,w+2,0,0);
    for (int channel=0;channel<c;channel+=blocks*DIM) {
        int cols=c-channel;
        if (cols>blocks*DIM) cols=blocks*DIM;
        for (int p=0;p<positions;p+=DIM) {
            int rows=positions-p>DIM ? DIM : positions-p;
            memory_load(pad+(size_t)p*c+channel,acc+p,cols,rows);
        }
        memory_wait();
        for (int k=0;k<cols;k+=DIM) {
            int width=cols-k>DIM ? DIM : cols-k;
            memory_store(dst+channel+k,acc+(k/DIM)*positions,width,0);
        }
        memory_wait();
    }
}
static void yolo32_memory_pool5(const elem_t *src,elem_t *dst,int h,int w,int c) {
    if (h<1 || h>15 || w<1 || w>20 || c<1 || c>128)
        yolo32_fail("memory_pool_geometry");
    unsigned worker=memory_worker();
    elem_t *pad=memory_pad[worker],*mid=memory_intermediate[worker];
    ++memory_stats[worker].pool_calls;
    uint64_t start=analysis_enabled ? read_cycle() : 0;
    memory_pad_input(src,pad,h,w,c);
    if (analysis_enabled) memory_stats[worker].pad_cycles+=read_cycle()-start;
    memory_pool3(pad,mid,h,w,c);
    start=analysis_enabled ? read_cycle() : 0;
    memory_pad_input(mid,pad,h,w,c);
    if (analysis_enabled) memory_stats[worker].pad_cycles+=read_cycle()-start;
    memory_pool3(pad,dst,h,w,c);
}
#if YOLO32_RESIZE_BATCH
/* Ordinary DMA commands do not use LoopConv credit. Every batch keeps its
 * original ingress/retirement/DMA completion check on both phase boundaries.
 * There is no yield or completion-proof refresh inside either submit loop,
 * so dirtying once BEFORE the first command covers all commands in that phase. */
static void yolo32_memory_resize2(const elem_t *src,elem_t *dst,int h,int w,int c) {
    if (h<1 || h>30 || w<1 || w>40 || c<1 || c>128)
        yolo32_fail("memory_resize_geometry");
    unsigned worker=memory_worker();
    Yolo32MemoryStats *stats=&memory_stats[worker];
    ++stats->resize_calls;
    const uint32_t acc=UINT32_C(1)<<31;
    const int ow=2*w;
    const size_t input_stride=(size_t)w*c,output_stride=(size_t)ow*c;
    gemmini_extended_config_st(c,NO_ACTIVATION,ACC_SCALE_IDENTITY);
    for (int channel=0;channel<c;channel+=MAX_BLOCK_LEN*DIM) {
        int cols=c-channel>MAX_BLOCK_LEN*DIM ? MAX_BLOCK_LEN*DIM : c-channel;
        int blocks=(cols+DIM-1)/DIM;
        int batch_limit=ACC_ROWS/(blocks*ow);
        if (batch_limit>h) batch_limit=h;
        if (YOLO32_RESIZE_ROWS && batch_limit>YOLO32_RESIZE_ROWS)
            batch_limit=YOLO32_RESIZE_ROWS;
        if (batch_limit<1) yolo32_fail("memory_resize_capacity");
        const int plane_rows=batch_limit*ow;
        gemmini_extended4_config_ld(0,MVIN_SCALE_IDENTITY,true,plane_rows,0);
        for (int first_y=0;first_y<h;first_y+=batch_limit) {
            int count=h-first_y>batch_limit ? batch_limit : h-first_y;
            yolo32_independent_memory_submit();
            stats->mvin+=(uint64_t)count*w;
            uintptr_t input_row=(uintptr_t)src+(size_t)first_y*input_stride+channel;
            for (int y=0;y<count;++y,input_row+=input_stride) {
                uintptr_t pixel=input_row;
                uint32_t address=acc+y*ow;
                for (int x=0;x<w;++x,pixel+=c,address+=2)
                    gemmini_extended_mvin((const elem_t *)pixel,address,cols,2);
            }
            memory_wait();
            /* The wait may have restored a valid local completion proof.
             * Invalidate it again before any new store command is emitted. */
            yolo32_independent_memory_submit();
            stats->mvout+=(uint64_t)blocks*2*count*((ow+DIM-1)/DIM);
            for (int block=0;block<blocks;++block) {
                int width=cols-block*DIM>DIM ? DIM : cols-block*DIM;
                uintptr_t output_row=(uintptr_t)dst+(size_t)(2*first_y)*output_stride+channel+block*DIM;
                uint32_t row_address=acc+block*plane_rows;
                for (int y=0;y<count;++y,output_row+=2*output_stride,row_address+=ow) {
                    for (int dy=0;dy<2;++dy) {
                        uintptr_t pixel=output_row+dy*output_stride;
                        uint32_t address=row_address;
                        for (int x=0;x<ow;x+=DIM,pixel+=(size_t)DIM*c,address+=DIM) {
                            int rows=ow-x>DIM ? DIM : ow-x;
                            gemmini_extended_mvout((elem_t *)pixel,address,width,rows);
                        }
                    }
                }
            }
            memory_wait(); /* ACC region can be reused only after stores retire. */
        }
    }
}
#else
static void yolo32_memory_resize2(const elem_t *src,elem_t *dst,int h,int w,int c) {
    if (h<1 || h>30 || w<1 || w>40 || c<1 || c>128)
        yolo32_fail("memory_resize_geometry");
    ++memory_stats[memory_worker()].resize_calls;
    const uint32_t acc=UINT32_C(1)<<31;
    int ow=2*w,blocks=MAX_BLOCK_LEN;
    if (blocks>ACC_ROWS/ow) blocks=ACC_ROWS/ow;
    if (blocks<1) yolo32_fail("memory_resize_capacity");
    gemmini_extended4_config_ld(0,MVIN_SCALE_IDENTITY,true,ow,0);
    gemmini_extended_config_st(c,NO_ACTIVATION,ACC_SCALE_IDENTITY);
    for (int channel=0;channel<c;channel+=blocks*DIM) {
        int cols=c-channel>blocks*DIM ? blocks*DIM : c-channel;
        for (int y=0;y<h;++y) {
            for (int x=0;x<w;++x)
                memory_load(src+((size_t)y*w+x)*c+channel,acc+2*x,cols,2);
            memory_wait();
            for (int k=0;k<cols;k+=DIM) {
                int width=cols-k>DIM ? DIM : cols-k;
                for (int dy=0;dy<2;++dy)
                    for (int x=0;x<ow;x+=DIM) {
                        int rows=ow-x>DIM ? DIM : ow-x;
                        memory_store(dst+((size_t)(2*y+dy)*ow+x)*c+channel+k,
                                     acc+(k/DIM)*ow+x,width,rows);
                    }
            }
            memory_wait();
        }
    }
}
#endif
