#ifndef CACHE_OPS_H
#define CACHE_OPS_H

#include <stddef.h>

void cache_flush_range(const void *base, size_t bytes);

#endif
