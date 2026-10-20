#include <assert.h>
#include <stdint.h>
#include <stdio.h>
#include "drivers/tensor/ai_tensor_device.h"
#include "platform/platform.h"
uint64_t test_cycle=1,test_cycle_step;
static uint32_t frames[16];
uint32_t mmio_read32(uintptr_t address){
    uintptr_t offset=address-FRAMEBUFFER_BASE-FRAMEBUFFER_WRITER_COUNT(0);
    assert(offset<64&&offset%4==0);return frames[offset/4];
}
void mmio_write32(uintptr_t address,uint32_t value){(void)address;(void)value;assert(0);}
static void expect(uint32_t mask){
    assert(ai_tensor_device_active_inputs()==(mask&CAMERA_PRESENT_MASK));
    assert(ai_tensor_device_active_inputs()==(mask&CAMERA_PRESENT_MASK));
}
int main(void){
    expect(0);
    frames[0]=frames[7]=frames[15]=1;test_cycle=SOC_CLOCK_HZ/10+2;expect(0x8081);
    frames[0]++;frames[7]++;test_cycle=SOC_CLOCK_HZ/2;expect(0x8081);
    frames[0]++;frames[7]++;test_cycle=SOC_CLOCK_HZ*12/10;expect(0x81);
    test_cycle=SOC_CLOCK_HZ*25/10;expect(0);
    frames[15]++;test_cycle=SOC_CLOCK_HZ*27/10;expect(0x8000);
    frames[0]=UINT32_MAX;test_cycle=SOC_CLOCK_HZ*29/10;expect(0x8001);
    frames[0]=0;test_cycle=SOC_CLOCK_HZ*31/10;expect(0x8001);
    puts("INPUT_MONITOR_PASS absent_hdmi=1 expiry=1 reconnect=1 counter_wrap=1 requested_mask=1");
    return 0;
}
