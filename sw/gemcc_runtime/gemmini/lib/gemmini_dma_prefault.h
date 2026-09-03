#ifndef GEMMINI_DMA_PREFAULT_H
#define GEMMINI_DMA_PREFAULT_H

#include <stddef.h>
#include <stdint.h>

#ifndef GEMCC_PAGE_SIZE
#define GEMCC_PAGE_SIZE 4096u
#endif

/* I: Gemmini DMA 目的范围
 * P: 每页 store 一个字节，使 Spike/pk 的 CoW 目的页在首次 mvout 前常驻；
 *    不整块清零，memref.alloc payload 保持未初始化语义
 * O: 目的范围的每个页已建立可写映射
 * A: shiroha_suki
 * T: 2026-08-29
 */
static inline void gemmini_dma_prefault(void *ptr, size_t nbytes) {
  if (!ptr || nbytes == 0)
    return;
  volatile uint8_t *p = (volatile uint8_t *)ptr;
  for (size_t off = 0; off < nbytes; off += GEMCC_PAGE_SIZE)
    p[off] = p[off];
  p[nbytes - 1] = p[nbytes - 1];
}

/* I: Gemmini DMA 源范围
 * P: 每页 load 一个字节，使 Spike/pk 文件/.rodata 页在首次 mvin 前常驻
 * O: 源范围的每个页已建立只读映射，内容不变
 * A: shiroha_suki
 * T: 2026-08-29
 */
static inline void gemmini_dma_touch(const void *ptr, size_t nbytes) {
  if (!ptr || nbytes == 0)
    return;
  const volatile uint8_t *p = (const volatile uint8_t *)ptr;
  for (size_t off = 0; off < nbytes; off += GEMCC_PAGE_SIZE)
    (void)p[off];
  (void)p[nbytes - 1];
}

/* I: Gemmini DMA 目的范围
 * P: 兼容旧测试名；执行与 gemmini_dma_prefault 相同的逐页 store
 * O: 目的范围的每个页已建立可写映射
 * A: shiroha_suki
 * T: 2026-08-29
 */
static inline void gemmini_dma_prefault_pages(void *ptr, size_t nbytes) {
  gemmini_dma_prefault(ptr, nbytes);
}

#endif
