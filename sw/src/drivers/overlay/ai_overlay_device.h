#ifndef AI_OVERLAY_DEVICE_H
#define AI_OVERLAY_DEVICE_H

#include <stdint.h>

/* One CPU owns the mailbox transaction. No frame, version or TTL policy, and
 * no added fence. Call begin before writing mapped boxes, then commit once. */
int ai_overlay_device_begin(uint32_t stream, uint32_t count);
void ai_overlay_device_write_box(uint32_t index, uint64_t packed_coordinates);
void ai_overlay_device_write_label(uint32_t index, const uint32_t words[4]);
void ai_overlay_device_commit(void);

#endif
