#ifndef VIDEO_CTRL_MMIO_H
#define VIDEO_CTRL_MMIO_H
#include <stdint.h>
#include <stddef.h>
static inline void mmio_write32(uintptr_t a,uint32_t v){*(volatile uint32_t *)a=v;}
static inline uint32_t mmio_read32(uintptr_t a){return *(volatile const uint32_t *)a;}
static inline void mmio_fence(void){
#ifdef YOLO32_PPU_ORDERED_MMIO
 extern void at_io_commit(void);at_io_commit();
#else
 __asm__ volatile("fence iorw,iorw":::"memory");
#endif
}
static inline void cpu_wfi(void){__asm__ volatile("wfi");}
#ifndef read_cycle
static inline uint64_t read_cycle(void){uint64_t c;__asm__ volatile("rdcycle %0":"=r"(c));return c;}
#endif
#endif
