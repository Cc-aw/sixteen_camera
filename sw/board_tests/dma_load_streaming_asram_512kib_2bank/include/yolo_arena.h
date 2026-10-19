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
_Static_assert(YOLO_ROUNDS>=1 && YOLO_ROUNDS<=3,"YOLO_ROUNDS must be 1..3");
static ActivationArenaView arena_views[3];
static ActivationSramCapabilities arena_caps;
static unsigned storage_profile, reference_ready;
static uintptr_t arena_dma_address(uintptr_t address,unsigned lane);
static void yolo_bind_storage(unsigned profile,int quiescent);
static void yolo_fill_arenas(unsigned char value);
static uint64_t yolo_hash_arenas(void);
static void yolo_commit_lane(unsigned lane);
static void yolo_check_guards(void);
#endif
