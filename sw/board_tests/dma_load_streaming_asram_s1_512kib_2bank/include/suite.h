#ifndef ASRAM_BOARD_SUITE_H
#define ASRAM_BOARD_SUITE_H
#include <stddef.h>
#include <stdint.h>
#include "activation_sram_map.h"
#include "build_config.h"

enum { DIM=32, DEST=64, MAX_SOURCE=2048, MAX_OUTPUT=1120,
       COUNTERS=20, TIMEOUT=200000000 };
typedef struct { unsigned cols, rows, pixels, stride, offset; } TestShape;
extern const TestShape shapes[3];
uint64_t pattern_word(unsigned lane, size_t offset, unsigned pass);
uint8_t source_byte(unsigned lane, unsigned row, unsigned col);
size_t source_size(const TestShape *s);
size_t output_size(const TestShape *s);
void fill_source(uint8_t *p, const TestShape *s, unsigned lane);
void reference_output(uint8_t *p, const TestShape *s, unsigned lane);

void hw_init(void);
uint64_t hw_cycle(void);
void hw_text(const char *s);
void hw_publish(void);
volatile uint8_t *hw_bank(unsigned lane);
void hw_check_identity(void);
uint64_t hw_probe_hole(unsigned lane, unsigned slot, unsigned write);
void hw_rvv_copy(void *dst, const void *src, size_t bytes);
void hw_select(unsigned lane, unsigned mode);
void hw_poison(unsigned lane, const uint8_t *poison, unsigned rows, unsigned pixels);
void hw_submit(unsigned lane, const TestShape *s, const uint8_t *source);
void hw_complete(unsigned lane);
void hw_store(unsigned lane, const TestShape *s, uint8_t *output);
void hw_clear(void);
void hw_snapshot(unsigned lane, uint64_t values[2][COUNTERS]);
uint64_t hw_trap_count(void);
void text_number(uint64_t value);
void field(const char *name, uint64_t value);
void fail(const char *reason, uint64_t address, uint64_t expected, uint64_t actual)
    __attribute__((noreturn));
#endif
