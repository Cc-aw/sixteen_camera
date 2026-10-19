#ifndef GEMMINI_FRONTEND_H
#define GEMMINI_FRONTEND_H
#include <stdint.h>
#include <stddef.h>

/* Table ABI retained from v4; control ABI v2 uses custom3 and a lane ID. */
typedef struct __attribute__((aligned(32))) {
    uint64_t control, rs1, rs2, reserved;
} GfCommand;
_Static_assert(sizeof(GfCommand)==32,"command table ABI");
enum { GF_RAW=0, GF_DRAIN=1, GF_HOST=2 };
enum { GF_REL_RS1=1u<<16, GF_REL_RS2=1u<<17 };
enum { GF_OWNED=1, GF_DONE=2, GF_HOST_WAIT=4, GF_FAULT=8,
       GF_START_READY=16, GF_GEMMINI_BUSY=32, GF_FENCE_BUSY=64, GF_ARMED=128 };
static inline GfCommand gf_raw(unsigned f,uint64_t a,uint64_t b,unsigned reloc) {
    return (GfCommand){((uint64_t)f<<8)|reloc,a,b,0};
}
static inline GfCommand gf_drain(void) {return (GfCommand){GF_DRAIN,0,0,0};}
static inline GfCommand gf_host(uint64_t tag) {return (GfCommand){GF_HOST,tag,0,0};}
#ifdef __riscv
#define GF_INSN(f,a,b,out) __asm__ volatile(".insn r 0x7b, 7, %3, %0, %1, %2" \
    : "=&r"(out) : "r"(a),"r"(b),"i"(f) : "memory")
#define GF_CONTROL(name,op) \
static inline uint64_t name(unsigned lane,uint64_t a,uint64_t b) { \
    uint64_t out; switch(lane) { \
    case 0:GF_INSN(op,a,b,out);break; \
    case 1:GF_INSN(32+op,a,b,out);break; \
    case 2:GF_INSN(64+op,a,b,out);break; \
    default:return UINT64_MAX; } return out; \
}
GF_CONTROL(gf_set_table,0)
GF_CONTROL(gf_set_frame,1)
GF_CONTROL(gf_start,2)
GF_CONTROL(gf_read,3)
GF_CONTROL(gf_resume,4)
GF_CONTROL(gf_ack,5)
GF_CONTROL(gf_set_release,6)
GF_CONTROL(gf_arm,7)
GF_CONTROL(gf_cancel,8)
GF_CONTROL(gf_set_dma_load_mode,9)
#undef GF_CONTROL
static inline uint64_t gf_global_read(unsigned query) {
    uint64_t out;GF_INSN(99,(uint64_t)query,0,out);return out;
}
static inline uint64_t gf_arm_mask(unsigned lanes,unsigned irqs) {
    uint64_t out;GF_INSN(103,(uint64_t)lanes,(uint64_t)irqs,out);return out;
}
#undef GF_INSN
static inline uint64_t gf_status(unsigned lane) {return gf_read(lane,0,0);}
static inline unsigned gf_pending(void) {return gf_global_read(0)&7;}
/* Orders CPU/RVV stores. Autonomous completion requires lane DONE/HOST.
 * Unrelated autonomous lanes are intentionally excluded from CPU fence busy. */
static inline void gf_publish(void) {__asm__ volatile("fence rw,rw":::"memory");}
static inline uint64_t gf_prepare(unsigned lane,const GfCommand *table,uint32_t count,
                                  uintptr_t frame,uint32_t timeout) {
    gf_publish();
    uint64_t rc=gf_set_table(lane,(uintptr_t)table,count);
    return rc ? rc : gf_set_frame(lane,frame,timeout);
}
static inline uint64_t gf_launch(unsigned lane,const GfCommand *table,uint32_t count,
                                 uintptr_t frame,uint32_t timeout,int irq) {
    uint64_t rc=gf_prepare(lane,table,count,frame,timeout);
    return rc ? rc : gf_start(lane,irq!=0,0);
}
/* Direct routes are available ONLY while that lane is unowned. A direct
 * command aimed at an owned lane can backpressure the shared RoCC queue. */
#define GF_DIRECT_ONE(op,f,a,b) __asm__ volatile(".insn r " op ", 3, %2, x0, %0, %1" \
    ::"r"(a),"r"(b),"i"(f):"memory")
#define GF_DIRECT(lane,f,a,b) do { \
    switch(lane) { \
    case 0:GF_DIRECT_ONE("0x0b",f,a,b);break; \
    case 1:GF_DIRECT_ONE("0x2b",f,a,b);break; \
    case 2:GF_DIRECT_ONE("0x5b",f,a,b);break; \
    } \
} while(0)
#endif
#endif
