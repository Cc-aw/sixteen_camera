#ifndef TENSOR_PRODUCTION_H
#define TENSOR_PRODUCTION_H
void tensor_production_init(void);
void tensor_production_toggle(void);
void tensor_production_service(void);
#ifdef TENSOR_INGRESS_STATS
void tensor_ingress_print_stats(void);
#endif
#endif
