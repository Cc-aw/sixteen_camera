from paths import HERE, source_path
"""The actual lockstep step must not publish captured heads before execution."""
from pathlib import Path
import subprocess
import sys
import tempfile
import unittest

from generate_parallel import function, generate


class HeadPublicationTests(unittest.TestCase):
    def test_tile_heads_publish_only_after_group_drain(self):
        source=(source_path('model.c')).read_text()
        publish=function(source,'static void yolo32_publish_head(unsigned worker, unsigned head) {')
        step=function(source,'int yolo32_parallel_step(')
        harness=r'''
#include <assert.h>
#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#define YOLO32_WORKERS 3U
#define YOLOV5NU_DIM16_RUNNING 0
struct yolov5nu_worker_context { unsigned active,stage,waiting,poll_armed; };
static struct yolov5nu_worker_context worker_contexts[3];
typedef int Yolo32Result;
static unsigned parallel_mode=1,parallel_stage,parallel_collecting,analysis_enabled=1,yolo32_independent_enabled;
static unsigned pending_heads[3],calls[3][6],executed;
static uint64_t group_wait_cycles,group_submit_cycles,stage_cycles[165],clock_cycle;
static unsigned parallel_conv_stage[165]={1};
static uint64_t read_cycle(void){return ++clock_cycle;}
static void yolo32_fail(const char *s){puts(s);exit(42);}
static void callback(unsigned w,unsigned h){assert(executed&&!parallel_collecting);++calls[w][h];}
static void (*head_callback)(unsigned,unsigned)=callback;
static void yolo32_publish_head(unsigned,unsigned);
static int yolov5nu_dim16_worker_poll(unsigned w,Yolo32Result *r){
 (void)r;for(unsigned h=0;h<6;++h)yolo32_publish_head(w,h);
 for(unsigned i=0;i<3;++i)for(unsigned h=0;h<6;++h)assert(!calls[i][h]);
 ++worker_contexts[w].stage;return 0;
}
static void parallel_execute(void){
 for(unsigned w=0;w<3;++w){assert(worker_contexts[w].stage==1);assert(pending_heads[w]==63);}
 /* Completion of the real tile group/drain is the publication boundary. */
 executed=1;parallel_collecting=0;
}
'''
        main=r'''
int main(void){Yolo32Result r[3]={0};for(unsigned w=0;w<3;++w)worker_contexts[w].active=1;
 assert(yolo32_parallel_step(r)==0);
 for(unsigned w=0;w<3;++w){assert(!pending_heads[w]);for(unsigned h=0;h<6;++h)assert(calls[w][h]==1);}
 assert(stage_cycles[0]>0);puts("PASS: all captured heads publish after group completion");return 0;}
'''
        with tempfile.TemporaryDirectory() as d:
            root=Path(d);p=root/'test.c';p.write_text(harness+publish+step+main)
            subprocess.run(['gcc','-std=c11','-O2','-Wall','-Wextra','-Werror',str(p),'-o',str(root/'test')],check=True,capture_output=True)
            subprocess.run([root/'test'],check=True,capture_output=True)
            params=next((HERE.parents[3]/'hw/soc').glob(
                '*/gen-collateral/include/gemmini_params_32x32_ws_dual_int8_dsp_inference_ram_custom3_xcvu13p.h'))
            for fixed,packets in ((False,False),(True,False),(True,True)):
                generate(root,fixed_plans=fixed,params=params,fixed_packets=packets)
                poll=function((root/'parallel_model.inc').read_text(),'int yolov5nu_dim16_worker_poll(')
                for forbidden in ('stage4_class_heads_i8(', 'stage4_dfl_heads_i8(', 'decode_all_compute(', 'decode_nms_from_candidates('):
                    self.assertNotIn(forbidden,poll)
                self.assertEqual(poll.count('yolo32_publish_head(worker_id,'),6)
                self.assertIn('if (parallel_mode || yolo32_independent_enabled || analysis_enabled)',poll)
                self.assertIn('if (yolo32_independent_enabled) context->waiting = context->poll_armed = 0;',poll)


if __name__=='__main__':unittest.main()
