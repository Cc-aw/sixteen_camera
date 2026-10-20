#include <assert.h>
#include <stdint.h>
#include <stdio.h>
#include "drivers/tensor/ai_tensor_device.h"
#include "platform/platform.h"
uint64_t test_cycle=1,test_cycle_step=100000;
static uint32_t control=1,ready,writing=1,reads,writes,stuck;
uint32_t mmio_read32(uintptr_t address){
    uintptr_t offset=address-FRAMEBUFFER_BASE;
    if(offset==FRAMEBUFFER_TENSOR_PROD_CONTROL)return control;
    if(offset==FRAMEBUFFER_TENSOR_PROD_ADMISSION_MASK)return 3;
    if(offset==FRAMEBUFFER_TENSOR_PROD_READY){
        reads++;
        if(!stuck&&reads>4){ready=0x00030003;writing=0;}
        return ready;
    }
    if(offset==FRAMEBUFFER_TENSOR_PROD_WRITING)return writing;
    if(offset==FRAMEBUFFER_TENSOR_DMA_OUTSTANDING)return writing?1:0;
    assert(0);return 0;
}
void mmio_write32(uintptr_t address,uint32_t value){
    assert(address==FRAMEBUFFER_BASE+FRAMEBUFFER_TENSOR_PROD_CONTROL&&value==0);
    assert(ready==0x00030003&&writing==0);control=value;writes++;
}
int main(void){
    assert(ai_tensor_device_quiesce()==0&&writes==1&&reads>=5&&control==0);
    assert(ai_tensor_device_quiesce()==0&&writes==1);
    control=1;ready=0;writing=1;stuck=1;test_cycle_step=SOC_CLOCK_HZ;
    assert(ai_tensor_device_quiesce()==-1&&control==1&&writes==1);
    puts("CAPTURE_QUIESCE_PASS full_slots_before_disable=1 timeout_preserves_enable=1");return 0;
}
