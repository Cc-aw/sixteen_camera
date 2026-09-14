/* I: CPU/DMA shared NHWC buffers and integer references.
 * P: N6 capacity guards, cache ownership transfer, exact output comparison.
 * O: coherent buffers and a checked result. A: 王志瑞. T: 2026-09-10. */
#ifndef YOLOV5NU_N6_RUNTIME_H
#define YOLOV5NU_N6_RUNTIME_H
#include "gemmini-myboard-uart.h"
#ifndef N6_VERBOSE_UART
#define N6_VERBOSE_UART 0
#endif
#if DIM != 64 || BANK_NUM != 8 || BANK_ROWS != 1024 || ACC_ROWS != 2048
#error "This port requires the frozen Gemmini64 Scale32 N6 geometry"
#endif
/* I: ordered accelerator scopes and cache ranges. P: buffer timestamps only.
 * O: per-call attribution after inference; no UART in timed scopes.
 * A: 王志瑞. T: 2026-09-10. */
static uint64_t n6_cache_cycles, n6_cache_bytes, n6_wait_cycles;
struct n6_scope { const char *name; uint64_t start, total, cache0, cache, wait0, wait; };
static struct n6_scope n6_scopes[128];
static unsigned n6_scope_count, n6_scope_active, n6_trace_overflow;
struct n6_flush_record { uintptr_t base; size_t bytes; uint64_t cycles; unsigned scope, phase; };
static struct n6_flush_record n6_flush_records[512];
static unsigned n6_flush_count, n6_flush_phase;
static inline uint64_t n6_cycles(void) {
  uint64_t c; __asm__ volatile("rdcycle %0" : "=r"(c)); return c;
}
static void n6_wait(void) {
  uint64_t start=n6_cycles(), busy;
  do { __asm__ volatile("csrr %0, 0x7c2" : "=r"(busy) :: "memory"); } while (busy & 1);
  __asm__ volatile("fence rw,rw" ::: "memory");
  n6_wait_cycles+=n6_cycles()-start;
}
/* I: completion boundary. P: drain RoCC before changing LUT/load scale.
 * O: safe next configuration. A: 王志瑞. T: 2026-09-10. */
#undef gemmini_fence
#define gemmini_fence() n6_wait()
static void n6_flush(const void *base, size_t bytes) {
  if (!bytes) return;
  uint64_t start=n6_cycles();
  uintptr_t a=(uintptr_t)base & ~(uintptr_t)63;
  uintptr_t end=((uintptr_t)base+bytes+63) & ~(uintptr_t)63;
  n6_cache_bytes+=end-a;
  for (;a<end;a+=64) {
    __asm__ volatile("fence rw,rw" ::: "memory");
    *(volatile uint64_t *)0x02010200UL=a;
    __asm__ volatile("fence rw,rw" ::: "memory");
  }
  uint64_t elapsed=n6_cycles()-start;
  n6_cache_cycles+=elapsed;
  if (n6_flush_count<512) n6_flush_records[n6_flush_count++]=(struct n6_flush_record){
    (uintptr_t)base & ~(uintptr_t)63, end-((uintptr_t)base & ~(uintptr_t)63),
    elapsed, n6_scope_active ? n6_scope_count : 128, n6_flush_phase};
  else n6_trace_overflow++;
} 
/* I: accelerator group boundaries. P: measure inclusive wall time and nested
 * cache/wait deltas. O: attributable group totals. A: 王志瑞. T: 2026-09-10. */
static void n6_scope_begin(const char *name) {
  if(n6_scope_count>=128) {n6_trace_overflow++;return;}
  struct n6_scope *r=&n6_scopes[n6_scope_count];
  r->name=name; r->cache0=n6_cache_cycles; r->wait0=n6_wait_cycles;
  n6_flush_phase=0; n6_scope_active=1; r->start=n6_cycles();
}
static void n6_scope_end(void) {
  if(!n6_scope_active) return;
  struct n6_scope *r=&n6_scopes[n6_scope_count++];
  r->total=n6_cycles()-r->start;
  r->cache=n6_cache_cycles-r->cache0; r->wait=n6_wait_cycles-r->wait0;
  n6_scope_active=0;
}
/* I: per-operation event counters. P: sample after draining; print after graph.
 * O: overlapping DMA/execute event counts, not physical PE utilization.
 * A: 王志瑞. T: 2026-09-10. */
