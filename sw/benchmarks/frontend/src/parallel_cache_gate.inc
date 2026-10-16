/* HOST is served exactly once before RESUME admission. A pending HOST keeps
 * its existing event; no ACK, publication or host_next increment is repeated. */
struct SwP3GateLane {unsigned pending,tag,active,deferred,frame;uint64_t since,deadline;};
static struct SwP3GateLane sw_p3_gate[3];
static unsigned sw_p3_gate_enabled;
static uint64_t sw_p3_gate_count,sw_p3_gate_wait,sw_p3_gate_max,sw_p3_gate_timeouts;
static unsigned sw_p3_gate_peak;
static void sw_p3_gate_reset(void) {
    memset(sw_p3_gate,0,sizeof(sw_p3_gate));
    sw_p3_gate_count=sw_p3_gate_wait=sw_p3_gate_max=sw_p3_gate_timeouts=sw_p3_gate_peak=0;
}
static unsigned sw_p3_gate_active(void) {
    unsigned n=0;for(unsigned d=0;d<3;d++)n+=sw_p3_gate[d].active!=0;return n;
}
static void sw_p3_gate_observed(unsigned d,unsigned tag) {
    /* These HOSTs follow the native local completion boundaries. */
    if((tag==8&&sw_p3_gate[d].active==7)||(tag==10&&sw_p3_gate[d].active==9))sw_p3_gate[d].active=0;
}
static void sw_p3_gate_served(unsigned d,unsigned tag,uint64_t now) {
    sw_p3_gate[d].pending=1;sw_p3_gate[d].tag=tag;sw_p3_gate[d].since=now;
    sw_p3_gate[d].frame=current_frame;sw_p3_gate[d].deadline=now+16000;
    sw_p3_gate[d].deferred=sw_p3_gate_enabled&&(tag==7||tag==9)&&sw_p3_gate_active()>=2;
    if(sw_p3_gate[d].deferred)sw_p3_gate_count++;
}
static unsigned sw_p3_gate_ready(unsigned d,uint64_t now) {
    struct SwP3GateLane *p=&sw_p3_gate[d];
    return !sw_p3_gate_enabled||(p->tag!=7&&p->tag!=9)||sw_p3_gate_active()<2||now-p->since>=16000;
}
static void sw_p3_gate_resumed(unsigned d,uint64_t now) {
    struct SwP3GateLane *p=&sw_p3_gate[d];
    if(sw_p3_gate_enabled&&(p->tag==7||p->tag==9)) {
        uint64_t wait=now-p->since;
        if(p->deferred) {
            sw_p3_gate_wait+=wait;
            if(wait>sw_p3_gate_max)sw_p3_gate_max=wait;
            if(sw_p3_gate_active()>=2&&wait>=16000)sw_p3_gate_timeouts++;
        }
        p->active=p->tag;
        unsigned active=sw_p3_gate_active();if(active>sw_p3_gate_peak)sw_p3_gate_peak=active;
    }
    p->pending=0;
}
