#ifndef RUNTIME_DIAGNOSTICS_H
#define RUNTIME_DIAGNOSTICS_H
/* Device/model counters and raw per-frame profiles, for UART diagnostics. */
void rt_diagnostics_print_status(void);
void rt_diagnostics_print_frame_profiles(void);
#endif
