/* Test backend for actual emitted command operands, not a hardware simulator.
 * Decode FP16 config and model delayed per-worker DMA completion. */
#define _XOPEN_SOURCE 700
#include <assert.h>
#include <stdbool.h>
#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#ifndef __riscv
#include <ucontext.h>
#endif
#include "independent.h"
#include "yolo32.h"
#include "memory_kernels.h"
#include "mmio.h"
#include "gemmini_float16.h"
typedef int8_t elem_t;
typedef float scale_t,acc_scale_t;
typedef uint16_t scale_t_bits,acc_scale_t_bits;
static const elem_t elem_t_min=-128;
#define DIM 32
#define ACC_ROWS 2048
#define MAX_BLOCK_LEN 2
#define XCUSTOM_ACC 3
#define NO_ACTIVATION 0
#define MVIN_SCALE_IDENTITY 1.0f
#define ACC_SCALE_IDENTITY 1.0f
#define CONFIG_LD 1
#define CONFIG_ST 2
#define ADDR_LEN 32
#define k_CONFIG 0
#define k_MVIN 2
#define k_MVOUT 3
#define scale_t_to_scale_t_bits gemmini_float_to_half
#define acc_scale_t_to_acc_scale_t_bits gemmini_float_to_half
uint64_t tick;
static unsigned gemmini_pool_active_worker,analysis_enabled,stage[3],heads[3];
static unsigned tested_parallel,peer_progress;
unsigned memory_dirty_calls[3];
unsigned yolo32_test_memory_proof_clean(unsigned worker);
static int8_t accumulator[3][ACC_ROWS][DIM];
static struct {
    unsigned ld_stride,block_stride,st_stride,ph,pw,ih,iw,pitch,pool;
    uint64_t due;
    /* Delayed command transcript, not a claimed hardware queue depth. */
    struct {unsigned f;uintptr_t a;uint64_t b;} queue[1024];
    unsigned queued;
} hw[3];
static unsigned seen_commands[3][4];
static uint32_t independent_accepted_base[3];
void yolo32_fail(const char *s){fprintf(stderr,"FAIL: %s\n",s);exit(42);}
unsigned yolo32_stage(unsigned w){return stage[w];}
void yolo32_independent_select(unsigned w){gemmini_pool_active_worker=w;}
void yolo32_independent_snapshot(unsigned w){independent_accepted_base[w]=0;}
unsigned yolo32_independent_head_mask(unsigned w){return heads[w];}
void yolo32_ppu_early_service(void){}
static uint32_t independent_counter_read(unsigned w,unsigned r){(void)w;(void)r;return 0;}
static unsigned read_worker_busy(unsigned w){(void)w;return 0;} /* Deliberately weak. */
static void drain(unsigned w){
    if (!hw[w].queued) return;
    for(unsigned i=0;i<hw[w].queued;++i){
        unsigned f=hw[w].queue[i].f;
        uintptr_t a=hw[w].queue[i].a;uint64_t b=hw[w].queue[i].b;
        if(!f){
            assert((b>>32)==0x3c00 || ((a&3)==CONFIG_LD));
            if((a&3)==CONFIG_LD){
                assert((a>>32)==0x3c00 && ((a>>2)&1) && ((a>>8)&255)==1);
                hw[w].ld_stride=b;hw[w].block_stride=(a>>16)&65535;
            }else{
                assert((a&3)==CONFIG_ST && ((a>>2)&7)==0);
                hw[w].st_stride=(uint32_t)b;hw[w].pool=(a>>5)&3;
                if(hw[w].pool){
                    assert(hw[w].pool==1&&((a>>7)&3)==3);
                    hw[w].pitch=(a>>24)&255;hw[w].ph=(a>>32)&255;hw[w].pw=(a>>40)&255;
                    hw[w].ih=(a>>48)&255;hw[w].iw=(a>>56)&255;
                }
            }
            continue;
        }
        unsigned addr=(uint32_t)b,cols=(b>>32)&65535,rows=(b>>48)&65535;
        assert(addr&(1U<<31));addr&=0x7fffffff;
        if(f==2){
            assert(cols<=64&&rows<=32&&cols>0&&rows>0);
            const int8_t *src=(const int8_t *)a;
            for(unsigned row=0;row<rows;row++)for(unsigned ch=0;ch<cols;ch++){
                unsigned ar=addr+row+(ch/DIM)*hw[w].block_stride;
                assert(ar<ACC_ROWS);
                accumulator[w][ar][ch%DIM]=src[row*hw[w].ld_stride+ch];
            }
        }else{
            assert(f==3&&cols<=DIM&&cols>0);int8_t *dst=(int8_t *)a;
            if(hw[w].pool){
                assert(!rows);
                for(unsigned y=0;y<hw[w].ph;y++)for(unsigned x=0;x<hw[w].pw;x++)for(unsigned ch=0;ch<cols;ch++){
                    int v=-128;
                    for(unsigned ky=0;ky<3;ky++)for(unsigned kx=0;kx<3;kx++){
                        unsigned ar=addr+(y+ky)*hw[w].iw+x+kx;
                        assert(ar<ACC_ROWS);
                        if(accumulator[w][ar][ch]>v)v=accumulator[w][ar][ch];
                    }
                    dst[(y*hw[w].pitch+x)*hw[w].st_stride+ch]=v;
                }
            }else{
                assert(rows>0&&rows<=32);
                for(unsigned row=0;row<rows;row++)for(unsigned ch=0;ch<cols;ch++){
                    assert(addr+row<ACC_ROWS);
                    dst[row*hw[w].st_stride+ch]=accumulator[w][addr+row][ch];
                }
            }
        }
    }
    hw[w].queued=0;
}
static uint64_t independent_status_read(unsigned w){
    if(getenv("INGRESS_ERROR")&&w==0)return 0xc000;
    if(getenv("STUCK")&&w==0&&hw[w].queued)return 1;
    if(hw[w].queued&&tick>=hw[w].due)drain(w);
    return hw[w].queued ? 1 : 0;
}
unsigned yolo32_independent_busy_mask(void){
    unsigned mask=0;for(unsigned w=0;w<3;w++)if(independent_status_read(w)&1)mask|=1U<<w;return mask;
}
unsigned yolo32_independent_credit_ready(unsigned w,uint32_t issued,uint32_t *pending){
    (void)w;assert(!issued);*pending=0;return 1;
}
static void emit(unsigned f,uint64_t a,uint64_t b){
    unsigned w=gemmini_pool_active_worker;assert(f<4&&hw[w].queued<1024);
    if(yolo32_independent_enabled && (f==2||f==3))
        assert(!yolo32_test_memory_proof_clean(w));
    if(yolo32_independent_enabled)for(unsigned peer=0;peer<3;peer++)
        if(peer!=w&&hw[peer].queued)peer_progress++;
    hw[w].queue[hw[w].queued++]=(typeof(hw[w].queue[0])){f,a,b};
    hw[w].due=tick+5000;
    seen_commands[w][f]++;
}
#define ROCC_INSTRUCTION_RS1_RS2(x,a,b,f) emit(f,(uint64_t)(a),(uint64_t)(b))
/* Native ABI macros inserted here by the test builder. */
#include "memory_native_macros.inc"
static void yolov5nu_rvv_copy_i8(const elem_t *src,elem_t *dst,size_t n){
#ifdef __riscv_vector
    while(n){size_t vl;
        __asm__ volatile("vsetvli %0, %1, e8, m8, ta, ma\n\tvle8.v v0, (%2)\n\tvse8.v v0, (%3)"
          : "=&r"(vl):"r"(n),"r"(src),"r"(dst):"memory","v0","v1","v2","v3","v4","v5","v6","v7");
        n-=vl;src+=vl;dst+=vl;
    }
#else
    memcpy(dst,src,n);
#endif
}
static void model_fence(void){
    if(yolo32_independent_enabled)yolo32_independent_wait();
    else drain(gemmini_pool_active_worker);
}
#define gemmini_fence() model_fence()
#include "memory_kernels_runtime.inc"
void console_puts(const char *s){fputs(s,stdout);}
void console_putc(int c){fputc(c,stdout);}
void console_put_hex64(uint64_t n){printf("0x%016llX",(unsigned long long)n);}
void yolo32_set_analysis(unsigned enabled){analysis_enabled=enabled;memset(memory_stats,0,sizeof(memory_stats));}
#include "memory_selftest.inc"
/* Real context switch adapter inserted by test builder. */
#include "memory_switch.inc"
/* Exercise all real shapes, chaining three pool outputs, with one arena per
 * worker and deliberate private-buffer contents. */
