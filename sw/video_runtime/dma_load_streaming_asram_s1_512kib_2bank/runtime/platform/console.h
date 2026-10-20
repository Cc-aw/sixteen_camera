#ifndef HDMI_TX_TEST_CONSOLE_H
#define HDMI_TX_TEST_CONSOLE_H

#include <stdint.h>

void console_init(void);
void console_putc(char value);
void console_puts(const char *text);
void console_put_hex32(uint32_t value);
void console_put_hex64(uint64_t value);
void console_put_u32(uint32_t value);
int console_getc_nonblock(void);

#endif
