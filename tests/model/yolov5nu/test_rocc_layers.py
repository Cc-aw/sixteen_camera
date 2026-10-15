from paths import HERE, source_path, RISCV_LINUX_CC
"""Exercise the production collector with worker changes and exact bucket edges."""
from pathlib import Path
import subprocess
import tempfile
import copy
import sys
import unittest

from rocc_layers import validate
from generate_parallel import function


class LayerCollectorTests(unittest.TestCase):
    def test_native_collector_attributes_before_switch_and_handles_lockstep_stage(self):
        source=(source_path('model.c')).read_text()
        collector='\n'.join(function(source,begin) for begin in (
            'static void command_elapsed(unsigned funct, uint64_t cycles) {',
            'const Yolo32CommandStats *yolo32_command_stats(',
            'const Yolo32LayerCommandStats *yolo32_layer_command_stats('))
        with tempfile.TemporaryDirectory(prefix='yolo32-layer-collector-') as tmp:
            root=Path(tmp)
            (root/'collector.c').write_text('''
#include <assert.h>
#include <stdlib.h>
#include "yolo32.h"
#define SOC_CLOCK_HZ 100000000UL
static unsigned gemmini_pool_active_worker, parallel_mode, parallel_stage, stages[3];
static Yolo32CommandStats command_stats[YOLO32_WORKERS][YOLO32_COMMAND_FUNCTS];
static Yolo32LayerCommandStats layer_command_stats[YOLO32_WORKERS][YOLO32_GRAPH_STAGES][2];
unsigned yolo32_stage(unsigned worker) { return stages[worker]; }
void yolo32_fail(const char *reason) { (void)reason; abort(); }
''' + collector + '''
int main(void) {
    const unsigned cycles[]={1999,2000,9999,10000,99999,100000,120000};
    for(unsigned i=0;i<7;++i) command_elapsed(15,cycles[i]);
    const Yolo32LayerCommandStats *s=yolo32_layer_command_stats(0,0,15);
    assert(s->count==7 && s->cycles==343997 && s->max_cycles==120000 && s->max_index==7);
    assert(s->slow_count[0]==6 && s->slow_cycles[0]==341998);
    assert(s->slow_count[1]==4 && s->slow_cycles[1]==329999);
    assert(s->slow_count[2]==2 && s->slow_cycles[2]==220000);
    gemmini_pool_active_worker=1; stages[1]=17; command_elapsed(11,3000);
    assert(yolo32_layer_command_stats(1,17,11)->cycles==3000);
    assert(yolo32_layer_command_stats(0,17,11)->count==0);
    command_elapsed(8,9000);
    assert(yolo32_layer_command_stats(1,17,11)->count==1);
    parallel_mode=1; parallel_stage=40; stages[1]=41; command_elapsed(15,5000);
    assert(yolo32_layer_command_stats(1,40,15)->count==1);
    assert(yolo32_layer_command_stats(1,41,15)->count==0);
    assert(!yolo32_layer_command_stats(3,0,15));
    assert(!yolo32_layer_command_stats(0,165,15));
    assert(!yolo32_layer_command_stats(0,0,8));
    assert(yolo32_command_stats(0,15)->cycles==343997);
    return 0;
}
''')
            subprocess.run(['gcc','-std=c11','-O2','-Wall','-Wextra','-Werror',
                            '-DYOLO32_ROCC_LAYERS=1','-DYOLOV5NU_DIM16_WORKER_COUNT=3U','-DYOLO32_DIAGNOSTIC_BUILD=1',
                            '-I',str(HERE),'-I',str((HERE.parent/'frozen/native')),str(root/'collector.c'),'-o',str(root/'collector')],
                           check=True,capture_output=True)
            subprocess.run([str(root/'collector')],check=True,capture_output=True)

    def test_positive_latency_buckets_and_stage_cpu_bound_are_checked(self):
        row=dict(worker='0',stage='0',funct='15',kind='conv',label='layer0',
                 count='7',cycles='343997',max_cycles='120000',max_index='7',
                 n20='6',c20='341998',n100='4',c100='329999',n1000='2',c1000='220000')
        run=dict(rocc_layers=1,diagnostics=1,mode='independent',rocc_layer_stats={(0,0,15):row},
                 rocc={(0,15):dict(count='7',cycles='343997',max_cycles='120000')},
                 task_stages={(0,0):dict(kind='conv',label='layer0',cpu_cycles='350000')})
        validate(run)
        for key,value in [('n20','3'),('c100','200'),('n1000','0'),('c1000','219999'),
                          ('max_index','8'),('cycles','343998')]:
            damaged=copy.deepcopy(run);damaged['rocc_layer_stats'][(0,0,15)][key]=value
            with self.subTest(key=key),self.assertRaises(ValueError):validate(damaged)
        damaged=copy.deepcopy(run);damaged['task_stages'][(0,0)]['cpu_cycles']='343996'
        with self.assertRaises(ValueError):validate(damaged)
