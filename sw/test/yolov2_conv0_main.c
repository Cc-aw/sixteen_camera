#include <stdint.h>
#include <stdio.h>

#include "gemmini-myboard-uart.h"
#include "include/gemmini.h"
#include "include/gemmini_nn.h"
#include "tinyyolov2_params.h"

/* The current board is non-coherent for Gemmini DMA. */
extern void gemcc_myboard_l1_evict(void);

#define CONV0_INPUT_ELEMS (TINYYOLOV2_INPUT_H * TINYYOLOV2_INPUT_W * TINYYOLOV2_INPUT_C)
#define CONV0_OUTPUT_ELEMS (208 * 208 * 16)

/* Keep the DMA operands on cache-line boundaries. */
static elem_t conv0_input[CONV0_INPUT_ELEMS] __attribute__((aligned(64)));
static elem_t conv0_weights[27][16] __attribute__((aligned(64)));
static acc_t conv0_bias[16] __attribute__((aligned(64)));
static elem_t conv0_output[CONV0_OUTPUT_ELEMS] __attribute__((aligned(64)));

static inline uint64_t conv0_read_cycles(void)
{
  uint64_t value;
  __asm__ volatile("rdcycle %0" : "=r"(value));
  return value;
}

static void print_hex(uint64_t value)
{
  static const char digits[] = "0123456789ABCDEF";
  char text[17];
  for (int i = 15; i >= 0; --i) {
    text[i] = digits[value & 0xfu];
    value >>= 4;
  }
  text[16] = '\0';
  printf("0x%s", text);
}

static int64_t output_checksum(void)
{
  int64_t checksum = 0;
  for (int i = 0; i < CONV0_OUTPUT_ELEMS; ++i)
    checksum += conv0_output[i];
  return checksum;
}

static void output_stats(int *nonzero, int *minimum, int *maximum)
{
  int nz = 0;
  int lo = 127;
  int hi = -128;
  for (int i = 0; i < CONV0_OUTPUT_ELEMS; ++i) {
    int value = conv0_output[i];
    nz += value != 0;
    if (value < lo) lo = value;
    if (value > hi) hi = value;
  }
  *nonzero = nz;
  *minimum = lo;
  *maximum = hi;
}

void runtime_trap(uint64_t cause, uint64_t epc, uint64_t value)
{
  printf("CONV0 TRAP cause=");
  print_hex(cause);
  printf(" epc=");
  print_hex(epc);
  printf(" mtval=");
  print_hex(value);
  printf("\n");
  for (;;) __asm__ volatile("wfi");
}

int main(void)
{
  uart_init();
  printf("YOLOV2 CONV0 TEST\n");
  printf("CONFIG DIM=%d BANK_ROWS=%d ACC_ROWS=%d MAX_BYTES=%d\n",
         DIM, BANK_ROWS, ACC_ROWS, MAX_BYTES);
  printf("SHAPE input=1x%dx%dx%d conv=3x3x%d pool=2/2 output=208x208x16\n",
         TINYYOLOV2_INPUT_H, TINYYOLOV2_INPUT_W, TINYYOLOV2_INPUT_C,
         tinyyolov2_conv0_params.out_channels);

  printf("COPY INPUT BEGIN\n");
  for (int i = 0; i < CONV0_INPUT_ELEMS; ++i)
    conv0_input[i] = tinyyolov2_image_input[i];
  for (int i = 0; i < 27 * 16; ++i)
    ((elem_t *)conv0_weights)[i] = ((const elem_t *)tinyyolov2_conv0_w)[i];
  for (int i = 0; i < 16; ++i)
    conv0_bias[i] = tinyyolov2_conv0_b[i];
  gemcc_myboard_l1_evict();
  __asm__ volatile("fence rw, rw" ::: "memory");
  printf("COPY INPUT DONE input=");
  print_hex((uintptr_t)conv0_input);
  printf(" weights=");
  print_hex((uintptr_t)conv0_weights);
  printf(" output=");
  print_hex((uintptr_t)conv0_output);
  printf("\n");

  printf("GEMMINI FLUSH BEGIN\n");
  gemmini_flush(0);
  printf("GEMMINI FLUSH DONE\n");
  printf("CONV0 LAUNCH BEGIN\n");
  uint64_t start = conv0_read_cycles();
  const struct ConvParams *p = &tinyyolov2_conv0_params;
  tiled_conv_auto(
      p->batch_size, p->in_row_dim, p->in_col_dim, p->in_channels,
      p->out_channels, p->out_row_dim, p->out_col_dim,
      p->stride, 1, 1, p->padding, p->kernel_size,
      false, false, false, false, false,
      conv0_input, (const elem_t *)conv0_weights, conv0_bias, conv0_output,
      TINYYOLOV2_HIDDEN_ACT, p->output_scale,
      p->pool_size, p->pool_stride, p->pool_padding,
      WS);
  printf("CONV0 COMMANDS RETURNED cycles=");
  printf("%lu\n", (unsigned long)(conv0_read_cycles() - start));
  printf("CONV0 FENCE BEGIN\n");
  gemmini_fence();
  __asm__ volatile("fence rw, rw" ::: "memory");
  gemcc_myboard_l1_evict();
  uint64_t cycles = conv0_read_cycles() - start;
  printf("CONV0 FENCE DONE cycles=%lu\n", (unsigned long)cycles);

  int nonzero;
  int minimum;
  int maximum;
  output_stats(&nonzero, &minimum, &maximum);
  printf("OUTPUT checksum=%ld nonzero=%d min=%d max=%d\n",
         (long)output_checksum(), nonzero, minimum, maximum);
  printf("RESULT: CONV0 RETURNED\n");
  for (;;) __asm__ volatile("wfi");
}
