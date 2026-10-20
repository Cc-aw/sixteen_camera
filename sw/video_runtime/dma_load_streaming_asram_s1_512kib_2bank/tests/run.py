#!/usr/bin/env python3
from pathlib import Path
import os,subprocess,json
p=Path(__file__).resolve().parents[1]
lines=(p/'sources.mk').read_text().replace('\\\n',' ').split()[2:]
sources=[s for s in lines if s.startswith('runtime/ai/') and s not in ('runtime/ai/postprocess/ai_overlay.c',)]
# Real core/policy/services and scalar result decoding; device and overlay HALs
# are replaced by deterministic completion/fault injection in test_live.c.
flags=['-O1','-g','-std=gnu11','-ffunction-sections','-fdata-sections','-fno-tree-vectorize','-DATSOFT_THREE_WAY=1','-DYOLO_SPPF_ASRAM=0','-DACTIVATION_MEMORY_HOST_TEST','-DS1_HOST_TEST','-DAI_MODEL_WORKER_COUNT=3U','-DYOLOV5NU_DIM16_WORKER_COUNT=3U','-Wno-unused-function','-Wno-unused-variable','-Wno-unused-parameter','-Wno-sign-compare']
includes=['tests/fakes','tests','build/yolo_generated','build/yolo_generated/include','runtime','include','model','model/include']
cmd=[os.environ.get('HOST_CC','gcc'),*flags,*['-I'+str(p/x) for x in includes],'-include',str(p/'include/config.h'),str(p/'tests/test_live.c'),str(p/'src/activation_memory.c'),str(p/'model/ai/runtime/ai_head_slot_queue.c'),*[str(p/s) for s in sources],'-Wl,--gc-sections','-lm','-o',str(p/'build/test_live')]
subprocess.run(cmd,check=True)
subprocess.run([os.sys.executable,'-B','-m','unittest','discover','-s',str(p/'tests'),'-p','test_*.py','-v'],check=True)
for scenario in ['normal','fault','generation','ppu_error','frontend_fault','frontend_timeout','ppu_timeout','input_masks']:
 subprocess.run([str(p/'build/test_live'),scenario],check=True,timeout=120)
(p/'build/host_tests.json').write_text(json.dumps(dict(status='PASS',scenarios=8,log_tests=19,rtl_executed=False,board_tested=False),indent=2)+'\n')