/* I: eight hardware event slots. P: select memory-path diagnostics.
 * O: named overlapping events; not DDR-only latency. A: 王志瑞. T: 2026-09-10. */
/* I: optional profiling RTL. P: select ABI at build time; legacy software stays compatible.
 * O: extra measurements only in the profiling build. A: 王志瑞. T: 2026-09-11. */
#ifdef N6_DMA_PROFILE
#include "n6_dma_profile.h"
#endif
static const unsigned n6_events[8] = {LOAD_SCRATCHPAD_WAIT_CYCLE,
  STORE_SCRATCHPAD_WAIT_CYCLE, EXE_ACTIVE_CYCLE, RDMA_ACTIVE_CYCLE,
  WDMA_ACTIVE_CYCLE, RDMA_TL_WAIT_CYCLES, RDMA_TLB_WAIT_CYCLES, WDMA_TL_WAIT_CYCLES};
static const unsigned n6_external_events[4] = {RDMA_BYTES_REC, WDMA_BYTES_SENT,
  RDMA_TOTAL_LATENCY, WDMA_TOTAL_LATENCY};
struct n6_record {
#ifdef N6_DMA_PROFILE
  uint64_t dma_profile[2][N6_DMA_PROFILE_REGS];
#endif
const char *name; uint64_t cycles; uint32_t counts[8]; uint32_t external[4]; uint32_t accepted, retired; uint64_t calls, waits, credit_cycles;};
static struct n6_record n6_records[128];
static unsigned n6_record_count;
static uint64_t n6_start;
static uint64_t n6_calls0, n6_waits0, n6_credit0;
static uint32_t n6_accepted0, n6_retired0;
static const char *n6_pending_label;
static void n6_begin(const char *label) {
#ifdef N6_DMA_PROFILE
  n6_dma_profile_probe();
#endif
  if (n6_record_count>=128) {printf("FAIL: N6 profile capacity\n");exit(1);}
  n6_records[n6_record_count].name=label;
  for (unsigned i=0;i<8;i++) counter_configure(i,n6_events[i]);
  counter_reset();
  /* I: drained group boundary. P: snapshot unsigned counters.
   * O: wrap-safe per-group deltas. A: 王志瑞. T: 2026-09-10. */
  n6_calls0=n6_credit_calls; n6_waits0=n6_credit_waits; n6_credit0=n6_credit_cycles;
  n6_accepted0=gemmini_loopconv_accepted_count_read();
  n6_retired0=gemmini_loopconv_retired_count_read();
  n6_start=n6_cycles();
}
static void n6_end(void) {
  struct n6_record *r=&n6_records[n6_record_count++];
  r->cycles=n6_cycles()-n6_start;
  for (unsigned i=0;i<8;i++) r->counts[i]=counter_read(i);
  /* I: drained DMA and saved regular events. P: remap slots without reset;
   * external accumulators already ran throughout this group.
   * O: raw bytes and occupancy integrals. A: 王志瑞. T: 2026-09-10. */
  for (unsigned i=0;i<4;i++) {
    counter_configure(i,n6_external_events[i]);
    r->external[i]=counter_read(i);
  }
  r->calls=n6_credit_calls-n6_calls0; r->waits=n6_credit_waits-n6_waits0;
  r->credit_cycles=n6_credit_cycles-n6_credit0;
  r->accepted=gemmini_loopconv_accepted_count_read()-n6_accepted0;
  r->retired=gemmini_loopconv_retired_count_read()-n6_retired0;
#ifdef N6_DMA_PROFILE
  n6_dma_profile_capture(r->dma_profile);
#endif
  n6_flush_phase=1;
}
static void n6_print_memory(void) {
  if (!N6_VERBOSE_UART) return;
  for (unsigned i=0;i<n6_record_count;i++) {
    const struct n6_record *r=&n6_records[i];
#ifdef N6_DMA_PROFILE
    n6_dma_profile_print(i,r->name,r->dma_profile);
#endif
    printf("N6_MEMORY op=%s cycles=%lu load_req_backpressure=%u store_req_backpressure=%u exe_active=%u rdma_active=%u wdma_active=%u rdma_tl_wait=%u rdma_tlb_wait=%u wdma_tl_wait=%u\n",
      r->name,(unsigned long)r->cycles,r->counts[0],r->counts[1],r->counts[2],
      r->counts[3],r->counts[4],r->counts[5],r->counts[6],r->counts[7]);
    printf("N6_DMA id=%u op=%s rdma_bytes_raw=%u wdma_transaction_bytes=%u rdma_occupancy_cycles=%u wdma_occupancy_cycles=%u rdma_multibeat_overcount=1 ddr_bytes_measured=0\n",
      i,r->name,r->external[0],r->external[1],r->external[2],r->external[3]);
    printf("N6_CREDIT id=%u op=%s calls=%lu waited_calls=%lu wait_cycles=%lu accepted=%u retired=%u\n",
      i,r->name,(unsigned long)r->calls,(unsigned long)r->waits,
      (unsigned long)r->credit_cycles,r->accepted,r->retired);
  }
}
/* I: completed trace buffers. P: emit inclusive scopes and individual flushes.
 * O: auditable timeline with overflow status. A: 王志瑞. T: 2026-09-10. */
