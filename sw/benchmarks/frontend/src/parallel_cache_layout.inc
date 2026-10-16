/* SW-P3 views are fixed before binding/capture. Capacities never use sizeof a
 * pointer. Profiles share allocations and readonly constants. */
#include "sw_p3_layout_offsets.inc"
_Static_assert(YOLOV5NU_CONV_INPUT_SCRATCH==1228800 && YOLOV5NU_CONV_OUTPUT_SCRATCH==1228800, "SW-P3 logical scratch capacity changed");
static elem_t **const sw_p3_views[5] = {activation_arenas,conv_input_scratches,
    conv_output_scratches,memory_pad,memory_intermediate};
static elem_t *const sw_p3_storage[5] = {activation_arenas_storage,conv_input_scratches_storage,
    conv_output_scratches_storage,memory_pad_storage,memory_intermediate_storage};
static const size_t sw_p3_capacity[5] = {2217600,1228800,1228800,17*22*128,15*20*128};
static unsigned sw_p3_layout;
static void sw_p3_set_layout(unsigned candidate) {
    if(candidate>1)at_fail("sw_p3_layout_range",candidate);
    candidate=candidate&&sw_p3_layout_enabled;
    sw_p3_layout=candidate;
    for(unsigned k=0;k<5;k++)for(unsigned d=0;d<3;d++) {
        size_t n=sw_p3_capacity[k],offset=sw_p3_offsets[k][d];
        if(offset>=SW_P3_L2_PERIOD||offset%64)at_fail("sw_p3_alignment",offset);
        elem_t *p=sw_p3_storage[k]+64+d*(candidate?(n+SW_P3_L2_PERIOD+128):n)+(candidate?offset:0);
        if((uintptr_t)p%64||p<sw_p3_storage[k]+64||p+n+64>sw_p3_storage[k]+3*(n+SW_P3_L2_PERIOD+128))
            at_fail("sw_p3_storage_bounds",k);
        sw_p3_views[k][d]=p;
        if(candidate||d==0)memset(p-64,0x5a,64);
        if(candidate||d==2)memset(p+n,0x5a,64);
        for(unsigned previous=0;previous<d;previous++) {
            elem_t *q=sw_p3_views[k][previous];
            if(p<q+n&&q<p+n)at_fail("sw_p3_lane_overlap",k);
        }
    }
}
static void sw_p3_guards_check(void) {
    for(unsigned k=0;k<5;k++)for(unsigned d=0;d<3;d++)for(unsigned i=0;i<64;i++) {
        elem_t *p=sw_p3_views[k][d];size_t n=sw_p3_capacity[k];
        if(((sw_p3_layout||d==0)&&(uint8_t)p[(int)i-64]!=0x5a)||
           ((sw_p3_layout||d==2)&&(uint8_t)p[n+i]!=0x5a))at_fail("sw_p3_guard",k*3+d);
    }
}
static void sw_p3_tensor_fill(unsigned char value) {
    for(unsigned k=0;k<5;k++)for(unsigned d=0;d<3;d++)
        memset(sw_p3_views[k][d],value,sw_p3_capacity[k]);
}
static uint64_t sw_p3_tensor_hash(void) {
    uint64_t hash=0;
    for(unsigned k=0;k<5;k++)for(unsigned d=0;d<3;d++) {
        const uint8_t *p=(const uint8_t *)sw_p3_views[k][d];
        uint64_t h=UINT64_C(1469598103934665603);
        for(size_t i=0;i<sw_p3_capacity[k];i++){h^=p[i];h*=UINT64_C(1099511628211);}
        hash^=h+(uint64_t)(k*3+d);
    }
    return hash;
}
