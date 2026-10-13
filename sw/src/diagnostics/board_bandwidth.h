#ifndef BOARD_BANDWIDTH_H
#define BOARD_BANDWIDTH_H
void board_bandwidth_begin(void);
void board_read_bandwidth_begin(void);
void board_raw_concurrent_begin(void);
void board_bandwidth_service(void);
void board_write_only_begin(void);
void board_write_only_service(void);
#endif
