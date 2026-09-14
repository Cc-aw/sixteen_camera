#ifndef N6_DMA_PROFILE_H
#define N6_DMA_PROFILE_H
/* I: N6 profiling RTL ABI v1. P: read independent 64-bit counters after DMA drain.
 * O: per-layer request histograms and TL statistics; no UART inside normal inference.
 * A: 王志瑞. T: 2026-09-11. */
#define N6_DMA_PROFILE_REGS 35
static uint64_t n6_dma_profile_read(unsigned write, unsigned index) {
  uint64_t config=(UINT64_C(1)<<63)|((uint64_t)((write<<7)|index)<<16);
  uint64_t result;
  ROCC_INSTRUCTION(XCUSTOM_ACC,result,config,0,k_COUNTER);
  return result;
}
static void n6_dma_profile_probe(void) {
  static int checked;
  if(checked) return;
  for(unsigned w=0;w<2;w++) {
    if(n6_dma_profile_read(w,0)!=(UINT64_C(0x4e36505200010000)|w)) {
      printf("RESULT: FAIL - N6 DMA profiling ABI missing; load profiling bitstream\n");
      exit(1);
    }
  }
  checked=1;
}
static void n6_dma_profile_capture(uint64_t values[2][N6_DMA_PROFILE_REGS]) {
  for(unsigned w=0;w<2;w++)
    for(unsigned j=0;j<N6_DMA_PROFILE_REGS;j++) values[w][j]=n6_dma_profile_read(w,j);
}
static void n6_dma_profile_print(unsigned id, const char *op,
                               const uint64_t values[2][N6_DMA_PROFILE_REGS]) {
  for(unsigned w=0;w<2;w++) {
    printf("N6_DMA_PROFILE id=%u op=%s direction=%s abi=1 ddr_bytes_measured=0",
           id,op,w?"write":"read");
    for(unsigned j=0;j<N6_DMA_PROFILE_REGS;j++)
      printf(" c%u=%lu",j,(unsigned long)values[w][j]);
    printf("\n");
  }
}
#endif
