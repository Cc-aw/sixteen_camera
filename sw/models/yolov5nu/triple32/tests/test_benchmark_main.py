"""Run the real command/benchmark loop with a deterministic host model double.
This verifies scheduling, reference lifetime and log boundaries, not hardware math.
"""
from pathlib import Path
import shutil
import subprocess
import sys
import tempfile
import unittest

HERE = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(HERE))
from analyze_log import parse


class BenchmarkMainTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.tmp = tempfile.TemporaryDirectory(prefix='yolo32-bench-main-')
        root = Path(cls.tmp.name)
        source = root/'triple32'
        source.mkdir()
        (root/'dim16_dual').mkdir()
        for name in ('main.c', 'yolo32.h', 'compare.c', 'ppu.h', 'independent.h', 'task_context_config.h'):
            shutil.copy(HERE/name, source/name)
        for name in ('yolov5nu_dim16_dual.h', 'yolov5nu_head_layout.h'):
            shutil.copy(HERE/'native'/name, source/name)
        (source/'inputs.h').write_text('#include <stdint.h>\n#define YOLO32_INPUT_BYTES 3\nextern const int8_t yolo32_inputs[3][3];\nextern const char *const yolo32_image_ids[3];\n')
        (source/'platform.h').write_text('#define SOC_CLOCK_HZ 100000000UL\n')
        (source/'mmio.h').write_text('#include <stdint.h>\nextern uint64_t host_cycle;\nstatic inline uint64_t read_cycle(void) { return ++host_cycle; }\n')
        (source/'console.h').write_text('void console_init(void); void console_puts(const char*); void console_putc(char); void console_put_u32(unsigned); void console_put_hex64(unsigned long); int console_getc_nonblock(void);\n')
        (source/'fake.c').write_text(r'''
#include <assert.h>
#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include "yolo32.h"
#include "ppu.h"
#include "inputs.h"
#include "independent.h"
uint64_t host_cycle;
const int8_t yolo32_inputs[3][3]={{1,2,3},{4,5,6},{7,8,9}};
const char *const yolo32_image_ids[3]={"025","036","142"};
static unsigned active[3], ready[3], finished[3], analysis, grouped;
static int8_t heads[3][YOLOV5NU_HEAD_PAYLOAD_BYTES];
static Yolo32PpuResult results[3];
static Yolo32ParallelStats stats;
static Yolo32IndependentStats independent_stats;
#if YOLO32_PPU_EARLY
static Yolo32PpuEarlyStats early;
static uint64_t early_base;
static unsigned early_analysis;
#if YOLO32_PPU_HEAD_CLEAN
static Yolo32PpuHeadStats head_stats;
const Yolo32PpuHeadStats *yolo32_ppu_head_stats(void){return &head_stats;}
#endif
void yolo32_ppu_early_begin(uint64_t base,unsigned a){
 memset(&early,0,sizeof(early));early_base=base;early_analysis=a;
#if YOLO32_PPU_HEAD_CLEAN
 memset(&head_stats,0,sizeof(head_stats));
#endif
}
void yolo32_ppu_early_service(void){
 ++early.service_calls;
 for(unsigned w=0;w<3;w++)if((independent_stats.done_mask&(1U<<w))&&!(early.published_mask&(1U<<w))){
   Yolo32PpuEvent *e=&early.workers[w];e->graph_done_cycle=independent_stats.graph_done_cycle[w];
   #if YOLO32_PPU_HEAD_CLEAN
   e->publication_cycle=head_stats.heads[w][2].publication_cycle;
   head_stats.published_heads[w]=63;head_stats.ready_at_finish[w]=63;head_stats.allocated_at_finish[w]=1;
   head_stats.finish_sample_cycle[w]=++host_cycle;head_stats.publication_transactions+=6;
   e->enqueue_cycle=YOLO32_PPU_HEAD_ADMIT?head_stats.heads[w][0].publication_cycle:++host_cycle;
   e->enqueue_done_mask=independent_stats.done_mask & (YOLO32_PPU_HEAD_ADMIT?~(1U<<w):7U);
#else
   e->publication_cycle=++host_cycle;e->enqueue_cycle=++host_cycle;
   e->enqueue_done_mask=independent_stats.done_mask;
#endif
   early.published_mask|=1U<<w;early.enqueued_mask|=1U<<w;
   yolo32_ppu_graph_done(w);e->result_cycle=host_cycle;e->result_done_mask=independent_stats.done_mask;
   early.result_mask|=1U<<w;
   if(early_analysis&&independent_stats.done_mask!=7){
     e->progress_cycle=e->enqueue_cycle;e->progress_done_mask=e->enqueue_done_mask;
     early.progress_mask|=1U<<w;
   }
 }
}
const Yolo32PpuEarlyStats *yolo32_ppu_early_stats(void){assert(early_base&&early.result_mask==7);return &early;}
#endif
#if YOLO32_ROCC_LAYERS
static Yolo32TaskStage task_stage={1000,2000};
#else
static Yolo32TaskStage task_stage={1,2};
#endif
void console_init(void) {}
void console_puts(const char *s) { assert(!active[0]&&!active[1]&&!active[2]);fputs(s,stdout); }
void console_putc(char c) { putchar(c); }
void console_put_u32(unsigned v) { printf("%u",v); }
void console_put_hex64(unsigned long v) { printf("0x%016lX",v); }
int console_getc_nonblock(void) { static unsigned at;const char *c=getenv("COMMANDS");if(!c)c="a";if(c[at])return c[at++];exit(0); }
void yolo32_init(void) {}
void yolo32_set_head_callback(void (*c)(unsigned,unsigned)) { assert(c==yolo32_ppu_head); }
void yolo32_set_analysis(unsigned a) { analysis=a;grouped=0; }
const Yolo32CommandStats *yolo32_command_stats(unsigned w,unsigned f) {
 static const Yolo32CommandStats conv={500,500,1},matmul={10,10,1},none={0,0,0};
 (void)w;return f==15?&conv:(f==8||f==11)?&matmul:&none;
}
const Yolo32LayerCommandStats *yolo32_layer_command_stats(unsigned w,unsigned stage,unsigned f) {
 static const Yolo32LayerCommandStats conv={.count=500,.cycles=500,.max_cycles=1,.max_index=1};
 static const Yolo32LayerCommandStats split={.count=10,.cycles=10,.max_cycles=1,.max_index=1},none={0};
 (void)w;return f==15&&stage==0?&conv:f==11&&stage==2?&split:&none;
}
void yolo32_ppu_init(void) {}
uintptr_t yolo32_ppu_begin(unsigned w,uint64_t run) { assert(run);finished[w]=0;return (uintptr_t)heads[w]; }
int yolo32_start_hardware(unsigned w,const int8_t *input,uintptr_t head) {
 assert(input==yolo32_inputs[w] && head==(uintptr_t)heads[w] && !active[w]);active[w]=1;ready[w]=0;host_cycle+=10;return YOLOV5NU_DIM16_RUNNING;
}
int yolo32_graph_poll(unsigned w,Yolo32Result *r) { (void)r;assert(active[w]);active[w]=0;ready[w]=1;host_cycle+=grouped?5:100;return YOLOV5NU_DIM16_HEAD_READY; }
/* Explicitly fail if the firmware invokes legacy CPU postprocessing. */
int yolo32_poll(unsigned w,Yolo32Result *r) { (void)w;(void)r;abort(); }
void yolo32_finish_hardware(unsigned w) { assert(ready[w]);ready[w]=0; }
void yolo32_ppu_head(unsigned w,unsigned h) { (void)w;(void)h;if(grouped==2)assert(!active[0]&&!active[1]&&!active[2]); }
void yolo32_ppu_service(void) {}
void yolo32_ppu_graph_done(unsigned w) {
 yolo32_finish_hardware(w);host_cycle+=30;unsigned value=w+1;
 if(grouped&&getenv("CORRUPT")&&w==2)value+=10;
 memset(heads[w],value,sizeof(heads[w]));memset(&results[w],0,sizeof(results[w]));
 results[w].count=1;results[w].words[0][0]=value;results[w].words[0][1]=value+1;
 results[w].words[0][2]=(w<<16)|1234;results[w].core_cycles=20;
 results[w].wall_cycles=30;results[w].completed_cycle=host_cycle;finished[w]=1;
}
unsigned yolo32_ppu_done(unsigned w) { return finished[w]; }
const Yolo32PpuResult *yolo32_ppu_result(unsigned w) { return &results[w]; }
const int8_t *yolo32_raw_heads(unsigned w) { assert(finished[w]);return heads[w]; }
void yolo32_parallel_begin(void) {
 grouped=1;memset(&stats,0,sizeof(stats));stats.conv_groups=58;
 stats.tile_groups=stats.requests[0]=stats.requests[1]=stats.requests[2]=500;
 if(analysis){stats.overlap_samples=20;stats.triple_overlap_samples=10;stats.busy_mask_seen=7;}
}
int yolo32_parallel_step(Yolo32Result r[3]) { (void)r;host_cycle+=80;return 1; }
const Yolo32ParallelStats *yolo32_parallel_stats(void) { return &stats; }
void yolo32_independent_begin(unsigned a) {
 assert(a==analysis);grouped=2;memset(&independent_stats,0,sizeof(independent_stats));
#if !YOLO32_PPU_EARLY
 independent_stats.done_mask=7;
#endif
 independent_stats.command_yields=87;independent_stats.packet_yields=87;
 independent_stats.command_kept=1443;independent_stats.stage_kept=495;
 independent_stats.max_quantum_packets=2;
 independent_stats.feedback_commands=1530;independent_stats.feedback_cycles=1530;
 independent_stats.dispatch_max_cycles=1;
 for(unsigned w=0;w<3;w++){independent_stats.conv_requests[w]=500;independent_stats.matmul_requests[w]=10;independent_stats.resumes[w]=30;}
 if(!YOLO32_SCHED_ADAPTIVE){independent_stats.feedback_commands=0;independent_stats.feedback_cycles=0;independent_stats.dispatch_max_cycles=0;}
 if(YOLO32_TAIL_WAIT){
   independent_stats.tail_deferred=independent_stats.tail_wait_merges=6;
   independent_stats.tail_conv_merges=independent_stats.tail_ws_merges=3;
   independent_stats.wait_yields=6;
   for(unsigned w=0;w<3;w++)independent_stats.resumes[w]=32;
 }
 if(a){for(unsigned w=0;w<3;w++){independent_stats.task_wall_cycles[w]=1000;independent_stats.context_cycles[w]=10;}
 independent_stats.step_cycles=3100;independent_stats.scheduler_cycles=100;independent_stats.ready_cycles=30;
 independent_stats.ready_checks=7;independent_stats.ready_blocked=5;independent_stats.idle_steps=2;
 independent_stats.switch_cycles=30;independent_stats.switch_count=180;}
 if(a&&YOLO32_TAIL_WAIT)independent_stats.switch_count=192;
 if(a){independent_stats.ahead_submissions=1;independent_stats.overlap_samples=20;
 independent_stats.triple_overlap_samples=10;independent_stats.busy_mask_seen=7;
 independent_stats.trace_count=1;independent_stats.traces[0].worker=1;
 independent_stats.traces[0].busy_mask=7;independent_stats.traces[0].stages[1]=2;}
}
int yolo32_independent_step(void) {
#if YOLO32_PPU_EARLY
 static const unsigned order[3]={2,0,1};
 unsigned count=!!(independent_stats.done_mask&1)+!!(independent_stats.done_mask&2)+!!(independent_stats.done_mask&4);
 unsigned w=order[count];assert(active[w]);active[w]=0;ready[w]=1;host_cycle+=1400;
 #if YOLO32_PPU_HEAD_CLEAN
 static const unsigned order_h[6]={3,0,4,1,5,2},req[6]={100,200,300,400,450,500};
 for(unsigned i=0;i<6;i++){
   Yolo32PpuHeadEvent *h=&head_stats.heads[w][order_h[i]];
   h->completed_cycle=host_cycle-700+i*10;h->publication_cycle=h->completed_cycle+1;
   h->ready_cycle=analysis?h->publication_cycle+1:0;h->requests=req[i];
 }
#endif
 independent_stats.done_mask|=1U<<w;independent_stats.graph_done_cycle[w]=++host_cycle;
 yolo32_ppu_early_service();return independent_stats.done_mask==7;
#else
 for(unsigned w=0;w<3;w++){assert(active[w]);active[w]=0;ready[w]=1;}host_cycle+=4000;return 1;
#endif
}
void yolo32_independent_end(void) { assert(!active[0]&&!active[1]&&!active[2]); }
unsigned yolo32_independent_head_mask(unsigned w) { (void)w;return 63; }
const Yolo32IndependentStats *yolo32_independent_stats(void) { return &independent_stats; }
const Yolo32TaskStage *yolo32_independent_stage(unsigned w,unsigned s) { (void)w;(void)s;return &task_stage; }
uint64_t yolo32_stage_cycles(unsigned s) { return s+1; }
const char *yolo32_stage_kind(unsigned s) { (void)s;return "conv"; }
const char *yolo32_stage_label(unsigned s) { (void)s;return "test_layer"; }
uint64_t yolo32_parallel_submit_cycles(void) { return 10; }
uint64_t yolo32_parallel_wait_cycles(void) { return 20; }
int yolo32_profile(unsigned w,struct yolov5nu_dim16_profile *p) { (void)w;memset(p,0,sizeof(*p));return 0; }
void yolo32_fail(const char *s) { fprintf(stderr,"FAIL: %s\n",s);exit(42); }
''')
        cls.exe = root/'main-test'
        subprocess.run(['gcc', '-std=c11', '-O2', '-Wall', '-Wextra', '-Werror',
                        '-DYOLOV5NU_DIM16_WORKER_COUNT=3U', str(source/'main.c'),
                        str(source/'compare.c'), str(source/'fake.c'), '-o', str(cls.exe)],
                       check=True, capture_output=True)

        cls.layer_exe=root/'layer-main-test'
        subprocess.run(['gcc', '-std=c11', '-O2', '-Wall', '-Wextra', '-Werror',
                        '-DYOLOV5NU_DIM16_WORKER_COUNT=3U', '-DYOLO32_ROCC_LAYERS=1',
                        str(source/'main.c'), str(source/'compare.c'), str(source/'fake.c'),
                        '-o',str(cls.layer_exe)],check=True,capture_output=True)
        cls.scheduled_exe=root/'scheduled-main-test'
        subprocess.run(['gcc','-std=c11','-O2','-Wall','-Wextra','-Werror',
            '-DYOLOV5NU_DIM16_WORKER_COUNT=3U','-DYOLO32_FIXED_PLANS=1','-DYOLO32_FIXED_PACKETS=1',
            '-DYOLO32_IDLE_PRIORITY=1','-DYOLO32_TAIL_WAIT=1','-DYOLO32_SCHED_ADAPTIVE=0',
            str(source/'main.c'),str(source/'compare.c'),str(source/'fake.c'),'-o',str(cls.scheduled_exe)],
            check=True,capture_output=True)
        cls.prepared_exe=root/'prepared-main-test'
        subprocess.run(['gcc','-std=c11','-O2','-Wall','-Wextra','-Werror',
            '-DYOLOV5NU_DIM16_WORKER_COUNT=3U','-DYOLO32_FIXED_PLANS=1','-DYOLO32_FIXED_PACKETS=1',
            '-DYOLO32_IDLE_PRIORITY=1','-DYOLO32_TAIL_WAIT=1','-DYOLO32_SCHED_ADAPTIVE=0',
            '-DYOLO32_PREPARED_PACKETS=1',
            str(source/'main.c'),str(source/'compare.c'),str(source/'fake.c'),'-o',str(cls.prepared_exe)],
            check=True,capture_output=True)
        cls.early_exe=root/'early-main-test'
        subprocess.run(['gcc','-std=c11','-O2','-Wall','-Wextra','-Werror',
            '-DYOLOV5NU_DIM16_WORKER_COUNT=3U','-DYOLO32_FIXED_PLANS=1','-DYOLO32_FIXED_PACKETS=1',
            '-DYOLO32_IDLE_PRIORITY=1','-DYOLO32_TAIL_WAIT=1','-DYOLO32_SCHED_ADAPTIVE=0',
            '-DYOLO32_PREPARED_PACKETS=1','-DYOLO32_PPU_EARLY=1',
            str(source/'main.c'),str(source/'compare.c'),str(source/'fake.c'),'-o',str(cls.early_exe)],
            check=True,capture_output=True)


        cls.head_exe={}
        for mode in (0,1):
            exe=root/f'head-main-{mode}'
            subprocess.run(['gcc','-std=c11','-O2','-Wall','-Wextra','-Werror',
                '-DYOLOV5NU_DIM16_WORKER_COUNT=3U','-DYOLO32_FIXED_PLANS=1','-DYOLO32_FIXED_PACKETS=1',
                '-DYOLO32_IDLE_PRIORITY=1','-DYOLO32_TAIL_WAIT=1','-DYOLO32_SCHED_ADAPTIVE=0',
                '-DYOLO32_PREPARED_PACKETS=1','-DYOLO32_PPU_EARLY=1','-DYOLO32_PPU_HEAD_CLEAN=1',
                f'-DYOLO32_PPU_HEAD_ADMIT={mode}',str(source/'main.c'),str(source/'compare.c'),str(source/'fake.c'),
                '-o',str(exe)],check=True,capture_output=True)
            cls.head_exe[mode]=exe

    @classmethod
    def tearDownClass(cls):
        cls.tmp.cleanup()

    def invoke(self, commands, corrupt=False, layers=False, scheduled=False, prepared=False, early=False, head=None):
        import os
        env = dict(os.environ, COMMANDS=commands)
        if corrupt:
            env['CORRUPT']='1'
        exe=self.early_exe if early else self.prepared_exe if prepared else self.scheduled_exe if scheduled else self.layer_exe if layers else self.exe
        if head is not None:exe=self.head_exe[head]
        result = subprocess.run([exe], env=env, check=True, text=True, capture_output=True)
        return result.stdout

    def test_early_ppu_benchmark_and_manual_logs(self):
        for commands in ('a','t','p','0uUt'):
            with self.subTest(commands=commands):
                log=self.invoke(commands,early=True)
                errors,runs=parse(log)
                self.assertEqual(errors,[],log[-4000:])
                self.assertIn('YOLO32_FIRMWARE v16',log)
                self.assertTrue(all(r['ppu_early']==1 for r in runs))
                for r in runs:
                    if r['mode']=='independent':
                        self.assertEqual(set(r['ppu_events']),{0,1,2})
                        self.assertEqual(int(r['ppu_events'][2]['enqueue_done_mask'],0),4)
                    else:self.assertFalse(r['ppu_events'])
        self.assertIn('Use download.sh --ppu-early-rocc',self.invoke('q',early=True))

    def test_early_ppu_log_rejects_missing_duplicate_and_false_overlap(self):
        log=self.invoke('p',early=True)
        event=next(l for l in log.splitlines() if l.startswith('YOLO32_PPU_EVENT '))
        summary=next(l for l in log.splitlines() if l.startswith('YOLO32_PPU_EARLY '))
        for old,new in ((event,''),(event,event+'\n'+event),(summary,''),(summary,summary+'\n'+summary),
                        ('ppu_early=0x0000000000000001','ppu_early=2'),
                        ('published_mask=0x0000000000000007','published_mask=3'),
                        ('enqueue_done_mask=0x0000000000000005','enqueue_done_mask=7'),
                        ('progress_done_mask=0x0000000000000005','progress_done_mask=7'),
                        ('progress_sampling=0x0000000000000001','progress_sampling=0')):
            with self.subTest(field=old):
                self.assertIn(old,log)
                self.assertTrue(parse(log.replace(old,new,1))[0])
        self.assertTrue(parse(log+'\n'+event)[0])
        # Removing both the flag and every new record must not downgrade v16
        # into a valid historical prepared-packets log.
        stripped='\n'.join(l.replace(' ppu_early=0x0000000000000001','') for l in log.splitlines()
                           if not l.startswith(('YOLO32_PPU_EVENT ','YOLO32_PPU_EARLY ')))
        self.assertTrue(parse(stripped)[0])

    def test_early_ppu_reports_are_separate_from_prepared_baseline(self):
        import contextlib,io
        from analyze_log import report
        log=self.invoke('a',prepared=True)+'\n'+self.invoke('a',early=True)
        errors,runs=parse(log)
        self.assertEqual(errors,[])
        self.assertEqual({r['ppu_early'] for r in runs},{0,1})
        output=io.StringIO()
        with contextlib.redirect_stdout(output):report(runs)
        self.assertIn('ppu_early=0',output.getvalue())
        self.assertIn('ppu_early=1',output.getvalue())
        self.assertIn('publication_delay_cycles=',output.getvalue())


    def test_head_variants_real_main_benchmark_and_profiles(self):
        for mode in (0,1):
            for command in ('a','p','0uUt'):
                with self.subTest(mode=mode,command=command):
                    log=self.invoke(command,head=mode);errors,runs=parse(log)
                    self.assertEqual(errors,[],log[-2000:])
                    self.assertIn('YOLO32_FIRMWARE v17',log)
                    for r in runs:
                        self.assertEqual(r['head_clean'],1);self.assertEqual(r['head_admit'],mode)
                        if r['mode']=='independent':self.assertEqual(len(r['head_events']),18)
            self.assertIn('--ppu-head-'+('class0' if mode else 'clean')+'-rocc',self.invoke('q',head=mode))

    def test_head_event_missing_duplicate_order_and_flags_are_rejected(self):
        for mode in (0,1):
            log=self.invoke('p',head=mode)
            event=next(l for l in log.splitlines() if l.startswith('YOLO32_HEAD_EVENT '))
            state=next(l for l in log.splitlines() if l.startswith('YOLO32_HEAD_STATE '))
            summary=next(l for l in log.splitlines() if l.startswith('YOLO32_HEAD_CLEAN '))
            for old,new in ((event,''),(event,event+'\n'+event),(state,''),(summary,''),
                            ('stage=0x000000000000007C requests=','stage=125 requests='),
                            ('published_heads=0x000000000000003F','published_heads=31'),
                            ('head_clean=0x0000000000000001','head_clean=0'),
                            ('publication_transactions=0x0000000000000012','publication_transactions=19')):
                with self.subTest(mode=mode,field=old):
                    self.assertIn(old,log);self.assertTrue(parse(log.replace(old,new,1))[0])
            self.assertTrue(parse(log+'\n'+event)[0])
            # Ready observations are diagnostic, bounded by publication/result;
            # conv retirement checkpoints must agree with native head order.
            values=dict(token.split('=',1) for token in event.split()[1:])
            for key,value in (('requests','0'),('completed_cycles','-1'),
                              ('publication_commit_cycles','1'),('ready_observed_cycles','1')):
                bad=event.replace(f'{key}={values[key]}',f'{key}={value}')
                self.assertTrue(parse(log.replace(event,bad,1))[0])

    def test_reports_keep_complete_graph_and_class0_policies_separate(self):
        import contextlib,io
        from analyze_log import report
        errors,runs=parse(self.invoke('a',head=0)+'\n'+self.invoke('a',head=1))
        self.assertEqual(errors,[])
        output=io.StringIO()
        with contextlib.redirect_stdout(output):report(runs)
        self.assertIn('head_admit=0',output.getvalue());self.assertIn('head_admit=1',output.getvalue())

    def test_prepared_benchmark_configuration_and_diagnostic_entry(self):
        self.assertIn('Use download.sh --prepared-packets-rocc',self.invoke('q',prepared=True))
        log=self.invoke('a',prepared=True)
        errors,runs=parse(log)
        self.assertEqual(errors,[])
        self.assertEqual(len(runs),36)
        self.assertIn('YOLO32_FIRMWARE v15',log)
        self.assertTrue(all(r['prepared_packets']==1 for r in runs))
        for replacement in ('prepared_packets=2','prepared_packets=1 fixed_packets=0'):
            self.assertTrue(parse(log.replace('prepared_packets=0x0000000000000001',replacement))[0])
        # A forged run flag must not silently change the boot-selected backend.
        run_flag='prepared_packets=0x0000000000000001 context=light scheduling=fixed'
        self.assertIn(run_flag,log)
        self.assertTrue(parse(log.replace(run_flag,'prepared_packets=0 context=light scheduling=fixed',1))[0])

    def test_scheduled_packet_benchmark_and_tail_records(self):
        guidance = self.invoke('q', scheduled=True)
        self.assertIn('Use download.sh --scheduled-packets-rocc', guidance)
        self.assertNotIn('YOLO32_BEGIN ', guidance)
        log=self.invoke('a',scheduled=True)
        errors,runs=parse(log)
        self.assertEqual(errors,[])
        self.assertEqual(len(runs),36)
        self.assertIn('YOLO32_FIRMWARE v14',log)
        self.assertTrue(all(r['idle_priority']==1 and r['tail_wait']==1 for r in runs))
        self.assertTrue(all('tail' in r for r in runs if r['mode']=='independent'))
        original='YOLO32_TAIL_WAIT deferred=0x0000000000000006 merges=0x0000000000000006 conv=0x0000000000000003 ws=0x0000000000000003'
        self.assertIn(original,log)
        for replacement in ('',original+'\n'+original,original.replace('merges=0x0000000000000006','merges=5'),
                            original.replace('conv=0x0000000000000003','conv=0')):
            with self.subTest(replacement=replacement):
                self.assertTrue(parse(log.replace(original,replacement,1))[0])
        self.assertTrue(parse(log.replace('tail_wait=0x0000000000000001','tail_wait=0'))[0])

    def test_real_automatic_loop_and_summaries(self):
        log = self.invoke('a')
        errors, runs = parse(log)
        self.assertEqual(errors, [])
        self.assertEqual(len(runs), 36)
        self.assertIn('YOLO32_BENCH_RESULT PASS', log)

    def test_manual_commands_share_a_persistent_reference(self):
        log = self.invoke('0utUbl')
        errors, runs = parse(log)
        self.assertEqual(errors, [])
        self.assertEqual([r['mode'] for r in runs], ['forward','forward','independent','reverse','blocked','parallel'])
        self.assertEqual(sum(r['phase']=='baseline' for r in runs),1)

    def test_context_mode_is_recorded_and_validated(self):
        log = self.invoke('t')
        errors, runs = parse(log)
        self.assertEqual(errors, [])
        self.assertTrue(all(r['context']=='light' for r in runs))
        self.assertIn('context=light vcsr=preserved', log)
        self.assertIn('saved_bytes=0x00000000000000E0', log)
        self.assertEqual(parse(log.replace('context=light','context=full'))[0], [])
        self.assertTrue(parse(log.replace('context=light','context=unknown'))[0])

    def test_parallel_corruption_is_not_hidden_by_arena_reuse(self):
        log = self.invoke('a', corrupt=True)
        errors, _ = parse(log)
        self.assertTrue(errors)
        self.assertIn('YOLO32_RESULT FAIL reason=serial_mismatch',log)
        self.assertIn('YOLO32_BENCH_RESULT FAIL',log)

    def test_v5_requires_independent_progress_and_five_complete_modes(self):
        log = self.invoke('a')
        for old, new in [('modes=5', 'modes=4'), ('ahead_submissions=0x0000000000000001', 'ahead_submissions=0'),
                         ('INDEPENDENT_RESULT PASS', 'INDEPENDENT_RESULT FAIL'),
                         ('YOLO32_TASK_STAGE worker=0x0000000000000002 stage=0x00000000000000A4',
                          'YOLO32_TASK_STAGE worker=0x0000000000000002 stage=0x00000000000000A3'),
                         ('busy_mask=0x0000000000000007 stage0=', 'busy_mask=0 stage0=')]:
            with self.subTest(field=old):
                self.assertIn(old, log)
                self.assertTrue(parse(log.replace(old,new))[0])

    def test_v6_diagnostic_accounting_cannot_hide_missing_or_overlapping_time(self):
        log=self.invoke('p')
        for old,new in [('YOLO32_ROCC worker=', 'MISSING_ROCC worker='),
                        ('YOLO32_SCHED_PROFILE ', 'MISSING_SCHED_PROFILE '),
                        ('YOLO32_TASK_CPU worker=', 'MISSING_TASK_CPU worker='),
                        ('step_cycles=0x0000000000000C1C', 'step_cycles=1'),
                        ('switch_count=0x00000000000000B4', 'switch_count=1'),
                        ('ready_blocked=0x0000000000000005', 'ready_blocked=99'),
                        ('cpu_cycles=0x0000000000000001 span_cycles=0x0000000000000002',
                         'cpu_cycles=3 span_cycles=2')]:
            with self.subTest(field=old):
                self.assertIn(old,log)
                self.assertTrue(parse(log.replace(old,new))[0])

    def test_conditional_policy_counters_match_packets_and_handoffs(self):
        log = self.invoke('t')
        self.assertEqual(parse(log)[0], [])
        for old, new in [('command_kept=0x00000000000005A3', 'command_kept=0'),
                         ('packet_yields=0x0000000000000057', 'packet_yields=0'),
                         ('wait_yields=0x0000000000000000', 'wait_yields=1'),
                         ('submit_burst=0x0000000000000002', 'submit_burst=0')]:
            with self.subTest(field=old):
                self.assertIn(old, log)
                self.assertTrue(parse(log.replace(old, new))[0])

    def test_latency_feedback_configuration_and_dispatch_accounting(self):
        log=self.invoke('p')
        self.assertEqual(parse(log)[0],[])
        for old,new in [('scheduling=adaptive','scheduling=unknown'),
                        ('feedback_commands=0x00000000000005FA','feedback_commands=0'),
                        ('feedback_cycles=0x00000000000005FA','feedback_cycles=1531'),
                        ('dispatch_max_cycles=0x0000000000000001','dispatch_max_cycles=2'),
                        ('pressure_yields=0x0000000000000000','pressure_yields=1'),
                        ('burst_reductions=0x0000000000000000','burst_reductions=1'),
                        ('recover_us=0x0000000000000005','recover_us=20'),
                        ('slow_dispatches=0x0000000000000000','slow_dispatches=1531')]:
            with self.subTest(field=old):
                self.assertIn(old,log)
                self.assertTrue(parse(log.replace(old,new))[0])

    def test_reports_do_not_mix_adaptive_and_fixed_samples(self):
        import contextlib,io
        from analyze_log import report
        adaptive=self.invoke('a')
        fixed=adaptive.replace('scheduling=adaptive','scheduling=fixed')
        for key,value in (('feedback_commands','05FA'),('feedback_cycles','05FA'),('dispatch_max_cycles','0001')):
            fixed=fixed.replace(f'{key}=0x000000000000{value}',f'{key}=0')
        errors,runs=parse(fixed+'\n'+adaptive)
        self.assertEqual(errors,[])
        output=io.StringIO()
        with contextlib.redirect_stdout(output):report(runs)
        self.assertIn('scheduling: adaptive',output.getvalue())
        self.assertIn('scheduling: fixed',output.getvalue())

    def test_reports_separate_single_and_two_packet_budgets(self):
        import contextlib,io
        from analyze_log import report
        two=self.invoke('a').replace('scheduling=adaptive','scheduling=fixed')
        for key,value in (('feedback_commands','05FA'),('feedback_cycles','05FA'),('dispatch_max_cycles','0001')):
            two=two.replace(f'{key}=0x000000000000{value}',f'{key}=0')
        one=two.replace('submit_burst=0x0000000000000002','submit_burst=0x0000000000000001')
        errors,runs=parse(two+'\n'+one)
        self.assertEqual(errors,[])
        self.assertEqual({r['submit_burst'] for r in runs},{1,2})
        output=io.StringIO()
        with contextlib.redirect_stdout(output):report(runs)
        self.assertIn('submit_burst=1;',output.getvalue())
        self.assertIn('submit_burst=2;',output.getvalue())
        inconsistent=one.replace('YOLO32_POLICY submit_burst=0x0000000000000001',
                                'YOLO32_POLICY submit_burst=0x0000000000000002')
        self.assertTrue(parse(inconsistent)[0])

    def test_fixed_fast_paths_completion_cache_and_scheduler_partition(self):
        fixed=self.invoke('p').replace('scheduling=adaptive','scheduling=fixed')
        for key,value in (('feedback_commands','05FA'),('feedback_cycles','05FA'),('dispatch_max_cycles','0001')):
            fixed=fixed.replace(f'{key}=0x000000000000{value}',f'{key}=0')
        self.assertEqual(parse(fixed)[0],[])
        cached=fixed.replace('cached_ready_hits=0x0000000000000000','cached_ready_hits=4')
        self.assertTrue(parse(cached)[0])  # Legacy fixed mode still rejects it.
        fast=cached.replace('hot_paths=0x0000000000000000','hot_paths=1')
        for key,value in [('scheduler_steps',90),('idle_scheduler_cycles',40),('active_scheduler_cycles',60)]:
            fast=fast.replace(f'{key}=0x0000000000000000',f'{key}={value}')
        errors,runs=parse(fast)
        self.assertEqual(errors,[])
        self.assertTrue(all(r['hot_paths']==1 for r in runs))
        for old,new in [('hot_paths=1','hot_paths=2'),('idle_scheduler_cycles=40','idle_scheduler_cycles=41'),
                        ('scheduler_steps=90','scheduler_steps=89'),('feedback_commands=0','feedback_commands=1')]:
            with self.subTest(field=old):
                self.assertTrue(parse(fast.replace(old,new))[0])
        import contextlib,io
        from analyze_log import report
        errors,runs=parse(fixed+'\n'+fast)
        self.assertEqual(errors,[])
        output=io.StringIO()
        with contextlib.redirect_stdout(output):report(runs)
        self.assertIn('hot_paths=0',output.getvalue())
        self.assertIn('hot_paths=1',output.getvalue())


    def test_layer_diagnosis_compares_two_modes_and_preserves_strict_checks(self):
        import contextlib, io
        from analyze_log import report
        log=self.invoke('q',layers=True)
        errors,runs=parse(log)
        self.assertEqual(errors,[])
        self.assertEqual([(r['mode'],r['analysis']) for r in runs],
                         [('forward',0),('forward',1),('independent',1)])
        self.assertIn('YOLO32_FIRMWARE v11',log)
        self.assertEqual([len(r['rocc_layer_stats']) for r in runs],[0,6,6])
        with contextlib.redirect_stdout(io.StringIO()) as output: report(runs)
        self.assertIn('Top 10 serial -> independent',output.getvalue())
        self.assertIn('funct=11: total=',output.getvalue())
        layer=next(line for line in log.splitlines() if line.startswith('YOLO32_ROCC_LAYER '))
        for damaged in (log.replace(layer+'\n','',1), log.replace(layer,layer+'\n'+layer,1),
                        log.replace(layer,layer.replace('max_index=0x0000000000000001','max_index=0'),1),
                        log.replace(layer,layer.replace('n20=0x0000000000000000','n20=1'),1),
                        log.replace(layer,layer.replace('cycles=0x00000000000001F4','cycles=501'),1),
                        log.replace(layer,layer.replace('label=test_layer','label=wrong'),1),
                        log.replace('rocc_layers=0x0000000000000001','rocc_layers=0')):
            with self.subTest(damaged=damaged[-100:]): self.assertTrue(parse(damaged)[0])

    def test_layer_command_on_control_image_does_not_run_a_partial_test(self):
        log=self.invoke('q')
        self.assertIn('Use download.sh --rocc-layers',log)
        self.assertNotIn('YOLO32_BEGIN',log)


if __name__ == '__main__':
    unittest.main()
