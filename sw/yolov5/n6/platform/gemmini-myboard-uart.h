#pragma once

#include <stdint.h>
#include <stddef.h>
#include <sys/types.h>
#include "mmio.h"

#define UART_BASE      0x10020000UL
#define UART_TXDATA    (UART_BASE + 0x00)
#define UART_TXCTRL    (UART_BASE + 0x08)
#define UART_DIV       (UART_BASE + 0x18)
#define UART_TXFULL    (1UL << 31)
#define UART_TXEN      (1UL << 0)

static void uart_init(void)
{
  reg_write32(UART_DIV, 868);
  reg_write32(UART_TXCTRL, UART_TXEN);
}

ssize_t _write(int fd, const void *buf, size_t count)
{
  (void)fd;
  const unsigned char *p = (const unsigned char *)buf;
  for (size_t i = 0; i < count; i++) {
    unsigned char c = p[i];
    if (c == '\n') {
      while (reg_read32(UART_TXDATA) & UART_TXFULL) ;
      reg_write32(UART_TXDATA, '\r');
    }
    while (reg_read32(UART_TXDATA) & UART_TXFULL) ;
    reg_write32(UART_TXDATA, (uint32_t)c);
  }
  return (ssize_t)count;
}

void *_sbrk(int incr) { (void)incr; return (void *)-1; }
int _close(int fd) { (void)fd; return -1; }
int _fstat(int fd, void *buf) { (void)fd; (void)buf; return -1; }
int _isatty(int fd) { (void)fd; return 1; }
int _lseek(int fd, int ptr, int dir) { (void)fd; (void)ptr; (void)dir; return -1; }
int _read(int fd, void *buf, size_t cnt) { (void)fd; (void)buf; (void)cnt; return 0; }
