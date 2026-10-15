#include <stddef.h>
#include <stdint.h>
#include "platform.h"
void *memset(void *p,int v,size_t n) { unsigned char *d=p;while(n--)*d++=v;return p; }
void *memcpy(void *p,const void *s,size_t n) { unsigned char *d=p;const unsigned char *a=s;while(n--)*d++=*a++;return p; }
int memcmp(const void *p,const void *q,size_t n) { const unsigned char *a=p,*b=q;while(n--){if(*a!=*b)return *a-*b;a++;b++;}return 0; }
size_t strlen(const char *s) {size_t n=0;while(s[n])n++;return n;}
int *__errno(void) {static int e;return &e;}
int abs(int x) {return x<0?-x:x;}
static void out(const char *s) {
    volatile uint32_t *u=(volatile uint32_t *)AT_UART_BASE;
    while(*s) { if(*s=='\n'){while(u[0]&0x80000000u){}u[0]='\r';}while(u[0]&0x80000000u){}u[0]=(unsigned char)*s++; }
}
#if AT_HARDWARE_SILU
/* Called after stack/trap setup, before any BSS access. No mutable globals,
 * model state, vector instructions or Gemmini instructions are needed. */
void at_boot_before_bss(void) {
    volatile uint32_t *u=(volatile uint32_t *)AT_UART_BASE;
    u[4]=0;u[6]=AT_UART_DIV;u[2]=1;
    out("ATV5Y,BOOT,revision=camera_uart_fix1,uart_base=0x10020000\n");
    out("ATV5Y,BSS_BEGIN\n");
}
void at_boot_after_bss(void) {out("ATV5Y,BSS_END\n");}
#endif
int puts(const char *s) {out(s);out("\n");return 0;}
int printf(const char *s,...) {out(s);return strlen(s);}
__attribute__((noreturn)) void exit(int code) {(void)code;out("ATSOFT1,FAIL,reason=model_exit\n");for(;;)__asm__ volatile("nop");}
void *malloc(size_t n) {(void)n;return NULL;}
void free(void *p) {(void)p;}