static elem_t input[3][30*40*128],output[3][60*80*128+64];
static void check_output(unsigned w,int resize,unsigned h,unsigned width,unsigned c){
    unsigned oh=h*(resize?2:1),ow=width*(resize?2:1);
    for(unsigned y=0;y<oh;y++)for(unsigned x=0;x<ow;x++)for(unsigned ch=0;ch<c;ch++){
        int v=-128;
        if(resize)v=input[w][((size_t)(y/2)*width+x/2)*c+ch];
        else for(int ky=-2;ky<=2;ky++)for(int kx=-2;kx<=2;kx++){
            int iy=(int)y+ky,ix=(int)x+kx;
            if(iy>=0&&ix>=0&&iy<(int)h&&ix<(int)width){
                int q=input[w][((size_t)iy*width+ix)*c+ch];if(q>v)v=q;
            }
        }
        assert(output[w][((size_t)y*ow+x)*c+ch]==v);
    }
    size_t size=(size_t)oh*ow*c;
    for(unsigned i=0;i<64;i++)assert(output[w][size+i]==85);
}
int yolo32_graph_poll(unsigned w,Yolo32Result *r){
    (void)r;assert(gemmini_pool_active_worker==w);
    if(stage[w]==14){
        yolo32_independent_wait();
        assert(yolo32_independent_try_reuse_wait(14));
        memory_load(input[w],1U<<31,1,1);
        assert(!yolo32_independent_try_reuse_wait(14)); /* Same Conv/WS counts! */
        yolo32_independent_wait();
        assert(!hw[w].queued&&accumulator[w][0][0]==input[w][0]);
        stage[w]=75;
    }else if(stage[w]>=75&&stage[w]<=77){
        memset(output[w],85,38400+64);
        yolo32_memory_pool5(input[w],output[w],15,20,128);
        assert(!hw[w].queued);check_output(w,0,15,20,128);
        memcpy(input[w],output[w],38400);
        if(++stage[w]==78)stage[w]=83;
    }else if(stage[w]==83||stage[w]==97){
        unsigned h=stage[w]==83?15:30,width=stage[w]==83?20:40,c=stage[w]==83?128:64;
        for(unsigned i=0;i<h*width*c;i++)input[w][i]=(i*37+i/c*13+w*29)%256-128;
        memset(output[w],85,4*h*width*c+64);
        yolo32_memory_resize2(input[w],output[w],h,width,c);
        assert(!hw[w].queued);check_output(w,1,h,width,c);
        stage[w]=stage[w]==83?97:165;
    }else{
        assert(stage[w]==165);yolo32_independent_wait();heads[w]=63;stage[w]=167;
        return YOLOV5NU_DIM16_HEAD_READY;
    }
    return YOLOV5NU_DIM16_RUNNING;
}
int main(void){
    /* Actual board test implementation and actual operand encoding. */
    yolo32_memory_test();
    if(getenv("SMOKE_ONLY"))return 0;
    /* ACC capacity, partial channel blocks, final short batches, and output
     * chunk tails. Scalar oracle is separate from inference postprocessing. */
    const unsigned extra[][3]={{1,1,1},{1,40,33},{13,40,65},
                               {30,40,65},{30,40,128},{30,1,128}};
    for(unsigned w=0;w<3;w++)for(unsigned j=0;j<sizeof(extra)/sizeof(extra[0]);j++){
        unsigned h=extra[j][0],width=extra[j][1],c=extra[j][2];
        gemmini_pool_active_worker=w;
        for(unsigned i=0;i<h*width*c;i++)input[w][i]=(i*37+i/c*13+w*29)%256-128;
        memset(output[w],85,4*h*width*c+64);
        yolo32_memory_resize2(input[w],output[w],h,width,c);
        assert(!hw[w].queued);check_output(w,1,h,width,c);
    }
    for(unsigned repeat=0;repeat<2;repeat++){
        tick=0;peer_progress=0;memset(hw,0,sizeof(hw));memset(seen_commands,0,sizeof(seen_commands));
        memset(heads,0,sizeof(heads));memset(memory_stats,0,sizeof(memory_stats));
        memset(memory_dirty_calls,0,sizeof(memory_dirty_calls));
        analysis_enabled=repeat==0;
        for(unsigned w=0;w<3;w++){
            stage[w]=14;
            memset(memory_pad[w],w*31,sizeof(memory_pad[w]));
            memset(memory_intermediate[w],w*41,sizeof(memory_intermediate[w]));
            for(unsigned i=0;i<38400;i++)input[w][i]=(i*17+i/128+w*23)%127-128;
        }
#ifndef __riscv
        memset(contexts,0,sizeof(contexts));contexts_used=0;
#endif
        yolo32_independent_begin(repeat==0);
        while(!yolo32_independent_step()){}
        yolo32_independent_end();
        const Yolo32IndependentStats *s=yolo32_independent_stats();
        assert(peer_progress>0&&s->done_mask==7);
        for(unsigned w=0;w<3;w++){
            const Yolo32MemoryStats *m=yolo32_memory_stats(w);
            assert(m->pool_calls==3&&m->resize_calls==2&&m->mvin==1945&&m->mvout==624&&m->waits==YOLO32_MEMORY_WAITS);
            assert(seen_commands[w][2]==1945&&seen_commands[w][3]==624&&seen_commands[w][0]==(YOLO32_RESIZE_BATCH?17:16));
            assert(memory_dirty_calls[w]==(YOLO32_RESIZE_BATCH?169+YOLO32_MEMORY_WAITS-24:2569));
            assert(s->conv_requests[w]==0&&s->matmul_requests[w]==0&&!hw[w].queued);
        }
        assert(s->wait_yields==3*(YOLO32_MEMORY_WAITS+3));
    }
    puts("PASS: private arenas; real FP16 operands; chained pool; resize; guards; delayed DMA; stale completion invalidation; peer progress; restart");
    return 0;
}
