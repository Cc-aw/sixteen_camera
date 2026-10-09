#ifndef XIL_IO_H
#define XIL_IO_H

#include "mmio.h"
#include "xil_types.h"

static inline u32 Xil_In32(UINTPTR Addr)
{
    return mmio_read32(Addr);
}

static inline void Xil_Out32(UINTPTR Addr, u32 Value)
{
    mmio_write32(Addr, Value);
    mmio_fence();
}

static inline u16 Xil_In16(UINTPTR Addr)
{
    return *(volatile const u16 *)Addr;
}

static inline void Xil_Out16(UINTPTR Addr, u16 Value)
{
    *(volatile u16 *)Addr = Value;
    mmio_fence();
}

static inline u8 Xil_In8(UINTPTR Addr)
{
    return *(volatile const u8 *)Addr;
}

static inline void Xil_Out8(UINTPTR Addr, u8 Value)
{
    *(volatile u8 *)Addr = Value;
    mmio_fence();
}

#endif
