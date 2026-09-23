#ifndef AI_YOLOV5NU_SELFTEST_H
#define AI_YOLOV5NU_SELFTEST_H

int ai_yolov5nu_correctness_test(void);
int ai_yolov5nu_sequential_correctness_test(int reverse_order);
int ai_yolov5nu_postprocess_benchmark(void);
int ai_yolov5nu_graph_post_benchmark(void);

#endif
