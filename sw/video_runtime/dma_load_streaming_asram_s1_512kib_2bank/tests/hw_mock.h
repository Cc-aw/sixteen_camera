#ifndef S1_HW_MOCK_H
#define S1_HW_MOCK_H
#include "gemmini_frontend.h"
uint64_t gf_status(unsigned);
uint64_t gf_read(unsigned,uint64_t,uint64_t);
unsigned gf_pending(void);
void gf_publish(void);
uint64_t gf_launch(unsigned,const GfCommand *,uint32_t,uintptr_t,uint32_t,int);
uint64_t gf_resume(unsigned,uint64_t,uint64_t);
uint64_t gf_ack(unsigned,uint64_t,uint64_t);
uint32_t mmio_read32(uintptr_t);
void mmio_write32(uintptr_t,uint32_t);
#endif