static void n6_print_timing(void) {
  uint64_t total=0, cache=0, wait=0;
  for(unsigned i=0;i<n6_scope_count;i++) {
    const struct n6_scope *r=&n6_scopes[i];
    total+=r->total; cache+=r->cache; wait+=r->wait;
    printf("N6_SCOPE id=%u op=%s total_cycles=%lu cache_cycles=%lu wait_cycles=%lu other_cycles=%lu\n",
      i,r->name,(unsigned long)r->total,(unsigned long)r->cache,
      (unsigned long)r->wait,(unsigned long)(r->total-r->cache-r->wait));
  }
  for(unsigned i=0;i<n6_flush_count;i++) {
    const struct n6_flush_record *r=&n6_flush_records[i];
    printf("N6_FLUSH id=%u scope=%u phase=%u address=0x%lx bytes=%lu cycles=%lu\n",
      i,r->scope,r->phase,(unsigned long)r->base,(unsigned long)r->bytes,(unsigned long)r->cycles);
  }
  printf("N6_TIMING scopes=%u flushes=%u overflow=%u scope_cycles=%lu cache_cycles=%lu wait_cycles=%lu\n",
    n6_scope_count,n6_flush_count,n6_trace_overflow,(unsigned long)total,
    (unsigned long)cache,(unsigned long)wait);
}
/* Each A partition shares half the scratchpad with B. Reserve B before I.
 * The accumulator independently reserves half for each loop context. */
static size_t n6_tile_i(size_t j, size_t k) {
  const size_t half_spad=BANK_NUM*BANK_ROWS/2;
  const size_t b_rows=k*j*DIM;
  if (!j || !k || b_rows>=half_spad) return 0;
  size_t acc_i=(ACC_ROWS/2)/(j*DIM);
  size_t spad_i=(half_spad-b_rows)/(k*DIM);
  return acc_i<spad_i ? acc_i : spad_i;
}
static size_t n6_multi_tile_i(size_t j, const int *channels, int count) {
  size_t k=0;
  for (int q=0;q<count;++q) {
    size_t blocks=(channels[q]+DIM-1)/DIM;
    if (blocks>k) k=blocks;
  }
  return n6_tile_i(j,k);
}
extern const int8_t n6_ref_class_logits[], n6_ref_class_scores[], n6_ref_dfl[];
extern const uint8_t n6_ref_mask[];
/* I: location-major heads, class-major references and sparse mask. P: compare every valid byte
 * and mask against independent hardware integer reference. O: PASS/FAIL.
 * A: 王志瑞. T: 2026-09-10. */
static int n6_check_heads(const elem_t *logits, const elem_t *scores,
                         const elem_t *dfl, const uint8_t *mask) {
  size_t le=0,se=0,de=0,me=0;
  for (size_t p=0;p<6300;++p) for (size_t c=0;c<80;++c) {
    le+=logits[p*80+c]!=n6_ref_class_logits[c*6300+p];
    se+=scores[p*80+c]!=n6_ref_class_scores[c*6300+p];
  }
  for (size_t p=0;p<6300;++p) {
    me+=(mask[p]!=0)!=(n6_ref_mask[p]!=0);
    if (n6_ref_mask[p]) for (size_t e=0;e<4;++e)
      de+=dfl[p*4+e]!=n6_ref_dfl[e*6300+p];
  }
  printf("N6_CHECK class_logits_mismatches=%lu class_scores_mismatches=%lu sparse_dfl_mismatches=%lu mask_mismatches=%lu\n",
    (unsigned long)le,(unsigned long)se,(unsigned long)de,(unsigned long)me);
  return !(le||se||de||me);
}
#endif
