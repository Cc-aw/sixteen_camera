/* Actual frozen planner + new backend + actual video Runtime. Only devices
 * are mocked; these tests do not claim RTL execution or board accuracy. */
#include <assert.h>
#include <stdio.h>
#include <string.h>
#include "hw_mock.h"
#include "../src/yolo_boundary.c"
#include "ai/runtime/core/rt_internal.h"
uint64_t mock_cycle=1;
struct FakeLane {const GfCommand *table;unsigned active,tag,count,raw;};
static struct FakeLane fake_lanes[3];
static unsigned selected_bank,gen[6],masks[6],begun[6],deliver,inject,freeze_frontend,frontend_fault;
static AiPpuQueueResult results[64];
static unsigned result_read,result_write;
static AiTensorDeviceDescriptor tensors[32];
static uint32_t tensor_ready,tensor_enabled,releases,unsafe_release;
static uint32_t active_inputs=0xffff,programmed_mask,overlay_cleared;
static unsigned saw_three,saw_overlap;
const int8_t yolo32_inputs[3][YOLO32_INPUT_BYTES]={0};
const char *const yolo32_image_ids[3]={"025","036","142"};
void gf_publish(void){}
uint64_t gf_status(unsigned d){if(frontend_fault&&fake_lanes[d].active)return GF_FAULT;return fake_lanes[d].active?(fake_lanes[d].tag<=12?GF_HOST_WAIT:GF_DONE):GF_START_READY;}
unsigned gf_pending(void){unsigned m=0;if(freeze_frontend)return 0;for(unsigned d=0;d<3;d++)if(fake_lanes[d].active)m|=1U<<d;return m;}
uint64_t gf_read(unsigned d,uint64_t query,uint64_t arg){(void)arg;struct FakeLane *l=&fake_lanes[d];switch(query){case 0:return gf_status(d);case 1:return ((uint64_t)l->count<<32)|l->raw;case 2:return ((uint64_t)l->count<<32)|l->count;case 3:return l->tag;default:return 0;}}
uint64_t gf_launch(unsigned d,const GfCommand *t,uint32_t n,uintptr_t frame,uint32_t timeout,int irq){
 (void)frame;(void)timeout;(void)irq;assert(!fake_lanes[d].active);unsigned raw=0;
 for(unsigned i=0;i<n;i++)raw+=(t[i].control&255)==GF_RAW;
 fake_lanes[d]=(struct FakeLane){t,1,1,n,raw};return 0;
}
uint64_t gf_resume(unsigned d,uint64_t tag,uint64_t unused){(void)unused;assert(fake_lanes[d].tag==tag);fake_lanes[d].tag++;return 0;}
uint64_t gf_ack(unsigned d,uint64_t a,uint64_t b){(void)a;(void)b;assert(fake_lanes[d].tag==13);fake_lanes[d].active=0;return 0;}
uint32_t mmio_read32(uintptr_t address){unsigned o=address-POSTPROCESS_DIAG_BASE;switch(o){case 0x100:return 0x50505531;case 0x1a0:return 0x50505532;case 0x148:return 1;case 0x1b4:return begun[selected_bank];case 0x1bc:return gen[selected_bank];case 0x1b8:return masks[selected_bank]<<8;case 0x204:return 0x50505132;default:return 0;}}
void mmio_write32(uintptr_t address,uint32_t v){(void)address;(void)v;}
static unsigned bank(uintptr_t base){unsigned d=(base-0x32000000)/0x400000,s=((base-0x32000000)%0x400000)/0x100000;assert(d<3&&s<2);return d*2+s;}
int ai_ppu_publication_available(void){return 1;}
int ai_ppu_publication_begin(uintptr_t base){selected_bank=bank(base);gen[selected_bank]++;masks[selected_bank]=0;begun[selected_bank]=1;return 1;}
uint32_t ai_ppu_publication_generation(uintptr_t base){return gen[bank(base)];}
void ai_ppu_publication_publish(uintptr_t base,uint32_t mask){selected_bank=bank(base);masks[selected_bank]|=mask;}
int ai_ppu_queue_init(void){return 1;}
int ai_ppu_queue_ready(void){return 1;}
void ai_ppu_queue_expect(uint32_t stream,uint64_t frame,uint32_t version){assert(stream<16&&frame&&version);}
int ai_ppu_queue_submit(const AiHeadSlotDescriptor *d){
 assert(result_write<64);unsigned key=bank(d->base_addr);assert(masks[key]==63);
 results[result_write++]=(AiPpuQueueResult){.bank=key,.generation=gen[key],.stream=d->stream_id,.frame=d->frame_id,.version=d->version,.count=2};return 1;
}
int ai_ppu_queue_peek(AiPpuQueueResult *r){if(!deliver||result_read==result_write)return 0;*r=results[result_read];if(inject==1)r->version++;if(inject==2)r->generation++;if(inject==3)r->status=1;return 1;}
void ai_ppu_queue_pop(void){assert(result_read<result_write);result_read++;}
uint32_t ai_tensor_device_active_inputs(void){return active_inputs;}
uint32_t ai_tensor_device_ready(void){return tensor_ready;}
uint32_t ai_tensor_device_error(void){return 0;}
uint32_t ai_tensor_device_writing(void){return 0;}
int ai_tensor_device_read_slot(uint32_t slot,AiTensorDeviceDescriptor *d){if(slot>=32||!(tensor_ready&(1U<<slot)))return -1;*d=tensors[slot];return 0;}
int ai_tensor_device_release(uint32_t slot,uint32_t enabled){(void)enabled;
 AiRtCore *rt=rt_core_instance();for(unsigned d=0;d<3;d++)if(fake_lanes[d].active&&live_workers[d].state&&rt->workers[d].slot==slot)unsafe_release++;
 tensor_ready&=~(1U<<slot);releases++;return 0;
}
int ai_tensor_device_release_poll(uint32_t slot){return tensor_ready&(1U<<slot)?AI_TENSOR_RELEASE_SLOT_PRESENT:AI_TENSOR_RELEASE_ACK;}
int ai_tensor_device_enable(uint32_t mask,uint32_t limit){assert(mask==active_inputs&&limit==1);programmed_mask=mask;tensor_enabled=1;return 0;}
int ai_tensor_device_quiesce(void){tensor_enabled=0;return 0;}
void ai_tensor_device_disable(void){tensor_enabled=0;}
int ai_overlay_try_submit(const AiDetectionResult *r){if(!r->count)overlay_cleared|=1U<<r->stream_id;assert(!r->count||(r->flags&AI_RESULT_HARDWARE_OVERLAY));return 1;}
static void produce(unsigned stream,unsigned second,uint32_t version){
 unsigned slot=stream+second*16;assert(!(tensor_ready&(1U<<slot)));
 tensors[slot]=(AiTensorDeviceDescriptor){.tensor_addr=(second?0x31000000:0x30000000)+stream*YOLO32_INPUT_BYTES,
 .stream_id=stream,.frame_id=version*10+stream,.timestamp=mock_cycle,.version=version,.byte_count=YOLO32_INPUT_BYTES,.state=AI_TENSOR_DEVICE_READY};tensor_ready|=1U<<slot;
}
static void poll_n(unsigned n){while(n--){rt_poll();AiRtBackendResources r;live_resources(&r);saw_three|=r.activation_held==7;saw_overlap|=!r.activation_held&&r.owned_head;}}
static void assert_result(unsigned stream,uint32_t version){const AiDetectionResult *r=rt_latest_result(stream);assert(r&&r->stream_id==stream&&r->frame_id==version*10+stream&&r->version==version&&r->count==2&&(r->flags&AI_RESULT_HARDWARE_OVERLAY));}
static void test_patches(void){
 assert(!valid_input(0x30000001)&&!valid_input(0x32000000));
 for(unsigned d=0;d<3;d++)for(unsigned s=0;s<2;s++)for(unsigned slot=0;slot<32;slot++){
  uintptr_t addr=(slot<16?0x30000000:0x31000000)+(slot%16)*YOLO32_INPUT_BYTES;assert(valid_input(addr));
  bind_live_input(d,s,addr);
  for(unsigned i=0;i<input_patch_count[d][s];i++)assert(*input_patches[d][s][i].operand==AI_DDR_CPU_ALIAS(addr)+input_patches[d][s][i].offset);
  /* Check every command against the separately captured static-image table.
   * Only genuine input operands may differ; Head/ASRAM/weights stay exact. */
  struct Plan *p=&plans[d][s][0],*ref=&plans[d][s][1];
  for(unsigned i=0;i<p->count;i++){
   GfCommand expected=ref->commands[i];uint64_t *operands[]={&expected.rs1,&expected.rs2};
   for(unsigned j=0;j<2;j++){
    uintptr_t a=*operands[j],b=(uintptr_t)yolo32_inputs[1];
    if(a>=b&&a-b<YOLO32_INPUT_BYTES)*operands[j]=AI_DDR_CPU_ALIAS(addr)+(a-b);
   }
   assert(!memcmp(&expected,&p->commands[i],sizeof(expected)));
  }
 }
 yolo_check_guards();puts("LIVE_INPUT_PATCH_PASS tables=6 tensor_slots=32 native_math_preserved=1");
}
int main(int argc,char **argv){
 assert(rt_init()==0);test_patches();rt_set_enabled(1);assert(rt_is_enabled());
 if(argc>1&&(!strcmp(argv[1],"fault")||!strcmp(argv[1],"generation")||!strcmp(argv[1],"ppu_error"))){
  produce(15,1,1);poll_n(80);assert(releases==1&&result_write==1);
  inject=!strcmp(argv[1],"generation")?2:!strcmp(argv[1],"ppu_error")?3:1;deliver=1;poll_n(4);
  assert(rt_state()==AI_RT_STATE_FAULTED);AiRtBackendResources r;live_resources(&r);assert(r.owned_head&&r.unsafe_fault&&!live_idle());
  puts("LIVE_BAD_PPU_IDENTITY_PASS head_retained=1");return 0;
 }
 if(argc>1&&!strcmp(argv[1],"ppu_timeout")){
  produce(15,1,1);poll_n(80);assert(releases==1&&result_write==1);mock_cycle+=SOC_CLOCK_HZ*51;poll_n(4);
  assert(rt_state()==AI_RT_STATE_FAULTED&&!live_idle()&&releases==1);assert(head_queue.slots[0].state!=AI_HEAD_SLOT_FREE);
  puts("LIVE_PPU_TIMEOUT_PASS head_retained=1");return 0;
 }
 if(argc>1&&(!strcmp(argv[1],"frontend_fault")||!strcmp(argv[1],"frontend_timeout"))){
  produce(7,0,1);poll_n(1);assert(rt_core_instance()->tensors.held);
  if(!strcmp(argv[1],"frontend_timeout")){freeze_frontend=1;mock_cycle+=SOC_CLOCK_HZ*51;}else frontend_fault=1;
  poll_n(5);
  assert(rt_state()==AI_RT_STATE_FAULTED&&rt_core_instance()->tensors.held&&releases==0&&!live_idle());
  puts("LIVE_FRONTEND_FAULT_PASS tensor_and_head_retained=1");return 0;
 }
 if(argc>1&&!strcmp(argv[1],"input_masks")){
  active_inputs=0xff;poll_n(2);assert(rt_is_enabled()&&programmed_mask==0xff);
  deliver=1;
  for(unsigned version=1;version<=3;version++){
   for(unsigned stream=0;stream<8;stream++)produce(stream,version%2,version);
   poll_n(600);
  }
  AiRtStatus status;rt_get_status(&status);assert(status.completed_job_count==24&&!status.error_count);
  /* Lose inputs while jobs own Tensor/Head: restart only after retirement. */
  deliver=0;produce(2,0,4);poll_n(2);active_inputs=0x00fb;poll_n(100);
  assert(!rt_is_enabled()&&rt_state()==AI_RT_STATE_DRAINING&&!rt_is_idle());
  deliver=1;poll_n(100);assert(rt_is_enabled()&&programmed_mask==0x00fb);
  /* Hardware overlays expire even while Runtime remains logically enabled. */
  overlay_cleared=0;mock_cycle+=STREAM_RESULT_TTL+1;poll_n(20);
  assert(!rt_latest_result(2)&&(overlay_cleared&(1U<<2)));
  active_inputs=0xffff;poll_n(100);assert(rt_is_enabled()&&programmed_mask==0xffff);
  produce(15,1,5);poll_n(100);assert_result(15,5);
  /* Explicit stop cancels an automatic restart that is still draining. */
  deliver=0;produce(0,0,5);poll_n(2);active_inputs=0;poll_n(4);
  rt_set_enabled(0);deliver=1;poll_n(100);assert(rt_is_idle()&&!rt_is_enabled());
  rt_get_status(&status);assert(!status.error_count&&!unsafe_release);
  puts("LIVE_INPUT_MASK_PASS repeated_local_frames=24 missing_hdmi_excluded=1 hotplug_drain=1 ttl_clear=1 manual_stop=1");return 0;
 }
 /* All 16 producer identities use the actual scheduler, three lanes and both
  * physical Tensor pools. Delay the PPU to prove compute release separately. */
 for(unsigned s=0;s<16;s++)produce(s,s%2,1);
 poll_n(400);assert(saw_three&&saw_overlap&&unsafe_release==0);assert(result_write==6&&releases==6);
 for(unsigned d=0;d<3;d++)assert(head_queue.slots[d*2].state!=AI_HEAD_SLOT_FREE&&head_queue.slots[d*2+1].state!=AI_HEAD_SLOT_FREE);
 deliver=1;poll_n(1000);AiRtStatus status;rt_get_status(&status);assert(status.completed_job_count==16&&status.error_count==0);
 for(unsigned s=0;s<16;s++)assert_result(s,1);
 /* Exercise in-flight stop/drain, restart and same-stream version advance. */
 deliver=0;for(unsigned s=0;s<3;s++)produce(s,0,2);poll_n(2);rt_set_enabled(0);poll_n(80);assert(!rt_is_idle());
 deliver=1;poll_n(100);assert(rt_is_idle()&&tensor_ready==0&&unsafe_release==0);yolo_check_guards();
 rt_set_enabled(1);assert(rt_is_enabled());for(unsigned s=0;s<16;s++)produce(s,1-(s%2),3);poll_n(1000);
 for(unsigned s=0;s<16;s++)assert_result(s,3);
 rt_set_enabled(0);poll_n(100);assert(rt_is_idle());rt_get_status(&status);assert(!status.error_count);
 puts("LIVE_RUNTIME_PASS streams=16 workers=3 head_backpressure=1 compute_release_before_ppu=1 stop_drain_restart=1 hardware_executed=0");return 0;
}
