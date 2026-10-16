#ifndef __riscv
static void sw_p3_dump_inventory(const char *path) {
    char filename[1024];
    if(snprintf(filename,sizeof(filename),"%s.inventory.json",path)>=(int)sizeof(filename))at_fail("sw_p3_path",0);
    FILE *out=fopen(filename,"w");if(!out)at_fail("sw_p3_inventory_open",0);
    static char buffer[1<<20];
    if(setvbuf(out,buffer,_IOFBF,sizeof(buffer)))at_fail("sw_p3_inventory_buffer",0);
    fprintf(out,"{\"schema\":1,\"layout\":%u,\"tables\":[",sw_p3_layout);
    for(unsigned d=0;d<3;d++)for(unsigned s=0;s<2;s++)for(unsigned image=0;image<3;image++) {
        struct Plan *p=&plans[d][s][image];
        fprintf(out,"%s{\"lane\":%u,\"slot\":%u,\"image\":%u,\"commands\":[",(d||s||image)?",":"",d,s,image);
        for(unsigned i=0;i<p->count;i++) {
            GfCommand c=normalize(p->commands[i],d,s,image);
            fprintf(out,"%s[%u,\"%016llx\",\"%016llx\",\"%016llx\",\"%016llx\"]",i?",":"",sw_p3_phase_ids[i],
                (unsigned long long)c.control,(unsigned long long)c.rs1,(unsigned long long)c.rs2,(unsigned long long)c.reserved);
        }
        fprintf(out,"],\"hosts\":[");
        for(unsigned i=0;i<p->host_count;i++) {
            struct Host *h=&p->hosts[i];
            fprintf(out,"%s[%u,%u,%u,%d,%d,%d,\"%016llx\",\"%016llx\"]",i?",":"",h->kind,h->phase,h->head,h->h,h->w,h->c,
                (unsigned long long)normalized_address((uintptr_t)h->src,d,s,image,0),
                (unsigned long long)normalized_address((uintptr_t)h->dst,d,s,image,1));
        }
        worker_contexts[d].input=yolo32_inputs[image];worker_contexts[d].head_slot=(int8_t *)head_address(d,s);
        yolo32_batch_bind_start(d);
        fprintf(out,"],\"bindings\":[");
        for(unsigned i=0;i<58;i++) {
            struct yolo32_conv_binding *b=&batch_conv_bindings[d][i];
            fprintf(out,"%s[\"%016llx\",\"%016llx\",\"%016llx\",\"%016llx\"]",i?",":"",
                (unsigned long long)normalized_address((uintptr_t)b->input,d,s,image,0),
                (unsigned long long)normalized_address((uintptr_t)b->weights,d,s,image,0),
                (unsigned long long)normalized_address((uintptr_t)b->bias,d,s,image,0),
                (unsigned long long)normalized_address((uintptr_t)b->output,d,s,image,1));
        }
        fprintf(out,"]}");
    }
    fprintf(out,"]}\n");fclose(out);
}
#else
#include "sw_p3_identity.inc"
static const char *const sw_p3_profiles[]={"reference","layout","cache_plan","cache_plan_gate"};
static struct PpuResult sw_p3_reference[FRAMES];
/* Called at admission; matched replays the actual parallel image->lane map.
 * Each lane's standalone 12-frame run is also recorded, outside formal ratio. */
