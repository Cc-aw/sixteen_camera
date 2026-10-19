#ifndef GEMMINI_MERGED_POOL_H
#define GEMMINI_MERGED_POOL_H
/* Logical workers 0/1/2 use custom3/2/1. Each owns its credit ledger. */
#include "gemmini_params_64x64_ws_dual_int8_dsp_inference_ram_custom3_xcvu13p.h"
#define GEMMINI_POOL_RUNTIME_DISPATCH 1
#define GEMMINI_LOOPCONV_WORKER1_STATUS_CSR 0x7c5
#define GEMMINI_LOOPCONV_WORKER1_ACCEPTED_CSR 0x7c8
#define GEMMINI_LOOPCONV_WORKER1_RETIRED_CSR 0x7c9
#define GEMMINI_LOOPCONV_WORKER2_STATUS_CSR 0x7cb
#define GEMMINI_LOOPCONV_WORKER2_ACCEPTED_CSR 0x7cc
#define GEMMINI_LOOPCONV_WORKER2_RETIRED_CSR 0x7cd
#include "gemmini.h"
#endif
