#include <stdint.h>
#include "platform/console.h"
#include "platform/cycle.h"
#include "platform/platform.h"
#include "video/video_service.h"
#include "ai/runtime/rt.h"
#include "ai/runtime/core/rt_internal.h"
#include "drivers/tensor/ai_tensor_device.h"
#include "mmio.h"
extern void s1_runtime_check_guards(void);
static void decimal(uint64_t v){char b[24];unsigned n=sizeof(b);do{b[--n]='0'+v%10;v/=10;}while(v);while(n<sizeof(b))console_putc(b[n++]);}
static void field(const char *s,uint64_t v){console_puts(s);decimal(v);}
static void stats(unsigned detail) {
    AiRtStatus s;rt_get_status(&s);AiRtBackendResources resources;
    rt_backend_get_resources(&rt_core_instance()->backend,&resources);
    console_puts("S1RT,STATS");field(",state=",rt_state());field(",enabled=",s.enabled);
    field(",completed=",s.completed_job_count);field(",published=",s.result_publish_count);
    field(",capture_mask=",ai_tensor_device_active_inputs());field(",admission_mask=",rt_core_instance()->admission_mask);
    field(",hw_control=",mmio_read32(FRAMEBUFFER_BASE+FRAMEBUFFER_TENSOR_PROD_CONTROL));
    field(",hw_admission=",mmio_read32(FRAMEBUFFER_BASE+FRAMEBUFFER_TENSOR_PROD_ADMISSION_MASK));
    field(",errors=",s.error_count);field(",last_error_magnitude=",s.last_error<0?-(int64_t)s.last_error:s.last_error);
    field(",error_slots=",ai_tensor_device_error());field(",ready=",ai_tensor_device_ready());field(",writing=",ai_tensor_device_writing());
    field(",held_tensor=",rt_core_instance()->tensors.held);field(",active=",resources.activation_held);
    field(",heads=",resources.owned_head);field(",fault=",resources.unsafe_fault);console_puts("\n");
    if(!detail)return;
    for(unsigned i=0;i<VIDEO_CHANNEL_COUNT;i++) {
        AiRtStreamStatus stream;rt_get_stream_status(i,&stream);
        console_puts("S1RT,STREAM");field(",stream=",i);field(",dispatched=",stream.dispatched_count);
        field(",completed=",stream.completed_count);field(",capture_frames=",mmio_read32(FRAMEBUFFER_BASE+FRAMEBUFFER_WRITER_COUNT(i)));field(",frame=",stream.last_frame_id);field(",version=",stream.last_version);
        const AiDetectionResult *result=rt_latest_result(i);field(",detections=",result?result->count:0);console_puts("\n");
    }
}
int main(void) {
    console_init();console_puts("\nS1RT,BOOT,hardware_id=e037701c8d7cfc59,live_input=1\n");
    /* Check clean S1 hardware and initialize model before enabling production. */
    if(rt_init()!=0){console_puts("S1RT,FAIL,reason=runtime_init\n");for(;;)cpu_wfi();}
    ai_tensor_device_disable();rt_set_enabled(0);
    uint64_t cleanup=platform_read_cycle();
    while(!rt_is_idle()) {
        rt_poll();
        if(platform_read_cycle()-cleanup>SOC_CLOCK_HZ*5){console_puts("S1RT,FAIL,reason=startup_drain_reprogram_bitstream\n");for(;;)cpu_wfi();}
    }
    int video=video_service_init();
    console_puts(video?"S1RT,VIDEO_INIT,all_devices_ready=0,continuing_capture=1\n":"S1RT,VIDEO_INIT,all_devices_ready=1\n");
    rt_set_enabled(1);
    if(!rt_is_enabled()){console_puts("S1RT,FAIL,reason=enable\n");stats(1);for(;;)cpu_wfi();}
    console_puts("S1RT,READY,continuous=1,commands=b_sample100,s_stop,a_start,t_stats,v_streams\n");
    uint64_t last=platform_read_cycle();unsigned was_idle=0;
    uint64_t sample_target=0;unsigned sample_stopping=0;
    uint32_t last_admission=UINT32_MAX;
    for(;;) {
        video_service_poll();rt_poll();
        uint32_t admission=rt_core_instance()->admission_mask;
        if(admission!=last_admission) {
            console_puts("S1RT,INPUT_MASK");field(",mask=",admission);console_puts("\n");last_admission=admission;
        }
        int c=console_getc_nonblock();
        if(c=='s'){rt_set_enabled(0);console_puts("S1RT,STOP_REQUEST\n");}
        if(c=='a'){rt_set_enabled(1);console_puts("S1RT,START_REQUEST\n");}
        if(c=='t')stats(0);
        if(c=='v')stats(1);
        if(c=='b'&&rt_is_enabled()) {
            AiRtStatus status;rt_get_status(&status);sample_target=(uint64_t)status.completed_job_count+100;
            sample_stopping=0;console_puts("S1RT,SAMPLE_BEGIN");field(",initial=",status.completed_job_count);field(",target=",sample_target);console_puts("\n");
        }
        if(sample_target&&!sample_stopping) {
            AiRtStatus status;rt_get_status(&status);
            if(status.completed_job_count>=sample_target){rt_set_enabled(0);sample_stopping=1;console_puts("S1RT,SAMPLE_DRAIN\n");}
        }
        unsigned idle=rt_is_idle();
        if(idle&&!was_idle) {
            s1_runtime_check_guards();
            console_puts("S1RT,IDLE,ownership_released=1\n");stats(1);
            console_puts("S1RT,STOPPED\n");
            if(sample_stopping) {
                AiRtStatus status;rt_get_status(&status);
                console_puts("S1RT,SAMPLE_END");field(",completed=",status.completed_job_count);
                field(",errors=",status.error_count);console_puts(",idle=1,held_tensor=0,heads=0\n");
                sample_target=0;sample_stopping=0;
            }
        }
        was_idle=idle;
        if(rt_state()==AI_RT_STATE_FAULTED) {
            stats(1);console_puts("S1RT,FAIL,reason=runtime_fault,ownership=retained\n");
            for(;;)cpu_wfi();
        }
        uint64_t now=platform_read_cycle();
        if(now-last>=SOC_CLOCK_HZ){stats(0);last=now;}
    }
}
