#ifndef YOLO32_PACKET_DISPATCH_RUNTIME
#define YOLO32_PACKET_DISPATCH_RUNTIME
#ifndef YOLO32_RECORD_FIXED_RUN
#define YOLO32_RECORD_FIXED_RUN(worker,funct) GEMMINI_POOL_RECORD_COMMAND(funct)
#endif
/* Use native operand packing and the native fixed-opcode instruction macro.
 * Each caller chooses a worker once. Only the complete packet's RUN calls
 * the scheduler; arguments hooks and native diagnostic windows are retained. */
#define YOLO32_EMIT_FIXED(op,funct,a,b) do { \
    uint64_t _dispatch_a=(uint64_t)(a),_dispatch_b=(uint64_t)(b); \
    GEMMINI_POOL_COMMAND_ARGS_HOOK(funct,_dispatch_a,_dispatch_b); \
    __asm__ volatile("" :: "r"(_dispatch_a),"r"(_dispatch_b) : "memory"); \
    uint64_t _dispatch_start=GEMMINI_POOL_COMMAND_CLOCK(funct); \
    ROCC_INSTRUCTION_0_R_R(op,_dispatch_a,_dispatch_b,funct); \
    GEMMINI_POOL_COMMAND_ELAPSED(funct,_dispatch_start); \
} while (0)
#endif
