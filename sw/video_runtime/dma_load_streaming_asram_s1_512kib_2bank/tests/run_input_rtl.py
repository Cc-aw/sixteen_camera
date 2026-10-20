#!/usr/bin/env python3
"""Reproduce idle-input capture starvation using the frozen S1 capture RTL."""
from pathlib import Path
import subprocess
import tempfile
p=Path(__file__).resolve().parents[1]
hw=p.parents[2]/'hw/soc/version/dma_load_streaming_asram_s1_512kib_2bank/board/rtl'
with tempfile.TemporaryDirectory(prefix='s1_input_rtl_') as directory:
 out=Path(directory)/'obj'
 cmd=['verilator','--binary','--timing','--assert','-Wno-fatal','-j','2',
      '--top-module','tb_s1_absent_input_admission','--Mdir',str(out),
      str(hw/'interfaces/axi4_if.sv'),str(hw/'ai/preprocess/yolov5nu_tensor_stream_packer.sv'),
      str(hw/'ai/preprocess/yolov5nu_multi_channel_tensor_dma.sv'),str(p/'tests/rtl/tb_s1_absent_input_admission.sv')]
 subprocess.run(cmd,check=True)
 subprocess.run([str(out/'Vtb_s1_absent_input_admission')],check=True,timeout=60)
