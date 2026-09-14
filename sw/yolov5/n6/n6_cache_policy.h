/* I: aligned arena cache-line addresses. P: track lines evicted since last CPU
 * arena operation; DMA does not allocate CPU cache lines. O: redundant flush
 * elimination. A: 王志瑞. T: 2026-09-10. */
#ifndef N6_CACHE_POLICY_H
#define N6_CACHE_POLICY_H
#include <stdint.h>
#include <stddef.h>
#include <string.h>
static uintptr_t n6_arena_start,n6_arena_end;
static uint8_t n6_clean_lines[5000];
static void n6_cache_forget(void) {memset(n6_clean_lines,0,sizeof(n6_clean_lines));}
static void n6_cache_init(void *base,size_t bytes) {
  n6_arena_start=(uintptr_t)base;n6_arena_end=n6_arena_start+bytes;
  if ((n6_arena_start&63)||bytes>sizeof(n6_clean_lines)*8*64) {
    n6_arena_start=n6_arena_end=0; /* Unknown geometry: retain all flushes. */
  }
  n6_cache_forget();
}
static int n6_cache_need_line(uintptr_t a) {
  if(a<n6_arena_start || a+64>n6_arena_end)return 1;
  size_t line=(a-n6_arena_start)/64;uint8_t bit=1u<<(line&7);
  if(n6_clean_lines[line>>3]&bit)return 0;
  n6_clean_lines[line>>3]|=bit;return 1;
}
#endif
