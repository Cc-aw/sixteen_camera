#ifndef DMA_SPAD_MICRO_H
#define DMA_SPAD_MICRO_H

#include <stddef.h>
#include <stdint.h>

enum { MICRO_DIM=32, MICRO_DEST=64, MICRO_POISON=0xa5 };
typedef struct {
    unsigned cols, rows, pixels, stride, offset, ops;
    uint16_t scale;
} MicroCase;
typedef struct {
    uint32_t get32, get64, returned, writes, groups, assembled, rows, bytes;
    unsigned merge, assembly;
} MicroTraffic;

static inline unsigned micro_output_bytes(const MicroCase *c)
{
    return (c->rows+c->pixels+1)*MICRO_DIM;
}
static inline unsigned micro_source_bytes(const MicroCase *c)
{
    return c->offset+(c->rows-1)*c->stride+c->cols;
}
static inline uint64_t micro_shape(unsigned rows,unsigned cols,unsigned address)
{
    return ((uint64_t)rows<<48)|((uint64_t)cols<<32)|address;
}
static inline uint64_t micro_load_config(uint16_t scale,unsigned pixels)
{
    return ((uint64_t)scale<<32)|(UINT64_C(32)<<16)|((uint64_t)pixels<<8)|1;
}
void micro_fill_source(uint8_t *source,const MicroCase *c);
void micro_reference(const uint8_t *source,uint8_t *gold,const MicroCase *c);
MicroTraffic micro_predict(const MicroCase *c,unsigned mode);

void hw_init(void);
uint64_t hw_cycle(void);
uint64_t hw_identity(void);
uint32_t hw_capability(void);
void hw_select(unsigned mode);
void hw_prepare(const MicroCase *c,const uint8_t *poison);
void hw_load(const MicroCase *c,const uint8_t *source);
void hw_wait(void);
void hw_dump(const MicroCase *c,uint8_t *output);
void hw_counter_reset(void);
void hw_counters(uint32_t values[35]);
void hw_text(const char *text);
void micro_fail(const char *reason,uint64_t value) __attribute__((noreturn));

#endif
