#!/usr/bin/env python3
"""I: frozen N6 tiler and fixed Conv geometry. P: run unchanged integer search on host.
O: explicit tiles for baremetal. A: 王志瑞. T: 2026-09-10.
"""
from pathlib import Path
import subprocess,json
HERE=Path(__file__).resolve().parent
NAMES='batch_size in_row_dim in_col_dim in_channels out_channels out_row_dim out_col_dim stride input_dilation kernel_dilation padding kernel_dim wrot180 trans_output_1203 trans_input_3120 trans_weight_1203 trans_weight_0132'.split()
class Planner:
    def __init__(self,out):
        self.out=out;self.cache={}
        h=(HERE/'platform/include/gemmini.h').read_text()
        a=h.index('static int tiled_conv_total_spad_rows(');b=h.index('\n\nstatic void conv_cpu_without_pool',a)
        formula=h[a:b]
        a=h.index('static void tiled_conv_stride_auto(');a=h.index('    const bool no_pool',a);b=h.index('    const int batches = args[0];',a)
        body=h[a:b]
        code='#include <stdio.h>\n#include <stdlib.h>\n#include <stdbool.h>\n#define DIM 64\n#define BANK_NUM 8\n#define BANK_ROWS 1024\n#define ACC_ROWS 2048\n'+formula
        code+='\nstatic void plan('+','.join('int '+n for n in NAMES)+'){\n int pool_stride=0,pool_size=1,pool_padding=0;\n'+body
        code+='for(int i=0;i<7;i++)printf("%d ",args[i]);printf("\\n");}\nint main(int argc,char **argv){if(argc!=18)return 2;plan('+','.join(f'atoi(argv[{i+1}])' for i in range(17))+');}\n'
        out.mkdir(parents=True,exist_ok=True);(out/'host_tiler.c').write_text('/* I: N6 tiler. P: host search. O: tile. A: 王志瑞. T: 2026-09-10. */\n'+code)
        self.exe=out/'host_tiler';subprocess.run(['gcc','-O2',str(out/'host_tiler.c'),'-o',str(self.exe)],check=True)
    def tile(self,args):
        values=tuple({'true':'1','false':'0'}.get(x,x) for x in args[:17])
        if values not in self.cache:
            r=subprocess.run([str(self.exe),*values],check=True,capture_output=True,text=True)
            tile=list(map(int,r.stdout.split()));assert len(tile)==7 and min(tile)>0
            self.cache[values]=tile
        return list(map(str,self.cache[values]))
    def save(self):
        (self.out/'tiles.json').write_text(json.dumps([{'geometry':dict(zip(NAMES,k)),'tile':v} for k,v in self.cache.items()],indent=2)+'\n')
