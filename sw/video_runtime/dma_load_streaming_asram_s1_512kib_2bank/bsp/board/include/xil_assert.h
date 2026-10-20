#ifndef XIL_ASSERT_H
#define XIL_ASSERT_H

#include "xil_types.h"

extern u32 Xil_AssertStatus;
typedef void (*Xil_AssertCallback)(const char8 *File, s32 Line);

#define XIL_ASSERT_NONE  0U
#define XIL_ASSERT_OCCURRED 1U

#define Xil_AssertVoid(Expression) do { \
    if (!(Expression)) { Xil_AssertStatus = XIL_ASSERT_OCCURRED; return; } \
} while (0)
#define Xil_AssertNonvoid(Expression) do { \
    if (!(Expression)) { Xil_AssertStatus = XIL_ASSERT_OCCURRED; return 0; } \
} while (0)
#define Xil_AssertVoidAlways() do { \
    Xil_AssertStatus = XIL_ASSERT_OCCURRED; return; \
} while (0)
#define Xil_AssertNonvoidAlways() do { \
    Xil_AssertStatus = XIL_ASSERT_OCCURRED; return 0; \
} while (0)

static inline void Xil_AssertSetCallback(Xil_AssertCallback Routine)
{
    (void)Routine;
}

#endif