static unsigned sw_p3_serial_device(unsigned frame) {
    return sw_p3_matched?sw_p3_replay_lane[frame]:sw_p3_serial_lane;
}
static void sw_p3_result_check(unsigned reference) {
    for(unsigned f=0;f<FRAMES;f++) {
        struct PpuResult *r=&output[executor][f];
        if(reference)sw_p3_reference[f]=*r;
        else if(memcmp(r,&sw_p3_reference[f],sizeof(*r)))at_fail("sw_p3_full40_result_mismatch",f);
    }
    sw_p3_guards_check();
}
static uint64_t sw_p3_run(unsigned pass,unsigned profile,unsigned mode,unsigned lane,unsigned matched) {
    executor=mode;sw_p3_serial_lane=lane;sw_p3_matched=matched;
    sw_p3_gate_enabled=profile==3&&mode!=0;
    prepare_batch();batch_begin=clock_cycle();
    if(mode)parallel_batch(mode==2?3:1);else serial_batch();
    uint64_t elapsed=clock_cycle()-batch_begin;
    if(completed!=FRAMES||host_calls!=FRAMES*12||(mode&&launches!=FRAMES))at_fail("sw_p3_batch_incomplete",completed);
    for(unsigned d=0;d<3;d++) {
        unsigned expected=mode==2||matched?4:(d==lane?12:0);
        if(use[d]!=expected)at_fail("sw_p3_lane_quota",d);
    }
    if(mode==2)for(unsigned f=0;f<FRAMES;f++)sw_p3_replay_lane[f]=frames[f].device;
    sw_p3_result_check(pass==0&&profile==0&&mode==0);
    text("SWP3,RUN,pass=");number(pass);field(",profile=",profile);field(",mode=",mode);
    field(",serial_lane=",lane);field(",matched=",matched);field(",cycles=",elapsed);
    field(",frames=",FRAMES);field(",device0_frames=",use[0]);field(",device1_frames=",use[1]);field(",device2_frames=",use[2]);
    field(",run_id=",sw_p3_run_id);field(",host_calls=",host_calls);field(",launches=",launches);
    field(",gate_count=",sw_p3_gate_count);field(",gate_wait=",sw_p3_gate_wait);field(",gate_max=",sw_p3_gate_max);
    field(",gate_timeouts=",sw_p3_gate_timeouts);field(",gate_peak=",sw_p3_gate_peak);
    text(",result40=PASS,cache=warm_order_controlled\n");
    for(unsigned f=0;f<FRAMES;f++) {
        text("SWP3,FRAME,pass=");number(pass);field(",profile=",profile);field(",mode=",mode);
        field(",serial_lane=",lane);field(",matched=",matched);field(",frame=",f);
        field(",lane=",frames[f].device);field(",image=",frames[f].image);
        field(",begin=",frames[f].begin-batch_begin);field(",end=",frames[f].end-batch_begin);
        text("\n");
    }
    return elapsed;
}
static int sw_p3_suite(void) {
    const unsigned profile_count=SW_P3_COMPARE?4:1;
    text("SWP3,BUILD,schema=1,frames=12,profiles=");number(profile_count);
    text(",passes=2,gate_default=off,default_profile=reference,hardware_identity=download_manifest_declared\n");
#if SW_P3_COMPARE
    text("SWP3,MODE,build=compare\n");
#else
    text("SWP3,MODE,build=reference\n");
#endif
    text("SWP3,IDENTITY,");text(SW_P3_IDENTITY);text("\n");
    ppu_init();sw_p3_run_id=0;
    for(unsigned pass=0;pass<2;pass++)for(unsigned step=0;step<profile_count;step++) {
        unsigned p=pass?profile_count-1-step:step;
        text("SWP3,PROFILE,id=");number(p);text(",name=");text(sw_p3_profiles[p]);field(",pass=",pass);
        text(",plan_hash=");text(p>=2?SW_P3_CANDIDATE_PLAN_SHA:SW_P3_REFERENCE_PLAN_SHA);text("\n");
        sw_p3_tiling_enabled=p>=2;sw_p3_set_layout(p!=0);prepare_model();
        /* Identical initialization policy in every profile; no candidate-only warmup. */
        sw_p3_run(pass,p,0,0,0);
        uint64_t serial=sw_p3_run(pass,p,1,0,0);
        uint64_t parallel=sw_p3_run(pass,p,2,0,0);
        sw_p3_run(pass,p,1,1,0);sw_p3_run(pass,p,1,2,0);sw_p3_run(pass,p,1,0,1);
        text("SWP3,METRIC,pass=");number(pass);field(",profile=",p);
        field(",serial=",serial);field(",parallel=",parallel);
        field(",scaling_x1000=",parallel?serial*1000/parallel:0);
        field(",efficiency_x1000=",parallel?serial*1000/(3*parallel):0);text("\n");
    }
    text("SWP3,PASS,schema=1,profiles=");number(profile_count);
    text(",passes=2,result40=bit_exact,marker=ALL_COMPLETE\n");
    for(;;)__asm__ volatile("wfi");
    return 0;
}
#endif
