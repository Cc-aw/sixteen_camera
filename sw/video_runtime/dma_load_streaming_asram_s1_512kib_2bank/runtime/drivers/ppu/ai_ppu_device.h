#ifndef AI_PPU_DEVICE_H
#define AI_PPU_DEVICE_H

#include <stdint.h>

/* Device descriptors carry hardware identities, never Runtime job ownership. */
typedef struct {
    uintptr_t base_addr;
    uintptr_t class_addr[3];
    uintptr_t dfl_addr[3];
    uint32_t stream;
    uint64_t frame;
    uint32_t version;
} AiPpuDeviceDescriptor;

typedef struct {
    uint32_t bank, generation, stream, version, count, status, cycles;
    uint64_t frame;
} AiPpuDeviceResult;

typedef struct {
    uint32_t status, generation, masks;
} AiPpuDeviceReceipt;

typedef struct {
    uint32_t xy0, xy1, score_class;
} AiPpuDeviceDetection;

typedef enum {
    AI_PPU_COUNTER_RESULT_COUNT,
    AI_PPU_COUNTER_POSITIONS,
    AI_PPU_COUNTER_CANDIDATES,
    AI_PPU_COUNTER_NMS,
    AI_PPU_COUNTER_CYCLES,
    AI_PPU_COUNTER_READER_STATUS,
    AI_PPU_COUNTER_READER_BYTES,
    AI_PPU_COUNTER_READER_AR,
    AI_PPU_COUNTER_READER_BEATS,
    AI_PPU_COUNTER_COUNT
} AiPpuDeviceCounter;

#define AI_PPU_DEVICE_STATUS_BUSY UINT32_C(1)
#define AI_PPU_DEVICE_STATUS_DONE UINT32_C(2)
#define AI_PPU_DEVICE_STATUS_ERROR UINT32_C(4)
#define AI_PPU_DEVICE_STATUS_READ_BUSY UINT32_C(8)

/* Publication return values and generation wrap retain the legacy protocol.
 * All operations share one CPU owner; selected-bank receipts are not atomic. */
uint32_t ai_ppu_device_publication_generation(uintptr_t base);
int ai_ppu_device_publication_available(void);
int ai_ppu_device_publication_select(uintptr_t base);
int ai_ppu_device_publication_begin(uintptr_t base);
void ai_ppu_device_publication_publish(uintptr_t base, uint32_t mask);
void ai_ppu_device_publication_abort(uintptr_t base);
void ai_ppu_device_publication_receipt(AiPpuDeviceReceipt *receipt);
int ai_ppu_device_publication_matches(uintptr_t base, uint32_t generation);
int ai_ppu_device_receipt_matches(uintptr_t base, const AiPpuDeviceReceipt *receipt);

int ai_ppu_device_queue_init(void);
int ai_ppu_device_queue_active(void);
void ai_ppu_device_queue_expect(uint32_t stream, uint64_t frame, uint32_t version);
int ai_ppu_device_queue_ready(void);
int ai_ppu_device_queue_submit(const AiPpuDeviceDescriptor *descriptor);
/* Compatibility conversion runs only after readiness succeeds. This entry
 * commits using that same readiness observation, without another CSR read. */
int ai_ppu_device_queue_submit_ready(const AiPpuDeviceDescriptor *descriptor);
int ai_ppu_device_queue_peek(AiPpuDeviceResult *result);
void ai_ppu_device_queue_pop(void);

/* Legacy single-command and diagnostics: preserve their original read/write
 * order and do not add a fence. Cache visibility and live init ordering remain
 * the caller's responsibility. These APIs do not authorize Head release. */
int ai_ppu_device_available(void);
uint32_t ai_ppu_device_status(void);
uint32_t ai_ppu_device_reader_state(void);
void ai_ppu_device_live_configure(void);
void ai_ppu_device_start(const uintptr_t class_addr[3], const uintptr_t dfl_addr[3],
                         int publication_selected);
uint32_t ai_ppu_device_read_counter(AiPpuDeviceCounter counter);
void ai_ppu_device_read_detection(uint32_t index, AiPpuDeviceDetection *detection);

#endif
