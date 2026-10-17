from pathlib import Path
import subprocess
root=Path(__file__).resolve().parents[2]
folder=Path(__file__).resolve().parent
text=(root/'reference/src/main.c').read_text()
changes={
    'diagnostics=0,frames=12':'diagnostics=9,frames=12',
    'prepare_model();\n#ifndef __riscv':'text("L2PROBE,PREPARE_MODEL_BEGIN\\n");prepare_model();text("L2PROBE,PREPARE_MODEL_END\\n");\n#ifndef __riscv',
    'capture(d,s,i);':'{field("L2PROBE,CAPTURE_BEGIN,lane=",d);field(",slot=",s);field(",image=",i);text("\\n");capture(d,s,i);text("L2PROBE,CAPTURE_END\\n");}',
    'ppu_init();uint64_t cycles[MODES];':'text("L2PROBE,PPU_INIT_BEGIN\\n");ppu_init();text("L2PROBE,PPU_INIT_END\\n");uint64_t cycles[MODES];',
    'prepare_batch();batch_begin=clock_cycle();':'text("L2PROBE,PREPARE_BATCH_BEGIN\\n");prepare_batch();text("L2PROBE,PREPARE_BATCH_END\\n");batch_begin=clock_cycle();',
    'admit(f,0);struct Plan *p=frames[f].plan;':'field("L2PROBE,ADMIT_BEGIN,frame=",f);text("\\n");admit(f,0);text("L2PROBE,ADMIT_END\\n");struct Plan *p=frames[f].plan;',
    'if(kind==GF_RAW)direct(c);':'if(kind==GF_RAW){if(f==0&&(i<1024||i%128==0)){field("L2PROBE,DIRECT_BEGIN,index=",i);field(",control=",c->control);text("\\n");}direct(c);if(f==0&&i<1024){field("L2PROBE,DIRECT_END,index=",i);text("\\n");}}',
    'else if(kind==GF_DRAIN)gf_publish();':'else if(kind==GF_DRAIN){if(f==0&&i<1024){field("L2PROBE,FENCE_BEGIN,index=",i);text("\\n");}gf_publish();if(f==0&&i<1024)text("L2PROBE,FENCE_END\\n");}',
}
for before,after in changes.items():
    assert text.count(before)==1,(before,text.count(before))
    text=text.replace(before,after)
text=text.replace('direct(c);if(f==0', 'direct(c);if((c->control>>8)==15)gf_publish();if(f==0')
source=folder/'reference_trace_fenced.c';source.write_text(text)
cc='/home/wzr/chipyard/.conda-env/riscv-tools/bin/riscv64-unknown-elf-gcc'
flags=['-march=rv64gcv','-mabi=lp64d','-mcmodel=medany','-msmall-data-limit=0','-O2','-g','-std=gnu11','-ffunction-sections','-fdata-sections','-ffreestanding','-fno-builtin','-fno-tree-vectorize','-Wall','-Wextra','-Wno-unused-variable','-Wno-unused-function','-Wno-unused-parameter','-Wno-sign-compare','-Werror=implicit-function-declaration','-DATSOFT_THREE_WAY=1']
incs=['-I'+str(root/p) for p in ['include','build/generated','build/generated/include','model','model/include','reference/src']]
obj=folder/'reference_trace_fenced.o'
subprocess.run([cc]+flags+incs+['-include',str(root/'include/config.h'),'-c',str(source),'-o',str(obj)],check=True)
objects=[str(root/'build/obj'/name) for name in ['irq.o','support.o','inputs.o','publication.o','queue.o','slots.o']]
subprocess.run([cc]+flags+['-nostdlib','-nostartfiles','-Wl,--gc-sections','-T',str(root/'reference/src/link.ld'),str(root/'reference/src/start.S'),str(obj)]+objects+['-lm','-lgcc','-o',str(folder/'reference_trace_fenced.elf')],check=True)
print('REFERENCE_TRACE_BUILD=PASS performance_measurement=DISABLED')
