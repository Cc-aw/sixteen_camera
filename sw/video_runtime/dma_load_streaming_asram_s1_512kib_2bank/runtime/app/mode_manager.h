#ifndef APP_MODE_MANAGER_H
#define APP_MODE_MANAGER_H
#include "ai/runtime/rt.h"
#include "platform/platform.h"

/* Private Application/diagnostic state. No model or Head ownership here. */
#define BOARD_BANDWIDTH_ITERATIONS UINT32_C(256)
#define BOARD_BANDWIDTH_BURST_BYTES UINT32_C(64)
#define BOARD_WRITE_ONLY_CYCLES (SOC_CLOCK_HZ * UINT64_C(10))
#define BOARD_BW_CONCURRENT UINT32_C(1)
#define BOARD_BW_READ_ONLY UINT32_C(2)
#define BOARD_BW_RAW_CONCURRENT UINT32_C(3)

typedef struct {
    uint32_t active;
    uint64_t start_cycle;
    uint32_t write_beats;
    uint32_t write_bursts;
    uint32_t write_completed;
    uint32_t write_aw_stall;
    uint32_t write_w_stall;
    uint32_t write_b_wait;
    uint32_t saved_admission_limit;
    AiRtStatus runtime_start;
} BoardBandwidthState;


typedef struct {
    uint32_t active;
    uint32_t draining;
    uint64_t start_cycle;
    uint32_t write_beats;
    uint32_t write_bursts;
    uint32_t write_completed;
    uint32_t write_starvation;
    uint32_t write_aw_stall;
    uint32_t write_w_stall;
    uint32_t write_b_wait;
    uint32_t saved_admission_limit;
} BoardWriteOnlyState;


typedef struct {
    uint32_t mode;
    uint32_t done[VIDEO_CHANNEL_COUNT];
    uint32_t last_frame[VIDEO_CHANNEL_COUNT];
    uint64_t report_cycle;
} AiTensorProductionMode;
typedef struct {
    AiTensorProductionMode tensor;
    BoardBandwidthState bandwidth;
    BoardWriteOnlyState write_only;
} AiAppModes;
extern AiAppModes app_modes;
int app_mode_command_allowed(int command);
int app_mode_selftest_allowed(void);
void app_mode_toggle_runtime(void);
#endif
