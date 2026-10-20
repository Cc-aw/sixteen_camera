#ifndef APP_H
#define APP_H
/* Video init includes the original post-video Tensor reset preflight. */
void app_video_init(void);
void app_init(int runtime_status);
void app_poll(void);
#endif
