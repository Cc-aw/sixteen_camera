#ifndef YOLO_ASRAM_ARENA_H
#define YOLO_ASRAM_ARENA_H
#include "activation_memory.h"
#include "build_config.h"
#ifndef YOLO_ROUNDS
#define YOLO_ROUNDS 1
#endif
#ifndef YOLO_DIAGNOSTIC
#define YOLO_DIAGNOSTIC 0
#endif
#ifndef YOLO_SPPF_ASRAM
#define YOLO_SPPF_ASRAM 1
#endif
_Static_assert(YOLO_ROUNDS>=1 && YOLO_ROUNDS<=3,"YOLO_ROUNDS must be 1..3");
_Static_assert(YOLO_SPPF_ASRAM==0 || YOLO_SPPF_ASRAM==1,"YOLO_SPPF_ASRAM must be 0 or 1");
enum {
    SPPF_PAD_BYTES=17*22*128,
    SPPF_INTERMEDIATE_BYTES=15*20*128,
    SPPF_PAD_OFFSET=ASRAM_ARENA_BYTES+64,
    SPPF_INTERMEDIATE_OFFSET=SPPF_PAD_OFFSET+SPPF_PAD_BYTES+64,
    SPPF_LOCAL_END=SPPF_INTERMEDIATE_OFFSET+SPPF_INTERMEDIATE_BYTES
};
_Static_assert(SPPF_LOCAL_END+64<=ASRAM_BYTES_PER_BANK,"SPPF workspace exceeds ASRAM");
_Static_assert(SPPF_PAD_OFFSET%64==0 && SPPF_INTERMEDIATE_OFFSET%64==0,"SPPF alignment");
static ActivationArenaView arena_views[3];
static ActivationSramCapabilities arena_caps;
static unsigned storage_profile, reference_ready;
static uintptr_t arena_dma_address(uintptr_t address,unsigned lane);
static void yolo_bind_storage(unsigned profile,int quiescent);
static void yolo_fill_arenas(unsigned char value);
static uint64_t yolo_hash_arenas(void);
static void yolo_commit_lane(unsigned lane);
static void yolo_check_guards(void);
static unsigned yolo_sppf_local(void);
#endif
